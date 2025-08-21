import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/intimacy_data.dart';
import '../utils/logger_utils.dart';

class IntimacyService {
  static final IntimacyService _instance = IntimacyService._internal();
  factory IntimacyService() => _instance;
  IntimacyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, IntimacyData> _intimacyCache = {};
  String? _currentUserId;
  
  static const String _localStoragePrefix = 'intimacy_';
  static const String _collectionName = 'intimacy';
  
  void setUserId(String userId) {
    _currentUserId = userId;
    _loadAllIntimacyData();
  }

  Future<void> _loadAllIntimacyData() async {
    if (_currentUserId == null) return;
    
    try {
      await _loadFromLocal();
      
      await _syncWithFirestore();
    } catch (e) {
      LoggerUtils.error('加载亲密度数据失败: $e');
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_localStoragePrefix));
      
      for (final key in keys) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          final json = jsonDecode(jsonString);
          final intimacy = IntimacyData.fromJson(json);
          _intimacyCache[intimacy.npcId] = intimacy;
        }
      }
      
      LoggerUtils.info('从本地加载了 ${_intimacyCache.length} 个NPC的亲密度数据');
    } catch (e) {
      LoggerUtils.error('从本地加载亲密度数据失败: $e');
    }
  }

  Future<void> _syncWithFirestore() async {
    if (_currentUserId == null) return;
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection(_collectionName)
          .get();
      
      for (final doc in snapshot.docs) {
        final intimacy = IntimacyData.fromFirestore(doc);
        final localData = _intimacyCache[intimacy.npcId];
        
        if (localData == null || intimacy.lastInteraction.isAfter(localData.lastInteraction)) {
          _intimacyCache[intimacy.npcId] = intimacy;
          await _saveToLocal(intimacy);
        } else if (localData.lastInteraction.isAfter(intimacy.lastInteraction)) {
          await _saveToFirestore(localData);
        }
      }
      
      LoggerUtils.info('与Firestore同步完成，共 ${snapshot.docs.length} 个NPC数据');
    } catch (e) {
      LoggerUtils.error('与Firestore同步失败: $e');
    }
  }

  Future<void> _saveToLocal(IntimacyData intimacy) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_localStoragePrefix${intimacy.npcId}';
      await prefs.setString(key, jsonEncode(intimacy.toJson()));
    } catch (e) {
      LoggerUtils.error('保存到本地失败: $e');
    }
  }

  Future<void> _saveToFirestore(IntimacyData intimacy) async {
    if (_currentUserId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection(_collectionName)
          .doc(intimacy.npcId)
          .set(intimacy.toFirestore());
    } catch (e) {
      LoggerUtils.error('保存到Firestore失败: $e');
    }
  }

  IntimacyData getIntimacy(String npcId) {
    if (!_intimacyCache.containsKey(npcId)) {
      _intimacyCache[npcId] = IntimacyData(
        npcId: npcId,
        lastInteraction: DateTime.now(),
      );
    }
    return _intimacyCache[npcId]!;
  }

  Future<void> updateIntimacy(String npcId, IntimacyData updatedData) async {
    _intimacyCache[npcId] = updatedData;
    
    await Future.wait([
      _saveToLocal(updatedData),
      _saveToFirestore(updatedData),
    ]);
    
    LoggerUtils.info('更新NPC $npcId 的亲密度: ${updatedData.intimacyPoints} (等级: ${updatedData.intimacyLevel})');
  }

  Future<void> addIntimacyPoints(String npcId, int points, {String? reason}) async {
    final current = getIntimacy(npcId);
    final oldLevel = current.intimacyLevel;
    
    final updated = current.copyWith(
      intimacyPoints: current.intimacyPoints + points,
      lastInteraction: DateTime.now(),
    );
    
    await updateIntimacy(npcId, updated);
    
    if (updated.intimacyLevel > oldLevel) {
      _onLevelUp(npcId, oldLevel, updated.intimacyLevel);
    }
    
    LoggerUtils.info('NPC $npcId 获得 $points 亲密度点数${reason != null ? " (原因: $reason)" : ""}');
  }

  Future<bool> recordNPCDrunk(String npcId, int minutesSpentTogether) async {
    final current = getIntimacy(npcId);
    final oldLevel = current.intimacyLevel;
    
    // 每分钟 = 1点亲密度
    // 20-60分钟对应20-60点亲密度
    int pointsToAdd = minutesSpentTogether;
    
    final updated = current.copyWith(
      intimacyPoints: current.intimacyPoints + pointsToAdd,
      lastInteraction: DateTime.now(),
      totalGames: current.totalGames + 1,
      wins: current.wins + 1,  // 把NPC喝醉算作胜利
    );
    
    // 保存到本地和Firestore
    await updateIntimacy(npcId, updated);
    
    // 检测是否升级
    bool leveledUp = false;
    if (updated.intimacyLevel > oldLevel) {
      _onLevelUp(npcId, oldLevel, updated.intimacyLevel);
      leveledUp = true;
    }
    
    LoggerUtils.info('与醉酒的 $npcId 独处了 $minutesSpentTogether 分钟，获得 $pointsToAdd 亲密度');
    LoggerUtils.info('当前亲密度: ${updated.intimacyPoints} (等级: ${updated.intimacyLevel})');
    
    return leveledUp;
  }

  void _onLevelUp(String npcId, int oldLevel, int newLevel) {
    LoggerUtils.info('NPC $npcId 亲密度升级！$oldLevel -> $newLevel');
    
  }

  Future<void> unlockDialogue(String npcId, String dialogueId) async {
    final current = getIntimacy(npcId);
    
    if (!current.unlockedDialogues.contains(dialogueId)) {
      final updated = current.copyWith(
        unlockedDialogues: [...current.unlockedDialogues, dialogueId],
      );
      await updateIntimacy(npcId, updated);
    }
  }

  Future<void> achieveMilestone(String npcId, String milestoneId) async {
    final current = getIntimacy(npcId);
    
    if (!current.achievedMilestones.contains(milestoneId)) {
      final updated = current.copyWith(
        achievedMilestones: [...current.achievedMilestones, milestoneId],
      );
      await updateIntimacy(npcId, updated);
      
      await addIntimacyPoints(npcId, 50, reason: '达成里程碑: $milestoneId');
    }
  }

  Map<String, IntimacyData> getAllIntimacyData() {
    return Map.from(_intimacyCache);
  }

  List<IntimacyData> getTopIntimacyNPCs({int limit = 5}) {
    final allData = _intimacyCache.values.toList();
    allData.sort((a, b) => b.intimacyPoints.compareTo(a.intimacyPoints));
    return allData.take(limit).toList();
  }

  bool checkIntimacyRequirement(String npcId, int requiredLevel) {
    final intimacy = getIntimacy(npcId);
    return intimacy.intimacyLevel >= requiredLevel;
  }

  Future<void> resetIntimacy(String npcId) async {
    final fresh = IntimacyData(
      npcId: npcId,
      lastInteraction: DateTime.now(),
    );
    
    await updateIntimacy(npcId, fresh);
    LoggerUtils.info('重置NPC $npcId 的亲密度数据');
  }

  Future<void> clearAllLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_localStoragePrefix));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      _intimacyCache.clear();
      LoggerUtils.info('清除所有本地亲密度数据');
    } catch (e) {
      LoggerUtils.error('清除本地数据失败: $e');
    }
  }

  static List<IntimacyMilestone> getAvailableMilestones(String npcId) {
    return [
      IntimacyMilestone(
        level: 2,
        id: 'first_friend',
        title: '初次成为朋友',
        description: '与$npcId的关系达到朋友级别',
        reward: IntimacyReward(
          pointsRequired: 300,
          type: 'dialogue',
          rewardId: 'friend_dialogue_1',
          description: '解锁特殊对话',
        ),
      ),
      IntimacyMilestone(
        level: 5,
        id: 'best_friend',
        title: '成为密友',
        description: '与$npcId的关系达到密友级别',
        reward: IntimacyReward(
          pointsRequired: 1500,
          type: 'expression',
          rewardId: 'special_expression_1',
          description: '解锁特殊表情',
        ),
      ),
      IntimacyMilestone(
        level: 10,
        id: 'soul_mate',
        title: '灵魂伴侣',
        description: '与$npcId的关系达到最高级别',
        reward: IntimacyReward(
          pointsRequired: 4500,
          type: 'title',
          rewardId: 'soul_mate_title',
          description: '获得专属称号',
        ),
      ),
    ];
  }
}
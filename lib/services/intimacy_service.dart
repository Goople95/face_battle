import '../models/intimacy_data.dart';
import '../utils/logger_utils.dart';
import 'storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 亲密度服务 - 仅管理本地缓存
/// Firestore存储已移至GameProgressService中的npcIntimacy字段
class IntimacyService {
  static final IntimacyService _instance = IntimacyService._internal();
  factory IntimacyService() => _instance;
  IntimacyService._internal();

  final Map<String, IntimacyData> _intimacyCache = {};
  String? _currentUserId;
  
  static const String _localStoragePrefix = 'intimacy_';
  
  void setUserId(String userId) {
    _currentUserId = userId;
    // 设置LocalStorageService的用户ID
    LocalStorageService.instance.setUserId(userId);
    _loadAllIntimacyData();
  }

  Future<void> _loadAllIntimacyData() async {
    if (_currentUserId == null) return;
    
    try {
      await _loadFromLocal();
      
      // 不再自动同步Firestore，亲密度数据由GameProgressService管理
    } catch (e) {
      LoggerUtils.error('加载亲密度数据失败: $e');
    }
  }

  Future<void> _loadFromLocal() async {
    if (_currentUserId == null) return;
    
    try {
      final storage = LocalStorageService.instance;
      // 使用基础方法获取所有亲密度数据
      final userKeys = await storage.getUserKeys();
      final intimacyKeys = userKeys.where((key) => key.startsWith('intimacy_'));
      
      _intimacyCache.clear();
      for (final key in intimacyKeys) {
        final npcId = key.substring('intimacy_'.length);
        final data = await storage.getJson(key);
        if (data != null) {
          _intimacyCache[npcId] = IntimacyData.fromJson(data);
        }
      }
      
      LoggerUtils.info('从本地加载了 ${_intimacyCache.length} 个NPC的亲密度数据 (用户: $_currentUserId)');
    } catch (e) {
      LoggerUtils.error('从本地加载亲密度数据失败: $e');
    }
  }

  // Firestore同步已移除 - 亲密度数据现在由GameProgressService管理
  // NPC亲密度数据存储在gameProgress/{userId}的npcIntimacy字段中

  Future<void> _saveToLocal(IntimacyData intimacy) async {
    if (_currentUserId == null) return;
    
    try {
      final storage = LocalStorageService.instance;
      await storage.setJson('intimacy_${intimacy.npcId}', intimacy.toJson());
    } catch (e) {
      LoggerUtils.error('保存到本地失败: $e');
    }
  }

  // 保存到Firestore的方法已移除
  // 亲密度数据现在通过GameProgressService统一管理

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
      // 不再直接保存到Firestore
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

  // 已移除 unlockDialogue 和 achieveMilestone 方法
  // 对话现在是随机选择的，不需要解锁机制

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
    if (_currentUserId == null) return;
    
    try {
      // 使用LocalStorageService的清除方法
      final storage = LocalStorageService.instance;
      final userKeys = await storage.getUserKeys();
      final intimacyKeys = userKeys.where((key) => key.startsWith('intimacy_'));
      
      for (final key in intimacyKeys) {
        await storage.remove(key);
      }
      
      _intimacyCache.clear();
      LoggerUtils.info('清除用户 $_currentUserId 的本地亲密度数据');
    } catch (e) {
      LoggerUtils.error('清除本地数据失败: $e');
    }
  }

  // 已移除里程碑系统 - 简化存储逻辑
}
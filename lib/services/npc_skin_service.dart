import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'npc_raw_config_service.dart';
import 'intimacy_service.dart';
import 'purchase_service.dart';
import 'game_progress_service.dart';
import '../models/npc_skin.dart';
import '../utils/logger_utils.dart';

/// NPC皮膚管理服務 - 支持實時監聽Firestore變化
class NPCSkinService {
  static NPCSkinService? _instance;
  static NPCSkinService get instance => _instance ??= NPCSkinService._();
  
  NPCSkinService._();
  
  // 使用GameProgressService作為數據源
  GameProgressService get _progressService => GameProgressService.instance;
  
  bool _isInitialized = false;
  
  // Firestore監聽器
  StreamSubscription<DocumentSnapshot>? _skinListener;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 皮膚變化通知流
  final StreamController<Map<String, int>> _skinChangesController = 
      StreamController<Map<String, int>>.broadcast();
  
  /// 獲取皮膚變化的Stream
  Stream<Map<String, int>> get skinChangesStream => _skinChangesController.stream;
  
  /// 初始化服務並開始監聽Firestore
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 確保原始配置已加載
      await NPCRawConfigService.instance.ensureLoaded();
      
      // 從GameProgressService加載數據
      await _progressService.loadProgress();
      
      // 確保所有NPC都有默認皮膚數據
      _ensureDefaultSkinData();
      
      // 開始監聽Firestore中的皮膚數據變化
      _startListeningToSkinChanges();
      
      _isInitialized = true;
      LoggerUtils.info('NPCSkinService 初始化成功');
      
      // 初始化完成後，立即發送當前皮膚數據
      final progress = _progressService.getProgress();
      if (progress != null) {
        LoggerUtils.info('初始化時發送皮膚數據: ${progress.selectedNPCSkins}');
        _skinChangesController.add(Map<String, int>.from(progress.selectedNPCSkins));
      }
    } catch (e) {
      LoggerUtils.error('NPCSkinService 初始化失敗: $e');
    }
  }
  
  /// 確保初始化完成（不再強制寫入默認數據）
  void _ensureDefaultSkinData() {
    // 驗證服務是否正常初始化
    final progress = _progressService.getProgress();
    if (progress == null) {
      LoggerUtils.warning('NPCSkinService: GameProgressService尚未加載數據');
      return;
    }
    
    // 只記錄日誌，不修改數據
    // 默認值應該在讀取時提供，而不是在初始化時強制寫入
    LoggerUtils.info('NPCSkinService: 初始化完成');
    LoggerUtils.info('  - 已記錄${progress.selectedNPCSkins.length}個NPC的皮膚選擇');
    LoggerUtils.info('  - 已記錄${progress.unlockedNPCSkins.length}個NPC的解鎖皮膚');
    
    // 不再修改和保存數據，避免觸發不必要的同步
  }
  
  /// 開始監聽Firestore中的皮膚數據變化
  void _startListeningToSkinChanges() {
    final userId = _progressService.currentUserId;
    if (userId == null) return;
    
    // 取消之前的監聽器
    _skinListener?.cancel();
    
    // 監聽用戶的game_progress文檔
    _skinListener = _firestore
        .collection('users')
        .doc(userId)
        .collection('game_data')
        .doc('progress')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          // 更新本地緩存的皮膚數據
          final selectedSkins = data['selectedNPCSkins'] as Map<String, dynamic>?;
          if (selectedSkins != null) {
            // 更新GameProgressService中的數據
            final progress = _progressService.getProgress();
            if (progress != null) {
              // 保存舊數據用於比較
              final oldSkins = Map<String, int>.from(progress.selectedNPCSkins);
              
              // 更新為新數據
              progress.selectedNPCSkins = Map<String, int>.from(selectedSkins);
              
              // 檢查是否有實際變化
              bool hasChanges = false;
              for (final entry in progress.selectedNPCSkins.entries) {
                if (oldSkins[entry.key] != entry.value) {
                  hasChanges = true;
                  LoggerUtils.info('NPC ${entry.key} 皮膚變化: ${oldSkins[entry.key] ?? 1} -> ${entry.value}');
                }
              }
              
              if (hasChanges) {
                LoggerUtils.info('從Firestore實時更新皮膚數據，發送通知');
                // 通知UI更新 - 創建新的Map以確保觸發更新
                _skinChangesController.add(Map<String, int>.from(progress.selectedNPCSkins));
              } else {
                LoggerUtils.debug('Firestore皮膚數據無變化，跳過通知');
              }
            }
          }
        }
      }
    }, onError: (error) {
      LoggerUtils.error('監聽Firestore皮膚數據失敗: $error');
    });
  }
  
  /// 獲取NPC當前選擇的皮膚ID（只讀，不寫入默認值）
  int getSelectedSkinId(String npcId) {
    final progress = _progressService.getProgress();
    
    // 優先從緩存的進度數據獲取
    if (progress != null) {
      final skinId = progress.selectedNPCSkins[npcId];
      if (skinId != null) {
        return skinId;
      }
    }
    
    // 如果沒有找到，返回默認值1，但不寫入數據庫
    // 這是關鍵：只在讀取時提供默認值，不修改存儲的數據
    return 1;
  }
  
  /// 設置NPC選擇的皮膚
  Future<bool> setSelectedSkin(String npcId, int skinId) async {
    // 檢查皮膚是否已解鎖
    if (!isSkinUnlocked(npcId, skinId)) {
      LoggerUtils.warning('嘗試選擇未解鎖的皮膚: NPC=$npcId, Skin=$skinId');
      return false;
    }
    
    // 更新GameProgress中的數據
    var progress = _progressService.getProgress();
    if (progress == null) {
      progress = GameProgressData(userId: _progressService.currentUserId ?? '');
    }
    
    progress.selectedNPCSkins[npcId] = skinId;
    
    // 保存到GameProgressService（會自動同步到雲端）
    await _progressService.saveProgress(progress);
    
    // 立即通知UI更新（不等待Firestore同步）
    LoggerUtils.info('已選擇皮膚: NPC=$npcId, Skin=$skinId，立即通知UI更新');
    _skinChangesController.add(Map<String, int>.from(progress.selectedNPCSkins));
    
    return true;
  }
  
  /// 檢查皮膚是否已解鎖
  bool isSkinUnlocked(String npcId, int skinId) {
    // 皮膚ID 1（默認皮膚）總是解鎖的
    if (skinId == 1) {
      return true;
    }
    
    // 從GameProgress檢查記錄
    final progress = _progressService.getProgress();
    if (progress != null && progress.unlockedNPCSkins[npcId]?.contains(skinId) == true) {
      return true;
    }
    
    // 獲取NPC配置
    final npcConfig = NPCRawConfigService.instance.getNPCById(npcId);
    if (npcConfig == null) return false;
    
    // 獲取皮膚信息（使用extension方法）
    final skin = npcConfig.getSkinById(skinId);
    if (skin == null) return false;
    
    // 如果是默認皮膚類型，總是解鎖（但不寫入數據）
    if (skin.unlockCondition.type == 'default') {
      return true;
    }
    
    // 檢查解鎖條件
    final unlocked = checkUnlockCondition(npcId, skin.unlockCondition);
    if (unlocked && !_hasMarkedUnlock(npcId, skinId)) {
      // 只有在真正滿足條件且之前沒有標記過時才標記
      _markSkinUnlocked(npcId, skinId);
    }
    
    return unlocked;
  }
  
  /// 檢查是否已經標記過解鎖（避免重複寫入）
  bool _hasMarkedUnlock(String npcId, int skinId) {
    final progress = _progressService.getProgress();
    return progress?.unlockedNPCSkins[npcId]?.contains(skinId) ?? false;
  }
  
  /// 檢查解鎖條件
  bool checkUnlockCondition(String npcId, UnlockCondition condition) {
    switch (condition.type) {
      case 'default':
        return true;
      
      case 'intimacy':
        if (condition.level == null) return false;
        final currentIntimacy = IntimacyService().getIntimacyLevel(npcId);
        return currentIntimacy >= condition.level!;
      
      case 'payment':
        if (condition.itemId == null) return false;
        return PurchaseService.instance.hasItem(condition.itemId!);
      
      case 'vip_exclusive':
        // 檢查NPC本身是否是VIP NPC並已解鎖
        final npcConfig = NPCRawConfigService.instance.getNPCById(npcId);
        if (npcConfig?['isVIP'] == true) {
          final unlockItemId = npcConfig?['unlockItemId'] as String?;
          if (unlockItemId != null) {
            return PurchaseService.instance.hasItem(unlockItemId);
          }
        }
        return false;
      
      default:
        return false;
    }
  }
  
  /// 標記皮膚為已解鎖
  Future<void> _markSkinUnlocked(String npcId, int skinId) async {
    var progress = _progressService.getProgress();
    if (progress == null) {
      progress = GameProgressData(userId: _progressService.currentUserId ?? '');
    }
    
    // 確保列表存在
    if (!progress.unlockedNPCSkins.containsKey(npcId)) {
      progress.unlockedNPCSkins[npcId] = [];
    }
    
    // 添加解鎖的皮膚
    if (!progress.unlockedNPCSkins[npcId]!.contains(skinId)) {
      progress.unlockedNPCSkins[npcId]!.add(skinId);
      
      // 保存到GameProgressService（會自動同步到雲端）
      await _progressService.saveProgress(progress);
    }
  }
  
  /// 獲取NPC的所有皮膚列表（包含解鎖狀態）
  List<SkinInfo> getNPCSkins(String npcId) {
    final npcConfig = NPCRawConfigService.instance.getNPCById(npcId);
    if (npcConfig == null) return [];
    
    // 使用NPCSkinExtension擴展方法獲取皮膚列表
    final skins = npcConfig.skins;  // 這裡會調用extension中的get skins方法
    final selectedSkinId = getSelectedSkinId(npcId);
    
    return skins.map((skin) {
      final unlocked = isSkinUnlocked(npcId, skin.id);
      return SkinInfo(
        skin: skin,
        isUnlocked: unlocked,
        isSelected: skin.id == selectedSkinId,
      );
    }).toList();
  }
  
  /// 獲取NPC當前皮膚的資源路徑
  String getAvatarPath(String npcId) {
    final skinId = getSelectedSkinId(npcId);
    final npcConfig = NPCRawConfigService.instance.getNPCById(npcId);
    
    if (npcConfig == null) {
      return 'assets/npcs/$npcId/1/';  // 默認路徑
    }
    
    // 使用extension方法獲取皮膚
    final skin = npcConfig.getSkinById(skinId);
    if (skin?.avatarPath != null) {
      return skin!.avatarPath!;
    }
    
    // 使用NPC路徑 + 皮膚ID
    return 'assets/npcs/$npcId/$skinId/';
  }
  
  /// 獲取NPC當前皮膚的視頻路徑
  String getVideosPath(String npcId) {
    final skinId = getSelectedSkinId(npcId);
    final npcConfig = NPCRawConfigService.instance.getNPCById(npcId);
    
    if (npcConfig == null) {
      return 'assets/npcs/$npcId/1/';  // 默認路徑
    }
    
    // 使用extension方法獲取皮膚
    final skin = npcConfig.getSkinById(skinId);
    if (skin?.videosPath != null) {
      return skin!.videosPath!;
    }
    
    // 使用NPC路徑 + 皮膚ID
    return 'assets/npcs/$npcId/$skinId/';
  }
  
  /// 刷新所有皮膚解鎖狀態（當親密度或購買狀態變化時調用）
  Future<void> refreshUnlockStatus() async {
    final allNPCs = NPCRawConfigService.instance.getAllNPCs();
    
    for (final npcConfig in allNPCs) {
      final npcId = npcConfig['id'] as String;
      final skins = npcConfig.skins;  // 使用extension方法
      
      for (final skin in skins) {
        // 重新檢查每個皮膚的解鎖狀態
        isSkinUnlocked(npcId, skin.id);
      }
    }
    
    LoggerUtils.debug('已刷新所有NPC皮膚解鎖狀態');
  }
  
  /// 清除用戶數據
  Future<void> clearUserData() async {
    // 取消Firestore監聽
    _skinListener?.cancel();
    _skinListener = null;
    
    // 皮膚數據現在由GameProgressService管理
    // 清除操作應該通過GameProgressService進行
    var progress = _progressService.getProgress();
    if (progress != null) {
      progress.selectedNPCSkins.clear();
      progress.unlockedNPCSkins.clear();
      await _progressService.saveProgress(progress);
    }
    LoggerUtils.info('已清除皮膚選擇數據');
  }
  
  /// 銷毀服務時清理資源
  void dispose() {
    _skinListener?.cancel();
    _skinListener = null;
    _skinChangesController.close();
  }
}

/// 皮膚信息（包含解鎖和選擇狀態）
class SkinInfo {
  final NPCSkin skin;
  final bool isUnlocked;
  final bool isSelected;
  
  SkinInfo({
    required this.skin,
    required this.isUnlocked,
    required this.isSelected,
  });
}
import 'npc_raw_config_service.dart';
import 'intimacy_service.dart';
import 'purchase_service.dart';
import 'game_progress_service.dart';
import '../models/npc_skin.dart';
import '../utils/logger_utils.dart';

/// NPC皮膚管理服務
class NPCSkinService {
  static NPCSkinService? _instance;
  static NPCSkinService get instance => _instance ??= NPCSkinService._();
  
  NPCSkinService._();
  
  // 使用GameProgressService作為數據源
  GameProgressService get _progressService => GameProgressService.instance;
  
  bool _isInitialized = false;
  
  /// 初始化服務
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 確保原始配置已加載
      await NPCRawConfigService.instance.ensureLoaded();
      
      // 從GameProgressService加載數據
      await _progressService.loadProgress();
      
      _isInitialized = true;
      LoggerUtils.info('NPCSkinService 初始化成功');
    } catch (e) {
      LoggerUtils.error('NPCSkinService 初始化失敗: $e');
    }
  }
  
  /// 獲取NPC當前選擇的皮膚ID
  int getSelectedSkinId(String npcId) {
    final progress = _progressService.getProgress();
    if (progress == null) return 1;
    return progress.selectedNPCSkins[npcId] ?? 1;  // 默認使用ID為1的皮膚
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
    
    LoggerUtils.info('已選擇皮膚: NPC=$npcId, Skin=$skinId');
    return true;
  }
  
  /// 檢查皮膚是否已解鎖
  bool isSkinUnlocked(String npcId, int skinId) {
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
    
    // 如果是默認皮膚，總是解鎖
    if (skin.unlockCondition.type == 'default') {
      // 異步標記，但立即返回true
      _markSkinUnlocked(npcId, skinId);
      return true;
    }
    
    // 檢查解鎖條件
    final unlocked = checkUnlockCondition(npcId, skin.unlockCondition);
    if (unlocked) {
      // 異步標記，但立即返回結果
      _markSkinUnlocked(npcId, skinId);
    }
    
    return unlocked;
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
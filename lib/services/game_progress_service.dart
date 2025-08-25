import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'storage/local_storage_service.dart';
import 'storage/cloud_storage_service.dart';
import '../models/game_state.dart';
import '../utils/logger_utils.dart';
import '../l10n/generated/app_localizations.dart';

/// 游戏进度服务 - 专门处理GameProgress的双向同步
/// 这是唯一需要本地和云端同步的数据
class GameProgressService {
  static GameProgressService? _instance;
  static GameProgressService get instance => _instance ??= GameProgressService._();
  
  GameProgressService._();
  
  final LocalStorageService _local = LocalStorageService.instance;
  final CloudStorageService _cloud = CloudStorageService.instance;
  
  // 缓存的游戏进度
  GameProgressData? _cachedProgress;
  
  // 同步锁，防止并发同步
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  
  /// 获取当前用户ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  
  /// 设置用户ID（同步设置到LocalStorageService）
  void setUserId(String userId) {
    _local.setUserId(userId);
    LoggerUtils.info('GameProgressService: 设置用户ID为 $userId');
  }
  
  /// 初始化服务
  Future<void> initialize() async {
    LoggerUtils.info('GameProgressService: 初始化');
    
    // 如果有用户登录，设置用户ID并加载进度
    if (currentUserId != null) {
      setUserId(currentUserId!);
      await loadProgress();
    }
  }
  
  /// 加载游戏进度（优先本地，必要时从云端同步）
  Future<GameProgressData?> loadProgress() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        LoggerUtils.warning('GameProgressService: 无法加载进度，用户未登录');
        return null;
      }
      
      // 1. 尝试从本地加载
      final localJson = await _local.getJson('game_progress');
      GameProgressData? localProgress;
      if (localJson != null) {
        localProgress = GameProgressData.fromJson(localJson);
      }
      
      // 2. 尝试从云端加载
      final cloudJson = await _cloud.getGameProgress();
      GameProgressData? cloudProgress;
      if (cloudJson != null) {
        cloudProgress = GameProgressData.fromJson(cloudJson);
      }
      
      // 3. 智能合并
      _cachedProgress = await _mergeProgress(localProgress, cloudProgress);
      
      return _cachedProgress;
    } catch (e) {
      LoggerUtils.error('GameProgressService: 加载进度失败 $e');
      return null;
    }
  }
  
  /// 保存游戏进度
  Future<void> saveProgress(GameProgressData progress) async {
    try {
      LoggerUtils.info('GameProgressService.saveProgress: 开始保存进度');
      LoggerUtils.info('  - 当前总局数: ${progress.totalGames}');
      LoggerUtils.info('  - 上次同步时间: ${progress.lastSyncTime}');
      
      // 关键：更新lastUpdated时间戳
      progress.lastUpdated = DateTime.now();
      
      // 缓存
      _cachedProgress = progress;
      
      // 保存到本地
      await _saveToLocal(progress);
      LoggerUtils.info('  - 本地保存成功');
      
      // 决定是否需要同步到云端
      final shouldSync = await _shouldSyncToCloud(progress);
      LoggerUtils.info('  - 是否需要同步: $shouldSync');
      
      if (shouldSync) {
        LoggerUtils.info('  - 开始同步到云端...');
        await syncToCloud();
      }
    } catch (e) {
      LoggerUtils.error('GameProgressService: 保存进度失败 $e');
    }
  }
  
  /// 更新游戏结果（替代原 PlayerProfile.learnFromGame）
  Future<void> updateGameResult(
    GameRound round, 
    bool playerWon, 
    String aiId,
  ) async {
    LoggerUtils.info('GameProgressService.updateGameResult: 开始更新游戏结果');
    LoggerUtils.info('  - 玩家${playerWon ? "胜利" : "失败"}，对手: $aiId');
    
    // 获取或创建进度
    var progress = _cachedProgress ?? GameProgressData(userId: currentUserId ?? '');
    LoggerUtils.info('  - 更新前: 总局数=${progress.totalGames}, 胜=${progress.totalWins}, 负=${progress.totalLosses}');
    
    // 更新基础统计
    progress.totalGames++;
    if (playerWon) {
      progress.totalWins++;
      progress.currentWinStreak++;
      if (progress.currentWinStreak > progress.highestWinStreak) {
        progress.highestWinStreak = progress.currentWinStreak;
      }
    } else {
      progress.totalLosses++;
      progress.currentWinStreak = 0;
      progress.totalDrinks++;
    }
    
    // 更新与特定NPC的战绩
    _updateVsNPCRecord(progress, aiId, playerWon);
    
    // 分析游戏回合，更新玩家风格
    _analyzeGameRound(progress, round, playerWon);
    
    LoggerUtils.info('  - 更新后: 总局数=${progress.totalGames}, 胜=${progress.totalWins}, 负=${progress.totalLosses}');
    LoggerUtils.info('  - 玩家风格: 虚张=${progress.bluffingTendency.toStringAsFixed(2)}, 激进=${progress.aggressiveness.toStringAsFixed(2)}');
    
    // 关键：更新lastUpdated时间戳
    progress.lastUpdated = DateTime.now();
    
    // 注意：亲密度增长只在NPC喝醉时通过addNpcIntimacy处理
    // 普通游戏不增加亲密度，保持与IntimacyService同步
    
    // 检查成就
    _checkAchievements(progress);
    
    // 保存
    await saveProgress(progress);
  }
  
  /// 增加NPC亲密度
  Future<void> addNpcIntimacy(String npcId, int points) async {
    var progress = _cachedProgress ?? GameProgressData(userId: currentUserId ?? '');
    
    final currentIntimacy = progress.npcIntimacy[npcId] ?? 0;
    progress.npcIntimacy[npcId] = currentIntimacy + points;
    
    // 检查是否解锁新等级
    final newLevel = _calculateIntimacyLevel(currentIntimacy + points);
    final oldLevel = _calculateIntimacyLevel(currentIntimacy);
    
    if (newLevel > oldLevel) {
      LoggerUtils.info('NPC $npcId 亲密度升级: $oldLevel -> $newLevel');
      // 可以触发升级事件
    }
    
    await saveProgress(progress);
  }
  
  /// 记录NPC喝醉（替代原 PlayerProfile.recordAIDrunk）
  Future<void> recordNPCDrunk(String npcId) async {
    var progress = _cachedProgress ?? GameProgressData(userId: currentUserId ?? '');
    
    // 更新vsNPCRecords中的醉酒统计
    if (!progress.vsNPCRecords.containsKey(npcId)) {
      progress.vsNPCRecords[npcId] = {
        'totalGames': 0,
        'wins': 0,
        'losses': 0,
        'playerDrunkCount': 0,
        'aiDrunkCount': 0,
      };
    }
    
    progress.vsNPCRecords[npcId]!['aiDrunkCount'] = 
        (progress.vsNPCRecords[npcId]!['aiDrunkCount'] ?? 0) + 1;
    
    LoggerUtils.info('记录NPC $npcId 喝醉，累计 ${progress.vsNPCRecords[npcId]!['aiDrunkCount']} 次');
    
    await saveProgress(progress);
  }
  
  /// 记录玩家喝醉（替代原 PlayerProfile.recordPlayerDrunk）
  Future<void> recordPlayerDrunk(String npcId) async {
    var progress = _cachedProgress ?? GameProgressData(userId: currentUserId ?? '');
    
    // 更新vsNPCRecords中的醉酒统计
    if (!progress.vsNPCRecords.containsKey(npcId)) {
      progress.vsNPCRecords[npcId] = {
        'totalGames': 0,
        'wins': 0,
        'losses': 0,
        'playerDrunkCount': 0,
        'aiDrunkCount': 0,
      };
    }
    
    progress.vsNPCRecords[npcId]!['playerDrunkCount'] = 
        (progress.vsNPCRecords[npcId]!['playerDrunkCount'] ?? 0) + 1;
    
    LoggerUtils.info('记录玩家被NPC $npcId 喝醉，累计 ${progress.vsNPCRecords[npcId]!['playerDrunkCount']} 次');
    
    await saveProgress(progress);
  }
  
  /// 获取缓存的进度数据（供 IntimacyService 使用）
  GameProgressData? getCachedProgress() => _cachedProgress;
  
  /// 获取NPC亲密度
  int getNpcIntimacy(String npcId) {
    return _cachedProgress?.npcIntimacy[npcId] ?? 0;
  }
  
  /// 获取NPC亲密度等级
  int getNpcIntimacyLevel(String npcId) {
    final intimacy = getNpcIntimacy(npcId);
    return _calculateIntimacyLevel(intimacy);
  }
  
  /// 手动同步到云端
  Future<bool> syncToCloud() async {
    LoggerUtils.info('GameProgressService.syncToCloud: 检查同步条件');
    LoggerUtils.info('  - cachedProgress: ${_cachedProgress != null}');
    LoggerUtils.info('  - currentUserId: $currentUserId');
    LoggerUtils.info('  - isSyncing: $_isSyncing');
    
    if (_cachedProgress == null || currentUserId == null) {
      LoggerUtils.warning('GameProgressService: 无法同步 - 缓存或用户ID为空');
      return false;
    }
    
    // 防止重复同步
    if (_isSyncing) {
      LoggerUtils.info('GameProgressService: 同步正在进行中');
      return false;
    }
    
    // 限制同步频率
    if (_lastSyncTime != null && 
        DateTime.now().difference(_lastSyncTime!).inSeconds < 5) {
      LoggerUtils.info('GameProgressService: 同步频率过高');
      return false;
    }
    
    // 调用内部同步方法
    return await _syncToCloud(_cachedProgress!);
  }
  
  /// 清除本地进度
  Future<void> clearLocalProgress() async {
    _cachedProgress = null;
    await _local.remove('game_progress');
    LoggerUtils.info('GameProgressService: 本地进度已清除');
  }
  
  /// 记录看广告醒酒
  Future<void> recordAdSober({String? npcId}) async {
    LoggerUtils.info('GameProgressService.recordAdSober: 记录看广告醒酒');
    
    // 获取或创建进度
    var progress = _cachedProgress ?? GameProgressData(userId: currentUserId ?? '');
    
    if (npcId != null) {
      // 为NPC看广告醒酒
      LoggerUtils.info('  - 为NPC $npcId 看广告醒酒');
      
      // 确保NPC记录存在
      if (!progress.vsNPCRecords.containsKey(npcId)) {
        progress.vsNPCRecords[npcId] = {
          'totalGames': 0,
          'wins': 0,
          'losses': 0,
          'playerDrunkCount': 0,
          'aiDrunkCount': 0,
          'adSoberForNPC': 0,
          'adUnlockForNPC': 0,
        };
      }
      
      final record = progress.vsNPCRecords[npcId]!;
      record['adSoberForNPC'] = (record['adSoberForNPC'] ?? 0) + 1;
      LoggerUtils.info('  - NPC $npcId 累计被看广告醒酒 ${record['adSoberForNPC']} 次');
    } else {
      // 玩家自己看广告醒酒
      progress.adSoberCount++;
      LoggerUtils.info('  - 玩家累计看广告醒酒 ${progress.adSoberCount} 次');
    }
    
    // 更新时间戳并保存
    progress.lastUpdated = DateTime.now();
    await saveProgress(progress);
  }
  
  /// 记录看广告解锁VIP
  Future<void> recordAdUnlockVIP(String npcId) async {
    LoggerUtils.info('GameProgressService.recordAdUnlockVIP: 记录看广告解锁VIP');
    LoggerUtils.info('  - 为NPC $npcId 看广告解锁VIP');
    
    // 获取或创建进度
    var progress = _cachedProgress ?? GameProgressData(userId: currentUserId ?? '');
    
    // 确保NPC记录存在
    if (!progress.vsNPCRecords.containsKey(npcId)) {
      progress.vsNPCRecords[npcId] = {
        'totalGames': 0,
        'wins': 0,
        'losses': 0,
        'playerDrunkCount': 0,
        'aiDrunkCount': 0,
        'adSoberForNPC': 0,
        'adUnlockForNPC': 0,
      };
    }
    
    final record = progress.vsNPCRecords[npcId]!;
    record['adUnlockForNPC'] = (record['adUnlockForNPC'] ?? 0) + 1;
    LoggerUtils.info('  - NPC $npcId 累计被看广告解锁 ${record['adUnlockForNPC']} 次');
    
    // 更新时间戳并保存
    progress.lastUpdated = DateTime.now();
    await saveProgress(progress);
  }
  
  // === 私有方法 ===
  
  /// 保存到本地
  Future<void> _saveToLocal(GameProgressData progress) async {
    await _local.setJson('game_progress', progress.toJson());
  }
  
  /// 更新与特定NPC的战绩
  void _updateVsNPCRecord(GameProgressData progress, String npcId, bool playerWon) {
    if (!progress.vsNPCRecords.containsKey(npcId)) {
      progress.vsNPCRecords[npcId] = {
        'totalGames': 0,
        'wins': 0,
        'losses': 0,
        'playerDrunkCount': 0,
        'aiDrunkCount': 0,
        'adSoberForNPC': 0,
        'adUnlockForNPC': 0,
      };
    }
    
    final record = progress.vsNPCRecords[npcId]!;
    record['totalGames'] = (record['totalGames'] ?? 0) + 1;
    
    if (playerWon) {
      record['wins'] = (record['wins'] ?? 0) + 1;
    } else {
      record['losses'] = (record['losses'] ?? 0) + 1;
    }
  }
  
  /// 分析游戏回合，更新玩家风格
  void _analyzeGameRound(GameProgressData progress, GameRound round, bool playerWon) {
    if (round.bidHistory.isEmpty) return;
    
    // 简化的分析：只更新核心的4个指标
    int totalBids = 0;
    int bluffBids = 0;
    int aggressiveBids = 0;
    
    // 确定谁先叫牌
    bool firstIsPlayer = !round.isPlayerTurn;
    
    // 分析玩家的叫牌
    for (int i = 0; i < round.bidHistory.length; i++) {
      bool isPlayerBid = firstIsPlayer ? (i % 2 == 0) : (i % 2 == 1);
      
      if (isPlayerBid) {
        totalBids++;
        Bid bid = round.bidHistory[i];
        
        // 检查虚张
        int actualCount = round.playerDice.countValue(
          bid.value, 
          onesAreCalled: round.onesAreCalled
        );
        if (actualCount < bid.quantity / 2) {
          bluffBids++;
        }
        
        // 检查激进叫牌（数量增加超过2）
        if (i > 0) {
          Bid prevBid = round.bidHistory[i - 1];
          if (bid.quantity - prevBid.quantity > 2) {
            aggressiveBids++;
          }
        }
      }
    }
    
    // 更新玩家风格（使用指数移动平均）
    const double learningRate = 0.1;
    
    if (totalBids > 0) {
      // 虚张倾向
      double currentBluffRate = bluffBids.toDouble() / totalBids;
      progress.bluffingTendency = progress.bluffingTendency * (1 - learningRate) + 
                                  currentBluffRate * learningRate;
      
      // 激进程度
      double currentAggressiveness = aggressiveBids.toDouble() / totalBids;
      progress.aggressiveness = progress.aggressiveness * (1 - learningRate) + 
                               currentAggressiveness * learningRate;
    }
    
    // 质疑率（如果玩家发起了质疑）
    if (!playerWon && round.currentBid != null) {
      // 玩家质疑了AI
      progress.challengeRate = progress.challengeRate * (1 - learningRate) + 
                              1.0 * learningRate;
    } else {
      // 玩家没有质疑
      progress.challengeRate = progress.challengeRate * (1 - learningRate);
    }
    
    // 可预测性（基于行为的一致性，这里简化处理）
    progress.predictability = 0.5; // 暂时固定，可以后续优化
  }
  
  /// 处理云端到本地的同步
  Future<void> _handleCloudToLocalSync(GameProgressData cloudData) async {
    final syncTime = DateTime.now();
    cloudData.lastSyncTime = syncTime;
    cloudData.lastSyncDirection = 'cloud-to-local';
    
    // 保存到本地
    await _saveToLocal(cloudData);
    
    // 更新云端的同步信息
    await _cloud.saveGameProgress({
      ...cloudData.toFirestore(),
      'lastSyncTime': syncTime,
      'lastSyncDirection': 'cloud-to-local',
    });
    
    LoggerUtils.info('  - 已更新本地和云端的同步信息 (cloud-to-local)');
  }
  
  /// 合并本地和云端进度
  Future<GameProgressData?> _mergeProgress(
    GameProgressData? local,
    GameProgressData? cloud,
  ) async {
    // 都没有数据，创建新的
    if (local == null && cloud == null) {
      return GameProgressData(userId: currentUserId ?? '');
    }
    
    // 只有本地数据（可能是首次同步或云端数据丢失）
    if (local != null && cloud == null) {
      // 验证本地数据的用户ID是否匹配当前登录用户
      if (local.userId != currentUserId) {
        LoggerUtils.warning('GameProgressService: 本地数据用户ID不匹配（本地: ${local.userId}, 当前: $currentUserId），创建新进度');
        await clearLocalProgress();
        return GameProgressData(userId: currentUserId ?? '');
      }
      
      LoggerUtils.info('GameProgressService: 使用本地进度（云端无数据）');
      LoggerUtils.info('  数据详情: ${local.totalGames}局游戏, 最后更新: ${local.lastUpdated}');
      
      // 立即同步到云端
      await _syncToCloud(local);
      return local;
    }
    
    // 只有云端数据（新设备或重装应用）
    if (local == null && cloud != null) {
      LoggerUtils.info('GameProgressService: 使用云端进度（本地无数据，可能是新设备）');
      await _handleCloudToLocalSync(cloud);
      return cloud;
    }
    
    // 都有数据，基于lastUpdated时间戳判断
    // 注意：这里local和cloud都不为null，已经在前面的条件中处理了
    final localTime = local!.lastUpdated;
    final cloudTime = cloud!.lastUpdated;
    
    LoggerUtils.info('GameProgressService: 同步冲突解决');
    LoggerUtils.info('  本地时间戳: $localTime');
    LoggerUtils.info('  云端时间戳: $cloudTime');
    
    if (localTime.isAfter(cloudTime)) {
      // 本地更新，需要同步到云端
      LoggerUtils.info('  决策: 使用本地版本（更新）');
      // 立即同步到云端
      await _syncToCloud(local);
      return local;
    } else if (cloudTime.isAfter(localTime)) {
      // 云端更新（可能是其他设备修改）
      LoggerUtils.info('  决策: 使用云端版本（更新）');
      await _handleCloudToLocalSync(cloud);
      return cloud;
    } else {
      // 时间戳相同（极少见），比较游戏局数
      if (local.totalGames >= cloud.totalGames) {
        LoggerUtils.info('  决策: 时间戳相同，使用本地版本（局数更多）');
        return local;
      } else {
        LoggerUtils.info('  决策: 时间戳相同，使用云端版本（局数更多）');
        await _handleCloudToLocalSync(cloud);
        return cloud;
      }
    }
  }
  
  /// 判断是否需要同步到云端
  Future<bool> _shouldSyncToCloud(GameProgressData progress) async {
    if (currentUserId == null) return false;
    
    // 每5局游戏同步一次
    if (progress.totalGames > 0 && progress.totalGames % 5 == 0) {
      LoggerUtils.info('GameProgressService: 触发同步 - 每5局游戏（当前第${progress.totalGames}局）');
      return true;
    }
    
    // 破纪录时同步
    if (progress.currentWinStreak == progress.highestWinStreak && 
        progress.highestWinStreak > 0) {
      LoggerUtils.info('GameProgressService: 触发同步 - 破连胜纪录（${progress.highestWinStreak}连胜）');
      return true;
    }
    
    // 距离上次同步超过5分钟
    if (progress.lastSyncTime != null) {
      final minutesSinceSync = DateTime.now().difference(progress.lastSyncTime!).inMinutes;
      if (minutesSinceSync >= 5) {
        LoggerUtils.info('GameProgressService: 触发同步 - 距离上次同步已${minutesSinceSync}分钟');
        return true;
      }
    } else {
      // 如果从未同步过，立即同步
      LoggerUtils.info('GameProgressService: 触发同步 - 首次同步');
      return true;
    }
    
    // 获得新成就时同步
    // 这里需要记录上次的成就数量来判断
    
    return false;
  }
  
  /// 计算亲密度等级
  int _calculateIntimacyLevel(int intimacyPoints) {
    if (intimacyPoints < 100) return 1;
    if (intimacyPoints < 300) return 2;
    if (intimacyPoints < 600) return 3;
    if (intimacyPoints < 1000) return 4;
    if (intimacyPoints < 1500) return 5;
    if (intimacyPoints < 2100) return 6;
    if (intimacyPoints < 2800) return 7;
    if (intimacyPoints < 3600) return 8;
    if (intimacyPoints < 4500) return 9;
    return 10;
  }
  
  /// 检查成就
  void _checkAchievements(GameProgressData progress) {
    // 首胜成就
    if (progress.totalWins == 1 && !progress.achievements.contains('first_win')) {
      progress.achievements.add('first_win');
      LoggerUtils.info('获得成就: 首次胜利');
    }
    
    // 10连胜成就
    if (progress.currentWinStreak >= 10 && !progress.achievements.contains('win_streak_10')) {
      progress.achievements.add('win_streak_10');
      LoggerUtils.info('获得成就: 10连胜');
    }
    
    // 100场游戏成就
    if (progress.totalGames >= 100 && !progress.achievements.contains('games_100')) {
      progress.achievements.add('games_100');
      LoggerUtils.info('获得成就: 百战老兵');
    }
    
    // 更多成就...
  }
  
  /// 内部同步方法
  Future<bool> _syncToCloud(GameProgressData progress) async {
    try {
      _isSyncing = true;
      
      // 记录同步时间
      final syncTime = DateTime.now();
      
      // 创建要同步的数据（包含更新的同步信息）
      final dataToSync = {
        ...progress.toFirestore(),
        'lastSyncTime': syncTime,
        'lastSyncDirection': 'local-to-cloud',
      };
      
      // 保存到云端
      final success = await _cloud.saveGameProgress(dataToSync);
      
      if (success) {
        // 只在成功后更新本地的同步信息
        progress.lastSyncTime = syncTime;
        progress.lastSyncDirection = 'local-to-cloud';
        _lastSyncTime = syncTime;
        
        LoggerUtils.info('GameProgressService: 成功同步到云端 (local-to-cloud)');
        // 更新本地缓存的同步时间
        await _saveToLocal(progress);
      } else {
        LoggerUtils.error('GameProgressService: 同步到云端失败');
      }
      
      return success;
    } catch (e) {
      LoggerUtils.error('GameProgressService: 同步异常 $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }
  
  /// 重置游戏进度
  Future<void> resetProgress() async {
    try {
      final userId = currentUserId;
      if (userId == null) return;
      
      // 创建新的空进度
      final newProgress = GameProgressData(userId: userId);
      
      // 保存到本地和云端
      await saveProgress(newProgress);
      
      LoggerUtils.info('GameProgressService: 已重置游戏进度');
    } catch (e) {
      LoggerUtils.error('GameProgressService: 重置进度失败 $e');
    }
  }
}

/// 游戏进度数据模型
class GameProgressData {
  String userId;
  int totalGames;
  int totalWins;
  int totalLosses;
  int currentWinStreak;
  int highestWinStreak;
  int totalDrinks;
  int adSoberCount; // 看广告醒酒次数（玩家自己）
  Map<String, int> npcIntimacy; // NPC ID -> 亲密度点数
  List<String> unlockedNPCs;
  List<String> achievements;
  
  // 玩家风格数据
  double bluffingTendency;    // 虚张倾向 (0-1)
  double aggressiveness;      // 激进程度 (0-1)
  double challengeRate;       // 质疑率 (0-1)
  double predictability;      // 可预测性 (0-1)
  
  // 额外的统计字段（为了兼容旧代码）
  int totalChallenges;        // 总质疑次数
  int successfulChallenges;   // 成功质疑次数
  
  // 与每个NPC的战绩统计
  Map<String, Map<String, int>> vsNPCRecords; // NPC ID -> 战绩数据
  
  // 关键时间戳字段
  DateTime lastUpdated;      // 数据最后修改时间（用于同步判断）
  DateTime? lastSyncTime;    // 最后成功同步的时间
  String? lastSyncDirection; // 最后同步方向: 'local-to-cloud' 或 'cloud-to-local'
  
  GameProgressData({
    required this.userId,
    this.totalGames = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.currentWinStreak = 0,
    this.highestWinStreak = 0,
    this.totalDrinks = 0,
    this.adSoberCount = 0,
    Map<String, int>? npcIntimacy,
    List<String>? unlockedNPCs,
    List<String>? achievements,
    this.bluffingTendency = 0.5,
    this.aggressiveness = 0.5,
    this.challengeRate = 0.5,
    this.predictability = 0.5,
    this.totalChallenges = 0,
    this.successfulChallenges = 0,
    Map<String, Map<String, int>>? vsNPCRecords,
    DateTime? lastUpdated,
    this.lastSyncTime,
    this.lastSyncDirection,
  }) : npcIntimacy = npcIntimacy ?? {},
       unlockedNPCs = unlockedNPCs ?? [],
       achievements = achievements ?? [],
       vsNPCRecords = vsNPCRecords ?? {},
       lastUpdated = lastUpdated ?? DateTime.now();
  
  // 本地存储序列化（使用 UTC 字符串）
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'totalGames': totalGames,
    'totalWins': totalWins,
    'totalLosses': totalLosses,
    'currentWinStreak': currentWinStreak,
    'highestWinStreak': highestWinStreak,
    'totalDrinks': totalDrinks,
    'adSoberCount': adSoberCount,
    'npcIntimacy': npcIntimacy,
    'unlockedNPCs': unlockedNPCs,
    'achievements': achievements,
    'bluffingTendency': bluffingTendency,
    'aggressiveness': aggressiveness,
    'challengeRate': challengeRate,
    'predictability': predictability,
    'totalChallenges': totalChallenges,
    'successfulChallenges': successfulChallenges,
    'vsNPCRecords': vsNPCRecords,
    // 使用 UTC 时间存储，避免时区问题
    'lastUpdated': lastUpdated.toUtc().toIso8601String(),
    'lastSyncTime': lastSyncTime?.toUtc().toIso8601String(),
    'lastSyncDirection': lastSyncDirection,
  };
  
  // 云端存储序列化（使用 DateTime 对象）
  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'totalGames': totalGames,
    'totalWins': totalWins,
    'totalLosses': totalLosses,
    'currentWinStreak': currentWinStreak,
    'highestWinStreak': highestWinStreak,
    'totalDrinks': totalDrinks,
    'adSoberCount': adSoberCount,
    'npcIntimacy': npcIntimacy,
    'unlockedNPCs': unlockedNPCs,
    'achievements': achievements,
    'bluffingTendency': bluffingTendency,
    'aggressiveness': aggressiveness,
    'challengeRate': challengeRate,
    'predictability': predictability,
    'totalChallenges': totalChallenges,
    'successfulChallenges': successfulChallenges,
    'vsNPCRecords': vsNPCRecords,
    // Firestore 会自动处理 DateTime 对象
    'lastUpdated': lastUpdated,
    'lastSyncTime': lastSyncTime,
    'lastSyncDirection': lastSyncDirection,
  };
  
  // 解析vsNPCRecords
  static Map<String, Map<String, int>> _parseVsNPCRecords(dynamic json) {
    if (json == null) return {};
    
    Map<String, Map<String, int>> result = {};
    if (json is Map<String, dynamic>) {
      json.forEach((key, value) {
        if (value is Map) {
          result[key] = Map<String, int>.from(value);
        }
      });
    }
    return result;
  }
  
  /// 获取玩家风格描述（本地化版本）
  String getStyleDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (totalGames == 0) return l10n.styleNovice;
    
    List<String> traits = [];
    
    // 基于虚张倾向
    if (bluffingTendency > 0.7) {
      traits.add(l10n.styleBluffMaster);
    } else if (bluffingTendency > 0.5) {
      traits.add(l10n.styleBluffer);
    } else if (bluffingTendency < 0.3) {
      traits.add(l10n.styleHonest);
    }
    
    // 基于激进程度
    if (aggressiveness > 0.7) {
      traits.add(l10n.styleAggressive);
    } else if (aggressiveness > 0.5) {
      traits.add(l10n.styleOffensive);
    } else if (aggressiveness < 0.3) {
      traits.add(l10n.styleConservative);
    }
    
    // 基于质疑率
    if (challengeRate > 0.5) {
      traits.add(l10n.styleChallenger);
    } else if (challengeRate < 0.2) {
      traits.add(l10n.styleCautious);
    }
    
    return traits.isEmpty ? l10n.styleBalanced : traits.join(' & ');
  }
  
  /// 获取胜率
  double getWinRate() {
    if (totalGames == 0) return 0;
    return totalWins.toDouble() / totalGames;
  }
  
  /// 获取与特定NPC的胜率
  double getVsNPCWinRate(String npcId) {
    final record = vsNPCRecords[npcId];
    if (record == null) return 0;
    
    final total = (record['totalGames'] ?? 0);
    if (total == 0) return 0;
    
    final wins = (record['wins'] ?? 0);
    return wins.toDouble() / total;
  }
  
  /// 获取与特定NPC的战绩
  Map<String, int> getVsNPCRecord(String npcId) {
    return vsNPCRecords[npcId] ?? {
      'totalGames': 0,
      'wins': 0,
      'losses': 0,
      'playerDrunkCount': 0,
      'aiDrunkCount': 0,
      'adSoberForNPC': 0,  // 为这个NPC看广告醒酒的次数
      'adUnlockForNPC': 0,  // 为这个NPC看广告解锁VIP的次数
    };
  }
  
  // 解析日期时间（兼容 Firestore Timestamp 和字符串格式）
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    // 如果是 Firestore Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }
    
    // 如果是 DateTime 对象
    if (value is DateTime) {
      return value;
    }
    
    // 如果是字符串（ISO 8601 格式）
    if (value is String) {
      // parse 会自动识别 UTC 时间（带 Z 后缀）并转换为本地时间
      return DateTime.parse(value);
    }
    
    return null;
  }
  
  // JSON反序列化
  factory GameProgressData.fromJson(Map<String, dynamic> json) {
    return GameProgressData(
      userId: json['userId'] ?? '',
      totalGames: json['totalGames'] ?? 0,
      totalWins: json['totalWins'] ?? 0,
      totalLosses: json['totalLosses'] ?? 0,
      currentWinStreak: json['currentWinStreak'] ?? 0,
      highestWinStreak: json['highestWinStreak'] ?? 0,
      totalDrinks: json['totalDrinks'] ?? 0,
      adSoberCount: json['adSoberCount'] ?? 0,
      npcIntimacy: Map<String, int>.from(json['npcIntimacy'] ?? {}),
      unlockedNPCs: List<String>.from(json['unlockedNPCs'] ?? []),
      achievements: List<String>.from(json['achievements'] ?? []),
      bluffingTendency: (json['bluffingTendency'] ?? 0.5).toDouble(),
      aggressiveness: (json['aggressiveness'] ?? 0.5).toDouble(),
      challengeRate: (json['challengeRate'] ?? 0.5).toDouble(),
      predictability: (json['predictability'] ?? 0.5).toDouble(),
      totalChallenges: json['totalChallenges'] ?? 0,
      successfulChallenges: json['successfulChallenges'] ?? 0,
      vsNPCRecords: _parseVsNPCRecords(json['vsNPCRecords']),
      lastUpdated: _parseDateTime(json['lastUpdated']) ?? DateTime.now(),
      lastSyncTime: _parseDateTime(json['lastSyncTime']),
      lastSyncDirection: json['lastSyncDirection'],
    );
  }
}
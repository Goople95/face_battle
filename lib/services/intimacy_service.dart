import '../models/intimacy_data.dart';
import '../utils/logger_utils.dart';
import 'game_progress_service.dart';

/// 亲密度服务 - GameProgressService 的轻量级包装器
/// 保持原有 API 不变，内部调用 GameProgressService
/// 不再使用本地独立的 intimacy_xxxx 存储
class IntimacyService {
  static final IntimacyService _instance = IntimacyService._internal();
  factory IntimacyService() => _instance;
  IntimacyService._internal();

  String? _currentUserId;
  
  void setUserId(String userId) {
    _currentUserId = userId;
    // GameProgressService 会自动处理用户 ID
  }

  /// 获取 NPC 的亲密度数据
  /// 从 GameProgressService 获取数据并转换为 IntimacyData 格式
  IntimacyData getIntimacy(String npcId) {
    final points = GameProgressService.instance.getNpcIntimacy(npcId);
    final level = GameProgressService.instance.getNpcIntimacyLevel(npcId);
    
    // 从 GameProgress 获取战绩数据
    final progress = GameProgressService.instance.getCachedProgress();
    final vsRecord = progress?.vsNPCRecords[npcId] ?? {};
    
    return IntimacyData(
      npcId: npcId,
      intimacyPoints: points,
      lastInteraction: DateTime.now(), // 这个字段已不重要
      totalGames: (vsRecord['wins'] ?? 0) + (vsRecord['losses'] ?? 0),
      wins: vsRecord['wins'] ?? 0,
      losses: vsRecord['losses'] ?? 0,
    );
  }

  /// 更新亲密度（内部方法，不对外暴露）
  Future<void> _updateIntimacy(String npcId, int pointsToAdd) async {
    await GameProgressService.instance.addNpcIntimacy(npcId, pointsToAdd);
    LoggerUtils.info('NPC $npcId 获得 $pointsToAdd 亲密度点数');
  }

  /// 添加亲密度点数
  Future<void> addIntimacyPoints(String npcId, int points, {String? reason}) async {
    final oldLevel = GameProgressService.instance.getNpcIntimacyLevel(npcId);
    
    await _updateIntimacy(npcId, points);
    
    final newLevel = GameProgressService.instance.getNpcIntimacyLevel(npcId);
    if (newLevel > oldLevel) {
      _onLevelUp(npcId, oldLevel, newLevel);
    }
    
    LoggerUtils.info('NPC $npcId 获得 $points 亲密度点数${reason != null ? " (原因: $reason)" : ""}');
  }

  /// 记录 NPC 喝醉后的亲密度增长
  Future<bool> recordNPCDrunk(String npcId, int minutesSpentTogether) async {
    final oldLevel = GameProgressService.instance.getNpcIntimacyLevel(npcId);
    
    // 每分钟 = 1点亲密度
    // 20-60分钟对应20-60点亲密度
    int pointsToAdd = minutesSpentTogether;
    
    // 使用 GameProgressService 更新亲密度（内部会处理升级日志）
    await GameProgressService.instance.addNpcIntimacy(npcId, pointsToAdd);
    
    // 检测是否升级
    final newLevel = GameProgressService.instance.getNpcIntimacyLevel(npcId);
    bool leveledUp = newLevel > oldLevel;
    
    final currentPoints = GameProgressService.instance.getNpcIntimacy(npcId);
    LoggerUtils.info('与醉酒的 $npcId 独处了 $minutesSpentTogether 分钟，获得 $pointsToAdd 亲密度');
    LoggerUtils.info('当前亲密度: $currentPoints (等级: $newLevel)');
    
    return leveledUp;
  }

  /// 亲密度升级回调
  void _onLevelUp(String npcId, int oldLevel, int newLevel) {
    LoggerUtils.info('NPC $npcId 亲密度升级！$oldLevel -> $newLevel');
    // 可以在这里添加升级奖励或通知
  }

  /// 获取所有 NPC 的亲密度数据
  Map<String, IntimacyData> getAllIntimacyData() {
    final progress = GameProgressService.instance.getCachedProgress();
    if (progress == null) return {};
    
    final Map<String, IntimacyData> result = {};
    for (final entry in progress.npcIntimacy.entries) {
      result[entry.key] = getIntimacy(entry.key);
    }
    return result;
  }

  /// 获取亲密度最高的 NPC
  List<IntimacyData> getTopIntimacyNPCs({int limit = 5}) {
    final allData = getAllIntimacyData().values.toList();
    allData.sort((a, b) => b.intimacyPoints.compareTo(a.intimacyPoints));
    return allData.take(limit).toList();
  }

  /// 检查亲密度等级是否满足要求
  bool checkIntimacyRequirement(String npcId, int requiredLevel) {
    final level = GameProgressService.instance.getNpcIntimacyLevel(npcId);
    return level >= requiredLevel;
  }

  /// 重置 NPC 的亲密度
  Future<void> resetIntimacy(String npcId) async {
    final progress = GameProgressService.instance.getCachedProgress();
    if (progress != null) {
      progress.npcIntimacy[npcId] = 0;
      await GameProgressService.instance.saveProgress(progress);
      LoggerUtils.info('重置NPC $npcId 的亲密度数据');
    }
  }

  /// 清除所有本地数据（已废弃，因为数据由 GameProgressService 管理）
  Future<void> clearAllLocalData() async {
    LoggerUtils.info('IntimacyService.clearAllLocalData 已废弃，数据由 GameProgressService 管理');
    // 不再需要清除独立的 intimacy_xxxx 文件
  }
}
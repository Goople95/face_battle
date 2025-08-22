import 'storage/local_storage_service.dart';
import '../models/temp_game_state.dart';
import '../utils/logger_utils.dart';

/// 临时状态服务 - 管理纯本地的游戏临时状态
/// 这些数据不会同步到云端，仅存在于本地设备
class TempStateService {
  static TempStateService? _instance;
  static TempStateService get instance => _instance ??= TempStateService._();
  
  TempStateService._();
  
  final LocalStorageService _localStorage = LocalStorageService.instance;
  
  // 缓存的临时状态
  TempGameState? _cachedState;
  
  /// 获取临时状态
  Future<TempGameState> getState() async {
    // 如果有缓存，先处理醒酒
    if (_cachedState != null) {
      _cachedState!.processSobering();
      return _cachedState!;
    }
    
    // 从本地加载
    await loadState();
    return _cachedState!;
  }
  
  /// 加载临时状态
  Future<TempGameState> loadState() async {
    try {
      final json = await _localStorage.getJson('temp_game_state');
      
      if (json != null) {
        _cachedState = TempGameState.fromJson(json);
        LoggerUtils.info('TempStateService: 加载临时状态成功');
      } else {
        _cachedState = TempGameState();
        LoggerUtils.info('TempStateService: 创建新的临时状态');
      }
      
      // 处理自然醒酒
      _cachedState!.processSobering();
      
      return _cachedState!;
    } catch (e) {
      LoggerUtils.error('TempStateService: 加载临时状态失败 $e');
      _cachedState = TempGameState();
      return _cachedState!;
    }
  }
  
  /// 保存临时状态
  Future<void> saveState([TempGameState? state]) async {
    try {
      final stateToSave = state ?? _cachedState;
      if (stateToSave == null) {
        LoggerUtils.warning('TempStateService: 没有状态需要保存');
        return;
      }
      
      await _localStorage.setJson('temp_game_state', stateToSave.toJson());
      LoggerUtils.debug('TempStateService: 临时状态已保存');
    } catch (e) {
      LoggerUtils.error('TempStateService: 保存临时状态失败 $e');
    }
  }
  
  /// 玩家喝酒
  Future<void> playerDrink() async {
    final state = await getState();
    state.playerDrink();
    await saveState(state);
  }
  
  /// AI喝酒
  Future<void> aiDrink(String aiId, int capacity) async {
    final state = await getState();
    state.aiDrink(aiId, capacity);
    await saveState(state);
  }
  
  /// 使用醒酒药水
  Future<bool> useSoberPotion() async {
    final state = await getState();
    final success = state.useSoberPotion();
    if (success) {
      await saveState(state);
    }
    return success;
  }
  
  /// 看广告醒酒玩家
  Future<void> watchAdToSoberPlayer() async {
    final state = await getState();
    state.watchAdToSober();
    await saveState(state);
  }
  
  /// AI看广告醒酒
  Future<void> watchAdToSoberAI(String aiId) async {
    final state = await getState();
    state.aiWatchAdToSober(aiId);
    await saveState(state);
  }
  
  /// 获取玩家喝酒数
  Future<int> getPlayerDrinks() async {
    final state = await getState();
    return state.currentPlayerDrinks;
  }
  
  /// 获取AI喝酒数
  Future<int> getAIDrinks(String aiId) async {
    final state = await getState();
    return state.aiStates[aiId]?.currentDrinks ?? 0;
  }
  
  /// 获取玩家状态描述
  Future<String> getPlayerStatusDescription() async {
    final state = await getState();
    return state.getPlayerStatusDescription();
  }
  
  /// 获取下次醒酒剩余秒数
  Future<int> getNextSoberSeconds() async {
    final state = await getState();
    return state.getNextSoberSeconds();
  }
  
  /// 增加醒酒药水
  Future<void> addSoberPotion(int count) async {
    final state = await getState();
    state.soberPotions += count;
    await saveState(state);
  }
  
  /// 更新会话统计
  Future<void> updateSessionStats({bool? playerWon}) async {
    final state = await getState();
    
    if (playerWon != null) {
      if (playerWon) {
        state.currentSessionWins++;
      } else {
        state.currentSessionLosses++;
      }
    }
    
    await saveState(state);
  }
  
  /// 获取会话统计
  Future<Map<String, int>> getSessionStats() async {
    final state = await getState();
    return {
      'wins': state.currentSessionWins,
      'losses': state.currentSessionLosses,
    };
  }
  
  /// 重置会话统计
  Future<void> resetSessionStats() async {
    final state = await getState();
    state.currentSessionWins = 0;
    state.currentSessionLosses = 0;
    state.sessionStartTime = DateTime.now();
    await saveState(state);
  }
  
  /// 清除临时状态
  Future<void> clearState() async {
    _cachedState = null;
    await _localStorage.remove('temp_game_state');
    LoggerUtils.info('TempStateService: 临时状态已清除');
  }
  
  /// 从旧的DrinkingState迁移数据
  Future<void> migrateFromDrinkingState(Map<String, dynamic> oldData) async {
    try {
      final state = await getState();
      
      // 迁移玩家喝酒数据
      if (oldData['drinksConsumed'] != null) {
        state.currentPlayerDrinks = oldData['drinksConsumed'];
      }
      
      if (oldData['playerLastDrinkTime'] != null) {
        state.playerLastDrinkTime = DateTime.tryParse(oldData['playerLastDrinkTime']);
      }
      
      if (oldData['soberPotions'] != null) {
        state.soberPotions = oldData['soberPotions'];
      }
      
      // 迁移AI喝酒数据
      if (oldData['aiDrinks'] != null) {
        final aiDrinks = oldData['aiDrinks'] as Map<String, dynamic>;
        for (var entry in aiDrinks.entries) {
          state.aiStates[entry.key] = AITempState(
            currentDrinks: entry.value,
          );
        }
      }
      
      if (oldData['aiLastDrinkTimes'] != null) {
        final aiTimes = oldData['aiLastDrinkTimes'] as Map<String, dynamic>;
        for (var entry in aiTimes.entries) {
          if (state.aiStates.containsKey(entry.key) && entry.value != null) {
            state.aiStates[entry.key]!.lastDrinkTime = DateTime.tryParse(entry.value);
          }
        }
      }
      
      await saveState(state);
      LoggerUtils.info('TempStateService: 数据迁移完成');
    } catch (e) {
      LoggerUtils.error('TempStateService: 数据迁移失败 $e');
    }
  }
}
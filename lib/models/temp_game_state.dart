import '../utils/logger_utils.dart';

/// 临时游戏状态模型 - 纯本地存储，不同步到云端
/// 包含当前游戏会话的临时数据
class TempGameState {
  // ========== 玩家当前状态 ==========
  int currentPlayerDrinks;      // 当前喝酒数（0-6）
  DateTime? playerLastDrinkTime; // 最后喝酒时间（用于醒酒计算）
  int soberPotions;             // 醒酒药水数量
  
  // ========== AI当前状态 ==========
  Map<String, AITempState> aiStates; // AI ID -> 临时状态
  
  // ========== 游戏会话信息 ==========
  int currentSessionWins;       // 本次会话胜利数
  int currentSessionLosses;     // 本次会话失败数
  DateTime sessionStartTime;    // 会话开始时间
  
  TempGameState({
    this.currentPlayerDrinks = 0,
    this.playerLastDrinkTime,
    this.soberPotions = 0,
    Map<String, AITempState>? aiStates,
    this.currentSessionWins = 0,
    this.currentSessionLosses = 0,
    DateTime? sessionStartTime,
  }) : aiStates = aiStates ?? {},
       sessionStartTime = sessionStartTime ?? DateTime.now();
  
  /// 玩家喝酒
  void playerDrink() {
    if (currentPlayerDrinks < 6) {
      currentPlayerDrinks++;
      playerLastDrinkTime = DateTime.now();
      LoggerUtils.info('玩家喝酒: $currentPlayerDrinks/6');
    }
  }
  
  /// AI喝酒
  void aiDrink(String aiId, int capacity) {
    if (!aiStates.containsKey(aiId)) {
      aiStates[aiId] = AITempState();
    }
    
    final state = aiStates[aiId]!;
    if (state.currentDrinks < capacity) {
      state.currentDrinks++;
      state.lastDrinkTime = DateTime.now();
      LoggerUtils.info('AI $aiId 喝酒: ${state.currentDrinks}/$capacity');
    }
  }
  
  /// 处理自然醒酒（每10分钟减少1杯）
  void processSobering() {
    final now = DateTime.now();
    
    // 玩家醒酒
    if (playerLastDrinkTime != null && currentPlayerDrinks > 0) {
      final minutesPassed = now.difference(playerLastDrinkTime!).inMinutes;
      final soberingAmount = minutesPassed ~/ 10;
      
      if (soberingAmount > 0) {
        currentPlayerDrinks = (currentPlayerDrinks - soberingAmount).clamp(0, 6);
        if (currentPlayerDrinks == 0) {
          playerLastDrinkTime = null;
          LoggerUtils.info('玩家完全清醒');
        } else {
          // 更新时间，保留余数分钟
          playerLastDrinkTime = now.subtract(Duration(minutes: minutesPassed % 10));
          LoggerUtils.info('玩家自然醒酒: $currentPlayerDrinks/6');
        }
      }
    }
    
    // AI醒酒
    aiStates.forEach((aiId, state) {
      if (state.lastDrinkTime != null && state.currentDrinks > 0) {
        final minutesPassed = now.difference(state.lastDrinkTime!).inMinutes;
        final soberingAmount = minutesPassed ~/ 10;
        
        if (soberingAmount > 0) {
          state.currentDrinks = (state.currentDrinks - soberingAmount).clamp(0, 10);
          if (state.currentDrinks == 0) {
            state.lastDrinkTime = null;
            LoggerUtils.info('AI $aiId 完全清醒');
          } else {
            state.lastDrinkTime = now.subtract(Duration(minutes: minutesPassed % 10));
            LoggerUtils.info('AI $aiId 自然醒酒: ${state.currentDrinks}');
          }
        }
      }
    });
  }
  
  /// 使用醒酒药水
  bool useSoberPotion() {
    if (soberPotions > 0 && currentPlayerDrinks > 0) {
      soberPotions--;
      currentPlayerDrinks = (currentPlayerDrinks - 2).clamp(0, 6);
      LoggerUtils.info('使用醒酒药水，当前: $currentPlayerDrinks/6');
      return true;
    }
    return false;
  }
  
  /// 看广告完全醒酒
  void watchAdToSober() {
    currentPlayerDrinks = 0;
    playerLastDrinkTime = null;
    LoggerUtils.info('看广告醒酒成功');
  }
  
  /// AI看广告醒酒
  void aiWatchAdToSober(String aiId) {
    if (aiStates.containsKey(aiId)) {
      aiStates[aiId]!.currentDrinks = 0;
      aiStates[aiId]!.lastDrinkTime = null;
      LoggerUtils.info('AI $aiId 看广告醒酒成功');
    }
  }
  
  /// 获取玩家醉酒状态描述
  String getPlayerStatusDescription() {
    if (currentPlayerDrinks == 0) return '清醒状态';
    if (currentPlayerDrinks == 1) return '小酌一杯';
    if (currentPlayerDrinks == 2) return '略有酒意';
    if (currentPlayerDrinks == 3) return '微醺状态';
    if (currentPlayerDrinks == 4) return '明显醉意';
    if (currentPlayerDrinks == 5) return '醉意朦胧';
    return '烂醉如泥';
  }
  
  /// 获取下次醒酒剩余秒数
  int getNextSoberSeconds() {
    if (playerLastDrinkTime == null || currentPlayerDrinks == 0) return 0;
    final secondsPassed = DateTime.now().difference(playerLastDrinkTime!).inSeconds;
    return 600 - (secondsPassed % 600); // 10分钟 = 600秒
  }
  
  /// 转换为JSON（用于本地存储）
  Map<String, dynamic> toJson() {
    return {
      'currentPlayerDrinks': currentPlayerDrinks,
      'playerLastDrinkTime': playerLastDrinkTime?.toIso8601String(),
      'soberPotions': soberPotions,
      'aiStates': aiStates.map((k, v) => MapEntry(k, v.toJson())),
      'currentSessionWins': currentSessionWins,
      'currentSessionLosses': currentSessionLosses,
      'sessionStartTime': sessionStartTime.toIso8601String(),
    };
  }
  
  /// 从JSON创建
  factory TempGameState.fromJson(Map<String, dynamic> json) {
    return TempGameState(
      currentPlayerDrinks: json['currentPlayerDrinks'] ?? 0,
      playerLastDrinkTime: json['playerLastDrinkTime'] != null
          ? DateTime.parse(json['playerLastDrinkTime'])
          : null,
      soberPotions: json['soberPotions'] ?? 0,
      aiStates: (json['aiStates'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, AITempState.fromJson(v)),
      ) ?? {},
      currentSessionWins: json['currentSessionWins'] ?? 0,
      currentSessionLosses: json['currentSessionLosses'] ?? 0,
      sessionStartTime: json['sessionStartTime'] != null
          ? DateTime.parse(json['sessionStartTime'])
          : DateTime.now(),
    );
  }
}

/// AI的临时状态
class AITempState {
  int currentDrinks;      // 当前喝酒数
  DateTime? lastDrinkTime; // 最后喝酒时间
  bool isDrunkState;      // 是否处于醉酒状态（曾经达到最大酒量）
  
  AITempState({
    this.currentDrinks = 0,
    this.lastDrinkTime,
    this.isDrunkState = false,
  });
  
  Map<String, dynamic> toJson() => {
    'currentDrinks': currentDrinks,
    'lastDrinkTime': lastDrinkTime?.toIso8601String(),
    'isDrunkState': isDrunkState,
  };
  
  factory AITempState.fromJson(Map<String, dynamic> json) => AITempState(
    currentDrinks: json['currentDrinks'] ?? 0,
    lastDrinkTime: json['lastDrinkTime'] != null
        ? DateTime.parse(json['lastDrinkTime'])
        : null,
    isDrunkState: json['isDrunkState'] ?? false,
  );
}
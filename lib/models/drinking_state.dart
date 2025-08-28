import 'package:flutter/material.dart';
import '../services/temp_state_service.dart';
import '../models/temp_game_state.dart';
import '../services/npc_config_service.dart';
import '../utils/logger_utils.dart';
import '../l10n/generated/app_localizations.dart';

/// 饮酒状态管理（支持动态酒量）
class DrinkingState {
  static const int playerMaxDrinks = 6; // 玩家固定酒量6杯
  static const int maxDrinks = playerMaxDrinks; // 兼容旧代码
  
  int drinksConsumed = 0; // 玩家已喝酒杯数
  Map<String, int> aiDrinks = {}; // 每个AI的酒杯数
  Map<String, bool> aiDrunkStates = {}; // 每个AI的醉酒状态（是否曾经达到最大酒量）
  DateTime? lastDrinkTime; // 最后喝酒时间
  DateTime? playerLastDrinkTime; // 玩家最后喝酒时间
  Map<String, DateTime?> aiLastDrinkTimes = {}; // 每个AI的最后喝酒时间
  int soberPotions = 0; // 醒酒药水数量
  
  // NPC配置服务
  final _npcService = NPCConfigService();
  
  DrinkingState() {
    // 不在构造函数中初始化AI状态，让loadFromPrefs来处理
    // 这样可以避免覆盖从存储载入的数据
    
    // 兼容旧ID格式
    _initLegacyIds();
  }
  
  void _initLegacyIds() {
    // 不再初始化旧的字符串ID，只使用数字ID
  }
  
  // 获取AI的实际酒量
  int _getAICapacity(String aiId) {
    // 只使用ID从配置服务获取NPC
    var npc = _npcService.getNPCById(aiId);
    if (npc != null) {
      return npc.drinkCapacity;
    }
    
    // 默认酒量
    return 4;
  }
  
  /// 玩家是否醉酒（达到最大酒量）
  bool get isDrunk => drinksConsumed >= playerMaxDrinks;
  
  /// 玩家是否不能游戏（达到最大酒量）
  bool get isUnavailable => drinksConsumed >= playerMaxDrinks;
  
  /// 特定AI是否醉酒（达到其最大酒量）
  bool isAIDrunk(String aiId) {
    int capacity = _getAICapacity(aiId);
    return (aiDrinks[aiId] ?? 0) >= capacity;
  }
  
  /// 特定AI是否不能游戏（达到最大酒量时不能游戏）
  bool isAIUnavailable(String aiId) {
    // 简单规则：只有当AI当前达到其最大酒量时才不能游戏
    int capacity = _getAICapacity(aiId);
    int currentDrinks = aiDrinks[aiId] ?? 0;
    
    // 只有当前达到最大酒量时才不能游戏
    return currentDrinks >= capacity;
  }
  
  /// 获取特定AI的酒杯数
  int getAIDrinks(String aiId) => aiDrinks[aiId] ?? 0;
  
  /// 获取玩家下次醒酒的剩余分钟数
  int getPlayerNextSoberMinutes() {
    if (playerLastDrinkTime == null || drinksConsumed == 0) return 0;
    final minutesPassed = DateTime.now().difference(playerLastDrinkTime!).inMinutes;
    final nextSoberMinutes = 10 - (minutesPassed % 10);
    return nextSoberMinutes == 10 ? 0 : nextSoberMinutes;
  }
  
  /// 获取AI下次醒酒的剩余分钟数
  int getAINextSoberMinutes(String aiId) {
    if (aiLastDrinkTimes[aiId] == null || (aiDrinks[aiId] ?? 0) == 0) return 0;
    final minutesPassed = DateTime.now().difference(aiLastDrinkTimes[aiId]!).inMinutes;
    final nextSoberMinutes = 10 - (minutesPassed % 10);
    return nextSoberMinutes == 10 ? 0 : nextSoberMinutes;
  }
  
  /// 获取AI下次醒酒的剩余秒数
  int getAINextSoberSeconds(String aiId) {
    if (aiLastDrinkTimes[aiId] == null || (aiDrinks[aiId] ?? 0) == 0) return 0;
    final secondsPassed = DateTime.now().difference(aiLastDrinkTimes[aiId]!).inSeconds;
    final nextSoberSeconds = 600 - (secondsPassed % 600); // 10分钟 = 600秒
    return nextSoberSeconds;
  }
  
  /// 获取玩家下次醒酒的剩余秒数
  int getPlayerNextSoberSeconds() {
    if (playerLastDrinkTime == null || drinksConsumed == 0) return 0;
    final secondsPassed = DateTime.now().difference(playerLastDrinkTime!).inSeconds;
    final nextSoberSeconds = 600 - (secondsPassed % 600); // 10分钟 = 600秒
    return nextSoberSeconds;
  }
  
  /// 玩家是否微醺（喝了一半以上）
  bool get isTipsy => drinksConsumed >= (playerMaxDrinks / 2) && !isDrunk;
  
  /// 特定AI是否微醺
  bool isAITipsy(String aiId) {
    int capacity = _getAICapacity(aiId);
    int drinks = aiDrinks[aiId] ?? 0;
    return drinks >= (capacity / 2) && drinks < capacity;
  }
  
  /// 玩家是否清醒
  bool get isSober => drinksConsumed < (playerMaxDrinks / 2);
  
  /// 特定AI是否清醒
  bool isAISober(String aiId) {
    int capacity = _getAICapacity(aiId);
    return (aiDrinks[aiId] ?? 0) < (capacity / 2);
  }
  
  /// 玩家醉酒程度百分比
  double get drunkLevel => (drinksConsumed / playerMaxDrinks).clamp(0.0, 1.0);
  
  /// 特定AI醉酒程度百分比
  double getAIDrunkLevel(String aiId) {
    int capacity = _getAICapacity(aiId);
    return ((aiDrinks[aiId] ?? 0) / capacity).clamp(0.0, 1.0);
  }
  
  /// 获取玩家状态描述（需要传入context以获取本地化文本）
  String getStatusDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return statusDescription; // 如果没有context，返回默认值
    
    if (isDrunk) return l10n.drunkStatusDeadDrunk;
    if (drinksConsumed >= 5) return l10n.drunkStatusDizzy;
    if (drinksConsumed >= 4) return l10n.drunkStatusObvious;
    if (drinksConsumed >= 3) return l10n.drunkStatusTipsy;
    if (drinksConsumed >= 2) return l10n.drunkStatusSlightly;
    if (drinksConsumed >= 1) return l10n.drunkStatusOneDrink;
    return l10n.drunkStatusSober;
  }
  
  /// 获取玩家状态描述（兼容旧代码）
  String get statusDescription {
    if (isDrunk) return '烂醉如泥';
    if (drinksConsumed >= 5) return '醉意朦胧';
    if (drinksConsumed >= 4) return '明显醉意';
    if (drinksConsumed >= 3) return '微醺状态';
    if (drinksConsumed >= 2) return '略有酒意';
    if (drinksConsumed >= 1) return '小酌一杯';
    return '清醒状态';
  }
  
  /// 获取特定AI状态描述
  String getAIStatusDescription(String aiId) {
    int capacity = _getAICapacity(aiId);
    int drinks = aiDrinks[aiId] ?? 0;
    double ratio = drinks / capacity;
    
    if (ratio >= 1.0) return '烂醉如泥';
    if (ratio >= 0.8) return '醉意朦胧';
    if (ratio >= 0.6) return '明显醉意';
    if (ratio >= 0.4) return '微醺状态';
    if (ratio >= 0.2) return '略有酒意';
    if (drinks >= 1) return '小酌一杯';
    return '清醒状态';
  }
  
  /// 获取玩家状态表情
  String get statusEmoji {
    if (isDrunk) return '🥴';
    if (drinksConsumed >= 5) return '😵';
    if (drinksConsumed >= 4) return '🤪';
    if (drinksConsumed >= 3) return '🥺';
    if (drinksConsumed >= 2) return '😊';
    if (drinksConsumed >= 1) return '🍺';
    return '😎';
  }
  
  /// 获取特定AI状态表情
  String getAIStatusEmoji(String aiId) {
    int capacity = _getAICapacity(aiId);
    int drinks = aiDrinks[aiId] ?? 0;
    double ratio = drinks / capacity;
    
    if (ratio >= 1.0) return '🥴';
    if (ratio >= 0.8) return '😵';
    if (ratio >= 0.6) return '🤪';
    if (ratio >= 0.4) return '🥺';
    if (ratio >= 0.2) return '😊';
    if (drinks >= 1) return '🍺';
    return '😎';
  }
  
  /// 玩家喝一杯酒（输了游戏）
  void playerDrink() {
    if (drinksConsumed < playerMaxDrinks) {
      drinksConsumed++;
      lastDrinkTime = DateTime.now();
      if (playerLastDrinkTime == null || drinksConsumed == 1) {
        playerLastDrinkTime = DateTime.now();
      }
    }
  }
  
  /// 特定AI喝一杯酒（输了游戏）
  void aiDrink(String aiId) {
    int capacity = _getAICapacity(aiId);
    aiDrinks[aiId] ??= 0;
    
    if (aiDrinks[aiId]! < capacity) {
      aiDrinks[aiId] = aiDrinks[aiId]! + 1;
      lastDrinkTime = DateTime.now();
      if (aiLastDrinkTimes[aiId] == null || aiDrinks[aiId] == 1) {
        aiLastDrinkTimes[aiId] = DateTime.now();
      }
      
      // 如果达到最大酒量，标记为醉酒状态
      if (aiDrinks[aiId]! >= capacity) {
        aiDrunkStates[aiId] = true;
        LoggerUtils.info('AI $aiId 醉酒了（达到最大酒量 $capacity 杯）');
      }
    }
  }
  
  /// 玩家赢了游戏（对特定AI）
  void playerWin(String aiId) {
    aiDrink(aiId);
  }
  
  /// AI赢了游戏
  void aiWin(String aiId) {
    playerDrink();
  }
  
  /// 使用醒酒药水
  bool useSoberPotion() {
    if (soberPotions > 0) {
      soberPotions--;
      drinksConsumed = (drinksConsumed - 2).clamp(0, playerMaxDrinks);
      return true;
    }
    return false;
  }
  
  /// 看广告醒酒玩家
  void watchAdToSoberPlayer() {
    drinksConsumed = 0;
    playerLastDrinkTime = null;
  }
  
  /// 看广告醒酒特定AI
  void watchAdToSoberAI(String aiId) {
    aiDrinks[aiId] = 0;
    aiLastDrinkTimes[aiId] = null;
    aiDrunkStates[aiId] = false;  // 清除醉酒状态
  }
  
  /// 喝酒（简单接口，用于DataStorageService）
  void drink() {
    playerDrink();
  }
  
  /// 醒酒一杯（简单接口，用于DataStorageService）
  void soberUp() {
    if (drinksConsumed > 0) {
      drinksConsumed--;
      if (drinksConsumed == 0) {
        playerLastDrinkTime = null;
      }
    }
  }
  
  /// 自然醒酒（每10分钟减少1杯）
  void processSobering() {
    final now = DateTime.now();
    
    // 玩家醒酒
    if (playerLastDrinkTime != null && drinksConsumed > 0) {
      final minutesPassed = now.difference(playerLastDrinkTime!).inMinutes;
      final soberingAmount = minutesPassed ~/ 10;
      if (soberingAmount > 0) {
        drinksConsumed = (drinksConsumed - soberingAmount).clamp(0, playerMaxDrinks);
        if (drinksConsumed == 0) {
          playerLastDrinkTime = null;
        } else {
          playerLastDrinkTime = now.subtract(Duration(minutes: minutesPassed % 10));
        }
      }
    }
    
    // AI醒酒
    for (var aiId in aiDrinks.keys) {
      if (aiLastDrinkTimes[aiId] != null && (aiDrinks[aiId] ?? 0) > 0) {
        final minutesPassed = now.difference(aiLastDrinkTimes[aiId]!).inMinutes;
        final soberingAmount = minutesPassed ~/ 10;
        if (soberingAmount > 0) {
          int capacity = _getAICapacity(aiId);
          aiDrinks[aiId] = ((aiDrinks[aiId] ?? 0) - soberingAmount).clamp(0, capacity);
          if (aiDrinks[aiId] == 0) {
            aiLastDrinkTimes[aiId] = null;
            aiDrunkStates[aiId] = false;  // 清除醉酒状态
          } else {
            aiLastDrinkTimes[aiId] = now.subtract(Duration(minutes: minutesPassed % 10));
          }
        }
      }
    }
  }
  
  /// 保存状态到LocalStorage
  Future<void> saveToPrefs() async {
    // 使用TempStateService保存临时状态
    final tempService = TempStateService.instance;
    final state = await tempService.getState();
    
    // 更新玩家状态
    state.currentPlayerDrinks = drinksConsumed;
    state.playerLastDrinkTime = playerLastDrinkTime;
    state.soberPotions = soberPotions;
    
    // 更新AI状态
    for (var entry in aiDrinks.entries) {
      // 只保存数字ID的AI（如 "0001", "0002" 等）
      if (RegExp(r'^\d+$').hasMatch(entry.key)) {
        state.aiStates[entry.key] = AITempState(
          currentDrinks: entry.value,
          lastDrinkTime: aiLastDrinkTimes[entry.key],
          isDrunkState: aiDrunkStates[entry.key] ?? false,
        );
      }
    }
    
    await tempService.saveState(state);
    LoggerUtils.info('饮酒状态已保存');
  }
  
  /// 从LocalStorage加载状态
  Future<void> loadFromPrefs() async {
    // 使用TempStateService加载临时状态
    final tempService = TempStateService.instance;
    final state = await tempService.loadState();
    
    // 加载玩家状态
    drinksConsumed = state.currentPlayerDrinks;
    playerLastDrinkTime = state.playerLastDrinkTime;
    soberPotions = state.soberPotions;
    
    // 先初始化所有AI的默认状态（对于新增的NPC）
    for (var npc in _npcService.allCharacters) {
      // 使用putIfAbsent确保不覆盖已有数据
      aiDrinks.putIfAbsent(npc.id, () => 0);
      aiDrunkStates.putIfAbsent(npc.id, () => false);
      aiLastDrinkTimes.putIfAbsent(npc.id, () => null);
    }
    
    // 加载AI状态（覆盖默认值）
    // 遍历保存的状态，更新已保存的AI数据
    for (var entry in state.aiStates.entries) {
      aiDrinks[entry.key] = entry.value.currentDrinks;
      aiLastDrinkTimes[entry.key] = entry.value.lastDrinkTime;
      aiDrunkStates[entry.key] = entry.value.isDrunkState;
      LoggerUtils.debug('加载AI状态 - ID: ${entry.key}, 饮酒数: ${entry.value.currentDrinks}, 醉酒状态: ${entry.value.isDrunkState}');
    }
    
    // 处理醒酒
    processSobering();
    
    LoggerUtils.info('饮酒状态已加载 - 玩家: $drinksConsumed杯, AI数量: ${aiDrinks.length}');
  }
  
  /// 兼容旧方法名：加载状态（实例方法）
  Future<void> load() async {
    await loadFromPrefs();
  }
  
  /// 兼容旧方法名：保存状态
  Future<void> save() async {
    await saveToPrefs();
  }
  
  /// 更新醒酒状态
  void updateSoberStatus() {
    processSobering();
  }
  
  /// 静态加载方法（兼容旧代码）
  static Future<DrinkingState> loadStatic() async {
    final state = DrinkingState();
    await state.loadFromPrefs();
    return state;
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() => {
    'drinksConsumed': drinksConsumed,
    'aiDrinks': aiDrinks,
    'lastDrinkTime': lastDrinkTime?.toIso8601String(),
    'playerLastDrinkTime': playerLastDrinkTime?.toIso8601String(),
    'aiLastDrinkTimes': aiLastDrinkTimes.map((k, v) => 
        MapEntry(k, v?.toIso8601String())),
    'soberPotions': soberPotions,
  };
  
  /// 从JSON创建
  factory DrinkingState.fromJson(Map<String, dynamic> json) {
    final state = DrinkingState();
    state.drinksConsumed = json['drinksConsumed'] ?? 0;
    
    if (json['aiDrinks'] != null) {
      state.aiDrinks = Map<String, int>.from(json['aiDrinks']);
    }
    
    if (json['lastDrinkTime'] != null) {
      state.lastDrinkTime = DateTime.parse(json['lastDrinkTime']);
    }
    
    if (json['playerLastDrinkTime'] != null) {
      state.playerLastDrinkTime = DateTime.parse(json['playerLastDrinkTime']);
    }
    
    if (json['aiLastDrinkTimes'] != null) {
      Map<String, dynamic> times = json['aiLastDrinkTimes'];
      state.aiLastDrinkTimes = times.map((k, v) => 
          MapEntry(k, v != null ? DateTime.parse(v) : null));
    }
    
    state.soberPotions = json['soberPotions'] ?? 0;
    
    return state;
  }
}
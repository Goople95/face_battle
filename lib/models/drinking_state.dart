import 'package:shared_preferences/shared_preferences.dart';
import '../services/npc_config_service.dart';

/// 饮酒状态管理（支持动态酒量）
class DrinkingState {
  static const int playerMaxDrinks = 6; // 玩家固定酒量6杯
  static const int maxDrinks = playerMaxDrinks; // 兼容旧代码
  
  int drinksConsumed = 0; // 玩家已喝酒杯数
  Map<String, int> aiDrinks = {}; // 每个AI的酒杯数
  DateTime? lastDrinkTime; // 最后喝酒时间
  DateTime? playerLastDrinkTime; // 玩家最后喝酒时间
  Map<String, DateTime?> aiLastDrinkTimes = {}; // 每个AI的最后喝酒时间
  int soberPotions = 0; // 醒酒药水数量
  int totalLosses = 0; // 总失败次数
  int consecutiveLosses = 0; // 连续失败次数
  
  // NPC配置服务
  final _npcService = NPCConfigService();
  
  DrinkingState() {
    // 初始化所有AI的酒杯数
    for (var npc in _npcService.allCharacters) {
      aiDrinks[npc.id] = 0;
      aiLastDrinkTimes[npc.id] = null;
    }
    
    // 兼容旧ID格式
    _initLegacyIds();
  }
  
  void _initLegacyIds() {
    // 兼容旧的字符串ID
    aiDrinks['professor'] ??= 0;
    aiDrinks['gambler'] ??= 0;
    aiDrinks['provocateur'] ??= 0;
    aiDrinks['youngwoman'] ??= 0;
    aiDrinks['aki'] ??= 0;
    aiDrinks['katerina'] ??= 0;
    aiDrinks['lena'] ??= 0;
  }
  
  // 获取AI的实际酒量
  int _getAICapacity(String aiId) {
    // 尝试从配置服务获取NPC
    var npc = _npcService.getNPCById(aiId);
    if (npc != null) {
      return npc.drinkCapacity;
    }
    
    // 兼容旧ID格式
    switch (aiId) {
      case 'professor':
        return _npcService.professor.drinkCapacity;
      case 'gambler':
        return _npcService.gambler.drinkCapacity;
      case 'provocateur':
        return _npcService.provocateur.drinkCapacity;
      case 'youngwoman':
        return _npcService.youngwoman.drinkCapacity;
      case 'aki':
        return _npcService.aki.drinkCapacity;
      case 'katerina':
        return _npcService.katerina.drinkCapacity;
      case 'lena':
        return _npcService.lena.drinkCapacity;
      default:
        return 4; // 默认酒量
    }
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
  
  /// 特定AI是否不能游戏（有任何酒杯就不能游戏，必须完全清醒）
  bool isAIUnavailable(String aiId) {
    // 根据规则：一旦喝酒进入醉酒流程，必须完全清醒（0杯）才能继续游戏
    return (aiDrinks[aiId] ?? 0) > 0;
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
  
  /// 获取玩家状态描述
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
      consecutiveLosses++;
      totalLosses++;
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
    }
  }
  
  /// 玩家赢了游戏（对特定AI）
  void playerWin(String aiId) {
    consecutiveLosses = 0;
    aiDrink(aiId);
  }
  
  /// AI赢了游戏
  void aiWin(String aiId) {
    consecutiveLosses++;
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
    consecutiveLosses = 0;
    playerLastDrinkTime = null;
  }
  
  /// 看广告醒酒特定AI
  void watchAdToSoberAI(String aiId) {
    aiDrinks[aiId] = 0;
    aiLastDrinkTimes[aiId] = null;
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
          } else {
            aiLastDrinkTimes[aiId] = now.subtract(Duration(minutes: minutesPassed % 10));
          }
        }
      }
    }
  }
  
  /// 保存状态到SharedPreferences
  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('playerDrinks', drinksConsumed);
    await prefs.setInt('totalLosses', totalLosses);
    await prefs.setInt('consecutiveLosses', consecutiveLosses);
    await prefs.setInt('soberPotions', soberPotions);
    
    if (playerLastDrinkTime != null) {
      await prefs.setString('playerLastDrinkTime', playerLastDrinkTime!.toIso8601String());
    }
    
    // 保存每个AI的状态
    for (var entry in aiDrinks.entries) {
      await prefs.setInt('ai_drinks_${entry.key}', entry.value);
      if (aiLastDrinkTimes[entry.key] != null) {
        await prefs.setString('ai_last_drink_${entry.key}', 
            aiLastDrinkTimes[entry.key]!.toIso8601String());
      }
    }
  }
  
  /// 从SharedPreferences加载状态
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    drinksConsumed = prefs.getInt('playerDrinks') ?? 0;
    totalLosses = prefs.getInt('totalLosses') ?? 0;
    consecutiveLosses = prefs.getInt('consecutiveLosses') ?? 0;
    soberPotions = prefs.getInt('soberPotions') ?? 0;
    
    final playerDrinkTimeStr = prefs.getString('playerLastDrinkTime');
    if (playerDrinkTimeStr != null) {
      playerLastDrinkTime = DateTime.tryParse(playerDrinkTimeStr);
    }
    
    // 加载每个AI的状态
    for (var aiId in aiDrinks.keys) {
      aiDrinks[aiId] = prefs.getInt('ai_drinks_$aiId') ?? 0;
      final drinkTimeStr = prefs.getString('ai_last_drink_$aiId');
      if (drinkTimeStr != null) {
        aiLastDrinkTimes[aiId] = DateTime.tryParse(drinkTimeStr);
      }
    }
    
    // 处理醒酒
    processSobering();
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
}
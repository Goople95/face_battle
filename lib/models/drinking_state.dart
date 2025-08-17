import 'package:shared_preferences/shared_preferences.dart';

/// 饮酒状态管理
class DrinkingState {
  static const int maxDrinks = 6; // 最多喝6杯就醉了
  static const int soberThreshold = 3; // 3杯以下算清醒，3杯及以上微醺不能游戏
  
  int drinksConsumed = 0; // 玩家已喝酒杯数
  Map<String, int> aiDrinks = {
    'professor': 0,
    'gambler': 0,
    'provocateur': 0,
    'youngwoman': 0,
  }; // 每个AI的酒杯数
  DateTime? lastDrinkTime; // 最后喝酒时间
  DateTime? playerLastDrinkTime; // 玩家最后喝酒时间
  Map<String, DateTime?> aiLastDrinkTimes = {
    'professor': null,
    'gambler': null,
    'provocateur': null,
    'youngwoman': null,
  }; // 每个AI的最后喝酒时间
  int soberPotions = 0; // 醒酒药水数量
  int totalLosses = 0; // 总失败次数
  int consecutiveLosses = 0; // 连续失败次数
  
  DrinkingState();
  
  /// 玩家是否醉酒（6杯）
  bool get isDrunk => drinksConsumed >= maxDrinks;
  
  /// 玩家是否不能游戏（3杯以上微醺）
  bool get isUnavailable => drinksConsumed >= soberThreshold;
  
  /// 特定AI是否醉酒（失去战斗力）
  bool isAIDrunk(String aiId) => (aiDrinks[aiId] ?? 0) >= maxDrinks;
  
  /// 特定AI是否不能游戏（3杯以上微醺）
  bool isAIUnavailable(String aiId) => (aiDrinks[aiId] ?? 0) >= soberThreshold;
  
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
  
  /// 玩家是否微醺（影响判断）
  bool get isTipsy => drinksConsumed >= soberThreshold && !isDrunk;
  
  /// 特定AI是否微醺
  bool isAITipsy(String aiId) => (aiDrinks[aiId] ?? 0) >= soberThreshold && !isAIDrunk(aiId);
  
  /// 玩家是否清醒
  bool get isSober => drinksConsumed < soberThreshold;
  
  /// 特定AI是否清醒
  bool isAISober(String aiId) => (aiDrinks[aiId] ?? 0) < soberThreshold;
  
  /// 玩家醉酒程度百分比
  double get drunkLevel => (drinksConsumed / maxDrinks).clamp(0.0, 1.0);
  
  /// 特定AI醉酒程度百分比
  double getAIDrunkLevel(String aiId) => ((aiDrinks[aiId] ?? 0) / maxDrinks).clamp(0.0, 1.0);
  
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
    int drinks = aiDrinks[aiId] ?? 0;
    if (drinks >= maxDrinks) return '烂醉如泥';
    if (drinks >= 5) return '醉意朦胧';
    if (drinks >= 4) return '明显醉意';
    if (drinks >= 3) return '微醺状态';
    if (drinks >= 2) return '略有酒意';
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
    int drinks = aiDrinks[aiId] ?? 0;
    if (drinks >= maxDrinks) return '🥴';
    if (drinks >= 5) return '😵';
    if (drinks >= 4) return '🤪';
    if (drinks >= 3) return '🥺';
    if (drinks >= 2) return '😊';
    if (drinks >= 1) return '🍺';
    return '😎';
  }
  
  /// 玩家喝一杯酒（输了游戏）
  void playerDrink() {
    if (drinksConsumed < maxDrinks) {
      drinksConsumed++;
      lastDrinkTime = DateTime.now();
      // 只有在之前没有酒的时候才设置新的喝酒时间
      // 如果已经有酒，保持原有的倒计时
      if (playerLastDrinkTime == null || drinksConsumed == 1) {
        playerLastDrinkTime = DateTime.now();
      }
      consecutiveLosses++;
      totalLosses++;
    }
  }
  
  /// 特定AI喝一杯酒（输了游戏）
  void aiDrink(String aiId) {
    if (aiDrinks[aiId] != null && aiDrinks[aiId]! < maxDrinks) {
      aiDrinks[aiId] = aiDrinks[aiId]! + 1;
      lastDrinkTime = DateTime.now();
      // 只有在之前没有酒的时候才设置新的喝酒时间
      // 如果已经有酒，保持原有的倒计时
      if (aiLastDrinkTimes[aiId] == null || aiDrinks[aiId] == 1) {
        aiLastDrinkTimes[aiId] = DateTime.now();
      }
    }
  }
  
  /// 玩家赢了游戏（对特定AI）
  void playerWin(String aiId) {
    consecutiveLosses = 0;
    // AI输了要喝酒
    aiDrink(aiId);
  }
  
  /// AI赢了游戏
  void aiWin(String aiId) {
    consecutiveLosses++;
    // 玩家输了要喝酒
    playerDrink();
  }
  
  /// 使用醒酒药水
  bool useSoberPotion() {
    if (soberPotions > 0) {
      soberPotions--;
      drinksConsumed = (drinksConsumed - 2).clamp(0, maxDrinks);
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
    if (aiDrinks[aiId] != null) {
      aiDrinks[aiId] = 0;
      aiLastDrinkTimes[aiId] = null;
    }
  }
  
  /// 根据时间自动醒酒（每10分钟减少一杯）
  void updateSoberStatus() {
    final now = DateTime.now();
    
    // 更新玩家醒酒状态
    if (playerLastDrinkTime != null && drinksConsumed > 0) {
      final minutesPassed = now.difference(playerLastDrinkTime!).inMinutes;
      if (minutesPassed >= 10) {
        int cupsToRecover = minutesPassed ~/ 10;
        int newDrinks = (drinksConsumed - cupsToRecover).clamp(0, maxDrinks);
        
        if (newDrinks != drinksConsumed) {
          drinksConsumed = newDrinks;
          
          // 如果完全醒酒，清除时间记录
          if (drinksConsumed == 0) {
            playerLastDrinkTime = null;
          } else {
            // 更新时间，保留余数部分的时间
            int remainingMinutes = minutesPassed % 10;
            playerLastDrinkTime = now.subtract(Duration(minutes: remainingMinutes));
          }
        }
      }
    }
    
    // 更新每个AI的醒酒状态
    aiDrinks.forEach((aiId, drinks) {
      if (drinks > 0 && aiLastDrinkTimes[aiId] != null) {
        final minutesPassed = now.difference(aiLastDrinkTimes[aiId]!).inMinutes;
        if (minutesPassed >= 10) {
          int cupsToRecover = minutesPassed ~/ 10;
          int newDrinks = (drinks - cupsToRecover).clamp(0, maxDrinks);
          
          if (newDrinks != drinks) {
            aiDrinks[aiId] = newDrinks;
            
            // 如果完全醒酒，清除时间记录
            if (newDrinks == 0) {
              aiLastDrinkTimes[aiId] = null;
            } else {
              // 更新时间，保留余数部分的时间
              int remainingMinutes = minutesPassed % 10;
              aiLastDrinkTimes[aiId] = now.subtract(Duration(minutes: remainingMinutes));
            }
          }
        }
      }
    });
  }
  
  /// 玩家完全醒酒
  void fullSober() {
    drinksConsumed = 0;
    consecutiveLosses = 0;
    playerLastDrinkTime = null;
  }
  
  /// 特定AI完全醒酒
  void aiFullSober(String aiId) {
    if (aiDrinks[aiId] != null) {
      aiDrinks[aiId] = 0;
      aiLastDrinkTimes[aiId] = null;
    }
  }
  
  /// 重置所有状态（新游戏）
  void resetAll() {
    drinksConsumed = 0;
    playerLastDrinkTime = null;
    aiDrinks.forEach((key, value) {
      aiDrinks[key] = 0;
    });
    aiLastDrinkTimes.forEach((key, value) {
      aiLastDrinkTimes[key] = null;
    });
    consecutiveLosses = 0;
  }
  
  /// 购买醒酒药水
  void buyPotion(int count) {
    soberPotions += count;
  }
  
  /// 保存状态
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('drinks_consumed', drinksConsumed);
    
    // 保存每个AI的酒杯数
    for (var entry in aiDrinks.entries) {
      await prefs.setInt('ai_drinks_${entry.key}', entry.value);
    }
    
    await prefs.setInt('sober_potions', soberPotions);
    await prefs.setInt('total_losses', totalLosses);
    await prefs.setInt('consecutive_losses', consecutiveLosses);
    
    if (lastDrinkTime != null) {
      await prefs.setString('last_drink_time', lastDrinkTime!.toIso8601String());
    }
    
    // 保存玩家最后喝酒时间
    if (playerLastDrinkTime != null) {
      await prefs.setString('player_last_drink_time', playerLastDrinkTime!.toIso8601String());
    }
    
    // 保存每个AI的最后喝酒时间
    for (var entry in aiLastDrinkTimes.entries) {
      if (entry.value != null) {
        await prefs.setString('ai_last_drink_time_${entry.key}', entry.value!.toIso8601String());
      }
    }
  }
  
  /// 加载状态
  static Future<DrinkingState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final state = DrinkingState();
    
    state.drinksConsumed = prefs.getInt('drinks_consumed') ?? 0;
    
    // 加载每个AI的酒杯数
    // 普通NPC（兼容旧ID）
    state.aiDrinks['professor'] = prefs.getInt('ai_drinks_professor') ?? 0;
    state.aiDrinks['gambler'] = prefs.getInt('ai_drinks_gambler') ?? 0;
    state.aiDrinks['provocateur'] = prefs.getInt('ai_drinks_provocateur') ?? 0;
    state.aiDrinks['youngwoman'] = prefs.getInt('ai_drinks_youngwoman') ?? 0;
    
    // 新ID格式
    state.aiDrinks['0001'] = prefs.getInt('ai_drinks_0001') ?? state.aiDrinks['professor'] ?? 0;
    state.aiDrinks['0002'] = prefs.getInt('ai_drinks_0002') ?? state.aiDrinks['gambler'] ?? 0;
    state.aiDrinks['0003'] = prefs.getInt('ai_drinks_0003') ?? state.aiDrinks['provocateur'] ?? 0;
    state.aiDrinks['0004'] = prefs.getInt('ai_drinks_0004') ?? state.aiDrinks['youngwoman'] ?? 0;
    
    // VIP NPC
    state.aiDrinks['1001'] = prefs.getInt('ai_drinks_1001') ?? prefs.getInt('ai_drinks_aki') ?? 0;
    state.aiDrinks['1002'] = prefs.getInt('ai_drinks_1002') ?? prefs.getInt('ai_drinks_katerina') ?? 0;
    state.aiDrinks['1003'] = prefs.getInt('ai_drinks_1003') ?? prefs.getInt('ai_drinks_lena') ?? 0;
    
    
    state.soberPotions = prefs.getInt('sober_potions') ?? 0;
    state.totalLosses = prefs.getInt('total_losses') ?? 0;
    state.consecutiveLosses = prefs.getInt('consecutive_losses') ?? 0;
    
    // 加载旧的通用时间（为了兼容性）
    final lastDrinkStr = prefs.getString('last_drink_time');
    if (lastDrinkStr != null) {
      state.lastDrinkTime = DateTime.parse(lastDrinkStr);
    }
    
    // 加载玩家最后喝酒时间
    final playerLastDrinkStr = prefs.getString('player_last_drink_time');
    if (playerLastDrinkStr != null) {
      state.playerLastDrinkTime = DateTime.parse(playerLastDrinkStr);
    } else if (lastDrinkStr != null && state.drinksConsumed > 0) {
      // 兼容旧版本：如果没有单独的玩家时间，使用通用时间
      state.playerLastDrinkTime = state.lastDrinkTime;
    }
    
    // 加载每个AI的最后喝酒时间
    for (String aiId in state.aiDrinks.keys) {
      final aiLastDrinkStr = prefs.getString('ai_last_drink_time_$aiId');
      if (aiLastDrinkStr != null) {
        state.aiLastDrinkTimes[aiId] = DateTime.parse(aiLastDrinkStr);
      } else if (lastDrinkStr != null && state.aiDrinks[aiId]! > 0) {
        // 兼容旧版本：如果没有单独的AI时间，使用通用时间
        state.aiLastDrinkTimes[aiId] = state.lastDrinkTime;
      }
    }
    
    // 根据时间自动更新醒酒状态
    state.updateSoberStatus();
    
    return state;
  }
}
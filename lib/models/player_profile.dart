import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_state.dart';

/// 玩家画像 - 记录玩家的游戏风格和特征
class PlayerProfile {
  // 基础统计
  int totalGames = 0;
  int totalWins = 0;
  int totalChallenges = 0;
  int successfulChallenges = 0;
  int totalBluffs = 0;  // 虚张声势的次数
  int caughtBluffing = 0;  // 被抓到虚张的次数
  
  // 与每个AI的对战记录
  Map<String, Map<String, int>> vsAIRecords = {
    'professor': {'wins': 0, 'losses': 0},
    'gambler': {'wins': 0, 'losses': 0},
    'provocateur': {'wins': 0, 'losses': 0},
    'youngwoman': {'wins': 0, 'losses': 0},
  };
  
  // 叫牌风格分析
  Map<int, int> preferredValues = {}; // 偏好的点数
  double averageBidIncrease = 0; // 平均加注幅度
  int totalPlayerBids = 0; // 玩家总叫牌次数
  int aggressiveBids = 0; // 激进叫牌次数
  int normalBids = 0; // 正常叫牌次数
  
  // 行为模式
  Map<String, int> patterns = {
    'early_challenge': 0, // 早期质疑（前3轮）
    'late_challenge': 0,  // 晚期质疑
    'value_switching': 0, // 频繁换点数
    'value_sticking': 0,  // 坚持同一点数
    'high_quantity_bluff': 0, // 高数量虚张
  };
  
  // 时间相关
  DateTime? lastGameTime;
  List<GameRecord> recentGames = []; // 最近10局的详细记录
  
  // 学习权重 - AI用来调整策略
  double bluffingTendency = 0.5; // 虚张倾向 (0-1)
  double aggressiveness = 0.5; // 激进程度 (0-1)
  double predictability = 0.5; // 可预测性 (0-1)
  double challengeRate = 0.0; // 质疑率（平均每局质疑次数）
  
  PlayerProfile();
  
  /// 从一局游戏中学习
  void learnFromGame(GameRound round, bool playerWon, {String? aiId}) {
    totalGames++;
    if (playerWon) totalWins++;
    
    // 记录与特定AI的对战结果
    if (aiId != null && vsAIRecords.containsKey(aiId)) {
      if (playerWon) {
        vsAIRecords[aiId]!['wins'] = (vsAIRecords[aiId]!['wins'] ?? 0) + 1;
      } else {
        vsAIRecords[aiId]!['losses'] = (vsAIRecords[aiId]!['losses'] ?? 0) + 1;
      }
    }
    
    // 分析这局游戏
    _analyzeGameRound(round, playerWon);
    
    // 更新玩家倾向
    _updateTendencies();
    
    // 保存最近的游戏记录
    _saveRecentGame(round, playerWon);
    
    lastGameTime = DateTime.now();
  }
  
  /// 分析一局游戏
  void _analyzeGameRound(GameRound round, bool playerWon) {
    if (round.bidHistory.isEmpty) return;
    
    // 确定谁先叫牌
    bool firstIsPlayer = !round.isPlayerTurn;
    
    // 分析每个叫牌
    for (int i = 0; i < round.bidHistory.length; i++) {
      bool isPlayerBid = firstIsPlayer ? (i % 2 == 0) : (i % 2 == 1);
      
      if (isPlayerBid) {
        Bid bid = round.bidHistory[i];
        
        // 统计总叫牌次数
        totalPlayerBids++;
        
        // 记录偏好点数
        preferredValues[bid.value] = (preferredValues[bid.value] ?? 0) + 1;
        
        // 检查这次叫牌是否是虚张
        int actualCount = round.playerDice.countValue(
          bid.value, 
          onesAreCalled: round.onesAreCalled
        );
        if (actualCount < bid.quantity / 2) {
          // 玩家手上该点数的实际数量 < 叫牌数量的50%，判定为虚张
          totalBluffs++;
        }
        
        // 分析叫牌风格
        // 游戏规则：叫牌必须递增
        // 1. 保持点数不变，增加数量（如3个4→4个4）
        // 2. 增加点数，保持数量不变（如3个4→3个5）
        // 3. 同时增加点数和数量（如3个4→4个5）
        // 不允许任何维度减少！
        
        if (i > 0) {
          Bid prevBid = round.bidHistory[i - 1];
          
          // 判断是否换点数
          bool changedValue = bid.value != prevBid.value;
          int quantityChange = bid.quantity - prevBid.quantity;
          
          if (changedValue) {
            // 换点数的情况
            patterns['value_switching'] = patterns['value_switching']! + 1;
            
            if (bid.value > prevBid.value) {
              // 换到更高点数
              if (quantityChange == 0) {
                // 换高点数，数量不变：正常策略
                normalBids++;
              } else if (quantityChange > 0) {
                // 换高点数，数量还增加：激进策略
                aggressiveBids++;
                patterns['high_quantity_bluff'] = patterns['high_quantity_bluff']! + 1;
              }
              // quantityChange < 0 是不可能的（违反规则）
            } else if (bid.value < prevBid.value) {
              // 换到更低点数（必须增加数量才合规）
              if (quantityChange >= 2) {
                // 增加≥2个：激进策略
                aggressiveBids++;
                patterns['high_quantity_bluff'] = patterns['high_quantity_bluff']! + 1;
              } else if (quantityChange == 1) {
                // 只增加1个（最少增量）：正常策略
                normalBids++;
              }
              // quantityChange <= 0 是不可能的（违反规则）
            }
          } else {
            // 不换点数，只能增加数量（规则要求）
            patterns['value_sticking'] = patterns['value_sticking']! + 1;
            
            // 根据增加幅度和基数判断激进程度
            if (quantityChange >= 2 && prevBid.quantity >= 2) {
              // 激进：在已有基础（≥2个）上大幅加注（≥2个）
              aggressiveBids++;
              patterns['high_quantity_bluff'] = patterns['high_quantity_bluff']! + 1;
            } else if (quantityChange == 1) {
              // 正常：标准加注1个
              normalBids++;
            } else if (quantityChange >= 2 && prevBid.quantity < 2) {
              // 开局跳叫：算作正常叫牌
              normalBids++;
            }
          }
        }
      }
    }
    
    // 分析最终结果
    if (round.currentBid != null) {
      // 如果玩家是最后叫牌者且输了，统计被抓虚张
      bool playerWasLastBidder = (round.bidHistory.length % 2 == 1) == firstIsPlayer;
      
      if (playerWasLastBidder && !playerWon) {
        int actualCount = round.playerDice.countValue(
          round.currentBid!.value, 
          onesAreCalled: round.onesAreCalled
        );
        if (actualCount < round.currentBid!.quantity / 2) {
          caughtBluffing++;
        }
      }
    }
    
    // 分析质疑时机
    if (!playerWon && round.bidHistory.length <= 3) {
      patterns['early_challenge'] = patterns['early_challenge']! + 1;
    } else if (!playerWon && round.bidHistory.length > 6) {
      patterns['late_challenge'] = patterns['late_challenge']! + 1;
    }
  }
  
  /// 更新玩家倾向
  void _updateTendencies() {
    // 计算虚张倾向（平均每局虚张叫牌次数）
    if (totalGames > 0) {
      bluffingTendency = totalBluffs / totalGames.toDouble(); // 平均每局虚张次数
      bluffingTendency = bluffingTendency.clamp(0.0, 1.0);
    }
    
    // 计算激进程度（平均每局激进叫牌次数）
    if (totalGames > 0) {
      aggressiveness = aggressiveBids / totalGames.toDouble();
      aggressiveness = aggressiveness.clamp(0.0, 1.0);
    }
    
    // 计算质疑率（平均每局质疑次数）
    if (totalGames > 0) {
      challengeRate = totalChallenges / totalGames.toDouble();
    }
    
    // 计算可预测性（基于行为模式的一致性）
    int switching = patterns['value_switching'] ?? 0;
    int sticking = patterns['value_sticking'] ?? 0;
    if (switching + sticking > 0) {
      // 如果玩家总是换或总是不换，可预测性高
      double consistency = (switching - sticking).abs() / (switching + sticking).toDouble();
      predictability = consistency;
    }
  }
  
  /// 保存最近的游戏记录
  void _saveRecentGame(GameRound round, bool playerWon) {
    GameRecord record = GameRecord(
      timestamp: DateTime.now(),
      playerWon: playerWon,
      totalBids: round.bidHistory.length,
      finalBid: round.currentBid,
      playerDice: round.playerDice.values,
      aiDice: round.aiDice.values,
    );
    
    recentGames.add(record);
    
    // 只保留最近10局
    if (recentGames.length > 10) {
      recentGames.removeAt(0);
    }
  }
  
  /// 获取玩家风格描述
  String getStyleDescription() {
    List<String> traits = [];
    
    // 虚张倾向
    if (bluffingTendency > 0.7) {
      traits.add('经常虚张');
    } else if (bluffingTendency < 0.3) {
      traits.add('诚实型');
    }
    
    // 激进程度
    if (aggressiveness > 0.6) {
      traits.add('激进型');
    } else if (aggressiveness < 0.4) {
      traits.add('保守型');
    }
    
    // 偏好点数
    if (preferredValues.isNotEmpty) {
      var sorted = preferredValues.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (sorted.first.value > totalGames / 2) {
        traits.add('偏好${sorted.first.key}点');
      }
    }
    
    // 质疑习惯
    if (patterns['early_challenge']! > patterns['late_challenge']!) {
      traits.add('喜欢早期质疑');
    } else if (patterns['late_challenge']! > patterns['early_challenge']!) {
      traits.add('倾向晚期质疑');
    }
    
    return traits.isEmpty ? '风格未知' : traits.join('、');
  }
  
  /// 获取详细的玩家分析报告（用于API调用）
  String getDetailedAnalysis() {
    if (totalGames == 0) return '';
    
    String analysis = '''
═══════════════════════════════════════════════════
📊 玩家深度画像分析（基于${totalGames}局游戏）
═══════════════════════════════════════════════════

【基础数据】
• 总游戏局数：$totalGames
• 胜率：${totalWins}/${totalGames} = ${(totalWins * 100.0 / totalGames).toStringAsFixed(1)}%
• 质疑成功率：${successfulChallenges}/${totalChallenges > 0 ? totalChallenges : 1} = ${totalChallenges > 0 ? (successfulChallenges * 100.0 / totalChallenges).toStringAsFixed(1) : '0.0'}%
• 被抓虚张率：${caughtBluffing}/${totalBluffs > 0 ? totalBluffs : 1} = ${totalBluffs > 0 ? (caughtBluffing * 100.0 / totalBluffs).toStringAsFixed(1) : '0.0'}%

【行为特征】
• 虚张倾向：${(bluffingTendency * 100).toStringAsFixed(0)}% ${_getBluffingAnalysis()}
• 激进程度：${(aggressiveness * 100).toStringAsFixed(0)}% ${_getAggressivenessAnalysis()}
• 可预测性：${(predictability * 100).toStringAsFixed(0)}% ${_getPredictabilityAnalysis()}

【叫牌偏好】
${_getValuePreferenceAnalysis()}

【行为模式】
${_getPatternAnalysis()}

【最近游戏趋势】
${_getRecentTrend()}

【最近${recentGames.length}局详细记录】
${_getRecentGamesDetail()}

【关键洞察】
${_getKeyInsights()}

【建议策略】
${_getSuggestedStrategy()}
''';
    
    return analysis;
  }
  
  String _getRecentGamesDetail() {
    if (recentGames.isEmpty) return '• 暂无记录';
    
    List<String> details = [];
    for (int i = 0; i < recentGames.length && i < 3; i++) {
      GameRecord game = recentGames[recentGames.length - 1 - i];
      String result = game.playerWon ? '✅赢' : '❌输';
      String diceStr = game.playerDice.join(',');
      String finalBidStr = game.finalBid != null 
        ? '${game.finalBid!.quantity}个${game.finalBid!.value}' 
        : '未知';
      
      // 分析这局的特点
      Map<int, int> diceCounts = {};
      for (int die in game.playerDice) {
        diceCounts[die] = (diceCounts[die] ?? 0) + 1;
      }
      
      String analysis = '';
      if (game.finalBid != null && diceCounts[game.finalBid!.value] != null) {
        int actualCount = diceCounts[game.finalBid!.value]! + 
                         (diceCounts[1] ?? 0); // 加上万能1
        if (actualCount >= 3) {
          analysis = '（玩家有${actualCount}个）';
        } else if (actualCount == 0) {
          analysis = '（纯虚张）';
        }
      }
      
      details.add('  第${i+1}局：$result 骰子[$diceStr] 最终叫$finalBidStr$analysis');
    }
    
    return details.join('\n');
  }
  
  String _getBluffingAnalysis() {
    if (bluffingTendency > 0.7) {
      return '（高风险玩家，经常虚张声势，需要频繁质疑）';
    } else if (bluffingTendency > 0.5) {
      return '（中等虚张倾向，虚实结合）';
    } else if (bluffingTendency > 0.3) {
      return '（偏向诚实，但偶尔虚张）';
    } else {
      return '（极少虚张，叫牌可信度高）';
    }
  }
  
  String _getAggressivenessAnalysis() {
    if (aggressiveness > 0.7) {
      return '（激进冒险，喜欢大幅加注）';
    } else if (aggressiveness > 0.5) {
      return '（适度激进）';
    } else if (aggressiveness > 0.3) {
      return '（偏保守，小心谨慎）';
    } else {
      return '（极度保守，步步为营）';
    }
  }
  
  String _getPredictabilityAnalysis() {
    if (predictability > 0.7) {
      return '（行为模式固定，容易预测）';
    } else if (predictability > 0.4) {
      return '（有一定规律可循）';
    } else {
      return '（变化多端，难以预测）';
    }
  }
  
  String _getValuePreferenceAnalysis() {
    if (preferredValues.isEmpty) return '• 暂无明显偏好';
    
    var sorted = preferredValues.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    List<String> prefs = [];
    for (var entry in sorted.take(3)) {
      double percentage = entry.value * 100.0 / totalGames;
      prefs.add('  - ${entry.key}点：叫了${entry.value}次 (${percentage.toStringAsFixed(1)}%)');
    }
    
    // 分析偏好的含义
    String meaning = '';
    if (sorted.first.value > totalGames * 0.3) {
      int favValue = sorted.first.key;
      meaning = '\n• ⚠️ 特别偏好${favValue}点！当其叫${favValue}时很可能真有！';
    }
    
    return '• 常叫点数：\n${prefs.join('\n')}$meaning';
  }
  
  String _getPatternAnalysis() {
    List<String> analysis = [];
    
    // 质疑时机
    int earlyChallenge = patterns['early_challenge'] ?? 0;
    int lateChallenge = patterns['late_challenge'] ?? 0;
    if (earlyChallenge + lateChallenge > 0) {
      if (earlyChallenge > lateChallenge * 2) {
        analysis.add('• 喜欢早期质疑（前3轮质疑${earlyChallenge}次）');
      } else if (lateChallenge > earlyChallenge * 2) {
        analysis.add('• 倾向晚期质疑（6轮后质疑${lateChallenge}次）');
      }
    }
    
    // 换点习惯
    int switching = patterns['value_switching'] ?? 0;
    int sticking = patterns['value_sticking'] ?? 0;
    if (switching + sticking > 5) {
      if (switching > sticking * 1.5) {
        analysis.add('• 频繁换点数（换了${switching}次） - 可能在试探');
      } else if (sticking > switching * 1.5) {
        analysis.add('• 坚持同点数（坚持${sticking}次） - 可能真有该点');
      }
    }
    
    return analysis.isEmpty ? '• 暂无明显模式' : analysis.join('\n');
  }
  
  String _getRecentTrend() {
    if (recentGames.length < 3) return '• 数据不足';
    
    // 分析最近的胜率趋势
    int recentWins = recentGames.where((g) => g.playerWon).length;
    double recentWinRate = recentWins * 100.0 / recentGames.length;
    double overallWinRate = totalWins * 100.0 / totalGames;
    
    if (recentWinRate > overallWinRate + 20) {
      return '• 📈 最近状态火热！近${recentGames.length}局胜率${recentWinRate.toStringAsFixed(0)}%';
    } else if (recentWinRate < overallWinRate - 20) {
      return '• 📉 最近状态低迷，近${recentGames.length}局胜率${recentWinRate.toStringAsFixed(0)}%';
    } else {
      return '• 状态稳定，近${recentGames.length}局胜率${recentWinRate.toStringAsFixed(0)}%';
    }
  }
  
  String _getKeyInsights() {
    List<String> insights = [];
    
    // 虚张与点数的关系
    if (bluffingTendency > 0.6 && preferredValues.isNotEmpty) {
      var favValue = preferredValues.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      insights.add('• 💡 常在没有${favValue}时也叫${favValue}（虚张陷阱）');
    }
    
    // 激进与胜率的关系
    if (aggressiveness > 0.7 && totalWins < totalGames * 0.4) {
      insights.add('• ⚠️ 过度激进导致胜率偏低，容易被识破');
    } else if (aggressiveness < 0.3 && totalWins > totalGames * 0.6) {
      insights.add('• ✅ 保守策略有效，稳扎稳打');
    }
    
    // 质疑准确率
    if (totalChallenges > 5) {
      double challengeAccuracy = successfulChallenges * 100.0 / totalChallenges;
      if (challengeAccuracy > 70) {
        insights.add('• 🎯 质疑准确率极高(${challengeAccuracy.toStringAsFixed(0)}%)，判断力出色');
      } else if (challengeAccuracy < 30) {
        insights.add('• ❌ 质疑准确率低(${challengeAccuracy.toStringAsFixed(0)}%)，容易误判');
      }
    }
    
    return insights.isEmpty ? '• 继续观察中...' : insights.join('\n');
  }
  
  String _getSuggestedStrategy() {
    List<String> strategies = [];
    
    // 基于虚张倾向
    if (bluffingTendency > 0.6) {
      strategies.add('• 🎯 对其高数量叫牌保持怀疑，大概率虚张');
      strategies.add('• 📊 计算概率时下调20-30%可信度');
    } else if (bluffingTendency < 0.3) {
      strategies.add('• ✅ 其叫牌可信度高，不要轻易质疑');
      strategies.add('• 📊 可以相信其大部分叫牌');
    }
    
    // 基于偏好点数
    if (preferredValues.isNotEmpty) {
      var favValue = preferredValues.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      if (preferredValues[favValue]! > totalGames * 0.3) {
        strategies.add('• 🎲 当其叫${favValue}时要格外小心，可能真有');
        strategies.add('• 💡 可以用${favValue}设陷阱，引其上钩');
      }
    }
    
    // 基于激进程度
    if (aggressiveness > 0.7) {
      strategies.add('• 🔥 面对激进玩家，可以稳健应对，等其犯错');
    } else if (aggressiveness < 0.3) {
      strategies.add('• 🐌 面对保守玩家，可以适度虚张施压');
    }
    
    return strategies.isEmpty ? '• 标准策略，见机行事' : strategies.join('\n');
  }
  
  /// 保存到本地存储
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> data = {
        'totalGames': totalGames,
        'totalWins': totalWins,
        'totalChallenges': totalChallenges,
        'successfulChallenges': successfulChallenges,
        'totalBluffs': totalBluffs,
        'caughtBluffing': caughtBluffing,
        'preferredValues': preferredValues.map((k, v) => MapEntry(k.toString(), v)),
        'averageBidIncrease': averageBidIncrease,
        'totalPlayerBids': totalPlayerBids,
        'aggressiveBids': aggressiveBids,
        'normalBids': normalBids,
        'patterns': patterns,
        'lastGameTime': lastGameTime?.toIso8601String(),
        'bluffingTendency': bluffingTendency,
        'aggressiveness': aggressiveness,
        'predictability': predictability,
        'challengeRate': challengeRate,
        'recentGames': recentGames.map((g) => g.toJson()).toList(),
        'vsAIRecords': vsAIRecords,
      };
      String jsonString = jsonEncode(data);
      await prefs.setString('player_profile', jsonString);
      print('Player profile saved successfully');
    } catch (e) {
      print('Error saving player profile: $e');
    }
  }
  
  /// 从本地存储加载
  static Future<PlayerProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('player_profile');
    
    PlayerProfile profile = PlayerProfile();
    
    if (data != null) {
      try {
        Map<String, dynamic> json = jsonDecode(data);
        profile.totalGames = json['totalGames'] ?? 0;
        profile.totalWins = json['totalWins'] ?? 0;
        profile.totalChallenges = json['totalChallenges'] ?? 0;
        profile.successfulChallenges = json['successfulChallenges'] ?? 0;
        profile.totalBluffs = json['totalBluffs'] ?? 0;
        profile.caughtBluffing = json['caughtBluffing'] ?? 0;
        if (json['preferredValues'] != null) {
          Map<String, dynamic> prefValues = json['preferredValues'];
          profile.preferredValues = prefValues.map((k, v) => MapEntry(int.parse(k), v as int));
        }
        profile.averageBidIncrease = json['averageBidIncrease'] ?? 0.0;
        profile.totalPlayerBids = json['totalPlayerBids'] ?? 0;
        profile.aggressiveBids = json['aggressiveBids'] ?? 0;
        profile.normalBids = json['normalBids'] ?? 0;
        profile.patterns = Map<String, int>.from(json['patterns'] ?? profile.patterns);
        profile.bluffingTendency = json['bluffingTendency'] ?? 0.5;
        profile.aggressiveness = json['aggressiveness'] ?? 0.5;
        profile.predictability = json['predictability'] ?? 0.5;
        profile.challengeRate = json['challengeRate'] ?? 0.0;
        
        if (json['lastGameTime'] != null) {
          profile.lastGameTime = DateTime.parse(json['lastGameTime']);
        }
        
        if (json['recentGames'] != null) {
          profile.recentGames = (json['recentGames'] as List)
            .map((g) => GameRecord.fromJson(g))
            .toList();
        }
        
        if (json['vsAIRecords'] != null) {
          // 直接覆盖整个vsAIRecords，而不是只更新已存在的key
          Map<String, dynamic> records = json['vsAIRecords'];
          records.forEach((key, value) {
            profile.vsAIRecords[key] = Map<String, int>.from(value);
          });
        }
      } catch (e) {
        print('Error loading player profile: $e');
      }
    }
    
    return profile;
  }
}

/// 单局游戏记录
class GameRecord {
  final DateTime timestamp;
  final bool playerWon;
  final int totalBids;
  final Bid? finalBid;
  final List<int> playerDice;
  final List<int> aiDice;
  
  GameRecord({
    required this.timestamp,
    required this.playerWon,
    required this.totalBids,
    this.finalBid,
    required this.playerDice,
    required this.aiDice,
  });
  
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'playerWon': playerWon,
    'totalBids': totalBids,
    'finalBid': finalBid != null ? {
      'quantity': finalBid!.quantity,
      'value': finalBid!.value,
    } : null,
    'playerDice': playerDice,
    'aiDice': aiDice,
  };
  
  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
    timestamp: DateTime.parse(json['timestamp']),
    playerWon: json['playerWon'],
    totalBids: json['totalBids'],
    finalBid: json['finalBid'] != null 
      ? Bid(
          quantity: json['finalBid']['quantity'],
          value: json['finalBid']['value'],
        )
      : null,
    playerDice: List<int>.from(json['playerDice']),
    aiDice: List<int>.from(json['aiDice']),
  );
}
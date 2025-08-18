import 'dart:math' as math;
import '../models/game_state.dart';
import '../models/ai_personality.dart';
import '../utils/logger_utils.dart';
import 'probability_calculator.dart';

/// 顶级AI引擎 - 实现世界级大话骰策略
/// 
/// 核心特性:
/// 1. 贝叶斯推理 - 实时更新对手骰子分布概率
/// 2. 博弈论优化 - 纳什均衡与剥削性策略平衡
/// 3. 心理战系统 - 模式建立、反向陷阱、压力战术
/// 4. 元策略层 - 动态风格切换、反适应机制
class EliteAIEngine {
  final AIPersonality personality;
  final random = math.Random();
  final probabilityCalculator = ProbabilityCalculator();
  
  // 对手建模
  late OpponentModel opponentModel;
  
  // 策略状态
  StrategyState strategyState = StrategyState();
  
  EliteAIEngine({required this.personality}) {
    opponentModel = OpponentModel();
  }
  
  /// 主决策入口 - 整合所有层级的智能
  Map<String, dynamic> makeEliteDecision(GameRound round) {
    AILogger.logParsing('Elite AI决策开始', {
      'round': round.bidHistory.length,
      'currentBid': round.currentBid?.toString(),
      'personality': personality.id,
    });
    
    // 1. 更新对手模型
    opponentModel.updateFromHistory(round);
    
    // 2. 计算数学最优解
    var mathOptions = _calculateMathematicalOptions(round);
    
    // 3. 应用心理战术调整
    var psychOptions = _applyPsychologicalWarfare(mathOptions, round);
    
    // 4. 执行策略层决策
    var strategyChoice = _executeStrategy(psychOptions, round);
    
    // 5. 元策略调整
    var finalChoice = _applyMetaStrategy(strategyChoice, round);
    
    // 6. 保存所有选项供复盘使用（只保留前3个最佳选项）
    List<Map<String, dynamic>> topOptions = [];
    if (psychOptions.isNotEmpty) {
      // 按期望值排序并取前3个
      psychOptions.sort((a, b) => (b['expectedValue'] as double).compareTo(a['expectedValue'] as double));
      topOptions = psychOptions.take(3).toList();
    }
    finalChoice['allOptions'] = topOptions;
    
    AILogger.logParsing('Elite AI决策完成', {
      'choice': finalChoice['type'],
      'confidence': finalChoice['confidence'],
      'strategy': finalChoice['strategy'],
      'optionsCount': topOptions.length,
    });
    
    return finalChoice;
  }
  
  /// 数学模型层 - 贝叶斯推理与期望值计算
  List<Map<String, dynamic>> _calculateMathematicalOptions(GameRound round) {
    List<Map<String, dynamic>> options = [];
    
    // 获取我们的骰子统计
    Map<int, int> ourCounts = {};
    for (int i = 1; i <= 6; i++) {
      ourCounts[i] = round.aiDice.countValue(i, onesAreCalled: round.onesAreCalled);
    }
    
    // 计算对手骰子的后验分布
    Map<int, double> opponentDistribution = opponentModel.getPosteriorDistribution(
      round.currentBid,
      round.onesAreCalled
    );
    
    // 1. 计算质疑选项的期望值
    if (round.currentBid != null) {
      double challengeEV = _calculateChallengeEV(
        round.currentBid!,
        ourCounts,
        opponentDistribution,
        round
      );
      
      // 使用统一的概率计算器计算质疑成功率
      double challengeSuccessRate = probabilityCalculator.calculateChallengeSuccessProbability(
        currentBid: round.currentBid!,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      options.add({
        'type': 'challenge',
        'expectedValue': challengeEV,
        'confidence': challengeSuccessRate,  // 使用真实的质疑成功率
        'successRate': challengeSuccessRate,  // 保存原始成功率
        'reasoning': '质疑成功率: ${(challengeSuccessRate * 100).toStringAsFixed(1)}%',
      });
    }
    
    // 2. 计算所有可能叫牌的期望值
    var bidOptions = _generateSmartBids(round, ourCounts, opponentDistribution);
    options.addAll(bidOptions);
    
    // 3. 按期望值排序
    options.sort((a, b) => b['expectedValue'].compareTo(a['expectedValue']));
    
    return options;
  }
  
  /// 计算质疑的期望值（考虑贝叶斯更新）
  double _calculateChallengeEV(
    Bid currentBid,
    Map<int, int> ourCounts,
    Map<int, double> opponentDist,
    GameRound round,
  ) {
    // AI知道自己有多少个该点数（包括万能牌）
    int ourCount = ourCounts[currentBid.value] ?? 0;
    // 对手（玩家）需要有多少个才能让叫牌成立
    int opponentNeeded = currentBid.quantity - ourCount;
    
    // 调试日志
    AILogger.logParsing('质疑决策计算', {
      'currentBid': currentBid.toString(),
      'bidValue': currentBid.value,
      'bidQuantity': currentBid.quantity,
      'ourCount': ourCount,
      'opponentNeeded': opponentNeeded,
      'aiDice': round.aiDice.values,
      'onesAreCalled': round.onesAreCalled,
      'ourCounts': ourCounts,
    });
    
    if (opponentNeeded <= 0) {
      AILogger.logParsing('不应质疑', {'理由': '我们已经有足够的骰子'});
      return -100.0; // 我们已经有足够，叫牌必定成立，不应质疑
    }
    if (opponentNeeded > 5) {
      AILogger.logParsing('必须质疑', {'理由': '对手不可能有这么多'});
      return 100.0;    // 对手不可能有这么多，必须质疑
    }
    
    // 使用统一的概率计算器
    // 计算玩家叫牌成功的概率（从AI角度看）
    double bidSuccessProb = probabilityCalculator.calculateBidSuccessProbability(
      bid: currentBid,
      ourDice: round.aiDice,
      onesAreCalled: round.onesAreCalled,
    );
    
    // 对手有足够骰子的概率 = 叫牌成功概率
    double opponentHasEnough = bidSuccessProb;
    
    // 考虑对手的模式和历史
    double bluffAdjustment = opponentModel.estimatedBluffRate;
    
    // 根据对手虚张历史调整
    opponentHasEnough *= (1.0 - bluffAdjustment * 0.3);
    
    // 期望值 = 成功概率 * 收益 - 失败概率 * 损失
    double successProb = 1.0 - opponentHasEnough;
    
    // 动态调整收益和损失权重
    double winValue = 15.0 + (round.bidHistory.length * 3.0); // 后期质疑价值更高
    double loseValue = -10.0; // 降低质疑失败的代价，鼓励更激进
    
    // 如果成功率超过60%，额外奖励
    if (successProb > 0.6) {
      winValue *= 1.5;
    }
    
    return successProb * winValue + (1.0 - successProb) * loseValue;
  }
  
  /// 生成智能叫牌选项（考虑博弈论）
  List<Map<String, dynamic>> _generateSmartBids(
    GameRound round,
    Map<int, int> ourCounts,
    Map<int, double> opponentDist,
  ) {
    List<Map<String, dynamic>> bidOptions = [];
    Bid? currentBid = round.currentBid;
    
    // 生成候选叫牌
    List<Bid> candidates = [];
    
    if (currentBid == null) {
      // 开局叫牌策略
      for (int qty = 2; qty <= 4; qty++) {
        for (int val = 1; val <= 6; val++) {
          candidates.add(Bid(quantity: qty, value: val));
        }
      }
    } else {
      // 生成所有合法的后续叫牌
      for (int qty = currentBid.quantity; qty <= math.min(10, currentBid.quantity + 3); qty++) {
        for (int val = 1; val <= 6; val++) {
          // 对1进行特殊限制：当1被叫后，最多只能叫到合理范围
          if (val == 1 && round.onesAreCalled) {
            // 1失去万能牌地位后，最多只能有10个骰子中的一部分是1
            // 合理的上限是总骰子数的40%（即最多4个1）
            if (qty > 4) continue;
          }
          
          // 一般性合理性检查：任何点数都不应该超过总骰子数的70%
          if (qty > 7) continue;
          
          Bid newBid = Bid(quantity: qty, value: val);
          if (newBid.isHigherThan(currentBid, onesAreCalled: round.onesAreCalled)) {
            candidates.add(newBid);
          }
        }
      }
    }
    
    // 计算每个叫牌的期望值
    for (Bid bid in candidates) {
      double ev = _calculateBidEV(bid, ourCounts, opponentDist, round);
      
      // 识别策略类型
      String strategy = _identifyBidStrategy(bid, ourCounts, round);
      
      // 使用统一的概率计算器计算成功率
      double successRate = probabilityCalculator.calculateBidSuccessProbability(
        bid: bid,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      bidOptions.add({
        'type': 'bid',
        'bid': bid,
        'expectedValue': ev,
        'confidence': successRate,  // 使用真实的成功率而非期望值映射
        'successRate': successRate,  // 保存原始成功率
        'strategy': strategy,
        'reasoning': _getBidReasoning(strategy, ev),
      });
    }
    
    return bidOptions;
  }
  
  /// 计算叫牌的期望值
  double _calculateBidEV(
    Bid bid,
    Map<int, int> ourCounts,
    Map<int, double> opponentDist,
    GameRound round,
  ) {
    int ourCount = ourCounts[bid.value] ?? 0;
    
    // 计算我们成功的概率
    double ourSuccess = _calculateOurSuccessProb(bid, ourCount, opponentDist);
    
    // 计算对手质疑的概率（基于对手模型）
    double opponentChallengeProb = _estimateOpponentChallengeProb(bid, round);
    
    // 对不合理的叫牌进行惩罚
    if (bid.value == 1 && round.onesAreCalled && bid.quantity > 4) {
      // 叫超过4个1（当1被叫后）是极不合理的
      return -50.0;
    }
    
    // 对纯诈唬进行额外风险评估
    double ratio = ourCount.toDouble() / bid.quantity;
    if (ratio < 0.2) {
      // 纯诈唬：我们拥有的少于20%
      // 增加被质疑的概率估计
      opponentChallengeProb = math.min(0.9, opponentChallengeProb * 1.5);
      
      // 如果叫牌数量超过6，几乎肯定会被质疑
      if (bid.quantity > 6) {
        opponentChallengeProb = 0.95;
      }
    }
    
    // 期望值计算
    double continueValue = 5.0; // 继续游戏的价值
    double winChallengeValue = 15.0; // 对手质疑但我们赢
    double loseChallengeValue = -20.0; // 对手质疑且我们输
    
    // 考虑诈唬的额外价值（但要合理）
    double bluffBonus = 0.0;
    if (ourCount < bid.quantity * 0.6 && bid.quantity <= 6) {
      bluffBonus = 3.0; // 成功的诈唬有额外价值
    }
    
    double ev = (1.0 - opponentChallengeProb) * (continueValue + bluffBonus) +
                opponentChallengeProb * ourSuccess * winChallengeValue +
                opponentChallengeProb * (1.0 - ourSuccess) * loseChallengeValue;
    
    return ev;
  }
  
  /// 心理战术层 - 欺骗、压力、反向心理
  List<Map<String, dynamic>> _applyPsychologicalWarfare(
    List<Map<String, dynamic>> options,
    GameRound round,
  ) {
    // 检测当前心理战术机会
    var tactics = _detectPsychologicalOpportunities(round);
    
    for (var option in options) {
      // 应用心理战术加成
      for (var tactic in tactics) {
        if (_shouldApplyTactic(option, tactic, round)) {
          option['expectedValue'] = (option['expectedValue'] as double) + tactic['bonus'];
          option['psychTactic'] = tactic['name'];
          option['reasoning'] = '${option['reasoning']} + ${tactic['name']}';
        }
      }
    }
    
    // 添加特殊心理战术选项（降低触发门槛）
    if (round.bidHistory.length >= 2) {  // 从第2轮就可以开始心理战
      // 反向陷阱：故意示弱引诱质疑
      if (!strategyState.hasExecutedTrap && random.nextDouble() < 0.3) {  // 30%概率尝试陷阱
        var trapOption = _createReverseTrap(round);
        if (trapOption != null) {
          options.add(trapOption);
        }
      }
      
      // 压力升级：突然大幅加注
      if (round.currentBid != null && round.currentBid!.quantity <= 6 && random.nextDouble() < 0.25) {  // 25%概率施压
        var pressureOption = _createPressurePlay(round);
        if (pressureOption != null) {
          options.add(pressureOption);
        }
      }
    }
    
    return options;
  }
  
  /// 检测心理战术机会
  List<Map<String, dynamic>> _detectPsychologicalOpportunities(GameRound round) {
    List<Map<String, dynamic>> tactics = [];
    
    // 1. 模式破坏机会
    if (strategyState.hasEstablishedPattern) {
      tactics.add({
        'name': '模式破坏',
        'bonus': 8.0,
        'condition': 'break_pattern',
      });
    }
    
    // 2. 后期压力
    if (round.bidHistory.length > 5) {
      tactics.add({
        'name': '后期施压',
        'bonus': 5.0,
        'condition': 'endgame_pressure',
      });
    }
    
    // 3. 反向心理
    if (opponentModel.isAggressive) {
      tactics.add({
        'name': '诱导激进',
        'bonus': 6.0,
        'condition': 'induce_aggression',
      });
    }
    
    return tactics;
  }
  
  /// 创建反向陷阱
  Map<String, dynamic>? _createReverseTrap(GameRound round) {
    if (round.currentBid == null) return null;
    
    // 选择一个我们实际很强但看起来很弱的叫牌
    Map<int, int> ourCounts = {};
    for (int i = 1; i <= 6; i++) {
      ourCounts[i] = round.aiDice.countValue(i, onesAreCalled: round.onesAreCalled);
    }
    
    // 找到我们最多的点数
    int maxCount = 0;
    int strongValue = 1;
    ourCounts.forEach((value, count) {
      if (count > maxCount) {
        maxCount = count;
        strongValue = value;
      }
    });
    
    if (maxCount >= 2) {  // 降低门槛，有2个就可以设陷阱
      // 故意叫得保守，引诱质疑
      Bid trapBid = Bid(
        quantity: round.currentBid!.quantity + 1,
        value: strongValue,
      );
      
      if (trapBid.isHigherThan(round.currentBid!, onesAreCalled: round.onesAreCalled)) {
        strategyState.hasExecutedTrap = true;
        return {
          'type': 'bid',
          'bid': trapBid,
          'expectedValue': 25.0, // 陷阱成功价值很高
          'confidence': 0.85,
          'strategy': 'reverse_trap',
          'psychTactic': '反向陷阱',
          'reasoning': '示弱诱敌',
        };
      }
    }
    
    return null;
  }
  
  /// 创建压力打法
  Map<String, dynamic>? _createPressurePlay(GameRound round) {
    if (round.currentBid == null) return null;
    
    // 大幅提高数量施加压力
    int pressureQty = math.min(10, round.currentBid!.quantity + 3);
    
    // 选择一个中等概率的点数
    Map<int, int> ourCounts = {};
    for (int i = 1; i <= 6; i++) {
      ourCounts[i] = round.aiDice.countValue(i, onesAreCalled: round.onesAreCalled);
    }
    
    // 找一个我们有2个以上的
    for (var entry in ourCounts.entries) {
      if (entry.value >= 2) {
        Bid pressureBid = Bid(quantity: pressureQty, value: entry.key);
        if (pressureBid.isHigherThan(round.currentBid!, onesAreCalled: round.onesAreCalled)) {
          return {
            'type': 'bid',
            'bid': pressureBid,
            'expectedValue': 12.0,
            'confidence': 0.6,
            'strategy': 'pressure_play',
            'psychTactic': '压力升级',
            'reasoning': '心理压迫',
          };
        }
      }
    }
    
    return null;
  }
  
  /// 策略执行层 - 选择最佳行动
  Map<String, dynamic> _executeStrategy(
    List<Map<String, dynamic>> options,
    GameRound round,
  ) {
    if (options.isEmpty) {
      // 紧急降级
      return _emergencyFallback(round);
    }
    
    // 根据游戏阶段调整策略
    GamePhase phase = _identifyGamePhase(round);
    
    // 根据性格和阶段过滤选项
    List<Map<String, dynamic>> filtered = _filterByPersonalityAndPhase(
      options,
      phase,
      round
    );
    
    if (filtered.isEmpty) filtered = options;
    
    // 选择最佳选项（不总是选最高EV，增加不可预测性）
    Map<String, dynamic> chosen;
    
    if (random.nextDouble() < 0.8) {
      // 80%选择最优
      chosen = filtered[0];
    } else if (filtered.length > 1) {
      // 20%选择次优增加变化
      chosen = filtered[1];
    } else {
      chosen = filtered[0];
    }
    
    // 最终安全检查：绝对不应该选择明显错误的质疑
    if (chosen['type'] == 'challenge' && chosen['expectedValue'] < -50.0) {
      AILogger.logParsing('拒绝错误质疑，选择其他选项', {
        'originalChoice': chosen['type'],
        'ev': chosen['expectedValue'],
      });
      
      // 找一个叫牌选项
      var bidOptions = filtered.where((o) => o['type'] == 'bid').toList();
      if (bidOptions.isNotEmpty) {
        chosen = bidOptions[0];
      } else {
        // 如果没有叫牌选项，生成一个保守的叫牌
        chosen = _emergencyFallback(round);
      }
    }
    
    // 更新策略状态
    _updateStrategyState(chosen, round);
    
    return chosen;
  }
  
  /// 元策略层 - 动态调整与反适应
  Map<String, dynamic> _applyMetaStrategy(
    Map<String, dynamic> choice,
    GameRound round,
  ) {
    // 检测对手是否在适应我们
    if (opponentModel.hasAdaptedToUs()) {
      // 切换风格
      choice = _switchStyle(choice, round);
      strategyState.styleSwitch++;
    }
    
    // 检测是否需要改变节奏
    if (_shouldChangeRhythm(round)) {
      choice['decisionSpeed'] = random.nextDouble() < 0.5 ? 'fast' : 'slow';
    }
    
    // 添加最终的元信息
    choice['metaInfo'] = {
      'opponentAdaptation': opponentModel.adaptationLevel,
      'ourPatternStrength': strategyState.patternStrength,
      'styleChanges': strategyState.styleSwitch,
    };
    
    return choice;
  }
  
  /// 切换风格以对抗适应
  Map<String, dynamic> _switchStyle(
    Map<String, dynamic> choice,
    GameRound round,
  ) {
    // 如果之前保守，现在激进
    if (strategyState.currentStyle == 'conservative') {
      // 找一个更激进的选项
      if (choice['type'] == 'bid') {
        Bid currentBid = choice['bid'];
        Bid aggressiveBid = Bid(
          quantity: math.min(10, currentBid.quantity + 2),
          value: currentBid.value
        );
        choice['bid'] = aggressiveBid;
        choice['strategy'] = 'style_switch_aggressive';
        strategyState.currentStyle = 'aggressive';
      }
    } else {
      // 如果之前激进，现在保守
      strategyState.currentStyle = 'conservative';
    }
    
    return choice;
  }
  
  // ============= 辅助方法 =============
  
  /// 计算信心水平
  double _calculateConfidence(double expectedValue) {
    // 将期望值映射到0-1的信心水平
    if (expectedValue >= 20) return 0.95;
    if (expectedValue >= 10) return 0.85;
    if (expectedValue >= 5) return 0.70;
    if (expectedValue >= 0) return 0.50;
    if (expectedValue >= -5) return 0.35;
    return 0.20;
  }
  
  /// 识别叫牌策略
  String _identifyBidStrategy(Bid bid, Map<int, int> ourCounts, GameRound round) {
    int ourCount = ourCounts[bid.value] ?? 0;
    double ratio = ourCount.toDouble() / bid.quantity;
    
    if (ratio >= 0.8) return 'value_bet';
    if (ratio >= 0.5) return 'semi_bluff';
    if (ratio >= 0.2) return 'bluff';
    return 'pure_bluff';
  }
  
  /// 获取叫牌理由
  String _getBidReasoning(String strategy, double ev) {
    switch (strategy) {
      case 'value_bet':
        return '价值叫牌 EV:${ev.toStringAsFixed(1)}';
      case 'semi_bluff':
        return '半诈唬 EV:${ev.toStringAsFixed(1)}';
      case 'bluff':
        return '诈唬 EV:${ev.toStringAsFixed(1)}';
      case 'pure_bluff':
        return '纯诈唬 EV:${ev.toStringAsFixed(1)}';
      default:
        return '战术叫牌 EV:${ev.toStringAsFixed(1)}';
    }
  }
  
  /// 计算我们成功的概率
  double _calculateOurSuccessProb(
    Bid bid,
    int ourCount,
    Map<int, double> opponentDist,
  ) {
    int needed = bid.quantity - ourCount;
    if (needed <= 0) return 1.0;
    if (needed > 5) return 0.0;
    
    double prob = opponentDist[bid.value] ?? (1.0 / 6.0);
    return _binomialAtLeast(5, needed, prob);
  }
  
  /// 估计对手质疑概率
  double _estimateOpponentChallengeProb(Bid bid, GameRound round) {
    // 基础概率
    double baseProb = 0.2;
    
    // 根据叫牌激进程度调整
    if (round.currentBid != null) {
      int increase = bid.quantity - round.currentBid!.quantity;
      baseProb += increase * 0.15;
    }
    
    // 根据游戏阶段调整
    baseProb += round.bidHistory.length * 0.05;
    
    // 根据对手模型调整
    if (opponentModel.isAggressive) {
      baseProb *= 1.3;
    } else if (opponentModel.isConservative) {
      baseProb *= 0.7;
    }
    
    return baseProb.clamp(0.0, 0.9);
  }
  
  /// 识别游戏阶段
  GamePhase _identifyGamePhase(GameRound round) {
    int rounds = round.bidHistory.length;
    if (rounds <= 2) return GamePhase.opening;
    if (rounds <= 5) return GamePhase.midGame;
    return GamePhase.endGame;
  }
  
  /// 根据性格和阶段过滤选项
  List<Map<String, dynamic>> _filterByPersonalityAndPhase(
    List<Map<String, dynamic>> options,
    GamePhase phase,
    GameRound round,
  ) {
    // 根据性格设置过滤条件
    double minEV = -5.0;
    double maxRisk = 1.0;
    
    switch (personality.id) {
      case '0001': // Professor - 保守理性
      case 'professor':
        minEV = 0.0;
        maxRisk = 0.7;
        break;
      case '0002': // Gambler - 激进冒险
      case 'gambler':
        minEV = -10.0;
        maxRisk = 1.0;
        break;
      case '0003': // Provocateur - 心机深沉
      case 'provocateur':
        // 优先选择心理战术
        var psychOptions = options.where((o) => o['psychTactic'] != null).toList();
        if (psychOptions.isNotEmpty) return psychOptions;
        break;
    }
    
    // 阶段调整
    if (phase == GamePhase.endGame) {
      // 后期更倾向于质疑，但只有在EV足够高时
      var challenges = options.where((o) => o['type'] == 'challenge').toList();
      if (challenges.isNotEmpty && challenges[0]['expectedValue'] > 10.0) { // 提高阈值，避免错误质疑
        return challenges;
      }
    }
    
    // 应用过滤
    var filtered = options.where((o) {
      double ev = o['expectedValue'];
      double confidence = o['confidence'] ?? 0.5;
      
      // 特殊处理：如果是质疑且EV极低，一定要过滤掉
      if (o['type'] == 'challenge' && ev < -50.0) {
        return false; // 绝对不应该质疑
      }
      
      return ev >= minEV && confidence <= maxRisk;
    }).toList();
    
    // 如果过滤后为空，只返回正期望值的选项，避免选择糟糕的决策
    if (filtered.isEmpty) {
      filtered = options.where((o) => o['expectedValue'] > 0).toList();
      if (filtered.isEmpty) {
        // 如果还是空，选择期望值最高的（可能是负的，但选最不糟的）
        options.sort((a, b) => b['expectedValue'].compareTo(a['expectedValue']));
        return [options.first];
      }
    }
    
    return filtered;
  }
  
  /// 是否应该应用战术
  bool _shouldApplyTactic(
    Map<String, dynamic> option,
    Map<String, dynamic> tactic,
    GameRound round,
  ) {
    String condition = tactic['condition'];
    
    switch (condition) {
      case 'break_pattern':
        // 打破模式的条件
        return option['strategy'] != strategyState.lastStrategy;
      case 'endgame_pressure':
        // 后期施压条件
        return option['type'] == 'bid' && 
               (option['bid'] as Bid).quantity >= (round.currentBid?.quantity ?? 0) + 2;
      case 'induce_aggression':
        // 诱导激进的条件
        return option['strategy'] == 'semi_bluff' || option['strategy'] == 'bluff';
      default:
        return false;
    }
  }
  
  /// 更新策略状态
  void _updateStrategyState(Map<String, dynamic> choice, GameRound round) {
    // 更新最后的策略
    strategyState.lastStrategy = choice['strategy'] ?? '';
    
    // 检测是否建立了模式
    if (strategyState.strategyHistory.length >= 3) {
      int startIdx = math.max(0, strategyState.strategyHistory.length - 3);
      List<String> last3 = strategyState.strategyHistory.sublist(startIdx);
      String pattern = last3.join(',');
      if (pattern.contains('value_bet,value_bet') || pattern.contains('bluff,bluff')) {
        strategyState.hasEstablishedPattern = true;
        strategyState.patternStrength = 0.8;
      }
    }
    
    strategyState.strategyHistory.add(choice['strategy'] ?? '');
  }
  
  /// 是否应该改变节奏
  bool _shouldChangeRhythm(GameRound round) {
    // 每3-5轮改变一次节奏
    return round.bidHistory.length % (3 + random.nextInt(3)) == 0;
  }
  
  /// 紧急降级方案
  Map<String, dynamic> _emergencyFallback(GameRound round) {
    if (round.currentBid == null) {
      return {
        'type': 'bid',
        'bid': Bid(quantity: 2, value: random.nextInt(6) + 1),
        'expectedValue': 0.0,
        'confidence': 0.3,
        'strategy': 'emergency',
        'reasoning': '紧急降级',
      };
    }
    
    // 50%概率质疑
    if (random.nextDouble() < 0.5) {
      return {
        'type': 'challenge',
        'expectedValue': 0.0,
        'confidence': 0.5,
        'strategy': 'emergency',
        'reasoning': '紧急质疑',
      };
    }
    
    // 否则保守叫牌
    Bid safeBid = Bid(
      quantity: round.currentBid!.quantity + 1,
      value: round.currentBid!.value,
    );
    
    return {
      'type': 'bid',
      'bid': safeBid,
      'expectedValue': 0.0,
      'confidence': 0.3,
      'strategy': 'emergency',
      'reasoning': '紧急叫牌',
    };
  }
  
  // ============= 数学工具方法 =============
  
  // 二项分布计算已移动到probability_calculator.dart
  
  // 为了兼容，添加一个内部方法
  double _binomialAtLeast(int n, int k, double p) {
    if (k > n) return 0.0;
    if (k <= 0) return 1.0;
    
    // 使用probability_calculator的预计算值
    if (n == 5 && p == 1.0 / 3.0) {
      switch (k) {
        case 1: return 0.8683;
        case 2: return 0.5391;
        case 3: return 0.2101;
        case 4: return 0.0453;
        case 5: return 0.0041;
        default: return 0.0;
      }
    }
    
    if (n == 5 && p == 1.0 / 6.0) {
      switch (k) {
        case 1: return 0.5981;
        case 2: return 0.1962;
        case 3: return 0.0355;
        case 4: return 0.0032;
        case 5: return 0.0001;
        default: return 0.0;
      }
    }
    
    // 其他情况的通用计算
    double total = 0.0;
    for (int i = k; i <= n; i++) {
      double coeff = 1.0;
      for (int j = 0; j < i; j++) {
        coeff *= (n - j) / (j + 1);
      }
      total += coeff * math.pow(p, i) * math.pow(1 - p, n - i);
    }
    return total.clamp(0.0, 1.0);
  }
}

/// 对手模型 - 追踪和学习对手行为
class OpponentModel {
  // 对手统计
  int totalBids = 0;
  int bluffCount = 0;
  int challengeCount = 0;
  int aggressiveBids = 0;
  
  // 贝叶斯先验
  Map<int, double> priorDistribution = {};
  
  // 行为模式
  List<String> behaviorHistory = [];
  double adaptationLevel = 0.0;
  
  // 计算属性
  double get estimatedBluffRate => 
    totalBids > 0 ? bluffCount / totalBids : 0.3;
  
  bool get isAggressive =>
    totalBids > 3 && aggressiveBids / totalBids > 0.5;
    
  bool get isConservative =>
    totalBids > 3 && aggressiveBids / totalBids < 0.3;
  
  OpponentModel() {
    // 初始化均匀先验
    for (int i = 1; i <= 6; i++) {
      priorDistribution[i] = 1.0 / 6.0;
    }
  }
  
  /// 从游戏历史更新模型
  void updateFromHistory(GameRound round) {
    if (round.bidHistory.isEmpty) return;
    
    // 分析最新的叫牌
    var lastBid = round.bidHistory.last;
    // 注意：我们需要通过其他方式判断是否是玩家的叫牌
    // 简化处理：假设奇数轮是玩家，偶数轮是AI
    bool isPlayerBid = round.bidHistory.length % 2 == 1;
    
    if (isPlayerBid) {
      totalBids++;
      
      // 检测激进叫牌
      if (round.bidHistory.length > 1) {
        var prevBid = round.bidHistory[round.bidHistory.length - 2];
        if (lastBid.quantity - prevBid.quantity >= 2) {
          aggressiveBids++;
          behaviorHistory.add('aggressive');
        } else {
          behaviorHistory.add('normal');
        }
      }
      
      // 更新贝叶斯分布（简化版）
      _updateBayesianBelief(lastBid, round);
    }
    
    // 检测对手是否在适应
    _detectAdaptation();
  }
  
  /// 获取后验分布
  Map<int, double> getPosteriorDistribution(Bid? currentBid, bool onesAreCalled) {
    // 如果没有足够数据，返回先验
    if (totalBids < 3) return priorDistribution;
    
    // 根据历史调整分布
    Map<int, double> posterior = Map.from(priorDistribution);
    
    // 如果对手经常虚张，降低其声称点数的概率
    if (currentBid != null && estimatedBluffRate > 0.4) {
      posterior[currentBid.value] = (posterior[currentBid.value] ?? 0.167) * 0.7;
      
      // 重新归一化
      double sum = posterior.values.fold(0.0, (a, b) => a + b);
      posterior.forEach((key, value) {
        posterior[key] = value / sum;
      });
    }
    
    return posterior;
  }
  
  /// 更新贝叶斯信念
  void _updateBayesianBelief(Bid bid, GameRound round) {
    // 简化的贝叶斯更新
    // 如果叫牌被质疑并失败，说明对手可能没有那么多该点数
    // 这里简化处理，实际应该基于完整的游戏结果
    
    double learningRate = 0.1;
    
    // 如果叫牌数量很大，可能是虚张
    if (bid.quantity >= 6) {
      priorDistribution[bid.value] = 
        (priorDistribution[bid.value] ?? 0.167) * (1.0 - learningRate);
    }
    
    // 重新归一化
    double sum = priorDistribution.values.fold(0.0, (a, b) => a + b);
    if (sum > 0) {
      priorDistribution.forEach((key, value) {
        priorDistribution[key] = value / sum;
      });
    }
  }
  
  /// 检测对手适应
  void _detectAdaptation() {
    if (behaviorHistory.length < 6) return;
    
    // 检查最近的行为是否与早期不同
    int recentStart = math.max(0, behaviorHistory.length - 3);
    var recent = behaviorHistory.sublist(recentStart);
    var early = behaviorHistory.take(3).toList();
    
    int changes = 0;
    for (int i = 0; i < 3; i++) {
      if (i < recent.length && i < early.length && recent[i] != early[i]) {
        changes++;
      }
    }
    
    adaptationLevel = changes / 3.0;
  }
  
  /// 检测是否已适应我们
  bool hasAdaptedToUs() {
    return adaptationLevel > 0.6 && behaviorHistory.length > 5;
  }
}

/// 策略状态 - 追踪我们的策略执行
class StrategyState {
  String currentStyle = 'balanced';
  String lastStrategy = '';
  List<String> strategyHistory = [];
  
  bool hasEstablishedPattern = false;
  bool hasExecutedTrap = false;
  double patternStrength = 0.0;
  
  int styleSwitch = 0;
  int successfulBluffs = 0;
  int failedBluffs = 0;
  
  void reset() {
    hasEstablishedPattern = false;
    hasExecutedTrap = false;
    patternStrength = 0.0;
    strategyHistory.clear();
  }
}

/// 游戏阶段枚举
enum GamePhase {
  opening,  // 开局
  midGame,  // 中盘
  endGame,  // 残局
}
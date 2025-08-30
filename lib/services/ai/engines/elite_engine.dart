/// Elite AI引擎 - 重构简化版
/// 
/// 保留核心的贝叶斯推理和心理战术
library;

import 'dart:math' as math;
import '../../../models/game_state.dart';
import '../../../models/ai_personality.dart';
import '../../../utils/logger_utils.dart';
import '../../probability_calculator.dart';
import '../models/elite_opponent_model.dart';

/// 策略状态 - 追踪策略执行
class StrategyState {
  int consecutiveBluffs = 0;
  int totalBluffs = 0;
  int successfulBluffs = 0;
  bool lastWasBluff = false;
  String lastStrategy = 'balanced';
  
  void recordBluff(bool success) {
    totalBluffs++;
    if (success) successfulBluffs++;
    consecutiveBluffs = success ? 0 : consecutiveBluffs + 1;
    lastWasBluff = true;
  }
  
  void recordNormal() {
    consecutiveBluffs = 0;
    lastWasBluff = false;
  }
  
  bool shouldChangeStyle() {
    return consecutiveBluffs > 2 || 
           (totalBluffs > 5 && successfulBluffs / totalBluffs < 0.3);
  }
}

class EliteAIEngine {
  final AIPersonality personality;
  final ProbabilityCalculator probabilityCalculator = ProbabilityCalculator();
  final math.Random random = math.Random();
  
  // 对手建模
  late EliteOpponentModel opponentModel;
  
  // 策略状态
  StrategyState strategyState = StrategyState();
  
  EliteAIEngine({required this.personality}) {
    opponentModel = EliteOpponentModel();
  }
  
  /// 主决策入口
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
    
    // 4. 选择最佳策略
    var finalChoice = _selectBestOption(psychOptions, round);
    
    // 5. 保存选项供复盘
    finalChoice['allOptions'] = psychOptions.take(3).toList();
    
    AILogger.logParsing('Elite AI决策完成', {
      'type': finalChoice['type'],
      'confidence': finalChoice['confidence'],
      'strategy': finalChoice['strategy'] ?? 'unknown',
    });
    
    return finalChoice;
  }
  
  /// 计算数学最优选项
  List<Map<String, dynamic>> _calculateMathematicalOptions(GameRound round) {
    List<Map<String, dynamic>> options = [];
    
    // 获取骰子统计
    Map<int, int> ourCounts = {};
    for (int i = 1; i <= 6; i++) {
      ourCounts[i] = round.aiDice.countValue(i, onesAreCalled: round.onesAreCalled);
    }
    
    // 1. 质疑选项
    if (round.currentBid != null) {
      double challengeProb = probabilityCalculator.calculateChallengeSuccessProbability(
        currentBid: round.currentBid!,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      options.add({
        'type': 'challenge',
        'confidence': challengeProb,
        'successRate': challengeProb,
        'expectedValue': challengeProb * 10 - (1 - challengeProb) * 10,
        'reasoning': '质疑成功率 ${(challengeProb * 100).toStringAsFixed(1)}%',
      });
    }
    
    // 2. 叫牌选项
    options.addAll(_generateBidOptions(round, ourCounts));
    
    // 按期望值排序
    options.sort((a, b) => b['expectedValue'].compareTo(a['expectedValue']));
    
    return options;
  }
  
  /// 生成叫牌选项
  List<Map<String, dynamic>> _generateBidOptions(GameRound round, Map<int, int> ourCounts) {
    List<Map<String, dynamic>> bidOptions = [];
    Bid? currentBid = round.currentBid;
    
    // 生成候选叫牌
    List<Bid> candidates = [];
    
    if (currentBid == null) {
      // 开局叫牌
      for (int qty = 2; qty <= 4; qty++) {
        for (int val = 1; val <= 6; val++) {
          candidates.add(Bid(quantity: qty, value: val));
        }
      }
    } else {
      // 后续叫牌
      for (int qty = currentBid.quantity; qty <= math.min(10, currentBid.quantity + 3); qty++) {
        for (int val = 1; val <= 6; val++) {
          if (_isValidBid(Bid(quantity: qty, value: val), currentBid, onesAreCalled: round.onesAreCalled)) {
            candidates.add(Bid(quantity: qty, value: val));
          }
        }
      }
    }
    
    // 计算每个叫牌的价值
    for (var bid in candidates) {
      double successRate = probabilityCalculator.calculateBidSuccessProbability(
        bid: bid,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      // 计算期望值
      double ev = _calculateBidExpectedValue(bid, successRate, round);
      
      // 识别策略类型
      String strategy = _identifyBidStrategy(bid, ourCounts, successRate);
      
      bidOptions.add({
        'type': 'bid',
        'bid': bid,
        'confidence': successRate,
        'successRate': successRate,
        'expectedValue': ev,
        'strategy': strategy,
        'reasoning': _getBidReasoning(strategy, successRate),
      });
    }
    
    return bidOptions;
  }
  
  /// 应用心理战术
  List<Map<String, dynamic>> _applyPsychologicalWarfare(
    List<Map<String, dynamic>> options, 
    GameRound round
  ) {
    // 根据对手状态调整选项权重
    for (var option in options) {
      double adjustment = 1.0;
      
      // 如果对手保守，激进选项更有价值
      if (opponentModel.isConservative) {
        if (option['strategy'] == 'bluff' || option['strategy'] == 'pure_bluff') {
          adjustment *= 1.3;
        }
      }
      
      // 如果对手激进，保守选项更有价值
      if (opponentModel.isAggressive) {
        if (option['type'] == 'challenge') {
          adjustment *= 1.2;
        }
      }
      
      // 如果对手已适应，需要改变策略
      if (opponentModel.hasAdaptedToUs()) {
        if (option['strategy'] != strategyState.lastStrategy) {
          adjustment *= 1.15;
        }
      }
      
      // 应用调整
      option['expectedValue'] = (option['expectedValue'] as double) * adjustment;
      
      // 添加心理效果标记
      if (option['type'] == 'bid') {
        var bid = option['bid'] as Bid;
        if (bid.quantity >= 7) {
          option['psychEffect'] = 'intimidation';
        } else if (option['successRate'] < 0.3) {
          option['psychEffect'] = 'bluff';
        }
      }
    }
    
    // 重新排序
    options.sort((a, b) => b['expectedValue'].compareTo(a['expectedValue']));
    
    return options;
  }
  
  /// 选择最佳选项
  Map<String, dynamic> _selectBestOption(
    List<Map<String, dynamic>> options,
    GameRound round,
  ) {
    if (options.isEmpty) {
      // 紧急降级
      return _emergencyFallback(round);
    }
    
    // 获取最佳选项
    var best = options.first;
    
    // 根据性格微调
    if (personality.bluffRatio > 0.6 && random.nextDouble() < 0.3) {
      // 高诈唬性格偶尔选择次优但更激进的选项
      for (var option in options.take(3)) {
        if (option['strategy'] == 'bluff' || option['strategy'] == 'pure_bluff') {
          best = option;
          break;
        }
      }
    }
    
    // 更新策略状态
    if (best['type'] == 'bid') {
      bool isBluff = (best['successRate'] ?? 0.5) < 0.4;
      if (isBluff) {
        strategyState.recordBluff(false); // 成功与否需要后续更新
      } else {
        strategyState.recordNormal();
      }
      strategyState.lastStrategy = best['strategy'] ?? 'unknown';
    }
    
    return best;
  }
  
  /// 计算叫牌期望值
  double _calculateBidExpectedValue(Bid bid, double successRate, GameRound round) {
    // 基础期望值
    double ev = successRate * 10 - (1 - successRate) * 15;
    
    // 根据回合数调整
    ev += round.bidHistory.length * 0.5;
    
    // 高风险高回报
    if (bid.quantity >= 7) {
      ev += 3;
    }
    
    return ev;
  }
  
  /// 识别叫牌策略
  String _identifyBidStrategy(Bid bid, Map<int, int> ourCounts, double successRate) {
    int ourCount = ourCounts[bid.value] ?? 0;
    double ratio = ourCount / bid.quantity;
    
    if (successRate >= 0.7) return 'value_bet';
    if (successRate >= 0.5) return 'semi_bluff';
    if (successRate >= 0.3) return 'bluff';
    return 'pure_bluff';
  }
  
  /// 获取叫牌理由
  String _getBidReasoning(String strategy, double successRate) {
    String confidence = successRate >= 0.7 ? '高置信' :
                       successRate >= 0.5 ? '中置信' :
                       successRate >= 0.3 ? '低置信' : '诈唬';
    
    switch (strategy) {
      case 'value_bet':
        return '$confidence - 价值叫牌';
      case 'semi_bluff':
        return '$confidence - 半诈唬';
      case 'bluff':
        return '$confidence - 战术诈唬';
      case 'pure_bluff':
        return '$confidence - 纯诈唬';
      default:
        return confidence;
    }
  }
  
  /// 检查叫牌是否合法
  bool _isValidBid(Bid newBid, Bid currentBid, {bool onesAreCalled = false}) {
    // 使用Bid类自带的isHigherThan方法，它已经正确实现了1>6>5>4>3>2的规则
    return newBid.isHigherThan(currentBid, onesAreCalled: onesAreCalled);
  }
  
  /// 紧急降级
  Map<String, dynamic> _emergencyFallback(GameRound round) {
    if (round.currentBid == null) {
      return {
        'type': 'bid',
        'bid': Bid(quantity: 2, value: random.nextInt(6) + 1),
        'confidence': 0.5,
        'expectedValue': 0,
        'strategy': 'emergency',
        'reasoning': '紧急开局',
      };
    }
    
    // 质疑
    return {
      'type': 'challenge',
      'confidence': 0.5,
      'expectedValue': 0,
      'strategy': 'emergency',
      'reasoning': '紧急质疑',
    };
  }
  
  /// 重置引擎（新游戏）
  void reset() {
    opponentModel.reset();
    strategyState = StrategyState();
  }
}
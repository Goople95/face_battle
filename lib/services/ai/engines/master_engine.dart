/// 大师级AI引擎 - 重构简化版
/// 
/// 使用组件化架构，代码更清晰、可维护
library;

import 'dart:math' as math;
import '../../../models/game_state.dart';
import '../../../models/ai_personality.dart';
import '../../../utils/logger_utils.dart';
import '../../probability_calculator.dart';
import '../models/ai_models.dart';
import '../components/game_understanding.dart';
import '../components/opponent_mind.dart';
import '../components/strategic_planner.dart';
import '../components/game_memory.dart';
import '../strategies/strategy_factory.dart';

class MasterAIEngine {
  final AIPersonality personality;
  final ProbabilityCalculator probabilityCalculator = ProbabilityCalculator();
  final math.Random random = math.Random();
  
  // 核心组件
  late final GameUnderstanding gameUnderstanding;
  late final OpponentMind opponentMind;
  late final StrategicPlanner strategicPlanner;
  late final GameMemory gameMemory;
  late final StrategyFactory strategyFactory;
  
  MasterAIEngine({required this.personality}) {
    gameUnderstanding = GameUnderstanding();
    opponentMind = OpponentMind();
    strategicPlanner = StrategicPlanner(personality);
    gameMemory = GameMemory();
    strategyFactory = StrategyFactory(personality);
  }
  
  /// 主决策方法
  Map<String, dynamic> makeDecision(GameRound round) {
    AILogger.logParsing('Master AI 决策开始', {
      'personality': personality.id,
      'round': round.bidHistory.length,
      'currentBid': round.currentBid?.toString(),
    });
    
    // 1. 分析游戏局势
    var situation = gameUnderstanding.analyzeSituation(round, gameMemory);
    
    // 2. 分析对手状态
    var opponentState = opponentMind.readOpponent(round, gameMemory);
    
    // 3. 制定策略
    var strategy = strategicPlanner.planStrategy(situation, opponentState);
    
    // 4. 执行策略
    var executor = strategyFactory.getExecutor(strategy.type);
    var decision = executor.execute(round, situation, opponentState);
    
    // 5. 生成所有可选项（用于UI显示）
    var allOptions = _generateAllOptions(round, situation);
    decision['allOptions'] = allOptions;
    
    // 6. 记录和学习
    gameMemory.recordRound(round, decision, strategy);
    opponentMind.learn(round, decision);
    
    AILogger.logParsing('Master AI 决策完成', {
      'type': decision['type'],
      'confidence': decision['confidence'],
      'strategy': decision['strategy'],
    });
    
    return decision;
  }
  
  /// 生成所有可能的选项（用于复盘显示）
  List<Map<String, dynamic>> _generateAllOptions(GameRound round, Situation situation) {
    List<Map<String, dynamic>> options = [];
    
    // 如果有当前叫牌，添加质疑选项
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
        'strategy': 'challenge',
        'reasoning': '质疑成功率 ${(challengeProb * 100).toStringAsFixed(1)}%',
      });
    }
    
    // 生成不同的叫牌选项
    List<Bid> candidateBids = _generateCandidateBids(round, situation);
    
    for (var bid in candidateBids) {
      double successRate = probabilityCalculator.calculateBidSuccessProbability(
        bid: bid,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      // 判断策略类型
      String strategy = _identifyBidStrategy(bid, situation, round);
      
      options.add({
        'type': 'bid',
        'bid': bid,
        'confidence': successRate,
        'successRate': successRate,
        'strategy': strategy,
        'reasoning': _getBidReasoning(strategy, successRate),
      });
    }
    
    // 按成功率排序
    options.sort((a, b) => b['successRate'].compareTo(a['successRate']));
    
    // 只返回前5个选项
    return options.take(5).toList();
  }
  
  /// 生成候选叫牌
  List<Bid> _generateCandidateBids(GameRound round, Situation situation) {
    List<Bid> candidates = [];
    
    if (round.currentBid == null) {
      // 开局叫牌
      for (int qty = 2; qty <= 4; qty++) {
        candidates.add(Bid(quantity: qty, value: situation.ourBestValue));
        if (situation.ourSecondBestValue != situation.ourBestValue) {
          candidates.add(Bid(quantity: qty, value: situation.ourSecondBestValue));
        }
      }
    } else {
      // 后续叫牌
      Bid current = round.currentBid!;
      
      // 最小增量
      candidates.add(Bid(quantity: current.quantity + 1, value: current.value));
      
      // 增加1-2个
      if (current.quantity < 8) {
        candidates.add(Bid(quantity: current.quantity + 2, value: current.value));
      }
      
      // 换点数
      for (int value = 1; value <= 6; value++) {
        if (value != current.value) {
          Bid newBid = Bid(quantity: current.quantity, value: value);
          if (_isValidBid(newBid, current, onesAreCalled: round.onesAreCalled)) {
            candidates.add(newBid);
          } else {
            candidates.add(Bid(quantity: current.quantity + 1, value: value));
          }
        }
      }
    }
    
    // 过滤掉太高的叫牌
    return candidates.where((bid) => bid.quantity <= 9).toList();
  }
  
  /// 判断叫牌策略类型
  String _identifyBidStrategy(Bid bid, Situation situation, GameRound round) {
    int ourCount = round.aiDice.countValue(bid.value, onesAreCalled: round.onesAreCalled);
    double ratio = ourCount / bid.quantity;
    
    if (ratio >= 0.7) return 'value_bet';
    if (ratio >= 0.5) return 'semi_bluff';
    if (ratio >= 0.3) return 'tactical_bluff';
    return 'pure_bluff';
  }
  
  /// 获取叫牌理由
  String _getBidReasoning(String strategy, double successRate) {
    String confidence = probabilityCalculator.getStrategyAdvice(successRate);
    
    switch (strategy) {
      case 'value_bet':
        return '$confidence - 基于实际持有';
      case 'semi_bluff':
        return '$confidence - 半诈唬';
      case 'tactical_bluff':
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
  
  /// 重置引擎（新游戏开始）
  void reset() {
    gameMemory.reset();
    strategyFactory.reset();
  }
}
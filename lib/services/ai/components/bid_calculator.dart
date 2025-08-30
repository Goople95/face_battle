/// 叫牌选项计算器 - 优化版
/// 
/// 使用统一的概率计算器，避免重复代码
library;

import 'dart:math' as math;
import '../../../models/game_state.dart';
import '../../probability_calculator.dart';

class BidCalculator {
  static final ProbabilityCalculator _probabilityCalc = ProbabilityCalculator();
  static final math.Random _random = math.Random();
  
  /// 计算所有可能的决策选项
  static List<Map<String, dynamic>> calculateOptions(GameRound round) {
    List<Map<String, dynamic>> options = [];
    
    // 获取骰子统计
    Map<int, int> ourCounts = {};
    for (int i = 1; i <= 6; i++) {
      ourCounts[i] = round.aiDice.countValue(i, onesAreCalled: round.onesAreCalled);
    }
    
    // 1. 质疑选项
    if (round.currentBid != null) {
      double challengeRate = _probabilityCalc.calculateChallengeSuccessProbability(
        currentBid: round.currentBid!,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      options.add({
        'type': 'challenge',
        'successRate': challengeRate,
        'confidence': challengeRate,
        'strategy': _getStrategyType(challengeRate),
        'reasoning': _probabilityCalc.getProbabilityDescription(challengeRate),
      });
    }
    
    // 2. 叫牌选项
    options.addAll(_generateBidOptions(round, ourCounts));
    
    // 3. 按成功率排序
    options.sort((a, b) => b['successRate'].compareTo(a['successRate']));
    
    return options.take(10).toList();
  }
  
  /// 生成叫牌选项
  static List<Map<String, dynamic>> _generateBidOptions(
    GameRound round,
    Map<int, int> ourCounts,
  ) {
    List<Map<String, dynamic>> bidOptions = [];
    
    // 生成候选叫牌
    List<Bid> candidates = _generateCandidates(round, ourCounts);
    
    for (var bid in candidates) {
      double successRate = _probabilityCalc.calculateBidSuccessProbability(
        bid: bid,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      // 只保留有意义的选项
      if (successRate > 0.1 || bidOptions.length < 3) {
        bidOptions.add({
          'type': 'bid',
          'bid': bid,
          'successRate': successRate,
          'confidence': successRate,
          'strategy': _getStrategyType(successRate),
          'reasoning': _probabilityCalc.getStrategyAdvice(successRate),
        });
      }
    }
    
    return bidOptions;
  }
  
  /// 生成候选叫牌
  static List<Bid> _generateCandidates(GameRound round, Map<int, int> ourCounts) {
    List<Bid> candidates = [];
    
    if (round.currentBid == null) {
      // 开局叫牌
      for (int qty = 2; qty <= 4; qty++) {
        for (int val = 1; val <= 6; val++) {
          candidates.add(Bid(quantity: qty, value: val));
        }
      }
    } else {
      Bid current = round.currentBid!;
      
      // 基于当前叫牌生成
      for (int qty = current.quantity; qty <= math.min(10, current.quantity + 3); qty++) {
        for (int val = 1; val <= 6; val++) {
          Bid newBid = Bid(quantity: qty, value: val);
          if (_isValidBid(newBid, current, onesAreCalled: round.onesAreCalled)) {
            candidates.add(newBid);
          }
        }
      }
      
      // 确保至少有最小增量选项
      if (candidates.isEmpty) {
        candidates.add(Bid(quantity: current.quantity + 1, value: current.value));
      }
    }
    
    return candidates;
  }
  
  /// 检查叫牌是否合法
  static bool _isValidBid(Bid newBid, Bid currentBid, {bool onesAreCalled = false}) {
    // 使用Bid类自带的isHigherThan方法，它已经正确实现了1>6>5>4>3>2的规则
    return newBid.isHigherThan(currentBid, onesAreCalled: onesAreCalled);
  }
  
  /// 根据成功率获取策略类型
  static String _getStrategyType(double successRate) {
    if (successRate >= 0.8) return 'value_bet';
    if (successRate >= 0.6) return 'semi_bluff';
    if (successRate >= 0.4) return 'tactical_bluff';
    if (successRate >= 0.2) return 'bluff';
    return 'pure_bluff';
  }
}
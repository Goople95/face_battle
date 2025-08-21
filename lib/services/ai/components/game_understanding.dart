/// 游戏理解组件 - 分析游戏局势
/// 
/// 负责理解当前游戏状态，包括：
/// - 分析我们的骰子组合
/// - 评估当前叫牌情况
/// - 计算风险等级
/// - 提供局势评估
library;

import 'dart:math' as math;
import '../../../models/game_state.dart';
import '../../probability_calculator.dart';
import '../models/ai_models.dart';
import 'game_memory.dart';

class GameUnderstanding {
  final probabilityCalculator = ProbabilityCalculator();
  
  /// 分析当前游戏局势
  Situation analyzeSituation(GameRound round, GameMemory memory) {
    var situation = Situation();
    
    // 分析我们的骰子
    Map<int, int> ourCounts = {};
    for (int i = 1; i <= 6; i++) {
      ourCounts[i] = round.aiDice.countValue(i, onesAreCalled: round.onesAreCalled);
    }
    
    // 找出我们最强和次强的点数
    var sorted = ourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    situation.ourBestValue = sorted[0].key;
    situation.ourBestCount = sorted[0].value;
    situation.ourSecondBestValue = sorted.length > 1 ? sorted[1].key : sorted[0].key;
    
    // 分析当前叫牌
    if (round.currentBid != null) {
      situation.bidQuantity = round.currentBid!.quantity;
      situation.ourCount = ourCounts[round.currentBid!.value] ?? 0;
      situation.opponentNeeds = round.currentBid!.quantity - situation.ourCount;
      
      situation.weHaveEnough = situation.opponentNeeds <= 0;
      situation.impossibleForOpponent = situation.opponentNeeds > 5;
      
      // 使用统一的概率计算器
      situation.opponentSuccessProb = probabilityCalculator.calculateBidSuccessProbability(
        bid: round.currentBid!,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
    }
    
    // 计算我们的整体实力
    situation.ourStrength = situation.ourBestCount / 5.0;
    
    // 计算风险等级
    situation.risk = _calculateRisk(round, situation);
    
    return situation;
  }
  
  /// 计算当前风险等级
  double _calculateRisk(GameRound round, Situation situation) {
    double risk = 0.3; // 基础风险
    
    // 回合数越多，风险越高
    risk += round.bidHistory.length * 0.05;
    
    // 叫牌数量越高，风险越高
    if (round.currentBid != null) {
      risk += round.currentBid!.quantity * 0.05;
    }
    
    // 我们的牌力越弱，风险越高
    risk += (1 - situation.ourStrength) * 0.2;
    
    return math.min(1.0, risk);
  }
}
/// 激进策略执行器 - 主动进攻，施加压力
/// 
/// 特点：
/// - 频繁诈唬
/// - 大幅提高叫牌
/// - 给对手施压

import '../models/ai_models.dart';
import '../../../models/game_state.dart';
import '../../../models/ai_personality.dart';
import 'strategy_executor.dart';

class AggressiveStrategyExecutor extends StrategyExecutor {
  AggressiveStrategyExecutor(AIPersonality personality) : super(personality);
  
  @override
  Map<String, dynamic> execute(
    GameRound round,
    Situation situation,
    OpponentState opponentState,
  ) {
    // 激进策略的核心：主动进攻，频繁诈唬
    
    // 1. 如果没有当前叫牌，激进开局
    if (round.currentBid == null) {
      // 激进开局：3-4个
      int quantity = 3 + (random.nextDouble() < 0.5 ? 1 : 0);
      int value = random.nextInt(6) + 1;
      
      return createDecision(
        type: 'bid',
        bid: Bid(quantity: quantity, value: value),
        confidence: 0.65,
        strategy: 'aggressive_opening',
        reasoning: '激进开局，施加压力',
      );
    }
    
    // 2. 如果对手显示弱势，加大压力
    if (opponentState.isWeak || opponentState.isNervous) {
      Bid? aggressiveBid = calculateAggressiveBid(round, situation);
      
      if (aggressiveBid != null && aggressiveBid.quantity <= 8) {
        double bidSuccess = probabilityCalculator.calculateBidSuccessProbability(
          bid: aggressiveBid,
          ourDice: round.aiDice,
          onesAreCalled: round.onesAreCalled,
        );
        
        // 激进策略：即使成功率较低也敢叫
        if (bidSuccess > 0.2 || opponentState.isWeak) {
          return createDecision(
            type: 'bid',
            bid: aggressiveBid,
            confidence: bidSuccess,
            strategy: 'aggressive_pressure',
            reasoning: '对手示弱，加大压力',
          );
        }
      }
    }
    
    // 3. 计算激进叫牌
    Bid currentBid = round.currentBid!;
    
    // 大幅提高数量
    int increase = personality.riskAppetite > 0.7 ? 2 : 1;
    if (opponentState.isConservative) {
      increase++; // 对保守对手更激进
    }
    
    Bid aggressiveBid = Bid(
      quantity: currentBid.quantity + increase,
      value: currentBid.value,
    );
    
    // 偶尔换点数诈唬
    if (random.nextDouble() < 0.3) {
      int newValue = random.nextInt(6) + 1;
      if (newValue != currentBid.value) {
        aggressiveBid = Bid(
          quantity: currentBid.quantity + 1,
          value: newValue,
        );
      }
    }
    
    // 4. 检查是否太过分
    if (aggressiveBid.quantity > 9) {
      // 太高了，考虑质疑
      double challengeProb = probabilityCalculator.calculateChallengeSuccessProbability(
        currentBid: currentBid,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      if (challengeProb > 0.7) {
        return createDecision(
          type: 'challenge',
          confidence: challengeProb,
          strategy: 'aggressive_limit_challenge',
          reasoning: '已达极限，转为质疑',
        );
      }
    }
    
    // 5. 计算成功率
    double bidSuccess = probabilityCalculator.calculateBidSuccessProbability(
      bid: aggressiveBid,
      ourDice: round.aiDice,
      onesAreCalled: round.onesAreCalled,
    );
    
    // 6. 激进决策：低成功率也敢叫
    if (bidSuccess > 0.15) {
      // 根据对手状态调整策略描述
      String reasoning = bidSuccess > 0.5 ? '强势推进' : 
                        bidSuccess > 0.3 ? '激进诈唬' : 
                        '纯诈唬施压';
      
      return createDecision(
        type: 'bid',
        bid: aggressiveBid,
        confidence: bidSuccess,
        strategy: bidSuccess > 0.3 ? 'aggressive_push' : 'aggressive_bluff',
        reasoning: reasoning,
      );
    }
    
    // 7. 如果实在不行，考虑质疑
    double challengeProb = probabilityCalculator.calculateChallengeSuccessProbability(
      currentBid: currentBid,
      ourDice: round.aiDice,
      onesAreCalled: round.onesAreCalled,
    );
    
    if (challengeProb > 0.5) {
      return createDecision(
        type: 'challenge',
        confidence: challengeProb,
        strategy: 'aggressive_tactical_challenge',
        reasoning: '战术性质疑',
      );
    }
    
    // 8. 最后的诈唬
    return createDecision(
      type: 'bid',
      bid: Bid(quantity: currentBid.quantity + 1, value: currentBid.value),
      confidence: 0.2,
      strategy: 'aggressive_last_bluff',
      reasoning: '最后一搏',
    );
  }
}
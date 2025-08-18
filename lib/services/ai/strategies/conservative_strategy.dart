/// 保守策略执行器 - 谨慎为主，优先质疑
/// 
/// 特点：
/// - 只在有把握时叫牌
/// - 积极质疑可疑叫牌
/// - 避免高风险决策

import '../models/ai_models.dart';
import '../../../models/game_state.dart';
import '../../../models/ai_personality.dart';
import 'strategy_executor.dart';

class ConservativeStrategyExecutor extends StrategyExecutor {
  ConservativeStrategyExecutor(AIPersonality personality) : super(personality);
  
  @override
  Map<String, dynamic> execute(
    GameRound round,
    Situation situation,
    OpponentState opponentState,
  ) {
    // 保守策略的核心：只在有把握时叫牌
    
    // 1. 如果没有当前叫牌，保守开局
    if (round.currentBid == null) {
      int safeQuantity = situation.ourBestCount;
      if (safeQuantity < 2) safeQuantity = 2;
      
      return createDecision(
        type: 'bid',
        bid: Bid(quantity: safeQuantity, value: situation.ourBestValue),
        confidence: 0.7,
        strategy: 'conservative_opening',
        reasoning: '保守开局，基于实际持有',
      );
    }
    
    // 2. 评估是否应该质疑
    double challengeProb = probabilityCalculator.calculateChallengeSuccessProbability(
      currentBid: round.currentBid!,
      ourDice: round.aiDice,
      onesAreCalled: round.onesAreCalled,
    );
    
    // 保守策略：超过60%概率就质疑
    if (challengeProb > 0.6) {
      return createDecision(
        type: 'challenge',
        confidence: challengeProb,
        strategy: 'conservative_challenge',
        reasoning: '质疑概率${(challengeProb * 100).toStringAsFixed(1)}%，值得质疑',
      );
    }
    
    // 3. 如果对手叫牌很高，更倾向质疑
    if (round.currentBid!.quantity >= 7 && challengeProb > 0.4) {
      return createDecision(
        type: 'challenge',
        confidence: challengeProb,
        strategy: 'conservative_high_challenge',
        reasoning: '叫牌过高，风险太大',
      );
    }
    
    // 4. 尝试安全叫牌
    Bid? safeBid = calculateSafeBid(round, situation);
    
    if (safeBid != null) {
      // 计算这个叫牌的成功率
      double bidSuccess = probabilityCalculator.calculateBidSuccessProbability(
        bid: safeBid,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      // 保守策略：只在成功率超过50%时叫牌
      if (bidSuccess > 0.5) {
        return createDecision(
          type: 'bid',
          bid: safeBid,
          confidence: bidSuccess,
          strategy: 'conservative_safe',
          reasoning: '安全叫牌，成功率${(bidSuccess * 100).toStringAsFixed(1)}%',
        );
      }
      
      // 如果成功率太低，考虑最小增量叫牌
      if (bidSuccess > 0.3) {
        Bid minBid = Bid(
          quantity: round.currentBid!.quantity + 1,
          value: round.currentBid!.value,
        );
        
        double minBidSuccess = probabilityCalculator.calculateBidSuccessProbability(
          bid: minBid,
          ourDice: round.aiDice,
          onesAreCalled: round.onesAreCalled,
        );
        
        if (minBidSuccess > 0.4) {
          return createDecision(
            type: 'bid',
            bid: minBid,
            confidence: minBidSuccess,
            strategy: 'conservative_minimal',
            reasoning: '最小增量，降低风险',
          );
        }
      }
    }
    
    // 5. 如果叫牌成功率太低，必须质疑
    if (challengeProb > 0.3) {
      return createDecision(
        type: 'challenge',
        confidence: challengeProb,
        strategy: 'conservative_forced_challenge',
        reasoning: '无法安全叫牌，选择质疑',
      );
    }
    
    // 6. 被迫叫牌（极少情况）
    Bid forcedBid = Bid(
      quantity: round.currentBid!.quantity + 1,
      value: round.currentBid!.value,
    );
    
    return createDecision(
      type: 'bid',
      bid: forcedBid,
      confidence: 0.3,
      strategy: 'conservative_forced',
      reasoning: '被迫继续',
    );
  }
}
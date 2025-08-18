/// 平衡策略执行器 - 根据局势灵活调整
/// 
/// 特点：
/// - 根据数学期望决策
/// - 平衡风险和收益
/// - 适应性强

import '../models/ai_models.dart';
import '../../../models/game_state.dart';
import '../../../models/ai_personality.dart';
import 'strategy_executor.dart';

class BalancedStrategyExecutor extends StrategyExecutor {
  BalancedStrategyExecutor(AIPersonality personality) : super(personality);
  
  @override
  Map<String, dynamic> execute(
    GameRound round,
    Situation situation,
    OpponentState opponentState,
  ) {
    // 平衡策略：根据期望值决策
    
    // 1. 开局
    if (round.currentBid == null) {
      // 平衡开局：基于实际持有略加
      int quantity = situation.ourBestCount + (random.nextDouble() < 0.5 ? 1 : 0);
      if (quantity < 2) quantity = 2;
      
      return createDecision(
        type: 'bid',
        bid: Bid(quantity: quantity, value: situation.ourBestValue),
        confidence: 0.6,
        strategy: 'balanced_opening',
        reasoning: '平衡开局',
      );
    }
    
    // 2. 计算质疑期望值
    double challengeProb = probabilityCalculator.calculateChallengeSuccessProbability(
      currentBid: round.currentBid!,
      ourDice: round.aiDice,
      onesAreCalled: round.onesAreCalled,
    );
    
    // 3. 计算继续叫牌的选项
    List<Map<String, dynamic>> bidOptions = [];
    
    // 选项1：安全叫牌
    Bid? safeBid = calculateSafeBid(round, situation);
    if (safeBid != null && safeBid.quantity <= 8) {
      double success = probabilityCalculator.calculateBidSuccessProbability(
        bid: safeBid,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      bidOptions.add({
        'bid': safeBid,
        'success': success,
        'risk': 1 - success,
        'type': 'safe',
      });
    }
    
    // 选项2：最小增量
    Bid minBid = Bid(
      quantity: round.currentBid!.quantity + 1,
      value: round.currentBid!.value,
    );
    
    if (minBid.quantity <= 9) {
      double success = probabilityCalculator.calculateBidSuccessProbability(
        bid: minBid,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      bidOptions.add({
        'bid': minBid,
        'success': success,
        'risk': 1 - success,
        'type': 'minimal',
      });
    }
    
    // 选项3：适度激进
    if (situation.ourStrength > 0.4 && round.currentBid!.quantity < 6) {
      Bid moderateBid = Bid(
        quantity: round.currentBid!.quantity + 1,
        value: situation.ourBestValue,
      );
      
      moderateBid = ensureLegalBid(moderateBid, round);
      
      if (moderateBid.quantity <= 7) {
        double success = probabilityCalculator.calculateBidSuccessProbability(
          bid: moderateBid,
          ourDice: round.aiDice,
          onesAreCalled: round.onesAreCalled,
        );
        
        bidOptions.add({
          'bid': moderateBid,
          'success': success,
          'risk': 1 - success,
          'type': 'moderate',
        });
      }
    }
    
    // 4. 计算期望值并选择最佳选项
    double challengeEV = challengeProb * 1.0 - (1 - challengeProb) * 1.2; // 质疑的期望值
    
    Map<String, dynamic>? bestBidOption;
    double bestBidEV = -999;
    
    for (var option in bidOptions) {
      // 继续叫牌的期望值
      double continueEV = option['success'] * 0.5 - option['risk'] * 1.0;
      
      // 根据对手状态调整
      if (opponentState.isWeak) {
        continueEV += 0.2; // 对弱势对手更有利
      }
      if (opponentState.challengeProbability > 0.5) {
        continueEV -= 0.3; // 对手可能质疑，风险增加
      }
      
      if (continueEV > bestBidEV) {
        bestBidEV = continueEV;
        bestBidOption = option;
      }
    }
    
    // 5. 决策
    if (challengeEV > bestBidEV && challengeProb > 0.45) {
      // 质疑更优
      return createDecision(
        type: 'challenge',
        confidence: challengeProb,
        strategy: 'balanced_optimal_challenge',
        reasoning: '期望值分析，质疑更优',
      );
    }
    
    if (bestBidOption != null && bestBidOption['success'] > 0.25) {
      // 继续叫牌
      String reasoning = bestBidOption['type'] == 'safe' ? '安全推进' :
                        bestBidOption['type'] == 'minimal' ? '最小风险' :
                        '适度进攻';
      
      return createDecision(
        type: 'bid',
        bid: bestBidOption['bid'],
        confidence: bestBidOption['success'],
        strategy: 'balanced_${bestBidOption['type']}',
        reasoning: reasoning,
      );
    }
    
    // 6. 如果都不理想，根据阈值决定
    if (challengeProb > 0.4) {
      return createDecision(
        type: 'challenge',
        confidence: challengeProb,
        strategy: 'balanced_threshold_challenge',
        reasoning: '风险过高，选择质疑',
      );
    }
    
    // 7. 被迫继续
    Bid forcedBid = Bid(
      quantity: round.currentBid!.quantity + 1,
      value: round.currentBid!.value,
    );
    
    return createDecision(
      type: 'bid',
      bid: forcedBid,
      confidence: 0.3,
      strategy: 'balanced_forced',
      reasoning: '被迫继续',
    );
  }
}
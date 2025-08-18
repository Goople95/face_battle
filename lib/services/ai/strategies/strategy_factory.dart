/// 策略工厂 - 创建合适的策略执行器
/// 
/// 根据策略类型创建对应的执行器实例

import '../../../models/game_state.dart';
import '../../../models/ai_personality.dart';
import '../models/ai_models.dart';
import 'strategy_executor.dart';
import 'aggressive_strategy.dart';
import 'conservative_strategy.dart';
import 'balanced_strategy.dart';

class StrategyFactory {
  final AIPersonality personality;
  
  // 缓存策略执行器实例
  final Map<StrategyType, StrategyExecutor> _executors = {};
  
  StrategyFactory(this.personality);
  
  /// 根据策略类型获取执行器
  StrategyExecutor getExecutor(StrategyType type) {
    // 如果已缓存，直接返回
    if (_executors.containsKey(type)) {
      return _executors[type]!;
    }
    
    // 创建新的执行器
    StrategyExecutor executor;
    
    switch (type) {
      case StrategyType.aggressive:
        executor = AggressiveStrategyExecutor(personality);
        break;
        
      case StrategyType.conservative:
        executor = ConservativeStrategyExecutor(personality);
        break;
        
      case StrategyType.trap:
        // 陷阱策略：先示弱后强攻
        executor = TrapStrategyExecutor(personality);
        break;
        
      case StrategyType.pressure:
        // 压力策略：持续施压
        executor = PressureStrategyExecutor(personality);
        break;
        
      case StrategyType.probe:
        // 试探策略：小幅试探对手反应
        executor = ProbeStrategyExecutor(personality);
        break;
        
      case StrategyType.balanced:
      default:
        executor = BalancedStrategyExecutor(personality);
        break;
    }
    
    // 缓存并返回
    _executors[type] = executor;
    return executor;
  }
  
  /// 清除缓存（新游戏开始时调用）
  void reset() {
    _executors.clear();
  }
}

/// 陷阱策略执行器 - 示弱诱敌
class TrapStrategyExecutor extends StrategyExecutor {
  TrapStrategyExecutor(AIPersonality personality) : super(personality);
  
  @override
  Map<String, dynamic> execute(
    round,
    Situation situation,
    OpponentState opponentState,
  ) {
    // 陷阱策略：有好牌时故意示弱
    
    if (round.currentBid == null) {
      // 示弱开局
      return createDecision(
        type: 'bid',
        bid: Bid(quantity: 2, value: situation.ourSecondBestValue),
        confidence: 0.5,
        strategy: 'trap_weak_opening',
        reasoning: '示弱开局',
      );
    }
    
    // 如果我们牌很好，继续示弱
    if (situation.ourStrength > 0.6) {
      // 最小增量，装作勉强跟注
      Bid weakBid = Bid(
        quantity: round.currentBid!.quantity + 1,
        value: round.currentBid!.value,
      );
      
      double success = probabilityCalculator.calculateBidSuccessProbability(
        bid: weakBid,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      if (success > 0.7) {
        return createDecision(
          type: 'bid',
          bid: weakBid,
          confidence: success,
          strategy: 'trap_lure',
          reasoning: '诱敌深入',
          extra: {'psychEffect': 'fake_weakness'},
        );
      }
    }
    
    // 如果对手上钩（激进叫牌），准备收网
    if (opponentState.isAggressive && situation.weHaveEnough) {
      double challengeProb = probabilityCalculator.calculateChallengeSuccessProbability(
        currentBid: round.currentBid!,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      if (challengeProb < 0.3) {
        // 我们有牌，让对手继续
        Bid continueBid = Bid(
          quantity: round.currentBid!.quantity + 1,
          value: round.currentBid!.value,
        );
        
        return createDecision(
          type: 'bid',
          bid: continueBid,
          confidence: 0.8,
          strategy: 'trap_spring',
          reasoning: '陷阱即将触发',
        );
      }
    }
    
    // 默认使用平衡策略
    return BalancedStrategyExecutor(personality).execute(round, situation, opponentState);
  }
}

/// 压力策略执行器 - 持续施压
class PressureStrategyExecutor extends StrategyExecutor {
  PressureStrategyExecutor(AIPersonality personality) : super(personality);
  
  @override
  Map<String, dynamic> execute(
    round,
    Situation situation,
    OpponentState opponentState,
  ) {
    // 压力策略：快速提高叫牌，给对手压力
    
    if (round.currentBid == null) {
      // 强势开局
      return createDecision(
        type: 'bid',
        bid: Bid(quantity: 4, value: random.nextInt(6) + 1),
        confidence: 0.6,
        strategy: 'pressure_strong_opening',
        reasoning: '强势开局施压',
      );
    }
    
    // 大幅提高
    int increase = 2;
    if (opponentState.isNervous) {
      increase = 3; // 对手紧张，加大压力
    }
    
    Bid pressureBid = Bid(
      quantity: round.currentBid!.quantity + increase,
      value: round.currentBid!.value,
    );
    
    if (pressureBid.quantity > 9) {
      // 已到极限，质疑
      double challengeProb = probabilityCalculator.calculateChallengeSuccessProbability(
        currentBid: round.currentBid!,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      return createDecision(
        type: 'challenge',
        confidence: challengeProb,
        strategy: 'pressure_limit_challenge',
        reasoning: '压力已到极限',
      );
    }
    
    double success = probabilityCalculator.calculateBidSuccessProbability(
      bid: pressureBid,
      ourDice: round.aiDice,
      onesAreCalled: round.onesAreCalled,
    );
    
    if (success > 0.1) {
      return createDecision(
        type: 'bid',
        bid: pressureBid,
        confidence: success,
        strategy: 'pressure_escalate',
        reasoning: '持续施压',
        extra: {'psychEffect': 'intimidation'},
      );
    }
    
    // 压力无效，转为质疑
    double challengeProb = probabilityCalculator.calculateChallengeSuccessProbability(
      currentBid: round.currentBid!,
      ourDice: round.aiDice,
      onesAreCalled: round.onesAreCalled,
    );
    
    return createDecision(
      type: 'challenge',
      confidence: challengeProb,
      strategy: 'pressure_tactical_challenge',
      reasoning: '压力转质疑',
    );
  }
}

/// 试探策略执行器 - 小幅试探
class ProbeStrategyExecutor extends StrategyExecutor {
  ProbeStrategyExecutor(AIPersonality personality) : super(personality);
  
  @override
  Map<String, dynamic> execute(
    round,
    Situation situation,
    OpponentState opponentState,
  ) {
    // 试探策略：小幅增加，观察对手反应
    
    if (round.currentBid == null) {
      // 试探性开局
      return createDecision(
        type: 'bid',
        bid: Bid(quantity: 2, value: random.nextInt(6) + 1),
        confidence: 0.5,
        strategy: 'probe_opening',
        reasoning: '试探性开局',
      );
    }
    
    // 小幅增加
    Bid probeBid = Bid(
      quantity: round.currentBid!.quantity + 1,
      value: round.currentBid!.value,
    );
    
    // 偶尔换个点数试探
    if (random.nextDouble() < 0.3 && round.bidHistory.length < 4) {
      int newValue = situation.ourBestValue;
      if (newValue != round.currentBid!.value) {
        probeBid = Bid(
          quantity: round.currentBid!.quantity,
          value: newValue,
        );
        probeBid = ensureLegalBid(probeBid, round);
      }
    }
    
    double success = probabilityCalculator.calculateBidSuccessProbability(
      bid: probeBid,
      ourDice: round.aiDice,
      onesAreCalled: round.onesAreCalled,
    );
    
    if (success > 0.3) {
      return createDecision(
        type: 'bid',
        bid: probeBid,
        confidence: success,
        strategy: 'probe_test',
        reasoning: '试探对手反应',
      );
    }
    
    // 试探完成，根据情况决定
    if (opponentState.isAggressive) {
      // 对手激进，我们质疑
      double challengeProb = probabilityCalculator.calculateChallengeSuccessProbability(
        currentBid: round.currentBid!,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      if (challengeProb > 0.5) {
        return createDecision(
          type: 'challenge',
          confidence: challengeProb,
          strategy: 'probe_counter_challenge',
          reasoning: '试探完成，对手激进，质疑',
        );
      }
    }
    
    // 继续小幅试探
    return createDecision(
      type: 'bid',
      bid: probeBid,
      confidence: success,
      strategy: 'probe_continue',
      reasoning: '继续试探',
    );
  }
}
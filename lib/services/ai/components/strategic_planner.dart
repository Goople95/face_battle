/// 策略规划器 - 制定游戏策略
/// 
/// 根据游戏阶段、对手状态和AI性格制定策略
library;

import 'dart:math' as math;
import '../../../models/ai_personality.dart';
import '../models/ai_models.dart';

class StrategicPlanner {
  final AIPersonality personality;
  final math.Random random = math.Random();
  
  StrategicPlanner(this.personality);
  
  /// 制定策略
  Strategy planStrategy(Situation situation, OpponentState opponent) {
    // 根据游戏阶段调整策略
    GamePhase phase = _identifyGamePhase(situation);
    
    // 阶段特定策略
    switch (phase) {
      case GamePhase.early:
        return _earlyGameStrategy(situation, opponent);
      case GamePhase.middle:
        return _middleGameStrategy(situation, opponent);
      case GamePhase.late:
        return _lateGameStrategy(situation, opponent);
    }
  }
  
  /// 识别游戏阶段
  GamePhase _identifyGamePhase(Situation situation) {
    if (situation.bidQuantity == 0) return GamePhase.early;
    if (situation.bidQuantity <= 4) return GamePhase.early;
    if (situation.bidQuantity <= 6) return GamePhase.middle;
    return GamePhase.late;
  }
  
  /// 早期游戏策略
  Strategy _earlyGameStrategy(Situation situation, OpponentState opponent) {
    // 早期：可以更多样化，引入更多随机性
    
    // 如果对手在倾斜状态，施压
    if (opponent.isTilting) {
      return Strategy(StrategyType.pressure, confidence: 0.8);
    }
    
    // 如果对手很保守，激进
    if (opponent.isConservative && situation.ourStrength > 0.5) {
      return Strategy(StrategyType.aggressive, confidence: 0.7);
    }
    
    // 如果我们很强，有机会设陷阱
    if (situation.ourStrength > 0.7 && !opponent.isAggressive) {
      return Strategy(StrategyType.trap, confidence: 0.75);
    }
    
    // 早期策略轮盘（增加多样性）
    double roll = random.nextDouble();
    
    // 根据AI性格调整概率
    if (personality.bluffRatio > 0.5) {
      // 高诈唬性格：更激进
      if (roll < 0.40) {
        return Strategy(StrategyType.aggressive, confidence: 0.65);
      }
      if (roll < 0.60) {
        return Strategy(StrategyType.probe, confidence: 0.6);
      }
      if (roll < 0.75) {
        return Strategy(StrategyType.trap, confidence: 0.6);
      }
    } else if (personality.bluffRatio < 0.3) {
      // 保守性格：更谨慎
      if (roll < 0.40) {
        return Strategy(StrategyType.conservative, confidence: 0.65);
      }
      if (roll < 0.60) {
        return Strategy(StrategyType.probe, confidence: 0.6);
      }
      if (roll < 0.80) {
        return Strategy(StrategyType.balanced, confidence: 0.65);
      }
    } else {
      // 平衡性格
      if (roll < 0.25) {
        return Strategy(StrategyType.probe, confidence: 0.6);
      }
      if (roll < 0.45) {
        return Strategy(StrategyType.aggressive, confidence: 0.65);
      }
      if (roll < 0.60) {
        return Strategy(StrategyType.trap, confidence: 0.6);
      }
      if (roll < 0.75) {
        return Strategy(StrategyType.conservative, confidence: 0.6);
      }
    }
    
    return Strategy(StrategyType.balanced, confidence: 0.65);
  }
  
  /// 中期游戏策略
  Strategy _middleGameStrategy(Situation situation, OpponentState opponent) {
    // 中期：更加谨慎但仍保持一定多样性
    
    // 如果对手虚张概率高，准备质疑
    if (opponent.bluffProbability > 0.6) {
      return Strategy(StrategyType.conservative, confidence: 0.7);
    }
    
    // 如果我们的牌弱，但对手也不强势
    if (situation.ourStrength < 0.4 && !opponent.isConfident) {
      // 尝试压力战术
      if (random.nextDouble() < 0.5) {
        return Strategy(StrategyType.pressure, confidence: 0.6);
      }
    }
    
    // 中期策略选择（减少激进，增加保守）
    double roll = random.nextDouble();
    
    // 根据性格调整
    if (personality.challengeThreshold < 0.3) {
      // 容易质疑的性格：更保守
      if (roll < 0.50) {
        return Strategy(StrategyType.conservative, confidence: 0.65);
      }
    }
    
    // 10% 激进（仅在条件好时）
    if (roll < 0.10 && situation.ourStrength > 0.6) {
      return Strategy(StrategyType.aggressive, confidence: 0.6);
    }
    
    // 25% 保守
    if (roll < 0.35) {
      return Strategy(StrategyType.conservative, confidence: 0.65);
    }
    
    // 15% 试探
    if (roll < 0.50) {
      return Strategy(StrategyType.probe, confidence: 0.65);
    }
    
    // 10% 陷阱（如果有机会）
    if (roll < 0.60 && situation.ourStrength > 0.5 && !opponent.isAggressive) {
      return Strategy(StrategyType.trap, confidence: 0.65);
    }
    
    // 40% 平衡（主流策略）
    return Strategy(StrategyType.balanced, confidence: 0.7);
  }
  
  /// 后期游戏策略
  Strategy _lateGameStrategy(Situation situation, OpponentState opponent) {
    // 后期：非常谨慎，主要看数学概率
    
    // 后期主要看数学概率
    if (situation.opponentSuccessProb < 0.3) {
      // 对手成功率低，倾向质疑
      return Strategy(StrategyType.conservative, confidence: 0.75);
    }
    
    // 如果我们的牌很弱，但必须继续
    if (situation.ourStrength < 0.3 && situation.weHaveEnough) {
      // 被迫继续，但要保守
      return Strategy(StrategyType.conservative, confidence: 0.6);
    }
    
    // 如果叫牌已经很高，基本上要质疑
    if (situation.bidQuantity >= 8) {
      return Strategy(StrategyType.conservative, confidence: 0.8);
    }
    
    // 后期默认保守
    return Strategy(StrategyType.conservative, confidence: 0.7);
  }
}
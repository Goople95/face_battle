/// AI决策系统的核心数据模型
/// 
/// 这个文件包含所有AI决策系统使用的数据模型和枚举类型

import '../../../models/game_state.dart';

/// 游戏局势分析结果
class Situation {
  int ourBestValue = 3;
  int ourBestCount = 0;
  int ourSecondBestValue = 3;
  int ourCount = 0;
  int opponentNeeds = 0;
  int bidQuantity = 0;  // 当前叫牌数量
  
  bool weHaveEnough = false;
  bool impossibleForOpponent = false;
  
  double ourStrength = 0;
  double opponentSuccessProb = 0;
  double risk = 0;
  
  double calculateBidSuccess(Bid bid) {
    // 简化计算
    return ourCount / bid.quantity.toDouble();
  }
}

/// 对手状态分析结果
class OpponentState {
  bool isAggressive = false;
  bool isConservative = false;
  bool isBluffing = false;
  bool isConfident = false;
  bool isNervous = false;
  bool isWeak = false;
  bool isTilting = false;
  
  double bluffProbability = 0.3;
  double challengeProbability = 0.2;
  
  int winStreak = 0;
}

/// 玩家行动记录
class PlayerAction {
  final Bid bid;
  final int round;
  bool wasBluff;
  
  PlayerAction({
    required this.bid,
    required this.round,
    required this.wasBluff,
  });
}

/// 游戏阶段
enum GamePhase {
  early,   // 早期（≤4个）
  middle,  // 中期（5-6个）
  late,    // 后期（≥7个）
}

/// 策略类型
enum StrategyType {
  aggressive,   // 激进
  conservative, // 保守
  trap,        // 陷阱
  pressure,    // 施压
  probe,       // 试探
  balanced,    // 平衡
}

/// 策略决策结果
class Strategy {
  final StrategyType type;
  final double confidence;
  
  Strategy(this.type, {this.confidence = 0.5});
}

/// 回合结果记录
class RoundResult {
  final GameRound round;
  final Map<String, dynamic> decision;
  final Strategy strategy;
  bool success;  // 移除final，允许后续更新
  
  RoundResult({
    required this.round,
    required this.decision,
    required this.strategy,
    required this.success,
  });
}
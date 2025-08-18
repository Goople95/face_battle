/// 大师级AI引擎 - 真正理解大话骰的AI
/// 
/// 大话骰的本质：
/// 1. 信息不对称的博弈 - 你不知道对手的骰子
/// 2. 心理博弈 - 让对手相信你的叫牌
/// 3. 风险管理 - 知道何时该冒险，何时该保守
/// 4. 模式识别 - 发现对手的习惯和弱点

import 'dart:math' as math;
import '../models/game_state.dart';
import '../models/ai_personality.dart';
import '../utils/logger_utils.dart';
import 'probability_calculator.dart';

/// 大师级AI决策引擎
class MasterAIEngine {
  final AIPersonality personality;
  final random = math.Random();
  final probabilityCalculator = ProbabilityCalculator();
  
  // 核心智能组件
  late final GameUnderstanding gameKnowledge;      // 游戏理解
  late final OpponentMind opponentMind;           // 对手心理模型
  late final StrategicPlanner strategist;         // 策略规划
  late final RiskManager riskManager;             // 风险管理
  late final BluffingExpert bluffer;              // 诈唬专家
  
  // 游戏记忆
  final GameMemory memory = GameMemory();
  
  MasterAIEngine({required this.personality}) {
    gameKnowledge = GameUnderstanding();
    opponentMind = OpponentMind();
    strategist = StrategicPlanner(personality);
    riskManager = RiskManager(personality);
    bluffer = BluffingExpert(personality);
  }
  
  /// 主决策方法 - 像人类高手一样思考
  Map<String, dynamic> makeDecision(GameRound round) {
    // 1. 理解当前局势
    var situation = gameKnowledge.analyzeSituation(round, memory);
    
    // 2. 读懂对手
    var opponentState = opponentMind.readOpponent(round, memory);
    
    // 3. 制定策略
    var strategy = strategist.planStrategy(situation, opponentState);
    
    // 4. 执行决策
    var decision = _executeStrategy(strategy, round, situation, opponentState);
    
    // 5. 生成所有可能的选项（用于复盘显示）
    var allOptions = _generateAllOptions(round, situation);
    decision['allOptions'] = allOptions;
    
    // 6. 记录和学习
    memory.recordRound(round, decision, strategy);
    opponentMind.learn(round, decision);
    
    return decision;
  }
  
  /// 执行策略 - 将策略转化为具体行动
  Map<String, dynamic> _executeStrategy(
    Strategy strategy,
    GameRound round,
    Situation situation,
    OpponentState opponentState,
  ) {
    // 绝对规则检查
    var mandatoryAction = _checkAbsoluteRules(round, situation);
    if (mandatoryAction != null) {
      return mandatoryAction;
    }
    
    // 根据策略执行
    switch (strategy.type) {
      case StrategyType.aggressive:
        return _executeAggressiveStrategy(round, situation, opponentState);
        
      case StrategyType.conservative:
        return _executeConservativeStrategy(round, situation, opponentState);
        
      case StrategyType.trap:
        return _executeTrapStrategy(round, situation, opponentState);
        
      case StrategyType.pressure:
        return _executePressureStrategy(round, situation, opponentState);
        
      case StrategyType.probe:
        return _executeProbeStrategy(round, situation, opponentState);
        
      default:
        return _executeBalancedStrategy(round, situation, opponentState);
    }
  }
  
  /// 绝对规则 - 不可违反的铁律
  Map<String, dynamic>? _checkAbsoluteRules(GameRound round, Situation situation) {
    if (round.currentBid == null) return null;
    
    // 铁律1：如果我们已经有足够的骰子，绝不质疑
    if (situation.weHaveEnough) {
      AILogger.logParsing('铁律触发', {
        'rule': '不质疑已足够的叫牌',
        'ourCount': situation.ourCount,
        'needed': round.currentBid!.quantity,
      });
      
      // 必须继续叫牌
      return _forcedBid(round, situation);
    }
    
    // 铁律2：如果对手需要不可能的数量，必须质疑
    if (situation.impossibleForOpponent) {
      AILogger.logParsing('铁律触发', {
        'rule': '质疑不可能的叫牌',
        'opponentNeeds': situation.opponentNeeds,
      });
      
      return {
        'type': 'challenge',
        'confidence': 1.0,
        'strategy': 'absolute_rule',
        'reasoning': '对手需要${situation.opponentNeeds}个，不可能',
      };
    }
    
    return null;
  }
  
  /// 激进策略 - 施加压力，快速升级（改进版）
  Map<String, dynamic> _executeAggressiveStrategy(
    GameRound round,
    Situation situation,
    OpponentState opponentState,
  ) {
    // 获取当前数量
    int currentQty = round.currentBid?.quantity ?? 0;
    
    // 后期不适合激进（数量≥6）
    if (currentQty >= 6) {
      AILogger.logParsing('激进策略限制', {
        'reason': '后期转保守',
        'currentQuantity': currentQty,
      });
      return _executeConservativeStrategy(round, situation, opponentState);
    }
    
    // 激进不等于鲁莽
    if (situation.risk > 0.7 && !opponentState.isWeak) {
      // 风险太高，转为半诈唬
      Bid semiBluffBid = _semiBluff(round, situation);
      
      // 限制增幅
      if (semiBluffBid.quantity > currentQty + 2) {
        semiBluffBid = Bid(quantity: currentQty + 2, value: semiBluffBid.value);
      }
      
      double actualConfidence = _calculateBidConfidence(semiBluffBid, round, situation);
      return {
        'type': 'bid',
        'bid': semiBluffBid,
        'confidence': actualConfidence,
        'strategy': 'semi_bluff',
        'reasoning': '半诈唬',
      };
    }
    
    // 大幅提高叫牌（但要合理）
    var aggressiveBid = _calculateAggressiveBid(round, situation);
    
    // 限制激进程度
    if (currentQty < 3) {
      // 早期可以跳2个
      if (aggressiveBid.quantity > currentQty + 2) {
        aggressiveBid = Bid(quantity: currentQty + 2, value: aggressiveBid.value);
      }
    } else {
      // 中后期最多加1个
      if (aggressiveBid.quantity > currentQty + 1) {
        aggressiveBid = Bid(quantity: currentQty + 1, value: aggressiveBid.value);
      }
    }
    
    // 总量检查
    if (aggressiveBid.quantity >= 7) {
      // 检查是否合理
      if (situation.opponentNeeds >= 3) {
        AILogger.logParsing('激进策略总量检查', {
          'bidQuantity': aggressiveBid.quantity,
          'opponentNeeds': situation.opponentNeeds,
          'decision': '质疑',
        });
        
        // 计算实际质疑成功率
        double challengeConfidence = probabilityCalculator.calculateChallengeSuccessProbability(
          currentBid: round.currentBid!,
          ourDice: round.aiDice,
          onesAreCalled: round.onesAreCalled,
        );
        return {
          'type': 'challenge',
          'confidence': challengeConfidence,
          'strategy': 'aggressive_total_check',
          'reasoning': '总量过高',
        };
      }
    }
    
    double actualConfidence = _calculateBidConfidence(aggressiveBid, round, situation);
    return {
      'type': 'bid',
      'bid': aggressiveBid,
      'confidence': actualConfidence,
      'strategy': 'aggressive',
      'reasoning': '施压',
      'psychEffect': 'intimidation',
    };
  }
  
  /// 保守策略 - 稳扎稳打
  Map<String, dynamic> _executeConservativeStrategy(
    GameRound round,
    Situation situation,
    OpponentState opponentState,
  ) {
    // 如果对手很可能在虚张，质疑
    if (opponentState.bluffProbability > 0.65) {
      // 计算实际质疑成功率
      double challengeConfidence = round.currentBid != null ?
        probabilityCalculator.calculateChallengeSuccessProbability(
          currentBid: round.currentBid!,
          ourDice: round.aiDice,
          onesAreCalled: round.onesAreCalled,
        ) : 0.5;
      return {
        'type': 'challenge',
        'confidence': challengeConfidence,
        'strategy': 'conservative_challenge',
        'reasoning': '对手可能虚张',
      };
    }
    
    // 检查当前叫牌是否已经过高
    if (round.currentBid != null) {
      int currentQty = round.currentBid!.quantity;
      
      // 如果已经叫到7个或更多，优先考虑质疑
      if (currentQty >= 7) {
        // 计算对手需要多少个
        int ourCount = round.aiDice.countValue(
          round.currentBid!.value, 
          onesAreCalled: round.onesAreCalled
        );
        int opponentNeeds = currentQty - ourCount;
        
        if (opponentNeeds >= 3) {
          // 对手需要3个或更多，应该质疑
          // 计算实际质疑成功率
          double challengeConfidence = probabilityCalculator.calculateChallengeSuccessProbability(
            currentBid: round.currentBid!,
            ourDice: round.aiDice,
            onesAreCalled: round.onesAreCalled,
          );
          return {
            'type': 'challenge',
            'confidence': challengeConfidence,
            'strategy': 'conservative_high_challenge',
            'reasoning': '总量过高，不可信',
          };
        }
      }
      
      // 如果是8个或更多，几乎必须质疑
      if (currentQty >= 8) {
        // 计算实际质疑成功率
        double challengeConfidence = probabilityCalculator.calculateChallengeSuccessProbability(
          currentBid: round.currentBid!,
          ourDice: round.aiDice,
          onesAreCalled: round.onesAreCalled,
        );
        return {
          'type': 'challenge',
          'confidence': challengeConfidence,
          'strategy': 'conservative_extreme_challenge',
          'reasoning': '极限数量，必须质疑',
        };
      }
    }
    
    // 尝试安全叫牌
    var safeBid = _calculateSafeBid(round, situation);
    
    // 计算这个叫牌的实际置信度
    double confidence = _calculateBidConfidence(safeBid, round, situation);
    
    // 重要检查：如果"安全"叫牌的成功率太低，应该质疑而不是继续
    if (confidence < 0.2) {
      // 成功率低于20%，不应该继续叫牌
      // 计算质疑成功率
      double challengeConfidence = probabilityCalculator.calculateChallengeSuccessProbability(
        currentBid: round.currentBid!,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      // 如果质疑成功率更高，选择质疑
      if (challengeConfidence > confidence) {
        return {
          'type': 'challenge',
          'confidence': challengeConfidence,
          'strategy': 'conservative_forced_challenge',
          'reasoning': '叫牌成功率太低，选择质疑',
        };
      }
    }
    
    // 二次检查：即使是"安全"叫牌，也要确保不会叫得太离谱
    if (safeBid.quantity >= 8) {
      // 如果"安全"叫牌都要叫到8个或更多，应该质疑而不是继续
      double challengeConfidence = probabilityCalculator.calculateChallengeSuccessProbability(
        currentBid: round.currentBid!,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      return {
        'type': 'challenge',
        'confidence': challengeConfidence,
        'strategy': 'conservative_extreme_challenge',
        'reasoning': '数量过高，无法继续',
      };
    }
    
    return {
      'type': 'bid',
      'bid': safeBid,
      'confidence': confidence,
      'strategy': 'conservative',
      'reasoning': confidence > 0.6 ? '稳健' : confidence > 0.3 ? '尝试' : '冒险',
    };
  }
  
  /// 陷阱策略 - 引诱对手犯错
  Map<String, dynamic> _executeTrapStrategy(
    GameRound round,
    Situation situation,
    OpponentState opponentState,
  ) {
    // 故意示弱
    if (situation.ourStrength > 0.7) {
      var weakBid = _calculateWeakBid(round, situation);
      
      return {
        'type': 'bid',
        'bid': weakBid,
        'confidence': 0.6,
        'strategy': 'trap',
        'reasoning': '诱敌',
        'psychEffect': 'fake_weakness',
        'hiddenStrength': situation.ourStrength,
      };
    }
    
    // 如果陷阱条件不满足，转为正常策略
    return _executeBalancedStrategy(round, situation, opponentState);
  }
  
  /// 压力策略 - 心理压迫（改进版）
  Map<String, dynamic> _executePressureStrategy(
    GameRound round,
    Situation situation,
    OpponentState opponentState,
  ) {
    if (round.currentBid == null) {
      // 开局适度激进
      Bid openingBid = Bid(quantity: math.min(3, situation.ourBestCount + 1), value: situation.ourBestValue);
      double actualConfidence = _calculateBidConfidence(openingBid, round, situation);
      return {
        'type': 'bid',
        'bid': openingBid,
        'confidence': actualConfidence,
        'strategy': 'pressure',
        'reasoning': '开局施压',
        'psychEffect': 'sudden_escalation',
      };
    }
    
    int currentQty = round.currentBid!.quantity;
    int currentVal = round.currentBid!.value;
    
    // 重要：根据当前数量调整激进程度
    int increment;
    if (currentQty < 3) {
      increment = 2;  // 早期可以较激进
    } else if (currentQty < 5) {
      increment = 1;  // 中期适度
    } else if (currentQty < 7) {
      increment = 1;  // 后期谨慎
      // 检查是否值得继续
      if (situation.opponentSuccessProb < 0.3) {
        // 对手成功率已经很低，考虑质疑
        // 计算实际质疑成功率
        double challengeConfidence = probabilityCalculator.calculateChallengeSuccessProbability(
          currentBid: round.currentBid!,
          ourDice: round.aiDice,
          onesAreCalled: round.onesAreCalled,
        );
        return {
          'type': 'challenge',
          'confidence': challengeConfidence,
          'strategy': 'pressure_to_challenge',
          'reasoning': '压力已足，转为质疑',
        };
      }
    } else {
      // 数量≥ 7，非常谨慎
      if (situation.opponentNeeds >= 3) {
        // 对手需要≥3个，应该质疑
        // 计算实际质疑成功率
        double challengeConfidence = probabilityCalculator.calculateChallengeSuccessProbability(
          currentBid: round.currentBid!,
          ourDice: round.aiDice,
          onesAreCalled: round.onesAreCalled,
        );
        return {
          'type': 'challenge',
          'confidence': challengeConfidence,
          'strategy': 'high_quantity_challenge',
          'reasoning': '数量太高，质疑',
        };
      }
      increment = 1;  // 最多加1
    }
    
    // 构建压力叫牌
    Bid pressureBid;
    if (situation.ourBestValue != currentVal && situation.ourBestCount >= 2) {
      // 换成我们最强的点数
      pressureBid = Bid(
        quantity: currentQty + 1,
        value: situation.ourBestValue,
      );
    } else {
      // 增加数量
      pressureBid = Bid(
        quantity: math.min(9, currentQty + increment),  // 最多到9
        value: currentVal,
      );
    }
    
    // 总量检查：如果超过8个，重新考虑
    if (pressureBid.quantity > 8) {
      // 计算成功率
      double successProb = situation.calculateBidSuccess(pressureBid);
      if (successProb < 0.2) {
        // 成功率太低，改为质疑
        // 计算实际质疑成功率  
        // 注意：这里是压力叫牌不可能成立的情况
        double challengeConfidence = 0.8;  // 策略决定的固定值
        return {
          'type': 'challenge',
          'confidence': challengeConfidence,
          'strategy': 'impossible_bid',
          'reasoning': '叫牌不可能成立',
        };
      }
    }
    
    // 确保合法性
    if (!pressureBid.isHigherThan(round.currentBid!, onesAreCalled: round.onesAreCalled)) {
      if (currentVal < 6) {
        pressureBid = Bid(quantity: currentQty, value: currentVal + 1);
      } else {
        pressureBid = Bid(quantity: currentQty + 1, value: 1);
      }
    }
    
    // 计算实际的成功概率
    double actualConfidence = _calculateBidConfidence(pressureBid, round, situation);
    
    return {
      'type': 'bid',
      'bid': pressureBid,
      'confidence': actualConfidence,
      'strategy': 'pressure',
      'reasoning': '压力叫牌',
      'psychEffect': 'controlled_pressure',  // 受控压力
    };
  }
  
  /// 试探策略 - 测试对手反应（改进版）
  Map<String, dynamic> _executeProbeStrategy(
    GameRound round,
    Situation situation,
    OpponentState opponentState,
  ) {
    // 获取当前数量
    int currentQty = round.currentBid?.quantity ?? 0;
    
    // 后期不适合试探
    if (currentQty >= 6) {
      // 转为保守策略
      return _executeConservativeStrategy(round, situation, opponentState);
    }
    
    // 小幅提高，观察反应
    var probeBid = _calculateProbeBid(round, situation);
    
    // 确保试探不要太激进
    if (probeBid != null && probeBid.quantity > currentQty + 1) {
      probeBid = Bid(quantity: currentQty + 1, value: probeBid.value);
    }
    
    // 总量检查
    if (probeBid != null && probeBid.quantity >= 7) {
      if (situation.opponentNeeds >= 3) {
        // 计算实际质疑成功率
        double challengeConfidence = probabilityCalculator.calculateChallengeSuccessProbability(
          currentBid: round.currentBid!,
          ourDice: round.aiDice,
          onesAreCalled: round.onesAreCalled,
        );
        return {
          'type': 'challenge',
          'confidence': challengeConfidence,
          'strategy': 'probe_total_check',
          'reasoning': '试探发现总量过高',
        };
      }
    }
    
    double actualConfidence = _calculateBidConfidence(probeBid, round, situation);
    return {
      'type': 'bid',
      'bid': probeBid,
      'confidence': actualConfidence,
      'strategy': 'probe',
      'reasoning': '试探',
      'expectingReaction': true,
    };
  }
  
  /// 平衡策略 - 标准打法（增强版）
  Map<String, dynamic> _executeBalancedStrategy(
    GameRound round,
    Situation situation,
    OpponentState opponentState,
  ) {
    // 总量检查
    if (round.currentBid != null) {
      int currentQty = round.currentBid!.quantity;
      
      // 如果叫牌数量超过7，需要特别谨慎
      if (currentQty >= 7) {
        // 如果对手需要≥4个，几乎不可能
        if (situation.opponentNeeds >= 4) {
          // 计算实际质疑成功率
          double challengeConfidence = probabilityCalculator.calculateChallengeSuccessProbability(
            currentBid: round.currentBid!,
            ourDice: round.aiDice,
            onesAreCalled: round.onesAreCalled,
          );
          return {
            'type': 'challenge',
            'confidence': challengeConfidence,
            'strategy': 'high_total_challenge',
            'reasoning': '总量过高，不可能',
          };
        }
        // 如果对手需要≥3个，很可能是虚张
        if (situation.opponentNeeds >= 3 && situation.opponentSuccessProb < 0.25) {
          // 计算实际质疑成功率
          double challengeConfidence = probabilityCalculator.calculateChallengeSuccessProbability(
            currentBid: round.currentBid!,
            ourDice: round.aiDice,
            onesAreCalled: round.onesAreCalled,
          );
          return {
            'type': 'challenge',
            'confidence': challengeConfidence,
            'strategy': 'probable_bluff',
            'reasoning': '高位虚张可能',
          };
        }
      }
      
      // 如果叫牌数量超过8，几乎总是质疑
      if (currentQty > 8) {
        // 计算实际质疑成功率
        double challengeConfidence = probabilityCalculator.calculateChallengeSuccessProbability(
          currentBid: round.currentBid!,
          ourDice: round.aiDice,
          onesAreCalled: round.onesAreCalled,
        );
        return {
          'type': 'challenge',
          'confidence': challengeConfidence,
          'strategy': 'extreme_quantity',
          'reasoning': '数量极端',
        };
      }
    }
    
    // 计算期望值
    double challengeEV = _calculateChallengeEV(round, situation, opponentState);
    
    // 找最佳叫牌
    var bestBid = _findBestBid(round, situation);
    
    // 总量限制：如果最佳叫牌超过8，重新考虑
    if (bestBid.quantity > 8) {
      // 尝试换点数来降低数量
      if (round.currentBid != null) {
        for (int value = 1; value <= 6; value++) {
          if (value != round.currentBid!.value) {
            int ourCount = situation.ourBestValue == value ? situation.ourBestCount : 0;
            if (ourCount >= 2) {
              bestBid = Bid(quantity: round.currentBid!.quantity + 1, value: value);
              if (bestBid.isHigherThan(round.currentBid!, onesAreCalled: round.onesAreCalled)) {
                break;
              }
            }
          }
        }
      }
      
      // 如果还是超过8，考虑质疑
      if (bestBid.quantity > 8) {
        challengeEV += 10; // 增加质疑倾向
      }
    }
    
    double bidEV = _calculateBidEV(bestBid, situation, opponentState);
    
    // 选择期望值更高的
    if (challengeEV > bidEV && challengeEV > 0) {
      return {
        'type': 'challenge',
        'confidence': _evToConfidence(challengeEV),
        'strategy': 'balanced',
        'reasoning': '期望值分析',
        'ev': challengeEV,
      };
    } else {
      return {
        'type': 'bid',
        'bid': bestBid,
        'confidence': _evToConfidence(bidEV),
        'strategy': 'balanced',
        'reasoning': '最优叫牌',
        'ev': bidEV,
      };
    }
  }
  
  // === 辅助计算方法 ===
  
  Map<String, dynamic> _forcedBid(GameRound round, Situation situation) {
    // 被迫叫牌时，选择最安全的
    Bid safeBid = _calculateSafeBid(round, situation);
    
    double actualConfidence = _calculateBidConfidence(safeBid, round, situation);
    
    // 即使是被迫叫牌，如果成功率太低也不应该继续
    if (actualConfidence < 0.1 && round.currentBid != null) {
      // 成功率低于10%，选择质疑
      double challengeConfidence = probabilityCalculator.calculateChallengeSuccessProbability(
        currentBid: round.currentBid!,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      return {
        'type': 'challenge',
        'confidence': challengeConfidence,
        'strategy': 'forced_challenge',
        'reasoning': '无法继续叫牌',
      };
    }
    
    return {
      'type': 'bid',
      'bid': safeBid,
      'confidence': actualConfidence,
      'strategy': 'forced',
      'reasoning': actualConfidence > 0.5 ? '必须叫牌' : '被迫尝试',
    };
  }
  
  Bid _calculateAggressiveBid(GameRound round, Situation situation) {
    int currentQty = round.currentBid?.quantity ?? 1;
    int aggressiveQty = math.min(10, currentQty + 2);
    
    // 选择我们最强的点数
    int value = situation.ourBestValue;
    
    Bid bid = Bid(quantity: aggressiveQty, value: value);
    
    // 确保合法性
    if (round.currentBid != null && 
        !bid.isHigherThan(round.currentBid!, onesAreCalled: round.onesAreCalled)) {
      bid = Bid(quantity: aggressiveQty + 1, value: value);
    }
    
    return bid;
  }
  
  Bid _calculateSafeBid(GameRound round, Situation situation) {
    if (round.currentBid == null) {
      // 开局保守叫牌
      return Bid(quantity: 2, value: situation.ourBestValue);
    }
    
    // 检查当前叫牌是否已经过高
    int currentQty = round.currentBid!.quantity;
    int currentVal = round.currentBid!.value;
    
    // 计算我们有多少个
    int ourCount = round.aiDice.countValue(currentVal, onesAreCalled: round.onesAreCalled);
    
    // 如果继续加1，对手需要多少个？
    int nextQty = currentQty + 1;
    int opponentNeeds = nextQty - ourCount;
    
    // 如果对手需要超过4个，这不安全！应该质疑或换点数
    if (opponentNeeds >= 4) {
      // 尝试换到我们更强的点数
      int bestValue = situation.ourBestValue;
      if (bestValue != currentVal) {
        // 换点数，但保守地叫
        int ourBestCount = round.aiDice.countValue(bestValue, onesAreCalled: round.onesAreCalled);
        int safeQty = math.min(currentQty, ourBestCount + 2); // 最多比实际多2个
        
        Bid newBid = Bid(quantity: safeQty, value: bestValue);
        
        // 确保合法
        if (!newBid.isHigherThan(round.currentBid!, onesAreCalled: round.onesAreCalled)) {
          // 如果换点数不合法，只能小幅增加
          if (currentVal < 6) {
            return Bid(quantity: currentQty, value: currentVal + 1);
          } else {
            // 被迫加量，但标记为高风险
            return Bid(quantity: currentQty + 1, value: 1);
          }
        }
        
        return newBid;
      }
      
      // 如果无法换点数，尝试最小合法叫牌
      if (currentVal < 6) {
        return Bid(quantity: currentQty, value: currentVal + 1);
      } else {
        // 最后选择：加1但换到1
        return Bid(quantity: currentQty + 1, value: 1);
      }
    }
    
    // 如果对手需要3个或更少，可以继续（但仍然保守）
    if (opponentNeeds <= 2) {
      // 相对安全，可以加1
      return Bid(quantity: currentQty + 1, value: currentVal);
    } else {
      // 需要3个，尝试换点数
      if (currentVal < 6) {
        return Bid(quantity: currentQty, value: currentVal + 1);
      } else {
        return Bid(quantity: currentQty + 1, value: currentVal);
      }
    }
  }
  
  Bid _calculateWeakBid(GameRound round, Situation situation) {
    // 故意叫得保守，但不能太明显
    int qty = (round.currentBid?.quantity ?? 1) + 1;
    int value = situation.ourBestValue;
    
    return Bid(quantity: qty, value: value);
  }
  
  Bid _calculateProbeBid(GameRound round, Situation situation) {
    // 小幅试探
    if (round.currentBid == null) {
      return Bid(quantity: 2, value: 3); // 中性开局
    }
    
    // 换个点数试探
    int newValue = (round.currentBid!.value % 6) + 1;
    if (newValue == 1) newValue = 2; // 避免直接叫1
    
    return Bid(
      quantity: round.currentBid!.quantity + 1,
      value: newValue,
    );
  }
  
  Bid _semiBluff(GameRound round, Situation situation) {
    // 半诈唬 - 有一定基础的虚张
    int qty = (round.currentBid?.quantity ?? 2) + 1;
    int value = situation.ourSecondBestValue;
    
    return Bid(quantity: qty, value: value);
  }
  
  Bid _findBestBid(GameRound round, Situation situation) {
    // 基于当前情况找最佳叫牌
    if (round.currentBid == null) {
      return Bid(quantity: 2, value: situation.ourBestValue);
    }
    
    // 根据我们的牌力选择
    if (situation.ourStrength > 0.6) {
      return _calculateAggressiveBid(round, situation);
    } else {
      return _calculateSafeBid(round, situation);
    }
  }
  
  /// 生成所有可能的选项（用于复盘界面显示）
  List<Map<String, dynamic>> _generateAllOptions(GameRound round, Situation situation) {
    List<Map<String, dynamic>> options = [];
    
    if (round.currentBid == null) {
      // 首轮叫牌选项
      for (int value = 2; value <= 6; value++) {
        for (int qty = 2; qty <= 4; qty++) {
          Bid bid = Bid(quantity: qty, value: value);
          int ourCount = round.aiDice.countValue(value, onesAreCalled: false);
          int opponentNeeds = qty - ourCount;
          
          // 计算真实概率
          double confidence = _calculateBidConfidenceSimple(round, bid);
          
          options.add({
            'type': 'bid',
            'bid': bid,
            'confidence': confidence,
            'strategy': ourCount >= qty ? '稳健' : 
                       ourCount >= qty - 1 ? '合理' : '冒险',
            'reasoning': '开局叫牌',
          });
        }
      }
    } else {
      // 质疑选项
      // 计算质疑成功率
      double challengeSuccess = probabilityCalculator.calculateChallengeSuccessProbability(
        currentBid: round.currentBid!,
        ourDice: round.aiDice,
        onesAreCalled: round.onesAreCalled,
      );
      
      options.add({
        'type': 'challenge',
        'confidence': challengeSuccess,
        'strategy': challengeSuccess > 0.7 ? '高概率' : 
                   challengeSuccess > 0.5 ? '合理' : '冒险',
        'reasoning': '质疑对手',
      });
      
      // 叫牌选项
      // 同点数加量
      if (round.currentBid!.quantity < 8) {
        for (int addQty = 1; addQty <= 2; addQty++) {
          Bid bid = Bid(
            quantity: round.currentBid!.quantity + addQty,
            value: round.currentBid!.value,
          );
          double confidence = _calculateBidConfidenceSimple(round, bid);
          
          options.add({
            'type': 'bid',
            'bid': bid,
            'confidence': confidence,
            'strategy': confidence > 0.6 ? '稳健' : 
                       confidence > 0.3 ? '冒险' : '诈唬',
            'reasoning': '提高数量',
          });
        }
      }
      
      // 切换点数
      for (int newValue = 1; newValue <= 6; newValue++) {
        if (newValue == round.currentBid!.value) continue;
        
        // 计算需要的最小数量
        int minQty = round.currentBid!.quantity;
        if (newValue < round.currentBid!.value && !round.onesAreCalled) {
          minQty = round.currentBid!.quantity + 1;
        }
        
        if (minQty <= 7) {
          Bid bid = Bid(quantity: minQty, value: newValue);
          double confidence = _calculateBidConfidenceSimple(round, bid);
          
          options.add({
            'type': 'bid',
            'bid': bid,
            'confidence': confidence,
            'strategy': confidence > 0.5 ? '切换' : '转移',
            'reasoning': '改变点数',
          });
        }
      }
    }
    
    // 按置信度排序
    options.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
    
    // 只返回前5个选项
    return options.take(5).toList();
  }
  
  /// 简化的置信度计算（用于选项生成）
  double _calculateBidConfidenceSimple(GameRound round, Bid bid) {
    return probabilityCalculator.calculateBidSuccessProbability(
      bid: bid,
      ourDice: round.aiDice,
      onesAreCalled: round.onesAreCalled,
    );
  }
  
  double _calculateBidConfidence(Bid bid, GameRound round, Situation situation) {
    return probabilityCalculator.calculateBidSuccessProbability(
      bid: bid,
      ourDice: round.aiDice,
      onesAreCalled: round.onesAreCalled,
    );
  }
  
  double _calculateChallengeEV(
    GameRound round,
    Situation situation,
    OpponentState opponentState,
  ) {
    if (round.currentBid == null) return -100;
    
    // 基础成功率
    double successProb = 1.0 - situation.opponentSuccessProb;
    
    // 根据对手状态调整
    if (opponentState.isBluffing) {
      successProb += 0.2;
    }
    if (opponentState.isConfident) {
      successProb -= 0.15;
    }
    
    // 期望值计算
    double winValue = 15.0 + (round.bidHistory.length * 2);
    double loseValue = -10.0;
    
    return successProb * winValue + (1 - successProb) * loseValue;
  }
  
  double _calculateBidEV(
    Bid bid,
    Situation situation,
    OpponentState opponentState,
  ) {
    // 我们成功的概率
    double ourSuccess = situation.calculateBidSuccess(bid);
    
    // 对手质疑的概率
    double challengeProb = opponentState.challengeProbability;
    
    // 继续游戏的价值
    double continueValue = 5.0;
    double winChallengeValue = 20.0;
    double loseChallengeValue = -15.0;
    
    return (1 - challengeProb) * continueValue +
           challengeProb * ourSuccess * winChallengeValue +
           challengeProb * (1 - ourSuccess) * loseChallengeValue;
  }
  
  double _evToConfidence(double ev) {
    // 将期望值映射到置信度
    if (ev > 20) return 0.95;
    if (ev > 10) return 0.8;
    if (ev > 5) return 0.65;
    if (ev > 0) return 0.5;
    return 0.3;
  }
  
}

/// 游戏理解 - 理解当前局势
class GameUnderstanding {
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
      situation.bidQuantity = round.currentBid!.quantity;  // 记录当前数量
      situation.ourCount = ourCounts[round.currentBid!.value] ?? 0;
      situation.opponentNeeds = round.currentBid!.quantity - situation.ourCount;
      
      situation.weHaveEnough = situation.opponentNeeds <= 0;
      situation.impossibleForOpponent = situation.opponentNeeds > 5;
      
      // 计算对手成功概率
      situation.opponentSuccessProb = _calculateOpponentProb(
        situation.opponentNeeds,
        round.onesAreCalled,
        round.currentBid!.value,
      );
    }
    
    // 计算我们的整体实力
    int totalDice = ourCounts.values.fold(0, (a, b) => a + b);
    situation.ourStrength = situation.ourBestCount / 5.0; // 最强点数的比例
    
    // 计算风险等级
    situation.risk = _calculateRisk(round, situation);
    
    return situation;
  }
  
  double _calculateOpponentProb(int needed, bool onesAreCalled, int value) {
    if (needed <= 0) return 1.0;
    if (needed > 5) return 0.0;
    
    // 基础概率
    double baseProb = 1/6.0;
    
    // 如果1是万能牌，概率更高
    if (!onesAreCalled && value != 1) {
      baseProb = 2/6.0; // 目标值或1都可以
    }
    
    // 二项分布计算
    double prob = 0;
    for (int k = needed; k <= 5; k++) {
      prob += _binomial(5, k, baseProb);
    }
    
    return prob;
  }
  
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
  
  double _binomial(int n, int k, double p) {
    if (k > n) return 0;
    
    double coeff = 1;
    for (int i = 0; i < k; i++) {
      coeff *= (n - i) / (i + 1);
    }
    
    return coeff * math.pow(p, k) * math.pow(1 - p, n - k);
  }
}

/// 局势分析结果
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

/// 对手心理模型
class OpponentMind {
  final List<PlayerAction> recentActions = [];
  final Map<String, int> patterns = {};
  
  OpponentState readOpponent(GameRound round, GameMemory memory) {
    var state = OpponentState();
    
    // 分析最近的叫牌
    if (round.currentBid != null && round.bidHistory.isNotEmpty) {
      var lastBid = round.bidHistory.last;
      
      // 激进程度
      if (round.bidHistory.length > 1) {
        var prevBid = round.bidHistory[round.bidHistory.length - 2];
        int increase = lastBid.quantity - prevBid.quantity;
        
        state.isAggressive = increase >= 2;
        state.isConservative = increase == 0 && lastBid.value == prevBid.value;
      }
      
      // 虚张概率（基于历史）
      state.bluffProbability = _estimateBluffProb(round, memory);
      
      // 质疑倾向
      state.challengeProbability = _estimateChallengeProb(round, memory);
      
      // 情绪状态
      state.isConfident = lastBid.quantity >= 5;
      state.isNervous = round.bidHistory.length > 5;
      state.isBluffing = state.bluffProbability > 0.6;
    }
    
    // 连胜/连败状态
    state.winStreak = memory.getWinStreak();
    state.isWeak = state.winStreak < -2;
    state.isTilting = state.winStreak < -3;
    
    return state;
  }
  
  void learn(GameRound round, Map<String, dynamic> decision) {
    // 记录玩家行为模式
    if (round.currentBid != null) {
      recentActions.add(PlayerAction(
        bid: round.currentBid!,
        round: round.bidHistory.length,
        wasBluff: false, // 需要在回合结束后更新
      ));
    }
    
    // 只保留最近20个行动
    if (recentActions.length > 20) {
      recentActions.removeAt(0);
    }
  }
  
  double _estimateBluffProb(GameRound round, GameMemory memory) {
    // 基于历史估计虚张概率
    if (memory.totalRounds == 0) return 0.3;
    
    return memory.opponentBluffs / math.max(1, memory.totalRounds);
  }
  
  double _estimateChallengeProb(GameRound round, GameMemory memory) {
    // 基于局势估计质疑概率
    double baseProb = 0.2;
    
    // 叫牌越高，质疑概率越大
    if (round.currentBid != null) {
      baseProb += round.currentBid!.quantity * 0.05;
    }
    
    // 回合越多，质疑概率越大
    baseProb += round.bidHistory.length * 0.03;
    
    return math.min(0.8, baseProb);
  }
}

/// 对手状态
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

/// 策略规划器（增强版）
class StrategicPlanner {
  final AIPersonality personality;
  final math.Random random = math.Random();
  
  StrategicPlanner(this.personality);
  
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
  
  GamePhase _identifyGamePhase(Situation situation) {
    if (situation.bidQuantity == 0) return GamePhase.early;
    if (situation.bidQuantity <= 4) return GamePhase.early;
    if (situation.bidQuantity <= 6) return GamePhase.middle;
    return GamePhase.late;
  }
  
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
    
    // 30% 试探
    if (roll < 0.30) {
      return Strategy(StrategyType.probe, confidence: 0.6);
    }
    
    // 20% 激进（根据性格调整）
    if (roll < 0.50 && personality.bluffRatio > 0.4) {
      return Strategy(StrategyType.aggressive, confidence: 0.65);
    }
    
    // 15% 陷阱（如果有条件）
    if (roll < 0.65 && situation.ourStrength > 0.5) {
      return Strategy(StrategyType.trap, confidence: 0.6);
    }
    
    // 15% 保守
    if (roll < 0.80) {
      return Strategy(StrategyType.conservative, confidence: 0.6);
    }
    
    // 20% 平衡
    return Strategy(StrategyType.balanced, confidence: 0.65);
  }
  
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
  
  Strategy _lateGameStrategy(Situation situation, OpponentState opponent) {
    // 后期：非常谨慎
    
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
    
    // 后期默认保守
    return Strategy(StrategyType.conservative, confidence: 0.7);
  }
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

/// 策略
class Strategy {
  final StrategyType type;
  final double confidence;
  
  Strategy(this.type, {this.confidence = 0.5});
}

/// 风险管理器
class RiskManager {
  final AIPersonality personality;
  
  RiskManager(this.personality);
  
  bool shouldTakeRisk(double risk, double reward) {
    // 根据性格决定是否冒险
    double threshold = personality.riskAppetite;
    
    // 风险收益比
    double ratio = reward / (risk + 0.1);
    
    return ratio > (2 - threshold); // 性格越冒险，阈值越低
  }
}

/// 诈唬专家
class BluffingExpert {
  final AIPersonality personality;
  
  BluffingExpert(this.personality);
  
  bool shouldBluff(Situation situation, OpponentState opponent) {
    // 诈唬的艺术
    
    // 如果对手很弱，不需要诈唬
    if (opponent.isWeak) return false;
    
    // 如果我们很强，也不需要诈唬
    if (situation.ourStrength > 0.7) return false;
    
    // 如果对手很可能质疑，不诈唬
    if (opponent.challengeProbability > 0.6) return false;
    
    // 根据性格决定
    return personality.bluffRatio > 0.5;
  }
}

/// 游戏记忆
class GameMemory {
  int totalRounds = 0;
  int wins = 0;
  int losses = 0;
  int opponentBluffs = 0;
  int ourBluffs = 0;
  
  final List<RoundResult> history = [];
  
  void recordRound(GameRound round, Map<String, dynamic> decision, Strategy strategy) {
    totalRounds++;
    
    history.add(RoundResult(
      round: round.bidHistory.length,
      decision: decision['type'],
      strategy: strategy.type,
      success: false, // 需要在回合结束后更新
    ));
    
    // 只保留最近50轮
    if (history.length > 50) {
      history.removeAt(0);
    }
  }
  
  int getWinStreak() {
    int streak = 0;
    for (int i = history.length - 1; i >= 0; i--) {
      if (history[i].success) {
        if (streak >= 0) streak++;
        else break;
      } else {
        if (streak <= 0) streak--;
        else break;
      }
    }
    return streak;
  }
}

/// 回合结果
class RoundResult {
  final int round;
  final String decision;
  final StrategyType strategy;
  bool success;
  
  RoundResult({
    required this.round,
    required this.decision,
    required this.strategy,
    required this.success,
  });
}
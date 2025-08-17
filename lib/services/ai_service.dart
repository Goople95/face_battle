import 'dart:math' as math;
import '../models/game_state.dart';
import '../models/ai_personality.dart';
import '../models/player_profile.dart';
import '../utils/logger_utils.dart';
import 'elite_ai_engine.dart';

/// 精简版AI服务 - 作为Gemini API的降级备用
class AIService {
  final AIPersonality personality;
  final PlayerProfile? playerProfile;
  final random = math.Random();
  late final EliteAIEngine eliteEngine;
  
  AIService({
    required this.personality,
    this.playerProfile,
  }) {
    eliteEngine = EliteAIEngine(personality: personality);
  }
  
  /// 决定AI行动 - 使用Elite AI引擎
  AIDecision decideAction(GameRound round, dynamic playerFaceData) {
    // 使用Elite AI引擎获取决策
    var eliteDecision = eliteEngine.makeEliteDecision(round);
    
    AILogger.logParsing('Local Elite AI决策', {
      'type': eliteDecision['type'],
      'confidence': eliteDecision['confidence'],
      'strategy': eliteDecision['strategy'],
    });
    
    // 转换为AIDecision格式
    if (eliteDecision['type'] == 'challenge') {
      return AIDecision(
        playerBid: round.currentBid,
        action: GameAction.challenge,
        probability: eliteDecision['confidence'] ?? 0.5,
        wasBluffing: false,
        reasoning: eliteDecision['reasoning'] ?? '战术质疑',
      );
    }
    
    // 继续叫牌
    Bid newBid = eliteDecision['bid'] ?? _generateFallbackBid(round);
    bool isBluffing = (eliteDecision['strategy'] ?? '').contains('bluff');
    
    return AIDecision(
      playerBid: round.currentBid,
      action: GameAction.bid,
      aiBid: newBid,
      probability: eliteDecision['confidence'] ?? 0.5,
      wasBluffing: isBluffing,
      reasoning: eliteDecision['reasoning'] ?? '战术叫牌',
    );
  }
  
  /// 生成降级叫牌
  Bid _generateFallbackBid(GameRound round) {
    if (round.currentBid == null) {
      return Bid(quantity: 2, value: random.nextInt(6) + 1);
    }
    
    // 简单增加数量
    return Bid(
      quantity: round.currentBid!.quantity + 1,
      value: round.currentBid!.value,
    );
  }
  
  /// 生成AI叫牌
  (Bid, bool) generateBidWithAnalysis(GameRound round) {
    // 使用Elite AI引擎
    var eliteDecision = eliteEngine.makeEliteDecision(round);
    
    // 确保是叫牌决策（不是质疑）
    if (eliteDecision['type'] == 'challenge') {
      // 如果Elite建议质疑，但我们需要叫牌，重新生成一个保守的叫牌
      Map<int, int> ourCounts = {};
      for (int value = 1; value <= 6; value++) {
        ourCounts[value] = round.aiDice.countValue(value, onesAreCalled: round.onesAreCalled);
      }
      
      // 找到我们最多的点数进行保守叫牌
      int maxCount = 0;
      int bestValue = 1;
      ourCounts.forEach((value, count) {
        if (count > maxCount) {
          maxCount = count;
          bestValue = value;
        }
      });
      
      Bid safeBid;
      if (round.currentBid == null) {
        safeBid = Bid(quantity: math.max(2, maxCount), value: bestValue);
      } else {
        safeBid = Bid(
          quantity: round.currentBid!.quantity + 1,
          value: bestValue,
        );
      }
      
      return (safeBid, false);
    }
    
    Bid newBid = eliteDecision['bid'] ?? _generateFallbackBid(round);
    bool isBluffing = (eliteDecision['strategy'] ?? '').contains('bluff');
    
    return (newBid, isBluffing);
  }
  
  /// 基于性格选择方案（简化版）
  Map<String, dynamic> _chooseOptionBasedOnPersonality(
    List<Map<String, dynamic>> options,
    GameRound round,
  ) {
    if (options.isEmpty) {
      // 紧急降级
      Bid lastBid = round.currentBid ?? Bid(quantity: 1, value: 1);
      return {
        'type': 'bid',
        'bid': Bid(
          quantity: lastBid.quantity + 1,
          value: lastBid.value
        ),
        'successRate': 0.3,
        'reasoning': '无选项降级',
      };
    }
    
    // 找出质疑选项和最佳叫牌选项
    Map<String, dynamic>? challengeOption;
    double maxBidSuccessRate = 0.0;
    
    for (var opt in options) {
      if (opt['type'] == 'challenge') {
        challengeOption = opt;
      } else if (opt['type'] == 'bid') {
        if (opt['successRate'] > maxBidSuccessRate) {
          maxBidSuccessRate = opt['successRate'];
        }
      }
    }
    
    // 智能比较质疑和叫牌
    if (challengeOption != null) {
      double challengeSuccessRate = challengeOption['successRate'];
      double difference = challengeSuccessRate - maxBidSuccessRate;
      
      // 根据性格设置质疑偏好
      double challengeBias = 0.0;
      switch (personality.id) {
        case 'gambler':
        case '0002':
          challengeBias = 0.15;  // 激进，更愿意质疑
          break;
        case 'provocateur':
        case '0003':
          challengeBias = 0.10;  // 心机，善于读取
          break;
        case 'youngwoman':
        case '0004':
          challengeBias = 0.08;  // 直觉型
          break;
        case 'professor':
        case '0001':
          challengeBias = -0.05; // 保守，倾向叫牌
          break;
        default:
          challengeBias = 0.05;
      }
      
      // 后期增加质疑倾向
      if (round.bidHistory.length > 4) {
        challengeBias += 0.1;
      }
      if (round.currentBid != null && round.currentBid!.quantity >= 7) {
        challengeBias += 0.15;
      }
      
      // 决定是否质疑
      bool shouldChallenge = false;
      
      if (challengeSuccessRate >= 0.75) {
        shouldChallenge = random.nextDouble() < 0.9;
      } else if (difference > challengeBias) {
        double challengeProb = 0.5 + (difference * 2);
        shouldChallenge = random.nextDouble() < challengeProb;
      } else if (challengeSuccessRate > 0.5 && maxBidSuccessRate < 0.4) {
        shouldChallenge = random.nextDouble() < 0.7;
      }
      
      if (shouldChallenge) {
        return challengeOption;
      }
    }
    
    // 根据性格选择叫牌
    return _selectBidByPersonality(options);
  }
  
  /// 根据性格选择叫牌（简化版）
  Map<String, dynamic> _selectBidByPersonality(List<Map<String, dynamic>> options) {
    // 过滤出叫牌选项
    List<Map<String, dynamic>> bidOptions = options.where((opt) => opt['type'] == 'bid').toList();
    if (bidOptions.isEmpty) return options[0];
    
    // 根据性格选择风险偏好
    String preferredRisk = 'normal';
    double minSuccessRate = 0.3;
    
    switch (personality.id) {
      case 'gambler':
      case '0002':
        preferredRisk = random.nextDouble() < 0.4 ? 'extreme' : 'risky';
        minSuccessRate = 0.15;
        break;
      case 'provocateur':
      case '0003':
        // 优先选择战术虚张
        for (var opt in bidOptions) {
          if (opt['strategy'] == 'tactical_bluff' && opt['successRate'] >= 0.25) {
            return opt;
          }
        }
        preferredRisk = 'risky';
        minSuccessRate = 0.25;
        break;
      case 'professor':
      case '0001':
        preferredRisk = 'safe';
        minSuccessRate = 0.45;
        break;
      case 'youngwoman':
      case '0004':
        // 随机
        double rand = random.nextDouble();
        if (rand < 0.3) {
          preferredRisk = 'safe';
        } else if (rand < 0.7) {
          preferredRisk = 'normal';
        } else {
          preferredRisk = 'risky';
        }
        minSuccessRate = 0.2;
        break;
    }
    
    // 选择符合条件的选项
    List<Map<String, dynamic>> preferred = bidOptions.where((opt) =>
      opt['riskLevel'] == preferredRisk && 
      opt['successRate'] >= minSuccessRate
    ).toList();
    
    if (preferred.isNotEmpty) {
      // 不总是选最优，增加随机性
      if (random.nextDouble() < 0.7 && preferred.length > 1) {
        return preferred[random.nextInt(math.min(3, preferred.length))];
      }
      return preferred[0];
    }
    
    // 降级：选择任何满足最低成功率的
    for (var opt in bidOptions) {
      if (opt['successRate'] >= minSuccessRate * 0.7) {
        return opt;
      }
    }
    
    // 最终降级：返回第一个选项
    return bidOptions[0];
  }
  
  /// 计算叫牌概率（供外部使用）
  double calculateBidProbability(Bid bid, DiceRoll ourDice, int totalDice, {bool onesAreCalled = false}) {
    int ourCount = ourDice.countValue(bid.value, onesAreCalled: onesAreCalled);
    int unknownDice = totalDice - 5;
    int needed = math.max(0, bid.quantity - ourCount);
    
    if (needed == 0) return 1.0;
    if (needed > unknownDice) return 0.0;
    
    double singleDieProbability;
    if (bid.value == 1) {
      singleDieProbability = 1.0 / 6.0;
    } else if (onesAreCalled) {
      singleDieProbability = 1.0 / 6.0;
    } else {
      singleDieProbability = 2.0 / 6.0;
    }
    
    double probability = 0.0;
    for (int k = needed; k <= unknownDice; k++) {
      probability += _binomialProbability(unknownDice, k, singleDieProbability);
    }
    
    return probability.clamp(0.05, 0.95);
  }
  
  double _binomialProbability(int n, int k, double p) {
    if (k > n) return 0.0;
    if (k == 0) return math.pow(1 - p, n).toDouble();
    
    double coefficient = 1.0;
    for (int i = 0; i < k; i++) {
      coefficient *= (n - i) / (i + 1);
    }
    
    return coefficient * math.pow(p, k) * math.pow(1 - p, n - k);
  }
  
  /// 生成对话和表情（使用Elite引擎）
  (String dialogue, String expression) generateDialogue(GameRound round, GameAction? lastAction, Bid? newBid) {
    // 生成Elite决策获取策略信息
    var eliteDecision = eliteEngine.makeEliteDecision(round);
    
    // 基于策略生成对话
    String dialogue = '';
    String expression = 'thinking';
    
    // 如果有心理战术，优先使用
    if (eliteDecision['psychTactic'] != null) {
      switch (eliteDecision['psychTactic']) {
        case '反向陷阱':
          dialogue = '我...不太确定';
          expression = 'nervous';
          break;
        case '压力升级':
          dialogue = '来真的吧！';
          expression = 'confident';
          break;
        case '模式破坏':
          dialogue = '换个玩法';
          expression = 'suspicious';
          break;
        case '后期施压':
          dialogue = '该结束了';
          expression = 'confident';
          break;
        case '诱导激进':
          dialogue = '你敢跟吗？';
          expression = 'happy';
          break;
        default:
          dialogue = _getStrategyDialogue(eliteDecision['strategy'] ?? '', lastAction, newBid);
      }
    } else {
      dialogue = _getStrategyDialogue(eliteDecision['strategy'] ?? '', lastAction, newBid);
    }
    
    // 根据策略调整表情
    String strategy = eliteDecision['strategy'] ?? '';
    if (strategy.contains('bluff')) {
      expression = random.nextDouble() < 0.3 ? 'nervous' : 'thinking';
    } else if (strategy.contains('value')) {
      expression = 'confident';
    } else if (strategy.contains('trap')) {
      expression = 'nervous';
    } else if (strategy.contains('pressure')) {
      expression = 'confident';
    }
    
    // 性格微调
    switch (personality.id) {
      case 'professor':
      case '0001':
        if (expression == 'confident' && random.nextDouble() < 0.5) {
          expression = 'thinking';
        }
        break;
      case 'gambler':
      case '0002':
        if (expression == 'thinking' && random.nextDouble() < 0.5) {
          expression = 'confident';
        }
        break;
      case 'provocateur':
      case '0003':
        if (random.nextDouble() < 0.3) expression = 'suspicious';
        break;
      case 'youngwoman':
      case '0004':
        if (random.nextDouble() < 0.3) expression = 'happy';
        break;
    }
    
    return (dialogue, expression);
  }
  
  /// 根据策略生成对话
  String _getStrategyDialogue(String strategy, GameAction? lastAction, Bid? newBid) {
    if (lastAction == GameAction.challenge) {
      return _getRandomFrom(['我不信', '你在虚张', '不可能', '让我看看']);
    }
    
    switch (strategy) {
      case 'value_bet':
        return _getRandomFrom(['稳稳的', '我有货', '跟上来']);
      case 'semi_bluff':
        return _getRandomFrom(['试试看', '继续玩', '跟不跟']);
      case 'bluff':
      case 'pure_bluff':
        return _getRandomFrom(['就这样', '全押了', '敢跟吗']);
      case 'reverse_trap':
        return '我...不太确定';
      case 'pressure_play':
        return '来真的吧！';
      default:
        if (newBid != null) {
          return '我叫${newBid}';
        }
        return '继续';
    }
  }
  
  String _getRandomFrom(List<String> options) {
    return options[random.nextInt(options.length)];
  }
  
  /// 获取嘲讽语句
  String getTaunt(GameRound round) {
    if (personality.taunts.isEmpty) return '';
    
    if (round.bidHistory.length > 4 && random.nextDouble() < 0.3) {
      return personality.taunts[random.nextInt(personality.taunts.length)];
    }
    
    return '';
  }
}
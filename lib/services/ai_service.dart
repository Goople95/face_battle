import 'dart:math' as math;
import '../models/game_state.dart';
import '../models/ai_personality.dart';
import '../models/player_profile.dart';
import 'bid_options_calculator.dart';

/// 精简版AI服务 - 作为Gemini API的降级备用
class AIService {
  final AIPersonality personality;
  final PlayerProfile? playerProfile;
  final random = math.Random();
  
  AIService({
    required this.personality,
    this.playerProfile,
  });
  
  /// 决定AI行动 - 使用BidOptionsCalculator
  AIDecision decideAction(GameRound round, dynamic playerFaceData) {
    if (round.currentBid == null) {
      // 首轮总是叫牌
      return AIDecision(
        playerBid: null,
        action: GameAction.bid,
        probability: 0.5,
        wasBluffing: false,
        reasoning: '开局策略',
      );
    }
    
    // 使用统一的选项计算器
    Map<int, int> ourCounts = {};
    for (int value = 1; value <= 6; value++) {
      ourCounts[value] = round.aiDice.countValue(value, onesAreCalled: round.onesAreCalled);
    }
    
    List<Map<String, dynamic>> options = BidOptionsCalculator.calculateAllOptions(round, ourCounts);
    
    // 基于性格选择方案
    var chosen = _chooseOptionBasedOnPersonality(options, round);
    
    // 如果选择质疑
    if (chosen['type'] == 'challenge') {
      return AIDecision(
        playerBid: round.currentBid,
        action: GameAction.challenge,
        probability: 1.0 - chosen['successRate'],
        wasBluffing: false,
        reasoning: '成功率${(chosen['successRate'] * 100).toStringAsFixed(1)}%',
      );
    }
    
    // 继续叫牌
    return AIDecision(
      playerBid: round.currentBid,
      action: GameAction.bid,
      aiBid: chosen['bid'],
      probability: chosen['successRate'],
      wasBluffing: chosen['strategy'] == 'tactical_bluff',
      reasoning: chosen['reasoning'] ?? '继续加注',
    );
  }
  
  /// 生成AI叫牌
  (Bid, bool) generateBidWithAnalysis(GameRound round) {
    Map<int, int> ourCounts = {};
    for (int value = 1; value <= 6; value++) {
      ourCounts[value] = round.aiDice.countValue(value, onesAreCalled: round.onesAreCalled);
    }
    
    List<Map<String, dynamic>> options = BidOptionsCalculator.calculateAllOptions(round, ourCounts);
    
    var chosen = _chooseOptionBasedOnPersonality(options, round);
    
    // 如果选择质疑，降级到安全叫牌
    if (chosen['type'] == 'challenge') {
      for (var opt in options) {
        if (opt['type'] == 'bid' && opt['riskLevel'] == 'safe') {
          chosen = opt;
          break;
        }
      }
      // 如果还是没有，选第一个叫牌
      if (chosen['type'] == 'challenge') {
        for (var opt in options) {
          if (opt['type'] == 'bid') {
            chosen = opt;
            break;
          }
        }
      }
    }
    
    Bid newBid = chosen['bid'] ?? Bid(quantity: chosen['quantity'], value: chosen['value']);
    bool isBluffing = chosen['strategy'] == 'tactical_bluff' || 
                      (chosen['successRate'] ?? 0.5) < 0.4;
    
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
  
  /// 生成对话和表情（简化版）
  (String dialogue, String expression) generateDialogue(GameRound round, GameAction? lastAction, Bid? newBid) {
    String dialogue = '';
    String expression = 'thinking';
    
    if (lastAction == GameAction.challenge) {
      // 质疑时的对话
      dialogue = _getRandomFrom([
        '我不信',
        '你在虚张',
        '不可能',
        '让我看看',
      ]);
      expression = 'suspicious';
    } else if (newBid != null) {
      // 叫牌时的对话
      bool isHighBid = round.currentBid != null && 
                       newBid.quantity > round.currentBid!.quantity + 1;
      
      if (isHighBid) {
        dialogue = _getRandomFrom([
          '加大注码',
          '来真的了',
          '提高赌注',
        ]);
        expression = 'confident';
      } else {
        dialogue = _getRandomFrom([
          '继续',
          '跟注',
          '我叫${newBid}',
        ]);
        expression = random.nextDouble() < 0.5 ? 'thinking' : 'happy';
      }
    }
    
    // 性格特定调整
    switch (personality.id) {
      case 'professor':
      case '0001':
        if (expression == 'confident') expression = 'thinking';
        break;
      case 'gambler':
      case '0002':
        if (expression == 'thinking') expression = 'confident';
        break;
      case 'provocateur':
      case '0003':
        if (random.nextDouble() < 0.4) expression = 'suspicious';
        break;
      case 'youngwoman':
      case '0004':
        if (random.nextDouble() < 0.5) expression = 'happy';
        break;
    }
    
    return (dialogue, expression);
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
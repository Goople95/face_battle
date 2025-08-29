import 'dart:math' as math;
import '../models/game_state.dart';
import '../models/ai_personality.dart';
import '../models/game_progress.dart';
import 'game_progress_service.dart';
import '../utils/logger_utils.dart';
import 'elite_ai_engine.dart';
import 'master_ai_engine.dart';
import 'dialogue_service.dart';

/// AI服务 - 游戏AI决策引擎
class AIService {
  final AIPersonality personality;
  final GameProgressData? playerProfile;
  final random = math.Random();
  late final EliteAIEngine eliteEngine;
  late final MasterAIEngine masterEngine;
  
  // 保存Master引擎的决策，供对话生成使用
  String _lastMasterStrategy = '';
  Map<String, dynamic>? _lastMasterDecision;
  
  AIService({
    required this.personality,
    this.playerProfile,
  }) {
    eliteEngine = EliteAIEngine(personality: personality);
    masterEngine = MasterAIEngine(personality: personality);
  }
  
  /// 决定AI行动 - 使用Master AI引擎
  AIDecision decideAction(GameRound round, dynamic playerFaceData) {
    // 同时获取Master和Elite决策
    var masterDecision = masterEngine.makeDecision(round);
    var eliteDecision = eliteEngine.makeEliteDecision(round);
    
    // 保存Master的策略供对话生成使用
    _lastMasterStrategy = masterDecision['strategy'] ?? '';
    _lastMasterDecision = masterDecision;
    
    // 详细记录Master决策
    AILogger.logParsing('🎯 [Master AI决策]', {
      'type': masterDecision['type'],
      'confidence': masterDecision['confidence'],
      'strategy': masterDecision['strategy'],
      'reasoning': masterDecision['reasoning'],
      'bid': masterDecision['bid']?.toString(),
    });
    
    // 详细记录Elite决策（供对比观察）
    // Elite直接返回决策，不是嵌套在choice字段中
    AILogger.logParsing('👑 [Elite AI决策]', {
      'type': eliteDecision['type'],
      'confidence': eliteDecision['confidence'] ?? eliteDecision['successRate'],
      'strategy': eliteDecision['strategy'],
      'reasoning': eliteDecision['reasoning'],
      'bid': eliteDecision['bid']?.toString(),
      'psychTactic': eliteDecision['psychTactic'],
    });
    
    // 对比两个引擎的决策差异
    if (masterDecision['type'] != eliteDecision['type']) {
      AILogger.logParsing('⚠️ [决策差异]', {
        'Master选择': masterDecision['type'] == 'challenge' ? '质疑' : '"叫牌: ${masterDecision['bid']}"',
        'Elite选择': eliteDecision['type'] == 'challenge' ? '质疑' : '"叫牌: ${eliteDecision['bid']}"',
        'Master策略': masterDecision['strategy'],
        'Elite策略': eliteDecision['strategy'],
      });
    }
    
    // 使用Master的决策，但提供Elite的选项列表用于UI显示
    List<Map<String, dynamic>>? eliteOptions = eliteDecision['allOptions'] as List<Map<String, dynamic>>?;
    
    // 转换为AIDecision格式
    if (masterDecision['type'] == 'challenge') {
      return AIDecision(
        playerBid: round.currentBid,
        action: GameAction.challenge,
        probability: masterDecision['confidence'] ?? 0.5,
        wasBluffing: false,
        reasoning: masterDecision['reasoning'] ?? '战术质疑',
        eliteOptions: eliteOptions, // 提供Elite选项列表供UI显示
      );
    }
    
    // 继续叫牌
    Bid newBid = masterDecision['bid'] ?? _generateFallbackBid(round);
    bool isBluffing = (masterDecision['strategy'] ?? '').contains('bluff') || 
                     (masterDecision['strategy'] ?? '').contains('trap');
    
    return AIDecision(
      playerBid: round.currentBid,
      action: GameAction.bid,
      aiBid: newBid,
      probability: masterDecision['confidence'] ?? 0.5,
      wasBluffing: isBluffing,
      reasoning: masterDecision['reasoning'] ?? '战术叫牌',
      eliteOptions: eliteOptions, // 提供Elite选项列表供UI显示
    );
  }
  
  /// 生成降级叫牌
  Bid _generateFallbackBid(GameRound round) {
    if (round.currentBid == null) {
      return Bid(quantity: 2, value: random.nextInt(6) + 1);
    }
    
    // 如果当前叫的是1（最大值），必须增加数量
    if (round.currentBid!.value == 1) {
      return Bid(
        quantity: round.currentBid!.quantity + 1,
        value: random.nextInt(6) + 1,  // 可以选择任意点数
      );
    }
    
    // 如果不是1，可以尝试叫1（相同数量）或增加数量
    if (random.nextBool() && round.currentBid!.value != 1) {
      // 50%概率尝试叫1
      return Bid(
        quantity: round.currentBid!.quantity,
        value: 1,
      );
    } else {
      // 否则简单增加数量
      return Bid(
        quantity: round.currentBid!.quantity + 1,
        value: round.currentBid!.value,
      );
    }
  }
  
  /// 生成AI叫牌
  (Bid, bool) generateBidWithAnalysis(GameRound round) {
    // 使用Master AI引擎（与decideAction保持一致）
    var masterDecision = masterEngine.makeDecision(round);
    
    // 也获取Elite的决策供对比
    var eliteDecision = eliteEngine.makeEliteDecision(round);
    
    // 记录对比日志
    AILogger.logParsing('🎯 [generateBid - Master]', {
      'type': masterDecision['type'],
      'bid': masterDecision['bid']?.toString(),
      'strategy': masterDecision['strategy'],
    });
    
    AILogger.logParsing('👑 [generateBid - Elite]', {
      'type': eliteDecision['type'],
      'bid': eliteDecision['bid']?.toString(),
      'strategy': eliteDecision['strategy'],
    });
    
    // 保存Master的策略供对话生成使用
    _lastMasterStrategy = masterDecision['strategy'] ?? '';
    _lastMasterDecision = masterDecision;
    
    // 确保是叫牌决策（不是质疑）
    if (masterDecision['type'] == 'challenge') {
      // 如果Master AI建议质疑，但我们需要叫牌，重新生成一个保守的叫牌
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
        // 生成一个安全的叫牌，确保遵循游戏规则
        Bid testBid = Bid(
          quantity: round.currentBid!.quantity,
          value: bestValue,
        );
        
        // 如果同数量的叫牌不合法，则增加数量
        if (!testBid.isHigherThan(round.currentBid!)) {
          safeBid = Bid(
            quantity: round.currentBid!.quantity + 1,
            value: bestValue,
          );
        } else {
          safeBid = testBid;
        }
      }
      
      return (safeBid, false);
    }
    
    Bid newBid = masterDecision['bid'] ?? _generateFallbackBid(round);
    bool isBluffing = (masterDecision['strategy'] ?? '').contains('bluff') || 
                     (masterDecision['strategy'] ?? '').contains('trap');
    
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
  
  /// 生成对话和表情（使用保存的Master决策）
  (String dialogue, String expression) generateDialogue(GameRound round, GameAction? lastAction, Bid? newBid, {String locale = 'en'}) {
    // 使用已保存的Master策略，确保决策和对话一致
    String strategy = _lastMasterStrategy;
    Map<String, dynamic>? masterDecision = _lastMasterDecision;
    
    // 基于策略生成对话
    final dialogueService = DialogueService();
    String dialogue = '';
    String expression = 'thinking';
    
    // 检查是否有特殊策略或心理战术
    if (masterDecision != null && masterDecision['psychTactic'] != null) {
      // 使用DialogueService获取心理战术对话
      dialogue = dialogueService.getStrategyDialogue(
        personality.id, 
        masterDecision['psychTactic'], 
        locale: locale
      );
      
      // 根据心理战术设置表情（只用核心4种）
      switch (masterDecision['psychTactic']) {
        case 'reverse_trap_alt':
          expression = 'suspicious';  // nervous改为suspicious
          break;
        case 'pressure_escalation':
        case 'late_pressure':
          expression = 'confident';
          break;
        case 'pattern_break':
          expression = 'suspicious';
          break;
        case 'aggressive_bait':
          expression = 'happy';
          break;
        default:
          expression = 'thinking';
      }
    } else {
      dialogue = _getStrategyDialogue(strategy, lastAction, newBid, locale: locale);
      
      // 如果是叫牌格式标记，保留它让game_screen处理
      if (dialogue == '__USE_BID_FORMAT__' && newBid != null) {
        // 保持标记不变
      }
    }
    
    // 根据策略调整表情（只用核心4种）
    if (strategy.contains('bluff')) {
      expression = random.nextDouble() < 0.3 ? 'suspicious' : 'thinking';
    } else if (strategy.contains('value')) {
      expression = 'confident';
    } else if (strategy.contains('trap')) {
      expression = 'suspicious';  // nervous改为suspicious
    } else if (strategy.contains('pressure')) {
      expression = 'confident';
    }
    
    // 性格微调（只用新ID格式）
    switch (personality.id) {
      case '0001':
        if (expression == 'confident' && random.nextDouble() < 0.5) {
          expression = 'thinking';
        }
        break;
      case '0002':
        if (expression == 'thinking' && random.nextDouble() < 0.5) {
          expression = 'confident';
        }
        break;
      case '0003':
        if (random.nextDouble() < 0.3) expression = 'suspicious';
        break;
      case '0004':
        if (random.nextDouble() < 0.3) expression = 'happy';
        break;
    }
    
    return (dialogue, expression);
  }
  
  /// 根据策略生成对话
  String _getStrategyDialogue(String strategy, GameAction? lastAction, Bid? newBid, {String locale = 'en'}) {
    final dialogueService = DialogueService();
    
    if (lastAction == GameAction.challenge) {
      return dialogueService.getStrategyDialogue(personality.id, 'challenge_action', locale: locale);
    }
    
    // 对于bluff和pure_bluff，统一使用bluff策略对话
    String dialogueStrategy = strategy;
    if (strategy == 'pure_bluff') {
      dialogueStrategy = 'bluff';
    }
    
    // 如果没有匹配的策略，使用默认对话
    final dialogue = dialogueService.getStrategyDialogue(personality.id, dialogueStrategy, locale: locale);
    
    // 如果返回默认值且有newBid，返回特殊标记让调用方使用ARB格式
    if (dialogue == '...' && newBid != null) {
      // 返回特殊标记，让调用方使用本地化的叫牌格式
      return '__USE_BID_FORMAT__';
    }
    
    return dialogue;
  }
  
  String _getRandomFrom(List<String> options) {
    return options[random.nextInt(options.length)];
  }
  
  /// 获取嘲讽语句
  Future<String> getTaunt(GameRound round) async {
    // 使用DialogueService获取对话
    final dialogueService = DialogueService();
    
    if (round.bidHistory.length > 4 && random.nextDouble() < 0.3) {
      // 根据当前状态决定使用嘲讽还是鼓励
      final isWinning = _isCurrentlyWinning(round);
      return isWinning 
        ? await dialogueService.getTaunt(personality.id)
        : await dialogueService.getEncouragement(personality.id);
    }
    
    return '';
  }
  
  /// 判断AI是否当前处于优势
  bool _isCurrentlyWinning(GameRound round) {
    // 简单判断：如果当前轮到玩家，说明上一个出价是AI的
    // 因为游戏是轮流进行的
    return round.isPlayerTurn;
  }
}
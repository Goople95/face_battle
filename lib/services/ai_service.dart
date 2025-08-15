import 'dart:math';
import '../models/game_state.dart';
import '../models/ai_personality.dart';
import '../models/player_profile.dart';

class AIService {
  final AIPersonality personality;
  final PlayerProfile? playerProfile;
  final Random _random = Random();
  
  // AI emotional state
  double _currentValence = 0.0;     // -1 to 1 (negative to positive)
  double _currentArousal = 0.5;     // 0 to 1 (calm to excited)
  double _currentConfidence = 0.5;  // 0 to 1
  double _currentBluffLevel = 0.0;  // 0 to 1
  
  // Acting cooldown
  int _reverseActingCooldown = 0;
  
  AIService({
    required this.personality,
    this.playerProfile,
  });
  
  /// Get current AI emotional state for expression rendering
  Map<String, double> get emotionalState => {
    'valence': _currentValence,
    'arousal': _currentArousal,
    'confidence': _currentConfidence,
    'bluff': _currentBluffLevel,
  };
  
  /// Decide AI action based on game state
  AIDecision decideAction(GameRound round, dynamic playerFaceData) {
    if (round.currentBid == null) {
      // First bid - always bid
      // 注意：这里的probability会在makeDecision中被重新计算
      return AIDecision(
        playerBid: null,
        action: GameAction.bid,
        probability: 0.5,  // 占位符，会在生成具体叫牌后重新计算
        wasBluffing: false,
        reasoning: '开局策略：基于手牌选择稳健开局',
      );
    }
    
    // Calculate probability of current bid being true
    double bidTrueProbability = calculateBidProbability(
      round.currentBid!,
      round.aiDice,
      round.totalDiceCount,
      onesAreCalled: round.onesAreCalled,
    );
    
    // Face data removed for privacy
    
    // Update emotional state
    _updateEmotionalState(bidTrueProbability);
    
    // Make decision with personality bias
    double challengeThreshold = personality.challengeThreshold;
    double originalThreshold = challengeThreshold;
    
    // Add some randomness based on mistake rate
    bool madeError = false;
    if (_random.nextDouble() < personality.mistakeRate) {
      challengeThreshold += (_random.nextDouble() - 0.5) * 0.2;
      madeError = true;
    }
    
    GameAction action;
    String reasoning;
    
    if (bidTrueProbability < challengeThreshold) {
      action = GameAction.challenge;
      reasoning = '根据计算，你的${round.currentBid}成功概率仅${(bidTrueProbability * 100).toStringAsFixed(1)}%';
      if (madeError && bidTrueProbability > originalThreshold) {
        reasoning += '（冲动决定）';
      }
    } else {
      action = GameAction.bid;
      reasoning = '你的${round.currentBid}有${(bidTrueProbability * 100).toStringAsFixed(1)}%可能为真，继续加注';
      if (madeError && bidTrueProbability < originalThreshold) {
        reasoning += '（保守过度）';
      }
    }
    
    return AIDecision(
      playerBid: round.currentBid,
      action: action,
      probability: bidTrueProbability,
      wasBluffing: false,
      reasoning: reasoning,
    );
  }
  
  /// Generate AI bid with analysis
  (Bid, bool) generateBidWithAnalysis(GameRound round) {
    Bid? lastBid = round.currentBid;
    
    // Calculate what we actually have
    Map<int, int> ourCounts = {};
    for (int value = 2; value <= 6; value++) {
      ourCounts[value] = round.aiDice.countValue(value);
    }
    
    // Decide bluff level based on personality
    double bluffDecision = _random.nextDouble();
    bool shouldBluff = bluffDecision < personality.bluffRatio;
    
    Bid newBid;
    if (shouldBluff) {
      _currentBluffLevel = 0.3 + _random.nextDouble() * 0.5;
      
      // Generate aggressive bid
      newBid = _generateAggressiveBid(lastBid, round.totalDiceCount);
    } else {
      _currentBluffLevel = 0.0;
      
      // Generate conservative bid
      newBid = _generateConservativeBid(lastBid, ourCounts, round.totalDiceCount, round.aiDice);
    }
    
    return (newBid, shouldBluff);
  }
  
  /// Legacy method for compatibility
  Bid generateBid(GameRound round) {
    return generateBidWithAnalysis(round).$1;
  }
  
  /// Calculate probability of a bid being true
  double calculateBidProbability(Bid bid, DiceRoll ourDice, int totalDice, {bool onesAreCalled = false}) {
    int ourCount = ourDice.countValue(bid.value, onesAreCalled: onesAreCalled);
    int unknownDice = totalDice - ourDice.values.length;
    int needed = bid.quantity - ourCount;
    
    if (needed <= 0) return 1.0; // We already have enough
    if (needed > unknownDice) return 0.0; // Impossible
    
    // Binomial probability calculation
    double singleDieProbability;
    if (bid.value == 1) {
      singleDieProbability = 1.0 / 6.0; // Only actual 1s count
    } else if (onesAreCalled) {
      singleDieProbability = 1.0 / 6.0; // 1s no longer wild
    } else {
      singleDieProbability = 2.0 / 6.0; // Value + wild 1s
    }
    double probability = 0.0;
    
    for (int k = needed; k <= unknownDice; k++) {
      probability += _binomialProbability(unknownDice, k, singleDieProbability);
    }
    
    return probability.clamp(0.0, 1.0);
  }
  
  double _binomialProbability(int n, int k, double p) {
    if (k > n) return 0.0;
    
    // Simplified calculation for small values
    double coefficient = 1.0;
    for (int i = 0; i < k; i++) {
      coefficient *= (n - i) / (i + 1);
    }
    
    return coefficient * pow(p, k) * pow(1 - p, n - k);
  }
  
  
  /// Update AI emotional state based on game situation
  void _updateEmotionalState(double bidTrueProbability) {
    // Valence: positive if winning, negative if losing
    _currentValence = (bidTrueProbability - 0.5) * 2;
    
    // Arousal: high when decision is difficult
    _currentArousal = 1.0 - (bidTrueProbability - 0.5).abs() * 2;
    
    // Confidence: based on probability and personality
    _currentConfidence = bidTrueProbability * (1.0 - personality.tellExposure) +
                        personality.tellExposure * 0.5;
    
    // Decide if should do reverse acting
    if (_reverseActingCooldown <= 0 && 
        _random.nextDouble() < personality.reverseActingProb) {
      // Reverse the valence for acting
      _currentValence = -_currentValence;
      _reverseActingCooldown = 3; // Cooldown for 3 turns
    } else if (_reverseActingCooldown > 0) {
      _reverseActingCooldown--;
    }
  }
  
  Bid _generateConservativeBid(Bid? lastBid, Map<int, int> ourCounts, int totalDice, DiceRoll ourDice) {
    // Find our best value
    int bestValue = 2;
    int bestCount = 0;
    
    // Also count 1s separately (they're wild for other values)
    int onesCount = 0;
    for (int die in ourDice.values) {
      if (die == 1) onesCount++;
    }
    
    for (var entry in ourCounts.entries) {
      if (entry.value > bestCount) {
        bestCount = entry.value;
        bestValue = entry.key;
      }
    }
    
    // Generate minimal increase
    if (lastBid == null) {
      // Opening bid - be conservative with 5 dice each
      return Bid(quantity: max(2, bestCount), value: bestValue);
    }
    
    // Check if we can make a valid higher bid
    Bid candidateBid;
    
    // Try same quantity with higher value
    if (lastBid.value < 6) {
      candidateBid = Bid(quantity: lastBid.quantity, value: lastBid.value + 1);
      if (candidateBid.isHigherThan(lastBid)) {
        return candidateBid;
      }
    }
    
    // Try switching to 1s if beneficial
    if (lastBid.value != 1 && onesCount > 0) {
      int requiredQuantity = (lastBid.quantity + 1) ~/ 2;
      if (onesCount >= requiredQuantity) {
        candidateBid = Bid(quantity: requiredQuantity, value: 1);
        if (candidateBid.isHigherThan(lastBid)) {
          return candidateBid;
        }
      }
    }
    
    // Minimal quantity increase
    return Bid(quantity: lastBid.quantity + 1, value: max(2, lastBid.value));
  }
  
  Bid _generateAggressiveBid(Bid? lastBid, int totalDice) {
    if (lastBid == null) {
      // Opening aggressive bid - with 10 total dice
      int quantity = 3 + _random.nextInt(3); // 3-5
      int value = 3 + _random.nextInt(4); // 3-6
      return Bid(quantity: quantity, value: value);
    }
    
    // Try aggressive 1s bid sometimes
    if (lastBid.value != 1 && _random.nextDouble() < 0.2) {
      int requiredQuantity = (lastBid.quantity + 1) ~/ 2;
      Bid onesBid = Bid(quantity: requiredQuantity + _random.nextInt(2), value: 1);
      if (onesBid.isHigherThan(lastBid)) {
        return onesBid;
      }
    }
    
    // Aggressive increase
    int quantityIncrease = 1 + (_random.nextDouble() < personality.riskAppetite ? 2 : 1);
    int newQuantity = min(lastBid.quantity + quantityIncrease, totalDice);
    
    // Sometimes jump in value too
    int newValue = lastBid.value;
    if (_random.nextDouble() < 0.3 && lastBid.value < 6) {
      newValue = min(6, lastBid.value + 1 + _random.nextInt(2));
    }
    
    // Make sure the bid is valid
    Bid candidateBid = Bid(quantity: newQuantity, value: newValue);
    if (!candidateBid.isHigherThan(lastBid)) {
      // Fall back to minimal increase
      return Bid(quantity: lastBid.quantity + 1, value: max(2, lastBid.value));
    }
    
    return candidateBid;
  }
  
  /// Get taunt based on situation
  String getTaunt(GameRound round) {
    if (personality.taunts.isEmpty) return '';
    return personality.taunts[_random.nextInt(personality.taunts.length)];
  }
  
  /// Generate contextual dialogue and expression
  (String dialogue, String expression) generateDialogue(GameRound round, GameAction? lastAction, Bid? newBid) {
    String dialogue = '';
    String expression = 'neutral';
    
    // Based on emotional state and situation
    if (lastAction == GameAction.challenge) {
      // AI decided to challenge
      if (_currentConfidence > 0.8) {
        dialogue = _getRandomFrom([
          '你在虚张吧？',
          '让我看看你的牌！',
          '不可能有这么多！',
          '我不信！',
          '这个太夸张了吧！',
        ]);
        expression = _getRandomFrom(['confident', 'determined', 'suspicious']);
      } else if (_currentConfidence > 0.5) {
        dialogue = _getRandomFrom([
          '我觉得不太可能...',
          '让我赌一把...',
          '有点悬啊...',
        ]);
        expression = _getRandomFrom(['worried', 'anxious', 'contemplating']);
      } else {
        dialogue = _getRandomFrom([
          '应该...不会吧？',
          '只能拼了...',
          '希望我没猜错...',
        ]);
        expression = _getRandomFrom(['nervous', 'anxious', 'frustrated']);
      }
    } else if (newBid != null) {
      // AI made a bid
      double bidRisk = newBid.quantity / 10.0; // Estimate risk level
      
      if (_currentBluffLevel > 0.7) {
        // Heavy bluffing
        dialogue = _getRandomFrom([
          '这都是小意思~',
          '你敢质疑吗？',
          '我很有把握哦！',
          '继续加吧！',
        ]);
        expression = _getRandomFrom(['smirk', 'cunning', 'playful']);
      } else if (_currentBluffLevel > 0.4) {
        // Moderate bluffing
        dialogue = _getRandomFrom([
          '我很有信心哦~',
          '这个很简单吧？',
          '你敢跟吗？',
          '来吧来吧！',
        ]);
        expression = _getRandomFrom(['confident', 'proud', 'determined']);
      } else if (_currentConfidence > 0.7) {
        // Very confident
        dialogue = _getRandomFrom([
          '我手气不错',
          '这把稳了',
          '没问题的',
          '放心吧',
        ]);
        expression = _getRandomFrom(['happy', 'relaxed', 'proud']);
      } else if (_currentConfidence > 0.4) {
        // Moderate confidence
        dialogue = _getRandomFrom([
          '应该可以吧',
          '试试看',
          '感觉还行',
        ]);
        expression = _getRandomFrom(['thinking', 'contemplating', 'neutral']);
      } else {
        // Low confidence
        dialogue = _getRandomFrom([
          '希望运气好一点...',
          '应该问题不大...',
          '冒个险吧...',
          '只能这样了...',
        ]);
        expression = _getRandomFrom(['nervous', 'worried', 'anxious']);
      }
      
      // Additional variation based on bid risk
      if (bidRisk > 0.7) {
        expression = _getRandomFrom(['anxious', 'nervous', 'determined', 'frustrated']);
      } else if (bidRisk < 0.3) {
        expression = _getRandomFrom(['relaxed', 'confident', 'happy', 'playful']);
      }
    }
    
    // Add personality-specific flavor with more variations
    if (personality.id == 'professor') {
      // 稳重大叔 - 理性分析型
      if (_currentConfidence > 0.7) {
        expression = _getRandomFrom(['thinking', 'contemplating', 'confident']);
      } else if (_currentBluffLevel > 0.5) {
        expression = _getRandomFrom(['cunning', 'suspicious', 'determined']);
      }
    } else if (personality.id == 'gambler') {
      // 冲动小哥 - 冒险激情型
      if (_currentBluffLevel > 0.3) {
        expression = _getRandomFrom(['excited', 'playful', 'smirk']);
      } else if (_currentConfidence < 0.4) {
        expression = _getRandomFrom(['anxious', 'frustrated', 'nervous']);
      }
    } else if (personality.id == 'provocateur') {
      // 心机御姐 - 心理战术型
      if (_random.nextDouble() < 0.4) {
        expression = _getRandomFrom(['cunning', 'playful', 'smirk', 'suspicious']);
      } else if (_currentConfidence > 0.6) {
        expression = _getRandomFrom(['proud', 'confident', 'relaxed']);
      }
    } else if (personality.id == 'youngwoman') {
      // 活泼少女 - 直觉任性型
      if (_random.nextDouble() < 0.3) {
        expression = _getRandomFrom(['playful', 'excited', 'happy', 'smirk']);
      } else if (_currentConfidence < 0.5) {
        expression = _getRandomFrom(['worried', 'anxious', 'frustrated']);
      } else {
        expression = _getRandomFrom(['confident', 'proud', 'determined']);
      }
    }
    
    // Random expression changes for more variety
    if (_random.nextDouble() < 0.15) {
      // 15% chance of surprise emotion
      expression = _getRandomFrom(['surprised', 'disappointed', 'contemplating']);
    }
    
    return (dialogue, expression);
  }
  
  String _getRandomFrom(List<String> options) {
    return options[_random.nextInt(options.length)];
  }
  
  /// Get expression emoji based on state
  String getExpressionEmoji(String expression) {
    switch (expression) {
      case 'happy': return '😄';
      case 'confident': return '😎';
      case 'smirk': return '😏';
      case 'nervous': return '😰';
      case 'worried': return '😟';
      case 'thinking': return '🤔';
      case 'excited': return '🤩';
      case 'mysterious': return '🤫';
      case 'neutral': return '😐';
      case 'suspicious': return '🤨';
      case 'proud': return '😊';
      case 'anxious': return '😖';
      case 'frustrated': return '😤';
      case 'disappointed': return '😞';
      case 'contemplating': return '🤔';
      case 'determined': return '😤';
      case 'cunning': return '😈';
      case 'playful': return '😜';
      case 'relaxed': return '😌';
      case 'surprised': return '😲';
      // Chinese expressions
      case '开心': return '😄';
      case '自信': return '😎';
      case '得意': return '😏';
      case '紧张': return '😰';
      case '担心': return '😟';
      case '思考': return '🤔';
      case '兴奋': return '🤩';
      case '神秘': return '🤫';
      case '平静': return '😐';
      case '怀疑': return '🤨';
      case '骄傲': return '😊';
      case '焦虑': return '😖';
      case '沮丧': return '😤';
      case '失望': return '😞';
      case '沉思': return '🤔';
      case '坚定': return '😤';
      case '狡猾': return '😈';
      case '调皮': return '😜';
      case '放松': return '😌';
      case '惊讶': return '😲';
      default: return '🙂';
    }
  }
  
  /// Generate explanation for decision (for post-game analysis)
  String explainDecision(GameAction action, double probability) {
    if (action == GameAction.challenge) {
      return '根据我的计算，对方报数的概率只有${(probability * 100).toStringAsFixed(1)}%，所以我选择质疑。';
    } else {
      return '虽然有${((1 - probability) * 100).toStringAsFixed(1)}%的风险，但我决定继续加注。';
    }
  }
}
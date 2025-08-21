/// Dice game state models

import '../utils/logger_utils.dart';
class DiceRoll {
  final List<int> values;
  
  DiceRoll(this.values);
  
  /// Count occurrences of a specific value
  int countValue(int value, {bool onesAreCalled = false}) {
    int count = 0;
    for (int die in values) {
      if (value == 1) {
        // If looking for 1s, only count actual 1s
        if (die == 1) count++;
      } else {
        // For other values, 1s are wild ONLY if not called yet
        if (die == value || (!onesAreCalled && die == 1)) {
          count++;
        }
      }
    }
    return count;
  }
  
  /// Check if bid is valid
  bool canMakeBid(Bid bid) {
    return countValue(bid.value) >= bid.quantity;
  }
}

class Bid {
  final int quantity;  // Number of dice
  final int value;     // Face value (2-6)
  
  Bid({required this.quantity, required this.value});
  
  /// Check if this bid is higher than another
  /// Special rule: After someone calls 1s, switching to another number requires increasing quantity
  bool isHigherThan(Bid other, {bool onesAreCalled = false}) {
    // Special rule: if previous bid was 1s and we're bidding a different number
    // we MUST increase the quantity
    if (other.value == 1 && value != 1) {
      // Switching from 1s to another number - must increase quantity
      return quantity > other.quantity;
    }
    
    // Special rule: if previous bid was NOT 1s and we're bidding 1s
    // we can bid the same quantity (because 1 is the highest value)
    if (other.value != 1 && value == 1 && quantity == other.quantity) {
      return true;
    }
    
    // Normal rules when not switching from 1s
    if (quantity == other.quantity) {
      // Same quantity: order is 2 < 3 < 4 < 5 < 6 < 1
      // 1 is the highest value
      if (value == 1 && other.value != 1) return true;  // 1 beats everything
      if (value != 1 && other.value == 1) return false; // nothing beats 1
      // For non-1 values, higher number wins
      return value > other.value;
    }
    
    // Higher quantity is always valid
    return quantity > other.quantity;
  }
  
  @override
  String toString() => '$quantity个$value';
}

enum GameAction {
  bid,       // Make a higher bid
  challenge, // Challenge opponent's bid
}

class AIDecision {
  final Bid? playerBid;  // The bid AI was responding to
  final GameAction action;  // What AI decided to do
  final Bid? aiBid;  // If AI bid, what was it
  final double probability;  // Calculated probability
  final bool wasBluffing;  // Was AI bluffing
  final String reasoning;  // Explanation of decision
  final List<Map<String, dynamic>>? eliteOptions;  // Elite AI的决策选项
  
  AIDecision({
    this.playerBid,
    required this.action,
    this.aiBid,
    required this.probability,
    required this.wasBluffing,
    required this.reasoning,
    this.eliteOptions,
  });
}

class BidBehavior {
  final bool isBluffing;  // 是否虚张
  final bool isAggressive; // 是否激进
  
  BidBehavior({
    this.isBluffing = false,
    this.isAggressive = false,
  });
}

class GameRound {
  final DiceRoll playerDice;
  final DiceRoll aiDice;
  final List<Bid> bidHistory;
  final List<AIDecision> aiDecisions = []; // Track AI decisions
  final List<BidBehavior> bidBehaviors = []; // Track behavior classification for each bid
  final List<double> playerBluffProbabilities = []; // 跟踪每轮玩家虚张概率
  Bid? currentBid;
  bool isPlayerTurn;
  bool isRoundOver;
  String? winner;
  bool onesAreCalled = false; // Track if 1s have been called
  
  GameRound({
    required this.playerDice,
    required this.aiDice,
    this.isPlayerTurn = true,
    this.isRoundOver = false,
  }) : bidHistory = [];
  
  /// Get total dice count for validation
  int get totalDiceCount => playerDice.values.length + aiDice.values.length;
  
  /// Analyze bid behavior for classification
  BidBehavior analyzeBidBehavior(Bid bid, bool isPlayerBid) {
    bool isBluffing = false;
    bool isAggressive = false;
    
    LoggerUtils.debug('analyzeBidBehavior: bid=${bid.quantity}个${bid.value}, isPlayerBid=$isPlayerBid');
    
    // 分析虚张（玩家和AI都分析）
    DiceRoll relevantDice = isPlayerBid ? playerDice : aiDice;
    int actualCount = relevantDice.countValue(bid.value, onesAreCalled: onesAreCalled);
    if (actualCount < bid.quantity / 2) {
      isBluffing = true;
    }
    
    // Check for aggressive (only if not first bid)
    if (bidHistory.isNotEmpty) {
      final prevBid = bidHistory.last;
      int quantityChange = bid.quantity - prevBid.quantity;
      
      LoggerUtils.debug('prevBid=${prevBid.quantity}个${prevBid.value}, quantityChange=$quantityChange');
      
      if (bid.value != prevBid.value) {
        // Changed value
        if (bid.value > prevBid.value) {
          LoggerUtils.debug('换高点数: ${prevBid.value} -> ${bid.value}');
          if (quantityChange > 0) {
            isAggressive = true; // Higher value, more quantity
            LoggerUtils.debug('激进：数量还增加');
          }
        } else if (bid.value < prevBid.value) {
          LoggerUtils.debug('换低点数: ${prevBid.value} -> ${bid.value}, 增加$quantityChange个');
          if (quantityChange >= 2) {
            isAggressive = true; // Lower value, 2+ more quantity
            LoggerUtils.debug('激进：增加≥2个');
          }
        }
      } else {
        // Same value
        if (quantityChange >= 2 && prevBid.quantity >= 2) {
          isAggressive = true; // Big increase on established base
        }
      }
    }
    
    final behavior = BidBehavior(
      isBluffing: isBluffing,
      isAggressive: isAggressive,
    );
    
    LoggerUtils.debug('结果: 虚张=$isBluffing, 激进=$isAggressive');
    
    return behavior;
  }
  
  /// Add a bid and analyze its behavior
  void addBid(Bid bid, bool isPlayerBid, {double? playerBluffProbability}) {
    // 先分析行为（在添加到历史之前）
    bidBehaviors.add(analyzeBidBehavior(bid, isPlayerBid));
    // 然后添加到历史
    bidHistory.add(bid);
    currentBid = bid;
    
    // 如果是玩家叫牌且提供了虚张概率，记录下来
    if (isPlayerBid && playerBluffProbability != null) {
      playerBluffProbabilities.add(playerBluffProbability);
    }
    
    // Check if 1s are called
    if (bid.value == 1) {
      onesAreCalled = true;
    }
  }
  
  /// Check if a bid is valid given all dice
  bool isBidTrue(Bid bid) {
    int totalCount = playerDice.countValue(bid.value, onesAreCalled: onesAreCalled) + 
                     aiDice.countValue(bid.value, onesAreCalled: onesAreCalled);
    return totalCount >= bid.quantity;
  }
  
  /// 获取玩家的平均虚张概率
  double getAveragePlayerBluffProbability() {
    if (playerBluffProbabilities.isEmpty) return 0.0;
    return playerBluffProbabilities.reduce((a, b) => a + b) / playerBluffProbabilities.length;
  }
  
  /// 获取最近的玩家虚张概率
  double? getLatestPlayerBluffProbability() {
    if (playerBluffProbabilities.isEmpty) return null;
    return playerBluffProbabilities.last;
  }
}

// PlayerProfile moved to player_profile.dart
/// 策略执行器基类 - 定义策略执行接口
/// 
/// 所有具体策略都需要实现这个接口
library;

import 'dart:math' as math;
import '../../../models/game_state.dart';
import '../../../models/ai_personality.dart';
import '../../probability_calculator.dart';
import '../models/ai_models.dart';

/// 策略执行器抽象基类
abstract class StrategyExecutor {
  final AIPersonality personality;
  final ProbabilityCalculator probabilityCalculator = ProbabilityCalculator();
  final math.Random random = math.Random();
  
  StrategyExecutor(this.personality);
  
  /// 执行策略
  Map<String, dynamic> execute(
    GameRound round,
    Situation situation,
    OpponentState opponentState,
  );
  
  /// 通用方法：计算安全叫牌
  Bid? calculateSafeBid(GameRound round, Situation situation) {
    // 获取我们的骰子统计
    Map<int, int> ourCounts = {};
    for (int i = 1; i <= 6; i++) {
      ourCounts[i] = round.aiDice.countValue(i, onesAreCalled: round.onesAreCalled);
    }
    
    // 找出我们数量最多的点数
    int bestValue = situation.ourBestValue;
    int bestCount = situation.ourBestCount;
    
    // 基础叫牌数量
    int baseQuantity = bestCount + 1;
    
    // 如果是开局
    if (round.currentBid == null) {
      return Bid(quantity: math.min(3, baseQuantity), value: bestValue);
    }
    
    // 确保合法的叫牌
    Bid currentBid = round.currentBid!;
    
    // 尝试叫我们最强的点数
    if (bestValue > currentBid.value) {
      return Bid(quantity: currentBid.quantity, value: bestValue);
    } else if (bestValue == currentBid.value) {
      return Bid(quantity: currentBid.quantity + 1, value: bestValue);
    } else {
      // 我们的最强点数小于当前，必须增加数量
      int minQuantity = currentBid.quantity + 1;
      
      // 检查是否合理
      if (minQuantity > 7) {
        return null; // 太高了，应该质疑
      }
      
      return Bid(quantity: minQuantity, value: bestValue);
    }
  }
  
  /// 通用方法：计算激进叫牌
  Bid? calculateAggressiveBid(GameRound round, Situation situation) {
    if (round.currentBid == null) {
      // 开局激进
      return Bid(quantity: 3, value: random.nextInt(6) + 1);
    }
    
    Bid currentBid = round.currentBid!;
    
    // 激进策略：大幅增加数量
    int increase = personality.riskAppetite > 0.5 ? 2 : 1;
    int newQuantity = currentBid.quantity + increase;
    
    // 限制最大数量
    if (newQuantity > 8) {
      return null; // 太高了，应该质疑
    }
    
    // 随机选择是否换点数
    if (random.nextDouble() < 0.3) {
      int newValue = random.nextInt(6) + 1;
      if (newValue != currentBid.value) {
        return Bid(quantity: currentBid.quantity + 1, value: newValue);
      }
    }
    
    return Bid(quantity: newQuantity, value: currentBid.value);
  }
  
  /// 通用方法：确保叫牌合法
  Bid ensureLegalBid(Bid bid, GameRound round) {
    if (round.currentBid == null) return bid;
    
    Bid currentBid = round.currentBid!;
    
    // 如果点数更大，数量可以相同
    if (bid.value > currentBid.value && bid.quantity >= currentBid.quantity) {
      return bid;
    }
    
    // 如果点数相同，数量必须更大
    if (bid.value == currentBid.value && bid.quantity > currentBid.quantity) {
      return bid;
    }
    
    // 如果点数更小，数量必须更大
    if (bid.value < currentBid.value) {
      bid = Bid(quantity: math.max(bid.quantity, currentBid.quantity + 1), value: bid.value);
    }
    
    // 最终检查
    if (!isValidBid(bid, currentBid)) {
      // 强制修正为合法叫牌
      return Bid(quantity: currentBid.quantity + 1, value: currentBid.value);
    }
    
    return bid;
  }
  
  /// 检查叫牌是否合法
  bool isValidBid(Bid newBid, Bid currentBid) {
    // 点数更大，数量相同或更多
    if (newBid.value > currentBid.value) {
      return newBid.quantity >= currentBid.quantity;
    }
    // 点数相同，数量必须更多
    if (newBid.value == currentBid.value) {
      return newBid.quantity > currentBid.quantity;
    }
    // 点数更小，数量必须更多
    return newBid.quantity > currentBid.quantity;
  }
  
  /// 生成决策结果
  Map<String, dynamic> createDecision({
    required String type,
    Bid? bid,
    required double confidence,
    required String strategy,
    required String reasoning,
    Map<String, dynamic>? extra,
  }) {
    var decision = {
      'type': type,
      'confidence': confidence,
      'strategy': strategy,
      'reasoning': reasoning,
    };
    
    if (bid != null) {
      decision['bid'] = bid;
    }
    
    if (extra != null) {
      extra.forEach((key, value) {
        decision[key] = value;
      });
    }
    
    return decision;
  }
}
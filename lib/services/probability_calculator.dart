import 'dart:math' as math;
import '../models/game_state.dart';

/// 统一的概率计算服务
/// 提供所有游戏相关的概率计算功能
class ProbabilityCalculator {
  /// 单例模式
  static final ProbabilityCalculator _instance = ProbabilityCalculator._internal();
  factory ProbabilityCalculator() => _instance;
  ProbabilityCalculator._internal();

  /// 计算叫牌成功的概率
  /// [bid] - 要叫的牌
  /// [ourDice] - 我们的骰子
  /// [onesAreCalled] - 1是否已经被叫过（失去万能属性）
  /// 返回：叫牌成功的概率 [0.0, 1.0]
  double calculateBidSuccessProbability({
    required Bid bid,
    required DiceRoll ourDice,
    required bool onesAreCalled,
  }) {
    // 计算我们有多少个目标值
    int ourCount = ourDice.countValue(bid.value, onesAreCalled: onesAreCalled);
    
    // 计算对手需要贡献多少个
    int opponentNeeds = bid.quantity - ourCount;
    
    // 如果我们已经有足够的骰子，100%成功
    if (opponentNeeds <= 0) {
      return 1.0;
    }
    
    // 如果对手需要超过5个（不可能），0%成功
    if (opponentNeeds > 5) {
      return 0.0;
    }
    
    // 计算对手至少有opponentNeeds个目标值的概率
    return _calculateOpponentHasProbability(
      targetCount: opponentNeeds,
      targetValue: bid.value,
      onesAreCalled: onesAreCalled,
    );
  }

  /// 计算质疑成功的概率
  /// [currentBid] - 当前的叫牌
  /// [ourDice] - 我们的骰子
  /// [onesAreCalled] - 1是否已经被叫过
  /// 返回：质疑成功的概率 [0.0, 1.0]
  double calculateChallengeSuccessProbability({
    required Bid currentBid,
    required DiceRoll ourDice,
    required bool onesAreCalled,
  }) {
    // 计算我们有多少个目标值
    int ourCount = ourDice.countValue(currentBid.value, onesAreCalled: onesAreCalled);
    
    // 计算对手需要贡献多少个
    int opponentNeeds = currentBid.quantity - ourCount;
    
    // 如果我们已经有足够，对手肯定成功，质疑失败
    if (opponentNeeds <= 0) {
      return 0.0;
    }
    
    // 如果对手需要超过5个，对手不可能成功，质疑必成功
    if (opponentNeeds > 5) {
      return 1.0;
    }
    
    // 质疑成功 = 1 - 对手成功概率
    return 1.0 - _calculateOpponentHasProbability(
      targetCount: opponentNeeds,
      targetValue: currentBid.value,
      onesAreCalled: onesAreCalled,
    );
  }

  /// 计算对手拥有特定数量骰子的概率（内部方法）
  /// [targetCount] - 需要的目标值数量
  /// [targetValue] - 目标值（1-6）
  /// [onesAreCalled] - 1是否已经被叫过
  double _calculateOpponentHasProbability({
    required int targetCount,
    required int targetValue,
    required bool onesAreCalled,
  }) {
    // 每个骰子是目标值的概率
    double p;
    
    if (onesAreCalled || targetValue == 1) {
      // 如果1已经被叫过，或者目标值就是1，那么只有1/6的概率
      p = 1.0 / 6.0;
    } else {
      // 如果1还是万能的，那么每个骰子有2/6的概率（目标值或1）
      p = 2.0 / 6.0;
    }
    
    // 使用二项分布计算：P(X >= targetCount)，其中X ~ B(5, p)
    return _binomialProbabilityAtLeast(5, targetCount, p);
  }

  /// 计算二项分布的累积概率：P(X >= k)，其中X ~ B(n, p)
  /// [n] - 试验次数
  /// [k] - 至少成功次数
  /// [p] - 单次成功概率
  double _binomialProbabilityAtLeast(int n, int k, double p) {
    if (k <= 0) return 1.0;
    if (k > n) return 0.0;
    
    // 对于常见情况，使用预计算的精确值
    if (n == 5 && p == 1.0 / 3.0) {
      return _precomputedBinomial5OneThird(k);
    }
    
    if (n == 5 && p == 1.0 / 6.0) {
      return _precomputedBinomial5OneSixth(k);
    }
    
    // 否则，使用通用计算
    double probability = 0.0;
    for (int i = k; i <= n; i++) {
      probability += _binomialProbability(n, i, p);
    }
    return probability;
  }

  /// 预计算的二项分布值：n=5, p=1/3
  /// 这是1不被叫时的情况
  double _precomputedBinomial5OneThird(int k) {
    switch (k) {
      case 1:
        // P(X >= 1) = 1 - P(X = 0) = 1 - (2/3)^5
        return 0.8683; // 实际值：0.86831...
      case 2:
        // P(X >= 2) = 1 - P(X = 0) - P(X = 1)
        return 0.5391; // 实际值：0.53909...
      case 3:
        // P(X >= 3)
        return 0.2101; // 实际值：0.21004...
      case 4:
        // P(X >= 4)
        return 0.0453; // 实际值：0.04527...
      case 5:
        // P(X = 5) = (1/3)^5
        return 0.0041; // 实际值：0.00412...
      default:
        return 0.0;
    }
  }

  /// 预计算的二项分布值：n=5, p=1/6
  /// 这是1被叫后的情况
  double _precomputedBinomial5OneSixth(int k) {
    switch (k) {
      case 1:
        // P(X >= 1) = 1 - P(X = 0) = 1 - (5/6)^5
        return 0.5981; // 实际值：0.59812...
      case 2:
        // P(X >= 2)
        return 0.1962; // 实际值：0.19618...
      case 3:
        // P(X >= 3)
        return 0.0355; // 实际值：0.03549...
      case 4:
        // P(X >= 4)
        return 0.0032; // 实际值：0.00322...
      case 5:
        // P(X = 5) = (1/6)^5
        return 0.0001; // 实际值：0.00013...
      default:
        return 0.0;
    }
  }

  /// 计算单个二项分布概率：P(X = k)，其中X ~ B(n, p)
  double _binomialProbability(int n, int k, double p) {
    if (k < 0 || k > n) return 0.0;
    
    // 计算组合数 C(n, k)
    double combination = _combination(n, k);
    
    // 计算概率：C(n, k) * p^k * (1-p)^(n-k)
    return combination * math.pow(p, k) * math.pow(1 - p, n - k);
  }

  /// 计算组合数 C(n, k)
  double _combination(int n, int k) {
    if (k > n || k < 0) return 0.0;
    if (k == 0 || k == n) return 1.0;
    
    // 优化：使用较小的k值
    if (k > n - k) {
      k = n - k;
    }
    
    double result = 1.0;
    for (int i = 0; i < k; i++) {
      result *= (n - i) / (i + 1);
    }
    return result;
  }

  /// 获取概率的文字描述
  String getProbabilityDescription(double probability) {
    if (probability >= 0.95) return '几乎必然';
    if (probability >= 0.85) return '极高概率';
    if (probability >= 0.70) return '高概率';
    if (probability >= 0.50) return '中等概率';
    if (probability >= 0.30) return '低概率';
    if (probability >= 0.15) return '极低概率';
    if (probability >= 0.05) return '几乎不可能';
    return '不可能';
  }

  /// 获取策略建议
  String getStrategyAdvice(double probability) {
    if (probability >= 0.80) return '稳健';
    if (probability >= 0.60) return '合理';
    if (probability >= 0.40) return '冒险';
    if (probability >= 0.20) return '诈唬';
    return '纯诈唬';
  }
}
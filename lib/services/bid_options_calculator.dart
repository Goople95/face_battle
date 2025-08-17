import 'dart:math' as math;
import '../models/game_state.dart';

/// 精简版叫牌选项计算器
class BidOptionsCalculator {
  
  /// 计算所有可能的决策选项（包括质疑和叫牌）
  static List<Map<String, dynamic>> calculateAllOptions(
    GameRound round,
    Map<int, int> ourCounts,
  ) {
    List<Map<String, dynamic>> allOptions = [];
    
    // 1. 计算质疑选项
    if (round.currentBid != null) {
      double challengeSuccessRate = _calculateChallengeSuccessRate(
        round.currentBid!,
        ourCounts,
        round.onesAreCalled,
      );
      
      allOptions.add({
        'type': 'challenge',
        'successRate': challengeSuccessRate,
        'riskLevel': challengeSuccessRate >= 0.6 ? 'safe' : 
                     challengeSuccessRate >= 0.4 ? 'normal' : 'risky',
        'reasoning': '质疑对手',
      });
    }
    
    // 2. 添加叫牌选项
    _addBidOptions(allOptions, round, ourCounts);
    
    // 3. 添加少量战术虚张（简化版）
    _addSimpleTacticalBluffs(allOptions, round, ourCounts);
    
    // 4. 按成功率排序
    allOptions.sort((a, b) => b['successRate'].compareTo(a['successRate']));
    
    // 5. 返回前10个最佳选项
    return allOptions.take(10).toList();
  }
  
  /// 计算质疑成功率
  static double _calculateChallengeSuccessRate(
    Bid currentBid,
    Map<int, int> ourCounts,
    bool onesAreCalled,
  ) {
    int ourCount = ourCounts[currentBid.value] ?? 0;
    int opponentNeeds = math.max(0, currentBid.quantity - ourCount);
    
    if (opponentNeeds == 0) return 0.0; // 我们已经有足够
    if (opponentNeeds > 5) return 1.0;   // 对手不可能有这么多
    
    // 单个骰子是目标值的概率
    double singleDieProb = (currentBid.value == 1 || onesAreCalled) 
        ? 1.0 / 6.0  // 没有万能
        : 2.0 / 6.0; // 有万能1
    
    // 对手至少有opponentNeeds个的概率
    double opponentSuccessProb = _binomialAtLeast(5, opponentNeeds, singleDieProb);
    
    return 1.0 - opponentSuccessProb;
  }
  
  /// 添加正常叫牌选项（简化版）
  static void _addBidOptions(
    List<Map<String, dynamic>> allOptions,
    GameRound round,
    Map<int, int> ourCounts,
  ) {
    if (round.currentBid != null) {
      Bid currentBid = round.currentBid!;
      
      // 策略1：同数量，更高点数
      if (currentBid.value < 6) {
        for (int nextValue = currentBid.value + 1; nextValue <= 6; nextValue++) {
          int myCount = ourCounts[nextValue] ?? 0;
          double successRate = _calculateBidSuccessRate(
            currentBid.quantity, nextValue, myCount, round.onesAreCalled
          );
          
          if (successRate >= 0.1) { // 过滤太低成功率
            allOptions.add(_createBidOption(
              Bid(quantity: currentBid.quantity, value: nextValue),
              myCount, 
              successRate,
              '换高点'
            ));
          }
        }
      }
      
      // 策略2：增加1-2个数量
      for (int addQty = 1; addQty <= 2; addQty++) {
        int nextQty = currentBid.quantity + addQty;
        if (nextQty > 10) break;
        
        // 只考虑我们有的点数
        for (var entry in ourCounts.entries) {
          if (entry.value > 0) {
            Bid newBid = Bid(quantity: nextQty, value: entry.key);
            if (newBid.isHigherThan(currentBid, onesAreCalled: round.onesAreCalled)) {
              double successRate = _calculateBidSuccessRate(
                nextQty, entry.key, entry.value, round.onesAreCalled
              );
              
              if (successRate >= 0.15) { // 过滤太低成功率
                allOptions.add(_createBidOption(
                  newBid,
                  entry.value,
                  successRate,
                  addQty == 1 ? '加注' : '大幅加注'
                ));
              }
            }
          }
        }
      }
    } else {
      // 首轮叫牌（简化：只生成合理选项）
      for (int qty = 2; qty <= 3; qty++) {
        for (var entry in ourCounts.entries) {
          if (entry.value >= qty - 1) { // 至少有qty-1个
            double successRate = _calculateBidSuccessRate(
              qty, entry.key, entry.value, false
            );
            
            if (successRate >= 0.3) {
              allOptions.add(_createBidOption(
                Bid(quantity: qty, value: entry.key),
                entry.value,
                successRate,
                '开局'
              ));
            }
          }
        }
      }
    }
  }
  
  /// 添加简化的战术虚张
  static void _addSimpleTacticalBluffs(
    List<Map<String, dynamic>> allOptions,
    GameRound round,
    Map<int, int> ourCounts,
  ) {
    if (round.currentBid == null) return;
    
    Bid currentBid = round.currentBid!;
    
    // 找到我们最少的点数进行虚张
    int minCount = 6;
    int bluffValue = 1;
    for (var entry in ourCounts.entries) {
      if (entry.value < minCount) {
        minCount = entry.value;
        bluffValue = entry.key;
      }
    }
    
    // 只在我们很少这个数时虚张
    if (minCount <= 1) {
      int bluffQty = currentBid.quantity + 1;
      if (bluffQty <= 8) {
        Bid bluffBid = Bid(quantity: bluffQty, value: bluffValue);
        if (bluffBid.isHigherThan(currentBid, onesAreCalled: round.onesAreCalled)) {
          double successRate = _calculateBidSuccessRate(
            bluffQty, bluffValue, minCount, round.onesAreCalled
          );
          
          if (successRate >= 0.1) {
            allOptions.add({
              'type': 'bid',
              'bid': bluffBid,
              'quantity': bluffQty,
              'value': bluffValue,
              'successRate': successRate,
              'riskLevel': 'extreme',
              'strategy': 'tactical_bluff',
              'reasoning': '战术虚张',
            });
          }
        }
      }
    }
    
    // 后期赌博策略
    if (round.bidHistory.length >= 4 && currentBid.quantity <= 7) {
      // 找一个我们有2个以上的数
      for (var entry in ourCounts.entries) {
        if (entry.value >= 2) {
          int gambleQty = math.min(currentBid.quantity + 3, 10);
          Bid gambleBid = Bid(quantity: gambleQty, value: entry.key);
          
          if (gambleBid.isHigherThan(currentBid, onesAreCalled: round.onesAreCalled)) {
            double successRate = _calculateBidSuccessRate(
              gambleQty, entry.key, entry.value, round.onesAreCalled
            );
            
            allOptions.add({
              'type': 'bid',
              'bid': gambleBid,
              'quantity': gambleQty,
              'value': entry.key,
              'successRate': successRate,
              'riskLevel': 'extreme',
              'strategy': 'endgame_gamble',
              'reasoning': '终极赌博',
            });
            break; // 只添加一个
          }
        }
      }
    }
  }
  
  /// 创建叫牌选项
  static Map<String, dynamic> _createBidOption(
    Bid bid,
    int myCount,
    double successRate,
    String reasoning,
  ) {
    String riskLevel = successRate >= 0.7 ? 'safe' : 
                       successRate >= 0.4 ? 'normal' : 
                       successRate >= 0.2 ? 'risky' : 'extreme';
    
    String strategy = myCount >= bid.quantity ? 'honest' : 
                     myCount >= bid.quantity - 1 ? 'slight_bluff' : 'bluff';
    
    return {
      'type': 'bid',
      'bid': bid,
      'quantity': bid.quantity,
      'value': bid.value,
      'successRate': successRate,
      'riskLevel': riskLevel,
      'strategy': strategy,
      'reasoning': reasoning,
    };
  }
  
  /// 计算叫牌成功率
  static double _calculateBidSuccessRate(
    int quantity,
    int value,
    int myCount,
    bool onesAreCalled,
  ) {
    int opponentNeeds = math.max(0, quantity - myCount);
    if (opponentNeeds == 0) return 1.0;
    if (opponentNeeds > 5) return 0.0;
    
    double singleDieProb = (value == 1 || onesAreCalled) 
        ? 1.0 / 6.0 
        : 2.0 / 6.0;
    
    return _binomialAtLeast(5, opponentNeeds, singleDieProb);
  }
  
  /// 计算二项分布"至少k个"的概率（简化版）
  static double _binomialAtLeast(int n, int k, double p) {
    if (k > n) return 0.0;
    if (k <= 0) return 1.0;
    
    double probability = 0.0;
    for (int i = k; i <= n; i++) {
      // 计算C(n,i)
      double binomCoeff = 1.0;
      for (int j = 0; j < i; j++) {
        binomCoeff *= (n - j) / (j + 1);
      }
      // 累加概率
      probability += binomCoeff * math.pow(p, i) * math.pow(1 - p, n - i);
    }
    
    return probability.clamp(0.0, 1.0);
  }
}
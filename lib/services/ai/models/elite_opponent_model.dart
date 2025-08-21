/// Elite AI的对手建模系统
/// 
/// 使用贝叶斯推理和行为模式分析来追踪对手
library;

import 'dart:math' as math;
import '../../../models/game_state.dart';

class EliteOpponentModel {
  // 对手统计
  int totalBids = 0;
  int bluffCount = 0;
  int challengeCount = 0;
  int aggressiveBids = 0;
  
  // 贝叶斯先验
  Map<int, double> priorDistribution = {};
  
  // 行为模式
  List<String> behaviorHistory = [];
  double adaptationLevel = 0.0;
  
  // 计算属性
  double get estimatedBluffRate => 
    totalBids > 0 ? bluffCount / totalBids : 0.3;
  
  bool get isAggressive =>
    totalBids > 3 && aggressiveBids / totalBids > 0.5;
    
  bool get isConservative =>
    totalBids > 3 && aggressiveBids / totalBids < 0.3;
  
  EliteOpponentModel() {
    // 初始化均匀先验
    for (int i = 1; i <= 6; i++) {
      priorDistribution[i] = 1.0 / 6.0;
    }
  }
  
  /// 从游戏历史更新模型
  void updateFromHistory(GameRound round) {
    if (round.bidHistory.isEmpty) return;
    
    // 分析最新的叫牌
    var lastBid = round.bidHistory.last;
    // 简化处理：假设奇数轮是玩家，偶数轮是AI
    bool isPlayerBid = round.bidHistory.length % 2 == 1;
    
    if (isPlayerBid) {
      totalBids++;
      
      // 检测激进叫牌
      if (round.bidHistory.length > 1) {
        var prevBid = round.bidHistory[round.bidHistory.length - 2];
        if (lastBid.quantity - prevBid.quantity >= 2) {
          aggressiveBids++;
          behaviorHistory.add('aggressive');
        } else {
          behaviorHistory.add('normal');
        }
      }
      
      // 更新贝叶斯分布
      _updateBayesianBelief(lastBid, round);
    }
    
    // 检测对手是否在适应
    _detectAdaptation();
  }
  
  /// 获取后验分布
  Map<int, double> getPosteriorDistribution(Bid? currentBid, bool onesAreCalled) {
    // 如果没有足够数据，返回先验
    if (totalBids < 3) return priorDistribution;
    
    // 根据历史调整分布
    Map<int, double> posterior = Map.from(priorDistribution);
    
    // 如果对手经常虚张，降低其声称点数的概率
    if (currentBid != null && estimatedBluffRate > 0.4) {
      posterior[currentBid.value] = (posterior[currentBid.value] ?? 0.167) * 0.7;
      
      // 重新归一化
      double sum = posterior.values.fold(0.0, (a, b) => a + b);
      posterior.forEach((key, value) {
        posterior[key] = value / sum;
      });
    }
    
    return posterior;
  }
  
  /// 更新贝叶斯信念
  void _updateBayesianBelief(Bid bid, GameRound round) {
    // 简化的贝叶斯更新
    double learningRate = 0.1;
    
    // 如果叫牌数量很大，可能是虚张
    if (bid.quantity >= 6) {
      priorDistribution[bid.value] = 
        (priorDistribution[bid.value] ?? 0.167) * (1.0 - learningRate);
    }
    
    // 重新归一化
    double sum = priorDistribution.values.fold(0.0, (a, b) => a + b);
    if (sum > 0) {
      priorDistribution.forEach((key, value) {
        priorDistribution[key] = value / sum;
      });
    }
  }
  
  /// 检测对手适应
  void _detectAdaptation() {
    if (behaviorHistory.length < 6) return;
    
    // 检查最近的行为是否与早期不同
    int recentStart = math.max(0, behaviorHistory.length - 3);
    var recent = behaviorHistory.sublist(recentStart);
    var early = behaviorHistory.take(3).toList();
    
    int changes = 0;
    for (int i = 0; i < 3; i++) {
      if (i < recent.length && i < early.length && recent[i] != early[i]) {
        changes++;
      }
    }
    
    adaptationLevel = changes / 3.0;
  }
  
  /// 检测是否已适应我们
  bool hasAdaptedToUs() {
    return adaptationLevel > 0.6 && behaviorHistory.length > 5;
  }
  
  /// 重置模型（新游戏）
  void reset() {
    totalBids = 0;
    bluffCount = 0;
    challengeCount = 0;
    aggressiveBids = 0;
    behaviorHistory.clear();
    adaptationLevel = 0.0;
    
    // 重置为均匀先验
    for (int i = 1; i <= 6; i++) {
      priorDistribution[i] = 1.0 / 6.0;
    }
  }
}
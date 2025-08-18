/// 对手心理模型组件 - 分析对手行为模式
/// 
/// 负责理解和预测对手行为，包括：
/// - 追踪对手的叫牌模式
/// - 估计对手的虚张概率
/// - 预测对手的质疑倾向
/// - 识别对手的情绪状态

import 'dart:math' as math;
import '../../../models/game_state.dart';
import '../models/ai_models.dart';
import 'game_memory.dart';

class OpponentMind {
  final List<PlayerAction> recentActions = [];
  final Map<String, int> patterns = {};
  
  /// 读取对手当前状态
  OpponentState readOpponent(GameRound round, GameMemory memory) {
    var state = OpponentState();
    
    // 分析最近的叫牌
    if (round.currentBid != null && round.bidHistory.isNotEmpty) {
      var lastBid = round.bidHistory.last;
      
      // 激进程度分析
      if (round.bidHistory.length > 1) {
        var prevBid = round.bidHistory[round.bidHistory.length - 2];
        int increase = lastBid.quantity - prevBid.quantity;
        
        state.isAggressive = increase >= 2;
        state.isConservative = increase == 0 && lastBid.value == prevBid.value;
      }
      
      // 虚张概率估计
      state.bluffProbability = _estimateBluffProb(round, memory);
      
      // 质疑倾向估计
      state.challengeProbability = _estimateChallengeProb(round, memory);
      
      // 情绪状态分析
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
  
  /// 学习对手行为
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
    
    // 更新模式统计
    _updatePatterns(round);
  }
  
  /// 估计对手虚张概率
  double _estimateBluffProb(GameRound round, GameMemory memory) {
    // 基于历史估计虚张概率
    if (memory.totalRounds == 0) return 0.3;
    
    double historicalRate = memory.opponentBluffs / math.max(1, memory.totalRounds);
    
    // 根据当前叫牌调整
    double adjustment = 0;
    if (round.currentBid != null) {
      // 叫牌越高，虚张可能性越大
      adjustment = round.currentBid!.quantity * 0.03;
    }
    
    return math.min(0.8, historicalRate + adjustment);
  }
  
  /// 估计对手质疑概率
  double _estimateChallengeProb(GameRound round, GameMemory memory) {
    double baseProb = 0.2;
    
    // 叫牌越高，质疑概率越大
    if (round.currentBid != null) {
      baseProb += round.currentBid!.quantity * 0.05;
    }
    
    // 回合越多，质疑概率越大
    baseProb += round.bidHistory.length * 0.03;
    
    // 根据历史质疑频率调整
    if (memory.totalRounds > 0) {
      double historicalRate = memory.opponentChallenges / memory.totalRounds;
      baseProb = (baseProb + historicalRate) / 2;
    }
    
    return math.min(0.8, baseProb);
  }
  
  /// 更新行为模式
  void _updatePatterns(GameRound round) {
    if (round.bidHistory.length < 2) return;
    
    // 记录叫牌模式
    var lastBid = round.bidHistory.last;
    var prevBid = round.bidHistory[round.bidHistory.length - 2];
    
    String pattern = '${prevBid.value}->${lastBid.value}';
    patterns[pattern] = (patterns[pattern] ?? 0) + 1;
  }
  
  /// 获取对手偏好的点数
  int? getPreferredValue() {
    if (recentActions.isEmpty) return null;
    
    Map<int, int> valueCounts = {};
    for (var action in recentActions) {
      valueCounts[action.bid.value] = (valueCounts[action.bid.value] ?? 0) + 1;
    }
    
    var sorted = valueCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.isNotEmpty ? sorted.first.key : null;
  }
}
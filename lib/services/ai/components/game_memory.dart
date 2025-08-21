/// 游戏记忆组件 - 记录历史信息用于学习
/// 
/// 负责记录和分析游戏历史，包括：
/// - 回合结果记录
/// - 胜负统计
/// - 对手行为统计
/// - 连胜/连败追踪
library;

import '../../../models/game_state.dart';
import '../models/ai_models.dart';

class GameMemory {
  int totalRounds = 0;
  int wins = 0;
  int losses = 0;
  int opponentBluffs = 0;
  int opponentChallenges = 0;
  int ourBluffs = 0;
  int ourSuccessfulBluffs = 0;
  
  final List<RoundResult> history = [];
  
  /// 记录回合结果
  void recordRound(GameRound round, Map<String, dynamic> decision, Strategy strategy) {
    totalRounds++;
    
    history.add(RoundResult(
      round: round,
      decision: decision,
      strategy: strategy,
      success: false, // 需要在回合结束后更新
    ));
    
    // 只保留最近50轮
    if (history.length > 50) {
      history.removeAt(0);
    }
    
    // 更新统计
    if (decision['type'] == 'challenge') {
      opponentChallenges++;
    }
  }
  
  /// 更新回合结果
  void updateLastRoundResult(bool success, {bool wasBluff = false}) {
    if (history.isNotEmpty) {
      history.last.success = success;
      
      if (success) {
        wins++;
      } else {
        losses++;
      }
      
      if (wasBluff) {
        if (success) {
          ourSuccessfulBluffs++;
        }
        ourBluffs++;
      }
    }
  }
  
  /// 获取连胜/连败数
  int getWinStreak() {
    int streak = 0;
    for (int i = history.length - 1; i >= 0; i--) {
      if (history[i].success) {
        if (streak >= 0) {
          streak++;
        } else {
          break;
        }
      } else {
        if (streak <= 0) {
          streak--;
        } else {
          break;
        }
      }
    }
    return streak;
  }
  
  /// 获取最近N轮的胜率
  double getRecentWinRate(int rounds) {
    if (history.isEmpty) return 0.5;
    
    int count = 0;
    int wins = 0;
    
    for (int i = history.length - 1; i >= 0 && count < rounds; i--) {
      count++;
      if (history[i].success) wins++;
    }
    
    return count > 0 ? wins / count : 0.5;
  }
  
  /// 获取策略成功率
  Map<StrategyType, double> getStrategySuccessRates() {
    Map<StrategyType, int> counts = {};
    Map<StrategyType, int> successes = {};
    
    for (var result in history) {
      counts[result.strategy.type] = (counts[result.strategy.type] ?? 0) + 1;
      if (result.success) {
        successes[result.strategy.type] = (successes[result.strategy.type] ?? 0) + 1;
      }
    }
    
    Map<StrategyType, double> rates = {};
    for (var type in StrategyType.values) {
      int count = counts[type] ?? 0;
      int success = successes[type] ?? 0;
      rates[type] = count > 0 ? success / count : 0.5;
    }
    
    return rates;
  }
  
  /// 清空记忆（新游戏开始）
  void reset() {
    totalRounds = 0;
    wins = 0;
    losses = 0;
    opponentBluffs = 0;
    opponentChallenges = 0;
    ourBluffs = 0;
    ourSuccessfulBluffs = 0;
    history.clear();
  }
}
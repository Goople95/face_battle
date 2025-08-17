import 'package:cloud_firestore/cloud_firestore.dart';

/// 游戏进度模型 - 存储在Firestore中
class GameProgress {
  final String userId;
  final int totalGames;
  final int totalWins;
  final int totalLosses;
  final double winRate;
  final int totalChallenges;
  final int successfulChallenges;
  final int totalBids;
  final int successfulBids;
  final int highestWinStreak;
  final int currentWinStreak;
  final String? favoriteOpponent; // 最常对战的AI角色
  final DateTime? lastPlayedAt;
  final int totalPlayTimeMinutes;
  final List<String> achievements;
  
  // AI对战记录
  final Map<String, int> vsAIWins; // 对每个AI的胜利次数
  final Map<String, int> vsAILosses; // 对每个AI的失败次数

  GameProgress({
    required this.userId,
    this.totalGames = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.winRate = 0.0,
    this.totalChallenges = 0,
    this.successfulChallenges = 0,
    this.totalBids = 0,
    this.successfulBids = 0,
    this.highestWinStreak = 0,
    this.currentWinStreak = 0,
    this.favoriteOpponent,
    this.lastPlayedAt,
    this.totalPlayTimeMinutes = 0,
    List<String>? achievements,
    Map<String, int>? vsAIWins,
    Map<String, int>? vsAILosses,
  }) : achievements = achievements ?? [],
       vsAIWins = vsAIWins ?? {},
       vsAILosses = vsAILosses ?? {};

  /// 从Firestore文档创建
  factory GameProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameProgress(
      userId: doc.id,
      totalGames: data['totalGames'] ?? 0,
      totalWins: data['totalWins'] ?? 0,
      totalLosses: data['totalLosses'] ?? 0,
      winRate: (data['winRate'] ?? 0).toDouble(),
      totalChallenges: data['totalChallenges'] ?? 0,
      successfulChallenges: data['successfulChallenges'] ?? 0,
      totalBids: data['totalBids'] ?? 0,
      successfulBids: data['successfulBids'] ?? 0,
      highestWinStreak: data['highestWinStreak'] ?? 0,
      currentWinStreak: data['currentWinStreak'] ?? 0,
      favoriteOpponent: data['favoriteOpponent'],
      lastPlayedAt: data['lastPlayedAt'] != null 
          ? (data['lastPlayedAt'] as Timestamp).toDate()
          : null,
      totalPlayTimeMinutes: data['totalPlayTimeMinutes'] ?? 0,
      achievements: List<String>.from(data['achievements'] ?? []),
      vsAIWins: Map<String, int>.from(data['vsAIWins'] ?? {}),
      vsAILosses: Map<String, int>.from(data['vsAILosses'] ?? {}),
    );
  }

  /// 转换为Firestore文档
  Map<String, dynamic> toFirestore() {
    return {
      'totalGames': totalGames,
      'totalWins': totalWins,
      'totalLosses': totalLosses,
      'winRate': winRate,
      'totalChallenges': totalChallenges,
      'successfulChallenges': successfulChallenges,
      'totalBids': totalBids,
      'successfulBids': successfulBids,
      'highestWinStreak': highestWinStreak,
      'currentWinStreak': currentWinStreak,
      'favoriteOpponent': favoriteOpponent,
      'lastPlayedAt': lastPlayedAt != null 
          ? Timestamp.fromDate(lastPlayedAt!)
          : null,
      'totalPlayTimeMinutes': totalPlayTimeMinutes,
      'achievements': achievements,
      'vsAIWins': vsAIWins,
      'vsAILosses': vsAILosses,
    };
  }

  /// 更新游戏结果
  GameProgress updateAfterGame({
    required bool won,
    required String opponent,
    required int gameDurationMinutes,
    bool? madeChallenge,
    bool? challengeSuccessful,
    int? bidsInGame,
    int? successfulBidsInGame,
  }) {
    final newTotalGames = totalGames + 1;
    final newTotalWins = totalWins + (won ? 1 : 0);
    final newTotalLosses = totalLosses + (won ? 0 : 1);
    final newWinRate = newTotalGames > 0 ? newTotalWins / newTotalGames : 0.0;
    
    // 更新连胜
    final newCurrentStreak = won ? currentWinStreak + 1 : 0;
    final newHighestStreak = newCurrentStreak > highestWinStreak 
        ? newCurrentStreak 
        : highestWinStreak;
    
    // 更新AI对战记录
    final newVsAIWins = Map<String, int>.from(vsAIWins);
    final newVsAILosses = Map<String, int>.from(vsAILosses);
    if (won) {
      newVsAIWins[opponent] = (newVsAIWins[opponent] ?? 0) + 1;
    } else {
      newVsAILosses[opponent] = (newVsAILosses[opponent] ?? 0) + 1;
    }
    
    // 计算最常对战的对手
    final allOpponents = <String, int>{};
    newVsAIWins.forEach((key, value) {
      allOpponents[key] = value + (newVsAILosses[key] ?? 0);
    });
    newVsAILosses.forEach((key, value) {
      allOpponents[key] = (allOpponents[key] ?? 0) + value;
    });
    String? newFavoriteOpponent;
    if (allOpponents.isNotEmpty) {
      newFavoriteOpponent = allOpponents.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
    
    return GameProgress(
      userId: userId,
      totalGames: newTotalGames,
      totalWins: newTotalWins,
      totalLosses: newTotalLosses,
      winRate: newWinRate,
      totalChallenges: totalChallenges + (madeChallenge == true ? 1 : 0),
      successfulChallenges: successfulChallenges + (challengeSuccessful == true ? 1 : 0),
      totalBids: totalBids + (bidsInGame ?? 0),
      successfulBids: successfulBids + (successfulBidsInGame ?? 0),
      highestWinStreak: newHighestStreak,
      currentWinStreak: newCurrentStreak,
      favoriteOpponent: newFavoriteOpponent,
      lastPlayedAt: DateTime.now(),
      totalPlayTimeMinutes: totalPlayTimeMinutes + gameDurationMinutes,
      achievements: achievements,
      vsAIWins: newVsAIWins,
      vsAILosses: newVsAILosses,
    );
  }

  /// 检查并添加成就
  List<String> checkAchievements() {
    final newAchievements = <String>[];
    
    // 首胜
    if (totalWins == 1 && !achievements.contains('first_win')) {
      newAchievements.add('first_win');
    }
    
    // 10连胜
    if (currentWinStreak >= 10 && !achievements.contains('win_streak_10')) {
      newAchievements.add('win_streak_10');
    }
    
    // 100场游戏
    if (totalGames >= 100 && !achievements.contains('games_100')) {
      newAchievements.add('games_100');
    }
    
    // 高胜率
    if (totalGames >= 20 && winRate >= 0.7 && !achievements.contains('high_win_rate')) {
      newAchievements.add('high_win_rate');
    }
    
    return newAchievements;
  }
}
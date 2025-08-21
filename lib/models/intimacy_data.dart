import 'package:cloud_firestore/cloud_firestore.dart';

class IntimacyData {
  final String npcId;
  final int intimacyPoints;
  final DateTime lastInteraction;
  final int totalGames;
  final int wins;
  final int losses;
  final List<String> unlockedDialogues;
  final List<String> achievedMilestones;

  IntimacyData({
    required this.npcId,
    this.intimacyPoints = 0,
    required this.lastInteraction,
    this.totalGames = 0,
    this.wins = 0,
    this.losses = 0,
    this.unlockedDialogues = const [],
    this.achievedMilestones = const [],
  });

  int get intimacyLevel {
    if (intimacyPoints < 100) return 1;
    if (intimacyPoints < 300) return 2;
    if (intimacyPoints < 600) return 3;
    if (intimacyPoints < 1000) return 4;
    if (intimacyPoints < 1500) return 5;
    if (intimacyPoints < 2100) return 6;
    if (intimacyPoints < 2800) return 7;
    if (intimacyPoints < 3600) return 8;
    if (intimacyPoints < 4500) return 9;
    return 10;
  }

  String get levelTitle {
    switch (intimacyLevel) {
      case 1: return '初遇';
      case 2: return '相识';
      case 3: return '友谊';
      case 4: return '好友';
      case 5: return '佳友';
      case 6: return '知心';
      case 7: return '挚爱';
      case 8: return '亲密';
      case 9: return '深情';
      case 10: return '灵魂伴侣';
      default: return '初次见面';
    }
  }

  int get pointsToNextLevel {
    final thresholds = [100, 300, 600, 1000, 1500, 2100, 2800, 3600, 4500, 999999];
    if (intimacyLevel >= 10) return 0;
    return thresholds[intimacyLevel - 1] - intimacyPoints;
  }

  double get levelProgress {
    if (intimacyLevel >= 10) return 1.0;
    
    final currentThreshold = intimacyLevel == 1 ? 0 : [0, 100, 300, 600, 1000, 1500, 2100, 2800, 3600, 4500][intimacyLevel - 1];
    final nextThreshold = [100, 300, 600, 1000, 1500, 2100, 2800, 3600, 4500, 999999][intimacyLevel - 1];
    
    return (intimacyPoints - currentThreshold) / (nextThreshold - currentThreshold);
  }

  double get winRate => totalGames > 0 ? wins / totalGames : 0.0;

  IntimacyData copyWith({
    String? npcId,
    int? intimacyPoints,
    DateTime? lastInteraction,
    int? totalGames,
    int? wins,
    int? losses,
    List<String>? unlockedDialogues,
    List<String>? achievedMilestones,
  }) {
    return IntimacyData(
      npcId: npcId ?? this.npcId,
      intimacyPoints: intimacyPoints ?? this.intimacyPoints,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      totalGames: totalGames ?? this.totalGames,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      unlockedDialogues: unlockedDialogues ?? this.unlockedDialogues,
      achievedMilestones: achievedMilestones ?? this.achievedMilestones,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'npcId': npcId,
      'intimacyPoints': intimacyPoints,
      'lastInteraction': lastInteraction.toIso8601String(),
      'totalGames': totalGames,
      'wins': wins,
      'losses': losses,
      'unlockedDialogues': unlockedDialogues,
      'achievedMilestones': achievedMilestones,
    };
  }

  factory IntimacyData.fromJson(Map<String, dynamic> json) {
    return IntimacyData(
      npcId: json['npcId'] ?? '',
      intimacyPoints: json['intimacyPoints'] ?? 0,
      lastInteraction: json['lastInteraction'] != null 
          ? DateTime.parse(json['lastInteraction'])
          : DateTime.now(),
      totalGames: json['totalGames'] ?? 0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      unlockedDialogues: List<String>.from(json['unlockedDialogues'] ?? []),
      achievedMilestones: List<String>.from(json['achievedMilestones'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'npcId': npcId,
      'intimacyPoints': intimacyPoints,
      'lastInteraction': Timestamp.fromDate(lastInteraction),
      'totalGames': totalGames,
      'wins': wins,
      'losses': losses,
      'unlockedDialogues': unlockedDialogues,
      'achievedMilestones': achievedMilestones,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory IntimacyData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IntimacyData(
      npcId: data['npcId'] ?? '',
      intimacyPoints: data['intimacyPoints'] ?? 0,
      lastInteraction: (data['lastInteraction'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalGames: data['totalGames'] ?? 0,
      wins: data['wins'] ?? 0,
      losses: data['losses'] ?? 0,
      unlockedDialogues: List<String>.from(data['unlockedDialogues'] ?? []),
      achievedMilestones: List<String>.from(data['achievedMilestones'] ?? []),
    );
  }
}

class IntimacyReward {
  final int pointsRequired;
  final String type;
  final String rewardId;
  final String description;

  IntimacyReward({
    required this.pointsRequired,
    required this.type,
    required this.rewardId,
    required this.description,
  });
}

class IntimacyMilestone {
  final int level;
  final String id;
  final String title;
  final String description;
  final IntimacyReward? reward;

  IntimacyMilestone({
    required this.level,
    required this.id,
    required this.title,
    required this.description,
    this.reward,
  });
}
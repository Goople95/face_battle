import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/game_progress.dart';
import '../utils/logger_utils.dart';

/// Firestore数据库服务
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 获取用户集合引用
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// 创建或更新用户档案
  Future<void> createOrUpdateUserProfile(User user, String provider) async {
    try {
      final docRef = _usersCollection.doc(user.uid);
      
      // 检查是否已存在
      final doc = await docRef.get();
      
      if (!doc.exists) {
        // 创建新用户文档，包含profile和progress
        final now = DateTime.now();
        final userData = {
          // Profile字段
          'accountCreatedAt': Timestamp.fromDate(now),
          'lastLoginAt': Timestamp.fromDate(now),
          'loginProvider': provider.toLowerCase(),
          'username': user.email?.split('@')[0] ?? 'player',
          'displayName': user.displayName ?? 'Player',
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'language': 'zh',
          'country': null,
          'isActive': true,
          
          // Progress字段（初始值）
          'totalGames': 0,
          'totalWins': 0,
          'totalLosses': 0,
          'winRate': 0.0,
          'totalChallenges': 0,
          'successfulChallenges': 0,
          'totalBids': 0,
          'successfulBids': 0,
          'highestWinStreak': 0,
          'currentWinStreak': 0,
          'favoriteOpponent': null,
          'lastPlayedAt': null,
          'totalPlayTimeMinutes': 0,
          'achievements': [],
          'vsAIWins': {},
          'vsAILosses': {},
        };
        
        await docRef.set(userData);
        LoggerUtils.info('创建新用户档案: ${user.uid}');
      } else {
        // 仅更新最后登录时间
        await docRef.update({
          'lastLoginAt': Timestamp.fromDate(DateTime.now()),
        });
        LoggerUtils.info('更新用户登录时间: ${user.uid}');
      }
    } catch (e) {
      LoggerUtils.error('创建/更新用户档案失败: $e');
      rethrow;
    }
  }

  /// 获取用户档案
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      LoggerUtils.error('获取用户档案失败: $e');
      return null;
    }
  }

  /// 获取游戏进度
  Future<GameProgress?> getGameProgress(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      
      if (doc.exists) {
        return GameProgress.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      LoggerUtils.error('获取游戏进度失败: $e');
      return null;
    }
  }

  /// 更新游戏进度
  Future<void> updateGameProgress(GameProgress progress) async {
    try {
      // 直接更新主文档中的progress字段
      await _usersCollection
          .doc(progress.userId)
          .update(progress.toFirestore());
      LoggerUtils.info('更新游戏进度: ${progress.userId}');
    } catch (e) {
      LoggerUtils.error('更新游戏进度失败: $e');
      rethrow;
    }
  }

  /// 实时监听用户档案变化
  Stream<UserProfile?> watchUserProfile(String userId) {
    return _usersCollection
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return UserProfile.fromFirestore(snapshot);
      }
      return null;
    });
  }

  /// 实时监听游戏进度变化
  Stream<GameProgress?> watchGameProgress(String userId) {
    return _usersCollection
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return GameProgress.fromFirestore(snapshot);
      }
      return null;
    });
  }

  /// 更新用户语言偏好
  Future<void> updateUserLanguage(String userId, String language) async {
    try {
      await _usersCollection
          .doc(userId)
          .update({'language': language});
    } catch (e) {
      LoggerUtils.error('更新语言偏好失败: $e');
    }
  }

  /// 更新用户国家
  Future<void> updateUserCountry(String userId, String country) async {
    try {
      await _usersCollection
          .doc(userId)
          .update({'country': country});
    } catch (e) {
      LoggerUtils.error('更新国家失败: $e');
    }
  }

  /// 记录游戏结果
  Future<void> recordGameResult({
    required String userId,
    required bool won,
    required String opponent,
    required int gameDurationMinutes,
    bool? madeChallenge,
    bool? challengeSuccessful,
    int? bidsInGame,
    int? successfulBidsInGame,
  }) async {
    try {
      // 获取当前进度
      final progress = await getGameProgress(userId);
      if (progress == null) return;
      
      // 更新进度
      final updatedProgress = progress.updateAfterGame(
        won: won,
        opponent: opponent,
        gameDurationMinutes: gameDurationMinutes,
        madeChallenge: madeChallenge,
        challengeSuccessful: challengeSuccessful,
        bidsInGame: bidsInGame,
        successfulBidsInGame: successfulBidsInGame,
      );
      
      // 检查成就
      final newAchievements = updatedProgress.checkAchievements();
      if (newAchievements.isNotEmpty) {
        updatedProgress.achievements.addAll(newAchievements);
        LoggerUtils.info('获得新成就: $newAchievements');
      }
      
      // 保存更新
      await updateGameProgress(updatedProgress);
    } catch (e) {
      LoggerUtils.error('记录游戏结果失败: $e');
    }
  }

  /// 获取排行榜数据
  Future<List<GameProgress>> getLeaderboard({int limit = 10}) async {
    try {
      // 直接从users集合查询，按winRate排序
      final querySnapshot = await _usersCollection
          .orderBy('winRate', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => GameProgress.fromFirestore(doc))
          .toList();
    } catch (e) {
      LoggerUtils.error('获取排行榜失败: $e');
      return [];
    }
  }
}
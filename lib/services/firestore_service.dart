import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/game_progress.dart';
import '../utils/logger_utils.dart';
import 'ip_location_service.dart';

/// Firestore数据库服务
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 获取用户集合引用
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// 创建或更新用户档案（完整版 - 一次性更新所有登录信息）
  Future<void> updateUserCompleteLoginInfo({
    required User user,
    required String provider,
    required Map<String, dynamic> deviceInfo,
    required Map<String, dynamic> locationInfo,
    required String deviceLanguage,
    required String appVersion,
  }) async {
    try {
      final docRef = _usersCollection.doc(user.uid);
      final doc = await docRef.get();
      final now = DateTime.now();
      
      if (!doc.exists) {
        // 创建新用户 - 一次性设置所有字段
        final userData = {
          'profile': {
            // 基本信息
            'userId': user.uid,
            'email': user.email ?? '',
            'displayName': user.displayName ?? 'Player',
            'photoUrl': user.photoURL,
            
            // 账号信息
            'accountCreatedAt': Timestamp.fromDate(now),
            'lastLoginAt': Timestamp.fromDate(now),
            'loginMethod': provider.toLowerCase(),
            'userType': 'normal',
            
            // 语言设置
            'deviceLanguage': deviceLanguage,
            'userSelectedLanguage': null,  // 用户未选择
            
            // 地理位置信息
            'country': locationInfo['country'],
            'countryCode': locationInfo['countryCode'],
            'region': locationInfo['region'],
            'city': locationInfo['city'],
            'timezone': locationInfo['timezone'],
            'utcOffset': IpLocationService.getUTCOffset(locationInfo['timezone']),
            'isp': locationInfo['isp'],
            
            // 应用版本
            'appVersion': appVersion,
          },
          // 设备信息
          'device': deviceInfo,
        };
        
        await docRef.set(userData);
        LoggerUtils.info('创建新用户档案（包含完整信息）: ${user.uid}');
      } else {
        // 更新已有用户 - 一次性更新所有登录相关字段
        // 包括更新displayName和photoUrl（可能已经改变）
        await docRef.update({
          'profile.displayName': user.displayName ?? 'Player',
          'profile.photoUrl': user.photoURL,
          'profile.lastLoginAt': Timestamp.fromDate(now),
          'profile.deviceLanguage': deviceLanguage,
          'profile.country': locationInfo['country'],
          'profile.countryCode': locationInfo['countryCode'],
          'profile.region': locationInfo['region'],
          'profile.city': locationInfo['city'],
          'profile.timezone': locationInfo['timezone'],
          'profile.utcOffset': IpLocationService.getUTCOffset(locationInfo['timezone']),
          'profile.isp': locationInfo['isp'],
          'profile.appVersion': appVersion,
          'device': deviceInfo,
        });
        LoggerUtils.info('更新用户登录信息（包括头像和名称）: ${user.uid}');
      }
    } catch (e) {
      LoggerUtils.error('更新用户完整登录信息失败: $e');
      rethrow;
    }
  }
  
  /// 创建或更新用户档案（简化版 - 保留兼容性）
  Future<void> createOrUpdateUserProfile(User user, String provider) async {
    try {
      final docRef = _usersCollection.doc(user.uid);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        // 创建基本用户文档
        final now = DateTime.now();
        final userData = {
          'profile': {
            'userId': user.uid,
            'email': user.email ?? '',
            'displayName': user.displayName ?? 'Player',
            'photoUrl': user.photoURL,
            'accountCreatedAt': Timestamp.fromDate(now),
            'lastLoginAt': Timestamp.fromDate(now),
            'loginMethod': provider.toLowerCase(),
            'userType': 'normal',
          }
        };
        await docRef.set(userData);
        LoggerUtils.info('创建基本用户档案: ${user.uid}');
      } else {
        // 更新现有用户的登录时间、显示名称和头像
        await docRef.update({
          'profile.displayName': user.displayName ?? 'Player',
          'profile.photoUrl': user.photoURL,
          'profile.lastLoginAt': Timestamp.fromDate(DateTime.now()),
        });
        LoggerUtils.info('更新用户信息（包括头像）: ${user.uid}');
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
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['profile'] != null) {
          final profileData = data['profile'] as Map<String, dynamic>;
          return UserProfile.fromMap(profileData);
        }
      }
      return null;
    } catch (e) {
      LoggerUtils.error('获取用户档案失败: $e');
      return null;
    }
  }

  // 游戏进度相关方法已移至 GameProgressService
  // 游戏进度数据存储在独立的 gameProgress/{userId} 集合中

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


  /// 更新用户选择的语言
  Future<void> updateUserSelectedLanguage(String userId, String language) async {
    try {
      await _usersCollection
          .doc(userId)
          .update({'profile.userSelectedLanguage': language});
      LoggerUtils.info('用户选择语言已更新: $language');
    } catch (e) {
      LoggerUtils.error('更新用户选择语言失败: $e');
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
      // 游戏进度更新已移至 GameProgressService
      // 这里暂时不处理，应该调用 GameProgressService.instance.updateGameResult()
      LoggerUtils.info('游戏结果更新应该使用 GameProgressService');
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
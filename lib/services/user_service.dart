import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/player_profile.dart';
import '../utils/logger_utils.dart';
import 'storage/local_storage_service.dart';
import 'intimacy_service.dart';

/// 用户服务 - 管理用户数据和游戏统计
class UserService extends ChangeNotifier {
  PlayerProfile? _playerProfile;
  User? _currentUser;
  
  PlayerProfile? get playerProfile => _playerProfile;
  User? get currentUser => _currentUser;
  String get displayName => _playerProfile?.nickname ?? _currentUser?.displayName ?? '玩家';
  String? get avatarUrl => _currentUser?.photoURL;
  
  /// 初始化用户服务
  Future<void> initialize(User? user) async {
    _currentUser = user;
    
    // 设置LocalStorageService的用户ID
    final userId = user?.uid ?? 'guest';
    LocalStorageService.instance.setUserId(userId);
    
    // 设置IntimacyService的用户ID
    IntimacyService().setUserId(userId);
    
    if (user != null) {
      // 加载或创建用户档案
      await _loadOrCreateProfile(user.uid);
    } else {
      // 游客模式
      await _loadGuestProfile();
    }
    
    notifyListeners();
  }
  
  /// 加载或创建用户档案
  Future<void> _loadOrCreateProfile(String uid) async {
    try {
      final storage = LocalStorageService.instance;
      final profileData = await storage.getJson('player_profile');
      
      if (profileData != null) {
        // 加载已有档案
        _playerProfile = PlayerProfile.fromJson(profileData);
        LoggerUtils.info('加载用户档案: ${_playerProfile!.nickname}');
      } else {
        // 创建新档案
        _playerProfile = PlayerProfile(
          id: uid,
          nickname: _currentUser?.displayName ?? '玩家',
          avatar: _currentUser?.photoURL ?? '',
          totalGames: 0,
          totalWins: 0,
          totalChallenges: 0,
          successfulChallenges: 0,
          totalBids: 0,
          successfulBids: 0,
          bluffingTendency: 0.3,
          challengeTendency: 0.4,
          lastPlayTime: DateTime.now(),
        );
        await _saveProfile();
        LoggerUtils.info('创建新用户档案: ${_playerProfile!.nickname}');
      }
    } catch (e) {
      LoggerUtils.error('加载用户档案失败: $e');
      _createDefaultProfile();
    }
  }
  
  /// 加载游客档案
  Future<void> _loadGuestProfile() async {
    try {
      final storage = LocalStorageService.instance;
      final profileData = await storage.getJson('player_profile');
      
      if (profileData != null) {
        _playerProfile = PlayerProfile.fromJson(profileData);
        LoggerUtils.info('加载游客档案');
      } else {
        _playerProfile = PlayerProfile(
          id: 'guest',
          nickname: '游客',
          avatar: '',
          totalGames: 0,
          totalWins: 0,
          totalChallenges: 0,
          successfulChallenges: 0,
          totalBids: 0,
          successfulBids: 0,
          bluffingTendency: 0.3,
          challengeTendency: 0.4,
          lastPlayTime: DateTime.now(),
        );
        await _saveProfile();
        LoggerUtils.info('创建游客档案');
      }
    } catch (e) {
      LoggerUtils.error('加载游客档案失败: $e');
      _createDefaultProfile();
    }
  }
  
  /// 创建默认档案
  void _createDefaultProfile() {
    _playerProfile = PlayerProfile(
      id: _currentUser?.uid ?? 'guest',
      nickname: _currentUser?.displayName ?? '玩家',
      avatar: _currentUser?.photoURL ?? '',
      totalGames: 0,
      totalWins: 0,
      totalChallenges: 0,
      successfulChallenges: 0,
      totalBids: 0,
      successfulBids: 0,
      bluffingTendency: 0.3,
      challengeTendency: 0.4,
      lastPlayTime: DateTime.now(),
    );
  }
  
  /// 保存用户档案
  Future<void> _saveProfile() async {
    if (_playerProfile == null) return;
    
    try {
      final storage = LocalStorageService.instance;
      await storage.setJson('player_profile', _playerProfile!.toJson());
    } catch (e) {
      LoggerUtils.error('保存用户档案失败: $e');
    }
  }
  
  /// 更新游戏统计
  Future<void> updateGameStats({
    bool? won,
    bool? challenged,
    bool? challengeSuccess,
    bool? bid,
    bool? bidSuccess,
    bool? bluffed,
  }) async {
    if (_playerProfile == null) return;
    
    _playerProfile!.totalGames++;
    
    if (won == true) _playerProfile!.totalWins++;
    if (challenged == true) _playerProfile!.totalChallenges++;
    if (challengeSuccess == true) _playerProfile!.successfulChallenges++;
    if (bid == true) _playerProfile!.totalBids++;
    if (bidSuccess == true) _playerProfile!.successfulBids++;
    
    // 更新倾向性
    if (_playerProfile!.totalBids > 10) {
      _playerProfile!.bluffingTendency = 
          _playerProfile!.successfulBids / _playerProfile!.totalBids;
    }
    
    if (_playerProfile!.totalChallenges > 10) {
      _playerProfile!.challengeTendency = 
          _playerProfile!.successfulChallenges / _playerProfile!.totalChallenges;
    }
    
    _playerProfile!.lastPlayTime = DateTime.now();
    
    await _saveProfile();
    notifyListeners();
  }
  
  /// 更新用户昵称
  Future<void> updateNickname(String nickname) async {
    if (_playerProfile == null) return;
    
    _playerProfile!.nickname = nickname;
    await _saveProfile();
    notifyListeners();
  }
  
  /// 重置游戏统计
  Future<void> resetStats() async {
    if (_playerProfile == null) return;
    
    _playerProfile!.totalGames = 0;
    _playerProfile!.totalWins = 0;
    _playerProfile!.totalChallenges = 0;
    _playerProfile!.successfulChallenges = 0;
    _playerProfile!.totalBids = 0;
    _playerProfile!.successfulBids = 0;
    _playerProfile!.bluffingTendency = 0.3;
    _playerProfile!.challengeTendency = 0.4;
    
    await _saveProfile();
    notifyListeners();
  }
  
  /// 获取胜率
  double get winRate {
    if (_playerProfile == null || _playerProfile!.totalGames == 0) {
      return 0.0;
    }
    return _playerProfile!.totalWins / _playerProfile!.totalGames;
  }
  
  /// 获取质疑成功率
  double get challengeSuccessRate {
    if (_playerProfile == null || _playerProfile!.totalChallenges == 0) {
      return 0.0;
    }
    return _playerProfile!.successfulChallenges / _playerProfile!.totalChallenges;
  }
  
  /// 清理用户数据（登出时调用）
  void clear() {
    _currentUser = null;
    _playerProfile = null;
    notifyListeners();
  }
}
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_progress.dart';
import 'game_progress_service.dart';
import '../utils/logger_utils.dart';
import 'storage/local_storage_service.dart';
import 'intimacy_service.dart';

/// 用户服务 - 管理用户数据和游戏统计
class UserService extends ChangeNotifier {
  GameProgressData? _gameProgress;
  User? _currentUser;
  
  GameProgressData? get playerProfile => _gameProgress; // 保持兼容性
  User? get currentUser => _currentUser;
  String get displayName => _currentUser?.displayName ?? '玩家';
  String? get avatarUrl => _currentUser?.photoURL;
  
  /// 初始化用户服务
  Future<void> initialize(User? user) async {
    _currentUser = user;
    
    // 设置LocalStorageService的用户ID
    final userId = user?.uid ?? 'guest';
    LocalStorageService.instance.setUserId(userId);
    
    // 设置IntimacyService的用户ID
    IntimacyService().setUserId(userId);
    
    // 加载游戏进度
    _gameProgress = await GameProgressService.instance.loadProgress();
    
    notifyListeners();
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
    // 统计更新已移至 GameProgressService.updateGameResult
    LoggerUtils.info('统计更新已移至 GameProgressService');
    _gameProgress = await GameProgressService.instance.loadProgress();
    notifyListeners();
  }
  
  /// 更新用户昵称
  Future<void> updateNickname(String nickname) async {
    // 昵称现在使用Firebase用户的displayName
    LoggerUtils.info('昵称更新: $nickname');
    notifyListeners();
  }
  
  /// 重置游戏统计
  Future<void> resetStats() async {
    await GameProgressService.instance.resetProgress();
    _gameProgress = await GameProgressService.instance.loadProgress();
    notifyListeners();
  }
  
  /// 获取胜率
  double get winRate {
    if (_gameProgress == null || _gameProgress!.totalGames == 0) {
      return 0.0;
    }
    return _gameProgress!.totalWins / _gameProgress!.totalGames;
  }
  
  /// 获取质疑成功率
  double get challengeSuccessRate {
    if (_gameProgress == null || _gameProgress!.totalChallenges == 0) {
      return 0.0;
    }
    return _gameProgress!.successfulChallenges / _gameProgress!.totalChallenges;
  }
  
  /// 清理用户数据（登出时调用）
  void clear() {
    _currentUser = null;
    _gameProgress = null;
    notifyListeners();
  }
}
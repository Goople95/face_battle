import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'firestore_service.dart';
import 'device_info_service.dart';
import 'game_progress_service.dart';
import 'storage/local_storage_service.dart';
import 'ip_location_service.dart';
import '../utils/logger_utils.dart';

/// 认证服务 - 管理用户登录状态
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  
  AuthService() {
    // 监听认证状态变化
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
    
    // 初始化时尝试自动登录
    _tryAutoLogin();
  }
  
  /// 尝试自动登录（应用启动时）
  Future<void> _tryAutoLogin() async {
    try {
      // 检查是否有之前的Google登录
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      if (googleUser != null) {
        // 获取认证详情
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        // 创建凭证
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        // 使用凭证登录Firebase
        final UserCredential userCredential = 
            await _auth.signInWithCredential(credential);
        
        _user = userCredential.user;
        
        // 保存用户信息到Firestore
        if (_user != null) {
          // 统一处理登录后的所有更新（自动登录也使用相同流程）
          await _handleUserLogin(_user!, 'google');
        }
        
        notifyListeners();
      }
    } catch (e) {
      // 自动登录失败，忽略错误，让用户手动登录
      LoggerUtils.debug('Auto login failed: $e');
    }
  }
  
  /// Google 登录
  Future<User?> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();
      
      // 先尝试静默登录（cold login）
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      // 如果静默登录失败，则显示登录界面
      if (googleUser == null) {
        googleUser = await _googleSignIn.signIn();
      }
      
      if (googleUser == null) {
        // 用户取消了登录
        _setLoading(false);
        return null;
      }
      
      // 获取认证详情
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // 创建凭证
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // 使用凭证登录Firebase
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      
      _user = userCredential.user;
      
      // 保存用户信息到Firestore
      if (_user != null) {
        // 首先设置LocalStorageService的用户ID
        // 统一处理登录后的所有更新
        await _handleUserLogin(_user!, 'google');
      }
      
      _setLoading(false);
      notifyListeners();
      return _user;
      
    } catch (e) {
      _setError('Google登录失败: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }
  
  /// Facebook 登录
  Future<User?> signInWithFacebook() async {
    try {
      _setLoading(true);
      _clearError();
      
      // 检查是否配置了有效的Facebook应用ID
      // 注意：当前使用的是测试ID，仅能消除错误日志，不能实现实际登录
      LoggerUtils.warning('Facebook登录使用测试配置，生产环境需要配置真实的应用ID');
      
      // 触发Facebook登录流程
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      
      // 检查登录状态
      if (result.status == LoginStatus.success) {
        // 获取访问令牌
        final AccessToken? accessToken = result.accessToken;
        
        if (accessToken != null) {
          // 创建Firebase凭证
          final OAuthCredential credential = 
              FacebookAuthProvider.credential(accessToken.token);
          
          // 使用凭证登录Firebase
          final UserCredential userCredential = 
              await _auth.signInWithCredential(credential);
          
          _user = userCredential.user;
          
          // 保存用户信息到Firestore
          if (_user != null) {
            // 首先设置LocalStorageService的用户ID
            // 统一处理登录后的所有更新
            await _handleUserLogin(_user!, 'facebook');
          }
          
          _setLoading(false);
          notifyListeners();
          return _user;
        }
      } else if (result.status == LoginStatus.cancelled) {
        // 用户取消了登录
        _setLoading(false);
        return null;
      } else if (result.status == LoginStatus.failed) {
        _setError('Facebook登录失败: ${result.message}');
        _setLoading(false);
        return null;
      }
      
      _setLoading(false);
      return null;
      
    } catch (e) {
      _setError('Facebook登录失败: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }
  
  /// 匿名登录（游客模式）
  Future<User?> signInAnonymously() async {
    try {
      _setLoading(true);
      _clearError();
      
      // 注意：Firebase的匿名登录会在以下情况重用用户ID：
      // 1. 应用数据未完全清除
      // 2. Android自动备份恢复了认证状态
      // 3. Firebase SDK缓存了凭证
      // 这可能导致卸载重装后仍使用相同的匿名用户ID
      
      final UserCredential userCredential = 
          await _auth.signInAnonymously();
      
      _user = userCredential.user;
      
      if (_user != null) {
        LoggerUtils.info('匿名登录成功: ${_user!.uid}');
        LoggerUtils.info('  账号创建时间: ${_user!.metadata.creationTime}');
        LoggerUtils.info('  最后登录时间: ${_user!.metadata.lastSignInTime}');
        
        // 检查是否是重用的旧匿名账号
        if (_user!.metadata.creationTime != null && 
            _user!.metadata.lastSignInTime != null) {
          final timeDiff = _user!.metadata.lastSignInTime!
              .difference(_user!.metadata.creationTime!);
          if (timeDiff.inMinutes > 5) {
            LoggerUtils.warning('检测到重用的匿名账号（创建于${timeDiff.inHours}小时前）');
            // 这是正常的，Firebase会重用匿名账号
            // GameProgressService会从云端恢复数据
          }
        }
      }
      
      _setLoading(false);
      notifyListeners();
      return _user;
      
    } catch (e) {
      _setError('匿名登录失败: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }
  
  /// 登出
  Future<void> signOut() async {
    try {
      _setLoading(true);
      
      // 同步数据到云端（登出前最后一次同步）
      await GameProgressService.instance.syncToCloud();
      
      // 登出所有平台
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        FacebookAuth.instance.logOut(),
      ]);
      
      _user = null;
      _setLoading(false);
      notifyListeners();
      
    } catch (e) {
      _setError('登出失败: ${e.toString()}');
      _setLoading(false);
    }
  }
  
  /// 删除账户
  Future<bool> deleteAccount() async {
    try {
      if (_user == null) return false;
      
      _setLoading(true);
      await _user!.delete();
      _user = null;
      _setLoading(false);
      notifyListeners();
      return true;
      
    } catch (e) {
      _setError('删除账户失败: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
  
  /// 获取用户显示名称
  String get displayName {
    if (_user == null) return '游客';
    return _user!.displayName ?? _user!.email?.split('@')[0] ?? '玩家';
  }
  
  /// 获取用户头像URL
  String? get photoURL => _user?.photoURL;
  
  /// 获取用户邮箱
  String? get email => _user?.email;
  
  /// 获取用户ID
  String? get uid => _user?.uid;
  
  /// 检查是否是匿名用户
  bool get isAnonymous => _user?.isAnonymous ?? false;
  
  // 私有辅助方法
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
  
  /// 统一处理用户登录后的数据更新
  Future<void> _handleUserLogin(User user, String provider) async {
    try {
      // 1. 设置 LocalStorage 用户ID
      LocalStorageService.instance.setUserId(user.uid);
      
      // 2. 并发收集所有需要的信息
      final results = await Future.wait([
        DeviceInfoService.instance.collectDeviceInfo(),
        IpLocationService.instance.getUserCountryInfo(),
        _getAppVersion(),
      ]);
      
      final deviceInfo = results[0] as Map<String, dynamic>;
      final locationInfo = results[1] as Map<String, dynamic>;
      final appVersion = results[2] as String;
      final deviceLanguage = Platform.localeName;
      
      // 3. 一次性更新所有用户信息到 Firestore
      await FirestoreService().updateUserCompleteLoginInfo(
        user: user,
        provider: provider,
        deviceInfo: deviceInfo,
        locationInfo: locationInfo,
        deviceLanguage: deviceLanguage,
        appVersion: appVersion,
      );
      
      // 4. 初始化游戏进度服务
      await GameProgressService.instance.initialize();
      
      LoggerUtils.info('用户登录处理完成: ${user.uid} (版本: $appVersion)');
    } catch (e) {
      LoggerUtils.error('处理用户登录失败: $e');
      // 不抛出错误，避免影响登录流程
    }
  }
  
  /// 获取应用版本（包含build number）
  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      // 返回完整版本信息：version+buildNumber
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      LoggerUtils.warning('获取应用版本失败: $e');
      return '0.1.2+1'; // 默认值，更新为当前版本
    }
  }
}
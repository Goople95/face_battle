import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

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
  }
  
  /// Google 登录
  Future<User?> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();
      
      // 触发Google登录流程
      await _googleSignIn.signOut(); // 确保之前的登录清除
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
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
        await FirestoreService().createOrUpdateUserProfile(_user!, 'google');
        await _saveUserLocally(_user!);
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
            await FirestoreService().createOrUpdateUserProfile(_user!, 'facebook');
            await _saveUserLocally(_user!);
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
      
      final UserCredential userCredential = 
          await _auth.signInAnonymously();
      
      _user = userCredential.user;
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
  
  /// 保存用户信息到本地（可选）
  Future<void> _saveUserLocally(User user) async {
    // 可以使用 SharedPreferences 保存一些用户信息
    // 用于离线展示或快速加载
  }
}
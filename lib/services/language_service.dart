import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import '../utils/logger_utils.dart';

class LanguageService extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  String? _userSelectedLanguage; // 用户手动选择的语言（来自 Firestore）
  
  Locale get currentLocale => _currentLocale;
  
  static const Map<String, Locale> supportedLanguages = {
    'zh_CN': Locale('zh', 'CN'),
    'en': Locale('en'),
    'zh_TW': Locale('zh', 'TW'),
    'es': Locale('es'),
    'pt': Locale('pt'),
  };
  
  Future<void> initialize() async {
    await _detectAndSetLanguage();
  }
  
  /// 检测并设置语言（优先级：用户选择 > 系统语言 > 默认英语）
  Future<void> _detectAndSetLanguage() async {
    try {
      String? languageCode;
      
      // 1. 尝试从 Firestore 获取用户选择的语言
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = await FirestoreService().getUserProfile(user.uid);
        if (profile != null && profile.userSelectedLanguage != null) {
          _userSelectedLanguage = profile.userSelectedLanguage;
          languageCode = _userSelectedLanguage;
          LoggerUtils.info('使用用户选择的语言: $languageCode');
        }
      }
      
      // 2. 如果没有用户选择，使用系统语言
      if (languageCode == null) {
        final systemLocale = Platform.localeName; // 例如: zh_CN, en_US
        languageCode = _mapSystemLocaleToSupported(systemLocale);
        LoggerUtils.info('使用系统语言: $systemLocale -> $languageCode');
      }
      
      // 3. 设置语言
      _currentLocale = supportedLanguages[languageCode] ?? const Locale('en');
      notifyListeners();
    } catch (e) {
      LoggerUtils.error('检测语言失败: $e');
      // 出错时使用英语
      _currentLocale = const Locale('en');
      notifyListeners();
    }
  }
  
  /// 将系统语言映射到支持的语言
  String _mapSystemLocaleToSupported(String systemLocale) {
    // 系统语言格式: zh_CN, en_US, es_ES 等
    final parts = systemLocale.split('_');
    final languageCode = parts.isNotEmpty ? parts[0] : 'en';
    
    // 中文需要区分简体和繁体
    if (languageCode == 'zh') {
      final countryCode = parts.length > 1 ? parts[1] : '';
      if (countryCode == 'TW' || countryCode == 'HK' || countryCode == 'MO') {
        return 'zh_TW'; // 繁体中文
      }
      return 'zh_CN'; // 简体中文
    }
    
    // 其他语言直接使用语言代码
    if (supportedLanguages.containsKey(languageCode)) {
      return languageCode;
    }
    
    // 默认英语
    return 'en';
  }
  
  Future<void> changeLanguage(String languageCode) async {
    try {
      // 更新当前语言
      _currentLocale = supportedLanguages[languageCode] ?? const Locale('en');
      _userSelectedLanguage = languageCode;
      
      // 同步到 Firestore（如果用户已登录）
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirestoreService().updateUserSelectedLanguage(user.uid, languageCode);
        LoggerUtils.info('语言设置已同步到云端: $languageCode');
      }
      
      LoggerUtils.info('切换语言为: $languageCode');
      notifyListeners();
    } catch (e) {
      LoggerUtils.error('保存语言设置失败: $e');
    }
  }
  
  String getLanguageCode() {
    if (_currentLocale.countryCode != null) {
      return '${_currentLocale.languageCode}_${_currentLocale.countryCode}';
    }
    return _currentLocale.languageCode;
  }
  
  /// 用户登录后同步语言设置
  Future<void> syncLanguageFromCloud() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final profile = await FirestoreService().getUserProfile(user.uid);
      if (profile != null && profile.userSelectedLanguage != null) {
        // 如果云端有用户选择的语言，使用它
        _userSelectedLanguage = profile.userSelectedLanguage;
        _currentLocale = supportedLanguages[_userSelectedLanguage!] ?? const Locale('en');
        LoggerUtils.info('从云端同步语言设置: $_userSelectedLanguage');
        notifyListeners();
      } else if (_userSelectedLanguage == null) {
        // 如果云端没有设置，但用户已登录，使用系统语言
        final systemLocale = Platform.localeName;
        final languageCode = _mapSystemLocaleToSupported(systemLocale);
        _currentLocale = supportedLanguages[languageCode] ?? const Locale('en');
        LoggerUtils.info('使用系统语言: $languageCode');
        notifyListeners();
      }
    } catch (e) {
      LoggerUtils.error('同步云端语言设置失败: $e');
    }
  }
}
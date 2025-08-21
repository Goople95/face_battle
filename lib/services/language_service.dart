import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger_utils.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  
  Locale _currentLocale = const Locale('zh', 'CN');
  
  Locale get currentLocale => _currentLocale;
  
  static const Map<String, Locale> supportedLanguages = {
    'zh_CN': Locale('zh', 'CN'),
    'en': Locale('en'),
    'zh_TW': Locale('zh', 'TW'),
    'es': Locale('es'),
    'pt': Locale('pt'),
  };
  
  Future<void> initialize() async {
    await loadLanguagePreference();
  }
  
  Future<void> loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'zh_CN';
      _currentLocale = supportedLanguages[languageCode] ?? const Locale('zh', 'CN');
      LoggerUtils.info('加载语言设置: $languageCode');
      notifyListeners();
    } catch (e) {
      LoggerUtils.error('加载语言设置失败: $e');
    }
  }
  
  Future<void> changeLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      _currentLocale = supportedLanguages[languageCode] ?? const Locale('zh', 'CN');
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
}
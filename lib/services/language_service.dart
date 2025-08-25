import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../utils/logger_utils.dart';

class LanguageService extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  String? _userSelectedLanguage; // 用户手动选择的语言（来自 Firestore）
  StreamSubscription<DocumentSnapshot>? _languageSubscription;
  
  Locale get currentLocale => _currentLocale;
  
  static const Map<String, Locale> supportedLanguages = {
    'en': Locale('en'),
    'zh_TW': Locale('zh', 'TW'),
    'es': Locale('es'),
    'pt': Locale('pt'),
    'id': Locale('id'),
  };
  
  Future<void> initialize() async {
    // 初始化时只设置系统语言或默认语言，不查询数据库
    // 数据库查询将在用户登录后通过 syncLanguageFromCloud 进行
    await _detectInitialLanguage();
  }
  
  /// 初始检测语言（仅使用系统语言，不查询数据库）
  Future<void> _detectInitialLanguage() async {
    try {
      // 初始化时仅使用系统语言
      final systemLocale = Platform.localeName; // 例如: zh_CN, en_US
      final languageCode = _mapSystemLocaleToSupported(systemLocale);
      _currentLocale = supportedLanguages[languageCode] ?? const Locale('en');
      LoggerUtils.info('初始化语言设置: $systemLocale -> $languageCode');
      notifyListeners();
    } catch (e) {
      LoggerUtils.error('初始化语言失败: $e');
      // 出错时使用英语
      _currentLocale = const Locale('en');
      notifyListeners();
    }
  }
  
  /// 规范化语言代码，处理各种格式
  String _normalizeLanguageCode(String code) {
    LoggerUtils.debug('规范化语言代码，输入: $code');
    
    // 处理所有中文变体 - 统一映射到繁体中文（因为游戏只支持繁体中文）
    if (code.toLowerCase().contains('zh')) {
      // zh, zh-CN, zh_CN, zh-TW, zh_TW, zh-HK 等都映射到 zh_TW
      LoggerUtils.debug('识别为中文变体: $code -> zh_TW');
      return 'zh_TW';
    }
    
    // 转换为小写进行其他语言判断
    String normalized = code.toLowerCase();
    
    // 处理印尼语的大小写: ID, id -> id
    if (normalized == 'id') {
      LoggerUtils.debug('识别为印尼语: $code -> id');
      return 'id';
    }
    
    // 其他语言直接返回小写形式
    LoggerUtils.debug('识别为其他语言: $code -> $normalized');
    return normalized;
  }
  
  /// 将系统语言映射到支持的语言
  String _mapSystemLocaleToSupported(String systemLocale) {
    LoggerUtils.debug('映射系统语言: $systemLocale');
    
    // 处理各种中文格式（包括 - 和 _ 分隔符）
    final lowerLocale = systemLocale.toLowerCase();
    if (lowerLocale.startsWith('zh')) {
      // zh-CN, zh_CN, zh-HK, zh_HK, zh-TW, zh_TW 等都映射到繁体中文
      LoggerUtils.debug('检测到中文系统语言，映射到 zh_TW');
      return 'zh_TW';
    }
    
    // 处理其他语言（使用 _ 或 - 分隔符）
    final parts = systemLocale.split(RegExp(r'[_-]'));
    final languageCode = parts.isNotEmpty ? parts[0].toLowerCase() : 'en';
    
    // 检查是否是支持的语言
    if (supportedLanguages.containsKey(languageCode)) {
      return languageCode;
    }
    
    // 默认英语
    LoggerUtils.debug('未识别的系统语言 $systemLocale，使用默认英语');
    return 'en';
  }
  
  Future<void> changeLanguage(String languageCode) async {
    try {
      // 规范化语言代码
      String normalizedCode = _normalizeLanguageCode(languageCode);
      
      // 更新当前语言
      _currentLocale = supportedLanguages[normalizedCode] ?? const Locale('en');
      _userSelectedLanguage = normalizedCode;
      
      // 同步到 Firestore（如果用户已登录），保存原始格式
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirestoreService().updateUserSelectedLanguage(user.uid, normalizedCode);
        LoggerUtils.info('语言设置已同步到云端: $languageCode -> $normalizedCode');
      }
      
      LoggerUtils.info('切换语言为: $normalizedCode');
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
      if (user == null) {
        LoggerUtils.debug('syncLanguageFromCloud: 用户未登录');
        return;
      }
      
      LoggerUtils.info('开始同步语言设置，用户: ${user.uid}');
      
      final profile = await FirestoreService().getUserProfile(user.uid);
      LoggerUtils.debug('获取到的profile不为空: ${profile != null}');
      LoggerUtils.debug('profile.userSelectedLanguage: ${profile?.userSelectedLanguage}');
      
      if (profile != null && profile.userSelectedLanguage != null) {
        // 优先级1：如果云端有用户选择的语言，使用它
        // 修复：规范化语言代码，处理各种格式问题
        final rawLanguage = profile.userSelectedLanguage!;
        _userSelectedLanguage = _normalizeLanguageCode(rawLanguage);
        
        _currentLocale = supportedLanguages[_userSelectedLanguage!] ?? const Locale('en');
        LoggerUtils.info('✅ 优先级1：从云端同步语言设置: $rawLanguage -> $_userSelectedLanguage');
        LoggerUtils.debug('当前Locale: ${_currentLocale.toString()}');
        notifyListeners();
      } else {
        // 优先级2：如果云端没有设置，使用系统语言
        LoggerUtils.debug('云端没有语言设置，使用系统语言');
        final systemLocale = Platform.localeName;
        final languageCode = _mapSystemLocaleToSupported(systemLocale);
        _currentLocale = supportedLanguages[languageCode] ?? const Locale('en');
        LoggerUtils.info('✅ 优先级2：使用系统语言: $systemLocale -> $languageCode');
        notifyListeners();
      }
      
      // 开始监听语言设置变化
      startListeningToLanguageChanges();
    } catch (e) {
      LoggerUtils.error('同步云端语言设置失败: $e');
      // 优先级3：出错时使用英语
      _currentLocale = const Locale('en');
      LoggerUtils.info('✅ 优先级3：使用默认英语');
      notifyListeners();
    }
  }
  
  /// 开始监听数据库中的语言设置变化
  void startListeningToLanguageChanges() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // 取消之前的监听
      _languageSubscription?.cancel();
      
      // 监听用户文档的变化
      _languageSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          
          // 语言设置在 profile.userSelectedLanguage 路径下
          final profile = data?['profile'] as Map<String, dynamic>?;
          final rawLanguage = profile?['userSelectedLanguage'] as String?;
          
          // 调试：打印完整的profile数据
          LoggerUtils.debug('Profile数据: ${profile?.toString()}');
          LoggerUtils.debug('检测到的原始语言: $rawLanguage, 当前语言: $_userSelectedLanguage');
          
          // 规范化语言代码
          String? newLanguage;
          if (rawLanguage != null) {
            newLanguage = _normalizeLanguageCode(rawLanguage);
          }
          
          // 如果语言设置发生变化
          if (newLanguage != null && newLanguage != _userSelectedLanguage) {
            LoggerUtils.info('🌐 检测到语言设置变化: $_userSelectedLanguage -> $newLanguage (原始: $rawLanguage)');
            _userSelectedLanguage = newLanguage;
            _currentLocale = supportedLanguages[newLanguage] ?? const Locale('en');
            
            // 显示调试信息
            LoggerUtils.debug('当前Locale: ${_currentLocale.toString()}');
            LoggerUtils.debug('支持的语言: ${supportedLanguages.keys.join(", ")}');
            
            // 通知所有监听者更新UI
            notifyListeners();
            
            // 调试用：打印一条消息确认UI应该更新了
            LoggerUtils.info('✅ UI应该已更新为新语言: $newLanguage');
          } else if (newLanguage == null) {
            LoggerUtils.debug('数据库中没有语言设置');
          } else {
            LoggerUtils.debug('语言未变化，保持: $newLanguage');
          }
        }
      }, onError: (error) {
        LoggerUtils.error('监听语言设置失败: $error');
      });
      
      LoggerUtils.info('🎯 开始监听数据库语言设置变化 (用户: ${user.uid})');
    } catch (e) {
      LoggerUtils.error('设置语言监听器失败: $e');
    }
  }
  
  /// 停止监听语言设置变化
  void stopListeningToLanguageChanges() {
    _languageSubscription?.cancel();
    _languageSubscription = null;
    LoggerUtils.info('停止监听数据库语言设置变化');
  }
  
  @override
  void dispose() {
    stopListeningToLanguageChanges();
    super.dispose();
  }
}
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../utils/logger_utils.dart';

class RulesService {
  static final RulesService _instance = RulesService._internal();
  factory RulesService() => _instance;
  RulesService._internal();

  Map<String, List<String>>? _rules;
  bool _isLoaded = false;

  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      LoggerUtils.info('Loading rules configuration from cloud...');
      
      // 必须从Firebase Storage加载，不缓存JSON
      bool cloudLoaded = await _loadFromCloud();
      
      if (!cloudLoaded) {
        // 无法加载规则，游戏需要联网
        throw Exception('无法从Firebase Storage加载游戏规则');
      }
      
      _isLoaded = true;
      LoggerUtils.info('Rules loaded successfully for ${_rules!.keys.length} languages');
    } catch (e) {
      LoggerUtils.error('Failed to load rules: $e');
      // 必须联网才能游戏
      throw Exception('需要网络连接：游戏规则必须从云端获取');
    }
  }

  Future<bool> _loadFromCloud() async {
    try {
      // 获取Firebase Storage引用
      final storageRef = FirebaseStorage.instance.ref();
      final rulesRef = storageRef.child('rules.json');
      
      // 获取下载URL
      final String downloadUrl = await rulesRef.getDownloadURL();
      LoggerUtils.info('Rules download URL: $downloadUrl');
      
      // 使用HTTP下载JSON内容
      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
        
        _rules = {};
        final rulesData = jsonData['rules'] as Map<String, dynamic>;
        
        rulesData.forEach((locale, rules) {
          _rules![locale] = List<String>.from(rules);
        });
        
        LoggerUtils.info('Successfully loaded rules from cloud for ${_rules!.keys.length} languages');
        return true;
      } else {
        LoggerUtils.error('Failed to download rules: HTTP ${response.statusCode}');
        return false;
      }
    } catch (e) {
      LoggerUtils.error('Error loading rules from cloud: $e');
      return false;
    }
  }

  List<String> getRules(String locale) {
    if (!_isLoaded || _rules == null) {
      LoggerUtils.error('Rules not loaded yet');
      // 如果规则未加载，返回空列表
      return [];
    }

    // 标准化locale
    String normalizedLocale = _normalizeLocale(locale);
    
    // 尝试获取对应语言的规则，默认使用英文
    return _rules![normalizedLocale] ?? _rules!['en'] ?? [];
  }

  String _normalizeLocale(String locale) {
    // 处理中文的特殊情况
    if (locale.startsWith('zh')) {
      return 'zh_TW';
    }
    
    // 其他语言直接返回语言代码
    if (locale.contains('_')) {
      return locale.split('_')[0];
    }
    
    return locale;
  }
}
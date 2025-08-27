import 'dart:convert';
import 'package:flutter/services.dart';
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
      LoggerUtils.info('Loading rules configuration...');
      
      final String jsonString = await rootBundle.loadString('assets/config/rules.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      _rules = {};
      final rulesData = jsonData['rules'] as Map<String, dynamic>;
      
      rulesData.forEach((locale, rules) {
        _rules![locale] = List<String>.from(rules);
      });
      
      _isLoaded = true;
      LoggerUtils.info('Rules loaded successfully for ${_rules!.keys.length} languages');
    } catch (e) {
      LoggerUtils.error('Failed to load rules: $e');
      // 使用默认规则作为后备
      _rules = _getDefaultRules();
      _isLoaded = true;
    }
  }

  List<String> getRules(String locale) {
    if (!_isLoaded) {
      LoggerUtils.warning('Rules not loaded yet, using defaults');
      return _getDefaultRules()[locale] ?? _getDefaultRules()['en']!;
    }

    // 标准化locale
    String normalizedLocale = _normalizeLocale(locale);
    
    // 尝试获取对应语言的规则
    return _rules![normalizedLocale] ?? _rules!['en'] ?? _getDefaultRules()['en']!;
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

  Map<String, List<String>> _getDefaultRules() {
    return {
      'en': [
        'Each player rolls 5 dices in secret.',
        '1s are wild and count as any number, until someone calls 1s directly.',
        'Each new bid must be higher in quantity or face value.',
        'If you think it\'s a bluff, call it! The dice will decide who loses.',
        'Dice ranking: 1 > 6 > 5 > 4 > 3 > 2.'
      ],
      'zh_TW': [
        '每位玩家各自秘密擲 5 顆骰子。',
        '點數 1 為萬用，可當任意點數，直到有人直接叫「1」為止。',
        '每次叫注必須提高數量或骰子點數。',
        '若懷疑對手在吹牛，就揭穿！結果由骰子決定輸贏。',
        '骰子大小順序：1 > 6 > 5 > 4 > 3 > 2。'
      ]
    };
  }
}
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../utils/logger_utils.dart';

/// 对话服务 - 管理NPC的对话内容
class DialogueService {
  static final DialogueService _instance = DialogueService._internal();
  factory DialogueService() => _instance;
  DialogueService._internal();

  final Map<String, Map<String, dynamic>> _dialogues = {};
  final Random _random = Random();
  bool _isLoaded = false;

  /// 初始化服务，加载所有对话文件
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    try {
      // 加载所有NPC的对话文件
      final npcIds = ['0001', '0002', '1001', '1002'];  // 移除不存在的1003
      
      for (String id in npcIds) {
        try {
          final String jsonString = await rootBundle.loadString(
            'assets/dialogues/dialogue_$id.json'  // 使用新的文件命名格式
          );
          final Map<String, dynamic> dialogueData = json.decode(jsonString);
          _dialogues[id] = dialogueData;
          LoggerUtils.info('加载对话文件: $id');
        } catch (e) {
          LoggerUtils.warning('无法加载对话文件 $id: $e');
        }
      }
      
      _isLoaded = true;
      LoggerUtils.info('对话服务初始化完成，加载了 ${_dialogues.length} 个角色的对话');
    } catch (e) {
      LoggerUtils.error('对话服务初始化失败: $e');
    }
  }

  /// 获取NPC胜利时的对话
  String getWinDialogue(String npcId, {String locale = 'zh_TW'}) {
    final dialogueData = _dialogues[npcId];
    if (dialogueData == null) {
      LoggerUtils.warning('未找到NPC $npcId 的对话数据。已加载的NPCs: ${_dialogues.keys.toList()}');
      return _getDefaultWinDialogue();
    }

    // 处理locale代码（移除zh简体中文，统一使用zh_TW繁体）
    String localeCode = _normalizeLocale(locale);

    // 新的多语言格式: dialogues.winning[locale]
    final dialogues = dialogueData['dialogues'] as Map<String, dynamic>?;
    if (dialogues != null) {
      final winningData = dialogues['winning'];
      if (winningData != null) {
        List<dynamic>? winningDialogues;
        
        // 如果是多语言格式
        if (winningData is Map<String, dynamic>) {
          LoggerUtils.info('Getting winning dialogue for locale: $localeCode');
          winningDialogues = winningData[localeCode] ?? winningData['en'] ?? winningData['zh_TW'];
          LoggerUtils.info('Available locales in winning data: ${winningData.keys.toList()}');
          LoggerUtils.info('Selected dialogues: $winningDialogues');
        } 
        // 如果是单语言列表（向后兼容）
        else if (winningData is List<dynamic>) {
          winningDialogues = winningData;
        }
        
        if (winningDialogues != null && winningDialogues.isNotEmpty) {
          final selected = winningDialogues[_random.nextInt(winningDialogues.length)];
          LoggerUtils.info('Selected winning dialogue: $selected');
          return selected;
        }
      }
    }
    
    // 旧格式兼容: win_dialogues
    final winDialogues = dialogueData['win_dialogues'] as List<dynamic>?;
    if (winDialogues != null && winDialogues.isNotEmpty) {
      final dialogue = winDialogues[_random.nextInt(winDialogues.length)];
      return dialogue[localeCode] ?? dialogue['zh_TW'] ?? _getDefaultWinDialogue();
    }

    return _getDefaultWinDialogue();
  }

  /// 获取NPC失败时的对话
  String getLoseDialogue(String npcId, {String locale = 'zh_TW'}) {
    final dialogueData = _dialogues[npcId];
    if (dialogueData == null) {
      LoggerUtils.warning('未找到NPC $npcId 的对话数据。已加载的NPCs: ${_dialogues.keys.toList()}');
      return _getDefaultLoseDialogue();
    }

    // 处理locale代码
    String localeCode = _normalizeLocale(locale);

    // 新的多语言格式: dialogues.losing[locale]
    final dialogues = dialogueData['dialogues'] as Map<String, dynamic>?;
    if (dialogues != null) {
      final losingData = dialogues['losing'];
      if (losingData != null) {
        List<dynamic>? losingDialogues;
        
        // 如果是多语言格式
        if (losingData is Map<String, dynamic>) {
          losingDialogues = losingData[localeCode] ?? losingData['en'] ?? losingData['zh_TW'];
        }
        // 如果是单语言列表（向后兼容）
        else if (losingData is List<dynamic>) {
          losingDialogues = losingData;
        }
        
        if (losingDialogues != null && losingDialogues.isNotEmpty) {
          return losingDialogues[_random.nextInt(losingDialogues.length)];
        }
      }
    }
    
    // 旧格式兼容: lose_dialogues
    final loseDialogues = dialogueData['lose_dialogues'] as List<dynamic>?;
    if (loseDialogues != null && loseDialogues.isNotEmpty) {
      final dialogue = loseDialogues[_random.nextInt(loseDialogues.length)];
      return dialogue[localeCode] ?? dialogue['zh_TW'] ?? _getDefaultLoseDialogue();
    }

    return _getDefaultLoseDialogue();
  }

  /// 获取嘲讽对话（随机从赢的对话中选择）
  String getTaunt(String npcId, {String locale = 'zh_TW'}) {
    // 嘲讽时使用胜利对话的一部分
    return getWinDialogue(npcId, locale: locale);
  }

  /// 获取鼓励对话（随机从输的对话中选择）
  String getEncouragement(String npcId, {String locale = 'zh_TW'}) {
    // 鼓励时使用失败对话的一部分
    return getLoseDialogue(npcId, locale: locale);
  }

  /// 根据游戏状态获取合适的对话
  String getContextualDialogue(String npcId, {
    required bool isWinning,
    required int roundNumber,
    String locale = 'zh_TW'
  }) {
    // 根据当前状态返回合适的对话
    if (isWinning) {
      // NPC赢了这一轮
      return getWinDialogue(npcId, locale: locale);
    } else {
      // NPC输了这一轮
      return getLoseDialogue(npcId, locale: locale);
    }
  }

  // 默认对话
  String _getDefaultWinDialogue() => '該你喝酒了！';
  String _getDefaultLoseDialogue() => '你好厉害啊！';
  
  // 标准化locale代码
  String _normalizeLocale(String locale) {
    LoggerUtils.info('Normalizing locale: $locale');
    
    // 将zh或zh_CN统一转换为zh_TW
    if (locale == 'zh' || locale == 'zh_CN') {
      return 'zh_TW';
    }
    // 处理其他变体
    if (locale.startsWith('zh')) {
      if (locale.contains('TW') || locale.contains('HK') || locale.contains('MO')) {
        return 'zh_TW';
      }
      return 'zh_TW'; // 默认使用繁体
    }
    // 其他语言直接返回
    if (locale.contains('_')) {
      final normalized = locale.split('_')[0]; // 只保留语言代码
      LoggerUtils.info('Normalized locale to: $normalized');
      return normalized;
    }
    
    LoggerUtils.info('Final locale: $locale');
    return locale;
  }

  /// 清除缓存
  void clear() {
    _dialogues.clear();
    _isLoaded = false;
  }

  /// 重新加载对话
  Future<void> reload() async {
    clear();
    await initialize();
  }
  
  /// 获取问候语
  String getGreeting(String npcId, {String locale = 'zh_TW'}) {
    final dialogueData = _dialogues[npcId];
    if (dialogueData == null) return '你好！';
    
    String localeCode = _normalizeLocale(locale);
    final dialogues = dialogueData['dialogues'] as Map<String, dynamic>?;
    
    if (dialogues != null) {
      final greetingData = dialogues['greeting'];
      if (greetingData != null) {
        List<dynamic>? greetings;
        
        if (greetingData is Map<String, dynamic>) {
          greetings = greetingData[localeCode] ?? greetingData['en'] ?? greetingData['zh_TW'];
        } else if (greetingData is List<dynamic>) {
          greetings = greetingData;
        }
        
        if (greetings != null && greetings.isNotEmpty) {
          return greetings[_random.nextInt(greetings.length)];
        }
      }
    }
    
    return '你好！';
  }
  
  /// 获取情绪对话
  String getEmotionDialogue(String npcId, String emotion, {String locale = 'zh_TW'}) {
    final dialogueData = _dialogues[npcId];
    if (dialogueData == null) return '';
    
    String localeCode = _normalizeLocale(locale);
    final dialogues = dialogueData['dialogues'] as Map<String, dynamic>?;
    
    if (dialogues != null) {
      final emotionsData = dialogues['emotions'] as Map<String, dynamic>?;
      if (emotionsData != null) {
        final emotionData = emotionsData[emotion];
        if (emotionData != null) {
          if (emotionData is Map<String, dynamic>) {
            return emotionData[localeCode] ?? emotionData['en'] ?? emotionData['zh_TW'] ?? '';
          } else if (emotionData is String) {
            return emotionData;
          }
        }
      }
    }
    
    return '';
  }
  
  /// 获取思考对话
  String getThinkingDialogue(String npcId, {String locale = 'zh_TW'}) {
    final dialogueData = _dialogues[npcId];
    if (dialogueData == null) return '...';
    
    String localeCode = _normalizeLocale(locale);
    final dialogues = dialogueData['dialogues'] as Map<String, dynamic>?;
    
    if (dialogues != null) {
      final thinkingData = dialogues['thinking'];
      if (thinkingData != null) {
        List<dynamic>? thinkingDialogues;
        
        if (thinkingData is Map<String, dynamic>) {
          thinkingDialogues = thinkingData[localeCode] ?? thinkingData['en'] ?? thinkingData['zh_TW'];
        } else if (thinkingData is List<dynamic>) {
          thinkingDialogues = thinkingData;
        }
        
        if (thinkingDialogues != null && thinkingDialogues.isNotEmpty) {
          return thinkingDialogues[_random.nextInt(thinkingDialogues.length)];
        }
      }
    }
    
    // 默认返回通用的思考对话
    return localeCode == 'zh_TW' ? '讓我想想...' : 'Let me think...';
  }
  
  /// 获取策略对话
  String getStrategyDialogue(String npcId, String strategy, {String locale = 'zh_TW'}) {
    final dialogueData = _dialogues[npcId];
    if (dialogueData == null) {
      return _getDefaultStrategyDialogue(strategy);
    }
    
    String localeCode = _normalizeLocale(locale);
    final dialogues = dialogueData['dialogues'] as Map<String, dynamic>?;
    
    if (dialogues != null) {
      final strategyData = dialogues['strategy_dialogue'] as Map<String, dynamic>?;
      if (strategyData != null) {
        final specificStrategy = strategyData[strategy];
        if (specificStrategy != null) {
          // 处理多语言格式
          if (specificStrategy is Map<String, dynamic>) {
            final localizedDialogues = specificStrategy[localeCode] ?? 
                                       specificStrategy['en'] ?? 
                                       specificStrategy['zh_TW'];
            if (localizedDialogues != null) {
              if (localizedDialogues is List && localizedDialogues.isNotEmpty) {
                return localizedDialogues[_random.nextInt(localizedDialogues.length)];
              } else if (localizedDialogues is String) {
                return localizedDialogues;
              }
            }
          } else if (specificStrategy is String) {
            return specificStrategy;
          } else if (specificStrategy is List && specificStrategy.isNotEmpty) {
            return specificStrategy[_random.nextInt(specificStrategy.length)];
          }
        }
      }
    }
    
    return _getDefaultStrategyDialogue(strategy);
  }
  
  String _getDefaultStrategyDialogue(String strategy) {
    switch (strategy) {
      case 'challenge_action':
        return '我不信';
      case 'value_bet':
        return '稳稳的';
      case 'semi_bluff':
        return '试试看';
      case 'bluff':
      case 'pure_bluff':
        return '就这样';
      case 'reverse_trap':
        return '我...不太确定';
      case 'pressure_play':
        return '该决定了';
      case 'safe_play':
        return '求稳';
      default:
        return '...';
    }
  }
  
  /// 获取醉酒对话
  String getDrunkDialogue(String npcId, bool isHeavy, {String locale = 'zh_TW'}) {
    final dialogueData = _dialogues[npcId];
    if (dialogueData == null) return '...';
    
    String localeCode = _normalizeLocale(locale);
    final dialogues = dialogueData['dialogues'] as Map<String, dynamic>?;
    
    if (dialogues != null) {
      final drunkData = dialogues['drunk'] as Map<String, dynamic>?;
      if (drunkData != null) {
        final levelData = drunkData[isHeavy ? 'heavy' : 'light'];
        if (levelData != null) {
          List<dynamic>? drunkDialogues;
          
          if (levelData is Map<String, dynamic>) {
            drunkDialogues = levelData[localeCode] ?? levelData['en'] ?? levelData['zh_TW'];
          } else if (levelData is List<dynamic>) {
            drunkDialogues = levelData;
          }
          
          if (drunkDialogues != null && drunkDialogues.isNotEmpty) {
            return drunkDialogues[_random.nextInt(drunkDialogues.length)];
          }
        }
      }
    }
    
    return '...';
  }
}
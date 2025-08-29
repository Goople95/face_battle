import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/logger_utils.dart';

/// 对话服务 - 管理NPC的对话内容
class DialogueService {
  static final DialogueService _instance = DialogueService._internal();
  factory DialogueService() => _instance;
  DialogueService._internal();

  final Map<String, Map<String, dynamic>> _dialogues = {};
  final Random _random = Random();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 初始化服务（不再预加载所有对话）
  Future<void> initialize() async {
    LoggerUtils.info('对话服务初始化完成（按需加载模式）');
  }

  /// 按需加载指定NPC的对话文件
  Future<Map<String, dynamic>?> _loadDialogueForNPC(String npcId) async {
    // 如果已缓存，直接返回
    if (_dialogues.containsKey(npcId)) {
      return _dialogues[npcId];
    }

    try {
      // 优先尝试从云端加载
      LoggerUtils.info('从云端加载NPC对话: $npcId');
      
      try {
        final ref = _storage.ref('npcs/$npcId/dialogue_$npcId.json');
        final data = await ref.getData(10000000); // 10MB限制
        
        if (data != null) {
          final jsonString = utf8.decode(data);
          final dialogueData = json.decode(jsonString) as Map<String, dynamic>;
          _dialogues[npcId] = dialogueData;
          LoggerUtils.info('成功从云端加载对话: $npcId');
          return dialogueData;
        }
      } catch (e) {
        LoggerUtils.warning('云端加载失败，尝试本地: $npcId - $e');
      }

      // 云端失败，回退到本地
      try {
        final String jsonString = await rootBundle.loadString(
          'assets/dialogues/dialogue_$npcId.json'
        );
        final Map<String, dynamic> dialogueData = json.decode(jsonString);
        _dialogues[npcId] = dialogueData;
        LoggerUtils.info('从本地加载对话: $npcId');
        return dialogueData;
      } catch (e) {
        LoggerUtils.error('本地加载也失败: $npcId - $e');
      }
      
    } catch (e) {
      LoggerUtils.error('加载NPC对话失败: $npcId - $e');
    }
    
    return null;
  }

  /// 获取NPC胜利时的对话（改为异步）
  Future<String> getWinDialogue(String npcId, {String locale = 'zh_TW'}) async {
    // 按需加载对话
    final dialogueData = await _loadDialogueForNPC(npcId);
    if (dialogueData == null) {
      LoggerUtils.warning('未找到NPC $npcId 的对话数据');
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
  Future<String> getLoseDialogue(String npcId, {String locale = 'zh_TW'}) async {
    final dialogueData = await _loadDialogueForNPC(npcId);
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
  Future<String> getTaunt(String npcId, {String locale = 'zh_TW'}) async {
    // 嘲讽时使用胜利对话的一部分
    return await getWinDialogue(npcId, locale: locale);
  }

  /// 获取鼓励对话（随机从输的对话中选择）
  Future<String> getEncouragement(String npcId, {String locale = 'zh_TW'}) async {
    // 鼓励时使用失败对话的一部分
    return await getLoseDialogue(npcId, locale: locale);
  }

  /// 根据游戏状态获取合适的对话
  Future<String> getContextualDialogue(String npcId, {
    required bool isWinning,
    required int roundNumber,
    String locale = 'zh_TW'
  }) async {
    // 根据当前状态返回合适的对话
    if (isWinning) {
      // NPC赢了这一轮
      return await getWinDialogue(npcId, locale: locale);
    } else {
      // NPC输了这一轮
      return await getLoseDialogue(npcId, locale: locale);
    }
  }

  // 默认对话
  String _getDefaultWinDialogue() => '該你喝酒了！';
  String _getDefaultLoseDialogue() => '你好厉害啊！';
  
  // 标准化locale代码
  String _normalizeLocale(String locale) {
    LoggerUtils.info('Normalizing locale: $locale');
    
    // 所有中文都使用繁体中文
    if (locale.startsWith('zh')) {
      return 'zh_TW';
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
    
    return _getDefaultStrategyDialogue(strategy, locale: locale);
  }
  
  String _getDefaultStrategyDialogue(String strategy, {String locale = 'en'}) {
    // 返回特殊标记，让调用方使用ARB本地化
    // 这些会在game_screen中被处理
    switch (strategy) {
      case 'challenge_action':
        return '__DEFAULT_CHALLENGE__';
      case 'value_bet':
        return '__DEFAULT_VALUE_BET__';
      case 'semi_bluff':
        return '__DEFAULT_SEMI_BLUFF__';
      case 'bluff':
      case 'pure_bluff':
        return '__DEFAULT_BLUFF__';
      case 'reverse_trap':
        return '__DEFAULT_REVERSE_TRAP__';
      case 'pressure_play':
        return '__DEFAULT_PRESSURE_PLAY__';
      case 'safe_play':
        return '__DEFAULT_SAFE_PLAY__';
      case 'pattern_break':
        return '__DEFAULT_PATTERN_BREAK__';
      case 'reverse_trap_alt':
        return '__DEFAULT_REVERSE_TRAP__';  // 使用相同的默認值
      case 'pressure_escalation':
        return '__DEFAULT_PRESSURE_PLAY__';  // 使用相似的默認值
      case 'late_pressure':
        return '__DEFAULT_PRESSURE_PLAY__';  // 使用相似的默認值
      case 'aggressive_bait':
        return '__DEFAULT_BLUFF__';  // 使用相似的默認值
      case 'induce_aggressive':
        return '__DEFAULT_INDUCE_AGGRESSIVE__';
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
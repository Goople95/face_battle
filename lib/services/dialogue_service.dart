import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/logger_utils.dart';
import '../models/ai_personality.dart';
import 'npc_resource_loader.dart';
import 'npc_skin_service.dart';

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
  Future<Map<String, dynamic>?> _loadDialogueForNPC(String npcId, {AIPersonality? personality}) async {
    // 获取当前选择的皮肤ID
    final skinId = NPCSkinService.instance.getSelectedSkinId(npcId);
    
    // 使用皮肤ID作为缓存key
    final cacheKey = '${npcId}_$skinId';
    
    // 如果已缓存，直接返回
    if (_dialogues.containsKey(cacheKey)) {
      return _dialogues[cacheKey];
    }

    try {
      // 使用NPCResourceLoader统一处理本地和云端资源
      String dialoguePath;
      
      // 如果有personality，使用其avatarPath作为basePath
      if (personality != null && personality.avatarPath.isNotEmpty) {
        dialoguePath = await NPCResourceLoader.getDialoguePath(
          npcId, 
          personality.avatarPath,
          skinId: skinId,  // 使用当前选择的皮肤ID
        );
      } else {
        // 没有personality，假设是云端资源
        dialoguePath = await NPCResourceLoader.getDialoguePath(
          npcId, 
          '',  // 空basePath表示云端资源
          skinId: skinId,  // 使用当前选择的皮肤ID
        );
      }
      
      LoggerUtils.info('加载NPC对话: $npcId (皮肤$skinId) from $dialoguePath');
      
      // 根据路径类型加载文件
      String jsonString;
      if (dialoguePath.startsWith('assets/')) {
        // 本地asset资源
        jsonString = await rootBundle.loadString(dialoguePath);
        LoggerUtils.info('从本地asset加载对话: $npcId (皮肤$skinId)');
      } else if (dialoguePath.startsWith('http')) {
        // 网络URL（云端资源）- 使用正确的皮肤路径
        final ref = _storage.ref('npcs/$npcId/$skinId/dialogue_$npcId.json');
        final data = await ref.getData(10000000); // 10MB限制
        if (data != null) {
          jsonString = utf8.decode(data);
          LoggerUtils.info('从云端URL加载对话: $npcId (皮肤$skinId)');
        } else {
          throw Exception('云端对话文件为空');
        }
      } else {
        // 本地文件路径（缓存的文件）
        final file = File(dialoguePath);
        if (await file.exists()) {
          jsonString = await file.readAsString();
          LoggerUtils.info('从本地缓存加载对话: $npcId (皮肤$skinId)');
        } else {
          throw Exception('本地缓存文件不存在');
        }
      }
      
      final Map<String, dynamic> dialogueData = json.decode(jsonString);
      _dialogues[cacheKey] = dialogueData;  // 使用带皮肤ID的缓存key
      return dialogueData;
      
    } catch (e) {
      LoggerUtils.error('加载NPC对话失败: $npcId - $e');
    }
    
    return null;
  }

  /// 获取NPC胜利时的对话（改为异步）
  Future<String> getWinDialogue(String npcId, {String locale = 'zh_TW', AIPersonality? personality}) async {
    // 按需加载对话
    final dialogueData = await _loadDialogueForNPC(npcId, personality: personality);
    if (dialogueData == null) {
      LoggerUtils.warning('未找到NPC $npcId 的对话数据');
      return _getDefaultWinDialogue(locale);
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
      return dialogue[localeCode] ?? dialogue['zh_TW'] ?? _getDefaultWinDialogue(locale);
    }

    return _getDefaultWinDialogue(locale);
  }

  /// 获取NPC失败时的对话
  Future<String> getLoseDialogue(String npcId, {String locale = 'zh_TW', AIPersonality? personality}) async {
    final dialogueData = await _loadDialogueForNPC(npcId, personality: personality);
    if (dialogueData == null) {
      LoggerUtils.warning('未找到NPC $npcId 的对话数据。已加载的NPCs: ${_dialogues.keys.toList()}');
      return _getDefaultLoseDialogue(locale);
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
      return dialogue[localeCode] ?? dialogue['zh_TW'] ?? _getDefaultLoseDialogue(locale);
    }

    return _getDefaultLoseDialogue(locale);
  }

  /// 获取嘲讽对话（随机从赢的对话中选择）
  Future<String> getTaunt(String npcId, {String locale = 'zh_TW', AIPersonality? personality}) async {
    // 嘲讽时使用胜利对话的一部分
    return await getWinDialogue(npcId, locale: locale, personality: personality);
  }

  /// 获取鼓励对话（随机从输的对话中选择）
  Future<String> getEncouragement(String npcId, {String locale = 'zh_TW', AIPersonality? personality}) async {
    // 鼓励时使用失败对话的一部分
    return await getLoseDialogue(npcId, locale: locale, personality: personality);
  }

  /// 根据游戏状态获取合适的对话
  Future<String> getContextualDialogue(String npcId, {
    required bool isWinning,
    required int roundNumber,
    String locale = 'zh_TW',
    AIPersonality? personality,
  }) async {
    // 根据当前状态返回合适的对话
    if (isWinning) {
      // NPC赢了这一轮
      return await getWinDialogue(npcId, locale: locale, personality: personality);
    } else {
      // NPC输了这一轮
      return await getLoseDialogue(npcId, locale: locale, personality: personality);
    }
  }

  // 默认对话（根据语言返回）
  String _getDefaultWinDialogue(String locale) {
    switch (_normalizeLocale(locale)) {
      case 'zh_TW':
        return '該你喝了！';
      case 'es':
        return '¡Es tu turno de beber!';
      case 'pt':
        return 'É sua vez de beber!';
      case 'id':
        return 'Giliranmu minum!';
      default:
        return "It's your turn to drink!";
    }
  }
  
  String _getDefaultLoseDialogue(String locale) {
    switch (_normalizeLocale(locale)) {
      case 'zh_TW':
        return '你真厲害！';
      case 'es':
        return '¡Eres increíble!';
      case 'pt':
        return 'Você é incrível!';
      case 'id':
        return 'Kamu luar biasa!';
      default:
        return "You're amazing!";
    }
  }
  
  String _getDefaultGreeting(String locale) {
    switch (_normalizeLocale(locale)) {
      case 'zh_TW':
        return '你好！';
      case 'es':
        return '¡Hola!';
      case 'pt':
        return 'Olá!';
      case 'id':
        return 'Halo!';
      default:
        return 'Hello!';
    }
  }
  
  String _getDefaultThinking(String locale) {
    return '...';  // 所有语言都一样
  }
  
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
    if (dialogueData == null) return _getDefaultGreeting(locale);
    
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
    
    return _getDefaultGreeting(locale);
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
    if (dialogueData == null) return _getDefaultThinking(locale);
    
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
    // 根据策略和语言返回本地化的默认对话
    String normalizedLocale = _normalizeLocale(locale);
    
    switch (strategy) {
      case 'challenge_action':
        return _getActionDialogue('challenge', normalizedLocale);
      case 'value_bet':
        return _getActionDialogue('valueBet', normalizedLocale);
      case 'semi_bluff':
      case 'bluff':
      case 'pure_bluff':
      case 'aggressive_bait':
        return _getActionDialogue('bluff', normalizedLocale);
      case 'reverse_trap':
      case 'reverse_trap_alt':
        return _getActionDialogue('reverseTrap', normalizedLocale);
      case 'pressure_play':
      case 'pressure_escalation':
      case 'late_pressure':
        return _getActionDialogue('pressurePlay', normalizedLocale);
      case 'safe_play':
        return _getActionDialogue('safePlay', normalizedLocale);
      case 'pattern_break':
        return _getActionDialogue('patternBreak', normalizedLocale);
      case 'induce_aggressive':
        return _getActionDialogue('induceAggressive', normalizedLocale);
      default:
        return _getDefaultThinking(locale);
    }
  }
  
  String _getActionDialogue(String action, String locale) {
    switch (action) {
      case 'challenge':
        switch (locale) {
          case 'zh_TW': return '我要挑戰！';
          case 'es': return '¡Lo desafío!';
          case 'pt': return 'Eu desafio isso!';
          case 'id': return 'Aku tantang itu!';
          default: return 'I challenge that!';
        }
      case 'valueBet':
        switch (locale) {
          case 'zh_TW': return '我押實力牌。';
          case 'es': return 'Apuesto por valor.';
          case 'pt': return 'Apostando em valor.';
          case 'id': return 'Bertaruh pada nilai.';
          default: return "I'm betting on value.";
        }
      case 'bluff':
        switch (locale) {
          case 'zh_TW': return '看你信不信...';
          case 'es': return 'Veamos si lo crees...';
          case 'pt': return 'Vamos ver se você acredita...';
          case 'id': return 'Mari lihat apa kamu percaya...';
          default: return "Let's see if you believe this...";
        }
      case 'reverseTrap':
        switch (locale) {
          case 'zh_TW': return '掉進我的陷阱了？';
          case 'es': return '¿Cayendo en mi trampa?';
          case 'pt': return 'Caindo na minha armadilha?';
          case 'id': return 'Masuk ke jebakanku?';
          default: return 'Walking into my trap?';
        }
      case 'pressurePlay':
        switch (locale) {
          case 'zh_TW': return '感受壓力吧！';
          case 'es': return '¡Siente la presión!';
          case 'pt': return 'Sinta a pressão!';
          case 'id': return 'Rasakan tekanannya!';
          default: return 'Feel the pressure!';
        }
      case 'safePlay':
        switch (locale) {
          case 'zh_TW': return '穩妥為上。';
          case 'es': return 'Jugando a lo seguro.';
          case 'pt': return 'Jogando seguro.';
          case 'id': return 'Bermain aman.';
          default: return 'Playing it safe.';
        }
      case 'patternBreak':
        switch (locale) {
          case 'zh_TW': return '該改變策略了！';
          case 'es': return '¡Hora de cambiar las cosas!';
          case 'pt': return 'Hora de mudar as coisas!';
          case 'id': return 'Saatnya mengubah segalanya!';
          default: return 'Time to change things up!';
        }
      case 'induceAggressive':
        switch (locale) {
          case 'zh_TW': return '來吧，大膽一點！';
          case 'es': return '¡Vamos, sé valiente!';
          case 'pt': return 'Vamos, seja ousado!';
          case 'id': return 'Ayo, beranilah!';
          default: return 'Come on, be bold!';
        }
      default:
        return '...';
    }
  }
  
  /// 获取醉酒对话
  Future<String> getDrunkDialogue(String npcId, bool isHeavy, {String locale = 'zh_TW', AIPersonality? personality}) async {
    final dialogueData = await _loadDialogueForNPC(npcId, personality: personality);
    if (dialogueData == null) return _getDefaultThinking(locale);
    
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
    
    return _getDefaultThinking(locale);
  }
}
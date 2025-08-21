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
  String getWinDialogue(String npcId, {String locale = 'zh_CN'}) {
    final dialogueData = _dialogues[npcId];
    if (dialogueData == null) {
      LoggerUtils.warning('未找到NPC $npcId 的对话数据。已加载的NPCs: ${_dialogues.keys.toList()}');
      return _getDefaultWinDialogue();
    }

    // 新格式: dialogues.winning
    final dialogues = dialogueData['dialogues'] as Map<String, dynamic>?;
    if (dialogues != null) {
      final winningDialogues = dialogues['winning'] as List<dynamic>?;
      if (winningDialogues != null && winningDialogues.isNotEmpty) {
        return winningDialogues[_random.nextInt(winningDialogues.length)];
      }
    }
    
    // 旧格式兼容: win_dialogues
    final winDialogues = dialogueData['win_dialogues'] as List<dynamic>?;
    if (winDialogues != null && winDialogues.isNotEmpty) {
      final dialogue = winDialogues[_random.nextInt(winDialogues.length)];
      return dialogue[locale] ?? dialogue['zh_CN'] ?? _getDefaultWinDialogue();
    }

    return _getDefaultWinDialogue();
  }

  /// 获取NPC失败时的对话
  String getLoseDialogue(String npcId, {String locale = 'zh_CN'}) {
    final dialogueData = _dialogues[npcId];
    if (dialogueData == null) {
      LoggerUtils.warning('未找到NPC $npcId 的对话数据。已加载的NPCs: ${_dialogues.keys.toList()}');
      return _getDefaultLoseDialogue();
    }

    // 新格式: dialogues.losing
    final dialogues = dialogueData['dialogues'] as Map<String, dynamic>?;
    if (dialogues != null) {
      final losingDialogues = dialogues['losing'] as List<dynamic>?;
      if (losingDialogues != null && losingDialogues.isNotEmpty) {
        return losingDialogues[_random.nextInt(losingDialogues.length)];
      }
    }
    
    // 旧格式兼容: lose_dialogues
    final loseDialogues = dialogueData['lose_dialogues'] as List<dynamic>?;
    if (loseDialogues != null && loseDialogues.isNotEmpty) {
      final dialogue = loseDialogues[_random.nextInt(loseDialogues.length)];
      return dialogue[locale] ?? dialogue['zh_CN'] ?? _getDefaultLoseDialogue();
    }

    return _getDefaultLoseDialogue();
  }

  /// 获取嘲讽对话（随机从赢的对话中选择）
  String getTaunt(String npcId, {String locale = 'zh_CN'}) {
    // 嘲讽时使用胜利对话的一部分
    return getWinDialogue(npcId, locale: locale);
  }

  /// 获取鼓励对话（随机从输的对话中选择）
  String getEncouragement(String npcId, {String locale = 'zh_CN'}) {
    // 鼓励时使用失败对话的一部分
    return getLoseDialogue(npcId, locale: locale);
  }

  /// 根据游戏状态获取合适的对话
  String getContextualDialogue(String npcId, {
    required bool isWinning,
    required int roundNumber,
    String locale = 'zh_CN'
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
  String _getDefaultWinDialogue() => '该你喝酒了！';
  String _getDefaultLoseDialogue() => '你好厉害啊！';

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
}
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/game_state.dart';
import '../models/ai_personality.dart';
import '../models/game_progress.dart';
import 'game_progress_service.dart';
import '../config/api_config.dart';
import '../utils/logger_utils.dart';
import 'bid_options_calculator.dart';
import 'elite_ai_engine.dart';
import 'master_ai_engine.dart';

/// 精简版Gemini服务 - 只保留必要功能
class GeminiService {
  // API配置从配置文件读取
  static String get _apiKey => ApiConfig.geminiApiKey;
  static String get _baseUrl => ApiConfig.geminiEndpoint;
  
  final AIPersonality personality;
  final GameProgressData? playerProfile;
  late final EliteAIEngine eliteEngine;
  late final MasterAIEngine masterEngine;  // 新的大师级AI
  
  GeminiService({required this.personality, this.playerProfile}) {
    eliteEngine = EliteAIEngine(personality: personality);
    masterEngine = MasterAIEngine(personality: personality);  // 初始化大师AI
  }
  
  /// 合并的AI决策方法 - 一次调用完成决策和叫牌
  /// 返回完整的决策信息，包括是否质疑、具体叫牌、表情等
  Future<(AIDecision decision, Bid? newBid, List<String> emotions, String dialogue, bool bluffing, double? playerBluffProb)> makeCompleteDecision(GameRound round) async {
    AILogger.apiCallStart('Gemini', 'makeCompleteDecision');
    GameLogger.logGameState('AI完整决策', details: {
      'currentBid': round.currentBid?.toString(),
      'aiDice': round.aiDice.values.toString(),
    });
    
    // 使用新的Master AI引擎
    var masterDecision = masterEngine.makeDecision(round);
    
    AILogger.logParsing('Master AI决策', {
      'type': masterDecision['type'],
      'confidence': masterDecision['confidence'],
      'strategy': masterDecision['strategy'],
      'reasoning': masterDecision['reasoning'],
    });
    
    // 兼容旧的Elite AI决策格式（如果需要降级）
    var eliteDecision = masterDecision;
    
    // 构建增强的性格化prompt（结合Elite AI的洞察）
    String prompt = _buildEnhancedPersonalityPrompt(round, eliteDecision);
    AILogger.logPrompt(prompt);
    
    try {
      final response = await _callGeminiAPI(prompt);
      AILogger.logResponse(response);
      
      // 解析AI的性格化选择（结合Elite决策）
      final result = _parseEnhancedChoice(response, eliteDecision, round);
      
      AILogger.apiCallSuccess('Gemini', 'personalityDecision', 
        result: result.$1.action == GameAction.challenge ? 'challenge' : result.$2.toString());
      return result;
    } catch (e) {
      AILogger.apiCallError('Gemini', 'personalityDecision', e);
      GameLogger.logGameState('使用Elite AI降级决策');
      
      // 使用Elite AI的决策作为降级
      return _convertEliteDecisionToResult(eliteDecision, round);
    }
  }
  
  /// 构建增强的性格化prompt（使用Elite AI洞察）
  String _buildEnhancedPersonalityPrompt(GameRound round, Map<String, dynamic> eliteDecision) {
    String personalityDesc = _getPersonalityDescription();
    
    // 获取Elite AI的建议
    String eliteAdvice = '';
    if (eliteDecision['type'] == 'challenge') {
      eliteAdvice = '数学分析强烈建议质疑（期望值:${eliteDecision['expectedValue']?.toStringAsFixed(1)})';
    } else {
      Bid? suggestedBid = eliteDecision['bid'];
      eliteAdvice = '推荐叫牌:$suggestedBid (策略:${eliteDecision['strategy']})';
    }
    
    // 心理战术建议
    String psychAdvice = '';
    if (eliteDecision['psychTactic'] != null) {
      psychAdvice = '\n心理战术机会: ${eliteDecision['psychTactic']}';
    }
    
    String prompt = '''你是$personalityDesc

当前游戏状态：
- 你的骰子：${round.aiDice.values.join(',')}
- 对手叫牌：${round.currentBid?.toString() ?? '首轮'}
- 回合数：${round.bidHistory.length}
- 1是否被叫：${round.onesAreCalled ? '是' : '否'}

高级分析建议：
$eliteAdvice$psychAdvice

根据你的性格特点和分析建议，做出决策。输出JSON格式：
{
  "decision": "challenge" 或 "bid",
  "bid": {"quantity": 数量, "value": 点数} (仅在bid时需要),
  "emotions": ["表情1", "表情2"],  // 从thinking/happy/confident/nervous/suspicious中选
  "dialogue": "对话内容",
  "reasoning": "决策理由",
  "bluffing": true/false
}''';
    
    return prompt;
  }
  
  /// 构建性格化决策prompt
  String _buildPersonalityDecisionPrompt(GameRound round) {
    String personalityDesc = _getPersonalityDescription();
    
    Map<int, int> ourCounts = {};
    for (int i = 1; i <= 6; i++) {
      ourCounts[i] = round.aiDice.countValue(i, onesAreCalled: round.onesAreCalled);
    }
    
    List<Map<String, dynamic>> options = BidOptionsCalculator.calculateAllOptions(round, ourCounts);
    
    String optionsText = '';
    for (int i = 0; i < options.length && i < 10; i++) {
      var opt = options[i];
      if (opt['type'] == 'challenge') {
        optionsText += '${i+1}. 质疑 - 成功率${(opt['successRate'] * 100).toStringAsFixed(1)}%\n';
      } else {
        optionsText += '${i+1}. 叫牌${opt['bid']} - 成功率${(opt['successRate'] * 100).toStringAsFixed(1)}%';
        if (opt['strategy'] == 'tactical_bluff') {
          optionsText += ' (战术虚张)';
        }
        optionsText += '\n';
      }
    }
    
    // 游戏历史分析
    String historyInfo = '';
    if (round.bidHistory.length > 2) {
      historyInfo = '\n游戏历史：已进行${round.bidHistory.length}轮叫牌';
      if (round.playerBluffProbabilities.isNotEmpty) {
        double avgBluff = round.getAveragePlayerBluffProbability();
        historyInfo += '，对手平均虚张概率${(avgBluff * 100).toStringAsFixed(1)}%';
      }
    }
    
    String prompt = '''你是$personalityDesc

当前游戏状态：
- 你的骰子：${round.aiDice.values.join(',')}
- 对手叫牌：${round.currentBid?.toString() ?? '首轮'}
- 1是否被叫：${round.onesAreCalled ? '是' : '否'}$historyInfo

可选方案（按成功率排序）：
$optionsText

请根据你的性格特点，从以上方案中选择一个。输出JSON格式：
{
  "choice": 选项编号(1-${options.length}),
  "emotions": ["表情1", "表情2"],  // 1-3个表情，从thinking/happy/confident/nervous/suspicious中选
  "dialogue": "对话内容",
  "reasoning": "选择理由"
}''';
    
    return prompt;
  }
  
  /// 调用Gemini API
  Future<String> _callGeminiAPI(String prompt) async {
    final temperature = personality.id == 'gambler' ? 0.9 : 
                       personality.id == 'provocateur' ? 0.8 : 0.7;
    
    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': 500,
      }
    };
    
    AILogger.logParsing('API参数', {
      'temperature': temperature,
      'maxTokens': 500,
      'promptLength': prompt.length
    });
    
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _apiKey,
      },
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      AILogger.apiCallError('Gemini', 'HTTP ${response.statusCode}', response.body);
      throw Exception('API调用失败: ${response.statusCode}');
    }
  }
  
  /// 解析增强的AI选择（结合Elite决策）
  (AIDecision, Bid?, List<String>, String, bool, double?) _parseEnhancedChoice(
    String response,
    Map<String, dynamic> eliteDecision,
    GameRound round,
  ) {
    try {
      // 清理响应并提取JSON
      String cleanResponse = response;
      if (response.contains('```json')) {
        cleanResponse = response.replaceAll(RegExp(r'```json\s*'), '')
                                .replaceAll(RegExp(r'```'), '');
      }
      
      final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', 
                               multiLine: true, dotAll: true).firstMatch(cleanResponse);
      
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final json = jsonDecode(jsonStr);
        
        AILogger.logParsing('Enhanced选择JSON', json);
        
        // 获取决策类型
        String decision = json['decision'] ?? (eliteDecision['type'] == 'challenge' ? 'challenge' : 'bid');
        
        // 获取表情
        List<String> emotions = [];
        if (json['emotions'] != null && json['emotions'] is List) {
          emotions = List<String>.from(json['emotions']);
        }
        if (emotions.isEmpty) {
          // 根据策略生成默认表情
          if (eliteDecision['strategy'] == 'reverse_trap') {
            emotions = ['nervous', 'thinking'];
          } else if (eliteDecision['strategy'] == 'pressure_play') {
            emotions = ['confident', 'happy'];
          } else {
            emotions = ['thinking'];
          }
        }
        
        // 获取对话
        String dialogue = json['dialogue'] ?? _generateEliteDialogue(eliteDecision);
        String reasoning = json['reasoning'] ?? eliteDecision['reasoning'] ?? '';
        bool bluffing = json['bluffing'] ?? (eliteDecision['strategy']?.contains('bluff') ?? false);
        
        // 构建决策
        if (decision == 'challenge') {
          final aiDecision = AIDecision(
            playerBid: round.currentBid,
            action: GameAction.challenge,
            probability: eliteDecision['confidence'] ?? 0.5,
            wasBluffing: bluffing,
            reasoning: reasoning,
          );
          
          // 估计对手虚张概率
          double playerBluffProb = eliteEngine.opponentModel.estimatedBluffRate;
          
          return (aiDecision, null, emotions, dialogue, false, playerBluffProb);
        } else {
          // 解析叫牌
          Bid newBid;
          if (json['bid'] != null) {
            newBid = Bid(
              quantity: json['bid']['quantity'],
              value: json['bid']['value'],
            );
          } else {
            newBid = eliteDecision['bid'] ?? _fallbackBid(round);
          }
          
          // 验证并调整叫牌（确保API决策遵守规则）
          newBid = _validateAndAdjustBid(newBid, round, eliteDecision);
          
          final aiDecision = AIDecision(
            playerBid: round.currentBid,
            action: GameAction.bid,
            aiBid: newBid,
            probability: eliteDecision['confidence'] ?? 0.5,
            wasBluffing: bluffing,
            reasoning: reasoning,
          );
          
          return (aiDecision, newBid, emotions, dialogue, bluffing, null);
        }
      }
    } catch (e) {
      AILogger.apiCallError('Gemini', '解析增强选择失败', e);
    }
    
    // 降级到Elite决策
    return _convertEliteDecisionToResult(eliteDecision, round);
  }
  
  /// 将Elite决策转换为结果格式
  (AIDecision, Bid?, List<String>, String, bool, double?) _convertEliteDecisionToResult(
    Map<String, dynamic> eliteDecision,
    GameRound round,
  ) {
    // 生成表情
    List<String> emotions = _generateEliteEmotions(eliteDecision);
    
    // 生成对话
    String dialogue = _generateEliteDialogue(eliteDecision);
    
    // 判断是否虚张
    bool isBluffing = eliteDecision['strategy']?.toString().contains('bluff') ?? false;
    
    // 获取Elite AI的所有选项
    List<Map<String, dynamic>>? eliteOptions = eliteDecision['allOptions'] as List<Map<String, dynamic>>?;
    
    if (eliteDecision['type'] == 'challenge') {
      final decision = AIDecision(
        playerBid: round.currentBid,
        action: GameAction.challenge,
        probability: eliteDecision['confidence'] ?? 0.5,
        wasBluffing: false,
        reasoning: eliteDecision['reasoning'] ?? '战术质疑',
        eliteOptions: eliteOptions,
      );
      
      double playerBluffProb = eliteEngine.opponentModel.estimatedBluffRate;
      return (decision, null, emotions, dialogue, false, playerBluffProb);
    } else {
      Bid newBid = eliteDecision['bid'] ?? _fallbackBid(round);
      
      // 验证并调整叫牌（确保本地决策也遵守规则）
      newBid = _validateAndAdjustBid(newBid, round, eliteDecision);
      
      final decision = AIDecision(
        playerBid: round.currentBid,
        action: GameAction.bid,
        aiBid: newBid,
        probability: eliteDecision['confidence'] ?? 0.5,
        wasBluffing: isBluffing,
        reasoning: eliteDecision['reasoning'] ?? '战术叫牌',
        eliteOptions: eliteOptions,
      );
      
      return (decision, newBid, emotions, dialogue, isBluffing, null);
    }
  }
  
  /// 根据Elite策略生成表情
  List<String> _generateEliteEmotions(Map<String, dynamic> eliteDecision) {
    String strategy = eliteDecision['strategy'] ?? '';
    
    // 支持新的Master AI策略
    switch (strategy) {
      case 'aggressive':
        return ['confident', 'happy'];
      case 'conservative':
        return ['thinking', 'nervous'];
      case 'trap':
        return ['nervous', 'thinking']; // 故意示弱
      case 'pressure':
        return ['confident', 'suspicious'];
      case 'probe':
        return ['thinking', 'happy'];
      case 'balanced':
        return ['thinking', 'confident'];
      case 'forced':
        return ['nervous'];
      case 'absolute_rule':
        return ['confident'];
      // 兼容旧的Elite AI策略
      case 'reverse_trap':
        return ['nervous', 'thinking'];
      case 'pressure_play':
        return ['confident', 'suspicious'];
      case 'value_bet':
        return ['confident', 'happy'];
      case 'pure_bluff':
        return ['thinking', 'nervous'];
      case 'style_switch_aggressive':
        return ['confident', 'happy'];
      default:
        double confidence = eliteDecision['confidence'] ?? 0.5;
        if (confidence > 0.8) return ['confident'];
        if (confidence > 0.6) return ['thinking', 'happy'];
        if (confidence > 0.4) return ['thinking'];
        return ['nervous', 'thinking'];
    }
  }
  
  /// 根据Elite策略生成对话
  String _generateEliteDialogue(Map<String, dynamic> eliteDecision) {
    String strategy = eliteDecision['strategy'] ?? '';
    String psychEffect = eliteDecision['psychEffect'] ?? '';
    
    // 心理效果对话（Master AI的新字段）
    if (psychEffect.isNotEmpty) {
      switch (psychEffect) {
        case 'intimidation':
          return '压力来了！';
        case 'fake_weakness':
          return '我...不太确定';
        case 'sudden_escalation':
          return '玩大点！';
      }
    }
    
    // 策略对话（支持新的Master AI策略）
    switch (strategy) {
      case 'aggressive':
        return '来真的！';
      case 'conservative':
        return '稳一点';
      case 'trap':
        return '嗯...';
      case 'pressure':
        return '你跟吗？';
      case 'probe':
        return '看看你';
      case 'balanced':
        return '继续';
      case 'forced':
        return '只能这样';
      case 'absolute_rule':
        return '必须的';
      // 兼容旧策略
      case 'value_bet':
        return '稳稳的';
      case 'semi_bluff':
        return '试试看';
      case 'bluff':
        return '就这样';
      case 'pure_bluff':
        return '全押了';
      case 'emergency':
        return '继续';
      default:
        if (eliteDecision['type'] == 'challenge') {
          return '不可能吧';
        }
        return '我叫${eliteDecision['bid']}';
    }
  }
  
  /// 解析AI的性格化选择（简化版）
  (AIDecision, Bid?, List<String>, String, bool, double?) _parsePersonalityChoice(
    String response, 
    List<Map<String, dynamic>> options,
    GameRound round
  ) {
    try {
      // 清理响应并提取JSON
      String cleanResponse = response;
      if (response.contains('```json')) {
        cleanResponse = response.replaceAll(RegExp(r'```json\s*'), '')
                                .replaceAll(RegExp(r'```'), '');
      }
      
      final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', 
                               multiLine: true, dotAll: true).firstMatch(cleanResponse);
      
      if (jsonMatch != null && options.isNotEmpty) {
        final jsonStr = jsonMatch.group(0)!;
        final json = jsonDecode(jsonStr);
        
        AILogger.logParsing('选择JSON', json);
        
        // 获取选择的选项
        int choiceIndex = (json['choice'] as int) - 1;
        if (choiceIndex < 0 || choiceIndex >= options.length) {
          choiceIndex = 0; // 默认选择最优
        }
        
        var chosenOption = options[choiceIndex];
        
        // 获取表情
        List<String> emotions = [];
        if (json['emotions'] != null && json['emotions'] is List) {
          emotions = List<String>.from(json['emotions']);
        }
        if (emotions.isEmpty) {
          emotions = ['thinking'];
        }
        
        // 获取对话
        String dialogue = json['dialogue'] ?? '';
        String reasoning = json['reasoning'] ?? chosenOption['reasoning'] ?? '';
        
        // 构建决策
        if (chosenOption['type'] == 'challenge') {
          final decision = AIDecision(
            playerBid: round.currentBid,
            action: GameAction.challenge,
            probability: 1.0 - chosenOption['successRate'],
            wasBluffing: false,
            reasoning: reasoning,
          );
          return (decision, null, emotions, dialogue, false, null);
        } else {
          Bid newBid = chosenOption['bid'];
          bool isBluffing = chosenOption['strategy'] == 'tactical_bluff';
          
          final decision = AIDecision(
            playerBid: round.currentBid,
            action: GameAction.bid,
            aiBid: newBid,
            probability: chosenOption['successRate'],
            wasBluffing: isBluffing,
            reasoning: reasoning,
          );
          return (decision, newBid, emotions, dialogue, isBluffing, null);
        }
      }
    } catch (e) {
      AILogger.apiCallError('Gemini', '解析选择失败', e);
    }
    
    // 降级处理
    GameLogger.logGameState('使用降级逻辑');
    final decision = _fallbackDecision(round);
    if (decision.action == GameAction.challenge) {
      return (decision, null, ['thinking'], '', false, null);
    } else {
      final bid = _fallbackBid(round);
      final updatedDecision = AIDecision(
        playerBid: round.currentBid,
        action: GameAction.bid,
        aiBid: bid,
        probability: decision.probability,
        wasBluffing: false,
        reasoning: decision.reasoning,
      );
      return (updatedDecision, bid, ['thinking'], '', false, null);
    }
  }
  
  /// 降级决策（当API失败时）
  AIDecision _fallbackDecision(GameRound round) {
    // 使用BidOptionsCalculator计算选项
    Map<int, int> ourCounts = {};
    for (int i = 1; i <= 6; i++) {
      ourCounts[i] = round.aiDice.countValue(i, onesAreCalled: round.onesAreCalled);
    }
    
    List<Map<String, dynamic>> options = BidOptionsCalculator.calculateAllOptions(round, ourCounts);
    
    // 基于性格选择
    for (var option in options) {
      if (option['type'] == 'challenge') {
        if (option['successRate'] > personality.challengeThreshold) {
          return AIDecision(
            playerBid: round.currentBid,
            action: GameAction.challenge,
            probability: 1.0 - option['successRate'],
            wasBluffing: false,
            reasoning: '概率分析建议质疑',
          );
        }
      }
    }
    
    // 默认叫牌
    Bid bestBid = _fallbackBid(round);
    return AIDecision(
      playerBid: round.currentBid,
      action: GameAction.bid,
      aiBid: bestBid,
      probability: 0.5,
      wasBluffing: false,
      reasoning: '继续叫牌',
    );
  }
  
  /// 降级叫牌（当API失败时）
  Bid _fallbackBid(GameRound round) {
    Bid? lastBid = round.currentBid;
    
    if (lastBid == null) {
      // 首轮叫牌
      Map<int, int> counts = {};
      for (int i = 1; i <= 6; i++) {
        counts[i] = round.aiDice.countValue(i, onesAreCalled: false);
      }
      
      // 找出最多的点数
      int maxCount = 0;
      int bestValue = 1;
      counts.forEach((value, count) {
        if (count > maxCount) {
          maxCount = count;
          bestValue = value;
        }
      });
      
      // 基于性格调整数量
      int quantity = maxCount;
      if (personality.bluffRatio > 0.5 && quantity < 3) {
        quantity = math.min(3, quantity + 1);
      }
      
      return Bid(quantity: math.max(2, quantity), value: bestValue);
    }
    
    // 后续叫牌 - 使用BidOptionsCalculator
    Map<int, int> ourCounts = {};
    for (int i = 1; i <= 6; i++) {
      ourCounts[i] = round.aiDice.countValue(i, onesAreCalled: round.onesAreCalled);
    }
    
    List<Map<String, dynamic>> options = BidOptionsCalculator.calculateAllOptions(round, ourCounts);
    
    // 找最佳叫牌选项
    for (var option in options) {
      if (option['type'] == 'bid' && option['bid'] != null) {
        Bid bid = option['bid'];
        if (bid.isHigherThan(lastBid, onesAreCalled: round.onesAreCalled)) {
          return bid;
        }
      }
    }
    
    // 如果没有找到合适的，生成一个保守的叫牌
    if (lastBid.value < 6) {
      return Bid(quantity: lastBid.quantity, value: lastBid.value + 1);
    } else {
      return Bid(quantity: lastBid.quantity + 1, value: 1);
    }
  }
  
  /// 验证并调整叫牌（确保遵守改进后的规则）
  Bid _validateAndAdjustBid(Bid bid, GameRound round, Map<String, dynamic> decision) {
    int currentQty = round.currentBid?.quantity ?? 0;
    String strategy = decision['strategy'] ?? '';
    
    // 规则1：限制增幅
    if (bid.quantity > currentQty) {
      int increase = bid.quantity - currentQty;
      int maxIncrease;
      
      // 根据当前数量和策略确定最大增幅
      if (currentQty < 3) {
        // 早期
        if (strategy == 'aggressive' || strategy == 'pressure') {
          maxIncrease = 2;  // 激进策略可以跳2
        } else {
          maxIncrease = 1;  // 其他策略最多加1
        }
      } else if (currentQty < 5) {
        // 中期
        maxIncrease = 1;  // 中期都只能加1
      } else {
        // 后期
        maxIncrease = 1;  // 后期必须谨慎
        
        // 压力策略在后期应该转质疑
        if (strategy == 'pressure' && currentQty >= 6) {
          // 这种情况本应质疑，但如果已经决定叫牌，限制增幅
          maxIncrease = 1;
        }
      }
      
      // 应用限制
      if (increase > maxIncrease) {
        AILogger.logParsing('叫牌验证', {
          'original': '${bid.quantity}个${bid.value}',
          'currentQty': currentQty,
          'increase': increase,
          'maxIncrease': maxIncrease,
          'adjusted': '${currentQty + maxIncrease}个${bid.value}',
        });
        
        bid = Bid(quantity: currentQty + maxIncrease, value: bid.value);
      }
    }
    
    // 规则2：总量检查
    if (bid.quantity >= 7) {
      // 计算对手需要多少个
      int opponentNeeds = bid.quantity - (round.aiDice.countValue(bid.value, onesAreCalled: round.onesAreCalled));
      
      if (opponentNeeds >= 4) {
        // 总量不合理，降低到6
        AILogger.logParsing('总量检查', {
          'original': '${bid.quantity}个${bid.value}',
          'opponentNeeds': opponentNeeds,
          'adjusted': '6个${bid.value}',
          'reason': '总量过高',
        });
        
        bid = Bid(quantity: 6, value: bid.value);
      }
    }
    
    // 规则3：确保叫牌合法（必须高于当前叫牌）
    if (round.currentBid != null && !bid.isHigherThan(round.currentBid!, onesAreCalled: round.onesAreCalled)) {
      // 如果调整后的叫牌不合法，生成最小合法叫牌
      if (round.currentBid!.value < 6) {
        bid = Bid(quantity: round.currentBid!.quantity, value: round.currentBid!.value + 1);
      } else {
        bid = Bid(quantity: round.currentBid!.quantity + 1, value: 1);
      }
      
      AILogger.logParsing('合法性调整', {
        'adjusted': '${bid.quantity}个${bid.value}',
        'reason': '确保高于当前叫牌',
      });
    }
    
    return bid;
  }
  
  /// 获取性格描述
  String _getPersonalityDescription() {
    switch (personality.id) {
      case '0001':
      case 'professor':
        return '稳重大叔，理性冷静，精于计算，很少虚张声势';
      case '0002':
      case 'gambler':
        return '冲动小哥，喜欢冒险，经常虚张声势，激进大胆';
      case '0003':
      case 'provocateur':
        return '心机御姐，善于心理战，经常误导对手，表里不一';
      case '0004':
      case 'youngwoman':
        return '活泼少女，直觉敏锐，偶尔任性，变化多端';
      case '1001':
      case 'aki':
        return '温柔可爱的日本少女，表面天真但暗藏心机';
      case '1002':
      case 'katerina':
        return '冷艳高贵的俄罗斯美女，算无遗策，深不可测';
      case '1003':
      case 'lena':
        return '严谨理性的德国女郎，精确计算，很少失误';
      default:
        return '神秘角色';
    }
  }
  
  /// 生成对话和表情（如果需要保留）
  Future<(String dialogue, String expression)> generateDialogue(
    GameRound round,
    String action,
    {Bid? newBid}
  ) async {
    String prompt = '''你是${personality.name}，${personality.description}。

当前状态：
- 动作：$action
${newBid != null ? '- 叫牌：$newBid' : ''}
- 回合：第${round.bidHistory.length}轮

请生成：
1. 符合性格的一句对话（10字以内）
2. 表情（happy/confident/nervous/thinking/suspicious之一）

输出JSON格式：
{
  "dialogue": "对话",
  "expression": "表情"
}''';
    
    try {
      final response = await _callGeminiAPI(prompt);
      final json = jsonDecode(response);
      return (json['dialogue']?.toString() ?? '', json['expression']?.toString() ?? 'thinking');
    } catch (e) {
      return Future.value(('', 'thinking'));
    }
  }
}
/// Gemini API服务 - 重构简化版
/// 
/// 负责与Gemini API交互，获取AI决策
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/game_state.dart';
import '../../models/ai_personality.dart';
import '../../utils/logger_utils.dart';
import '../../config/api_config.dart';
import '../ai/prompts/gemini_prompts.dart';
import '../ai/engines/elite_engine.dart';
import '../ai/engines/master_engine.dart' as master;

class GeminiService {
  final AIPersonality personality;
  late final EliteAIEngine eliteEngine;
  late final master.MasterAIEngine masterEngine;
  
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  // API配置
  final bool useRealAPI = ApiConfig.useRealAI;
  final String apiKey = ApiConfig.geminiApiKey;
  
  // 请求计数器（速率限制）
  int _requestCount = 0;
  DateTime _lastResetTime = DateTime.now();
  
  GeminiService({required this.personality}) {
    eliteEngine = EliteAIEngine(personality: personality);
    masterEngine = master.MasterAIEngine(personality: personality);
  }
  
  /// 获取AI决策
  Future<AIDecision> getDecision(GameRound round, dynamic playerFaceData) async {
    try {
      // 检查是否使用真实API
      if (!useRealAPI || apiKey == 'YOUR_API_KEY_HERE') {
        return _getLocalDecision(round);
      }
      
      // 速率限制检查
      if (!_checkRateLimit()) {
        AILogger.apiCallError('Gemini', '超过速率限制', 'Rate limit exceeded');
        return _getLocalDecision(round);
      }
      
      // 获取Elite和Master的建议
      var eliteDecision = eliteEngine.makeEliteDecision(round);
      var masterDecision = masterEngine.makeDecision(round);
      
      // 构建prompt
      String prompt = _buildPrompt(round, eliteDecision, masterDecision);
      
      // 调用API
      var response = await _callGeminiAPI(prompt);
      
      // 解析响应
      return _parseAPIResponse(response, round, eliteDecision);
      
    } catch (e) {
      AILogger.apiCallError('Gemini', '调用失败', e);
      return _getLocalDecision(round);
    }
  }
  
  /// 构建API提示词
  String _buildPrompt(
    GameRound round,
    Map<String, dynamic> eliteDecision,
    Map<String, dynamic> masterDecision,
  ) {
    String personalityDesc = GeminiPrompts.buildPersonalityDescription(
      personality.name,
      personality.description,
      personality.bluffRatio,
      personality.challengeThreshold,
      personality.riskAppetite,
    );
    
    // 构建Elite建议文本
    String eliteAdvice = '';
    if (eliteDecision['type'] == 'challenge') {
      eliteAdvice = 'Elite AI建议：质疑（置信度${eliteDecision['confidence']}）\n';
    } else if (eliteDecision['bid'] != null) {
      eliteAdvice = 'Elite AI建议：叫牌${eliteDecision['bid']}（置信度${eliteDecision['confidence']}）\n';
    }
    
    // 心理分析（简化）
    String psychAdvice = round.bidHistory.length > 3 ? 
      '\n心理分析：对手可能在${round.bidHistory.length > 5 ? "施压" : "试探"}' : '';
    
    return GeminiPrompts.getAdvancedDecisionPrompt(
      personalityDesc: personalityDesc,
      aiDiceValues: round.aiDice.values.join(','),
      currentBid: round.currentBid?.toString() ?? '首轮',
      roundNumber: round.bidHistory.length,
      onesAreCalled: round.onesAreCalled,
      eliteAdvice: eliteAdvice,
      psychAdvice: psychAdvice,
    );
  }
  
  /// 调用Gemini API
  Future<String> _callGeminiAPI(String prompt) async {
    final url = Uri.parse('$_baseUrl?key=$apiKey');
    
    final requestBody = {
      'contents': [{
        'parts': [{
          'text': '${GeminiPrompts.gameRulesContext}\n\n$prompt'
        }]
      }],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 500,
      }
    };
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      _requestCount++;
      return response.body;
    } else {
      throw Exception('API返回错误: ${response.statusCode}');
    }
  }
  
  /// 解析API响应
  AIDecision _parseAPIResponse(
    String response,
    GameRound round,
    Map<String, dynamic> eliteDecision,
  ) {
    try {
      final data = jsonDecode(response);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      
      // 提取JSON
      final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}').firstMatch(text);
      if (jsonMatch == null) {
        throw Exception('无法解析API响应');
      }
      
      final json = jsonDecode(jsonMatch.group(0)!);
      
      // 构建决策
      if (json['decision'] == 'challenge' || json['action'] == 'challenge') {
        return AIDecision(
          playerBid: round.currentBid,
          action: GameAction.challenge,
          probability: json['confidence'] ?? 0.5,
          wasBluffing: false,
          reasoning: json['reasoning'] ?? '战术质疑',
          eliteOptions: eliteDecision['allOptions'],
        );
      } else {
        Bid newBid;
        if (json['bid'] != null) {
          newBid = Bid(
            quantity: json['bid']['quantity'],
            value: json['bid']['value'],
          );
        } else {
          // 降级处理
          newBid = _generateFallbackBid(round);
        }
        
        return AIDecision(
          playerBid: round.currentBid,
          action: GameAction.bid,
          aiBid: newBid,
          probability: json['confidence'] ?? 0.5,
          wasBluffing: json['bluffing'] ?? false,
          reasoning: json['reasoning'] ?? '战术叫牌',
          eliteOptions: eliteDecision['allOptions'],
        );
      }
    } catch (e) {
      AILogger.logParsing('解析API响应失败', {'error': e.toString()});
      rethrow;
    }
  }
  
  /// 本地决策（降级方案）
  AIDecision _getLocalDecision(GameRound round) {
    // 使用Master AI作为降级方案
    var masterDecision = masterEngine.makeDecision(round);
    var eliteDecision = eliteEngine.makeEliteDecision(round);
    
    if (masterDecision['type'] == 'challenge') {
      return AIDecision(
        playerBid: round.currentBid,
        action: GameAction.challenge,
        probability: masterDecision['confidence'] ?? 0.5,
        wasBluffing: false,
        reasoning: masterDecision['reasoning'] ?? '本地AI质疑',
        eliteOptions: eliteDecision['allOptions'],
      );
    } else {
      Bid newBid = masterDecision['bid'] ?? _generateFallbackBid(round);
      
      return AIDecision(
        playerBid: round.currentBid,
        action: GameAction.bid,
        aiBid: newBid,
        probability: masterDecision['confidence'] ?? 0.5,
        wasBluffing: (masterDecision['strategy'] ?? '').contains('bluff'),
        reasoning: masterDecision['reasoning'] ?? '本地AI叫牌',
        eliteOptions: eliteDecision['allOptions'],
      );
    }
  }
  
  /// 生成降级叫牌
  Bid _generateFallbackBid(GameRound round) {
    if (round.currentBid == null) {
      return Bid(quantity: 2, value: 3);
    }
    
    return Bid(
      quantity: round.currentBid!.quantity + 1,
      value: round.currentBid!.value,
    );
  }
  
  /// 检查速率限制
  bool _checkRateLimit() {
    final now = DateTime.now();
    
    // 每分钟重置
    if (now.difference(_lastResetTime).inMinutes >= 1) {
      _requestCount = 0;
      _lastResetTime = now;
    }
    
    // 免费层限制：60次/分钟
    return _requestCount < 60;
  }
  
  /// 重置服务（新游戏）
  void reset() {
    eliteEngine.reset();
    masterEngine.reset();
    _requestCount = 0;
    _lastResetTime = DateTime.now();
  }
}
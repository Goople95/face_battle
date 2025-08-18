/// 统一的AI服务接口
/// 
/// 提供统一的AI决策接口，自动选择最佳的AI引擎

import '../../models/game_state.dart';
import '../../models/ai_personality.dart';
import '../../config/api_config.dart';
import '../../utils/logger_utils.dart';
import '../gemini_service_v2.dart';
import '../ai_service.dart';

/// AI服务模式
enum AIMode {
  local,    // 本地AI（Master + Elite）
  api,      // API模式（Gemini）
  auto,     // 自动选择
}

/// 统一AI服务
class UnifiedAIService {
  final AIPersonality personality;
  final AIMode mode;
  
  late final AIService localService;
  late final GeminiService apiService;
  
  // 性能统计
  int localCalls = 0;
  int apiCalls = 0;
  int apiFailures = 0;
  
  UnifiedAIService({
    required this.personality,
    this.mode = AIMode.auto,
  }) {
    localService = AIService(personality: personality);
    apiService = GeminiService(personality: personality);
  }
  
  /// 获取AI决策
  Future<AIDecision> makeDecision(GameRound round, {dynamic playerFaceData}) async {
    AILogger.logParsing('统一AI服务', {
      'mode': mode.toString(),
      'personality': personality.id,
      'round': round.bidHistory.length,
    });
    
    // 根据模式选择服务
    switch (mode) {
      case AIMode.local:
        return _useLocalAI(round, playerFaceData);
        
      case AIMode.api:
        return _useAPIWithFallback(round, playerFaceData);
        
      case AIMode.auto:
      default:
        return _autoSelectService(round, playerFaceData);
    }
  }
  
  /// 使用本地AI
  Future<AIDecision> _useLocalAI(GameRound round, dynamic playerFaceData) async {
    localCalls++;
    
    try {
      final decision = localService.decideAction(round, playerFaceData);
      
      AILogger.logParsing('本地AI决策', {
        'action': decision.action.toString(),
        'confidence': decision.probability,
      });
      
      return decision;
    } catch (e) {
      AILogger.logParsing('本地AI错误', {'error': e.toString()});
      rethrow;
    }
  }
  
  /// 使用API（带降级）
  Future<AIDecision> _useAPIWithFallback(GameRound round, dynamic playerFaceData) async {
    apiCalls++;
    
    try {
      final decision = await apiService.getDecision(round, playerFaceData);
      
      AILogger.logParsing('API决策成功', {
        'action': decision.action.toString(),
        'confidence': decision.probability,
      });
      
      return decision;
    } catch (e) {
      apiFailures++;
      
      AILogger.apiCallError('UnifiedAI', 'API失败，降级到本地', e);
      
      // 降级到本地AI
      return _useLocalAI(round, playerFaceData);
    }
  }
  
  /// 自动选择服务
  Future<AIDecision> _autoSelectService(GameRound round, dynamic playerFaceData) async {
    // 检查API是否可用
    bool apiAvailable = ApiConfig.useRealAI && 
                       ApiConfig.geminiApiKey != 'YOUR_API_KEY_HERE';
    
    // 检查API失败率
    double failureRate = apiCalls > 0 ? apiFailures / apiCalls : 0;
    bool apiReliable = failureRate < 0.3;
    
    // 决策逻辑
    if (apiAvailable && apiReliable) {
      // 重要回合使用API
      bool isImportantRound = round.bidHistory.length > 5 || 
                             (round.currentBid?.quantity ?? 0) >= 7;
      
      if (isImportantRound) {
        return _useAPIWithFallback(round, playerFaceData);
      }
    }
    
    // 默认使用本地AI
    return _useLocalAI(round, playerFaceData);
  }
  
  /// 获取服务统计
  Map<String, dynamic> getStatistics() {
    return {
      'localCalls': localCalls,
      'apiCalls': apiCalls,
      'apiFailures': apiFailures,
      'apiFailureRate': apiCalls > 0 ? apiFailures / apiCalls : 0,
      'primaryService': apiCalls > localCalls ? 'API' : 'Local',
    };
  }
  
  /// 重置服务
  void reset() {
    localService = AIService(personality: personality);
    apiService.reset();
    
    // 重置统计
    localCalls = 0;
    apiCalls = 0;
    apiFailures = 0;
  }
  
  /// 切换模式
  void switchMode(AIMode newMode) {
    AILogger.logParsing('切换AI模式', {
      'from': mode.toString(),
      'to': newMode.toString(),
    });
  }
}
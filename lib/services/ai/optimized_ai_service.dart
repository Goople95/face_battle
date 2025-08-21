/// 优化后的统一AI服务
/// 
/// 整合所有优化：缓存、配置管理、调试工具
library;

import 'dart:async';
import '../../models/game_state.dart';
import '../../models/ai_personality.dart';
import '../../utils/logger_utils.dart';
import 'engines/master_engine.dart';
import 'engines/elite_engine.dart';
import 'cache/decision_cache.dart';
import 'config/ai_config_manager.dart';
import 'debug/ai_debugger.dart';
import 'components/bid_calculator.dart';

/// 优化的AI服务
class OptimizedAIService {
  final AIPersonality personality;
  
  // 引擎
  late final MasterAIEngine masterEngine;
  late final EliteAIEngine eliteEngine;
  
  // 管理器
  final DecisionCache cache = DecisionCache();
  final AIConfigManager config = AIConfigManager();
  
  // 性能监控
  final Stopwatch _stopwatch = Stopwatch();
  
  OptimizedAIService({required this.personality}) {
    // 直接使用原始性格，不再调整难度
    masterEngine = MasterAIEngine(personality: personality);
    eliteEngine = EliteAIEngine(personality: personality);
    
    config.currentPersonality = personality;
  }
  
  /// 获取AI决策（带所有优化）
  Future<AIDecision> makeDecision(GameRound round, {dynamic playerFaceData}) async {
    _stopwatch.reset();
    _stopwatch.start();
    
    try {
      // 1. 检查缓存
      var cached = cache.get(round);
      if (cached != null) {
        _stopwatch.stop();
        
        config.stats.recordCacheHit();
        PerformanceMonitor.record('cache_hit', _stopwatch.elapsedMilliseconds);
        
        AILogger.logParsing('缓存命中', {
          'time': _stopwatch.elapsedMilliseconds,
          'hitRate': cache.hitRate,
        });
        
        return _buildDecision(cached, round);
      }
      
      // 2. 生成新决策
      Map<String, dynamic> decision;
      
      // 使用Master引擎
      decision = await _makeMasterDecision(round);
      
      // 3. 缓存决策
      cache.put(round, decision);
      
      // 4. 记录性能
      _stopwatch.stop();
      config.stats.recordResponseTime(_stopwatch.elapsed);
      PerformanceMonitor.record('decision_time', _stopwatch.elapsedMilliseconds);
      
      // 5. 调试输出
      if (AIDebugger.enabled) {
        AIDebugger.logDecision(
          engine: 'Master',
          round: round,
          decision: decision,
          processingTime: _stopwatch.elapsed,
          extra: {
            'cacheSize': cache.size,
            'hitRate': cache.hitRate,
          },
        );
      }
      
      return _buildDecision(decision, round);
      
    } catch (e) {
      _stopwatch.stop();
      
      AILogger.apiCallError('OptimizedAI', '决策失败', e);
      
      // 紧急降级
      return _emergencyFallback(round);
    }
  }
  
  /// 使用Master引擎决策
  Future<Map<String, dynamic>> _makeMasterDecision(GameRound round) async {
    var decision = masterEngine.makeDecision(round);
    return decision;
  }
  
  /// 使用Elite引擎决策
  Future<Map<String, dynamic>> _makeEliteDecision(GameRound round) async {
    var decision = eliteEngine.makeEliteDecision(round);
    
    // 专家模式增强
    if (decision['confidence'] != null) {
      decision['confidence'] = (decision['confidence'] * 1.1).clamp(0.0, 1.0);
    }
    
    return decision;
  }
  
  /// 构建最终决策
  AIDecision _buildDecision(Map<String, dynamic> decision, GameRound round) {
    // 生成选项列表（用于UI显示）
    var options = decision['allOptions'] ?? BidCalculator.calculateOptions(round);
    
    // 构建决策对象
    if (decision['type'] == 'challenge') {
      return AIDecision(
        playerBid: round.currentBid,
        action: GameAction.challenge,
        probability: decision['confidence'] ?? 0.5,
        wasBluffing: false,
        reasoning: decision['reasoning'] ?? '战术决策',
        eliteOptions: options,
      );
    } else {
      Bid bid = decision['bid'] ?? _generateSafeBid(round);
      
      return AIDecision(
        playerBid: round.currentBid,
        action: GameAction.bid,
        aiBid: bid,
        probability: decision['confidence'] ?? 0.5,
        wasBluffing: (decision['strategy'] ?? '').contains('bluff'),
        reasoning: decision['reasoning'] ?? '战术叫牌',
        eliteOptions: options,
      );
    }
  }
  
  /// 紧急降级决策
  AIDecision _emergencyFallback(GameRound round) {
    if (round.currentBid == null) {
      return AIDecision(
        playerBid: null,
        action: GameAction.bid,
        aiBid: Bid(quantity: 2, value: 3),
        probability: 0.5,
        wasBluffing: false,
        reasoning: '紧急开局',
        eliteOptions: [],
      );
    }
    
    // 50%概率质疑
    if (DateTime.now().millisecondsSinceEpoch % 2 == 0) {
      return AIDecision(
        playerBid: round.currentBid,
        action: GameAction.challenge,
        probability: 0.5,
        wasBluffing: false,
        reasoning: '紧急质疑',
        eliteOptions: [],
      );
    }
    
    // 最小增量叫牌
    return AIDecision(
      playerBid: round.currentBid,
      action: GameAction.bid,
      aiBid: Bid(
        quantity: round.currentBid!.quantity + 1,
        value: round.currentBid!.value,
      ),
      probability: 0.5,
      wasBluffing: false,
      reasoning: '紧急叫牌',
      eliteOptions: [],
    );
  }
  
  /// 生成安全叫牌
  Bid _generateSafeBid(GameRound round) {
    if (round.currentBid == null) {
      return Bid(quantity: 2, value: 3);
    }
    
    return Bid(
      quantity: round.currentBid!.quantity + 1,
      value: round.currentBid!.value,
    );
  }
  
  /// 随机决策（用于简单模式）
  Map<String, dynamic> _makeRandomDecision(GameRound round) {
    if (round.currentBid != null && DateTime.now().millisecondsSinceEpoch % 3 == 0) {
      return {
        'type': 'challenge',
        'confidence': 0.5,
        'strategy': 'random',
        'reasoning': '随机质疑',
      };
    }
    
    int qty = round.currentBid?.quantity ?? 1;
    int val = round.currentBid?.value ?? 1;
    
    return {
      'type': 'bid',
      'bid': Bid(quantity: qty + 1, value: val),
      'confidence': 0.5,
      'strategy': 'random',
      'reasoning': '随机叫牌',
    };
  }
  
  
  /// 启用/禁用调试
  void setDebugMode(bool enabled) {
    config.debugMode = enabled;
    AIDebugger.setEnabled(enabled);
  }
  
  /// 获取统计信息
  Map<String, dynamic> getStatistics() {
    return {
      'config': config.toJson(),
      'cache': cache.getStats(),
      'debug': AIDebugger.analyzePatterns(),
      'performance': {
        'avgResponseTime': config.stats.averageResponseTime,
        'cacheHitRate': config.stats.cacheHitRate,
        'accuracy': config.stats.accuracy,
      },
    };
  }
  
  /// 重置服务
  void reset() {
    masterEngine.reset();
    eliteEngine.reset();
    cache.clear();
    config.reset();
    AIDebugger.clearHistory();
    PerformanceMonitor.clear();
  }
}
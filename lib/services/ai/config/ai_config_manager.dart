/// AI配置管理器
/// 
/// 集中管理所有AI相关配置
library;

import '../../../models/ai_personality.dart';

class AIConfigManager {
  // 单例模式
  static final AIConfigManager _instance = AIConfigManager._internal();
  factory AIConfigManager() => _instance;
  AIConfigManager._internal();
  
  // ============= 全局配置 =============
  
  /// AI模式配置
  bool useCloudAI = false;
  bool enableFallback = true;
  bool debugMode = false;
  
  /// 性能配置
  int maxCacheSize = 100;
  Duration cacheExpiration = Duration(minutes: 5);
  int maxRetries = 3;
  Duration apiTimeout = Duration(seconds: 10);
  
  /// 决策阈值配置
  final DecisionThresholds thresholds = DecisionThresholds();
  
  // ============= 运行时配置 =============
  
  /// 当前使用的性格
  AIPersonality? currentPersonality;
  
  /// 性能统计
  final PerformanceStats stats = PerformanceStats();
  
  // ============= 方法 =============
  
  
  /// 重置配置
  void reset() {
    useCloudAI = false;
    enableFallback = true;
    debugMode = false;
    thresholds.reset();
    stats.reset();
  }
  
  /// 导出配置
  Map<String, dynamic> toJson() {
    return {
      'useCloudAI': useCloudAI,
      'enableFallback': enableFallback,
      'debugMode': debugMode,
      'thresholds': thresholds.toJson(),
      'stats': stats.toJson(),
    };
  }
  
  /// 导入配置
  void fromJson(Map<String, dynamic> json) {
    useCloudAI = json['useCloudAI'] ?? false;
    enableFallback = json['enableFallback'] ?? true;
    debugMode = json['debugMode'] ?? false;
  }
}

/// 决策阈值
class DecisionThresholds {
  double challengeThreshold = 0.5;  // 质疑阈值
  double bluffThreshold = 0.4;      // 诈唬阈值
  double riskThreshold = 0.5;       // 风险承受阈值
  double confidenceMin = 0.2;       // 最低置信度
  
  void reset() {
    challengeThreshold = 0.5;
    bluffThreshold = 0.4;
    riskThreshold = 0.5;
    confidenceMin = 0.2;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'challengeThreshold': challengeThreshold,
      'bluffThreshold': bluffThreshold,
      'riskThreshold': riskThreshold,
      'confidenceMin': confidenceMin,
    };
  }
}

/// 性能统计
class PerformanceStats {
  int totalDecisions = 0;
  int correctDecisions = 0;
  int apiCalls = 0;
  int cacheHits = 0;
  double averageResponseTime = 0;
  
  List<double> responseTimes = [];
  
  void recordDecision(bool correct) {
    totalDecisions++;
    if (correct) correctDecisions++;
  }
  
  void recordApiCall() {
    apiCalls++;
  }
  
  void recordCacheHit() {
    cacheHits++;
  }
  
  void recordResponseTime(Duration time) {
    responseTimes.add(time.inMilliseconds.toDouble());
    if (responseTimes.length > 100) {
      responseTimes.removeAt(0);
    }
    
    // 计算平均响应时间
    if (responseTimes.isNotEmpty) {
      double sum = responseTimes.reduce((a, b) => a + b);
      averageResponseTime = sum / responseTimes.length;
    }
  }
  
  double get accuracy => totalDecisions > 0 ? correctDecisions / totalDecisions : 0;
  double get cacheHitRate => (apiCalls + cacheHits) > 0 ? cacheHits / (apiCalls + cacheHits) : 0;
  
  void reset() {
    totalDecisions = 0;
    correctDecisions = 0;
    apiCalls = 0;
    cacheHits = 0;
    averageResponseTime = 0;
    responseTimes.clear();
  }
  
  Map<String, dynamic> toJson() {
    return {
      'totalDecisions': totalDecisions,
      'accuracy': accuracy,
      'apiCalls': apiCalls,
      'cacheHitRate': cacheHitRate,
      'averageResponseTime': averageResponseTime,
    };
  }
}
/// AI配置管理器
/// 
/// 集中管理所有AI相关配置

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
  
  /// 难度配置
  DifficultyLevel difficulty = DifficultyLevel.medium;
  
  // ============= 运行时配置 =============
  
  /// 当前使用的性格
  AIPersonality? currentPersonality;
  
  /// 性能统计
  final PerformanceStats stats = PerformanceStats();
  
  // ============= 方法 =============
  
  /// 根据难度调整AI参数
  void applyDifficulty(DifficultyLevel level) {
    difficulty = level;
    
    switch (level) {
      case DifficultyLevel.easy:
        thresholds.challengeThreshold = 0.7;  // 更容易质疑
        thresholds.bluffThreshold = 0.6;      // 更少诈唬
        thresholds.riskThreshold = 0.3;       // 更保守
        break;
        
      case DifficultyLevel.medium:
        thresholds.challengeThreshold = 0.5;
        thresholds.bluffThreshold = 0.4;
        thresholds.riskThreshold = 0.5;
        break;
        
      case DifficultyLevel.hard:
        thresholds.challengeThreshold = 0.3;  // 更难质疑
        thresholds.bluffThreshold = 0.2;      // 更多诈唬
        thresholds.riskThreshold = 0.7;       // 更激进
        break;
        
      case DifficultyLevel.expert:
        thresholds.challengeThreshold = 0.2;
        thresholds.bluffThreshold = 0.15;
        thresholds.riskThreshold = 0.8;
        break;
    }
  }
  
  /// 获取调整后的性格参数
  AIPersonality getAdjustedPersonality(AIPersonality base) {
    if (difficulty == DifficultyLevel.medium) {
      return base;
    }
    
    // 根据难度调整性格参数
    double adjustment = difficulty == DifficultyLevel.easy ? 0.8 :
                       difficulty == DifficultyLevel.hard ? 1.2 : 1.5;
    
    return AIPersonality(
      id: base.id,
      name: base.name,
      description: base.description,
      avatarPath: base.avatarPath,
      bluffRatio: (base.bluffRatio * adjustment).clamp(0.0, 1.0),
      challengeThreshold: (base.challengeThreshold / adjustment).clamp(0.0, 1.0),
      riskAppetite: (base.riskAppetite * adjustment).clamp(0.0, 1.0),
      mistakeRate: (base.mistakeRate * adjustment).clamp(0.0, 1.0),
      tellExposure: base.tellExposure,
      reverseActingProb: base.reverseActingProb,
      bidPreferenceThreshold: base.bidPreferenceThreshold,
      taunts: base.taunts,
      isVIP: base.isVIP,
      country: base.country,
      difficulty: base.difficulty,
    );
  }
  
  /// 重置配置
  void reset() {
    useCloudAI = false;
    enableFallback = true;
    debugMode = false;
    difficulty = DifficultyLevel.medium;
    thresholds.reset();
    stats.reset();
  }
  
  /// 导出配置
  Map<String, dynamic> toJson() {
    return {
      'useCloudAI': useCloudAI,
      'enableFallback': enableFallback,
      'debugMode': debugMode,
      'difficulty': difficulty.toString(),
      'thresholds': thresholds.toJson(),
      'stats': stats.toJson(),
    };
  }
  
  /// 导入配置
  void fromJson(Map<String, dynamic> json) {
    useCloudAI = json['useCloudAI'] ?? false;
    enableFallback = json['enableFallback'] ?? true;
    debugMode = json['debugMode'] ?? false;
    
    String? diffStr = json['difficulty'];
    if (diffStr != null) {
      difficulty = DifficultyLevel.values.firstWhere(
        (e) => e.toString() == diffStr,
        orElse: () => DifficultyLevel.medium,
      );
    }
  }
}

/// 难度级别
enum DifficultyLevel {
  easy,    // 简单
  medium,  // 中等
  hard,    // 困难
  expert,  // 专家
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
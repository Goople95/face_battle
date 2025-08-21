/// AI调试工具
/// 
/// 用于调试和分析AI决策过程
library;

import 'dart:convert';
import '../../../models/game_state.dart';
import '../../../utils/logger_utils.dart';

class AIDebugger {
  static bool enabled = false;
  static final List<DebugEntry> _history = [];
  static const int maxHistorySize = 100;
  
  /// 记录决策过程
  static void logDecision({
    required String engine,
    required GameRound round,
    required Map<String, dynamic> decision,
    required Duration processingTime,
    Map<String, dynamic>? extra,
  }) {
    if (!enabled) return;
    
    var entry = DebugEntry(
      timestamp: DateTime.now(),
      engine: engine,
      round: round,
      decision: decision,
      processingTime: processingTime,
      extra: extra,
    );
    
    _history.add(entry);
    
    // 限制历史大小
    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
    }
    
    // 输出到日志
    _printDebugInfo(entry);
  }
  
  /// 打印调试信息
  static void _printDebugInfo(DebugEntry entry) {
    StringBuffer sb = StringBuffer();
    sb.writeln('╔══════════════════════════════════════════════════════╗');
    sb.writeln('║ AI决策调试 - ${entry.engine.padRight(20)} ║');
    sb.writeln('╠══════════════════════════════════════════════════════╣');
    
    // 游戏状态
    sb.writeln('║ 游戏状态:');
    sb.writeln('║   AI骰子: ${entry.round.aiDice.values.join(', ')}');
    sb.writeln('║   当前叫牌: ${entry.round.currentBid?.toString() ?? "首轮"}');
    sb.writeln('║   回合数: ${entry.round.bidHistory.length}');
    sb.writeln('║   1被叫: ${entry.round.onesAreCalled ? "是" : "否"}');
    
    // 决策结果
    sb.writeln('║ 决策结果:');
    sb.writeln('║   类型: ${entry.decision['type']}');
    if (entry.decision['bid'] != null) {
      sb.writeln('║   叫牌: ${entry.decision['bid']}');
    }
    sb.writeln('║   置信度: ${entry.decision['confidence']?.toStringAsFixed(2) ?? 'N/A'}');
    sb.writeln('║   策略: ${entry.decision['strategy'] ?? 'unknown'}');
    sb.writeln('║   理由: ${entry.decision['reasoning'] ?? 'N/A'}');
    
    // 性能
    sb.writeln('║ 处理时间: ${entry.processingTime.inMilliseconds}ms');
    
    // 额外信息
    if (entry.extra != null) {
      sb.writeln('║ 额外信息:');
      entry.extra!.forEach((key, value) {
        sb.writeln('║   $key: $value');
      });
    }
    
    sb.writeln('╚══════════════════════════════════════════════════════╝');
    
    AILogger.logParsing('AI_DEBUG', {'info': sb.toString()});
  }
  
  /// 分析决策模式
  static Map<String, dynamic> analyzePatterns() {
    if (_history.isEmpty) {
      return {'message': '无历史数据'};
    }
    
    // 统计各种决策类型
    Map<String, int> decisionTypes = {};
    Map<String, int> strategies = {};
    List<double> confidences = [];
    List<int> processingTimes = [];
    
    for (var entry in _history) {
      // 决策类型
      String type = entry.decision['type'] ?? 'unknown';
      decisionTypes[type] = (decisionTypes[type] ?? 0) + 1;
      
      // 策略
      String strategy = entry.decision['strategy'] ?? 'unknown';
      strategies[strategy] = (strategies[strategy] ?? 0) + 1;
      
      // 置信度
      double? confidence = entry.decision['confidence'];
      if (confidence != null) {
        confidences.add(confidence);
      }
      
      // 处理时间
      processingTimes.add(entry.processingTime.inMilliseconds);
    }
    
    // 计算统计数据
    double avgConfidence = confidences.isNotEmpty 
      ? confidences.reduce((a, b) => a + b) / confidences.length 
      : 0;
    
    double avgProcessingTime = processingTimes.isNotEmpty
      ? processingTimes.reduce((a, b) => a + b) / processingTimes.length
      : 0;
    
    return {
      'totalDecisions': _history.length,
      'decisionTypes': decisionTypes,
      'strategies': strategies,
      'averageConfidence': avgConfidence,
      'averageProcessingTime': avgProcessingTime,
      'confidenceRange': {
        'min': confidences.isEmpty ? 0 : confidences.reduce((a, b) => a < b ? a : b),
        'max': confidences.isEmpty ? 0 : confidences.reduce((a, b) => a > b ? a : b),
      },
    };
  }
  
  /// 导出历史
  String exportHistory() {
    List<Map<String, dynamic>> data = [];
    
    for (var entry in _history) {
      data.add({
        'timestamp': entry.timestamp.toIso8601String(),
        'engine': entry.engine,
        'decision': entry.decision,
        'processingTime': entry.processingTime.inMilliseconds,
        'round': {
          'aiDice': entry.round.aiDice.values,
          'currentBid': entry.round.currentBid?.toString(),
          'bidHistory': entry.round.bidHistory.length,
          'onesAreCalled': entry.round.onesAreCalled,
        },
        'extra': entry.extra,
      });
    }
    
    return JsonEncoder.withIndent('  ').convert(data);
  }
  
  /// 清空历史
  static void clearHistory() {
    _history.clear();
  }
  
  /// 设置调试模式
  static void setEnabled(bool value) {
    enabled = value;
    if (enabled) {
      AILogger.logParsing('AI_DEBUG', {'status': '调试模式已启用'});
    } else {
      AILogger.logParsing('AI_DEBUG', {'status': '调试模式已关闭'});
    }
  }
}

/// 调试条目
class DebugEntry {
  final DateTime timestamp;
  final String engine;
  final GameRound round;
  final Map<String, dynamic> decision;
  final Duration processingTime;
  final Map<String, dynamic>? extra;
  
  DebugEntry({
    required this.timestamp,
    required this.engine,
    required this.round,
    required this.decision,
    required this.processingTime,
    this.extra,
  });
}

/// 性能监控
class PerformanceMonitor {
  static final Map<String, List<int>> _metrics = {};
  
  /// 记录性能指标
  static void record(String metric, int value) {
    if (!_metrics.containsKey(metric)) {
      _metrics[metric] = [];
    }
    
    _metrics[metric]!.add(value);
    
    // 只保留最近100个数据点
    if (_metrics[metric]!.length > 100) {
      _metrics[metric]!.removeAt(0);
    }
  }
  
  /// 获取统计信息
  static Map<String, dynamic> getStats(String metric) {
    var values = _metrics[metric];
    if (values == null || values.isEmpty) {
      return {'error': 'No data for metric: $metric'};
    }
    
    values.sort();
    
    int sum = values.reduce((a, b) => a + b);
    double avg = sum / values.length;
    int min = values.first;
    int max = values.last;
    int median = values[values.length ~/ 2];
    
    return {
      'count': values.length,
      'average': avg,
      'min': min,
      'max': max,
      'median': median,
    };
  }
  
  /// 清空指标
  static void clear([String? metric]) {
    if (metric != null) {
      _metrics.remove(metric);
    } else {
      _metrics.clear();
    }
  }
}
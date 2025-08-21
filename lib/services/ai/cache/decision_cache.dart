/// AI决策缓存
/// 
/// 缓存相似游戏状态的决策，提高性能
library;

import 'dart:collection';
import '../../../models/game_state.dart';

class DecisionCache {
  // 单例模式
  static final DecisionCache _instance = DecisionCache._internal();
  factory DecisionCache() => _instance;
  DecisionCache._internal();
  
  // LRU缓存
  final LinkedHashMap<String, CachedDecision> _cache = LinkedHashMap();
  final int maxSize = 100;
  final Duration maxAge = Duration(minutes: 5);
  
  // 统计
  int hits = 0;
  int misses = 0;
  
  /// 获取缓存的决策
  Map<String, dynamic>? get(GameRound round) {
    String key = _generateKey(round);
    
    var cached = _cache[key];
    if (cached != null) {
      // 检查是否过期
      if (DateTime.now().difference(cached.timestamp) < maxAge) {
        hits++;
        
        // 移到最前面（LRU）
        _cache.remove(key);
        _cache[key] = cached;
        
        return cached.decision;
      } else {
        // 过期了，删除
        _cache.remove(key);
      }
    }
    
    misses++;
    return null;
  }
  
  /// 缓存决策
  void put(GameRound round, Map<String, dynamic> decision) {
    String key = _generateKey(round);
    
    // 如果缓存满了，删除最旧的
    if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }
    
    _cache[key] = CachedDecision(
      decision: Map.from(decision),
      timestamp: DateTime.now(),
    );
  }
  
  /// 生成缓存键
  String _generateKey(GameRound round) {
    // 基于游戏状态生成唯一键
    StringBuffer key = StringBuffer();
    
    // AI骰子（排序后）
    var aiDice = List.from(round.aiDice.values)..sort();
    key.write(aiDice.join(','));
    key.write('|');
    
    // 当前叫牌
    if (round.currentBid != null) {
      key.write('${round.currentBid!.quantity}x${round.currentBid!.value}');
    } else {
      key.write('start');
    }
    key.write('|');
    
    // 1是否被叫
    key.write(round.onesAreCalled ? '1' : '0');
    key.write('|');
    
    // 回合数（粗粒度）
    key.write(round.bidHistory.length ~/ 2); // 每2轮为一个阶段
    
    return key.toString();
  }
  
  /// 清空缓存
  void clear() {
    _cache.clear();
    hits = 0;
    misses = 0;
  }
  
  /// 获取缓存命中率
  double get hitRate => (hits + misses) > 0 ? hits / (hits + misses) : 0;
  
  /// 获取缓存大小
  int get size => _cache.length;
  
  /// 清理过期缓存
  void cleanup() {
    var now = DateTime.now();
    _cache.removeWhere((key, value) => 
      now.difference(value.timestamp) >= maxAge
    );
  }
  
  /// 获取统计信息
  Map<String, dynamic> getStats() {
    return {
      'size': size,
      'maxSize': maxSize,
      'hits': hits,
      'misses': misses,
      'hitRate': hitRate,
    };
  }
}

/// 缓存的决策
class CachedDecision {
  final Map<String, dynamic> decision;
  final DateTime timestamp;
  
  CachedDecision({
    required this.decision,
    required this.timestamp,
  });
}

/// 选项缓存（用于复盘显示）
class OptionsCache {
  static final OptionsCache _instance = OptionsCache._internal();
  factory OptionsCache() => _instance;
  OptionsCache._internal();
  
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  
  /// 缓存选项列表
  void putOptions(String roundId, List<Map<String, dynamic>> options) {
    _cache[roundId] = List.from(options);
    
    // 只保留最近20轮
    if (_cache.length > 20) {
      var keys = _cache.keys.toList();
      _cache.remove(keys.first);
    }
  }
  
  /// 获取选项列表
  List<Map<String, dynamic>>? getOptions(String roundId) {
    return _cache[roundId];
  }
  
  /// 清空缓存
  void clear() {
    _cache.clear();
  }
}
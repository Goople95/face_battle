/// Master AI引擎 - 兼容层
/// 
/// 这是重构后的版本，使用新的组件化架构
/// 保持与原有接口兼容
library;

import '../models/game_state.dart';
import '../models/ai_personality.dart';
import 'ai/engines/master_engine.dart' as new_engine;

export 'ai/models/ai_models.dart';

/// 大师级AI决策引擎（兼容接口）
class MasterAIEngine {
  final AIPersonality personality;
  late final new_engine.MasterAIEngine _engine;
  
  MasterAIEngine({required this.personality}) {
    _engine = new_engine.MasterAIEngine(personality: personality);
  }
  
  /// 主决策方法
  Map<String, dynamic> makeDecision(GameRound round) {
    return _engine.makeDecision(round);
  }
  
  /// 重置引擎
  void reset() {
    _engine.reset();
  }
}
/// 顶级AI核心决策系统 - 重构版
/// 
/// 设计原则：
/// 1. 硬约束永远不可违反
/// 2. 决策链条清晰可追溯
/// 3. 每层都有明确职责
/// 4. 学习和适应是核心
library;

import 'dart:math' as math;
import '../models/game_state.dart';
import '../models/ai_personality.dart';
import '../utils/logger_utils.dart';

/// 决策结果 - 包含完整的决策链
class AIDecisionResult {
  final String action; // 'bid' or 'challenge'
  final Bid? bid;
  final double confidence;
  final String strategy;
  final String reasoning;
  final List<String> decisionChain; // 记录决策过程
  final Map<String, double> constraints; // 记录约束检查
  
  AIDecisionResult({
    required this.action,
    this.bid,
    required this.confidence,
    required this.strategy,
    required this.reasoning,
    required this.decisionChain,
    required this.constraints,
  });
}

/// 顶级AI核心引擎
class EliteAICore {
  final AIPersonality personality;
  final random = math.Random();
  
  // 核心组件
  late final HardConstraintChecker constraintChecker;
  late final MathematicalAnalyzer mathAnalyzer;
  late final OpponentProfiler opponentProfiler;
  late final PsychologicalEngine psychEngine;
  late final LearningSystem learner;
  
  EliteAICore({required this.personality}) {
    constraintChecker = HardConstraintChecker();
    mathAnalyzer = MathematicalAnalyzer();
    opponentProfiler = OpponentProfiler();
    psychEngine = PsychologicalEngine(personality);
    learner = LearningSystem();
  }
  
  /// 核心决策入口 - 清晰的决策流程
  AIDecisionResult makeDecision(GameRound round) {
    List<String> decisionChain = [];
    Map<String, double> constraintScores = {};
    
    // Step 1: 硬约束检查 - 这是最高优先级
    var hardConstraints = constraintChecker.check(round);
    decisionChain.add('硬约束检查: ${hardConstraints.summary}');
    
    // 如果有必须执行的硬约束，直接返回
    if (hardConstraints.hasMandatoryAction) {
      return AIDecisionResult(
        action: hardConstraints.mandatoryAction,
        bid: hardConstraints.mandatoryBid,
        confidence: 1.0,
        strategy: 'hard_constraint',
        reasoning: hardConstraints.reason,
        decisionChain: decisionChain,
        constraints: constraintScores,
      );
    }
    
    // Step 2: 数学分析 - 计算所有可能的期望值
    var mathAnalysis = mathAnalyzer.analyze(round, opponentProfiler.getProfile());
    decisionChain.add('数学分析: 最佳EV=${mathAnalysis.bestEV}');
    
    // Step 3: 心理战术评估
    var psychTactic = psychEngine.evaluateTactics(
      round, 
      opponentProfiler.getCurrentState(),
      mathAnalysis
    );
    if (psychTactic != null) {
      decisionChain.add('心理战术: ${psychTactic.name}');
    }
    
    // Step 4: 综合决策 - 但必须遵守硬约束
    var candidates = _generateCandidates(mathAnalysis, psychTactic, hardConstraints);
    candidates = _applyPersonality(candidates);
    
    // Step 5: 最终选择
    var chosen = _selectBest(candidates, round);
    decisionChain.add('最终选择: ${chosen.action}');
    
    // Step 6: 学习和更新
    learner.recordDecision(round, chosen);
    opponentProfiler.update(round);
    
    return chosen;
  }
  
  /// 生成候选决策（必须通过硬约束）
  List<AIDecisionResult> _generateCandidates(
    MathAnalysis math,
    PsychTactic? psych,
    HardConstraints constraints,
  ) {
    List<AIDecisionResult> candidates = [];
    
    // 从数学分析生成候选
    for (var option in math.options) {
      // 检查硬约束
      if (!constraints.allows(option)) {
        continue; // 跳过违反硬约束的选项
      }
      
      candidates.add(AIDecisionResult(
        action: option.type,
        bid: option.bid,
        confidence: option.confidence,
        strategy: option.strategy,
        reasoning: option.reasoning,
        decisionChain: [],
        constraints: {},
      ));
    }
    
    // 添加心理战术选项（如果有）
    if (psych != null && constraints.allows(psych.toOption())) {
      candidates.add(psych.toDecision());
    }
    
    return candidates;
  }
  
  /// 应用性格特征
  List<AIDecisionResult> _applyPersonality(List<AIDecisionResult> candidates) {
    // 根据性格调整候选权重
    return candidates.where((c) {
      switch (personality.id) {
        case '0001': // Professor - 理性
          return c.confidence > 0.6; // 只选高置信度
        case '0002': // Gambler - 冒险
          return true; // 接受所有选项
        case '0003': // Provocateur - 心理战
          return c.strategy.contains('psych') || c.confidence > 0.5;
        default:
          return true;
      }
    }).toList();
  }
  
  /// 选择最佳决策
  AIDecisionResult _selectBest(List<AIDecisionResult> candidates, GameRound round) {
    if (candidates.isEmpty) {
      return _emergencyDecision(round);
    }
    
    // 排序：置信度 * 策略权重
    candidates.sort((a, b) {
      double scoreA = a.confidence * _getStrategyWeight(a.strategy);
      double scoreB = b.confidence * _getStrategyWeight(b.strategy);
      return scoreB.compareTo(scoreA);
    });
    
    // 90%选最优，10%选次优（增加不可预测性）
    if (candidates.length > 1 && random.nextDouble() < 0.1) {
      return candidates[1];
    }
    
    return candidates[0];
  }
  
  double _getStrategyWeight(String strategy) {
    return {
      'value_bet': 1.2,
      'semi_bluff': 1.0,
      'trap': 1.5,
      'pressure': 1.3,
      'hard_constraint': 2.0, // 硬约束优先级最高
    }[strategy] ?? 1.0;
  }
  
  /// 紧急决策
  AIDecisionResult _emergencyDecision(GameRound round) {
    // 保守叫牌
    return AIDecisionResult(
      action: 'bid',
      bid: Bid(
        quantity: (round.currentBid?.quantity ?? 1) + 1,
        value: round.currentBid?.value ?? 3,
      ),
      confidence: 0.3,
      strategy: 'emergency',
      reasoning: '紧急决策',
      decisionChain: ['紧急决策触发'],
      constraints: {},
    );
  }
}

/// 硬约束检查器 - 绝对规则
class HardConstraintChecker {
  HardConstraints check(GameRound round) {
    var result = HardConstraints();
    
    if (round.currentBid == null) {
      result.summary = '开局叫牌';
      return result;
    }
    
    // 计算我们有多少个该点数
    int ourCount = round.aiDice.countValue(
      round.currentBid!.value,
      onesAreCalled: round.onesAreCalled,
    );
    
    int totalNeeded = round.currentBid!.quantity;
    int opponentNeeded = totalNeeded - ourCount;
    
    // 硬约束1：如果我们已经有足够，绝不质疑
    if (opponentNeeded <= 0) {
      result.hasMandatoryAction = true;
      result.mandatoryAction = 'bid'; // 必须叫牌，不能质疑
      result.reason = '我们有$ourCount个，已足够$totalNeeded个';
      result.summary = '禁止质疑（已有足够）';
      result.forbiddenActions.add('challenge');
      
      AILogger.logParsing('硬约束触发', {
        'type': '禁止质疑',
        'ourCount': ourCount,
        'needed': totalNeeded,
        'reason': result.reason,
      });
    }
    
    // 硬约束2：如果对手需要超过5个，必须质疑
    if (opponentNeeded > 5) {
      result.hasMandatoryAction = true;
      result.mandatoryAction = 'challenge';
      result.reason = '对手需要$opponentNeeded个，不可能';
      result.summary = '必须质疑（不可能）';
      
      AILogger.logParsing('硬约束触发', {
        'type': '必须质疑',
        'opponentNeeded': opponentNeeded,
        'reason': result.reason,
      });
    }
    
    return result;
  }
}

/// 硬约束结果
class HardConstraints {
  bool hasMandatoryAction = false;
  String mandatoryAction = '';
  Bid? mandatoryBid;
  String reason = '';
  String summary = '';
  List<String> forbiddenActions = [];
  
  bool allows(dynamic option) {
    if (option is Map) {
      return !forbiddenActions.contains(option['type']);
    }
    return true;
  }
}

/// 数学分析器
class MathematicalAnalyzer {
  MathAnalysis analyze(GameRound round, OpponentProfile profile) {
    // 实现贝叶斯推理和期望值计算
    return MathAnalysis();
  }
}

/// 数学分析结果
class MathAnalysis {
  double bestEV = 0;
  List<MathOption> options = [];
}

/// 数学选项
class MathOption {
  String type = '';
  Bid? bid;
  double confidence = 0;
  String strategy = '';
  String reasoning = '';
}

/// 对手画像
class OpponentProfiler {
  OpponentProfile getProfile() => OpponentProfile();
  OpponentState getCurrentState() => OpponentState();
  void update(GameRound round) {}
}

class OpponentProfile {
  double bluffRate = 0.3;
  Map<String, double> patterns = {};
}

class OpponentState {
  bool isNervous = false;
  bool isAggressive = false;
  int winStreak = 0;
}

/// 心理引擎
class PsychologicalEngine {
  final AIPersonality personality;
  
  PsychologicalEngine(this.personality);
  
  PsychTactic? evaluateTactics(
    GameRound round,
    OpponentState state,
    MathAnalysis math,
  ) {
    // 基于情境选择战术
    if (state.isNervous && math.bestEV > 10) {
      return PsychTactic(name: 'pressure', confidence: 0.8);
    }
    return null;
  }
}

/// 心理战术
class PsychTactic {
  final String name;
  final double confidence;
  
  PsychTactic({required this.name, required this.confidence});
  
  dynamic toOption() => {'type': 'bid', 'strategy': 'psych_$name'};
  AIDecisionResult toDecision() => AIDecisionResult(
    action: 'bid',
    confidence: confidence,
    strategy: 'psych_$name',
    reasoning: '心理战术: $name',
    decisionChain: [],
    constraints: {},
  );
}

/// 学习系统
class LearningSystem {
  void recordDecision(GameRound round, AIDecisionResult decision) {
    // 记录决策结果，用于后续学习
  }
}
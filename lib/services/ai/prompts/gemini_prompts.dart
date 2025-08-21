/// Gemini API的提示词模板
/// 
/// 集中管理所有API调用的提示词
library;

class GeminiPrompts {
  /// 高级决策提示词模板
  static String getAdvancedDecisionPrompt({
    required String personalityDesc,
    required String aiDiceValues,
    required String currentBid,
    required int roundNumber,
    required bool onesAreCalled,
    required String eliteAdvice,
    required String psychAdvice,
  }) {
    return '''你是$personalityDesc

当前游戏状态：
- 你的骰子：$aiDiceValues
- 对手叫牌：$currentBid
- 回合数：$roundNumber
- 1是否被叫：${onesAreCalled ? '是' : '否'}

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
  }
  
  /// 性格化决策提示词模板
  static String getPersonalityDecisionPrompt({
    required String personalityDesc,
    required String gameStatus,
    required String optionsText,
    required String historyInfo,
  }) {
    return '''你是$personalityDesc

游戏状态：
$gameStatus
$historyInfo

可选方案（按期望值排序）：
$optionsText

作为$personalityDesc，选择最符合你性格的选项。

输出JSON格式：
{
  "choice": 选项编号(1-10),
  "emotions": ["表情1", "表情2"],
  "dialogue": "性格化对话",
  "reasoning": "选择理由"
}''';
  }
  
  /// 简化决策提示词模板
  static String getSimpleDecisionPrompt({
    required String personalityName,
    required String personalityDesc,
    required String gameInfo,
    required String adviceText,
  }) {
    return '''你是$personalityName，$personalityDesc。

$gameInfo

建议：$adviceText

快速决策，输出JSON：
{
  "action": "bid" 或 "challenge",
  "bid": {"quantity": 数量, "value": 点数},
  "confidence": 0.0-1.0
}''';
  }
  
  /// 表情生成提示词
  static String getEmotionPrompt({
    required String personality,
    required String situation,
    required bool isBluffing,
  }) {
    return '''角色：$personality
情况：$situation
是否虚张：$isBluffing

生成2-3个合适的表情，从以下选择：
happy, angry, confident, nervous, thinking, suspicious, excited, disappointed, neutral, smirking

输出JSON数组：["表情1", "表情2"]''';
  }
  
  /// 对话生成提示词
  static String getDialoguePrompt({
    required String personality,
    required String action,
    required String context,
  }) {
    return '''角色：$personality
行动：$action
上下文：$context

生成一句简短的性格化对话（5-10个字），符合角色性格。

直接输出对话内容，不要加引号。''';
  }
  
  /// 游戏规则说明（用于API理解游戏）
  static const String gameRulesContext = '''
大话骰（Liar's Dice）游戏规则：
1. 每个玩家有5个骰子（1-6点）
2. 玩家轮流叫牌，声称场上所有骰子中有多少个特定点数
3. 1点通常是万能牌（除非被叫）
4. 叫牌必须比前一个更高（数量更多或点数更大）
5. 可以质疑对手的叫牌
6. 质疑后揭示所有骰子，判断输赢

策略要点：
- 基于概率计算做决策
- 适时虚张诈唬
- 读懂对手的模式
- 保持不可预测性
''';
  
  /// 性格描述生成
  static String buildPersonalityDescription(
    String name,
    String description,
    double bluffRatio,
    double challengeThreshold,
    double riskAppetite,
  ) {
    String bluffStyle = bluffRatio > 0.6 ? '经常虚张' : 
                        bluffRatio > 0.3 ? '偶尔虚张' : '很少虚张';
    
    String challengeStyle = challengeThreshold < 0.3 ? '容易质疑' :
                           challengeThreshold < 0.6 ? '适度质疑' : '不易质疑';
    
    String riskStyle = riskAppetite > 0.6 ? '冒险激进' :
                       riskAppetite > 0.3 ? '风险适中' : '保守谨慎';
    
    return '''$name - $description
性格特点：$bluffStyle，$challengeStyle，$riskStyle
决策风格：根据性格做出符合人设的选择''';
  }
}
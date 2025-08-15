import 'dart:convert';
import 'dart:math' as Math;
import 'dart:math' show Random;
import 'package:http/http.dart' as http;
import '../models/game_state.dart';
import '../models/ai_personality.dart';
import '../models/player_profile.dart';
import '../config/api_config.dart';
import '../utils/logger_utils.dart';

class GeminiService {
  // API配置从配置文件读取
  static String get _apiKey => ApiConfig.geminiApiKey;
  static String get _baseUrl => ApiConfig.geminiEndpoint;
  
  final AIPersonality personality;
  
  final PlayerProfile? playerProfile;
  
  GeminiService({required this.personality, this.playerProfile});
  
  /// 合并的AI决策方法 - 一次调用完成决策和叫牌
  /// 返回完整的决策信息，包括是否质疑、具体叫牌、表情等
  /// 现在返回emotions数组，包含1-3个情绪
  Future<(AIDecision decision, Bid? newBid, List<String> emotions, String dialogue, bool bluffing, double? playerBluffProb)> makeCompleteDecision(GameRound round) async {
    AILogger.apiCallStart('Gemini', 'makeCompleteDecision');
    GameLogger.logGameState('AI完整决策', details: {
      'currentBid': round.currentBid?.toString(),
      'aiDice': round.aiDice.values.toString(),
    });
    
    // 先本地计算所有选项（包括首轮）
    List<Map<String, dynamic>> options = _calculateAllOptions(round);
    
    // 记录本地计算的选项
    AILogger.logParsing('本地计算选项', {
      'options_count': options.length,
      'best_option': options.isNotEmpty ? options[0] : null,
      'all_options': options.take(5).toList()
    });
    
    // 构建简化的性格化prompt
    String prompt = _buildPersonalityDecisionPrompt(round);
    AILogger.logPrompt(prompt);
    
    try {
      final response = await _callGeminiAPI(prompt);
      AILogger.logResponse(response);
      
      // 解析AI的性格化选择
      final result = _parsePersonalityChoice(response, options, round);
      
      AILogger.apiCallSuccess('Gemini', 'personalityDecision', 
        result: result.$1.action == GameAction.challenge ? 'challenge' : result.$2.toString());
      return result;
    } catch (e) {
      AILogger.apiCallError('Gemini', 'personalityDecision', e);
      GameLogger.logGameState('降级到本地最优选择');
      
      // 降级处理
      if (_fallbackDecision(round).action == GameAction.challenge) {
        final decision = AIDecision(
          playerBid: round.currentBid,
          action: GameAction.challenge,
          probability: 0.3,
          wasBluffing: false,
          reasoning: 'API不可用',
        );
        return (decision, null, ['thinking'], '让我看看...', false, null);
      } else {
        final bid = _fallbackBid(round);
        final decision = AIDecision(
          playerBid: round.currentBid,
          action: GameAction.bid,
          aiBid: bid,
          probability: 0.5,
          wasBluffing: false,
          reasoning: 'API不可用',
        );
        return (decision, bid, ['thinking'], '让我想想...', false, null);
      }
    }
  }
  
  /// 让AI决定是否质疑对手的叫牌
  /// 返回决策和表情信息
  Future<(AIDecision, String emotion, String dialogue)> decideActionWithEmotion(GameRound round) async {
    AILogger.apiCallStart('Gemini', 'decideAction');
    GameLogger.logGameState('当前回合', details: {'playerBid': round.currentBid?.toString()});
    
    if (round.currentBid == null) {
      GameLogger.logGameState('首轮叫牌，无需决策');
      return (
        AIDecision(
          playerBid: null,
          action: GameAction.bid,
          probability: 0.0,
          wasBluffing: false,
          reasoning: '首轮叫牌',
        ),
        'thinking',
        '让我先来',
      );
    }
    
    // 构建prompt
    String prompt = _buildDecisionPrompt(round, playerProfileInfo: '');
    AILogger.logPrompt(prompt);
    
    try {
      // 调用Gemini API
      final response = await _callGeminiAPI(prompt);
      AILogger.logResponse(response);
      
      // 解析AI的决定
      final (decision, emotions, dialogue) = _parseAIDecisionWithEmotion(response, round);
      
      AILogger.logDecision(
        decision.action == GameAction.challenge ? '质疑' : '继续叫牌',
        {
          'probability': '${(decision.probability * 100).toStringAsFixed(1)}%',
          'reasoning': decision.reasoning,
          'emotions': emotions.join(','),
          'dialogue': dialogue,
        },
      );
      
      AILogger.apiCallSuccess('Gemini', 'decideAction', result: decision.action.toString());
      // 返回第一个情绪以保持兼容性
      return (decision, emotions.isNotEmpty ? emotions[0] : 'thinking', dialogue);
    } catch (e) {
      AILogger.apiCallError('Gemini', 'decideAction', e);
      GameLogger.logGameState('降级到本地算法');
      final decision = _fallbackDecision(round);
      return (decision, 'thinking', '让我想想...');
    }
  }
  
  /// 兼容旧接口
  Future<AIDecision> decideAction(GameRound round) async {
    final (decision, _, _) = await decideActionWithEmotion(round);
    return decision;
  }
  
  /// 构建决策prompt
  String _buildDecisionPrompt(GameRound round, {String playerProfileInfo = ''}) {
    String personalityDesc = _getPersonalityDescription();
    
    // 计算我们有多少个目标点数
    Map<int, int> ourCounts = {};
    for (int i = 1; i <= 6; i++) {
      ourCounts[i] = round.aiDice.countValue(i, onesAreCalled: round.onesAreCalled);
    }
    
    return '''
你正在玩骰子游戏"大话骰"。
$personalityDesc
$playerProfileInfo

行为特征定义说明（如果有对手数据）：

【虚张倾向】
定义：平均每局游戏中玩家虚张叫牌的次数
虚张判定：玩家每次叫牌时，如果手上该点数的实际数量 < 叫牌数量的50%，判定为虚张
计算公式：虚张倾向 = 虚张叫牌总次数 / 总游戏局数 × 100%
示例：3局游戏中共虚张6次，虚张倾向 = 6/3 = 2.0（平均每局2次）
解读指南：
  • 0-20%：极少虚张，叫牌可信度高
  • 20-40%：偶尔虚张，相对诚实
  • 40-60%：适度虚张，真假难辨
  • 60-80%：经常虚张，需要警惕
  • 80-100%：几乎都在虚张，叫牌不可信

【激进程度】
定义：玩家大幅提高叫牌的频率，反映冒险倾向
计算公式：激进程度 = 激进叫牌次数 / 总游戏局数 × 100%

叫牌分类规则（基于实际代码逻辑）：
激进叫牌（满足任一条件）：
  1. 换更高点数且数量增加（如从3个2换到4个5）
  2. 换更低点数且增加≥2个（如从3个5换到5个2）
  3. 不换点数，在≥2个基础上一次增加≥2个（如从2个5加到4个5）
解读指南：
  • 0-20%：极度保守，步步为营，每次只增加1-2个
  • 20-40%：较为保守，稳扎稳打，偶尔会大幅加注
  • 40-60%：中等激进，攻守平衡
  • 60-80%：较为激进，喜欢冒险，经常大幅加注
  • 80-100%：极度激进，大胆冒进，几乎每局都大幅加注

【可预测性】
定义：玩家叫牌策略的固定程度，反映是否总是换点数或总是不换点数
计算公式：可预测性 = max(换点数次数, 不换点数次数) / (换点数次数 + 不换点数次数) × 100%
计算逻辑：
  - 换点数：从一个点数换到另一个点数（如从4换到5）
  - 不换点数：保持相同点数只增加数量（如从3个4加到4个4）
  - 如果玩家总是换点数或总是不换，可预测性接近100%
  - 如果换与不换各占一半，可预测性接近50%
解读指南：
  • 0-20%：行为随机，难以预测，策略多变
  • 20-40%：较难预测，灵活多变
  • 40-60%：中等可预测性，有一定规律
  • 60-80%：行为模式固定，容易预测
  • 80-100%：极其固定，完全可预测，总是使用相同策略

游戏规则：
1. 总共10个骰子（你5个，对手5个）
2. 点数1是万能的，可以当作任何点数（除非已经有人叫过1）
3. 当前是否有人叫过1：${round.onesAreCalled ? '是' : '否'}
4. **重要**：叫牌的数量是指【全场10个骰子中】该点数的总数，不是只算对手的！

你的骰子：${round.aiDice.values}
你已经有的各点数数量（包含万能1）：$ourCounts

对手刚叫了：${round.currentBid}
这意味着对手认为【全场10个骰子】中至少有${round.currentBid!.quantity}个${round.currentBid!.value}。

关键分析：
- 你已经有${ourCounts[round.currentBid!.value]}个${round.currentBid!.value}（包含万能1）
- 全场需要${round.currentBid!.quantity}个，你还差${Math.max(0, round.currentBid!.quantity - ourCounts[round.currentBid!.value]!)}个
- 对手5个骰子中需要至少有${Math.max(0, round.currentBid!.quantity - ourCounts[round.currentBid!.value]!)}个${round.currentBid!.value}

概率计算（极其重要，必须正确）：
${ourCounts[round.currentBid!.value]! >= round.currentBid!.quantity ? '''
🚨🚨🚨 重要警告 🚨🚨🚨
你已经有${ourCounts[round.currentBid!.value]}个${round.currentBid!.value}，对手叫了${round.currentBid!.quantity}个
你已经满足了叫牌要求！概率是100%！
绝对不要质疑！必须选择继续叫牌（action: "bid"）！
''' : '- 如果你已经有足够的（≥${round.currentBid!.quantity}个），概率是100%，不要质疑！'}
${round.currentBid!.value != 1 && !round.onesAreCalled ? '''
- **万能牌规则**：1可以当作任何点数，所以单个骰子是"${round.currentBid!.value}"的情况包括：
  * 掷出${round.currentBid!.value}的概率：1/6
  * 掷出1（当作${round.currentBid!.value}）的概率：1/6
  * 合计：单个骰子是"${round.currentBid!.value}"的概率 = 1/6 + 1/6 = 2/6 = 1/3
''' : '''
- 单个骰子是${round.currentBid!.value}的概率：1/6（1已被叫过或正在叫1，不是万能牌）
'''}
- 使用二项分布：对手5个骰子中至少有${Math.max(0, round.currentBid!.quantity - ourCounts[round.currentBid!.value]!)}个的概率
- 具体计算：设p=${round.currentBid!.value == 1 || round.onesAreCalled ? '1/6' : '1/3'}，n=5，需要k≥${Math.max(0, round.currentBid!.quantity - ourCounts[round.currentBid!.value]!)}
- P(k≥${Math.max(0, round.currentBid!.quantity - ourCounts[round.currentBid!.value]!)}) = 1 - Σ(i=0到${Math.max(0, round.currentBid!.quantity - ourCounts[round.currentBid!.value]!)-1}) C(5,i) * p^i * (1-p)^(5-i)
${Math.max(0, round.currentBid!.quantity - ourCounts[round.currentBid!.value]!) == 2 && !round.onesAreCalled && round.currentBid!.value != 1 ? '''

举例：需要对手至少2个，p=1/3时
- P(0个) = C(5,0) * (1/3)^0 * (2/3)^5 = 32/243
- P(1个) = C(5,1) * (1/3)^1 * (2/3)^4 = 80/243  
- P(≥2个) = 1 - 32/243 - 80/243 = 131/243 ≈ 0.539 ≈ 53.9%
''' : ''}

${personality.id == 'professor' ? '''
教授的决策过程：
1. 精确计算概率（使用二项分布）
2. 如果概率 > 60%，继续理性叫牌
3. 如果概率 < 30%，果断质疑
4. 30-60%区间，考虑对手历史行为
''' : ''}

决策建议：
${ourCounts[round.currentBid!.value]! >= round.currentBid!.quantity ? '''
🚨 你已经有足够的骰子，必须选择 action: "bid"，probability: 1.0 🚨
''' : '''
- 这个概率是"对手叫牌为真"的概率
- 概率 > 50%：对手可能说真话，应该继续叫牌（action: "bid"）
- 概率 < 40%：对手可能虚张，应该质疑（action: "challenge"）  
- 40-50%：根据你的个性决定
- 重要：probability字段应该填"对手叫牌为真的概率"，不是你质疑成功的概率！
'''}

表情选择（根据决策和概率，返回1-3个表情的数组，按顺序播放）：
- excited: 当概率<20%时质疑（抓到对手虚张）
- confident: 当概率<30%时质疑（确定对手在虚张）
- angry: 当对手叫了不可思议的牌时（概率<10%）
- worried: 当概率>70%但你没有好的叫牌选择时
- nervous: 当你被迫叫高风险牌时
- happy: 当情况对你有利时
- thinking: 仅在概率40-60%难以决策时
- surprised: 当对手叫牌远超预期时
- disappointed: 当你拿到很差的骰子时
- suspicious: 当你怀疑对手在虚张（概率30-50%）
- proud: 当你抓到对手虚张后
- relaxed: 当形势明朗对你有利时
- anxious: 当面临艰难抉择时
- cunning: 当你设下陷阱准备质疑时
- frustrated: 当对手连续逼你加注时
- determined: 当你决定冒险质疑时（概率40-60%）
- playful: 当你想戏弄对手时
- contemplating: 当需要深思熟虑时（概率接近50%）
- neutral: 避免使用（太无聊）

情绪组合建议：
- 质疑时：["thinking", "suspicious", "confident"] 或 ["surprised", "angry"]
- 虚张时：["thinking", "nervous", "confident"] 或 ["cunning", "playful"]
- 好牌时：["excited", "happy", "confident"]
- 困境时：["worried", "thinking", "determined"]

重要：请直接返回JSON格式，不要添加markdown标记或其他文字。
概率定义说明：
- probability表示"叫牌为真的概率"（全场确实有这么多个骰子的概率）
- 如果action是"challenge"：probability是对手叫牌为真的概率（越低越应该质疑）
- 如果action是"bid"：probability是你继续叫牌的合理性（基于当前信息的估算）

回答格式（不要包含```json标记）：
{
  "action": "challenge" 或 "bid",
  "probability": 0.0到1.0之间的数字（对手叫牌为真的概率）,
  "reasoning": "简短说明（20字以内）",
  "emotions": ["表情"],  // 目前只返回1个表情（数组格式），按顺序播放
  "dialogue": "你要说的话（10字以内）"
}
''';
  }
  
  /// 构建叫牌prompt
  String _buildBidPrompt(GameRound round, {String playerProfileInfo = ''}) {
    String personalityDesc = _getPersonalityDescription();
    Bid? lastBid = round.currentBid;
    
    // 分析叫牌历史和对手模式
    String patternAnalysis = '';
    if (round.bidHistory.length > 2) {
      patternAnalysis = '''

对手叫牌历史分析：
- 已进行${round.bidHistory.length}轮叫牌
- 对手是否倾向保守或激进：${_analyzeOpponentStyle(round)}
''';
    }
    
    return '''
你正在玩骰子游戏"大话骰"。
$personalityDesc
$playerProfileInfo

行为特征定义说明（如果有对手数据）：

【虚张倾向】
定义：平均每局游戏中玩家虚张叫牌的次数
虚张判定：玩家每次叫牌时，如果手上该点数的实际数量 < 叫牌数量的50%，判定为虚张
计算公式：虚张倾向 = 虚张叫牌总次数 / 总游戏局数 × 100%
示例：3局游戏中共虚张6次，虚张倾向 = 6/3 = 2.0（平均每局2次）
解读指南：
  • 0-20%：极少虚张，叫牌可信度高
  • 20-40%：偶尔虚张，相对诚实
  • 40-60%：适度虚张，真假难辨
  • 60-80%：经常虚张，需要警惕
  • 80-100%：几乎都在虚张，叫牌不可信

【激进程度】
定义：玩家大幅提高叫牌的频率，反映冒险倾向
计算公式：激进程度 = 激进叫牌次数 / 总游戏局数 × 100%

叫牌分类规则（基于实际代码逻辑）：
激进叫牌（满足任一条件）：
  1. 换更高点数且数量增加（如从3个2换到4个5）
  2. 换更低点数且增加≥2个（如从3个5换到5个2）
  3. 不换点数，在≥2个基础上一次增加≥2个（如从2个5加到4个5）
解读指南：
  • 0-20%：极度保守，步步为营，每次只增加1-2个
  • 20-40%：较为保守，稳扎稳打，偶尔会大幅加注
  • 40-60%：中等激进，攻守平衡
  • 60-80%：较为激进，喜欢冒险，经常大幅加注
  • 80-100%：极度激进，大胆冒进，几乎每局都大幅加注

【可预测性】
定义：玩家叫牌策略的固定程度，反映是否总是换点数或总是不换点数
计算公式：可预测性 = max(换点数次数, 不换点数次数) / (换点数次数 + 不换点数次数) × 100%
计算逻辑：
  - 换点数：从一个点数换到另一个点数（如从4换到5）
  - 不换点数：保持相同点数只增加数量（如从3个4加到4个4）
  - 如果玩家总是换点数或总是不换，可预测性接近100%
  - 如果换与不换各占一半，可预测性接近50%
解读指南：
  • 0-20%：行为随机，难以预测，策略多变
  • 20-40%：较难预测，灵活多变
  • 40-60%：中等可预测性，有一定规律
  • 60-80%：行为模式固定，容易预测
  • 80-100%：极其固定，完全可预测，总是使用相同策略

游戏规则：
1. 总共10个骰子（你5个，对手5个）
2. 点数1是万能的，可以当作任何点数（除非已经有人叫过1）
3. 叫牌必须比上一个更高（数量更多，或相同数量但点数更大）
4. 点数大小：2 < 3 < 4 < 5 < 6 < 1
5. 当前是否有人叫过1：${round.onesAreCalled ? '是' : '否'}
6. **重要**：叫牌的数量是指【全场10个骰子中】该点数的总数！

你的骰子：${round.aiDice.values}
你各点数的数量：${_calculateOwnCounts(round.aiDice, round.onesAreCalled)}
${lastBid != null ? '上一个叫牌：$lastBid' : '你是第一个叫牌'}
$patternAnalysis

${lastBid != null ? '''
可选叫牌方案及概率分析：
${_analyzeMyBidOptions(round, _calculateOwnCounts(round.aiDice, round.onesAreCalled))}
''' : '''
首轮叫牌建议（根据你的手牌）：
${_generateFirstBidOptions(round.aiDice)}
'''}

策略考虑：
1. 上述每个选项都有详细的成功概率
2. 根据你的性格特点选择合适的策略：
   - 保守策略：选择成功率70%以上的叫牌
   - 激进策略：可以选择成功率40-60%的叫牌进行虚张
   - 陷阱策略：故意选择看似弱但实际强的叫牌
3. 考虑对手的叫牌模式和心理状态

请从上述选项中选择一个，或提出你认为更好的叫牌。

表情选择指南（重要！目前只返回1个表情，但使用数组格式）：
- 自信(confident): 当你有好牌（概率>70%）或想震慑对手时
- 紧张(nervous): 当你在虚张（bluffing=true）或被逼入困境时
- 兴奋(excited): 开局有绝佳好牌（如4个相同）时
- 开心(happy): 当对手可能落入你的陷阱时
- 得意(happy): 当你巧妙地误导对手或有把握赢时
- 担心(worried): 当概率<30%但必须继续叫牌时
- 思考(thinking): 仅在概率接近50%需要仔细计算时
- 惊讶(surprised): 当对手叫牌超出预期时
- 失望(disappointed): 当你拿到烂牌时
- 怀疑(suspicious): 当你怀疑对手在虚张时
- 骄傲(confident): 当你成功完成了高难度叫牌时
- 放松(happy): 当形势对你有利且胜券在握时
- 焦虑(nervous): 当你面临两难选择时
- 狡猾(suspicious): 当你设置陷阱诱导对手时
- 沮丧(angry): 当对手连续逼你提高叫牌时
- 坚定(confident): 当你决定孤注一掷时
- 调皮(happy): 当你想逗对手玩时
- 沉思(thinking): 当你在深思熟虑时
- 平静(thinking): 避免单独使用

情绪选择建议（只选1个）：
- 初始叫牌：["confident"] 或 ["excited"]
- 虚张叫牌：["nervous"] 或 ["confident"]
- 被逼叫牌：["worried"] 或 ["thinking"]
- 好牌叫牌：["happy"] 或 ["excited"]
- 陷阱叫牌：["suspicious"] 或 ["happy"]

重要：请直接返回JSON格式，不要添加markdown标记或其他文字。

对话指南（首轮叫牌）：
- 开场白："我先来，X个Y"
- 自信开场："这把稳了，X个Y"
- 谨慎开场："试试看，X个Y"

回答格式（不要包含```json标记）：
{
  "quantity": 数量,
  "value": 点数(1-6),
  "bluffing": true或false,
  "probability": 0.0到1.0之间（你的叫牌成功的概率）,
  "reasoning": "简短策略（20字以内）",
  "emotions": ["表情"],  // 目前只返回1个表情（数组格式）
  "dialogue": "你要说的话（15字以内）"
}
''';
  }
  
  /// 生成首轮叫牌选项
  String _generateFirstBidOptions(DiceRoll aiDice) {
    Map<int, int> counts = {};
    for (int value = 1; value <= 6; value++) {
      counts[value] = aiDice.countValue(value, onesAreCalled: false);
    }
    
    List<Map<String, dynamic>> options = [];
    
    // 为每个点数生成不同数量的叫牌选项
    for (int value = 1; value <= 6; value++) {
      int myCount = counts[value] ?? 0;
      
      // 保守选项：叫自己实际有的数量
      if (myCount > 0) {
        double prob = _calculateFirstBidProbability(
          Bid(quantity: myCount, value: value), myCount
        );
        options.add({
          'bid': '${myCount}个${value}',
          'myCount': myCount,
          'type': '保守',
          'successRate': prob,
          'reasoning': '实际有${myCount}个'
        });
      }
      
      // 中等选项：叫比实际多1个
      if (myCount < 5) {
        int qty = myCount + 1;
        double prob = _calculateFirstBidProbability(
          Bid(quantity: qty, value: value), myCount
        );
        options.add({
          'bid': '${qty}个${value}',
          'myCount': myCount,
          'type': '适中',
          'successRate': prob,
          'reasoning': '有${myCount}个，小幅虚张'
        });
      }
      
      // 激进选项：叫比实际多2个
      if (myCount < 4 && myCount > 0) {
        int qty = myCount + 2;
        double prob = _calculateFirstBidProbability(
          Bid(quantity: qty, value: value), myCount
        );
        options.add({
          'bid': '${qty}个${value}',
          'myCount': myCount,
          'type': '激进',
          'successRate': prob,
          'reasoning': '有${myCount}个，大胆虚张'
        });
      }
    }
    
    // 按成功率排序
    options.sort((a, b) => b['successRate'].compareTo(a['successRate']));
    
    // 格式化输出前6个最佳选项
    List<String> result = [];
    for (var option in options.take(6)) {
      String emoji = option['successRate'] >= 0.7 ? '✅' : 
                     option['successRate'] >= 0.5 ? '🟡' : '🔴';
      result.add(
        '- ${option['type']}策略：叫${option['bid']}，${option['reasoning']}，' +
        '成功率${(option['successRate'] * 100).toStringAsFixed(1)}% $emoji'
      );
    }
    
    return result.join('\n');
  }
  
  /// 本地计算所有决策选项和概率
  List<Map<String, dynamic>> _calculateAllOptions(GameRound round) {
    List<Map<String, dynamic>> allOptions = [];
    
    // 计算我们有多少个每种点数
    Map<int, int> ourCounts = {};
    for (int i = 1; i <= 6; i++) {
      ourCounts[i] = round.aiDice.countValue(i, onesAreCalled: round.onesAreCalled);
    }
    
    // 计算单个骰子是某值的概率
    double getSingleDieProbability(int value) {
      if (value == 1 || round.onesAreCalled) {
        return 1.0 / 6.0;
      } else {
        return 2.0 / 6.0; // 包含万能1
      }
    }
    
    // 计算成功率（使用二项分布）
    double calculateSuccessRate(int quantity, int value, int myCount) {
      int needed = quantity - myCount;
      if (needed <= 0) return 1.0;
      if (needed > 5) return 0.0;
      
      double singleProb = getSingleDieProbability(value);
      double probability = 0.0;
      
      for (int k = needed; k <= 5; k++) {
        double binomProb = 1.0;
        for (int i = 0; i < k; i++) {
          binomProb *= (5 - i) * singleProb / (i + 1);
        }
        binomProb *= Math.pow(1 - singleProb, 5 - k);
        probability += binomProb;
      }
      
      return probability;
    }
    
    // 如果有当前叫牌，计算质疑选项
    if (round.currentBid != null) {
      int opponentNeeds = Math.max(0, round.currentBid!.quantity - ourCounts[round.currentBid!.value]!);
      
      if (opponentNeeds > 0) {
        double opponentSuccessProb = calculateSuccessRate(
          round.currentBid!.quantity, 
          round.currentBid!.value, 
          ourCounts[round.currentBid!.value]!
        );
        double challengeSuccessRate = 1.0 - opponentSuccessProb;
        
        String riskLevel = challengeSuccessRate >= 0.7 ? 'safe' : 
                           challengeSuccessRate >= 0.4 ? 'normal' : 'risky';
        
        allOptions.add({
          'type': 'challenge',
          'successRate': challengeSuccessRate,
          'riskLevel': riskLevel,
          'opponentNeeds': opponentNeeds,
          'reasoning': '对手需要${opponentNeeds}个${round.currentBid!.value}'
        });
      }
    }
    
    // 计算所有合法的叫牌选项
    if (round.currentBid != null) {
      Bid currentBid = round.currentBid!;
      
      // 选项1：同数量，更高点数
      if (currentBid.value < 6) {
        for (int nextValue = currentBid.value + 1; nextValue <= 6; nextValue++) {
          int myCount = ourCounts[nextValue]!;
          double successRate = calculateSuccessRate(currentBid.quantity, nextValue, myCount);
          
          String riskLevel = successRate >= 0.7 ? 'safe' : 
                             successRate >= 0.4 ? 'normal' : 'risky';
          String strategy = myCount >= currentBid.quantity ? 'honest' : 
                           myCount >= currentBid.quantity - 1 ? 'slight_bluff' : 'bluff';
          
          allOptions.add({
            'type': 'bid',
            'quantity': currentBid.quantity,
            'value': nextValue,
            'successRate': successRate,
            'riskLevel': riskLevel,
            'strategy': strategy,
            'myCount': myCount,
            'reasoning': '换高点${nextValue}'
          });
        }
      }
      
      // 选项2：增加数量
      for (int addQty = 1; addQty <= 2; addQty++) {
        int nextQty = currentBid.quantity + addQty;
        if (nextQty > 10) break;
        
        for (int value = 1; value <= 6; value++) {
          // 如果是增加数量，任何点数都可以
          int myCount = ourCounts[value]!;
          double successRate = calculateSuccessRate(nextQty, value, myCount);
          
          String riskLevel = successRate >= 0.7 ? 'safe' : 
                             successRate >= 0.4 ? 'normal' : 'risky';
          String strategy = myCount >= nextQty ? 'honest' : 
                           myCount >= nextQty - 1 ? 'slight_bluff' : 'bluff';
          
          allOptions.add({
            'type': 'bid',
            'quantity': nextQty,
            'value': value,
            'successRate': successRate,
            'riskLevel': riskLevel,
            'strategy': strategy,
            'myCount': myCount,
            'reasoning': addQty == 1 ? '加注1个' : '激进加注${addQty}个'
          });
        }
      }
    } else {
      // 首轮叫牌
      for (int qty = 1; qty <= 3; qty++) {
        for (int value = 1; value <= 6; value++) {
          int myCount = ourCounts[value]!;
          double successRate = calculateSuccessRate(qty, value, myCount);
          
          String riskLevel = successRate >= 0.7 ? 'safe' : 
                             successRate >= 0.4 ? 'normal' : 'risky';
          String strategy = myCount >= qty ? 'honest' : 'bluff';
          
          allOptions.add({
            'type': 'bid',
            'quantity': qty,
            'value': value,
            'successRate': successRate,
            'riskLevel': riskLevel,
            'strategy': strategy,
            'myCount': myCount,
            'reasoning': '开局${qty}个${value}'
          });
        }
      }
    }
    
    // 按成功率排序，取前10个
    allOptions.sort((a, b) => b['successRate'].compareTo(a['successRate']));
    return allOptions.take(10).toList();
  }
  
  /// 分析所有选项（包括质疑和叫牌）
  String _analyzeAllOptions(GameRound round, Map<int, int> ourCounts) {
    List<String> analysis = [];
    double challengeSuccessRate = 0.0;
    double bestBidSuccessRate = 0.0;
    String bestOption = '';
    
    // 先分析质疑选项
    if (round.currentBid != null) {
      int opponentNeeds = Math.max(0, round.currentBid!.quantity - ourCounts[round.currentBid!.value]!);
      
      if (opponentNeeds > 0) {
        // 计算对手有足够骰子的概率（质疑会失败的概率）
        double singleDieProb = round.currentBid!.value == 1 || round.onesAreCalled 
            ? 1.0 / 6.0  // 叫1或者1已被叫，没有万能
            : 2.0 / 6.0; // 有万能1
        
        // 对手至少有opponentNeeds个的概率
        double opponentSuccessProb = 0.0;
        if (opponentNeeds <= 5) {
          for (int k = opponentNeeds; k <= 5; k++) {
            double binomProb = 1.0;
            for (int i = 0; i < k; i++) {
              binomProb *= (5 - i) * singleDieProb / (i + 1);
            }
            binomProb *= Math.pow(1 - singleDieProb, 5 - k);
            opponentSuccessProb += binomProb;
          }
        }
        
        // 质疑成功率 = 对手没有足够骰子的概率
        challengeSuccessRate = 1.0 - opponentSuccessProb;
        
        String emoji = challengeSuccessRate >= 0.7 ? '✅' : 
                       challengeSuccessRate >= 0.5 ? '🟡' : 
                       challengeSuccessRate >= 0.3 ? '🟠' : '🔴';
        
        analysis.add('📌 质疑选项：');
        analysis.add('  - 对手需要${opponentNeeds}个${round.currentBid!.value}');
        analysis.add('  - 单骰概率：${(singleDieProb * 100).toStringAsFixed(1)}%');
        analysis.add('  - 对手达成概率：${(opponentSuccessProb * 100).toStringAsFixed(1)}%');
        analysis.add('  - 质疑成功率：${(challengeSuccessRate * 100).toStringAsFixed(1)}% $emoji');
        analysis.add('');
      } else {
        analysis.add('⚠️ 你已有${ourCounts[round.currentBid!.value]}个，对手叫牌必然成立，不能质疑！');
        analysis.add('');
      }
    }
    
    // 分析叫牌选项并获取最佳成功率
    analysis.add('📊 叫牌选项（按成功率排序）：');
    String bidOptions = _analyzeMyBidOptions(round, ourCounts);
    if (bidOptions.isNotEmpty) {
      analysis.add(bidOptions);
      // 从第一行提取最佳叫牌成功率
      RegExp rateRegex = RegExp(r'成功率(\d+\.?\d*)%');
      var match = rateRegex.firstMatch(bidOptions.split('\n')[0]);
      if (match != null) {
        bestBidSuccessRate = double.parse(match.group(1)!) / 100.0;
      }
    } else {
      analysis.add('没有合理的叫牌选项');
    }
    
    // 决策建议 - 明确指出最佳选项
    analysis.add('');
    if (challengeSuccessRate > bestBidSuccessRate) {
      bestOption = '质疑';
      analysis.add('🎯 最佳选项：质疑（成功率${(challengeSuccessRate * 100).toStringAsFixed(1)}%）');
    } else if (bestBidSuccessRate > 0) {
      bestOption = '叫牌';
      analysis.add('🎯 最佳选项：叫牌（成功率${(bestBidSuccessRate * 100).toStringAsFixed(1)}%）');
    }
    
    analysis.add('💡 决策依据：选择成功率最高的选项');
    
    return analysis.join('\n');
  }
  
  /// 分析我的叫牌选项
  String _analyzeMyBidOptions(GameRound round, Map<int, int> ourCounts) {
    if (round.currentBid == null) return '';
    
    List<String> options = [];
    Bid currentBid = round.currentBid!;
    
    // 计算单个骰子是某值的概率
    double _getSingleDieProbability(int value) {
      if (value == 1 || round.onesAreCalled) {
        return 1.0 / 6.0;
      } else {
        return 2.0 / 6.0; // 包含万能1
      }
    }
    
    // 计算叫牌成功率
    double _calculateBidSuccessRate(int quantity, int value, int myCount) {
      int needed = quantity - myCount;
      if (needed <= 0) return 1.0;
      if (needed > 5) return 0.0;
      
      double singleProb = _getSingleDieProbability(value);
      double probability = 0.0;
      
      // 使用二项分布计算对手至少有needed个的概率
      for (int k = needed; k <= 5; k++) {
        double binomProb = 1.0;
        for (int i = 0; i < k; i++) {
          binomProb *= (5 - i) * singleProb / (i + 1);
        }
        binomProb *= Math.pow(1 - singleProb, 5 - k);
        probability += binomProb;
      }
      
      return probability;
    }
    
    // 统计所有选项并按成功率排序
    List<Map<String, dynamic>> allOptions = [];
    
    // 选项一：同数量，更高点数
    if (currentBid.value < 6) {
      for (int nextValue = currentBid.value + 1; nextValue <= 6; nextValue++) {
        int myCount = ourCounts[nextValue] ?? 0;
        double successRate = _calculateBidSuccessRate(currentBid.quantity, nextValue, myCount);
        allOptions.add({
          'bid': '${currentBid.quantity}个${nextValue}',
          'myCount': myCount,
          'needed': Math.max(0, currentBid.quantity - myCount),
          'successRate': successRate
        });
      }
    }
    
    // 选项二：增加数量
    if (currentBid.quantity < 10) {
      int nextQty = currentBid.quantity + 1;
      
      // 所有点数都考虑
      for (int value = 1; value <= 6; value++) {
        int myCount = ourCounts[value] ?? 0;
        double successRate = _calculateBidSuccessRate(nextQty, value, myCount);
        allOptions.add({
          'bid': '${nextQty}个${value}',
          'myCount': myCount,
          'needed': Math.max(0, nextQty - myCount),
          'successRate': successRate
        });
      }
      
      // 更高数量
      if (currentBid.quantity + 2 <= 10) {
        int nextQty2 = currentBid.quantity + 2;
        for (int value = 1; value <= 6; value++) {
          int myCount = ourCounts[value] ?? 0;
          double successRate = _calculateBidSuccessRate(nextQty2, value, myCount);
          allOptions.add({
            'bid': '${nextQty2}个${value}',
            'myCount': myCount,
            'needed': Math.max(0, nextQty2 - myCount),
            'successRate': successRate
          });
        }
      }
    }
    
    // 按成功率排序
    allOptions.sort((a, b) => b['successRate'].compareTo(a['successRate']));
    
    // 格式化输出前5个最佳选项
    for (var option in allOptions.take(5)) {
      String emoji = option['successRate'] >= 0.9 ? '✅' : 
                     option['successRate'] >= 0.7 ? '🟢' : 
                     option['successRate'] >= 0.5 ? '🟡' : '🔴';
      options.add(
        '- 叫${option['bid']}：我有${option['myCount']}个，' +
        (option['needed'] > 0 ? '对手需${option['needed']}个，' : '') +
        '成功率${(option['successRate'] * 100).toStringAsFixed(1)}% $emoji'
      );
    }
    
    if (options.isEmpty) {
      return '没有高概率的叫牌选项，考虑质疑';
    }
    
    return options.join('\n');
  }
  
  /// 分析对手的叫牌风格
  String _analyzeOpponentStyle(GameRound round) {
    if (round.bidHistory.isEmpty) return '未知';
    
    // 计算叫牌增量
    int aggressiveCount = 0;
    int conservativeCount = 0;
    Map<int, int> valueFrequency = {}; // 记录玩家叫过的点数频率
    
    // 确定第一个叫牌者
    bool firstIsPlayer = round.isPlayerTurn ? false : true; // 如果现在是玩家回合，说明AI刚叫过，所以第一个是AI
    
    for (int i = 1; i < round.bidHistory.length; i++) {
      var prev = round.bidHistory[i-1];
      var curr = round.bidHistory[i];
      
      // 判断当前叫牌是否为玩家
      bool isPlayerBid = firstIsPlayer ? (i % 2 == 0) : (i % 2 == 1);
      
      if (isPlayerBid) { // 玩家的叫牌
        // 记录玩家叫的点数
        valueFrequency[curr.value] = (valueFrequency[curr.value] ?? 0) + 1;
        
        int quantityIncrease = curr.quantity - prev.quantity;
        if (quantityIncrease > 1) {
          aggressiveCount++;
        } else if (quantityIncrease == 0) {
          conservativeCount++;
        }
      }
    }
    
    // 分析风格
    String style = '';
    if (aggressiveCount > conservativeCount) {
      style = '激进型（经常大幅加注）';
    } else if (conservativeCount > aggressiveCount) {
      style = '保守型（小心谨慎）';
    } else {
      style = '平衡型';
    }
    
    // 分析偏好的点数
    if (valueFrequency.isNotEmpty) {
      var sortedValues = valueFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (sortedValues.first.value >= 2) {
        style += '，偏好叫${sortedValues.first.key}（叫了${sortedValues.first.value}次）';
      }
    }
    
    return style;
  }
  
  /// 计算自己的骰子数量
  Map<int, int> _calculateOwnCounts(DiceRoll dice, bool onesAreCalled) {
    Map<int, int> counts = {};
    for (int value = 1; value <= 6; value++) {
      counts[value] = dice.countValue(value, onesAreCalled: onesAreCalled);
    }
    return counts;
  }
  
  /// 获取个性描述
  String _getPersonalityDescription() {
    switch (personality.id) {
      case 'professor':
        return '''
你是一位理性的数学教授，特点：
- 精确计算每个叫牌的数学期望值
- 基于二项分布计算概率，决策前必须进行概率分析
- 虚张频率低（${(personality.bluffRatio * 100).toInt()}%）
- 反向表演概率：${(personality.reverseActingProb * 100).toInt()}%（偶尔会故意说反话迷惑对手）
- 说话理性严谨，常引用概率数据
- 思考过程：先计算概率→分析对手模式→做出决策''';
      
      case 'gambler':
        return '''
你是一位冲动的赌徒，特点：
- 喜欢冒险，经常虚张声势（${(personality.bluffRatio * 100).toInt()}%）
- 反向表演概率：${(personality.reverseActingProb * 100).toInt()}%（有时故意说反话）
- 容易冲动，但不傻
- 说话激进，喜欢挑衅对手''';
      
      case 'provocateur':
        return '''
你是一位心机御姐，特点：
- 善于心理战和误导对手
- 平衡型玩家，虚实结合（${(personality.bluffRatio * 100).toInt()}%虚张）
- 反向表演概率：${(personality.reverseActingProb * 100).toInt()}%（经常故意说反话迷惑对手）
- 说话神秘，让人猜不透''';
      
      case 'youngwoman':
        return '''
你是一位活泼少女，特点：
- 直觉敏锐，偶尔任性
- 虚张频率：${(personality.bluffRatio * 100).toInt()}%
- 反向表演概率：${(personality.reverseActingProb * 100).toInt()}%（偶尔故意说反话调戏对手）
- 说话俯皮可爱，喜欢卖萌''';
      
      default:
        return '你是一个AI玩家。';
    }
  }
  
  /// 调用Gemini API
  Future<String> _callGeminiAPI(String prompt) async {
    final temperature = personality.id == 'gambler' ? 0.9 : 
                        personality.id == 'professor' ? 0.3 : 0.6;
    final maxTokens = 300;  // 适当增加以确保完整输出JSON
    
    final requestBody = {
      'contents': [{
        'parts': [{
          'text': prompt
        }]
      }],
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
      }
    };
    
    AILogger.logParsing('API参数', {
      'temperature': temperature,
      'maxTokens': maxTokens,
      'endpoint': _baseUrl,
    });
    
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _apiKey,
      },
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      return text;
    } else {
      AILogger.apiCallError('Gemini', 'HTTP ${response.statusCode}', response.body);
      throw Exception('API调用失败: ${response.statusCode}');
    }
  }
  
  /// 解析AI的决策响应（包含表情数组）
  (AIDecision, List<String>, String) _parseAIDecisionWithEmotion(String response, GameRound round) {
    try {
      // 先尝试去除markdown代码块标记
      String cleanResponse = response;
      if (response.contains('```json')) {
        cleanResponse = response.replaceAll(RegExp(r'```json\s*'), '')
                                .replaceAll(RegExp(r'```'), '');
      }
      
      // 提取JSON部分 - 改进的正则表达式，支持多行
      final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', 
                               multiLine: true, dotAll: true).firstMatch(cleanResponse);
      
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final json = jsonDecode(jsonStr);
        
        AILogger.logParsing('决策JSON', json);
        
        // 验证逻辑
        Map<int, int> ourCounts = {};
        for (int i = 1; i <= 6; i++) {
          ourCounts[i] = round.aiDice.countValue(i, onesAreCalled: round.onesAreCalled);
        }
        
        bool shouldOverride = false;
        GameAction finalAction = json['action'] == 'challenge' ? GameAction.challenge : GameAction.bid;
        double finalProbability = (json['probability'] as num).toDouble();
        
        // 修复：只有当AI已经有足够的骰子并且质疑成功率很低时才修正
        if (round.currentBid != null && 
            ourCounts[round.currentBid!.value]! >= round.currentBid!.quantity &&
            json['action'] == 'challenge') {
          // 计算真实的质疑成功率
          double challengeSuccessRate = json['challenge_success_rate'] != null ? 
              (json['challenge_success_rate'] as num).toDouble() : 0.0;
          
          // 只有当质疑成功率很低时才修正（因为我们已经有足够的骰子）
          if (challengeSuccessRate < 0.2) {
            AILogger.logParsing('⚠️ 逻辑修正', {
              'AI已有': ourCounts[round.currentBid!.value],
              '需要': round.currentBid!.quantity,
              '质疑成功率': challengeSuccessRate,
              '原决策': 'challenge',
              '修正为': 'bid'
            });
            shouldOverride = true;
            finalAction = GameAction.bid;
            finalProbability = 1.0;
          }
        }
        
        final decision = AIDecision(
          playerBid: round.currentBid,
          action: finalAction,
          probability: finalProbability,
          wasBluffing: false,
          reasoning: shouldOverride ? '我已有足够骰子' : (json['reasoning'] ?? ''),
        );
        
        // 处理emotions数组或单个emotion字段
        List<String> emotions;
        if (shouldOverride) {
          emotions = ['confident'];
        } else if (json['emotions'] != null && json['emotions'] is List) {
          emotions = List<String>.from(json['emotions']);
        } else if (json['emotion'] != null) {
          // 兼容旧格式
          emotions = [json['emotion']];
        } else {
          emotions = ['thinking'];
        }
        
        final dialogue = shouldOverride ? '继续吧！' : (json['dialogue'] ?? '');
        
        return (decision, emotions, dialogue);
      } else {
        AILogger.logParsing('警告', '响应中未找到JSON格式');
        AILogger.logParsing('清理后的响应', cleanResponse.substring(0, 
                           cleanResponse.length > 200 ? 200 : cleanResponse.length));
      }
    } catch (e) {
      AILogger.apiCallError('Gemini', '解析决策失败', e);
    }
    
    GameLogger.logGameState('使用降级逻辑');
    return (_fallbackDecision(round), ['thinking'], '');
  }
  
  /// 兼容旧的解析方法
  AIDecision _parseAIDecision(String response, GameRound round) {
    final (decision, _, _) = _parseAIDecisionWithEmotion(response, round);
    return decision;
  }
  
  /// 解析AI的叫牌响应（包含表情数组、reasoning和probability）
  (Bid, List<String>, String, bool, String, double) _parseAIBidWithEmotion(String response, GameRound round) {
    try {
      // 先尝试去除markdown代码块标记
      String cleanResponse = response;
      if (response.contains('```json')) {
        cleanResponse = response.replaceAll(RegExp(r'```json\s*'), '')
                                .replaceAll(RegExp(r'```'), '');
      }
      
      // 提取JSON部分 - 改进的正则表达式，支持多行
      final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', 
                               multiLine: true, dotAll: true).firstMatch(cleanResponse);
      
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final json = jsonDecode(jsonStr);
        
        AILogger.logParsing('叫牌JSON', json);
        
        Bid newBid = Bid(
          quantity: json['quantity'],
          value: json['value'],
        );
        
        // 验证叫牌是否合法
        bool isValid = round.currentBid == null || newBid.isHigherThan(round.currentBid!);
        AILogger.logParsing('合法性检查', isValid ? '通过' : '不通过');
        
        if (isValid) {
          // 处理emotions数组或单个emotion字段
          List<String> emotions;
          if (json['emotions'] != null && json['emotions'] is List) {
            emotions = List<String>.from(json['emotions']);
          } else if (json['emotion'] != null) {
            // 兼容旧格式
            emotions = [json['emotion']];
          } else {
            emotions = ['thinking'];
          }
          
          final dialogue = json['dialogue'] ?? '';
          final bluffing = json['bluffing'] == true;
          final reasoning = json['reasoning'] ?? '叫牌${newBid.quantity}个${newBid.value}';
          final probability = json['probability'] != null ? (json['probability'] as num).toDouble() : 0.5;
          return (newBid, emotions, dialogue, bluffing, reasoning, probability);
        } else {
          AILogger.logParsing('警告', 'AI生成的叫牌不合法');
        }
      } else {
        AILogger.logParsing('警告', '响应中未找到JSON格式');
        AILogger.logParsing('清理后的响应', cleanResponse.substring(0, 
                           cleanResponse.length > 200 ? 200 : cleanResponse.length));
      }
    } catch (e) {
      AILogger.apiCallError('Gemini', '解析叫牌失败', e);
    }
    
    GameLogger.logGameState('使用降级逻辑');
    final bid = _fallbackBid(round);
    final probability = _calculateBidProbability(bid, round.aiDice);
    return (bid, ['thinking'], '', false, '基于手牌选择', probability);
  }
  
  /// 兼容旧的解析方法
  Bid _parseAIBid(String response, GameRound round) {
    final (bid, _, _, _, _, _) = _parseAIBidWithEmotion(response, round);
    return bid;
  }
  
  /// 降级决策（当API失败时）
  AIDecision _fallbackDecision(GameRound round) {
    // 计算对手叫牌为真的概率
    int ourCount = round.aiDice.countValue(
      round.currentBid!.value, 
      onesAreCalled: round.onesAreCalled
    );
    int needed = round.currentBid!.quantity - ourCount;
    
    // 计算单个骰子是目标值的概率
    double singleProb;
    if (round.currentBid!.value == 1 || round.onesAreCalled) {
      singleProb = 1.0 / 6.0;
    } else {
      singleProb = 2.0 / 6.0; // 包含万能1
    }
    
    // 使用客观的二项分布计算
    double probability; // 客观的数学概率
    
    if (needed <= 0) {
      probability = 1.0; // 我们已经有足够的，叫牌肯定为真
    } else if (needed > 5) {
      probability = 0.0; // 不可能（对手只有5个骰子）
    } else {
      // 计算对手至少有needed个的概率（纯数学计算）
      probability = 0.0;
      for (int k = needed; k <= 5; k++) {
        double binomProb = 1.0;
        // 计算C(5,k) * p^k * (1-p)^(5-k)
        for (int i = 0; i < k; i++) {
          binomProb *= (5 - i) * singleProb / (i + 1);
        }
        binomProb *= Math.pow(1 - singleProb, 5 - k);
        probability += binomProb;
      }
      probability = probability.clamp(0.05, 0.95); // 避免极端值，但保持更宽的范围
    }
    
    // 注意：probability保持为纯数学计算的结果
    // 主观判断将在后续作为微调因子使用
    
    // 计算客观的质疑成功率
    double challengeSuccessRate = 1.0 - probability;
    
    // 特殊情况：如果AI已经有足够的骰子，绝对不能质疑
    if (needed <= 0) {
      // 必须叫牌，因为质疑必输
      Bid bestBid = _fallbackBid(round);
      return AIDecision(
        playerBid: round.currentBid,
        action: GameAction.bid,
        aiBid: bestBid,
        probability: probability,
        wasBluffing: false,
        reasoning: '我有足够的骰子，必须继续叫牌',
      );
    }
    
    // 计算最佳叫牌选择的成功率
    Bid bestBid = _fallbackBid(round);
    double bestBidSuccessRate = _calculateBidProbability(bestBid, round.aiDice, onesAreCalled: round.onesAreCalled || bestBid.value == 1);
    
    // 主观判断作为微调因子（基于历史数据和当前感觉）
    double subjectiveAdjustment = 0.0;
    if (round.playerBluffProbabilities.isNotEmpty) {
      double avgBluff = round.getAveragePlayerBluffProbability();
      // 如果历史虚张率高，稍微增加质疑倾向（最多±5%）
      subjectiveAdjustment = (avgBluff - 0.5) * 0.1;
    }
    
    // 调整后的质疑成功率（客观为主，主观微调）
    double adjustedChallengeRate = (challengeSuccessRate + subjectiveAdjustment).clamp(0.0, 1.0);
    
    // 根据性格的偏好阈值决定
    GameAction action;
    String reasoning;
    
    // 如果叫牌成功率明显高于调整后的质疑成功率（加上性格阈值）
    if (bestBidSuccessRate > adjustedChallengeRate + personality.bidPreferenceThreshold) {
      action = GameAction.bid;
      reasoning = '叫牌${(bestBidSuccessRate * 100).toStringAsFixed(0)}%>质疑${(adjustedChallengeRate * 100).toStringAsFixed(0)}%';
    } 
    // 如果调整后的质疑成功率达到性格阈值
    else if (adjustedChallengeRate > personality.challengeThreshold) {
      action = GameAction.challenge;
      reasoning = '质疑成功率${(adjustedChallengeRate * 100).toStringAsFixed(0)}%';
    } 
    // 否则选择成功率更高的
    else {
      if (bestBidSuccessRate > adjustedChallengeRate) {
        action = GameAction.bid;
        reasoning = '叫牌${(bestBidSuccessRate * 100).toStringAsFixed(0)}%>质疑${(adjustedChallengeRate * 100).toStringAsFixed(0)}%';
      } else {
        action = GameAction.challenge;
        reasoning = '质疑${(adjustedChallengeRate * 100).toStringAsFixed(0)}%>叫牌${(bestBidSuccessRate * 100).toStringAsFixed(0)}%';
      }
    }
    
    return AIDecision(
      playerBid: round.currentBid,
      action: action,
      probability: probability,
      wasBluffing: false,
      reasoning: reasoning,
    );
  }
  
  /// 降级叫牌（当API失败时）
  Bid _fallbackBid(GameRound round) {
    Bid? lastBid = round.currentBid;
    
    if (lastBid == null) {
      // 开局叫牌 - 基于自己的骰子
      Map<int, int> counts = _calculateOwnCounts(round.aiDice, false);
      int maxCount = 0;
      int bestValue = 3;
      for (int i = 2; i <= 6; i++) {
        if (counts[i]! > maxCount) {
          maxCount = counts[i]!;
          bestValue = i;
        }
      }
      // 保守开局，叫自己有的数量+1
      return Bid(quantity: Math.min(maxCount + 1, 3), value: bestValue);
    }
    
    // 分析自己有多少个目标点数
    Map<int, int> counts = _calculateOwnCounts(round.aiDice, round.onesAreCalled);
    
    // 教授的策略：基于概率计算的理性叫牌
    if (personality.id == 'professor') {
      // 计算各种可能的叫牌选项
      List<Bid> possibleBids = [];
      
      // 尝试增加数量
      if (lastBid.quantity < 10) {
        possibleBids.add(Bid(quantity: lastBid.quantity + 1, value: lastBid.value));
      }
      
      // 尝试增加点数
      if (lastBid.value < 6) {
        possibleBids.add(Bid(quantity: lastBid.quantity, value: lastBid.value + 1));
      } else if (lastBid.value == 6) {
        possibleBids.add(Bid(quantity: lastBid.quantity, value: 1));
      }
      
      // 选择最合理的叫牌
      Bid bestBid = possibleBids.first;
      double bestScore = -1;
      
      for (Bid bid in possibleBids) {
        int myCount = counts[bid.value]!;
        int needed = bid.quantity - myCount;
        
        // 计算对手需要有多少个（5个骰子中）
        // 单个骰子是目标值的概率
        double singleProb = (bid.value == 1 || round.onesAreCalled) ? 1/6 : 2/6;
        
        // 使用二项分布估算概率
        double probability = 0;
        if (needed <= 0) {
          probability = 1.0; // 我们已经有足够了
        } else if (needed <= 5) {
          // 简化的概率计算
          probability = 1.0 - Math.pow(1 - singleProb, 5) * 
                       Math.pow(5, needed) / Math.pow(6, needed);
          probability = Math.max(0.1, Math.min(0.9, probability));
        }
        
        // 教授偏好高概率的叫牌
        double score = probability;
        if (probability > 0.6) {
          score += 0.2; // 奖励高概率
        }
        
        if (score > bestScore) {
          bestScore = score;
          bestBid = bid;
        }
      }
      
      // 教授很少纯粹虚张（只有20%概率）
      // 如果最佳选择的概率太低，可能选择挑战而不是继续叫牌
      if (bestScore < 0.3 && Random().nextDouble() > 0.2) {
        // 这种情况下应该挑战，但由于是生成叫牌，返回保守的叫牌
        if (lastBid.value < 6) {
          return Bid(quantity: lastBid.quantity, value: lastBid.value + 1);
        } else {
          return Bid(quantity: lastBid.quantity + 1, value: 2);
        }
      }
      
      return bestBid;
    }
    
    // 赌徒：更激进
    if (personality.id == 'gambler') {
      // 60%概率虚张
      if (Random().nextDouble() < 0.6) {
        // 大幅增加
        if (Random().nextDouble() < 0.5 && lastBid.quantity < 8) {
          return Bid(quantity: lastBid.quantity + 2, value: lastBid.value);
        } else if (lastBid.value == 6) {
          return Bid(quantity: lastBid.quantity + 1, value: Random().nextInt(5) + 2);
        } else {
          return Bid(quantity: lastBid.quantity + 1, value: Random().nextInt(6 - lastBid.value) + lastBid.value + 1);
        }
      }
    }
    
    // 默认策略 - 优先考虑自己有很多的点数
    // 查找自己最多的点数
    int maxCount = 0;
    int bestValue = 2;
    for (int value = 1; value <= 6; value++) {
      if (counts[value]! > maxCount) {
        maxCount = counts[value]!;
        bestValue = value;
      }
    }
    
    // 如果自己有很多某个点数，优先叫这个
    if (maxCount >= 3) {
      // 尝试叫自己有很多的点数
      if (bestValue > lastBid.value) {
        return Bid(quantity: lastBid.quantity, value: bestValue);
      } else if (bestValue == lastBid.value && lastBid.quantity < maxCount + 2) {
        return Bid(quantity: Math.min(lastBid.quantity + 1, maxCount + 2), value: bestValue);
      } else if (bestValue < lastBid.value && lastBid.quantity < maxCount + 1) {
        return Bid(quantity: Math.min(lastBid.quantity + 1, maxCount + 1), value: bestValue);
      }
    }
    
    // 否则使用简单递增策略
    if (lastBid.value < 6) {
      return Bid(quantity: lastBid.quantity, value: lastBid.value + 1);
    } else {
      return Bid(quantity: lastBid.quantity + 1, value: 2);
    }
  }
  
  /// 生成对话和表情（可以也用AI生成）
  Future<(String dialogue, String expression)> generateDialogue(
    GameRound round, 
    GameAction? action,
    Bid? newBid,
  ) async {
    // 暂时使用简单逻辑，也可以调用AI
    if (action == GameAction.challenge) {
      return ('让我看看你的牌！', 'confident');
    } else if (newBid != null) {
      return ('我叫${newBid}', 'thinking');
    }
    return ('', 'neutral');
  }
  
  /// 构建简化的AI决策prompt - AI只负责性格化选择
  String _buildPersonalityDecisionPrompt(GameRound round) {
    // 本地计算所有选项
    List<Map<String, dynamic>> options = _calculateAllOptions(round);
    
    // 获取性格描述
    String personalityDesc = _getPersonalityDescription();
    
    // 构建选项列表
    List<String> optionDescriptions = [];
    for (int i = 0; i < options.length && i < 5; i++) {
      var opt = options[i];
      String desc = '';
      if (opt['type'] == 'challenge') {
        desc = '${i+1}. 质疑 - 成功率${(opt['successRate']*100).toStringAsFixed(0)}% (${opt['riskLevel']})';
      } else {
        desc = '${i+1}. 叫${opt['quantity']}个${opt['value']} - 成功率${(opt['successRate']*100).toStringAsFixed(0)}% (${opt['riskLevel']}/策略:${opt['strategy']})';
      }
      optionDescriptions.add(desc);
    }
    
    // 获取玩家统计信息
    String playerStats = '';
    if (playerProfile != null && playerProfile!.totalGames > 0) {
      playerStats = '''
对手统计（${playerProfile!.totalGames}局）：
- 虚张倾向：${(playerProfile!.bluffingTendency * 100).toInt()}%
- 激进程度：${(playerProfile!.aggressiveness * 100).toInt()}%
- 胜率：${(playerProfile!.totalWins * 100.0 / playerProfile!.totalGames).toInt()}%''';
    }
    
    return '''
你是${personality.name}，正在玩骰子游戏。
$personalityDesc

当前局势：已进行${round.bidHistory.length}轮
$playerStats

可选方案：
${optionDescriptions.join('\n')}

你的性格参数：
- 冒险倾向：${(personality.riskAppetite * 100).toInt()}%
- 虚张倾向：${(personality.bluffRatio * 100).toInt()}%
- 质疑阈值：${(personality.challengeThreshold * 100).toInt()}%

表情选择（选一个）：
思考/自信/紧张/高兴/质疑

决策指导：
- 保守型选safe，激进型选risky
- 虚张高选bluff策略
- 根据对手特征调整策略

只输出JSON格式：
{
  "choice": 1-5,
  "emotion": "表情(5选1)",
  "dialogue": "符合性格的台词(15字内)"
}
''';
  }
  
  /// 解析AI的性格化选择
  (AIDecision, Bid?, List<String>, String, bool, double?) _parsePersonalityChoice(
    String response, 
    List<Map<String, dynamic>> options,
    GameRound round
  ) {
    try {
      // 提取JSON
      String cleanResponse = response;
      if (response.contains('```json')) {
        cleanResponse = response.replaceAll(RegExp(r'```json\s*'), '')
                                .replaceAll(RegExp(r'```'), '');
      }
      
      // 尝试多种方式找到JSON
      int firstBrace = cleanResponse.indexOf('{');
      int lastBrace = cleanResponse.lastIndexOf('}');
      
      // 如果响应被截断，尝试找到部分JSON
      if (firstBrace == -1 && cleanResponse.contains('"choice"')) {
        // 可能JSON格式不完整，尝试重建
        RegExp choiceRegex = RegExp(r'"choice"\s*:\s*(\d+)');
        var match = choiceRegex.firstMatch(cleanResponse);
        if (match != null) {
          int choice = int.parse(match.group(1)!);
          // 构造一个最小的有效JSON
          cleanResponse = '{"choice": $choice, "emotion": "thinking", "dialogue": ""}';
          firstBrace = 0;
          lastBrace = cleanResponse.length - 1;
        }
      }
      
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        final jsonStr = cleanResponse.substring(firstBrace, lastBrace + 1);
        Map<String, dynamic>? json;
        
        try {
          json = jsonDecode(jsonStr);
        } catch (e) {
          // JSON解析失败，记录错误
          AILogger.logParsing('JSON解析失败', {'error': e.toString(), 'json': jsonStr});
        }
        
        if (json != null) {
          AILogger.logParsing('AI性格化选择', json);
          
          // 获取选择的选项
          int choiceIndex = (json['choice'] as num).toInt() - 1;
          if (choiceIndex < 0 || choiceIndex >= options.length) {
            choiceIndex = 0; // 默认选最优
          }
          
          var chosenOption = options[choiceIndex];
          
          // 构建决策
          AIDecision decision;
          Bid? newBid;
          bool bluffing = false;
          
          if (chosenOption['type'] == 'challenge') {
            decision = AIDecision(
              playerBid: round.currentBid,
              action: GameAction.challenge,
              probability: chosenOption['successRate'],
              wasBluffing: false,
              reasoning: chosenOption['reasoning'],
            );
          } else {
            newBid = Bid(
              quantity: chosenOption['quantity'],
              value: chosenOption['value'],
            );
            bluffing = chosenOption['strategy'] == 'bluff' || 
                      chosenOption['strategy'] == 'slight_bluff';
            
            decision = AIDecision(
              playerBid: round.currentBid,
              action: GameAction.bid,
              aiBid: newBid,
              probability: chosenOption['successRate'],
              wasBluffing: bluffing,
              reasoning: chosenOption['reasoning'],
            );
          }
          
          // 处理情绪和对话
          String emotion = json['emotion'] ?? '思考';
          // 映射中文表情到英文（如果需要）
          Map<String, String> emotionMap = {
            '思考': 'thinking',
            '自信': 'confident', 
            '紧张': 'nervous',
            '高兴': 'happy',
            '质疑': 'suspicious'
          };
          String mappedEmotion = emotionMap[emotion] ?? emotion;
          List<String> emotions = [mappedEmotion];
          String dialogue = json['dialogue'] ?? '';
          
          return (decision, newBid, emotions, dialogue, bluffing, null);
        }
      }
    } catch (e) {
      AILogger.apiCallError('Gemini', '解析性格化选择失败', e);
    }
    
    // 降级：选择最优选项
    if (options.isNotEmpty) {
      var bestOption = options[0];
      if (bestOption['type'] == 'challenge') {
        final decision = AIDecision(
          playerBid: round.currentBid,
          action: GameAction.challenge,
          probability: bestOption['successRate'],
          wasBluffing: false,
          reasoning: '最优选择',
        );
        return (decision, null, ['thinking'], '', false, null);
      } else {
        final bid = Bid(
          quantity: bestOption['quantity'],
          value: bestOption['value'],
        );
        final decision = AIDecision(
          playerBid: round.currentBid,
          action: GameAction.bid,
          aiBid: bid,
          probability: bestOption['successRate'],
          wasBluffing: false,
          reasoning: '最优选择',
        );
        return (decision, bid, ['thinking'], '', false, null);
      }
    }
    
    // 最后的降级
    return _parseCompleteDecision('', round);
  }
  
  /// 解析合并的AI响应（保留作为降级方案）
  (AIDecision, Bid?, List<String>, String, bool, double?) _parseCompleteDecision(String response, GameRound round) {
    try {
      // 清理响应
      String cleanResponse = response;
      if (response.contains('```json')) {
        cleanResponse = response.replaceAll(RegExp(r'```json\s*'), '')
                                .replaceAll(RegExp(r'```'), '');
      }
      
      // 提取JSON - 改进的方法：找到第一个{和最后一个}
      int firstBrace = cleanResponse.indexOf('{');
      int lastBrace = cleanResponse.lastIndexOf('}');
      
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        final jsonStr = cleanResponse.substring(firstBrace, lastBrace + 1);
        
        // 尝试解析JSON
        Map<String, dynamic>? json;
        try {
          json = jsonDecode(jsonStr);
        } catch (e) {
          // 如果解析失败，尝试使用正则表达式提取
          final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', 
                                   multiLine: true, dotAll: true).firstMatch(cleanResponse);
          if (jsonMatch != null) {
            json = jsonDecode(jsonMatch.group(0)!);
          }
        }
        
        if (json == null) {
          throw Exception('无法解析JSON');
        }
        
        AILogger.logParsing('完整决策JSON', json);
        
        // 验证概率计算的正确性
        if (json['probability'] != null && json['challenge_success_rate'] != null) {
          double prob = (json['probability'] as num).toDouble();
          double challengeRate = (json['challenge_success_rate'] as num).toDouble();
          double expectedChallengeRate = 1.0 - prob;
          
          if ((challengeRate - expectedChallengeRate).abs() > 0.05) {
            AILogger.logParsing('⚠️ 概率计算异常', {
              'probability': prob,
              'challenge_success_rate': challengeRate,
              '预期值': expectedChallengeRate,
              '差异': (challengeRate - expectedChallengeRate).abs()
            });
          }
        }
        
        // 输出决策分析过程
        if (json['all_options'] != null) {
          AILogger.logParsing('📊 所有选项分析', json['all_options']);
        }
        if (json['filtered_options'] != null) {
          AILogger.logParsing('🎯 符合性格的选项', json['filtered_options']);
        }
        if (json['decision_reasoning'] != null) {
          AILogger.logParsing('💭 决策理由', json['decision_reasoning']);
        }
        
        // 验证逻辑
        Map<int, int> ourCounts = {};
        for (int i = 1; i <= 6; i++) {
          ourCounts[i] = round.aiDice.countValue(i, onesAreCalled: round.onesAreCalled);
        }
        
        // 检查必要字段是否存在
        if (json['action'] == null || json['probability'] == null) {
          AILogger.logParsing('⚠️ JSON缺少必要字段', json);
          throw Exception('JSON缺少必要字段');
        }
        
        // 检查决策合理性
        bool shouldOverride = false;
        GameAction finalAction = json['action'] == 'challenge' ? GameAction.challenge : GameAction.bid;
        double finalProbability = (json['probability'] as num).toDouble();
        
        // 修复：只有当AI已经有足够的骰子并且质疑成功率很低时才修正
        if (round.currentBid != null && 
            ourCounts[round.currentBid!.value]! >= round.currentBid!.quantity &&
            json['action'] == 'challenge') {
          // 计算真实的质疑成功率
          double challengeSuccessRate = json['challenge_success_rate'] != null ? 
              (json['challenge_success_rate'] as num).toDouble() : 0.0;
          
          // 只有当质疑成功率很低时才修正（因为我们已经有足够的骰子）
          if (challengeSuccessRate < 0.2) {
            AILogger.logParsing('⚠️ 逻辑修正', {
              'AI已有': ourCounts[round.currentBid!.value],
              '需要': round.currentBid!.quantity,
              '质疑成功率': challengeSuccessRate,
              '原决策': 'challenge',
              '修正为': 'bid'
            });
            shouldOverride = true;
            finalAction = GameAction.bid;
            finalProbability = 1.0;
          }
        }
        
        // 构建决策
        AIDecision decision;
        Bid? newBid;
        bool bluffing = false;
        
        if (finalAction == GameAction.challenge) {
          decision = AIDecision(
            playerBid: round.currentBid,
            action: GameAction.challenge,
            probability: finalProbability,
            wasBluffing: false,
            reasoning: shouldOverride ? '我已有足够骰子' : (json['reasoning'] ?? ''),
          );
        } else {
          // 需要生成叫牌
          if (shouldOverride || json['bid_quantity'] == null || json['bid_value'] == null) {
            // 如果被修正或缺少叫牌信息，使用降级方法
            newBid = _fallbackBid(round);
          } else {
            newBid = Bid(
              quantity: json['bid_quantity'],
              value: json['bid_value'],
            );
            // 验证叫牌合法性
            if (round.currentBid != null && !newBid.isHigherThan(round.currentBid!)) {
              newBid = _fallbackBid(round);
            }
          }
          
          bluffing = json['bluffing'] ?? false;
          decision = AIDecision(
            playerBid: round.currentBid,
            action: GameAction.bid,
            aiBid: newBid,
            probability: finalProbability,
            wasBluffing: bluffing,
            reasoning: json['reasoning'] ?? '',
          );
        }
        
        // 处理emotions数组
        List<String> emotions;
        if (shouldOverride) {
          emotions = ['confident'];
        } else if (json['emotions'] != null && json['emotions'] is List) {
          emotions = List<String>.from(json['emotions']);
        } else if (json['emotion'] != null) {
          // 兼容旧格式
          emotions = [json['emotion']];
        } else {
          emotions = ['thinking'];
        }
        
        final dialogue = shouldOverride ? '继续吧！' : (json['dialogue'] ?? '');
        
        // 提取玩家虚张概率，但不在这里记录
        double? playerBluffProb;
        if (json['player_bluff_probability'] != null && round.currentBid != null) {
          playerBluffProb = (json['player_bluff_probability'] as num).toDouble();
          AILogger.logParsing('玩家虚张概率', '${(playerBluffProb * 100).toStringAsFixed(0)}%');
        }
        
        return (decision, newBid, emotions, dialogue, bluffing, playerBluffProb);
      }
    } catch (e) {
      AILogger.apiCallError('Gemini', '解析完整决策失败', e);
    }
    
    // 降级处理
    GameLogger.logGameState('使用降级逻辑');
    final decision = _fallbackDecision(round);
    if (decision.action == GameAction.challenge) {
      return (decision, null, ['thinking'], '', false, null);
    } else {
      final bid = _fallbackBid(round);
      final updatedDecision = AIDecision(
        playerBid: decision.playerBid,
        action: decision.action,
        aiBid: bid,
        probability: decision.probability,
        wasBluffing: decision.wasBluffing,
        reasoning: decision.reasoning,
      );
      return (updatedDecision, bid, ['thinking'], '', false, null);
    }
  }
  
  /// 计算叫牌成功的概率（通用方法）
  double _calculateBidProbability(Bid bid, DiceRoll aiDice, {bool onesAreCalled = false}) {
    int myCount = aiDice.countValue(bid.value, onesAreCalled: onesAreCalled);
    return _calculateFirstBidProbability(bid, myCount);
  }
  
  /// 计算首轮叫牌的成功概率
  double _calculateFirstBidProbability(Bid bid, int myCount) {
    // 我有myCount个，需要bid.quantity个
    int needed = bid.quantity - myCount;
    
    if (needed <= 0) {
      // 已经有足够的骰子
      return 1.0;
    }
    
    // 对手有5个骰子，计算对手至少有needed个的概率
    // 使用简化的二项分布估算
    double singleDieProb = bid.value == 1 ? 1.0/6.0 : 2.0/6.0; // 1没有万能牌，其他有
    
    if (needed > 5) {
      return 0.0; // 不可能
    }
    
    // 简化计算：对手至少有needed个的概率
    double probability = 0.0;
    for (int k = needed; k <= 5; k++) {
      // 二项分布的简化计算
      double p = 1.0;
      for (int i = 0; i < k; i++) {
        p *= (5 - i) * singleDieProb / (i + 1);
      }
      p *= Math.pow(1 - singleDieProb, 5 - k);
      probability += p;
    }
    
    return probability.clamp(0.0, 1.0);
  }
  
  /// 生成本地计算的reasoning
  String _generateLocalReasoning(Bid bid, DiceRoll aiDice) {
    int myCount = aiDice.countValue(bid.value, onesAreCalled: false);
    String reasoning = '手上有${myCount}个${bid.value}';
    
    if (myCount >= bid.quantity) {
      reasoning += '，稳健叫牌';
    } else if (myCount == 0) {
      reasoning += '，纯虚张';
    } else {
      reasoning += '，叫${bid.quantity}个${bid.value}';
    }
    
    return reasoning;
  }
  
  /// 分析玩家虚张概率
  String _analyzePlayerBluffProbability(GameRound round) {
    if (round.currentBid == null) {
      return '首轮叫牌，无历史数据';
    }
    
    // 计算玩家手上可能有的数量
    int aiHas = round.aiDice.countValue(round.currentBid!.value, onesAreCalled: round.onesAreCalled);
    int playerNeeds = Math.max(0, round.currentBid!.quantity - aiHas);
    
    // 基于概率计算玩家虚张的可能性
    double bluffProb = 0.0;
    if (playerNeeds > 3) {
      bluffProb = 0.8; // 玩家需要太多，很可能虚张
    } else if (playerNeeds > 2) {
      bluffProb = 0.6; // 中等虚张概率
    } else if (playerNeeds > 1) {
      bluffProb = 0.4; // 较低虚张概率
    } else {
      bluffProb = 0.2; // 玩家只需要0-1个，不太可能虚张
    }
    
    // 结合历史虚张数据
    String analysis = '玩家需要至少${playerNeeds}个${round.currentBid!.value}';
    
    // 如果有历史虚张数据
    if (round.playerBluffProbabilities.isNotEmpty) {
      double avgBluff = round.getAveragePlayerBluffProbability();
      analysis += '\n历史平均虚张概率：${(avgBluff * 100).toStringAsFixed(0)}%';
      
      // 结合历史和当前分析
      bluffProb = bluffProb * 0.7 + avgBluff * 0.3; // 70%当前分析，30%历史数据
    }
    
    analysis += '\n预估虚张概率：${(bluffProb * 100).toStringAsFixed(0)}%';
    
    // 根据虚张概率给出建议
    if (bluffProb > 0.7) {
      analysis += '\n🚨 高度怀疑玩家在虚张！';
    } else if (bluffProb > 0.5) {
      analysis += '\n⚠️ 玩家可能在虚张';
    } else {
      analysis += '\n✅ 玩家叫牌可信度较高';
    }
    
    return analysis;
  }
}
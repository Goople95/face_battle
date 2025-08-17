import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/ai_personality.dart';
import '../models/player_profile.dart';
import '../models/drinking_state.dart';
import '../services/ai_service.dart';
import '../services/gemini_service.dart';
import '../services/auth_service.dart';
import '../utils/ad_helper.dart';
import '../config/api_config.dart';
import '../config/character_assets.dart';
import '../utils/logger_utils.dart';
import '../widgets/animated_ai_face.dart';
import '../widgets/simple_ai_avatar.dart';
import '../widgets/simple_video_avatar.dart';  // 使用简化版
import '../widgets/drunk_overlay.dart';
import '../widgets/sober_dialog.dart';

class GameScreen extends StatefulWidget {
  final AIPersonality aiPersonality;
  
  const GameScreen({
    Key? key,
    required this.aiPersonality,
  }) : super(key: key);
  
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late AIService _aiService;
  late GeminiService _geminiService;
  PlayerProfile? _playerProfile;
  DrinkingState? _drinkingState;
  bool _useRealAI = ApiConfig.useRealAI;
  
  GameRound? _currentRound;
  bool _showDice = false;
  bool _gameStarted = false;  // Track if game has started
  bool _playerChallenged = false; // Track who challenged
  
  // UI Controllers
  int _selectedQuantity = 2;  // 起叫最少2个
  int _selectedValue = 2;
  
  // AI Expression and Dialogue
  String _aiExpression = 'excited';  // 默认表情改为 excited
  String _aiDialogue = '';
  String _currentEmotion = '兴奋'; // 用于显示当前表情文字
  String _currentVideoFile = 'excited.mp4'; // 用于显示当前视频文件名
  List<String> _emotionQueue = []; // 情绪播放队列
  int _currentEmotionIndex = 0; // 当前播放的情绪索引
  
  // 精细表情控制
  final GlobalKey<SimpleAIAvatarState> _avatarKey = GlobalKey<SimpleAIAvatarState>();
  String _currentAIEmotion = 'excited';  // 当前AI表情，默认excited
  
  // Probability calculation for our bid
  double _calculateBidProbability() {
    if (_currentRound == null) return 0.0;
    
    // Count how many we have
    int ourCount = _currentRound!.playerDice.countValue(
      _selectedValue, 
      onesAreCalled: _currentRound!.onesAreCalled || _selectedValue == 1,
    );
    int totalDice = 10; // 5 + 5
    int unknownDice = 5; // AI's dice
    int needed = _selectedQuantity - ourCount;
    
    if (needed <= 0) return 1.0; // We already have enough
    if (needed > unknownDice) return 0.0; // Impossible
    
    // Calculate binomial probability
    double singleDieProbability;
    if (_selectedValue == 1) {
      // Looking for 1s: only actual 1s count
      singleDieProbability = 1.0 / 6.0;
    } else if (_currentRound!.onesAreCalled) {
      // 1s already called, so only the specific value counts
      singleDieProbability = 1.0 / 6.0;
    } else {
      // 1s are still wild
      singleDieProbability = 2.0 / 6.0;
    }
    
    double probability = 0.0;
    for (int k = needed; k <= unknownDice; k++) {
      probability += _binomialProbability(unknownDice, k, singleDieProbability);
    }
    
    return probability.clamp(0.0, 1.0);
  }
  
  // Probability calculation for challenging current bid
  double _calculateChallengeProbability() {
    if (_currentRound == null || _currentRound!.currentBid == null) return 0.5;
    
    final bid = _currentRound!.currentBid!;
    
    // Count how many we have
    int ourCount = _currentRound!.playerDice.countValue(
      bid.value,
      onesAreCalled: _currentRound!.onesAreCalled,
    );
    
    // Extra debug check
    if (ourCount == 0 && bid.value == 2) {
      GameLogger.logGameState('WARNING: 计数为0但有2!', details: {
        '骰子详情': _currentRound!.playerDice.values.map((v) => 'Die:$v').join(', '),
      });
    }
    
    // AI需要有多少个才能让叫牌成立
    int aiNeeded = bid.quantity - ourCount;
    int aiDiceCount = 5; // AI has 5 dice
    
    // 调试日志 - 修正显示信息
    GameLogger.logGameState('质疑概率计算（玩家视角）', details: {
      '叫牌': bid.toString(),
      '叫牌值': bid.value,
      '叫牌量': bid.quantity,
      '玩家骰子': _currentRound!.playerDice.values.toString(),
      'AI骰子数': aiDiceCount,
      '玩家有': ourCount,
      'AI需要': aiNeeded,
      '1是否被叫': _currentRound!.onesAreCalled,
    });
    
    // 如果AI需要的数量超过5个骰子，叫牌不可能成立
    if (aiNeeded > aiDiceCount) {
      GameLogger.logGameState('质疑必定成功', details: {
        '原因': 'AI需要${aiNeeded}个，超过5个骰子',
        '叫牌量': bid.quantity,
        '我们有': ourCount,
        'AI需要': aiNeeded,
      });
      return 1.0; // 100% chance challenge succeeds (bid is impossible)
    }
    
    // 如果AI需要的数量小于等于0，叫牌已经成立（我们已经有足够了）
    if (aiNeeded <= 0) {
      GameLogger.logGameState('质疑必定失败', details: {
        '原因': '玩家已有${ourCount}个，叫牌已成立',
        '叫牌量': bid.quantity,
        '玩家有': ourCount,
      });
      return 0.0; // 0% chance challenge succeeds (bid is already satisfied)
    }
    
    // Calculate probability AI has at least 'aiNeeded' of the value
    double singleDieProbability;
    if (bid.value == 1) {
      singleDieProbability = 1.0 / 6.0;
      GameLogger.logGameState('概率计算-叫1', details: {'单骰概率': '1/6'});
    } else if (_currentRound!.onesAreCalled) {
      singleDieProbability = 1.0 / 6.0;
      GameLogger.logGameState('概率计算-1已被叫', details: {'单骰概率': '1/6 (1不再是万能)'});
    } else {
      singleDieProbability = 2.0 / 6.0;
      GameLogger.logGameState('概率计算-普通', details: {'单骰概率': '2/6 (含万能1)'});
    }
    
    double aiHasProbability = 0.0;
    for (int k = aiNeeded; k <= aiDiceCount; k++) {
      aiHasProbability += _binomialProbability(aiDiceCount, k, singleDieProbability);
    }
    
    GameLogger.logGameState('质疑概率结果', details: {
      '单骰概率': singleDieProbability.toStringAsFixed(3),
      'AI有足够的概率': aiHasProbability.toStringAsFixed(3),
      '质疑成功率': (1.0 - aiHasProbability).toStringAsFixed(3),
    });
    
    // Challenge succeeds if AI doesn't have enough
    return 1.0 - aiHasProbability;
  }
  
  double _binomialProbability(int n, int k, double p) {
    if (k > n) return 0.0;
    
    double coefficient = 1.0;
    for (int i = 0; i < k; i++) {
      coefficient *= (n - i) / (i + 1);
    }
    
    return coefficient * math.pow(p, k) * math.pow(1 - p, n - k);
  }
  
  @override
  void initState() {
    super.initState();
    _loadPlayerProfile();
    // 确保初始表情变量同步
    _applyAIEmotion(_aiExpression, 0.5, false);
    // Don't start game automatically
  }
  
  Future<void> _loadPlayerProfile() async {
    _playerProfile = await PlayerProfile.load();
    _drinkingState = await DrinkingState.load();
    // 初始化AI服务，传入玩家画像
    _aiService = AIService(personality: widget.aiPersonality);
    _geminiService = GeminiService(
      personality: widget.aiPersonality,
      playerProfile: _playerProfile,
    );
    setState(() {}); // Update UI after loading
  }
  
  void _startGame() {
    // 检查是否醉酒
    if (_drinkingState != null && _drinkingState!.isDrunk) {
      _showSoberDialog();
      return;
    }
    
    setState(() {
      _gameStarted = true;
    });
    _startNewRound();
    
    // 显示对战记录
    // 加载对战记录，无需显示通知
  }
  
  void _startNewRound() {
    final random = math.Random();
    
    // 生成骰子的函数
    DiceRoll rollDice() {
      return DiceRoll([
        random.nextInt(6) + 1,
        random.nextInt(6) + 1,
        random.nextInt(6) + 1,
        random.nextInt(6) + 1,
        random.nextInt(6) + 1,
      ]);
    }
    
    // 检查是否需要重摇（5个骰子都不相同）
    bool needReroll(DiceRoll dice) {
      Set<int> uniqueValues = dice.values.toSet();
      return uniqueValues.length == 5; // 如果有5个不同的值，说明都不相同
    }
    
    // Roll dice - 5 dice each
    DiceRoll playerDice = rollDice();
    int playerRerollCount = 0;
    while (needReroll(playerDice)) {
      playerRerollCount++;
      GameLogger.logGameState('玩家骰子自动重摇', details: {
        '原骰子': playerDice.values.toString(),
        '原因': '5个骰子都不相同',
      });
      playerDice = rollDice();
    }
    
    DiceRoll aiDice = rollDice();
    int aiRerollCount = 0;
    while (needReroll(aiDice)) {
      aiRerollCount++;
      GameLogger.logGameState('AI骰子自动重摇', details: {
        '原骰子': aiDice.values.toString(),
        '原因': '5个骰子都不相同',
      });
      aiDice = rollDice();
    }
    
    // 骰子重摇完成，无需通知用户
    
    // 先确定表情
    final newExpression = random.nextBool() ? 'thinking' : 'confident';
    final isPlayerFirst = random.nextBool();
    
    setState(() {
      _currentRound = GameRound(
        playerDice: playerDice,
        aiDice: aiDice,
        isPlayerTurn: isPlayerFirst,
      );
      _showDice = false; // Don't show AI dice at start
      _aiExpression = isPlayerFirst ? 'thinking' : 'confident';
      _aiDialogue = isPlayerFirst 
        ? '轮到你了'
        : '让我先来！';
      _currentAIEmotion = _aiExpression;  // 同步更新视频表情
    });
    
    // 初始化AI表情 - 确保所有变量同步更新
    _applyAIEmotion(_aiExpression, 0.5, false);
    
    // If AI goes first
    if (!_currentRound!.isPlayerTurn) {
      _aiTurn();
    }
  }
  
  void _playerBid() {
    if (_currentRound == null || !_currentRound!.isPlayerTurn) return;
    
    final newBid = Bid(quantity: _selectedQuantity, value: _selectedValue);
    
    // Validate bid
    // 检查起叫最少2个
    if (_currentRound!.currentBid == null && newBid.quantity < 2) {
      _showSnackBar('起叫最少2个');
      return;
    }
    
    if (_currentRound!.currentBid != null &&
        !newBid.isHigherThan(_currentRound!.currentBid!, onesAreCalled: _currentRound!.onesAreCalled)) {
      // 特殊提示：如果之前叫了1，换其他数字必须增加数量
      if (_currentRound!.currentBid!.value == 1 && newBid.value != 1) {
        _showSnackBar('叫了1之后，换其他数字必须增加数量');
      } else {
        _showSnackBar('出价必须高于当前报数');
      }
      return;
    }
    
    setState(() {
      // Check if 1s are being called
      _currentRound!.addBid(newBid, true); // true表示是玩家叫牌
      _currentRound!.isPlayerTurn = false;
      // Reset AI expression when player bids
      _aiExpression = 'thinking';
      _aiDialogue = '让我想想...';
    });
    // 立即更新表情映射
    _applyAIEmotion('thinking', 0.5, false);
    
    // AI's turn
    _aiTurn();
  }
  
  void _playerChallenge() {
    if (_currentRound == null || 
        !_currentRound!.isPlayerTurn || 
        _currentRound!.currentBid == null) return;
    
    _resolveChallenge(true);
  }
  
  Future<void> _aiTurn() async {
    if (_currentRound == null || _currentRound!.isPlayerTurn) return;
    
    // Simulate thinking time
    await Future.delayed(const Duration(seconds: 2));
    
    // 使用合并的API调用
    AIDecision decision;
    Bid? aiBid;
    List<String> aiEmotions = ['thinking']; // 默认情绪数组
    String aiDialogue = '';
    bool wasBluffing = false;
    
    if (_useRealAI && ApiConfig.geminiApiKey != 'YOUR_API_KEY_HERE') {
      GameLogger.logAIAction('使用Gemini AI决策', data: {'personality': widget.aiPersonality.name});
      try {
        // 一次API调用完成决策和叫牌
        final (dec, bid, emotions, dialogue, bluffing, playerBluffProb) = await _geminiService.makeCompleteDecision(_currentRound!);
        decision = dec;
        aiBid = bid;
        aiEmotions = emotions; // 现在是数组
        aiDialogue = dialogue;
        wasBluffing = bluffing;
        
        // 如果有玩家虚张概率，记录到GameRound
        if (playerBluffProb != null && _currentRound!.currentBid != null) {
          _currentRound!.playerBluffProbabilities.add(playerBluffProb);
        }
        AILogger.apiCallSuccess('GameScreen', '合并决策', result: decision.action.toString());
      } catch (e) {
        AILogger.apiCallError('GameScreen', '合并决策', e);
        // 降级到本地算法
        decision = _aiService.decideAction(_currentRound!, null);
        if (decision.action == GameAction.bid) {
          final result = _aiService.generateBidWithAnalysis(_currentRound!);
          aiBid = result.$1;
          wasBluffing = result.$2;
        }
        // 使用本地AI生成表情
        final (dialogue, expression) = _aiService.generateDialogue(
          _currentRound!, 
          decision.action,
          aiBid,
        );
        aiEmotions = [expression]; // 转换为数组
        aiDialogue = dialogue;
      }
    } else {
      GameLogger.logAIAction('使用本地算法', data: {'personality': widget.aiPersonality.name});
      if (ApiConfig.geminiApiKey == 'YOUR_API_KEY_HERE') {
        GameLogger.logGameState('API密钥未配置');
      }
      decision = _aiService.decideAction(_currentRound!, null);
      if (decision.action == GameAction.bid) {
        final result = _aiService.generateBidWithAnalysis(_currentRound!);
        aiBid = result.$1;
        wasBluffing = result.$2;
      }
      // 使用本地AI生成表情
      final (dialogue, expression) = _aiService.generateDialogue(
        _currentRound!, 
        decision.action,
        aiBid,
      );
      aiEmotions = [expression]; // 转换为数组
      aiDialogue = dialogue;
    }
    
    // 如果是首次叫牌，需要根据实际叫牌重新计算概率
    if (decision.action == GameAction.bid && _currentRound!.currentBid == null && aiBid != null) {
      // 计算实际叫牌的成功概率
      double actualProbability = _aiService.calculateBidProbability(
        aiBid,
        _currentRound!.aiDice,
        _currentRound!.totalDiceCount,
        onesAreCalled: _currentRound!.onesAreCalled,
      );
      
      // 创建更新后的decision
      decision = AIDecision(
        playerBid: decision.playerBid,
        action: decision.action,
        aiBid: aiBid,
        probability: actualProbability,
        wasBluffing: wasBluffing,
        reasoning: decision.reasoning,
      );
    }
    
    // Record AI decision
    _currentRound!.aiDecisions.add(decision);
    
    if (decision.action == GameAction.challenge) {
      // 使用Gemini或本地生成的表情
      setState(() {
        _aiDialogue = aiDialogue;
        _emotionQueue = aiEmotions; // 设置情绪队列
        _currentEmotionIndex = 0;
      });
      
      // 开始播放情绪序列
      _playEmotionSequence(decision.probability, true);
      
      // Wait a bit to show the dialogue
      await Future.delayed(const Duration(seconds: 1));
      
      _resolveChallenge(false);
    } else {
      // AI makes a bid - 叫牌已经在上面的合并调用中生成
      if (aiBid == null) {
        // 如果没有生成叫牌（不应该发生），使用降级方法
        GameLogger.logAIAction('生成降级叫牌', data: {'personality': widget.aiPersonality.name});
        final result = _aiService.generateBidWithAnalysis(_currentRound!);
        aiBid = result.$1;
        wasBluffing = result.$2;
        // 使用本地AI生成表情
        final (dialogue, expression) = _aiService.generateDialogue(
          _currentRound!, 
          GameAction.bid,
          aiBid,
        );
        aiEmotions = [expression]; // 转换为数组
        aiDialogue = dialogue;
        GameLogger.logAIAction('本地叫牌结果', data: {'bid': aiBid.toString(), 'bluffing': wasBluffing});
      }
      
      // Calculate bid probability for AI's own bid
      double bidProb = _aiService.calculateBidProbability(
        aiBid,
        _currentRound!.aiDice,
        10,
        onesAreCalled: _currentRound!.onesAreCalled || aiBid.value == 1,
      );
      
      // Decision already contains bid info from makeCompleteDecision
      
      setState(() {
        // Check if 1s are being called
        if (aiBid != null) {
          _currentRound!.addBid(aiBid, false); // false表示是AI叫牌
          
          // 自动调整玩家选择器到AI的叫牌值，方便玩家操作
          _selectedQuantity = aiBid.quantity;
          _selectedValue = aiBid.value;
        }
        _currentRound!.isPlayerTurn = true;
        _aiDialogue = aiDialogue;
        _emotionQueue = aiEmotions; // 设置情绪队列
        _currentEmotionIndex = 0;
      });
      
      // 开始播放情绪序列
      _playEmotionSequence(wasBluffing ? 0.7 : 0.3, true);
      
      // Clear dialogue after a few seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _aiDialogue = '';
          });
        }
      });
    }
  }
  
  void _resolveChallenge(bool playerChallenged) {
    if (_currentRound == null || _currentRound!.currentBid == null) return;
    
    final isBidTrue = _currentRound!.isBidTrue(_currentRound!.currentBid!);
    
    String winner;
    if (playerChallenged) {
      winner = isBidTrue ? 'AI' : 'Player';
      // 记录玩家质疑
      if (_playerProfile != null) {
        _playerProfile!.totalChallenges++;
        if (!isBidTrue) {
          _playerProfile!.successfulChallenges++;
        }
      }
    } else {
      winner = isBidTrue ? 'Player' : 'AI';
    }
    
    setState(() {
      _playerChallenged = playerChallenged; // Record who challenged
      _currentRound!.isRoundOver = true;
      _currentRound!.winner = winner;
      _showDice = true; // Reveal all dice
    });
    
    // 游戏结束，更新玩家画像和饮酒状态
    if (_playerProfile != null) {
      bool playerWon = winner == 'Player';
      _playerProfile!.learnFromGame(
        _currentRound!, 
        playerWon,
        aiId: widget.aiPersonality.id,
      );
      _playerProfile!.save(); // 保存到本地
      
      // 更新饮酒状态
      if (_drinkingState != null) {
        // 在setState中更新饮酒状态，确保界面立即刷新
        setState(() {
          if (playerWon) {
            _drinkingState!.playerWin(widget.aiPersonality.id); // 玩家赢，AI喝酒
            
            // 如果AI喝醉了，显示胜利提示
            if (_drinkingState!.isAIDrunk(widget.aiPersonality.id)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showAIDrunkDialog();
              });
            }
          } else {
            _drinkingState!.aiWin(widget.aiPersonality.id); // AI赢，玩家喝酒
            
            // 如果玩家喝醉了，显示提示
            if (_drinkingState!.isDrunk) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showDrunkAnimation();
              });
            }
          }
        });
        // 直接保存，不需要在这里更新醒酒状态
        // updateSoberStatus会根据时间自动减少酒杯数，但游戏刚结束时不应该立即减少
        _drinkingState!.save();
      }
      
      // AI学习玩家风格，无需显示通知
    }
    
    // Don't show dialog anymore - result is shown on game board
  }
  
  void _showReviewDialog() {
    if (_currentRound == null) return;
    
    final currentBid = _currentRound!.currentBid!;
    final actualCount = _currentRound!.playerDice.countValue(
                          currentBid.value, 
                          onesAreCalled: _currentRound!.onesAreCalled
                        ) + 
                        _currentRound!.aiDice.countValue(
                          currentBid.value,
                          onesAreCalled: _currentRound!.onesAreCalled
                        );
    final bidSuccess = actualCount >= currentBid.quantity;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.analytics,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'AI思考复盘',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Decisions
                      Text(
                        'AI决策过程',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      ..._currentRound!.aiDecisions.asMap().entries.map((entry) {
                        int index = entry.key;
                        AIDecision decision = entry.value;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade400,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: decision.action == GameAction.challenge 
                                      ? Colors.red.shade100 
                                      : Colors.blue.shade100,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      decision.action == GameAction.challenge 
                                        ? '质疑对手叫牌' 
                                        : decision.aiBid != null
                                          ? decision.playerBid == null
                                            ? '开局叫牌：${decision.aiBid!.quantity}个${decision.aiBid!.value}'
                                            : '叫牌：${decision.aiBid!.quantity}个${decision.aiBid!.value}'
                                          : '继续叫牌',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getProbabilityColor(decision.probability),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${(decision.probability * 100).toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                decision.reasoning,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      const SizedBox(height: 12),
                      
                      // AI Personality Info
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade100,
                              Colors.amber.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.psychology,
                              color: Colors.amber.shade800,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${widget.aiPersonality.name}的风格：${widget.aiPersonality.description}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Actions - Close button
              Container(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    '关闭',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Get color based on probability
  Color _getProbabilityColor(double probability) {
    if (probability > 0.7) return Colors.green;
    if (probability > 0.4) return Colors.orange;
    return Colors.red;
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  // 根据AI情绪获取边框颜色
  Color _getEmotionBorderColor() {
    switch (_aiExpression) {
      case 'happy':
        return Colors.yellow;
      case 'confident':
        return Colors.green;
      case 'nervous':
        return Colors.orange;
      case 'angry':
        return Colors.red;
      case 'excited':
        return Colors.pink;
      case 'worried':
        return Colors.purple;
      case 'thinking':
        return Colors.blue;
      case 'smirk':
        return Colors.amber;
      default:
        return Colors.white;
    }
  }
  
  // 显示AI醉倒对话框
  void _showAIDrunkDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade700, Colors.red.shade900],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🥴',
                style: TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 10),
              Text(
                '${widget.aiPersonality.name}醉倒了！',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'AI已经喝了${_drinkingState!.getAIDrinks(widget.aiPersonality.id)}杯酒',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '要帮AI醒酒继续游戏吗？',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              
              // 帮AI看广告醒酒
              ElevatedButton.icon(
                onPressed: () {
                  AdHelper.showRewardedAdAfterDialogClose(
                    context: context,
                    onRewarded: (rewardAmount) {
                      // 获得奖励时更新状态
                      setState(() {
                        _drinkingState!.watchAdToSoberAI(widget.aiPersonality.id);
                        _drinkingState!.save();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✨ ${widget.aiPersonality.name}醒酒了，继续对战！'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('看广告帮AI醒酒'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              
              // 不帮AI，直接胜利
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showVictoryDialog();
                },
                icon: const Icon(Icons.emoji_events),
                label: const Text('直接获胜'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.greenAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 显示胜利对话框
  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade700, Colors.green.shade900],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🏆',
                style: TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 10),
              const Text(
                '完胜！',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '你成功灌醉了${widget.aiPersonality.name}！',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // 返回主页
                },
                icon: const Icon(Icons.home),
                label: const Text('返回主页'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 显示玩家醉酒动画
  void _showDrunkAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.shade900.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🥴',
                style: TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 10),
              const Text(
                '你醉倒了！',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '已经喝了${_drinkingState!.drinksConsumed}杯酒',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSoberDialog();
                },
                child: const Text('醒酒选项'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 显示醒酒对话框
  void _showSoberDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SoberDialog(
        drinkingState: _drinkingState!,
        onWatchAd: () {
          LoggerUtils.debug('点击观看广告醒酒按钮');
          // 使用公用方法显示广告
          AdHelper.showRewardedAdWithLoading(
            context: context,
            onRewarded: (rewardAmount) {
              LoggerUtils.debug('广告奖励回调触发: $rewardAmount');
              // 广告观看完成，获得奖励
              setState(() {
                _drinkingState!.watchAdToSoberPlayer();
                _drinkingState!.save();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✨ 广告观看完成，完全清醒了！'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onCompleted: () {
              LoggerUtils.debug('广告流程完成');
            },
          );
        },
        onUsePotion: () {
          setState(() {
            _drinkingState!.useSoberPotion();
            _drinkingState!.save();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('使用醒酒药水，清醒了2杯！')),
          );
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
  
  // 播放情绪序列
  void _playEmotionSequence(double probability, bool talking) async {
    if (_emotionQueue.isEmpty) return;
    
    // 播放第一个情绪
    _currentEmotionIndex = 0;
    _applyAIEmotion(_emotionQueue[0], probability, talking);
    
    // 如果有多个情绪，依次播放
    if (_emotionQueue.length > 1) {
      for (int i = 1; i < _emotionQueue.length; i++) {
        await Future.delayed(const Duration(seconds: 5)); // 每个视频播放5秒
        if (mounted && i < _emotionQueue.length) {
          _currentEmotionIndex = i;
          _applyAIEmotion(_emotionQueue[i], probability, false);
        }
      }
      
      // 播放完所有情绪后，循环播放
      while (mounted && _emotionQueue.isNotEmpty) {
        await Future.delayed(const Duration(seconds: 5)); // 等待5秒后切换到下一个
        if (mounted) {
          _currentEmotionIndex = (_currentEmotionIndex + 1) % _emotionQueue.length;
          _applyAIEmotion(_emotionQueue[_currentEmotionIndex], probability, false);
        }
      }
    }
  }

  // 应用精细的AI表情控制
  void _applyAIEmotion(String emotion, double probability, bool talking) {
    if (!mounted) return;
    
    // 即使 avatarKey 还没有准备好，我们也要更新文字显示
    
    // 表情中文映射
    Map<String, String> emotionChinese = {
      'confident': '自信',
      'nervous': '紧张',
      'excited': '兴奋',
      'angry': '愤怒',
      'thinking': '思考',
      'happy': '开心',
      'worried': '担忧',
      'smirk': '得意',
      'surprised': '惊讶',
      'disappointed': '失望',
      'suspicious': '怀疑',
      'proud': '骄傲',
      'relaxed': '轻松',
      'anxious': '焦虑',
      'cunning': '狡黠',
      'frustrated': '沮丧',
      'determined': '坚定',
      'playful': '调皮',
      'neutral': '平静',
      'contemplating': '沉思',
      // 处理 API 返回的中文表情
      '思考/沉思': '思考/沉思',
      '开心/得意': '开心/得意',
      '兴奋/自信': '兴奋/自信',
      '担心/紧张': '担心/紧张',
      '思考': '思考',
      '怀疑': '怀疑',
      '自信': '自信',
      '紧张': '紧张',
      '生气': '生气',
      '兴奋': '兴奋',
      '担心': '担心',
      '惊讶': '惊讶',
      '失望': '失望',
      '得意': '得意',
      '沉思': '沉思',
    };
    
    // 视频文件映射（与 ai_video_avatar.dart 保持一致）
    Map<String, String> emotionFileMapping = {
      'thinking': 'thinking.mp4',
      'happy': 'happy.mp4',
      'confident': 'confident.mp4',
      'nervous': 'nervous.mp4',
      'angry': 'angry.mp4',
      'excited': 'excited.mp4',
      'worried': 'worried.mp4',
      'surprised': 'suprised.mp4',  // 注意拼写
      'disappointed': 'disappointed.mp4',
      'suspicious': 'suspicious.mp4',
      // 其他表情映射到最接近的视频
      'smirk': 'confident.mp4',
      'proud': 'confident.mp4',
      'relaxed': 'happy.mp4',
      'anxious': 'nervous.mp4',
      'cunning': 'suspicious.mp4',
      'frustrated': 'angry.mp4',
      'determined': 'confident.mp4',
      'playful': 'happy.mp4',
      'neutral': 'thinking.mp4',
      'contemplating': 'thinking.mp4',
      // 处理 API 返回的中文表情
      '思考/沉思': 'thinking.mp4',
      '开心/得意': 'happy.mp4',
      '兴奋/自信': 'excited.mp4',
      '担心/紧张': 'worried.mp4',
      '思考': 'thinking.mp4',
      '怀疑': 'suspicious.mp4',
      '自信': 'confident.mp4',
      '紧张': 'nervous.mp4',
      '生气': 'angry.mp4',
      '兴奋': 'excited.mp4',
      '担心': 'worried.mp4',
      '惊讶': 'suprised.mp4',
      '失望': 'disappointed.mp4',
      '得意': 'happy.mp4',
      '沉思': 'thinking.mp4',
    };
    
    // 更新当前表情文字和视频文件名（用于调试显示）
    setState(() {
      _currentEmotion = emotionChinese[emotion] ?? emotion;
      _currentVideoFile = emotionFileMapping[emotion] ?? 'excited.mp4';
      _currentAIEmotion = emotion;  // 更新视频表情
    });
    
    // 根据情绪和概率计算精细参数
    double valence = 0.0;
    double arousal = 0.3;
    double confidence = 0.5;
    double bluff = 0.0;
    String blink = 'none';
    
    // 根据概率调整基础参数
    if (probability < 0.2) {
      // 极低概率 - 很紧张或强烈诈唬
      arousal = 0.85;
      confidence = 0.2;
      bluff = 0.8;
    } else if (probability < 0.4) {
      // 低概率 - 紧张或诈唬
      arousal = 0.7;
      confidence = 0.35;
      bluff = 0.6;
    } else if (probability > 0.8) {
      // 极高概率 - 非常自信
      arousal = 0.15;
      confidence = 0.9;
    } else if (probability > 0.6) {
      // 高概率 - 自信
      arousal = 0.25;
      confidence = 0.75;
    }
    
    // 根据具体情绪调整
    switch (emotion) {
      case 'confident':
        valence = 0.3;
        confidence = 0.9;
        arousal = 0.2;
        break;
      case 'nervous':
        valence = -0.2;
        arousal = 0.8;
        confidence = 0.3;
        blink = 'fast';
        break;
      case 'excited':
        valence = 0.8;
        arousal = 0.9;
        confidence = 0.6;
        break;
      case 'angry':
        valence = -0.7;
        arousal = 0.9;
        confidence = 0.6;
        break;
      case 'thinking':
        valence = 0.0;
        arousal = 0.4;
        confidence = 0.5;
        break;
      case 'happy':
        valence = 0.7;
        arousal = 0.4;
        confidence = 0.7;
        break;
      case 'worried':
        valence = -0.3;
        arousal = 0.6;
        confidence = 0.2;
        break;
      case 'smirk':
        valence = 0.4;
        arousal = 0.3;
        confidence = 0.8;
        bluff = 0.6;
        break;
      case 'surprised':
        valence = 0.1;
        arousal = 0.8;
        confidence = 0.4;
        blink = 'fast';
        break;
      case 'disappointed':
        valence = -0.5;
        arousal = 0.3;
        confidence = 0.3;
        break;
      case 'suspicious':
        valence = -0.1;
        arousal = 0.5;
        confidence = 0.6;
        bluff = 0.4;
        break;
      case 'proud':
        valence = 0.6;
        arousal = 0.3;
        confidence = 0.95;
        break;
      case 'relaxed':
        valence = 0.4;
        arousal = 0.1;
        confidence = 0.7;
        break;
      case 'anxious':
        valence = -0.4;
        arousal = 0.85;
        confidence = 0.25;
        blink = 'fast';
        break;
      case 'cunning':
        valence = 0.3;
        arousal = 0.4;
        confidence = 0.7;
        bluff = 0.8;
        break;
      case 'frustrated':
        valence = -0.6;
        arousal = 0.7;
        confidence = 0.4;
        break;
      case 'determined':
        valence = 0.2;
        arousal = 0.6;
        confidence = 0.85;
        break;
      case 'playful':
        valence = 0.6;
        arousal = 0.5;
        confidence = 0.6;
        bluff = 0.5;
        break;
      case 'contemplating':
        valence = 0.0;
        arousal = 0.35;
        confidence = 0.55;
        break;
    }
    
    // 应用到头像
    _avatarKey.currentState?.applyEmotion(
      valence: valence,
      arousal: arousal,
      confidence: confidence,
      bluff: bluff,
      blink: blink,
      talking: talking,
      emotion: emotion,
    );
  }
  
  // Helper method to get dice image widget
  Widget _getDiceImage(int value, {double size = 28}) {
    return Image.asset(
      'assets/dice/dice-$value.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
  
  // Helper method to get dice icon (fallback for text-only contexts)
  String _getDiceIcon(int value) {
    switch (value) {
      case 1:
        return '⚀';
      case 2:
        return '⚁';
      case 3:
        return '⚂';
      case 4:
        return '⚃';
      case 5:
        return '⚄';
      case 6:
        return '⚅';
      default:
        return '?';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    Widget mainContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.indigo.shade900,
            Colors.black,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
              children: [
                // Top Bar - empty for now, will be used for other controls if needed
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Placeholder for future controls
                      Container(),
                    ],
                  ),
                ),
                
                // AI Face and Info with Dialogue
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: Row(
                    children: [
                      // Left side: Back button and AI mode switcher
                      Column(
                        children: [
                          // 返回主页按钮
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // 直接返回主页
                            },
                            icon: const Icon(
                              Icons.home,
                              color: Colors.blueAccent,
                              size: 28,
                            ),
                            tooltip: '返回主页',
                          ),
                          const SizedBox(height: 8),
                          // AI模式切换（不显示文字标签）
                          GestureDetector(
                            onTap: () {
                              if (ApiConfig.geminiApiKey == 'YOUR_API_KEY_HERE' && !_useRealAI) {
                                _showSnackBar('请先配置Gemini API密钥');
                                GameLogger.logGameState('无法切换: API密钥未配置');
                                return;
                              }
                              String oldMode = _useRealAI ? 'Gemini AI' : '本地算法';
                              setState(() {
                                _useRealAI = !_useRealAI;
                              });
                              String newMode = _useRealAI ? 'Gemini AI' : '本地算法';
                              _showSnackBar('切换到$newMode');
                              AILogger.logModeSwitch(oldMode, newMode);
                              GameLogger.logGameState('AI配置', details: {'mode': newMode, 'personality': widget.aiPersonality.name});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _useRealAI ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _useRealAI ? Colors.green : Colors.orange,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _useRealAI ? Icons.cloud : Icons.computer,
                                    color: _useRealAI ? Colors.green : Colors.orange,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _useRealAI ? 'Gemini' : '本地',
                                    style: TextStyle(
                                      color: _useRealAI ? Colors.green : Colors.orange,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      // 表情视频
                      Container(
                        width: 120,  // 与内部AIVideoAvatar尺寸一致
                        height: 120,  // 与内部AIVideoAvatar尺寸一致
                        decoration: BoxDecoration(
                          // 移除白色背景，让视频能够显示
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getEmotionBorderColor(),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: SimpleVideoAvatar(
                          characterId: widget.aiPersonality.id,
                          emotion: _currentAIEmotion,
                          size: 120,  // 增大尺寸以便看清视频
                          showBorder: false,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // AI Dialogue Bubble
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.aiPersonality.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (_aiDialogue.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(15),
                                    bottomLeft: Radius.circular(15),
                                    bottomRight: Radius.circular(15),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _aiDialogue,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
                // Game Board
                Container(
                  height: MediaQuery.of(context).size.height * 0.28,
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.green.shade900.withOpacity(0.5),
                        Colors.green.shade800.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.shade400.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: !_gameStarted 
                    ? _buildStartScreen()
                    : Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // AI Dice (hidden or revealed)
                      _currentRound?.isRoundOver == true
                        ? _buildResultDiceRow('AI骰子', _currentRound?.aiDice, _currentRound?.currentBid)
                        : _buildDiceRow('AI骰子', _currentRound?.aiDice, !_showDice),
                      
                      // Center Area - Show result or current bid
                      _currentRound?.isRoundOver == true
                        ? _buildResultCenter()
                        : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Wild card status indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _currentRound?.onesAreCalled == true
                                      ? Colors.grey.shade800.withOpacity(0.5)
                                      : Colors.yellow.shade900.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _currentRound?.onesAreCalled == true
                                        ? Colors.grey.shade600
                                        : Colors.yellow.shade600,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _getDiceImage(1, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        _currentRound?.onesAreCalled == true
                                          ? '不是万能'
                                          : '万能牌',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _currentRound?.onesAreCalled == true
                                            ? Colors.grey.shade400
                                            : Colors.yellow.shade200,
                                        ),
                                      ),
                                      if (_currentRound?.onesAreCalled != true) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.yellow.shade300,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Current bid display
                            _currentRound?.currentBid != null 
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _currentRound!.isPlayerTurn ? 'AI: ' : '你: ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.amber.shade200,
                                      ),
                                    ),
                                    Text(
                                      '${_currentRound!.currentBid!.quantity}个${_currentRound!.currentBid!.value}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  _currentRound?.isPlayerTurn == true ? '请叫牌' : 'AI思考中...',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                          ],
                        ),
                      ),
                      
                      // Player Dice
                      _currentRound?.isRoundOver == true
                        ? _buildResultDiceRow('你的骰子', _currentRound?.playerDice, _currentRound?.currentBid)
                        : _buildDiceRow('你的骰子', _currentRound?.playerDice, false),
                    ],
                  ),
                ),
              
                // Control Panel or Result Buttons (only show when game has started)
                if (_gameStarted && _currentRound != null && !_currentRound!.isRoundOver && _currentRound!.isPlayerTurn)
                  _buildControlPanel(),
                if (_gameStarted && _currentRound?.isRoundOver == true)
                  _buildResultButtons(),
                  
                // 叫牌历史 (游戏中显示)
                if (_gameStarted && !(_currentRound?.isRoundOver ?? false))
                  _buildBidHistoryPanel(),
                  
                // 完整叫牌历史 (游戏结束后显示)
                if (_gameStarted && (_currentRound?.isRoundOver ?? false))
                  _buildCompleteBidHistoryPanel(),
                  
                // 玩家数据分析 (游戏结束后显示)
                if (_gameStarted && (_currentRound?.isRoundOver ?? false) && 
                    _playerProfile != null && _playerProfile!.totalGames > 0)
                  _buildPlayerAnalysisPanel(),
                
                // Camera preview removed for privacy
              ],
            ),
          ),
        ),
      );
    
    // Wrap with DrunkOverlay if drinking state is loaded
    if (_drinkingState != null) {
      mainContent = DrunkOverlay(
        drinkingState: _drinkingState!,
        child: mainContent,
      );
    }
    
    return Scaffold(
      body: mainContent,
    );
  }
  
  Widget _buildDiceRow(String label, DiceRoll? dice, bool hidden) {
    // Get current bid or selected value for highlighting
    final onesAreCalled = _currentRound?.onesAreCalled ?? false;
    
    // Determine what value to highlight
    int? highlightValue;
    if (!hidden && label.contains('你的骰子')) {
      if (_currentRound != null && !_currentRound!.isRoundOver) {
        if (_currentRound!.isPlayerTurn) {
          // During player's turn, highlight based on selected value for preview
          highlightValue = _selectedValue;
        } else if (_currentRound!.currentBid != null) {
          // During AI's turn, highlight based on AI's current bid
          highlightValue = _currentRound!.currentBid!.value;
        }
      } else if (_currentRound?.currentBid != null) {
        // After round is over, highlight based on final bid
        highlightValue = _currentRound!.currentBid!.value;
      }
    }
    
    // Check if this is AI or Player
    bool isAI = label.contains('AI');
    
    return Column(
      children: [
        // Label with drinks on same row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left side drinks (first 3)
            if (_drinkingState != null) ...[
              _buildCompactDrinks(isAI, true),
              const SizedBox(width: 8),
            ],
            // Label text
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
            // Right side drinks (last 3)
            if (_drinkingState != null) ...[
              const SizedBox(width: 8),
              _buildCompactDrinks(isAI, false),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: dice?.values.map((value) {
            // Determine if this die should be highlighted
            bool shouldHighlight = false;
            Color highlightColor = Colors.transparent;
            double borderWidth = 1;
            
            if (!hidden && highlightValue != null && label.contains('你的骰子')) {
              // Highlight wild 1s (if they're still wild)
              if (value == 1 && !onesAreCalled && highlightValue != 1) {
                shouldHighlight = true;
                highlightColor = Colors.amber.shade400;
                borderWidth = 2.5;
              }
              // Highlight the selected/called value
              else if (value == highlightValue) {
                shouldHighlight = true;
                highlightColor = Colors.amber.shade400;
                borderWidth = 2.5;
              }
            }
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: hidden 
                ? Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade700, Colors.grey.shade600],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 42,  // Fixed width to prevent layout shifts
                    height: 42, // Fixed height to prevent layout shifts
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: shouldHighlight ? highlightColor : Colors.transparent,
                        width: shouldHighlight ? borderWidth : 1,
                      ),
                    ),
                    child: Center(
                      child: _getDiceImage(
                        value,
                        size: 36,  // Slightly smaller to account for border
                      ),
                    ),
                  ),
            );
          }).toList() ?? [],
        ),
      ],
    );
  }
  
  // Build dice row with highlighting for results
  Widget _buildResultDiceRow(String label, DiceRoll? dice, Bid? currentBid) {
    if (dice == null || currentBid == null) return Container();
    
    // Check if this is AI or Player
    bool isAI = label.contains('AI');
    
    return Column(
      children: [
        // Label with drinks on same row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left side drinks (first 3)
            if (_drinkingState != null) ...[
              _buildCompactDrinks(isAI, true),
              const SizedBox(width: 8),
            ],
            // Label text
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
            // Right side drinks (last 3)
            if (_drinkingState != null) ...[
              const SizedBox(width: 8),
              _buildCompactDrinks(isAI, false),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: dice.values.map((value) {
            bool isWild = value == 1 && !_currentRound!.onesAreCalled && currentBid.value != 1;
            bool isCalledValue = value == currentBid.value;
            bool shouldHighlight = isWild || isCalledValue;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: 42,  // Fixed width to prevent layout shifts
                height: 42, // Fixed height to prevent layout shifts
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: shouldHighlight ? Colors.amber.shade400 : Colors.transparent,
                    width: shouldHighlight ? 2.5 : 1,
                  ),
                ),
                child: Center(
                  child: _getDiceImage(
                    value,
                    size: 36,  // Slightly smaller to account for border
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  // Build center result display
  Widget _buildResultCenter() {
    if (_currentRound == null || _currentRound!.currentBid == null) return Container();
    
    final currentBid = _currentRound!.currentBid!;
    final actualCount = _currentRound!.playerDice.countValue(
                          currentBid.value, 
                          onesAreCalled: _currentRound!.onesAreCalled
                        ) + 
                        _currentRound!.aiDice.countValue(
                          currentBid.value,
                          onesAreCalled: _currentRound!.onesAreCalled
                        );
    final bidSuccess = actualCount >= currentBid.quantity;
    final winner = _currentRound!.winner ?? '';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: winner == 'Player' 
            ? [Colors.green.shade700.withOpacity(0.8), Colors.green.shade600.withOpacity(0.6)]
            : [Colors.red.shade700.withOpacity(0.8), Colors.red.shade600.withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: winner == 'Player' ? Colors.green.shade300 : Colors.red.shade300,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Who challenged and winner announcement in one line
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _playerChallenged ? '玩家开牌' : 'AI开牌',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '→',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                winner == 'Player' ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                winner == 'Player' ? '你赢了！' : 'AI赢了！',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Bid result in one line
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '叫牌：${currentBid.quantity}个${currentBid.value}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '实际：$actualCount个${currentBid.value}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: bidSuccess ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              if (!_currentRound!.onesAreCalled && currentBid.value != 1) ...[
                const SizedBox(width: 6),
                Text(
                  '(含${_currentRound!.playerDice.values.where((v) => v == 1).length + _currentRound!.aiDice.values.where((v) => v == 1).length}个万能1)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.yellow.shade200,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  // Build start screen
  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // VS Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Player
              Column(
                children: [
                  _buildPlayerAvatar(),
                  const SizedBox(height: 4),
                  Text(
                    _getPlayerName(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 30),
              const Text(
                'VS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 30),
              // AI
              Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red, width: 2),
                      image: DecorationImage(
                        image: AssetImage(CharacterAssets.getFullAvatarPath(widget.aiPersonality.avatarPath)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.aiPersonality.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // VS Record Display
          if (_playerProfile != null && 
              _playerProfile!.vsAIRecords[widget.aiPersonality.id] != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_playerProfile!.vsAIRecords[widget.aiPersonality.id]!['wins'] ?? 0}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade400,
                    ),
                  ),
                  const Text(
                    ' 胜 ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                  Text(
                    '${_playerProfile!.vsAIRecords[widget.aiPersonality.id]!['losses'] ?? 0}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade400,
                    ),
                  ),
                  const Text(
                    ' 负',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
          ],
          // Start Button
          ElevatedButton.icon(
            onPressed: _startGame,
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text(
              '开始游戏',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 5,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build complete bid history panel (游戏结束后显示)
  Widget _buildCompleteBidHistoryPanel() {
    if (_currentRound == null || _currentRound!.bidHistory.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // 确定谁先叫牌
    bool aiStartsFirst = !_currentRound!.isPlayerTurn;
    if (_currentRound!.bidHistory.length % 2 == 0) {
      aiStartsFirst = !_currentRound!.isPlayerTurn;
    } else {
      aiStartsFirst = _currentRound!.isPlayerTurn;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade900.withOpacity(0.3),
            Colors.purple.shade900.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_edu,
                color: Colors.indigo.shade300,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '完整叫牌记录',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade200,
                ),
              ),
              const Spacer(),
              Text(
                '${_currentRound!.bidHistory.length}轮',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 显示完整叫牌历史（包括双方的行为标签）
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: _currentRound!.bidHistory.length,
              itemBuilder: (context, index) {
                final bid = _currentRound!.bidHistory[index];
                bool isPlayerBid = aiStartsFirst ? (index % 2 == 1) : (index % 2 == 0);
                
                // 获取行为分类（游戏结束后显示双方的）
                List<String> behaviorTags = [];
                if (index < _currentRound!.bidBehaviors.length) {
                  final behavior = _currentRound!.bidBehaviors[index];
                  if (behavior.isBluffing) {
                    behaviorTags.add('虚张');
                  }
                  if (behavior.isAggressive) {
                    behaviorTags.add('激进');
                  }
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPlayerBid 
                        ? [Colors.blue.shade800.withOpacity(0.3), Colors.blue.shade900.withOpacity(0.2)]
                        : [Colors.red.shade800.withOpacity(0.3), Colors.red.shade900.withOpacity(0.2)],
                      begin: isPlayerBid ? Alignment.centerRight : Alignment.centerLeft,
                      end: isPlayerBid ? Alignment.centerLeft : Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPlayerBid ? Colors.blue.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // 显示是谁叫的牌
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPlayerBid ? Colors.blue.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPlayerBid ? '玩家' : 'AI',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // 显示叫牌内容
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '${bid.quantity}个',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: bid.value == 1 
                                  ? Colors.amber.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: bid.value == 1 
                                    ? Colors.amber
                                    : Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${bid.value}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: bid.value == 1 ? Colors.amber : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            if (bid.value == 1)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '万能',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            // 显示行为标签（游戏结束后双方都显示）
                            if (behaviorTags.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              ...behaviorTags.map((tag) => Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tag == '虚张' 
                                    ? Colors.orange.withOpacity(0.3)
                                    : Colors.purple.withOpacity(0.3), // 激进
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: tag == '虚张'
                                      ? Colors.orange.withOpacity(0.5)
                                      : Colors.purple.withOpacity(0.5), // 激进
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: tag == '虚张'
                                      ? Colors.orange.shade200
                                      : Colors.purple.shade200, // 激进
                                  ),
                                ),
                              )).toList(),
                            ],
                          ],
                        ),
                      ),
                      
                      // 显示轮次
                      Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // Build bid history panel (游戏中显示)
  Widget _buildBidHistoryPanel() {
    if (_currentRound == null || _currentRound!.bidHistory.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // 确定谁先叫牌（如果现在轮到玩家，说明AI先叫；反之亦然）
    bool aiStartsFirst = !_currentRound!.isPlayerTurn;
    if (_currentRound!.bidHistory.length % 2 == 0) {
      // 偶数个叫牌，说明双方都叫了相同次数
      aiStartsFirst = !_currentRound!.isPlayerTurn;
    } else {
      // 奇数个叫牌
      aiStartsFirst = _currentRound!.isPlayerTurn;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade900.withOpacity(0.3),
            Colors.blue.shade900.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.purple.shade300,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '叫牌历史',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade200,
                ),
              ),
              const Spacer(),
              Text(
                '第${_currentRound!.bidHistory.length}轮',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 显示叫牌历史
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: _currentRound!.bidHistory.length,
              itemBuilder: (context, index) {
                final bid = _currentRound!.bidHistory[index];
                bool isPlayerBid = aiStartsFirst ? (index % 2 == 1) : (index % 2 == 0);
                
                // 使用已经计算好的行为分类
                List<String> behaviorTags = [];
                if (index < _currentRound!.bidBehaviors.length) {
                  final behavior = _currentRound!.bidBehaviors[index];
                  print('🏷️ 显示标签 index=$index, isPlayerBid=$isPlayerBid, behavior: 虚张=${behavior.isBluffing}, 激进=${behavior.isAggressive}');
                  // 游戏进行中只显示玩家的行为标签，AI的行为保密
                  if (isPlayerBid) {
                    if (behavior.isBluffing) {
                      behaviorTags.add('虚张');
                    }
                    if (behavior.isAggressive) {
                      behaviorTags.add('激进');
                    }
                  }
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPlayerBid 
                        ? [Colors.blue.shade800.withOpacity(0.3), Colors.blue.shade900.withOpacity(0.2)]
                        : [Colors.red.shade800.withOpacity(0.3), Colors.red.shade900.withOpacity(0.2)],
                      begin: isPlayerBid ? Alignment.centerRight : Alignment.centerLeft,
                      end: isPlayerBid ? Alignment.centerLeft : Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPlayerBid ? Colors.blue.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // 显示是谁叫的牌
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPlayerBid ? Colors.blue.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPlayerBid ? '玩家' : 'AI',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // 显示叫牌内容
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '${bid.quantity}个',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: bid.value == 1 
                                  ? Colors.amber.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: bid.value == 1 
                                    ? Colors.amber
                                    : Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${bid.value}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: bid.value == 1 ? Colors.amber : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            if (bid.value == 1)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '万能',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            // 显示行为标签
                            if (behaviorTags.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              ...behaviorTags.map((tag) => Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tag == '虚张' 
                                    ? Colors.orange.withOpacity(0.3)
                                    : Colors.purple.withOpacity(0.3), // 激进
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: tag == '虚张'
                                      ? Colors.orange.withOpacity(0.5)
                                      : Colors.purple.withOpacity(0.5), // 激进
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: tag == '虚张'
                                      ? Colors.orange.shade200
                                      : Colors.purple.shade200, // 激进
                                  ),
                                ),
                              )).toList(),
                            ],
                          ],
                        ),
                      ),
                      
                      // 显示轮次
                      Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // 显示当前叫牌要求提示
          if (_currentRound!.currentBid != null && _currentRound!.isPlayerTurn)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.yellow.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.yellow.shade300,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '下次叫牌需要：数量>${_currentRound!.currentBid!.quantity} 或 点数>${_currentRound!.currentBid!.value}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.yellow.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  // Build player analysis panel (游戏结束后显示)
  Widget _buildPlayerAnalysisPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade900.withOpacity(0.3),
            Colors.purple.shade900.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.blue.shade400.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Colors.blue.shade300,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '玩家数据分析',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade200,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Text(
                  '${_playerProfile!.totalGames}局',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat(
                '总胜率',
                '${(_playerProfile!.totalWins * 100.0 / _playerProfile!.totalGames).toStringAsFixed(0)}%',
                Colors.blue,
              ),
              _buildMiniStat(
                '虚张倾向',
                '${(_playerProfile!.bluffingTendency * 100).toStringAsFixed(0)}%',
                Colors.orange,
              ),
              _buildMiniStat(
                '激进程度',
                '${(_playerProfile!.aggressiveness * 100).toStringAsFixed(0)}%',
                Colors.red,
              ),
              _buildMiniStat(
                '质疑率',
                '${(_playerProfile!.totalChallenges * 100.0 / _playerProfile!.totalGames).toStringAsFixed(0)}%',
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // VS Current AI Record
          if (_playerProfile!.vsAIRecords[widget.aiPersonality.id] != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.2),
                    Colors.red.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sports_score,
                    color: Colors.orange.shade300,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '对战${widget.aiPersonality.name}：',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_playerProfile!.vsAIRecords[widget.aiPersonality.id]!['wins'] ?? 0}胜',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade400,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_playerProfile!.vsAIRecords[widget.aiPersonality.id]!['losses'] ?? 0}负',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade400,
                    ),
                  ),
                  const Spacer(),
                  // Win rate
                  if ((_playerProfile!.vsAIRecords[widget.aiPersonality.id]!['wins'] ?? 0) + 
                      (_playerProfile!.vsAIRecords[widget.aiPersonality.id]!['losses'] ?? 0) > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (_playerProfile!.vsAIRecords[widget.aiPersonality.id]!['wins']! > 
                                _playerProfile!.vsAIRecords[widget.aiPersonality.id]!['losses']!)
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '胜率${((_playerProfile!.vsAIRecords[widget.aiPersonality.id]!['wins'] ?? 0) * 100.0 / 
                          ((_playerProfile!.vsAIRecords[widget.aiPersonality.id]!['wins'] ?? 0) + 
                           (_playerProfile!.vsAIRecords[widget.aiPersonality.id]!['losses'] ?? 0))).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Play Style
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Colors.purple.shade300,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '游戏风格：${_playerProfile!.getStyleDescription()}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Build player avatar with photo or default icon
  Widget _buildPlayerAvatar() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue, width: 2),
        color: Colors.blue.withOpacity(0.2),
      ),
      child: ClipOval(
        child: user?.photoURL != null
            ? Image.network(
                user!.photoURL!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person,
                  color: Colors.blue,
                  size: 30,
                ),
              )
            : const Icon(
                Icons.person,
                color: Colors.blue,
                size: 30,
              ),
      ),
    );
  }
  
  // Get player display name
  String _getPlayerName() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      // 如果名字太长，截取前8个字符
      String name = user.displayName!;
      if (name.length > 8) {
        return '${name.substring(0, 8)}...';
      }
      return name;
    }
    return '玩家';
  }
  
  // Build compact drinks display (3 drinks on left or right side)
  Widget _buildCompactDrinks(bool isAI, bool leftSide) {
    if (_drinkingState == null) return const SizedBox.shrink();
    
    int drinks = isAI ? _drinkingState!.getAIDrinks(widget.aiPersonality.id) : _drinkingState!.drinksConsumed;
    
    return Row(
      children: List.generate(3, (index) {
        int drinkIndex = leftSide ? index : (index + 3);
        bool isFilled = drinkIndex < drinks;
        return Icon(
          Icons.local_bar,
          size: 14,
          color: isFilled 
            ? (isAI ? Colors.red.shade300 : Colors.amber.shade300)
            : Colors.grey.withOpacity(0.2),
        );
      }),
    );
  }
  
  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
  
  // Build result buttons
  Widget _buildResultButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Review button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  _showReviewDialog();
                },
                icon: const Icon(Icons.analytics),
                label: const Text(
                  '复盘',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
          // Continue button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ElevatedButton.icon(
                onPressed: _startNewRound,
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  '继续',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Bid Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Quantity selector
              _buildSelector(
                label: '数量',
                value: _selectedQuantity,
                onDecrease: () {
                  setState(() {
                    // 起叫最少2个，如果是第一次叫牌
                    int minQuantity = _currentRound?.currentBid == null ? 2 : 1;
                    _selectedQuantity = math.max(minQuantity, _selectedQuantity - 1);
                  });
                },
                onIncrease: () {
                  setState(() {
                    _selectedQuantity = math.min(10, _selectedQuantity + 1);
                  });
                },
              ),
              
              const SizedBox(width: 40),
              
              // Value selector
              _buildSelector(
                label: '点数',
                value: _selectedValue,
                onDecrease: () {
                  setState(() {
                    if (_selectedValue == 1) {
                      _selectedValue = 6; // Cycle back to 6
                    } else {
                      _selectedValue = _selectedValue - 1;
                    }
                  });
                },
                onIncrease: () {
                  setState(() {
                    if (_selectedValue == 6) {
                      _selectedValue = 1; // Cycle to 1 after 6
                    } else {
                      _selectedValue = _selectedValue + 1;
                    }
                  });
                },
                isWild: _selectedValue == 1,
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Main Bid Button (Reduced height)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _playerBid,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                shadowColor: Colors.green.shade900,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.casino, size: 24, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '报数：$_selectedQuantity个$_selectedValue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_currentRound != null && _currentRound!.onesAreCalled && _selectedValue != 1)
                        Text(
                          ' (无万能)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.yellow.shade300,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '成功率: ${(_calculateBidProbability() * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: _calculateBidProbability() > 0.5
                        ? Colors.lightGreen.shade300
                        : _calculateBidProbability() > 0.3
                          ? Colors.yellow.shade300
                          : Colors.red.shade300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Challenge Button (Reduced)
          if (_currentRound?.currentBid != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: _playerChallenge,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                  side: BorderSide(color: Colors.red.shade400, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.visibility, 
                          size: 20,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '开牌',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '质疑成功率: ${(_calculateChallengeProbability() * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: _calculateChallengeProbability() > 0.5
                          ? Colors.green.shade400
                          : _calculateChallengeProbability() > 0.3
                            ? Colors.orange.shade400
                            : Colors.red.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSelector({
    required String label,
    required int value,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
    bool isWild = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isWild ? Colors.amber : Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: Colors.white.withOpacity(0.8),
                  size: 22,
                ),
                onPressed: onDecrease,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isWild 
                    ? Colors.amber.withOpacity(0.3)
                    : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isWild ? Colors.amber : Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: Colors.white.withOpacity(0.8),
                  size: 22,
                ),
                onPressed: onIncrease,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildProbabilityIndicator(double probability) {
    IconData icon;
    Color color;
    String tooltip;
    
    if (probability > 0.7) {
      icon = Icons.sentiment_very_satisfied;
      color = Colors.green.shade400;
      tooltip = '非常安全';
    } else if (probability > 0.5) {
      icon = Icons.sentiment_satisfied;
      color = Colors.lightGreen.shade400;
      tooltip = '比较安全';
    } else if (probability > 0.3) {
      icon = Icons.sentiment_neutral;
      color = Colors.amber.shade400;
      tooltip = '有风险';
    } else if (probability > 0.15) {
      icon = Icons.sentiment_dissatisfied;
      color = Colors.orange.shade400;
      tooltip = '风险较大';
    } else {
      icon = Icons.sentiment_very_dissatisfied;
      color = Colors.red.shade400;
      tooltip = '极度危险';
    }
    
    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        color: color,
        size: 28,
      ),
    );
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}
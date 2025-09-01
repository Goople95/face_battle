import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/game_state.dart';
import '../models/ai_personality.dart';
import '../models/drinking_state.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../utils/ad_helper.dart';
import '../utils/responsive_utils.dart';
import '../config/character_config.dart';
import '../utils/logger_utils.dart';
import '../widgets/simple_ai_avatar.dart';
import '../widgets/auto_play_video_avatar.dart';  // 使用自动轮播版
import '../widgets/drunk_overlay.dart';
import '../widgets/sober_dialog.dart';
import '../widgets/victory_drunk_animation.dart';
import '../widgets/animated_intimacy_display.dart';
import '../services/share_image_service.dart';
import '../services/image_share_service.dart';
import '../services/intimacy_service.dart';
import '../services/dialogue_service.dart';
import '../services/game_progress_service.dart';
import '../services/purchase_service.dart';
import '../services/analytics_service.dart';
import '../services/npc_skin_service.dart';
import '../services/cloud_npc_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/rules_display.dart';
import '../widgets/skin_selector_dialog.dart';
import '../widgets/skin_selector_overlay.dart';

class GameScreen extends StatefulWidget {
  final AIPersonality aiPersonality;
  
  const GameScreen({
    super.key,
    required this.aiPersonality,
  });
  
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AIService _aiService;
  GameProgressData? _gameProgress;  // 替代 PlayerProfile
  DrinkingState? _drinkingState;
  
  GameRound? _currentRound;
  bool _showDice = false;
  bool _gameStarted = false;  // Track if game has started
  bool _playerChallenged = false; // Track who challenged
  DateTime? _sessionStartTime;  // 记录游戏开始时间用于Analytics
  bool _drunkVideoPreloaded = false;  // 记录drunk视频是否已预加载
  
  // UI Controllers
  int _selectedQuantity = 2;  // 起叫最少2个
  int _selectedValue = 2;
  
  // AI Dialogue
  String _aiDialogue = '';
  
  // 亲密度提示
  bool _showIntimacyTip = false;
  
  
  // 酒杯飞行动画
  late AnimationController _drinkAnimationController;
  Animation<Offset>? _drinkAnimation;
  bool _showFlyingDrink = false;
  bool _isPlayerLoser = false; // 记录是玩家还是AI输了
  
  // 酒杯变化动画
  late AnimationController _drinkChangeAnimationController;
  int _animatingDrinkIndex = -1; // 正在动画的酒杯索引
  bool _isAnimatingAIDrink = false; // 是否是AI的酒杯在动画
  
  // 获取本地化的AI名称
  String _getLocalizedAIName(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    String localeCode = languageCode;
    if (languageCode == 'zh') {
      localeCode = 'zh_TW';
    }
    return widget.aiPersonality.getLocalizedName(localeCode);
  }
  
  // Probability calculation for our bid
  double _calculateBidProbability() {
    if (_currentRound == null) return 0.0;
    
    // Count how many we have
    int ourCount = _currentRound!.playerDice.countValue(
      _selectedValue, 
      onesAreCalled: _currentRound!.onesAreCalled || _selectedValue == 1,
    );
    // int totalDice = 10; // 5 + 5 - not used
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
    GameLogger.logGameState(AppLocalizations.of(context)!.challengeProbabilityLog, details: {
      '叫牌': bid.toString(),
      '叫牌值': bid.value,
      '叫牌量': bid.quantity,
      '玩家骰子': _currentRound!.playerDice.values.toString(),
      '${_getLocalizedAIName(context)}骰子数': aiDiceCount,
      '玩家有': ourCount,
      '${_getLocalizedAIName(context)}需要': aiNeeded,
      '1是否被叫': _currentRound!.onesAreCalled,
    });
    
    // 如果AI需要的数量超过5个骰子，叫牌不可能成立
    if (aiNeeded > aiDiceCount) {
      GameLogger.logGameState(AppLocalizations.of(context)!.challengeWillDefinitelySucceed, details: {
        '原因': '${_getLocalizedAIName(context)}需要$aiNeeded个，超过5个骰子',
        '叫牌量': bid.quantity,
        '我们有': ourCount,
        '${_getLocalizedAIName(context)}需要': aiNeeded,
      });
      return 1.0; // 100% chance challenge succeeds (bid is impossible)
    }
    
    // 如果AI需要的数量小于等于0，叫牌已经成立（我们已经有足够了）
    if (aiNeeded <= 0) {
      GameLogger.logGameState(AppLocalizations.of(context)!.challengeWillDefinitelyFail, details: {
        '原因': '玩家已有$ourCount个，叫牌已成立',
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
    
    GameLogger.logGameState(AppLocalizations.of(context)!.challengeProbabilityResult, details: {
      '单骰概率': singleDieProbability.toStringAsFixed(3),
      '${_getLocalizedAIName(context)}有足够的概率': aiHasProbability.toStringAsFixed(3),
      AppLocalizations.of(context)!.challengeSuccessRateValue: (1.0 - aiHasProbability).toStringAsFixed(3),
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
  
  /// Process special markers in dialogue, convert to localized text
  String _processDialogueMarkers(String dialogue, Bid? bid) {
    final l10n = AppLocalizations.of(context)!;
    
    switch (dialogue) {
      case '__USE_BID_FORMAT__':
        if (bid != null) {
          // Use more natural colloquial English
          if (Localizations.localeOf(context).languageCode == 'en') {
            return _getEnglishBidFormat(bid.quantity, bid.value);
          }
          return l10n.aiBidFormat(bid.quantity, bid.value);
        }
        return '...';
      case '__DEFAULT_CHALLENGE__':
        return l10n.defaultChallenge;
      case '__DEFAULT_VALUE_BET__':
        return l10n.defaultValueBet;
      case '__DEFAULT_SEMI_BLUFF__':
        return l10n.defaultSemiBluff;
      case '__DEFAULT_BLUFF__':
        return l10n.defaultBluff;
      case '__DEFAULT_REVERSE_TRAP__':
        return l10n.defaultReverseTrap;
      case '__DEFAULT_PRESSURE_PLAY__':
        return l10n.defaultPressurePlay;
      case '__DEFAULT_SAFE_PLAY__':
        return l10n.defaultSafePlay;
      case '__DEFAULT_PATTERN_BREAK__':
        return l10n.defaultPatternBreak;
      case '__DEFAULT_INDUCE_AGGRESSIVE__':
        return l10n.defaultInduceAggressive;
      default:
        return dialogue;
    }
  }
  
  /// 生成更自然的英文叫注格式
  String _getEnglishBidFormat(int quantity, int value) {
    // 數字轉英文單詞
    final quantityWords = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 
      'Six', 'Seven', 'Eight', 'Nine', 'Ten'
    ];
    
    final valueWords = [
      '', 'one', 'two', 'three', 'four', 'five', 'six'
    ];
    
    // 骰子值的複數形式
    final valuePlural = [
      '', 'ones', 'twos', 'threes', 'fours', 'fives', 'sixes'
    ];
    
    // 確保數字在範圍內
    if (quantity > 0 && quantity <= 10 && value >= 1 && value <= 6) {
      // 使用複數形式
      return '${quantityWords[quantity]} ${valuePlural[value]}';
    }
    
    // 超出範圍時的備用格式
    return '$quantity ${value}\'s';
  }

  @override
  void initState() {
    super.initState();
    _loadPlayerProfile();
    // 初始表情已经设置为'happy'，组件会自动加载对应视频
    // Don't start game automatically
    
    // 初始化酒杯飞行动画控制器
    _drinkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),  // 放慢动画速度
      vsync: this,
    );
    
    // 记录屏幕查看事件
    AnalyticsService().logScreenView(screenName: 'game_screen');
    
    // 初始化酒杯变化动画控制器
    _drinkChangeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }
  
  Future<void> _loadPlayerProfile() async {
    // 加载游戏进度（替代原PlayerProfile）
    _gameProgress = await GameProgressService.instance.loadProgress();
    _drinkingState = await DrinkingState.loadStatic();
    // 初始化AI服务
    _aiService = AIService(personality: widget.aiPersonality);
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
    
    // 记录游戏开始时间
    _sessionStartTime = DateTime.now();
    
    // 记录游戏开始事件（每次新游戏开始时）
    AnalyticsService().logGameStart(
      npcId: widget.aiPersonality.id,
      npcName: widget.aiPersonality.name,
      isVip: widget.aiPersonality.isVIP,  // 这个方法内部会处理
      playerDrinks: _drinkingState?.drinksConsumed ?? 0,
      npcDrinks: _drinkingState?.getAIDrinks(widget.aiPersonality.id) ?? 0,
    );
    
    // Reset bid selector to minimum value 2×2
    setState(() {
      _selectedQuantity = 2;
      _selectedValue = 2;
    });
    
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
    // int playerRerollCount = 0; // counting rerolls for stats
    while (needReroll(playerDice)) {
      // playerRerollCount++;
      GameLogger.logGameState('玩家骰子自动重摇', details: {
        '原骰子': playerDice.values.toString(),
        '原因': '5个骰子都不相同',
      });
      playerDice = rollDice();
    }
    
    DiceRoll aiDice = rollDice();
    // int aiRerollCount = 0; // counting rerolls for stats
    while (needReroll(aiDice)) {
      // aiRerollCount++;
      GameLogger.logGameState('${_getLocalizedAIName(context)}骰子自动重摇', details: {
        '原骰子': aiDice.values.toString(),
        '原因': '5个骰子都不相同',
      });
      aiDice = rollDice();
    }
    
    // 骰子重摇完成，无需通知用户
    
    // 先确定表情
    // final newExpression = random.nextBool() ? 'thinking' : 'confident'; // for later use
    final isPlayerFirst = random.nextBool();
    
    setState(() {
      _currentRound = GameRound(
        playerDice: playerDice,
        aiDice: aiDice,
        isPlayerTurn: isPlayerFirst,
      );
      _showDice = false; // Don't show AI dice at start
      // 随机初始表情，更自然
      
      // 使用DialogueService获取问候语或轮到谁的提示
      final dialogueService = DialogueService();
      final locale = Localizations.localeOf(context);
      final localeCode = '${locale.languageCode}${locale.countryCode != null ? '_${locale.countryCode}' : ''}';
      
      if (_currentRound!.bidHistory.isEmpty && _currentRound!.aiDecisions.isEmpty) {
        // 游戏刚开始，显示问候语
        _aiDialogue = dialogueService.getGreeting(widget.aiPersonality.id, locale: localeCode);
      } else {
        _aiDialogue = isPlayerFirst 
          ? AppLocalizations.of(context)!.yourTurn
          : dialogueService.getStrategyDialogue(widget.aiPersonality.id, 'pressure_play', locale: localeCode);
      }
      
      // 表情逻辑已移除，视频随机播放
    });
    
    // If AI goes first
    if (!_currentRound!.isPlayerTurn) {
      _aiTurn();
    }
    
    // 预加载drunk视频（游戏开始后只预加载一次）
    if (!_drunkVideoPreloaded) {
      _drunkVideoPreloaded = true;
      final skinId = NPCSkinService.instance.getSelectedSkinId(widget.aiPersonality.id);
      CloudNPCService.preloadDrunkVideo(
        widget.aiPersonality.id, 
        skinId: skinId,
        delay: 3000,  // 延迟3秒，避免与初始视频冲突
      );
      LoggerUtils.info('触发drunk视频预加载: ${widget.aiPersonality.id} (皮肤$skinId)');
    }
  }
  
  void _playerBid() {
    if (_currentRound == null || !_currentRound!.isPlayerTurn) return;
    
    final newBid = Bid(quantity: _selectedQuantity, value: _selectedValue);
    
    // Validate bid
    // 检查起叫最少2个
    if (_currentRound!.currentBid == null && newBid.quantity < 2) {
      _showSnackBar(AppLocalizations.of(context)!.minimumBidTwo);
      return;
    }
    
    if (_currentRound!.currentBid != null &&
        !newBid.isHigherThan(_currentRound!.currentBid!, onesAreCalled: _currentRound!.onesAreCalled)) {
      // 特殊提示：如果之前叫了1，换其他数字必须增加数量
      if (_currentRound!.currentBid!.value == 1 && newBid.value != 1) {
        // TODO: Add localization for this message
        _showSnackBar('After bidding 1s, must increase quantity to bid other values');
      } else {
        _showSnackBar(AppLocalizations.of(context)!.bidMustBeHigher);
      }
      return;
    }
    
    setState(() {
      // Check if 1s are being called
      _currentRound!.addBid(newBid, true); // true表示是玩家叫牌
      _currentRound!.isPlayerTurn = false;
      // 玩家叫牌后，AI随机表情
      // 使用个性化的思考对话
      final dialogueService = DialogueService();
      final locale = Localizations.localeOf(context);
      final localeCode = '${locale.languageCode}${locale.countryCode != null ? '_${locale.countryCode}' : ''}';
      _aiDialogue = dialogueService.getThinkingDialogue(widget.aiPersonality.id, locale: localeCode);
    });
    
    // AI's turn
    _aiTurn();
  }
  
  Future<void> _playerChallenge() async {
    if (_currentRound == null || 
        !_currentRound!.isPlayerTurn || 
        _currentRound!.currentBid == null) {
      return;
    }
    
    await _resolveChallenge(true);
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
    
    // 使用本地AI算法
    GameLogger.logAIAction('使用本地算法', data: {'personality': _getLocalizedAIName(context)});
    decision = _aiService.decideAction(_currentRound!, null);
    if (decision.action == GameAction.bid) {
      final result = _aiService.generateBidWithAnalysis(_currentRound!);
      aiBid = result.$1;
      wasBluffing = result.$2;
    }
    // 使用本地AI生成表情
    final locale = Localizations.localeOf(context);
    final localeCode = '${locale.languageCode}${locale.countryCode != null ? '_${locale.countryCode}' : ''}';
    final (dialogue, expression) = _aiService.generateDialogue(
      _currentRound!, 
      decision.action,
      aiBid,
      locale: localeCode,
    );
    aiEmotions = [expression]; // 转换为数组
    // 处理特殊标记，使用ARB格式的文本
    aiDialogue = _processDialogueMarkers(dialogue, aiBid);
    
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
    
    if (decision.action == GameAction.challenge) {
      // 记录质疑决策
      _currentRound!.aiDecisions.add(decision);
      
      // 使用AI生成的表情
      setState(() {
        _aiDialogue = aiDialogue;
      });
      
      // Wait a bit to show the dialogue
      await Future.delayed(const Duration(seconds: 1));
      
      await _resolveChallenge(false);
    } else {
      // AI makes a bid - 叫牌已经在上面的合并调用中生成
      if (aiBid == null) {
        // 如果没有生成叫牌（不应该发生），使用降级方法
        GameLogger.logAIAction('生成降级叫牌', data: {'personality': _getLocalizedAIName(context)});
        final result = _aiService.generateBidWithAnalysis(_currentRound!);
        aiBid = result.$1;
        wasBluffing = result.$2;
        
        // 更新decision以反映实际的叫牌
        decision = AIDecision(
          playerBid: decision.playerBid,
          action: decision.action,
          aiBid: aiBid,
          probability: decision.probability,
          wasBluffing: wasBluffing,
          reasoning: decision.reasoning,
          eliteOptions: decision.eliteOptions,
        );
        
        // 使用本地AI生成表情
        final locale = Localizations.localeOf(context);
        final localeCode = '${locale.languageCode}${locale.countryCode != null ? '_${locale.countryCode}' : ''}';
        final (dialogue, expression) = _aiService.generateDialogue(
          _currentRound!, 
          GameAction.bid,
          aiBid,
          locale: localeCode,
        );
        aiEmotions = [expression]; // 转换为数组
        // 处理特殊标记，使用ARB格式的文本
        aiDialogue = _processDialogueMarkers(dialogue, aiBid);
        GameLogger.logAIAction('本地叫牌结果', data: {'bid': aiBid.toString(), 'bluffing': wasBluffing});
      }
      
      // 记录最终的AI决策（确保记录的是实际使用的bid）
      _currentRound!.aiDecisions.add(decision);
      
      // Calculate bid probability for AI's own bid
      // double bidProb = _aiService.calculateBidProbability(
      //   aiBid,
      //   _currentRound!.aiDice,
      //   10,
      //   onesAreCalled: _currentRound!.onesAreCalled || aiBid.value == 1,
      // ); // probability calculated but not used yet
      
      // Decision already contains bid info from makeCompleteDecision
      
      setState(() {
        // Check if 1s are being called
        if (aiBid != null) {
          _currentRound!.addBid(aiBid, false); // false表示是AI叫牌
          
          // 自动调整玩家选择器：基于AI的叫牌，但不要设置得太高
          // 数量：AI叫牌数量+1，但不超过4（避免误操作）
          _selectedQuantity = math.min(4, aiBid.quantity + 1);
          // 点数：保持AI叫的点数，方便玩家继续叫同样的点数
          _selectedValue = aiBid.value;
        }
        _currentRound!.isPlayerTurn = true;
        _aiDialogue = aiDialogue;
      });
      
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
  
  Future<void> _resolveChallenge(bool playerChallenged) async {
    if (_currentRound == null || _currentRound!.currentBid == null) return;
    
    LoggerUtils.info('=== 游戏回合结束 ===');
    LoggerUtils.info('  - ${AppLocalizations.of(context)!.challenger}: ${playerChallenged ? "玩家" : "AI"}');
    
    final isBidTrue = _currentRound!.isBidTrue(_currentRound!.currentBid!);
    
    String winner;
    if (playerChallenged) {
      winner = isBidTrue ? 'AI' : 'Player';
      // 质疑统计已在 GameProgressService.updateGameResult 中处理
    } else {
      winner = isBidTrue ? 'Player' : 'AI';
    }
    
    LoggerUtils.info('  - 叫牌真假: ${isBidTrue ? "真" : "假"}');
    LoggerUtils.info('  - 胜利者: $winner');
    
    setState(() {
      _playerChallenged = playerChallenged; // Record who challenged
      _currentRound!.isRoundOver = true;
      _currentRound!.winner = winner;
      _showDice = true; // Reveal all dice
    });
    
    // 游戏结束，更新游戏进度和统计
    bool playerWon = winner == 'Player';
    
    // 记录游戏结束事件
    AnalyticsService().logGameEnd(
      npcId: widget.aiPersonality.id,
      playerWon: playerWon,
      rounds: 1,  // 当前只追踪单轮
      duration: DateTime.now().difference(_sessionStartTime ?? DateTime.now()).inSeconds,
      endReason: playerChallenged ? 
        (playerWon ? 'challenge_win' : 'challenge_lose') : 
        (playerWon ? 'ai_challenge_lose' : 'ai_challenge_win'),
    );
    
    // 更新游戏进度统计（现在包含所有原PlayerProfile的功能）
    LoggerUtils.info('=== 调用 GameProgressService.updateGameResult ===');
    LoggerUtils.info('  - 玩家胜负: ${playerWon ? "胜利" : "失败"}');
    LoggerUtils.info('  - AI ID: ${widget.aiPersonality.id}');
    await GameProgressService.instance.updateGameResult(
      _currentRound!,
      playerWon,
      widget.aiPersonality.id,
    );
    LoggerUtils.info('=== updateGameResult 调用完成 ===');
      
      // 不在这里更新亲密度，只在NPC喝醉时更新
      
      // 先设置动画参数（在飞行动画之前）
      bool needRecordNPCDrunk = false;
      bool needRecordPlayerDrunk = false;
      
      if (_drinkingState != null) {
        if (playerWon) {
          // AI输了，AI的下一个空杯子将变化
          _isAnimatingAIDrink = true;
          _animatingDrinkIndex = _drinkingState!.getAIDrinks(widget.aiPersonality.id);
        } else {
          // 玩家输了，玩家的下一个空杯子将变化
          _isAnimatingAIDrink = false;
          _animatingDrinkIndex = _drinkingState!.drinksConsumed;
        }
      }
      
      // 执行酒杯飞行动画（不等待完成）
      final flyAnimationFuture = _playDrinkFlyAnimation(!playerWon);
      
      // 提前开始获取对话（异步，不等待）
      Future<String>? dialogueFuture;
      if (_drinkingState != null) {
        final dialogueService = DialogueService();
        final locale = Localizations.localeOf(context);
        final localeCode = '${locale.languageCode}${locale.countryCode != null ? '_${locale.countryCode}' : ''}';
        
        if (playerWon) {
          dialogueFuture = dialogueService.getLoseDialogue(widget.aiPersonality.id, locale: localeCode);
        } else {
          dialogueFuture = dialogueService.getWinDialogue(widget.aiPersonality.id, locale: localeCode);
        }
      }
      
      // 在飞行动画进行到80%时开始酒杯变化动画
      await Future.delayed(const Duration(milliseconds: 1200)); // 1500ms * 0.8 = 1200ms
      
      // 更新饮酒状态
      if (_drinkingState != null) {
        // 等待对话加载完成
        String dialogue = await dialogueFuture!;
        
        // 在setState中更新饮酒状态，确保界面立即刷新
        setState(() {
          if (playerWon) {
            _drinkingState!.playerWin(widget.aiPersonality.id); // 玩家赢，AI喝酒
            _aiDialogue = dialogue;
            
            // 如果AI喝醉了，显示胜利提示
            if (_drinkingState!.isAIDrunk(widget.aiPersonality.id)) {
              // 记录NPC喝醉（使用GameProgressService）
              needRecordNPCDrunk = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showAIDrunkDialog();
              });
            }
          } else {
            // 设置动画参数：玩家的下一个酒杯将变化
            _isAnimatingAIDrink = false;
            _animatingDrinkIndex = _drinkingState!.drinksConsumed;
            
            _drinkingState!.aiWin(widget.aiPersonality.id); // AI赢，玩家喝酒
            _aiDialogue = dialogue;
            
            // 如果玩家喝醉了，显示提示
            if (_drinkingState!.isDrunk) {
              // 记录玩家喝醉（使用GameProgressService）
              needRecordPlayerDrunk = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showDrunkAnimation();
              });
            }
          }
        });
        
        // 触发酒杯变化动画（状态更新后）
        if (_animatingDrinkIndex >= 0) {
          // 立即开始动画
          _drinkChangeAnimationController.forward().then((_) {
            // 动画完成后重置
            _drinkChangeAnimationController.reset();
            setState(() {
              _animatingDrinkIndex = -1;
            });
          });
          
          // 等待动画显示
          await Future.delayed(const Duration(milliseconds: 800));
        }
        
        // 确保飞行动画完成
        await flyAnimationFuture;
        
        // 在setState外处理异步操作
        if (needRecordNPCDrunk) {
          await GameProgressService.instance.recordNPCDrunk(widget.aiPersonality.id);
        }
        if (needRecordPlayerDrunk) {
          await GameProgressService.instance.recordPlayerDrunk(widget.aiPersonality.id);
        }
        
        // 5秒后清除对话
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _aiDialogue = '';
            });
          }
        });
        // 直接保存，不需要在这里更新醒酒状态
        // updateSoberStatus会根据时间自动减少酒杯数，但游戏刚结束时不应该立即减少
        _drinkingState!.save();
      }
      
      // AI学习玩家风格，无需显示通知
    }
    
    // Don't show dialog anymore - result is shown on game board
  
  void _showRulesDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black.withValues(alpha: 0.9),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏 - 简洁设计
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // 居中标题
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!.gameInstructions,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // 关闭按钮
                      Positioned(
                        right: 12,
                        top: 0,
                        bottom: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 规则内容
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: const RulesDisplay(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    // 记录Analytics事件
    AnalyticsService().logDialogShow(
      dialogName: 'game_rules',
      params: {
        'screen': 'game',
        'npc_id': widget.aiPersonality.id,
      },
    );
  }

  void _showReviewDialog() {
    if (_currentRound == null) return;
    
    // final currentBid = _currentRound!.currentBid!; // for future use in review dialog
    // final actualCount = _currentRound!.playerDice.countValue( // calculated but will be computed again during challenge
    //                       currentBid.value, 
    //                       onesAreCalled: _currentRound!.onesAreCalled
    //                     ) + 
    //                     _currentRound!.aiDice.countValue(
    //                       currentBid.value,
    //                       onesAreCalled: _currentRound!.onesAreCalled
    //                     );
    // final bidSuccess = actualCount >= currentBid.quantity; // calculated but used in logic below
    
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
                    Text(
                      '${_getLocalizedAIName(context)}思考复盘',
                      style: const TextStyle(
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
                        AppLocalizations.of(context)!.aiDecisionProcess(_getLocalizedAIName(context)),
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
                                color: Colors.black.withValues(alpha: 0.05),
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
                                        ? decision.playerBid != null
                                          ? AppLocalizations.of(context)!.challengePlayerBidAction(decision.playerBid!.quantity.toString(), decision.playerBid!.value.toString())
                                          : AppLocalizations.of(context)!.challengeOpponentAction
                                        : decision.aiBid != null
                                          ? decision.playerBid == null
                                            ? AppLocalizations.of(context)!.openingBidAction(decision.aiBid!.quantity.toString(), decision.aiBid!.value.toString())
                                            : AppLocalizations.of(context)!.respondToBidAction(decision.playerBid!.quantity.toString(), decision.playerBid!.value.toString(), decision.aiBid!.quantity.toString(), decision.aiBid!.value.toString())
                                          : AppLocalizations.of(context)!.continueBiddingAction,
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
                              // 显示Elite AI的决策选项
                              if (decision.eliteOptions != null && decision.eliteOptions!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${_getLocalizedAIName(context)}考虑的选项:',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...decision.eliteOptions!.map((option) {
                                  String optionText = '';
                                  String strategyText = option['strategy'] ?? '';
                                  double confidence = option['confidence'] ?? 0.0;
                                  
                                  if (option['type'] == 'challenge') {
                                    optionText = AppLocalizations.of(context)!.challenge;
                                  } else if (option['bid'] != null) {
                                    Bid bid = option['bid'];
                                    optionText = '${bid.quantity} × ${bid.value}';
                                  }
                                  
                                  // 转换策略名称为中文
                                  String strategyDisplay = '';
                                  switch (strategyText) {
                                    case 'value_bet':
                                      strategyDisplay = 'Value bet';
                                      break;
                                    case 'semi_bluff':
                                      strategyDisplay = 'Semi-bluff';
                                      break;
                                    case 'bluff':
                                      strategyDisplay = 'Bluff';
                                      break;
                                    case 'pure_bluff':
                                      strategyDisplay = 'Pure bluff';
                                      break;
                                    case 'reverse_trap':
                                      strategyDisplay = 'reverse_trap_alt';
                                      break;
                                    case 'pressure_play':
                                      strategyDisplay = 'Pressure play';
                                      break;
                                    default:
                                      strategyDisplay = strategyText;
                                  }
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          option['type'] == 'challenge' 
                                            ? Icons.gavel 
                                            : Icons.casino,
                                          size: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            optionText,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getProbabilityColor(confidence),
                                                    ),
                                          child: Text(
                                            '${(confidence * 100).toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          strategyDisplay,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade700,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        if (option['reasoning'] != null) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            'EV:${(option['expectedValue'] ?? 0.0).toStringAsFixed(1)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        );
                      }),
                      
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
                                '${_getLocalizedAIName(context)}的风格：${widget.aiPersonality.localizedDescription}',
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
                  child: const Text(
                    '关闭',
                    style: TextStyle(
                      fontSize: 16,
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
  /* Color _getEmotionBorderColor() { // reserved for future UI enhancements
    switch (_aiExpression) {
      case 'happy':
        return Colors.yellow;
      case 'confident':
        return Colors.green;
      case 'suspicious':
        return Colors.orange;
      case 'thinking':
        return Colors.blue;
      default:
        return Colors.white;
    }
  } */
  
  // 获取情绪标签 - reserved for future UI enhancements
  /* String _getEmotionLabel() {
    switch (_aiExpression) {
      case 'happy':
        return '😊 开心';
      case 'confident':
        return '😎 自信';
      case 'thinking':
        return '🤔 思考';
      case 'suspicious':
        return '🧐 怀疑';
      default:
        return '😐 观察';
    }
  } */
  
  // 获取NPC名字的颜色
  Color _getNPCColor() {
    // 根据不同的NPC设置不同的颜色
    switch (_getLocalizedAIName(context)) {
      case '亚希':
        return Colors.pinkAccent;
      case '芳野':
        return Colors.purpleAccent;
      case '卡捷琳娜':
        return Colors.blueAccent;
      default:
        return Colors.orangeAccent;
    }
  }
  
  // 显示AI醉倒对话框 - 使用新的胜利动画
  void _showAIDrunkDialog() {
    // 停止表情序列播放，清理资源
    
    // 延迟一下，让视频资源有时间释放
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (context, animation, secondaryAnimation) => VictoryDrunkAnimation(
            defeatedAI: widget.aiPersonality,
            drinkingState: _drinkingState!,
            onComplete: () {
              // 亲密度已在VictoryDrunkAnimation中自动处理
              // 直接返回主页，不显示中间的对话框
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            onShare: (intimacyMinutes) {
              // 直接分享图片（无需预览）
              ImageShareService.shareDirectly(
                context: context,
                defeatedAI: widget.aiPersonality,
                drinkingState: _drinkingState!,
                intimacyMinutes: intimacyMinutes,
              );
            },
          onRematch: () {
            // 检查是否已购买该NPC（VIP特权：免费醒酒）
            final purchaseService = PurchaseService();
            if (purchaseService.isNPCPurchased(widget.aiPersonality.id)) {
              // VIP用户直接醒酒，无需看广告
              setState(() {
                _drinkingState!.watchAdToSoberAI(widget.aiPersonality.id);
                _drinkingState!.save();
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('VIP特权：${_getLocalizedAIName(context)}已免费醒酒'),
                  backgroundColor: Colors.purple,
                ),
              );
              _startNewRound();
            } else {
              // 非VIP用户需要看广告
              AdHelper.showRewardedAdAfterDialogClose(
                context: context,
                onRewarded: (rewardAmount) {
                  setState(() {
                    _drinkingState!.watchAdToSoberAI(widget.aiPersonality.id);
                    _drinkingState!.save();
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.aiSoberedUp(_getLocalizedAIName(context))),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _startNewRound();
                },
                onFailed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.adLoadFailed)),
                  );
                },
              );
            }
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
    });
  }
  
  // 显示胜利对话框
  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4A148C),
                Color(0xFF880E4F),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFE91E63).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 暧昧的图标
              const Text(
                '💕',
                style: TextStyle(fontSize: 50),
              ),
              const SizedBox(height: 15),
              // 主标题
              const Text(
                '夜已深',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 15),
              // 暧昧的描述
              Text(
                AppLocalizations.of(context)!.drunkDescription(_getLocalizedAIName(context)),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '你们之间的关系变得更亲密了',
                style: TextStyle(
                  color: Color(0xFFE91E63).withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 25),
              // 按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 继续探索按钮
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // 返回主页
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    child: Text(
                      '回到现实',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
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
            color: Colors.red.shade900.withValues(alpha: 0.9),
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
                AppLocalizations.of(context)!.youGotDrunk,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.drinksConsumedMessage(_drinkingState!.drinksConsumed),
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
                child: Text(AppLocalizations.of(context)!.soberOptions),
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
        fromGameScreen: true, // 标识从游戏页面调用
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
              // 记录看广告醒酒次数（玩家自己）
              GameProgressService.instance.recordAdSober();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.adWatchedSober),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.usedSoberPotion)),
          );
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
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
  
  // Helper method to get dice icon (fallback for text-only contexts) - reserved for future use
  /* String _getDiceIcon(int value) {
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
  } */
  
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
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Placeholder for future controls
                      Container(),
                    ],
                  ),
                ),
                
                // AI Face and Info with Dialogue - 大面积视频展示
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  // NPC大面积视频展示
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 计算1:1视频的高度（与宽度相同）
                      final videoSize = constraints.maxWidth; // 不需要再减去padding，constraints已经是padding后的宽度
                      
                      return Container(
                        height: videoSize,  // 使用1:1的高度
                        width: double.infinity,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 视频背景 - 1:1显示（自动轮播）
                              Positioned.fill(
                                child: AutoPlayVideoAvatar(
                                  characterId: widget.aiPersonality.id,
                                  size: videoSize,  // 使用正方形尺寸
                                  showBorder: false,
                                  personality: widget.aiPersonality,  // 传递personality以获取videoCount
                                ),
                              ),
                          // 左上角 - 返回主页按钮（粉色主题）
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.pink.shade400.withValues(alpha: 0.85),
                                    Colors.pink.shade400.withValues(alpha: 0.65),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(
                                  Icons.home,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          // 右上角 - 亲密度显示（小巧精致）
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AnimatedIntimacyDisplay(
                                  npcId: widget.aiPersonality.id,
                                  showDetails: false,
                                  onTap: () {
                                    setState(() {
                                      _showIntimacyTip = !_showIntimacyTip;
                                      if (_showIntimacyTip) {
                                        // 显示NPC对话
                                        _aiDialogue = AppLocalizations.of(context)!.intimacyTip;
                                        // 3秒后自动隐藏
                                        Future.delayed(const Duration(seconds: 3), () {
                                          if (mounted) {
                                            setState(() {
                                              _showIntimacyTip = false;
                                              _aiDialogue = '';
                                            });
                                          }
                                        });
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                // 皮膚切換按鈕
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _showSkinSelector,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.amber.withValues(alpha: 0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        '👙',
                                        style: TextStyle(
                                          fontSize: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 亲密度进度提示
                          if (_showIntimacyTip)
                            Positioned(
                              top: 60,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  border: Border.all(
                                    color: Colors.pink.shade400,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.favorite,
                                          color: Colors.pink.shade400,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          AppLocalizations.of(context)!.intimacyProgressTitle,
                                          style: TextStyle(
                                            color: Colors.pink.shade400,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    FutureBuilder<String>(
                                      future: _getIntimacyProgress(),
                                      builder: (context, snapshot) {
                                        return Text(
                                          snapshot.data ?? '加载中...',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      AppLocalizations.of(context)!.intimacyTooltip,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // 底部对话文字 - 透明背景
                          if (_aiDialogue.isNotEmpty)
                            Positioned(
                              bottom: 20,
                              left: 20,
                              right: 20,
                              child: Text(
                                _aiDialogue,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(1, 1),
                                      blurRadius: 4,
                                      color: Colors.black.withValues(alpha: 0.8),
                                    ),
                                    Shadow(
                                      offset: const Offset(-1, -1),
                                      blurRadius: 4,
                                      color: Colors.black.withValues(alpha: 0.8),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                    },
                  ),
                ),
              
                // Game Board
                Container(
                  height: MediaQuery.of(context).size.height * 0.28,
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.green.shade900.withValues(alpha: 0.5),
                        Colors.green.shade800.withValues(alpha: 0.3),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.green.shade400.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // 游戏规则按钮 - 右上角
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _showRulesDialog,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.help_outline,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // 主要内容
                      Positioned.fill(
                        child: !_gameStarted 
                          ? _buildStartScreen()
                          : Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // AI Dice (hidden or revealed)
                      _currentRound?.isRoundOver == true
                        ? _buildResultDiceRow(AppLocalizations.of(context)!.aiDiceLabel(_getLocalizedAIName(context)), _currentRound?.aiDice, _currentRound?.currentBid)
                        : _buildDiceRow(AppLocalizations.of(context)!.aiDiceLabel(_getLocalizedAIName(context)), _currentRound?.aiDice, !_showDice),
                      
                      // Center Area - Show result or current bid
                      _currentRound?.isRoundOver == true
                        ? _buildResultCenter()
                        : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.5),
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
                                      ? Colors.grey.shade800.withValues(alpha: 0.5)
                                      : Colors.yellow.shade900.withValues(alpha: 0.5),
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
                                          ? AppLocalizations.of(context)!.notWildcard
                                          : AppLocalizations.of(context)!.wildcard,
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
                                    _currentRound!.isPlayerTurn 
                                      ? RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: _getLocalizedAIName(context),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: _getNPCColor(),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: ': ',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.amber.shade200,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Text(
                                          '${AppLocalizations.of(context)!.yourTurn.replaceAll(' Turn', '')}: ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.amber.shade200,
                                          ),
                                        ),
                                    Row(
                                      children: [
                                        Text(
                                          '${_currentRound!.currentBid!.quantity} × ',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        _getDiceImage(_currentRound!.currentBid!.value, size: 24),
                                      ],
                                    ),
                                  ],
                                )
                              : Text(
                                  _currentRound?.isPlayerTurn == true 
                                    ? AppLocalizations.of(context)!.pleaseBid 
                                    : AppLocalizations.of(context)!.pleaseWaitThinking(_getLocalizedAIName(context)),
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
                        ? _buildResultDiceRow(AppLocalizations.of(context)!.playerDiceLabel, _currentRound?.playerDice, _currentRound?.currentBid)
                        : _buildDiceRow(AppLocalizations.of(context)!.playerDiceLabel, _currentRound?.playerDice, false),
                    ],
                  ),
                      ),
                      
                      // 飞行的酒杯 - 在牌桌内部
                      if (_showFlyingDrink && _drinkAnimation != null)
                        AnimatedBuilder(
                          animation: _drinkAnimation!,
                          builder: (context, child) {
                            final boxHeight = MediaQuery.of(context).size.height * 0.28;
                            final boxWidth = MediaQuery.of(context).size.width - 30;
                            return Positioned(
                              left: _drinkAnimation!.value.dx * boxWidth - 25,  // 调整位置使酒杯居中
                              top: _drinkAnimation!.value.dy * boxHeight - 25,
                              child: Transform.scale(
                                scale: 1.0 - (_drinkAnimationController.value * 0.3), // 从正常大小变小
                                child: Container(
                                  width: 50,  // 调小酒杯尺寸
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: _isPlayerLoser
                                        ? [
                                            Colors.amber.shade400,
                                            Colors.orange.shade700,
                                          ]
                                        : [
                                            Colors.red.shade300,
                                            Colors.red.shade700,
                                          ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isPlayerLoser ? Colors.amber : Colors.red).withValues(alpha: 0.5),
                                        blurRadius: 15,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.local_bar,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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
                  
                // 你的数据分析 (游戏结束后显示)
                if (_gameStarted && (_currentRound?.isRoundOver ?? false) && 
                    _gameProgress != null && _gameProgress!.totalGames > 0)
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
    if (!hidden && label == AppLocalizations.of(context)!.playerDiceLabel) {
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
    bool isAI = label.contains(_getLocalizedAIName(context));
    
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
            // Label text - using full localized label
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isAI ? _getNPCColor() : Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.bold,
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
            
            if (!hidden && highlightValue != null && label == AppLocalizations.of(context)!.playerDiceLabel) {
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
                        color: Colors.white.withValues(alpha: 0.3),
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
    bool isAI = label.contains(_getLocalizedAIName(context));
    
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
            // Label text - using full localized label
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isAI ? _getNPCColor() : Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.bold,
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
            ? [Colors.green.shade700.withValues(alpha: 0.8), Colors.green.shade600.withValues(alpha: 0.6)]
            : [Colors.red.shade700.withValues(alpha: 0.8), Colors.red.shade600.withValues(alpha: 0.6)],
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
                _playerChallenged 
                  ? AppLocalizations.of(context)!.playerShowDice 
                  : AppLocalizations.of(context)!.aiShowDice(_getLocalizedAIName(context)),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                winner == 'Player' ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 4),
              winner == 'Player' 
                ? Text(
                    AppLocalizations.of(context)!.youWin,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)!.aiWins(_getLocalizedAIName(context)),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 6),
          // Bid result in one line with dice icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 叫牌部分
              Text(
                '${AppLocalizations.of(context)!.bidShort}: ',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
              Text(
                '${currentBid.quantity}×',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Image.asset(
                'assets/dice/dice-${currentBid.value}.png',
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 12),
              // 实际结果
              Text(
                '${AppLocalizations.of(context)!.actualShort}: ',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
              Text(
                '$actualCount×',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: bidSuccess ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              Image.asset(
                'assets/dice/dice-${currentBid.value}.png',
                width: 18,
                height: 18,
              ),
              if (!_currentRound!.onesAreCalled && currentBid.value != 1) ...[
                const SizedBox(width: 6),
                Text(
                  '(${AppLocalizations.of(context)!.inclShort} ',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.yellow.shade200,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  '${_currentRound!.playerDice.values.where((v) => v == 1).length + _currentRound!.aiDice.values.where((v) => v == 1).length}×',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.yellow.shade200,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Image.asset(
                  'assets/dice/dice-1.png',
                  width: 14,
                  height: 14,
                ),
                Text(
                  ')',
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
  
  // Build start screen - 简化版，只有开始按钮
  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Start Button
          ElevatedButton.icon(
            onPressed: _startGame,
            icon: const Icon(Icons.casino, size: 28),
            label: Text(
              AppLocalizations.of(context)!.startGame,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            Colors.indigo.shade900.withValues(alpha: 0.3),
            Colors.purple.shade900.withValues(alpha: 0.3),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
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
                AppLocalizations.of(context)!.completeBidHistory,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade200,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.roundsCount(_currentRound!.bidHistory.length),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
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
                    behaviorTags.add(AppLocalizations.of(context)!.bluffLabel);
                  }
                  if (behavior.isAggressive) {
                    behaviorTags.add(AppLocalizations.of(context)!.aggressiveLabel);
                  }
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPlayerBid 
                        ? [Colors.blue.shade800.withValues(alpha: 0.3), Colors.blue.shade900.withValues(alpha: 0.2)]
                        : [Colors.red.shade800.withValues(alpha: 0.3), Colors.red.shade900.withValues(alpha: 0.2)],
                      begin: isPlayerBid ? Alignment.centerRight : Alignment.centerLeft,
                      end: isPlayerBid ? Alignment.centerLeft : Alignment.centerRight,
                    ),
                    border: Border.all(
                      color: isPlayerBid ? Colors.blue.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // 显示是谁叫的牌
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPlayerBid ? Colors.blue.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5),
                        ),
                        child: Text(
                          isPlayerBid ? 'You' : _getLocalizedAIName(context),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPlayerBid ? Colors.white : _getNPCColor(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // 显示叫牌内容
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '${bid.quantity} × ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            _getDiceImage(bid.value, size: 20),
                            if (bid.value == 1)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.wildcard,
                                  style: const TextStyle(
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
                                    ? Colors.orange.withValues(alpha: 0.3)
                                    : Colors.purple.withValues(alpha: 0.3), // 激进
                                  border: Border.all(
                                    color: tag == '虚张'
                                      ? Colors.orange.withValues(alpha: 0.5)
                                      : Colors.purple.withValues(alpha: 0.5), // 激进
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
                              )),
                            ],
                          ],
                        ),
                      ),
                      
                      // 显示轮次
                      Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.5),
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
            Colors.purple.shade900.withValues(alpha: 0.3),
            Colors.blue.shade900.withValues(alpha: 0.3),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
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
                AppLocalizations.of(context)!.bidHistory,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade200,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.roundNumber(_currentRound!.bidHistory.length),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
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
                  // 游戏进行中只显示玩家的行为标签，AI的行为保密
                  if (isPlayerBid) {
                    if (behavior.isBluffing) {
                      behaviorTags.add(AppLocalizations.of(context)!.bluffLabel);
                    }
                    if (behavior.isAggressive) {
                      behaviorTags.add(AppLocalizations.of(context)!.aggressiveLabel);
                    }
                  }
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPlayerBid 
                        ? [Colors.blue.shade800.withValues(alpha: 0.3), Colors.blue.shade900.withValues(alpha: 0.2)]
                        : [Colors.red.shade800.withValues(alpha: 0.3), Colors.red.shade900.withValues(alpha: 0.2)],
                      begin: isPlayerBid ? Alignment.centerRight : Alignment.centerLeft,
                      end: isPlayerBid ? Alignment.centerLeft : Alignment.centerRight,
                    ),
                    border: Border.all(
                      color: isPlayerBid ? Colors.blue.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // 显示是谁叫的牌
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPlayerBid ? Colors.blue.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5),
                        ),
                        child: Text(
                          isPlayerBid ? 'You' : _getLocalizedAIName(context),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPlayerBid ? Colors.white : _getNPCColor(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // 显示叫牌内容
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '${bid.quantity} × ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            _getDiceImage(bid.value, size: 20),
                            if (bid.value == 1)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.wildcard,
                                  style: const TextStyle(
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
                                    ? Colors.orange.withValues(alpha: 0.3)
                                    : Colors.purple.withValues(alpha: 0.3), // 激进
                                  border: Border.all(
                                    color: tag == '虚张'
                                      ? Colors.orange.withValues(alpha: 0.5)
                                      : Colors.purple.withValues(alpha: 0.5), // 激进
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
                              )),
                            ],
                          ],
                        ),
                      ),
                      
                      // 显示轮次
                      Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.4),
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
                color: Colors.yellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.yellow.withValues(alpha: 0.3),
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
                      AppLocalizations.of(context)!.nextBidHint(_currentRound!.currentBid!.quantity, _currentRound!.currentBid!.value),
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
            Colors.blue.shade900.withValues(alpha: 0.3),
            Colors.purple.shade900.withValues(alpha: 0.3),
          ],
        ),
        border: Border.all(
          color: Colors.blue.shade400.withValues(alpha: 0.3),
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
                AppLocalizations.of(context)!.playerDataAnalysis,
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
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Text(
                  AppLocalizations.of(context)!.totalGames(_gameProgress!.totalGames),
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
                AppLocalizations.of(context)!.winRate,
                '${(_gameProgress!.totalWins * 100.0 / _gameProgress!.totalGames).toStringAsFixed(0)}%',
                Colors.blue,
              ),
              _buildMiniStat(
                AppLocalizations.of(context)!.bluffingTendency,
                '${(_gameProgress!.bluffingTendency * 100).toStringAsFixed(0)}%',
                Colors.orange,
              ),
              _buildMiniStat(
                AppLocalizations.of(context)!.aggressiveness,
                '${(_gameProgress!.aggressiveness * 100).toStringAsFixed(0)}%',
                Colors.red,
              ),
              _buildMiniStat(
                AppLocalizations.of(context)!.challengeRate,
                '${(_gameProgress!.totalChallenges * 100.0 / _gameProgress!.totalGames).toStringAsFixed(0)}%',
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // VS Current AI Record
          if (_gameProgress!.vsNPCRecords[widget.aiPersonality.id] != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withValues(alpha: 0.2),
                    Colors.red.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.5),
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
                    'vs ${_getLocalizedAIName(context)}: ',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_gameProgress!.vsNPCRecords[widget.aiPersonality.id]!['wins'] ?? 0}${AppLocalizations.of(context)!.win}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade400,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_gameProgress!.vsNPCRecords[widget.aiPersonality.id]!['losses'] ?? 0}${AppLocalizations.of(context)!.lose}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade400,
                    ),
                  ),
                  const Spacer(),
                  // Win rate
                  if ((_gameProgress!.vsNPCRecords[widget.aiPersonality.id]!['wins'] ?? 0) + 
                      (_gameProgress!.vsNPCRecords[widget.aiPersonality.id]!['losses'] ?? 0) > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (_gameProgress!.vsNPCRecords[widget.aiPersonality.id]!['wins']! > 
                                _gameProgress!.vsNPCRecords[widget.aiPersonality.id]!['losses']!)
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${AppLocalizations.of(context)!.winRate}: ${((_gameProgress!.vsNPCRecords[widget.aiPersonality.id]!['wins'] ?? 0) * 100.0 / 
                          ((_gameProgress!.vsNPCRecords[widget.aiPersonality.id]!['wins'] ?? 0) + 
                           (_gameProgress!.vsNPCRecords[widget.aiPersonality.id]!['losses'] ?? 0))).toStringAsFixed(0)}%',
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
              color: Colors.black.withValues(alpha: 0.3),
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
                    '${AppLocalizations.of(context)!.gameStyle}: ${_gameProgress!.getStyleDescription(context)}',
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
        color: Colors.blue.withValues(alpha: 0.2),
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
  
  // Build compact drinks display (half drinks on left or right side)
  Widget _buildCompactDrinks(bool isAI, bool leftSide) {
    if (_drinkingState == null) return const SizedBox.shrink();
    
    int drinks = isAI ? _drinkingState!.getAIDrinks(widget.aiPersonality.id) : _drinkingState!.drinksConsumed;
    int capacity = isAI ? widget.aiPersonality.drinkCapacity : 6; // 玩家固定6杯
    
    // 计算每边显示的杯子数量（尽量对称）
    int leftCount = (capacity + 1) ~/ 2;  // 左边数量（向上取整）
    int rightCount = capacity - leftCount; // 右边数量
    int displayCount = leftSide ? leftCount : rightCount;
    int startIndex = leftSide ? 0 : leftCount;
    
    return Row(
      children: List.generate(displayCount, (index) {
        int drinkIndex = startIndex + index;
        bool isFilled = drinkIndex < drinks;
        bool isAnimating = (_isAnimatingAIDrink == isAI) && (drinkIndex == _animatingDrinkIndex);
        
        Widget drinkIcon = Icon(
          Icons.local_bar,
          size: 14,
          color: isFilled 
            ? (isAI ? Colors.red.shade300 : Colors.amber.shade300)
            : Colors.grey.withValues(alpha: 0.8),
        );
        
        // 如果这个酒杯正在动画中，添加放大缩小效果
        if (isAnimating) {
          return AnimatedBuilder(
            animation: _drinkChangeAnimationController,
            builder: (context, child) {
              // 使用曲线动画：先放大到2.4倍，然后恢复到1.0
              double scale = 1.0;
              if (_drinkChangeAnimationController.value < 0.5) {
                // 前半段：放大
                scale = 1.0 + (_drinkChangeAnimationController.value * 2 * 1.4);
              } else {
                // 后半段：缩小
                scale = 2.4 - ((_drinkChangeAnimationController.value - 0.5) * 2 * 1.4);
              }
              
              return Transform.scale(
                scale: scale,
                child: drinkIcon,
              );
            },
          );
        }
        
        return drinkIcon;
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
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _startNewRound,
          icon: const Icon(Icons.play_arrow),
          label: Text(
            AppLocalizations.of(context)!.continueGame,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 5,
          ),
        ),
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
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
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
                label: AppLocalizations.of(context)!.quantity,
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
                label: AppLocalizations.of(context)!.diceValue,
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
                      Text(
                        '$_selectedQuantity × ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      _getDiceImage(_selectedValue, size: 20),
                      if (_currentRound != null && _currentRound!.onesAreCalled && _selectedValue != 1)
                        Text(
                          ' ${AppLocalizations.of(context)!.noWildcard}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.yellow.shade300,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.challengeSuccessRateDisplay((_calculateBidProbability() * 100).toStringAsFixed(0)),
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
                          AppLocalizations.of(context)!.showDice,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      AppLocalizations.of(context)!.challengeSuccessRateDisplay((_calculateChallengeProbability() * 100).toStringAsFixed(1)),
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
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isWild ? Colors.amber : Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: Colors.white.withValues(alpha: 0.8),
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
                    ? Colors.amber.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
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
                  color: Colors.white.withValues(alpha: 0.8),
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
  
  /* Widget _buildProbabilityIndicator(double probability) { // reserved for future UI enhancements
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
  } */
  
  Future<String> _getIntimacyProgress() async {
    final intimacyService = IntimacyService();
    final intimacy = intimacyService.getIntimacy(widget.aiPersonality.id);
    
    // 获取当前等级的阈值
    final currentLevelThreshold = intimacy.intimacyLevel == 1 
        ? 0 
        : [0, 100, 300, 600, 1000, 1500, 2100, 2800, 3600, 4500][intimacy.intimacyLevel - 1];
    final nextLevelThreshold = [100, 300, 600, 1000, 1500, 2100, 2800, 3600, 4500, 999999][intimacy.intimacyLevel - 1];
    
    // 计算当前等级内的进度
    final currentLevelPoints = intimacy.intimacyPoints - currentLevelThreshold;
    final pointsNeeded = nextLevelThreshold - currentLevelThreshold;
    
    if (intimacy.intimacyLevel >= 10) {
      return AppLocalizations.of(context)!.intimacyMaxLevel(intimacy.intimacyPoints);
    }
    
    return AppLocalizations.of(context)!.intimacyProgressFormat(currentLevelPoints, pointsNeeded);
  }
  
  // 顯示皮膚選擇器
  Future<void> _showSkinSelector() async {
    // 获取比基尼按钮的位置
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final screenSize = MediaQuery.of(context).size;
    // 按钮大约在右上角位置
    final anchorPosition = Offset(screenSize.width - 60, 100);
    
    // 使用Overlay显示轻奢风格选择器
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => SkinSelectorOverlay(
        npcId: widget.aiPersonality.id,
        npcName: _getLocalizedAIName(context),
        anchorPosition: anchorPosition,
        onClose: () {
          overlayEntry?.remove();
          // 刷新界面
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
    
    Overlay.of(context).insert(overlayEntry);
  }

  // 播放酒杯飞行动画
  Future<void> _playDrinkFlyAnimation(bool isPlayerLoser) async {
    setState(() {
      _isPlayerLoser = isPlayerLoser;
      _showFlyingDrink = true;
    });
    
    // 简化处理：所有酒杯都飞到正中间
    // 只区分垂直高度：玩家0.65, NPC 0.08
    Offset targetPosition = isPlayerLoser 
      ? const Offset(0.5, 0.65)  // 玩家位置：中间，高度0.65
      : const Offset(0.5, 0.08);  // NPC位置：中间，高度0.08
    
    // 创建动画曲线 - 牌桌内部的相对位置
    _drinkAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0.5), // 牌桌中央
      end: targetPosition,
    ).animate(CurvedAnimation(
      parent: _drinkAnimationController,
      curve: Curves.easeOutQuart,  // 更平滑的动画曲线
    ));
    
    // 播放动画
    await _drinkAnimationController.forward();
    
    // 动画结束后隐藏飞行酒杯
    setState(() {
      _showFlyingDrink = false;
    });
    
    // 重置动画控制器
    _drinkAnimationController.reset();
  }
  
  @override
  void dispose() {
    _drinkAnimationController.dispose();
    _drinkChangeAnimationController.dispose();
    super.dispose();
  }
}
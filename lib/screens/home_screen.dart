import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'game_screen.dart';
import '../models/ai_personality.dart';
import '../services/game_progress_service.dart';
import '../models/game_progress.dart';
import '../models/drinking_state.dart';
import '../widgets/sober_dialog.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/language_service.dart';
import '../utils/ad_helper.dart';
import '../utils/responsive_utils.dart';
import '../services/vip_unlock_service.dart';
import '../config/character_assets.dart';
import '../services/intimacy_service.dart';
import '../models/intimacy_data.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/local_storage_debug_tool.dart';
import '../services/npc_config_service.dart';
import '../services/storage/local_storage_service.dart';
import '../utils/logger_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  GameProgressData? _gameProgress;
  DrinkingState? _drinkingState;
  Timer? _soberTimer;
  
  // 获取当前应用的locale代码
  String _getLocaleCode(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;
    
    // 处理中文的特殊情况
    if (languageCode == 'zh') {
      if (countryCode == 'TW' || countryCode == 'HK' || countryCode == 'MO') {
        return 'zh_TW';
      }
      return 'zh';
    }
    
    return languageCode;
  }
  
  // 获取本地化的NPC名称
  String _getLocalizedName(BuildContext context, AIPersonality personality) {
    return personality.getLocalizedName(_getLocaleCode(context));
  }
  
  // 获取本地化的NPC描述
  String _getLocalizedDescription(BuildContext context, AIPersonality personality) {
    return personality.getLocalizedDescription(_getLocaleCode(context));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _startTimer();
    // 同步语言设置
    _syncLanguageSettings();
    // 监听authService变化，更新userService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncUserService();
    });
  }
  
  Future<void> _syncUserService() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    
    // 如果用户信息不一致，更新UserService
    if (authService.user != null && 
        (userService.currentUser?.uid != authService.user?.uid ||
         userService.currentUser?.displayName != authService.user?.displayName ||
         userService.currentUser?.photoURL != authService.user?.photoURL)) {
      LoggerUtils.info('同步UserService用户信息:');
      LoggerUtils.info('  名称: ${authService.user?.displayName}');
      LoggerUtils.info('  头像: ${authService.user?.photoURL}');
      await userService.initialize(authService.user);
    }
  }
  
  Future<void> _syncLanguageSettings() async {
    try {
      final languageService = Provider.of<LanguageService>(context, listen: false);
      await languageService.syncLanguageFromCloud();
    } catch (e) {
      // 忽略错误，不影响应用运行
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _soberTimer?.cancel();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用恢复时重新加载数据和启动定时器
      _loadData();
      _startTimer();
    } else if (state == AppLifecycleState.paused) {
      // 应用暂停时停止定时器
      _soberTimer?.cancel();
    }
  }
  
  void _startTimer() {
    // 先取消之前的定时器
    _soberTimer?.cancel();
    
    // 设置定时器，每秒更新一次倒计时显示
    _soberTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateSoberStatus();
    });
  }
  
  Future<void> _loadData() async {
    // 先初始化用户ID相关的服务
    if (mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.uid != null) {
        // 设置用户ID到各个服务
        LocalStorageService.instance.setUserId(authService.uid!);
        IntimacyService().setUserId(authService.uid!);
        GameProgressService.instance.setUserId(authService.uid!);
      }
    }
    
    // 然后加载数据
    final progress = await GameProgressService.instance.loadProgress();
    final drinking = await DrinkingState.loadStatic();
    
    // 更新醒酒状态（DrinkingState.load() 内部已经调用了 updateSoberStatus）
    // drinking.updateSoberStatus();  // 不需要重复调用
    // await drinking.save();  // 如果没有实际变化，不需要保存
    
    setState(() {
      _gameProgress = progress;
      _drinkingState = drinking;
    });
  }
  
  void _updateSoberStatus() async {
    if (_drinkingState != null) {
      // 每10秒重新加载一次数据，确保获取最新状态
      if (DateTime.now().second % 10 == 0) {
        final latestState = await DrinkingState.loadStatic();
        _drinkingState = latestState;
        _drinkingState!.updateSoberStatus();
        await _drinkingState!.save();
      }
      
      // 每秒都刷新界面以更新倒计时显示
      if (mounted) {
        setState(() {
          // 触发界面重绘，倒计时会自动更新
        });
      }
    }
  }
  
  // 格式化醒酒倒计时（显示总的醒酒时间）
  String _getFormattedSoberTime(String aiId) {
    // 获取AI当前的酒杯数
    final aiDrinks = _drinkingState!.getAIDrinks(aiId);
    if (aiDrinks == 0) return '';
    
    // 获取下一杯的倒计时秒数
    final nextSoberSeconds = _drinkingState!.getAINextSoberSeconds(aiId);
    
    // 如果没有倒计时信息（比如刚加载游戏），显示估算的总时间
    if (nextSoberSeconds == 0) {
      // 显示预估的总醒酒时间
      final totalMinutes = aiDrinks * 10;
      return AppLocalizations.of(context)!.aboutMinutes(totalMinutes.toString());
    }
    
    // 计算实际剩余的总时间（秒）
    // = (剩余杯数-1) * 600秒 + 当前杯的剩余秒数
    final totalSeconds = (aiDrinks - 1) * 600 + nextSoberSeconds;
    
    // 转换为分钟和秒
    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  // 格式化玩家醒酒倒计时（显示总的醒酒时间）
  String _getFormattedPlayerSoberTime() {
    // 获取玩家当前的酒杯数
    final playerDrinks = _drinkingState!.drinksConsumed;
    if (playerDrinks == 0) return '';
    
    // 获取下一杯的倒计时秒数
    final nextSoberSeconds = _drinkingState!.getPlayerNextSoberSeconds();
    
    // 如果没有倒计时信息（比如刚加载游戏），显示估算的总时间
    if (nextSoberSeconds == 0) {
      // 显示预估的总醒酒时间
      final totalMinutes = playerDrinks * 10;
      return AppLocalizations.of(context)!.aboutMinutes(totalMinutes.toString());
    }
    
    // 计算实际剩余的总时间（秒）
    // = (剩余杯数-1) * 600秒 + 当前杯的剩余秒数
    final totalSeconds = (playerDrinks - 1) * 600 + nextSoberSeconds;
    
    // 转换为分钟和秒
    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userService = Provider.of<UserService>(context);
    
    // 检查用户信息是否需要同步
    if (authService.user != null && 
        (userService.currentUser?.uid != authService.user?.uid ||
         userService.currentUser?.displayName != authService.user?.displayName ||
         userService.currentUser?.photoURL != authService.user?.photoURL)) {
      // 使用addPostFrameCallback避免在build过程中调用setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncUserService();
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1A0000),  // 深黑红色
        leading: kDebugMode 
            ? IconButton(
                icon: const Icon(Icons.bug_report, color: Colors.orange),
                tooltip: AppLocalizations.of(context)!.debugTool,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocalStorageDebugPage(),
                    ),
                  );
                },
              )
            : null,
        title: Text(
          AppLocalizations.of(context)!.appTitle,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showSettingsDialog(context, authService, userService),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000000),  // 纯黑色
              Color(0xFF3D0000),  // 暗红色
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: 40.h),
                
                // AI Personality Selection
                Text(
                  AppLocalizations.of(context)!.selectOpponent,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20.h),
                
                // Normal Characters - 动态加载
                Container(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.horizontalPadding),
                  child: _buildNormalCharacterGrid(),
                ),
                
                SizedBox(height: 20.h),
                
                // VIP Characters Section
                Text(
                  AppLocalizations.of(context)!.vipOpponents,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.h),
                
                // VIP Character Cards - 动态加载
                Container(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.horizontalPadding),
                  child: _buildVIPCharacterGrid(),
                ),
                
                SizedBox(height: 40.h),
                
                // Instructions
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 40.w),
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.gameInstructions,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context)!.instructionsDetail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 40.h),
                
                // Player Profile Analysis
                if (_gameProgress != null && _gameProgress!.totalGames > 0) ...[
                  _buildPlayerAnalysis(),
                ],
                
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPlayerAnalysis() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
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
              const Icon(
                Icons.analytics,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.playerDataAnalysis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Text(
                  AppLocalizations.of(context)!.totalGames(_gameProgress!.totalGames.toString()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 玩家饮酒状态
          if (_drinkingState != null && _drinkingState!.drinksConsumed > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_bar,
                    color: Colors.orange.shade300,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _drinkingState!.statusDescription,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // 显示酒杯数量
                            ...List.generate(6, (index) {
                              return Icon(
                                Icons.local_bar,
                                size: 16,
                                color: index < _drinkingState!.drinksConsumed
                                  ? Colors.red.shade300
                                  : Colors.grey.withValues(alpha: 0.8),
                              );
                            }),
                            // 显示醒酒倒计时
                            if (_drinkingState!.drinksConsumed > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                _getFormattedPlayerSoberTime(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade300,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 醒酒按钮
                  if (_drinkingState!.drinksConsumed >= 3)
                    ElevatedButton(
                      onPressed: () {
                        // 显示醒酒对话框
                        showDialog(
                          context: context,
                          builder: (context) => SoberDialog(
                            drinkingState: _drinkingState!,
                            onWatchAd: () {
                              // 使用公用方法显示广告
                              AdHelper.showRewardedAdWithLoading(
                                context: context,
                                onRewarded: (rewardAmount) {
                                  // 广告观看完成，获得奖励
                                  setState(() {
                                    _drinkingState!.watchAdToSoberPlayer();
                                    _drinkingState!.save();
                                  });
                                  // 记录看广告醒酒次数（玩家自己）
                                  GameProgressService.instance.recordAdSober();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✨ 看完广告，完全清醒了！'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                onCompleted: () {
                                  // 广告流程完成后关闭醒酒对话框
                                  if (mounted && Navigator.canPop(context)) {
                                    Navigator.of(context).pop();
                                  }
                                },
                              );
                            },
                            onUsePotion: () {
                              setState(() {
                                _drinkingState!.useSoberPotion();
                                _drinkingState!.save();
                              });
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)!.usedSoberPotion)),
                              );
                            },
                            onCancel: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.sober,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Overall Stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  AppLocalizations.of(context)!.bluffingTendency,
                  '${(_gameProgress!.bluffingTendency * 100).toStringAsFixed(0)}%',
                  Colors.orange,
                ),
                _buildStatItem(
                  AppLocalizations.of(context)!.aggressiveness,
                  '${(_gameProgress!.aggressiveness * 100).toStringAsFixed(0)}%',
                  Colors.red,
                ),
                _buildStatItem(
                  AppLocalizations.of(context)!.challengeRate,
                  '${(_gameProgress!.challengeRate * 100).toStringAsFixed(0)}%',
                  Colors.purple,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // VS AI Records
          Text(
            AppLocalizations.of(context)!.vsRecord,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          
          ..._gameProgress!.vsNPCRecords.entries.map((entry) {
            final aiId = entry.key;
            final record = entry.value;
            final wins = record['wins'] ?? 0;
            final losses = record['losses'] ?? 0;
            final total = wins + losses;
            
            // 使用NPCConfigService动态获取NPC信息
            final npcService = NPCConfigService();
            final npc = npcService.getNPCById(aiId);
            
            // 如果找不到NPC配置，跳过
            if (npc == null || total == 0) return const SizedBox.shrink();
            
            final aiName = _getLocalizedName(context, npc);
            
            // 根据国家选择颜色主题
            Color aiColor = Colors.grey;
            switch (npc.country) {
              case 'Germany':
                aiColor = Colors.indigo;
                break;
              case 'Russia':
                aiColor = Colors.deepPurple;
                break;
              case 'Japan':
                aiColor = Colors.pink;
                break;
              case 'Brazil':
                aiColor = Colors.orange;
                break;
              default:
                aiColor = Colors.blue;
            }
            
            final winRate = wins * 100.0 / total;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: aiColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: aiColor.withValues(alpha: 0.2),
                      border: Border.all(color: aiColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        aiName[0],
                        style: TextStyle(
                          color: aiColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aiName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$wins${AppLocalizations.of(context)!.win} $losses${AppLocalizations.of(context)!.lose}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: winRate >= 50 
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: winRate >= 50 ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${winRate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: winRate >= 50 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 16),
          
          // Player Style
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF3D0000).withValues(alpha: 0.3),  // 暗红色半透明
                  Color(0xFF8B0000).withValues(alpha: 0.3),  // 深红色半透明
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFF8B0000).withValues(alpha: 0.5),  // 深红色边框
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.gameStyle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _gameProgress!.getStyleDescription(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLanguageChip(String label, String code, BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    bool isSelected = languageService.getLanguageCode() == code;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) async {
        if (selected) {
          // 使用LanguageService切换语言
          await languageService.changeLanguage(code);
          // 显示提示
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('语言已切换为 $label'),
                duration: const Duration(seconds: 1),
              ),
            );
            // 关闭对话框
            Navigator.of(context).pop();
          }
        }
      },
      selectedColor: Colors.blue,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontSize: 14,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
  
  // 动态构建普通角色网格
  Widget _buildNormalCharacterGrid() {
    final normalCharacters = AIPersonalities.normalCharacters;
    
    if (normalCharacters.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.loading,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }
    
    // 每行2个角色
    return SizedBox(
      height: ResponsiveUtils.cardHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < normalCharacters.length; i++) ...[
            if (i > 0) SizedBox(width: 12.w),
            Expanded(
              child: _buildPersonalityCard(
                context,
                normalCharacters[i],
                _getIconForCharacter(normalCharacters[i]),
                _getColorForCharacter(normalCharacters[i]),
              ),
            ),
          ],
          // 如果角色数量是奇数，添加空位
          if (normalCharacters.length % 2 == 1) ...[
            SizedBox(width: 12.w),
            Expanded(child: Container()),
          ],
        ],
      ),
    );
  }
  
  // 动态构建VIP角色网格
  Widget _buildVIPCharacterGrid() {
    final vipCharacters = AIPersonalities.vipCharacters;
    
    if (vipCharacters.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noVIPCharacters,
          style: const TextStyle(color: Colors.amber),
        ),
      );
    }
    
    // 将VIP角色按每行2个分组
    List<Widget> rows = [];
    for (int i = 0; i < vipCharacters.length; i += 2) {
      rows.add(
        SizedBox(
          height: ResponsiveUtils.cardHeight,
          child: Row(
            children: [
              Expanded(
                child: _buildVIPPersonalityCard(
                  context,
                  vipCharacters[i],
                  _getIconForCharacter(vipCharacters[i]),
                  _getColorForCharacter(vipCharacters[i]),
                ),
              ),
              SizedBox(width: 12.w),
              if (i + 1 < vipCharacters.length)
                Expanded(
                  child: _buildVIPPersonalityCard(
                    context,
                    vipCharacters[i + 1],
                    _getIconForCharacter(vipCharacters[i + 1]),
                    _getColorForCharacter(vipCharacters[i + 1]),
                  ),
                )
              else
                Expanded(child: Container()), // 空位
            ],
          ),
        ),
      );
      if (i + 2 < vipCharacters.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    
    return Column(children: rows);
  }
  
  // 为角色获取图标
  IconData _getIconForCharacter(AIPersonality character) {
    // 根据角色特性返回合适的图标
    switch (character.id) {
      case '0001': // Lena
        return Icons.calculate;
      case '0002': // Katerina
        return Icons.diamond;
      case '1001': // Aki
        return Icons.favorite;
      case '1002': // Isabella
        return Icons.sunny;
      default:
        return Icons.person;
    }
  }
  
  // 为角色获取颜色
  Color _getColorForCharacter(AIPersonality character) {
    // 根据角色特性返回合适的颜色
    switch (character.id) {
      case '0001': // Lena
        return Colors.purple;
      case '0002': // Katerina
        return Colors.pink;
      case '1001': // Aki
        return Colors.pinkAccent;
      case '1002': // Isabella
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPersonalityCard(
    BuildContext context,
    AIPersonality personality,
    IconData icon,
    Color color,
  ) {
    // 检查AI是否不能游戏（3杯以上）
    bool isUnavailable = _drinkingState != null && 
                        _drinkingState!.isAIUnavailable(personality.id);
    int aiDrinks = _drinkingState?.getAIDrinks(personality.id) ?? 0;
    
    return GestureDetector(
      onTap: () async {
        if (isUnavailable) {
          // AI醉了，显示醒酒对话框
          _showAISoberDialog(personality);
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameScreen(aiPersonality: personality),
            ),
          );
          // 游戏结束后刷新数据并重启定时器
          await _loadData();  // 等待数据加载完成
          _startTimer();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.8),
              color.withValues(alpha: 0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                // 使用真实头像替换图标
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isUnavailable ? Colors.red : Colors.white, 
                          width: 2,
                        ),
                        image: DecorationImage(
                          image: AssetImage(CharacterAssets.getFullAvatarPath(personality.avatarPath)),
                          fit: BoxFit.cover,
                          colorFilter: isUnavailable 
                            ? ColorFilter.mode(Colors.grey, BlendMode.saturation)
                            : null,
                        ),
                      ),
                    ),
                    // 如果不能游戏，显示醉酒标记
                    if (isUnavailable)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: const Text(
                            '🥴',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _getLocalizedName(context, personality),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // 显示亲密度
                const SizedBox(height: 2),
                Builder(
                  builder: (context) {
                    final intimacy = IntimacyService().getIntimacy(personality.id);
                    return Column(
                      children: [
                        // 等级和数值
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 12,
                              color: Colors.pink.shade400,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Lv.${intimacy.intimacyLevel}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.pink.shade400,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${intimacy.intimacyPoints}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // 进度条
                        Container(
                          width: 120,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Stack(
                            children: [
                              Container(
                                width: 120 * intimacy.levelProgress,
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.pink.shade300,
                                      Colors.pink.shade500,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // 显示AI酒杯数量和倒计时 (始终显示)
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(personality.drinkCapacity, (index) {
                      return Icon(
                        Icons.local_bar,
                        size: 12,
                        color: index < aiDrinks
                          ? Colors.red.shade300
                          : Colors.grey.withValues(alpha: 0.8),
                      );
                    }),
                    // 显示醒酒倒计时
                    if (aiDrinks > 0 && _drinkingState != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        _getFormattedSoberTime(personality.id),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade300,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _getLocalizedDescription(context, personality),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // VS Record - 始终显示战绩（即使是0胜0负）
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_gameProgress?.vsNPCRecords[personality.id]?['wins'] ?? 0}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade300,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.win,
                        style: TextStyle(
                          fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_gameProgress?.vsNPCRecords[personality.id]?['losses'] ?? 0}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade300,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.lose,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVIPPersonalityCard(
    BuildContext context,
    AIPersonality personality,
    IconData icon,
    Color color,
  ) {
    // 检查AI是否不能游戏（3杯以上）
    bool isUnavailable = _drinkingState != null && 
                        _drinkingState!.isAIUnavailable(personality.id);
    int aiDrinks = _drinkingState?.getAIDrinks(personality.id) ?? 0;
    
    return FutureBuilder<VIPStatus>(
      future: VIPUnlockService().getVIPStatus(personality.id),
      builder: (context, snapshot) {
        final vipStatus = snapshot.data ?? VIPStatus.locked;
        final isLocked = vipStatus == VIPStatus.locked;
        
        return GestureDetector(
          onTap: () async {
            // 在点击时重新检查醉酒状态
            bool currentlyUnavailable = _drinkingState != null && 
                                      _drinkingState!.isAIUnavailable(personality.id);
            
            if (isLocked) {
              // 显示VIP解锁对话框
              await VIPUnlockService.showVIPUnlockDialog(
                context: context,
                character: personality,
              );
              
              // 对话框关闭后，刷新界面以检查是否已解锁
              setState(() {});
              
              // 延迟一下让界面刷新
              await Future.delayed(const Duration(milliseconds: 500));
              
              // 再次检查解锁状态和醉酒状态
              bool nowUnlocked = await VIPUnlockService().isUnlocked(personality.id);
              bool stillUnavailable = _drinkingState != null && 
                                    _drinkingState!.isAIUnavailable(personality.id);
              
              // 如果现在已解锁且AI不醉，直接进入游戏
              if (nowUnlocked && !stillUnavailable && mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(aiPersonality: personality),
                  ),
                );
                await _loadData();
                _startTimer();
              } else if (nowUnlocked && stillUnavailable && mounted) {
                // 解锁了但是AI醉了
                _showAISoberDialog(personality);
              }
            } else if (currentlyUnavailable) {
              // AI醉了，显示醒酒对话框
              _showAISoberDialog(personality);
            } else {
              // 已解锁且AI清醒，直接进入游戏
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameScreen(aiPersonality: personality),
                ),
              );
              await _loadData();
              _startTimer();
            }
          },
          child: Container(
            width: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLocked
                  ? [Colors.grey.shade700, Colors.grey.shade800]
                  : [
                      color.withValues(alpha: 0.8),
                      color.withValues(alpha: 0.4),
                    ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLocked ? Colors.grey : Colors.amber,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isLocked ? Colors.black26 : Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // VIP标记
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'VIP',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                
                // 锁定图标
                if (isLocked)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.lock,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  )
                else if (vipStatus == VIPStatus.tempUnlocked)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FutureBuilder<Duration?>(
                      future: VIPUnlockService().getTempUnlockRemaining(personality.id),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final minutes = snapshot.data!.inMinutes;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$minutes分钟',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 头像
                      Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isLocked 
                                  ? Colors.grey 
                                  : (isUnavailable ? Colors.red : Colors.amber), 
                                width: 2,
                              ),
                              image: DecorationImage(
                                image: AssetImage(CharacterAssets.getFullAvatarPath(personality.avatarPath)),
                                fit: BoxFit.cover,
                                colorFilter: (isLocked || isUnavailable)
                                  ? ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                  : null,
                              ),
                            ),
                          ),
                          // 醉酒标记
                          if (isUnavailable && !isLocked)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: const Text(
                                  '🥴',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // 名字
                      Text(
                        _getLocalizedName(context, personality),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? Colors.grey.shade300 : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // 显示亲密度（锁定和未锁定都显示）
                      const SizedBox(height: 2),
                      Builder(
                        builder: (context) {
                          final intimacy = IntimacyService().getIntimacy(personality.id);
                          return Column(
                            children: [
                              // 等级和数值
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    size: 10,
                                    color: isLocked 
                                      ? Colors.grey.shade400
                                      : Colors.pink.shade400,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Lv.${intimacy.intimacyLevel}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isLocked 
                                        ? Colors.grey.shade400
                                        : Colors.pink.shade400,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${intimacy.intimacyPoints}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isLocked 
                                        ? Colors.grey.shade500
                                        : Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              // 进度条
                              Container(
                                width: 100,
                                height: 2.5,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100 * intimacy.levelProgress,
                                      height: 2.5,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isLocked
                                            ? [Colors.grey.shade500, Colors.grey.shade600]
                                            : [Colors.pink.shade300, Colors.pink.shade500],
                                        ),
                                        borderRadius: BorderRadius.circular(1.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      
                      // 酒杯状态（显示在描述之前）
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(personality.drinkCapacity, (index) {
                            return Icon(
                              Icons.local_bar,
                              size: 10,
                              color: isLocked
                                ? (index < aiDrinks 
                                    ? Colors.grey.shade500 
                                    : Colors.grey.withValues(alpha: 0.7))
                                : (index < aiDrinks
                                    ? Colors.red.shade300
                                    : Colors.grey.withValues(alpha: 0.8)),
                            );
                          }),
                        ],
                      ),
                      
                      // 描述
                      const SizedBox(height: 4),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _getLocalizedDescription(context, personality),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: isLocked ? Colors.grey.shade500 : Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      
                      // VS Record - 显示战绩（即使是0胜0负）
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_gameProgress?.vsNPCRecords[personality.id]?['wins'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isLocked ? Colors.grey.shade400 : Colors.green.shade300,
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context)!.win,
                              style: TextStyle(
                                fontSize: 9,
                                color: isLocked ? Colors.grey.shade500 : Colors.white60,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_gameProgress?.vsNPCRecords[personality.id]?['losses'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isLocked ? Colors.grey.shade400 : Colors.red.shade300,
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context)!.lose,
                              style: TextStyle(
                                fontSize: 9,
                                color: isLocked ? Colors.grey.shade500 : Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // 显示AI醒酒对话框
  void _showAISoberDialog(AIPersonality personality) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.orange.shade900,
                Colors.red.shade900,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI头像和状态
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 3),
                  image: DecorationImage(
                    image: AssetImage(CharacterAssets.getFullAvatarPath(personality.avatarPath)),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Colors.grey, BlendMode.saturation),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.aiIsDrunk(_getLocalizedName(context, personality)),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              // 醒酒倒计时
              if (_drinkingState != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getFormattedSoberTime(personality.id),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Text(
                  '她喝醉了，无法陪你游戏\n需要你帮她醒酒',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 醒酒选项
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 看广告
                  ElevatedButton.icon(
                    onPressed: () {
                      // 使用公用方法显示广告（先关闭当前对话框）
                      AdHelper.showRewardedAdAfterDialogClose(
                        context: context,
                        onRewarded: (rewardAmount) {
                          // 广告观看完成，获得奖励
                          setState(() {
                            _drinkingState!.watchAdToSoberAI(personality.id);
                            _drinkingState!.save();
                          });
                          // 记录为NPC看广告醒酒次数
                          GameProgressService.instance.recordAdSober(npcId: personality.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.aiSoberSuccess(_getLocalizedName(context, personality))),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.play_circle_outline, size: 22, color: Colors.white),
                    label: const Text(
                      '看广告',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                  // 取消
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close, size: 22, color: Colors.white),
                    label: const Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
  
  // 显示设置对话框
  void _showSettingsDialog(BuildContext context, AuthService authService, UserService userService) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A0000),  // 深黑红色
                Color(0xFF3D0000),  // 暗红色
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Text(
                AppLocalizations.of(context)!.settings,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              
              // 用户头像
              CircleAvatar(
                radius: 40,
                backgroundImage: authService.photoURL != null
                    ? NetworkImage(authService.photoURL!)
                    : null,
                backgroundColor: Colors.white24,
                child: authService.photoURL == null
                    ? Icon(
                        authService.isAnonymous
                            ? Icons.person_outline
                            : Icons.person,
                        size: 40,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              
              // 用户名
              Text(
                userService.displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              
              // 用户ID
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7, // 最大宽度为屏幕的70%
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        'ID: ${authService.uid ?? "未登录"}',
                        style: const TextStyle(
                          fontSize: 12,  // 减小2号，从14改为12
                          color: Colors.white70,
                          letterSpacing: -0.2,  // 稍微减小字母间距以显示更多内容
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        if (authService.uid != null) {
                          Clipboard.setData(ClipboardData(text: authService.uid!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.copiedToClipboard),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Icon(
                        Icons.copy,
                        size: 14,  // 图标也相应减小
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 统计信息
              if (userService.playerProfile != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            '胜率',
                            '${(userService.winRate * 100).toStringAsFixed(1)}%',
                            Colors.green,
                          ),
                          _buildStatItem(
                            AppLocalizations.of(context)!.totalGamesCount,
                            '${userService.playerProfile!.totalGames}',
                            Colors.blue,
                          ),
                          _buildStatItem(
                            '胜场',
                            '${userService.playerProfile!.totalWins}',
                            Colors.amber,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
              ],
              
              // 语言选择
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.language,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.language,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 语言选项
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildLanguageChip('简体中文', 'zh_CN', context),
                        _buildLanguageChip('English', 'en', context),
                        _buildLanguageChip('中文繁體', 'zh_TW', context),
                        _buildLanguageChip('Español', 'es', context),
                        _buildLanguageChip('Português', 'pt', context),
                        _buildLanguageChip('Bahasa', 'id', context),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 登出按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // 先关闭对话框
                    Navigator.of(context).pop();
                    
                    // 执行登出
                    await authService.signOut();
                    
                    // 导航到登录页
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(AppLocalizations.of(context)!.logout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // 关闭按钮
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  '关闭',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}
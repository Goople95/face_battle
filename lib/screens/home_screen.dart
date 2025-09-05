import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import 'game_screen.dart';
import '../models/ai_personality.dart';
import '../services/game_progress_service.dart';
import '../models/game_progress.dart';
import '../models/drinking_state.dart';
import '../widgets/player_drunk_dialog.dart';
import '../widgets/drunk_dialog.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/language_service.dart';
import '../utils/ad_helper.dart';
import '../utils/responsive_utils.dart';
import '../services/vip_unlock_service.dart';
import '../services/purchase_service.dart';
import '../config/character_config.dart';
import '../services/intimacy_service.dart';
import '../models/intimacy_data.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/local_storage_debug_tool.dart';
import '../services/analytics_service.dart';
import '../services/npc_config_service.dart';
import '../services/storage/local_storage_service.dart';
import '../utils/logger_utils.dart';
import '../widgets/rules_display.dart';
import '../widgets/npc_avatar_widget.dart';
import '../services/npc_skin_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  GameProgressData? _gameProgress;
  DrinkingState? _drinkingState;
  Timer? _soberTimer;
  PackageInfo? _packageInfo;
  int _vipRebuildKey = 0; // 用于强制刷新VIP卡片
  
  // 获取当前应用的locale代码
  String _getLocaleCode(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;
    
    // 处理中文的特殊情况
    if (languageCode == 'zh') {
      // 只支持繁体中文
      return 'zh_TW';
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
    // 获取版本信息
    _initPackageInfo();
    // 监听authService变化，更新userService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncUserService();
    });
  }
  
  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
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
    
    // 初始化NPCSkinService（需要在GameProgressService加载之后）
    await NPCSkinService.instance.initialize();
    
    // 手動刷新皮膚數據，確保監聽器收到最新數據
    NPCSkinService.instance.refreshSkinData();
    
    // 更新醒酒状态（DrinkingState.load() 内部已经调用了 updateSoberStatus）
    // drinking.updateSoberStatus();  // 不需要重复调用
    // await drinking.save();  // 如果没有实际变化，不需要保存
    
    // 设置状态并强制刷新界面，确保NPC图片使用正确的皮肤
    if (mounted) {
      setState(() {
        _gameProgress = progress;
        _drinkingState = drinking;
      });
    }
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
                icon: Icon(Icons.bug_report, color: Colors.orange),
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
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
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
                  style: TextStyle(
                    fontSize: 20.sp,
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
                  style: TextStyle(
                    fontSize: 20.sp,
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
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.gameInstructions,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      const RulesDisplay(),
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
        borderRadius: BorderRadius.circular(20.r),
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
                Icons.analytics,
                color: Colors.white,
                size: 28.r,
              ),
              SizedBox(width: 10.w),
              Text(
                AppLocalizations.of(context)!.playerDataAnalysis,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Text(
                  AppLocalizations.of(context)!.totalGames(_gameProgress!.totalGames.toString()),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          
          // Overall Stats
          Container(
            padding: EdgeInsets.all(12.r),
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
          
          SizedBox(height: 16.h),
          
          // VS AI Records
          Text(
            AppLocalizations.of(context)!.vsRecord,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10.h),
          
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
              padding: EdgeInsets.all(10.r),
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
                          fontSize: 16.sp,
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
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                        Text(
                          '$wins${AppLocalizations.of(context)!.win} $losses${AppLocalizations.of(context)!.lose}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: winRate >= 50 
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
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
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          
          SizedBox(height: 16.h),
          
          // Player Style
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.r),
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
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _gameProgress!.getStyleDescription(context),
                  style: TextStyle(
                    fontSize: 13.sp,
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
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
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
                content: Text(AppLocalizations.of(context)!.languageChanged(label)),
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
        fontSize: 14.sp,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
    );
  }
  
  // 动态构建普通角色网格
  Widget _buildNormalCharacterGrid() {
    final normalCharacters = AIPersonalities.normalCharacters;
    
    if (normalCharacters.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.loading,
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    
    // 将普通角色按每行2个分组（与VIP角色保持一致）
    List<Widget> rows = [];
    for (int i = 0; i < normalCharacters.length; i += 2) {
      rows.add(
        SizedBox(
          height: ResponsiveUtils.cardHeight,
          child: Row(
            children: [
              Expanded(
                child: _buildPersonalityCard(
                  context,
                  normalCharacters[i],
                  _getIconForCharacter(normalCharacters[i]),
                  _getColorForCharacter(normalCharacters[i]),
                ),
              ),
              SizedBox(width: 12.w),
              if (i + 1 < normalCharacters.length)
                Expanded(
                  child: _buildPersonalityCard(
                    context,
                    normalCharacters[i + 1],
                    _getIconForCharacter(normalCharacters[i + 1]),
                    _getColorForCharacter(normalCharacters[i + 1]),
                  ),
                )
              else
                Expanded(child: Container()), // 空位
            ],
          ),
        ),
      );
      if (i + 2 < normalCharacters.length) {
        rows.add(SizedBox(height: 16.h)); // 行间距
      }
    }
    
    return Column(
      children: rows,
    );
  }
  
  // 动态构建VIP角色网格
  Widget _buildVIPCharacterGrid() {
    final vipCharacters = AIPersonalities.vipCharacters;
    
    if (vipCharacters.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noVIPCharacters,
          style: TextStyle(color: Colors.amber),
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
        rows.add(SizedBox(height: 12.h));
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
        // 记录NPC点击事件
        AnalyticsService().logButtonClick(
          buttonName: 'npc_card',
          screen: 'home',
          additionalParams: {
            'npc_id': personality.id,
            'npc_name': personality.name,
            'is_vip': personality.isVIP ? 1 : 0,  // 转换为数字
            'is_drunk': isUnavailable ? 1 : 0,     // 转换为数字
          },
        );
        
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
          borderRadius: BorderRadius.circular(20.r),
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
                    // 头像
                    NPCAvatarWidget(
                      personality: personality,
                      size: 60.r,
                      showBorder: true,
                      isUnavailable: isUnavailable,
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
                          child: Text(
                            '🥴',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  _getLocalizedName(context, personality),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // 显示亲密度
                SizedBox(height: 2.h),
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
                              size: 12.r,
                              color: Colors.pink.shade400,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Lv.${intimacy.intimacyLevel}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.pink.shade400,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${intimacy.currentLevelPoints}',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
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
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(personality.drinkCapacity, (index) {
                      return Icon(
                        Icons.local_bar,
                        size: 12.r,
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
                          fontSize: 10.sp,
                          color: Colors.green.shade300,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _getLocalizedDescription(context, personality),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // VS Record - 始终显示战绩（即使是0胜0负）
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
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
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade300,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.win,
                        style: TextStyle(
                          fontSize: 10.sp,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_gameProgress?.vsNPCRecords[personality.id]?['losses'] ?? 0}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade300,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.lose,
                          style: TextStyle(
                            fontSize: 10.sp,
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
      key: ValueKey('vip_${personality.id}_$_vipRebuildKey'), // 添加key来强制重建
      future: VIPUnlockService().getVIPStatus(personality.id),
      builder: (context, snapshot) {
        final vipStatus = snapshot.data ?? VIPStatus.locked;
        // 使用PurchaseService检查永久解锁状态
        final isPermanentlyUnlocked = PurchaseService.instance.isNPCPurchased(personality.id);
        final isLocked = vipStatus == VIPStatus.locked && !isPermanentlyUnlocked;
        
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
              setState(() {
                _vipRebuildKey++; // 强制刷新VIP卡片
              });
              
              // 延迟一下让界面刷新
              await Future.delayed(const Duration(milliseconds: 500));
              
              // 再次检查解锁状态和醉酒状态
              bool nowUnlocked = await VIPUnlockService().isUnlocked(personality.id) || 
                                PurchaseService.instance.isNPCPurchased(personality.id);
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
                colors: [
                  color.withValues(alpha: 0.8),
                  color.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: Colors.amber,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
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
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'VIP',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ),
                
                // 锁定图标
                if (isLocked)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 16.r,
                      ),
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
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.tempUnlockTime(minutes),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
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
                          // VIP卡片头像
                          NPCAvatarWidget(
                            personality: personality,
                            size: 60.r,
                            showBorder: true,
                            isUnavailable: isUnavailable,
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
                                child: Text(
                                  '🥴',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      
                      // 名字
                      Text(
                        _getLocalizedName(context, personality),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // 显示亲密度（锁定和未锁定都显示）
                      SizedBox(height: 2.h),
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
                                    size: 10.r,
                                    color: Colors.pink.shade400,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Lv.${intimacy.intimacyLevel}',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.pink.shade400,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${intimacy.currentLevelPoints}',
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      color: Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 3.h),
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
                                          colors: [Colors.pink.shade300, Colors.pink.shade500],
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
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(personality.drinkCapacity, (index) {
                            return Icon(
                              Icons.local_bar,
                              size: 10.r,
                              color: index < aiDrinks
                                ? Colors.red.shade300
                                : Colors.grey.withValues(alpha: 0.8),
                            );
                          }),
                        ],
                      ),
                      
                      // 描述
                      SizedBox(height: 4.h),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _getLocalizedDescription(context, personality),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      
                      // VS Record - 显示战绩（即使是0胜0负）
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
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
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade300,
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context)!.win,
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: Colors.white60,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_gameProgress?.vsNPCRecords[personality.id]?['losses'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade300,
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context)!.lose,
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: Colors.white60,
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
    if (_drinkingState == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DrunkDialog(
        personality: personality,
        drinkingState: _drinkingState!,
        onSoberSuccess: () {
          setState(() {});
        },
      ),
    );
  }
  
  // 显示设置对话框
  void _showSettingsDialog(BuildContext context, AuthService authService, UserService userService) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
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
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20.h),
              
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
                        size: 40.r,
                        color: Colors.white,
                      )
                    : null,
              ),
              SizedBox(height: 16.h),
              
              // 用户名
              Text(
                userService.displayName,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              
              // 用户ID
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7, // 最大宽度为屏幕的70%
                ),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        'ID: ${authService.uid ?? "未登录"}',
                        style: TextStyle(
                          fontSize: 12.sp,  // 减小2号，从14改为12
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
                      child: Icon(
                        Icons.copy,
                        size: 14.r,  // 图标也相应减小
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              
              // 版本号显示
              if (_packageInfo != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Text(
                    '${AppLocalizations.of(context)!.version}: ${_packageInfo!.version}+${_packageInfo!.buildNumber}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white60,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              SizedBox(height: 12.h),
              
              // 统计信息
              if (userService.playerProfile != null) ...[
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            AppLocalizations.of(context)!.winRate,
                            '${(userService.winRate * 100).toStringAsFixed(1)}%',
                            Colors.green,
                          ),
                          _buildStatItem(
                            AppLocalizations.of(context)!.totalGamesCount,
                            '${userService.playerProfile!.totalGames}',
                            Colors.blue,
                          ),
                          _buildStatItem(
                            AppLocalizations.of(context)!.totalWins,
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
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.language,
                          color: Colors.white70,
                          size: 20.r,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.language,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    // 语言选项
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
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
              SizedBox(height: 20.h),
              
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
                  icon: Icon(Icons.logout),
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
              
              SizedBox(height: 10.h),
              
              // 关闭按钮
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppLocalizations.of(context)!.close,
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
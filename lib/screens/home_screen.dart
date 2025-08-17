import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'game_screen.dart';
import '../models/ai_personality.dart';
import '../models/player_profile.dart';
import '../models/drinking_state.dart';
import '../widgets/sober_dialog.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/ad_helper.dart';
import '../services/vip_unlock_service.dart';
import '../config/character_assets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  PlayerProfile? _playerProfile;
  DrinkingState? _drinkingState;
  Timer? _soberTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _startTimer();
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
    final profile = await PlayerProfile.load();
    final drinking = await DrinkingState.load();
    
    // 更新醒酒状态（DrinkingState.load() 内部已经调用了 updateSoberStatus）
    // drinking.updateSoberStatus();  // 不需要重复调用
    // await drinking.save();  // 如果没有实际变化，不需要保存
    
    setState(() {
      _playerProfile = profile;
      _drinkingState = drinking;
    });
  }
  
  void _updateSoberStatus() async {
    if (_drinkingState != null) {
      // 每10秒重新加载一次数据，确保获取最新状态
      if (DateTime.now().second % 10 == 0) {
        final latestState = await DrinkingState.load();
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
  
  // 格式化醒酒倒计时
  String _getFormattedSoberTime(String aiId) {
    final seconds = _drinkingState!.getAINextSoberSeconds(aiId);
    if (seconds == 0) return '';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  // 格式化玩家醒酒倒计时
  String _getFormattedPlayerSoberTime() {
    final seconds = _drinkingState!.getPlayerNextSoberSeconds();
    if (seconds == 0) return '';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userService = Provider.of<UserService>(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.purple.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // 用户信息栏
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 用户信息
                      Row(
                        children: [
                          // 头像
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: authService.photoURL != null
                                ? NetworkImage(authService.photoURL!)
                                : null,
                            backgroundColor: Colors.white24,
                            child: authService.photoURL == null
                                ? Icon(
                                    authService.isAnonymous
                                        ? Icons.person_outline
                                        : Icons.person,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          // 名字
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userService.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (userService.playerProfile != null)
                                Text(
                                  '胜率: ${(userService.winRate * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      // 登出按钮
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          // 显示确认对话框
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('确认登出'),
                              content: Text(authService.isAnonymous
                                  ? '登出后游客数据将丢失，确定要登出吗？'
                                  : '确定要登出吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('确定'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm == true) {
                            await authService.signOut();
                            userService.clear();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                // Title - get from app name
                const Text(
                  '骰子吹牛',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black54,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                
                // AI Personality Selection
                const Text(
                  '选择对手',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Personality Cards - Now with 4 characters in 2x2 grid
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // First row
                      SizedBox(
                        height: 200,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _buildPersonalityCard(
                                context,
                                AIPersonalities.professor,
                                Icons.school,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPersonalityCard(
                                context,
                                AIPersonalities.gambler,
                                Icons.casino,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Second row
                      SizedBox(
                        height: 200,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _buildPersonalityCard(
                                context,
                                AIPersonalities.provocateur,
                                Icons.psychology,
                                Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPersonalityCard(
                                context,
                                AIPersonalities.youngwoman,
                                Icons.favorite,
                                Colors.pink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // VIP Characters Section
                const Text(
                  'VIP对手',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                
                // VIP Character Cards
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 200,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildVIPPersonalityCard(
                          context,
                          AIPersonalities.aki,
                          Icons.favorite,
                          Colors.pink,
                        ),
                        const SizedBox(width: 12),
                        _buildVIPPersonalityCard(
                          context,
                          AIPersonalities.katerina,
                          Icons.diamond,
                          Colors.deepPurple,
                        ),
                        const SizedBox(width: 12),
                        _buildVIPPersonalityCard(
                          context,
                          AIPersonalities.lena,
                          Icons.calculate,
                          Colors.indigo,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Instructions
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: const [
                      Text(
                        '游戏说明',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '• 双方各掷5颗骰子，轮流报数\n'
                        '• 1点是万能牌，可当任何点数\n'
                        '• 报数必须递增或换更高点数\n'
                        '• 质疑对方时判断真假',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Player Profile Analysis
                if (_playerProfile != null && _playerProfile!.totalGames > 0) ...[
                  _buildPlayerAnalysis(),
                ],
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPlayerAnalysis() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
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
              const Icon(
                Icons.analytics,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Text(
                '玩家数据分析',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Text(
                  '${_playerProfile!.totalGames}局',
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
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.5),
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
                                  : Colors.grey.withOpacity(0.3),
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
                                const SnackBar(content: Text('使用醒酒药水，清醒了2杯！')),
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
                      child: const Text(
                        '醒酒',
                        style: TextStyle(fontSize: 12),
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
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '虚张倾向',
                  '${(_playerProfile!.bluffingTendency * 100).toStringAsFixed(0)}%',
                  Colors.orange,
                ),
                _buildStatItem(
                  '激进程度',
                  '${(_playerProfile!.aggressiveness * 100).toStringAsFixed(0)}%',
                  Colors.red,
                ),
                _buildStatItem(
                  '质疑率',
                  '${(_playerProfile!.challengeRate * 100).toStringAsFixed(0)}%',
                  Colors.purple,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // VS AI Records
          const Text(
            '对战记录',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          
          ..._playerProfile!.vsAIRecords.entries.map((entry) {
            final aiId = entry.key;
            final record = entry.value;
            final wins = record['wins'] ?? 0;
            final losses = record['losses'] ?? 0;
            final total = wins + losses;
            
            String aiName = '';
            Color aiColor = Colors.grey;
            if (aiId == '0001' || aiId == 'professor') { // 兼容旧ID
              aiName = '稳重大叔';
              aiColor = Colors.blue;
            } else if (aiId == '0002' || aiId == 'gambler') {
              aiName = '冲动小哥';
              aiColor = Colors.red;
            } else if (aiId == '0003' || aiId == 'provocateur') {
              aiName = '心机御姐';
              aiColor = Colors.purple;
            } else if (aiId == '0004' || aiId == 'youngwoman') {
              aiName = '活泼少女';
              aiColor = Colors.pink;
            } else if (aiId == '1001' || aiId == 'aki') {
              aiName = '亚希';
              aiColor = Colors.pink;
            } else if (aiId == '1002' || aiId == 'katerina') {
              aiName = '卡捷琳娜';
              aiColor = Colors.deepPurple;
            } else if (aiId == '1003' || aiId == 'lena') {
              aiName = '莱娜';
              aiColor = Colors.indigo;
            }
            
            if (total == 0) return const SizedBox.shrink();
            
            final winRate = wins * 100.0 / total;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: aiColor.withOpacity(0.3),
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
                      color: aiColor.withOpacity(0.2),
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
                  const SizedBox(width: 12),
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
                          '$wins胜 $losses负',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
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
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
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
          }).toList(),
          
          const SizedBox(height: 16),
          
          // Player Style
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.3),
                  Colors.blue.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.purple.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '游戏风格',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _playerProfile!.getStyleDescription(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
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
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
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
              color.withOpacity(0.8),
              color.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
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
                  personality.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // 显示AI酒杯数量和倒计时 (始终显示)
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(6, (index) {
                      return Icon(
                        Icons.local_bar,
                        size: 12,
                        color: index < aiDrinks
                          ? Colors.red.shade300
                          : Colors.grey.withOpacity(0.3),
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
                      personality.description,
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
                // VS Record
                if (_playerProfile != null && 
                    _playerProfile!.vsAIRecords[personality.id] != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_playerProfile!.vsAIRecords[personality.id]!['wins'] ?? 0}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade300,
                          ),
                        ),
                        Text(
                          '胜',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_playerProfile!.vsAIRecords[personality.id]!['losses'] ?? 0}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade300,
                          ),
                        ),
                        Text(
                          '负',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ],
              ),
            ),
            // Win rate badge (top right corner)
            if (_playerProfile != null && 
                _playerProfile!.vsAIRecords[personality.id] != null &&
                ((_playerProfile!.vsAIRecords[personality.id]!['wins'] ?? 0) + 
                 (_playerProfile!.vsAIRecords[personality.id]!['losses'] ?? 0)) > 0) 
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_playerProfile!.vsAIRecords[personality.id]!['wins']! > 
                            _playerProfile!.vsAIRecords[personality.id]!['losses']!)
                      ? Colors.green.withOpacity(0.9)
                      : Colors.red.withOpacity(0.9),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${((_playerProfile!.vsAIRecords[personality.id]!['wins'] ?? 0) * 100 ~/ 
                      ((_playerProfile!.vsAIRecords[personality.id]!['wins'] ?? 0) + 
                       (_playerProfile!.vsAIRecords[personality.id]!['losses'] ?? 0)))}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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
              
              // 再次检查解锁状态
              bool nowUnlocked = await VIPUnlockService().isUnlocked(personality.id);
              
              // 如果现在已解锁且AI不醉，直接进入游戏
              if (nowUnlocked && !isUnavailable) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(aiPersonality: personality),
                  ),
                );
                await _loadData();
                _startTimer();
              }
            } else if (isUnavailable) {
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
                      color.withOpacity(0.8),
                      color.withOpacity(0.4),
                    ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLocked ? Colors.grey : Colors.amber,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isLocked ? Colors.black26 : Colors.amber.withOpacity(0.3),
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
                      color: Colors.white.withOpacity(0.7),
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
                              '${minutes}分钟',
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
                        personality.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? Colors.grey.shade300 : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // 难度标签
                      if (personality.difficulty != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(personality.difficulty!).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getDifficultyColor(personality.difficulty!),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getDifficultyText(personality.difficulty!),
                            style: TextStyle(
                              fontSize: 10,
                              color: isLocked 
                                ? Colors.grey.shade400 
                                : _getDifficultyColor(personality.difficulty!),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      
                      // 描述
                      const SizedBox(height: 4),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            personality.description,
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
                      
                      // 酒杯状态（只有解锁后才显示）
                      if (!isLocked && aiDrinks > 0) ...[  
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...List.generate(6, (index) {
                              return Icon(
                                Icons.local_bar,
                                size: 10,
                                color: index < aiDrinks
                                  ? Colors.red.shade300
                                  : Colors.grey.withOpacity(0.3),
                              );
                            }),
                          ],
                        ),
                      ],
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
  
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      case 'expert':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
  
  String _getDifficultyText(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return '简单';
      case 'medium':
        return '中等';
      case 'hard':
        return '困难';
      case 'expert':
        return '专家';
      default:
        return difficulty;
    }
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
                '${personality.name}醉了！',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '已喝${_drinkingState!.getAIDrinks(personality.id)}杯酒',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '该AI已经微醺，无法陪你游戏\n需要帮TA醒酒才能继续',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✨ ${personality.name}醒酒成功！'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.play_circle_outline, size: 20),
                    label: const Text('看广告'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  // 取消
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('取消'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
}
import 'package:flutter/material.dart';
import 'dart:async';
import 'game_screen.dart';
import '../models/ai_personality.dart';
import '../models/player_profile.dart';
import '../models/drinking_state.dart';
import '../widgets/sober_dialog.dart';

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
                const SizedBox(height: 40),
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
                              setState(() {
                                _drinkingState!.watchAdToSoberPlayer();
                                _drinkingState!.save();
                              });
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('看完广告，完全清醒了！')),
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
            if (aiId == 'professor') {
              aiName = '稳重大叔';
              aiColor = Colors.blue;
            } else if (aiId == 'gambler') {
              aiName = '冲动小哥';
              aiColor = Colors.red;
            } else if (aiId == 'provocateur') {
              aiName = '心机御姐';
              aiColor = Colors.purple;
            } else if (aiId == 'youngwoman') {
              aiName = '活泼少女';
              aiColor = Colors.pink;
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
                          image: AssetImage(personality.avatarPath),
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
                    image: AssetImage(personality.avatarPath),
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
                      setState(() {
                        _drinkingState!.watchAdToSoberAI(personality.id);
                        _drinkingState!.save();
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${personality.name}醒酒成功！')),
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
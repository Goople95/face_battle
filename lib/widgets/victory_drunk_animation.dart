/// 胜利醉倒动画组件
/// 
/// 当NPC被喝醉时展示的胜利动画和成就感增强界面

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import '../models/ai_personality.dart';
import '../models/drinking_state.dart';
import '../services/share_service.dart';

/// 醉倒胜利动画
class VictoryDrunkAnimation extends StatefulWidget {
  final AIPersonality defeatedAI;
  final DrinkingState drinkingState;
  final VoidCallback onComplete;
  final VoidCallback? onShare;
  final VoidCallback? onRematch;
  
  const VictoryDrunkAnimation({
    Key? key,
    required this.defeatedAI,
    required this.drinkingState,
    required this.onComplete,
    this.onShare,
    this.onRematch,
  }) : super(key: key);
  
  @override
  State<VictoryDrunkAnimation> createState() => _VictoryDrunkAnimationState();
}

class _VictoryDrunkAnimationState extends State<VictoryDrunkAnimation>
    with TickerProviderStateMixin {
  
  // 视频控制器
  VideoPlayerController? _videoController;
  
  // 动画控制器
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _shakeController;
  late ConfettiController _confettiController;
  
  // 动画
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _shakeAnimation;
  
  // 状态
  bool _videoInitialized = false;
  bool _showingStats = false;
  bool _showingIntimacy = false;  // 显示亲密度场景
  int _totalWins = 0;
  int _consecutiveWins = 0;
  int _intimacyMinutes = 0;  // 独处时间
  
  @override
  void initState() {
    super.initState();
    
    // 触觉反馈
    HapticFeedback.heavyImpact();
    
    // 初始化动画控制器
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    
    // 设置动画
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.bounceOut,
    ));
    
    _shakeAnimation = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticInOut,
    ));
    
    // 加载视频
    _initializeVideo();
    
    // 启动动画序列
    _startAnimationSequence();
  }
  
  /// 初始化视频
  Future<void> _initializeVideo() async {
    // 醉倒视频路径
    String videoPath = 'assets/people/${widget.defeatedAI.id}/videos/drunk.mp4';
    
    try {
      _videoController = VideoPlayerController.asset(videoPath);
      await _videoController!.initialize();
      
      setState(() {
        _videoInitialized = true;
      });
      
      // 播放视频
      _videoController!.setLooping(false);
      _videoController!.play();
      
      // 视频播放完毕后显示亲密度场景
      _videoController!.addListener(() {
        if (_videoController!.value.position >= _videoController!.value.duration) {
          if (!_showingIntimacy && !_showingStats) {
            // 生成5-20之间的随机数
            _intimacyMinutes = 5 + math.Random().nextInt(16);
            setState(() {
              _showingIntimacy = true;
            });
            // 淡出效果
            _fadeController.reverse().then((_) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _fadeController.forward();
                }
              });
            });
          }
        }
      });
      
    } catch (e) {
      print('加载醉倒视频失败: $e');
      // 如果视频加载失败，也显示亲密度场景
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _intimacyMinutes = 5 + math.Random().nextInt(16);
          setState(() {
            _showingIntimacy = true;
          });
          _fadeController.reverse().then((_) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _fadeController.forward();
              }
            });
          });
        }
      });
    }
  }
  
  /// 启动动画序列
  void _startAnimationSequence() async {
    // 淡入
    _fadeController.forward();
    
    // 延迟启动其他动画
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _slideController.forward();
    
    // 播放彩带动画
    _confettiController.play();
    
    // 震动反馈
    HapticFeedback.mediumImpact();
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          // 背景渐变
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            decoration: BoxDecoration(
              gradient: _showingIntimacy
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.black.withOpacity(0.95),
                        Colors.black,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.red.shade900.withOpacity(0.5),
                        Colors.black,
                      ],
                    ),
            ),
          ),
          
          // 主内容
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // 顶部标题（亲密度场景时隐藏）
                  if (!_showingIntimacy)
                    SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // 胜利标题
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: const Text(
                                '🏆 完美胜利！',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
                                      color: Colors.amber,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 10),
                            
                            // 副标题
                            Text(
                              '${widget.defeatedAI.name} 已经烂醉如泥！',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // 中间内容区域
                  Expanded(
                    child: Center(
                      child: _showingIntimacy
                          ? _buildIntimacyView()
                          : _showingStats
                              ? _buildStatsView()
                              : _buildVideoView(),
                    ),
                  ),
                  
                  // 底部按钮（亲密度场景时隐藏）
                  if (!_showingIntimacy)
                    _buildBottomButtons(),
                ],
              ),
            ),
          ),
          
          // 彩带效果（亲密度场景时隐藏）
          if (!_showingIntimacy)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: math.pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                maxBlastForce: 20,
                minBlastForce: 10,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.1,
                shouldLoop: false,
                colors: const [
                  Colors.amber,
                  Colors.orange,
                  Colors.red,
                  Colors.yellow,
                  Colors.pink,
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  /// 构建亲密度场景视图
  Widget _buildIntimacyView() {
    return GestureDetector(
      onTap: () {
        // 点击后进入统计界面
        setState(() {
          _showingIntimacy = false;
          _showingStats = true;
        });
        _shakeController.repeat(reverse: true);
        HapticFeedback.lightImpact();
      },
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 暗示性的图标
            Icon(
              Icons.favorite,
              size: 60,
              color: Colors.pinkAccent.withOpacity(0.6),
            ),
            
            const SizedBox(height: 30),
            
            // 主文字
            Text(
              '你与${widget.defeatedAI.name}独处了',
              style: TextStyle(
                fontSize: 22,
                color: Colors.white.withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 10),
            
            // 时间显示
            Text(
              '$_intimacyMinutes 分钟',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent.withOpacity(0.9),
                shadows: [
                  Shadow(
                    blurRadius: 20,
                    color: Colors.pinkAccent.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 亲密度增加
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '亲密度 ',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  '+$_intimacyMinutes',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 60),
            
            // 提示文字
            Text(
              '( 点击屏幕继续 )',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.4),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建视频视图
  Widget _buildVideoView() {
    if (!_videoInitialized || _videoController == null) {
      // 加载中或失败时显示头像和动画
      return ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI头像（醉酒状态）
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  children: [
                    // 头像
                    Image.asset(
                      '${widget.defeatedAI.avatarPath}avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey,
                          child: const Icon(
                            Icons.person,
                            size: 100,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    
                    // 醉酒滤镜
                    Container(
                      color: Colors.red.withOpacity(0.3),
                    ),
                    
                    // 醉酒表情
                    const Center(
                      child: Text(
                        '😵‍💫',
                        style: TextStyle(fontSize: 80),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 醉酒动画文字
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _shakeAnimation.value,
                  child: const Text(
                    '晕头转向...',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }
    
    // 播放视频
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }
  
  /// 构建统计视图
  Widget _buildStatsView() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 成就标题
            const Text(
              '🎉 成就达成！',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 统计数据
            _buildStatRow('醉倒对手', '${widget.defeatedAI.name}', Colors.red),
            _buildStatRow('总计喝酒', '${widget.drinkingState.getAIDrinks(widget.defeatedAI.id)}杯', Colors.orange),
            _buildStatRow('战斗回合', '多轮激战', Colors.blue),
            _buildStatRow('获得奖励', '+100 金币', Colors.amber),
            
            const SizedBox(height: 20),
            
            // 成就徽章
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAchievementBadge('🍺', '酒神'),
                _buildAchievementBadge('💪', '不败'),
                _buildAchievementBadge('🎯', '精准'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建统计行
  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建成就徽章
  Widget _buildAchievementBadge(String icon, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建底部按钮
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 分享按钮
          if (widget.onShare != null)
            _buildActionButton(
              icon: Icons.share,
              label: '炫耀',
              color: Colors.blue,
              onTap: widget.onShare!,
            ),
          
          // 再战按钮
          if (widget.onRematch != null)
            _buildActionButton(
              icon: Icons.replay,
              label: '再战',
              color: Colors.green,
              onTap: widget.onRematch!,
            ),
          
          // 继续按钮
          _buildActionButton(
            icon: Icons.arrow_forward,
            label: '继续',
            color: Colors.amber,
            onTap: widget.onComplete,
            isPrimary: true,
          ),
        ],
      ),
    );
  }
  
  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isPrimary ? _scaleAnimation.value : 1.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isPrimary ? 30 : 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPrimary
                        ? [color, color.withOpacity(0.8)]
                        : [Colors.transparent, Colors.transparent],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                  boxShadow: isPrimary
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: isPrimary ? Colors.white : color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: isPrimary ? Colors.white : color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
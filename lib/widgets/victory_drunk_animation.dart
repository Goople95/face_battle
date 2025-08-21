/// 胜利醉倒动画组件
/// 
/// 当NPC被喝醉时展示的胜利动画和成就感增强界面
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:math' as math;
import '../models/ai_personality.dart';
import '../models/drinking_state.dart';
import '../services/intimacy_service.dart';
import '../utils/logger_utils.dart';

/// 醉倒胜利动画
class VictoryDrunkAnimation extends StatefulWidget {
  final AIPersonality defeatedAI;
  final DrinkingState drinkingState;
  final VoidCallback onComplete;
  final Function(int intimacyMinutes)? onShare;
  final VoidCallback? onRematch;
  
  const VictoryDrunkAnimation({
    super.key,
    required this.defeatedAI,
    required this.drinkingState,
    required this.onComplete,
    this.onShare,
    this.onRematch,
  });
  
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
  late AnimationController _pulseController;
  
  // 动画
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _shakeAnimation;
  
  // 状态
  bool _videoInitialized = false;
  bool _showingStats = false;
  bool _showingIntimacy = false;  // 显示亲密度场景
  // final int _totalWins = 0; // reserved for future stats
  // final int _consecutiveWins = 0; // reserved for future stats
  int _intimacyMinutes = 0;  // 独处时间
  bool _hasLeveledUp = false;  // 是否升级
  
  // 亲密度动画
  late AnimationController _intimacyCountController;
  late Animation<int> _intimacyCountAnimation;
  int _displayedIntimacy = 0;
  
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
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _intimacyCountController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
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
    
    // 初始化视频
    _initializeVideo();
    
    // 视频播放5秒后显示亲密度界面
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        // 生成20-60之间的随机数
        _intimacyMinutes = 20 + math.Random().nextInt(41);
        // 记录NPC醉倒，增加亲密度并检测升级
        IntimacyService().recordNPCDrunk(widget.defeatedAI.id, _intimacyMinutes).then((leveledUp) {
          if (leveledUp && mounted) {
            setState(() {
              _hasLeveledUp = true;
            });
          }
        });
        // 淡出当前场景
        _fadeController.reverse().then((_) {
          setState(() {
            _showingIntimacy = true;
          });
          // 淡入亲密度场景
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _fadeController.forward();
            }
          });
        });
      }
    });
    
    // 启动动画序列
    _startAnimationSequence();
  }
  
  /// 初始化视频
  Future<void> _initializeVideo() async {
    // 如果已经在初始化，避免重复
    if (_videoController != null) {
      LoggerUtils.debug('视频控制器已存在，跳过初始化');
      return;
    }
    
    // 醉倒视频路径
    String videoPath = 'assets/people/${widget.defeatedAI.id}/videos/drunk.mp4';
    
    LoggerUtils.debug('加载醉倒视频: $videoPath');
    
    // 创建视频控制器
    _videoController = VideoPlayerController.asset(videoPath);
    
    await _videoController!.initialize();
    
    LoggerUtils.debug('视频加载成功: ${_videoController!.value.size}');
    
    // 只有在组件仍然挂载时才更新状态
    if (mounted) {
      setState(() {
        _videoInitialized = true;
      });
      
      // 播放视频
      _videoController!.setLooping(false);
      _videoController!.play();
    }
      
      // 视频播放完毕后显示亲密度场景
      void videoListener() {
        if (_videoController!.value.position >= _videoController!.value.duration &&
            _videoController!.value.duration > Duration.zero) {
          if (!_showingIntimacy && !_showingStats) {
            // 移除监听器避免重复触发
            _videoController!.removeListener(videoListener);
            
            // 停止脉冲动画，减少rebuild
            _pulseController.stop();
            
            // 生成20-60之间的随机数
            _intimacyMinutes = 20 + math.Random().nextInt(41);
            // 记录NPC醉倒，增加亲密度并检测升级
            IntimacyService().recordNPCDrunk(widget.defeatedAI.id, _intimacyMinutes).then((leveledUp) {
              if (leveledUp && mounted) {
                setState(() {
                  _hasLeveledUp = true;
                });
              }
            });
            
            // 淡出视频场景
            _fadeController.reverse().then((_) {
              setState(() {
                _showingIntimacy = true;
              });
              // 淡入亲密度场景
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _fadeController.forward();
                }
              });
            });
          }
        }
      }
      _videoController!.addListener(videoListener);
      
  }
  
  /// 启动动画序列
  void _startAnimationSequence() async {
    // 淡入
    _fadeController.forward();
    
    // 启动脉冲动画（只在视频播放时）
    if (!_showingIntimacy && !_showingStats) {
      _pulseController.repeat(reverse: true);
    }
    
    // 延迟启动其他动画
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _slideController.forward();
    
    // 轻柔的震动反馈
    HapticFeedback.lightImpact();
  }
  
  @override
  void dispose() {
    // 先暂停视频，避免在释放时继续播放
    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.dispose();
    }
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    _intimacyCountController.dispose();
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
                        Colors.black.withValues(alpha: 0.95),
                        Colors.black,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.red.shade900.withValues(alpha: 0.5),
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
                                '🌙 夜深了...',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFF8BBD0),  // 粉色
                                  shadows: [
                                    Shadow(
                                      blurRadius: 15,
                                      color: Color(0x66E91E63),  // 暗粉色阴影
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 10),
                            
                            // 副标题
                            Text(
                              '${widget.defeatedAI.name} 醉了',
                              style: TextStyle(
                                fontSize: 20,
                                color: Color(0xFFF8BBD0).withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
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
                  
                  // 底部按钮（只在统计场景显示）
                  if (_showingStats)
                    _buildBottomButtons(),
                ],
              ),
            ),
          ),
          
          // 浮动的粉色光晕效果（简化版，减少rebuild）
          if (!_showingIntimacy && !_showingStats && _videoInitialized)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        Colors.transparent,
                        Color(0x1AE91E63).withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
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
        
        // 启动亲密度增长动画
        _intimacyCountAnimation = IntTween(
          begin: 0,
          end: _intimacyMinutes,
        ).animate(CurvedAnimation(
          parent: _intimacyCountController,
          curve: Curves.easeOutCubic,
        ));
        
        _intimacyCountAnimation.addListener(() {
          if (mounted) {
            setState(() {
              _displayedIntimacy = _intimacyCountAnimation.value;
            });
          }
        });
        
        _intimacyCountController.forward();
        _shakeController.repeat(reverse: true);
        HapticFeedback.lightImpact();
      },
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 背景渐变效果（静态版本，减少rebuild）
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 2.0,
                  colors: [
                    Colors.transparent,
                    Color(0xFF4A148C).withValues(alpha: 0.15),
                    Color(0xFFE91E63).withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
            
            // 主要内容
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 时间流逝提示（更暧昧的表达）
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Column(
                          children: [
                            // 省略号动画
                            Text(
                              '• • •',
                              style: TextStyle(
                                fontSize: 40,
                                color: Colors.white.withValues(alpha: 0.3 + 0.3 * _scaleAnimation.value),
                                letterSpacing: 20,
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // 暧昧的文字描述
                            Text(
                              '时间悄然流逝',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white.withValues(alpha: 0.5),
                                letterSpacing: 3,
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            
                            // 神秘的中心文字
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color(0xFFE91E63).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                '${widget.defeatedAI.name}与你...',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // 隐晦的亲密度提示
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_outline,
                                  size: 20,
                                  color: Color(0xFFE91E63).withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '关系更近了一步',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFE91E63).withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // 模糊的继续提示
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.3 + 0.2 * _pulseController.value,
                        child: Text(
                          '轻触继续',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                            letterSpacing: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建视频视图
  Widget _buildVideoView() {
    if (!_videoInitialized || _videoController == null || !_videoController!.value.isInitialized) {
      // 加载中显示空容器
      return Container();
    }
    
    // 播放视频 - 使用AspectRatio确保正确的宽高比
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 根据视频宽高比计算高度，添加安全检查
    final videoAspectRatio = _videoController!.value.isInitialized && 
                              _videoController!.value.aspectRatio > 0
        ? _videoController!.value.aspectRatio 
        : 16/9;
    
    // 添加错误处理
    try {
      return Container(
        constraints: BoxConstraints(
          maxWidth: screenWidth,
          maxHeight: screenHeight * 0.7, // 限制最大高度
        ),
        child: AspectRatio(
          aspectRatio: videoAspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    } catch (e) {
      LoggerUtils.error('视频播放出错: $e');
      // 如果播放出错，返回空容器
      return Container();
    }
  }
  
  /// 构建统计视图 - 简化为3行内容
  Widget _buildStatsView() {
    // 获取当前亲密度信息
    final intimacyService = IntimacyService();
    final currentIntimacy = intimacyService.getIntimacy(widget.defeatedAI.id);
    
    // 计算动画中的亲密度值（已经包含了增加的值）
    final animatedIntimacyPoints = currentIntimacy.intimacyPoints;
    final currentLevel = currentIntimacy.intimacyLevel;
    final progress = currentIntimacy.levelProgress;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        decoration: BoxDecoration(
          color: Color(0xFF1a0a14).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Color(0xFFE91E63).withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 如果升级了，显示恭喜信息
            if (_hasLeveledUp) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0.3),
                      Colors.orange.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.celebration,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '恭喜！亲密度升级了！',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // 第一行：独处时间和亲密度增加
            Text(
              '你们独处了${_intimacyMinutes}分钟',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
            AnimatedBuilder(
              animation: _intimacyCountController,
              builder: (context, child) {
                return Column(
                  children: [
                    Text(
                      '亲密度增加了 +$_displayedIntimacy',
                      style: TextStyle(
                        fontSize: 22,
                        color: Color(0xFFE91E63),
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                    // 显示增长进度的小提示
                    if (_displayedIntimacy < _intimacyMinutes)
                      Text(
                        '增长中...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE91E63).withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            // 第二行：进度条（带动画）
            AnimatedBuilder(
              animation: _intimacyCountController,
              builder: (context, child) {
                return Column(
                  children: [
                    // 进度条标签
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lv.$currentLevel',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFE91E63),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currentLevel < 10 
                            ? '${_getCurrentLevelProgress(animatedIntimacyPoints, currentLevel)} / ${_getLevelRange(currentLevel)}'
                            : 'MAX',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 进度条
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFE91E63),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            // 第三行：升级提示文案
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 18,
                    color: Colors.amber.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentLevel < 5 
                      ? '升级就可以知道更多她的小秘密'
                      : '你已经了解她的所有秘密',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.amber.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
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
              color: Colors.white.withValues(alpha: 0.8),
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
                  color: Colors.amber.withValues(alpha: 0.5),
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
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建底部按钮 - 简化为炫耀和继续
  Widget _buildBottomButtons() {
    // 统计场景显示简化的按钮
    if (_showingStats) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Row(
          children: [
            // 炫耀按钮
            Expanded(
              child: _buildSimpleButton(
                label: '炫耀',
                color: Color(0xFFE91E63),
                onTap: () {
                  if (widget.onShare != null) {
                    widget.onShare!(_intimacyMinutes);
                  }
                },
                icon: Icons.share,
              ),
            ),
            const SizedBox(width: 20),
            // 继续按钮（返回主页）
            Expanded(
              child: _buildSimpleButton(
                label: '继续',
                color: Colors.white,
                textColor: Colors.black87,
                onTap: widget.onComplete,
                icon: Icons.home,
              ),
            ),
          ],
        ),
      );
    }
    
    // 其他场景的按钮（保持原样）
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (widget.onRematch != null)
            _buildActionButton(
              icon: Icons.replay,
              label: '再战',
              color: Colors.green,
              onTap: widget.onRematch!,
            ),
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
  
  /// 获取亲密度等级
  int _getIntimacyLevel(int intimacy) {
    if (intimacy >= 100) return 5;
    if (intimacy >= 60) return 4;
    if (intimacy >= 30) return 3;
    if (intimacy >= 10) return 2;
    if (intimacy >= 5) return 1;
    return 0;
  }
  
  /// 获取下一级所需的亲密度阈值
  int _getNextLevelThreshold(int currentLevel) {
    // 根据IntimacyData模型的等级系统
    final thresholds = [100, 300, 600, 1000, 1500, 2100, 2800, 3600, 4500, 999999];
    if (currentLevel <= 0) return thresholds[0];
    if (currentLevel > 10) return thresholds[9];
    return thresholds[currentLevel - 1];
  }
  
  /// 获取当前等级的进度（相对于当前等级的起点）
  int _getCurrentLevelProgress(int totalPoints, int level) {
    if (level == 1) return totalPoints;
    final prevThreshold = _getPreviousLevelThreshold(level);
    return totalPoints - prevThreshold;
  }
  
  /// 获取当前等级的范围（从起点到终点的距离）
  int _getLevelRange(int level) {
    final prevThreshold = _getPreviousLevelThreshold(level);
    final nextThreshold = _getNextLevelThreshold(level);
    return nextThreshold - prevThreshold;
  }
  
  /// 获取上一级的阈值
  int _getPreviousLevelThreshold(int currentLevel) {
    final thresholds = [0, 100, 300, 600, 1000, 1500, 2100, 2800, 3600, 4500];
    if (currentLevel <= 1) return 0;
    if (currentLevel > 10) return thresholds[9];
    return thresholds[currentLevel - 1];
  }
  
  /// 计算当前等级的进度
  double _calculateProgress(int currentIntimacy, int currentLevel) {
    final nextThreshold = _getNextLevelThreshold(currentLevel);
    final prevThreshold = currentLevel == 0 ? 0 : _getNextLevelThreshold(currentLevel - 1);
    
    if (currentLevel >= 5) return 1.0;
    
    final levelRange = nextThreshold - prevThreshold;
    final currentProgress = currentIntimacy - prevThreshold;
    
    return (currentProgress / levelRange).clamp(0.0, 1.0);
  }
  
  /// 获取亲密度等级名称
  String _getIntimacyLevelName(int level) {
    switch (level) {
      case 0: return '陌生人';
      case 1: return '初识';
      case 2: return '朋友';
      case 3: return '好友';
      case 4: return '密友';
      case 5: return '知己';
      default: return '陌生人';
    }
  }
  
  /// 获取下一级奖励描述
  String _getNextLevelReward(int currentLevel) {
    switch (currentLevel) {
      case 0: return '了解她的基本信息';
      case 1: return '知道她的兴趣爱好';
      case 2: return '解锁私人故事';
      case 3: return '了解她的小秘密';
      case 4: return '成为她的特别存在';
      case 5: return '已达最高等级';
      default: return '继续加深了解';
    }
  }
  
  /// 构建简单按钮（用于统计界面）
  Widget _buildSimpleButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    required IconData icon,
    Color? textColor,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: textColor ?? Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? Colors.white,
                ),
              ),
            ],
          ),
        ),
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
                        ? [color, color.withValues(alpha: 0.8)]
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
                            color: color.withValues(alpha: 0.3),
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
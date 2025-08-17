import 'package:flutter/material.dart';
import 'dart:async';
import '../config/character_assets.dart';

/// 支持透明 PNG 序列帧的 AI 头像组件
/// 使用带 alpha 通道的 PNG 图片实现透明效果
class AITransparentAvatar extends StatefulWidget {
  final String characterId;
  final String emotion;
  final double size;
  final int fps;
  final Color? backgroundColor;  // 可选背景色
  final Gradient? backgroundGradient;  // 可选渐变背景
  final bool showGlow;  // 是否显示发光效果
  
  const AITransparentAvatar({
    Key? key,
    required this.characterId,
    this.emotion = 'excited',
    this.size = 120,
    this.fps = 24,
    this.backgroundColor,
    this.backgroundGradient,
    this.showGlow = true,
  }) : super(key: key);
  
  @override
  State<AITransparentAvatar> createState() => _AITransparentAvatarState();
}

class _AITransparentAvatarState extends State<AITransparentAvatar> 
    with SingleTickerProviderStateMixin {
  List<Image> _frames = [];
  int _currentFrame = 0;
  Timer? _frameTimer;
  bool _isLoading = true;
  String? _currentEmotion;
  late AnimationController _glowController;
  
  // 缓存已加载的透明帧序列
  static final Map<String, List<Image>> _frameCache = {};
  static const int _maxCacheSize = 3;
  
  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _loadTransparentFrames(widget.emotion);
  }
  
  @override
  void didUpdateWidget(AITransparentAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotion != widget.emotion || 
        oldWidget.characterId != widget.characterId) {
      _loadTransparentFrames(widget.emotion);
    }
  }
  
  Future<void> _loadTransparentFrames(String emotion) async {
    if (_currentEmotion == emotion && _frames.isNotEmpty) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    String cacheKey = '${widget.characterId}_$emotion';
    
    // 检查缓存
    if (_frameCache.containsKey(cacheKey)) {
      setState(() {
        _frames = _frameCache[cacheKey]!;
        _currentEmotion = emotion;
        _isLoading = false;
      });
      _startAnimation();
      return;
    }
    
    // 加载透明 PNG 序列
    List<Image> frames = [];
    int frameCount = 30;  // 假设每个表情30帧
    
    for (int i = 1; i <= frameCount; i++) {
      // 使用统一的CharacterAssets获取透明图片路径
      String framePath = CharacterAssets.getTransparentPath(widget.characterId, emotion, i);
      
      try {
        final image = Image.asset(
          framePath,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,  // 使用 contain 保持透明区域
        );
        
        await precacheImage(AssetImage(framePath), context);
        frames.add(image);
      } catch (e) {
        print('⚠️ 透明帧不存在: $framePath');
      }
    }
    
    // 如果没有透明序列，尝试加载普通头像
    if (frames.isEmpty) {
      String staticPath = CharacterAssets.getAvatarPath(widget.characterId);
      try {
        final image = Image.asset(
          staticPath,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
        );
        await precacheImage(AssetImage(staticPath), context);
        frames.add(image);
      } catch (e) {
        // 使用默认占位符
        print('⚠️ 没有找到透明图片');
      }
    }
    
    // 管理缓存
    if (_frameCache.length >= _maxCacheSize) {
      String? oldestKey = _frameCache.keys.first;
      _frameCache.remove(oldestKey);
    }
    
    if (frames.isNotEmpty) {
      _frameCache[cacheKey] = frames;
    }
    
    if (mounted) {
      setState(() {
        _frames = frames;
        _currentEmotion = emotion;
        _isLoading = false;
      });
      _startAnimation();
    }
  }
  
  void _startAnimation() {
    _frameTimer?.cancel();
    
    if (_frames.isEmpty) return;
    
    int frameInterval = (1000 / widget.fps).round();
    
    _frameTimer = Timer.periodic(Duration(milliseconds: frameInterval), (timer) {
      if (mounted && _frames.isNotEmpty) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % _frames.length;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _frameTimer?.cancel();
    _glowController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    Widget avatar;
    
    if (_isLoading) {
      avatar = Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
        ),
      );
    } else if (_frames.isNotEmpty) {
      // 显示透明 PNG 动画
      avatar = _frames[_currentFrame];
    } else {
      // 默认占位符
      avatar = Icon(
        Icons.person,
        size: widget.size * 0.6,
        color: Colors.white54,
      );
    }
    
    // 构建带背景的容器
    Widget content = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        // 背景（渐变或纯色）
        gradient: widget.backgroundGradient,
        color: widget.backgroundGradient == null 
            ? (widget.backgroundColor ?? Colors.transparent)
            : null,
        shape: BoxShape.circle,
      ),
      child: avatar,
    );
    
    // 添加发光效果
    if (widget.showGlow && !_isLoading) {
      return AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (widget.backgroundColor ?? Colors.blue)
                      .withOpacity(0.3 + _glowController.value * 0.3),
                  blurRadius: 20 + _glowController.value * 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: content,
          );
        },
      );
    }
    
    return content;
  }
}

/// 使用示例组件
class TransparentAvatarExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 渐变背景示例
            AITransparentAvatar(
              characterId: 'youngwoman',
              emotion: 'happy',
              size: 150,
              backgroundGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade400,
                  Colors.pink.shade400,
                ],
              ),
              showGlow: true,
            ),
            
            SizedBox(height: 20),
            
            // 纯色背景示例
            AITransparentAvatar(
              characterId: 'youngwoman',
              emotion: 'thinking',
              size: 150,
              backgroundColor: Colors.blue.shade700,
              showGlow: true,
            ),
            
            SizedBox(height: 20),
            
            // 无背景示例（完全透明）
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                // 棋盘格背景，展示透明效果
                image: DecorationImage(
                  image: AssetImage('assets/checkerboard.png'),
                  repeat: ImageRepeat.repeat,
                ),
              ),
              child: AITransparentAvatar(
                characterId: 'youngwoman',
                emotion: 'excited',
                size: 150,
                showGlow: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
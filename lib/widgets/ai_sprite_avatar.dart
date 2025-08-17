import 'package:flutter/material.dart';
import 'dart:async';
import '../config/character_assets.dart';

/// 基于图片序列帧的 AI 头像组件
/// 比视频播放器内存占用更少，性能更好
class AISpriteAvatar extends StatefulWidget {
  final String characterId;  // 角色ID
  final String emotion;      // 表情名称
  final double size;         // 头像大小
  final int fps;            // 帧率
  final bool showBorder;    // 是否显示边框
  
  const AISpriteAvatar({
    Key? key,
    required this.characterId,
    this.emotion = 'excited',
    this.size = 100,
    this.fps = 24,  // 默认24帧
    this.showBorder = true,
  }) : super(key: key);
  
  @override
  State<AISpriteAvatar> createState() => _AISpriteAvatarState();
}

class _AISpriteAvatarState extends State<AISpriteAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<Image> _frames = [];
  int _currentFrame = 0;
  Timer? _frameTimer;
  bool _isLoading = true;
  String? _currentEmotion;
  
  // 缓存已加载的帧序列
  static final Map<String, List<Image>> _frameCache = {};
  static const int _maxCacheSize = 3;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _loadFrames(widget.emotion);
  }
  
  @override
  void didUpdateWidget(AISpriteAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotion != widget.emotion || oldWidget.characterId != widget.characterId) {
      _loadFrames(widget.emotion);
    }
  }
  
  Future<void> _loadFrames(String emotion) async {
    // 如果是相同的表情，跳过
    if (_currentEmotion == emotion && _frames.isNotEmpty) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    String normalizedId = CharacterAssets.getNormalizedId(widget.characterId);
    String cacheKey = '${normalizedId}_$emotion';
    
    // 检查缓存
    if (_frameCache.containsKey(cacheKey)) {
      print('🎞️ [AISpriteAvatar] 从缓存加载帧序列: $cacheKey');
      setState(() {
        _frames = _frameCache[cacheKey]!;
        _currentEmotion = emotion;
        _isLoading = false;
      });
      _startAnimation();
      return;
    }
    
    // 加载新的帧序列
    List<Image> frames = [];
    
    // 假设每个表情有30帧，命名为 emotion_001.png 到 emotion_030.png
    // 实际使用时需要根据你的资源调整
    int frameCount = 30;
    
    for (int i = 1; i <= frameCount; i++) {
      String framePath = CharacterAssets.getSpritePath(widget.characterId, emotion, i);
      
      // 预加载图片
      try {
        final image = Image.asset(
          framePath,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        );
        
        // 预缓存图片
        await precacheImage(AssetImage(framePath), context);
        frames.add(image);
      } catch (e) {
        // 如果某一帧不存在，可以跳过或使用默认图片
        print('⚠️ [AISpriteAvatar] 帧文件不存在: $framePath');
      }
    }
    
    if (frames.isEmpty) {
      // 如果没有帧序列，回退到静态图片
      String staticImagePath = CharacterAssets.getAvatarPath(widget.characterId);
      
      frames.add(Image.asset(
        staticImagePath,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
      ));
    }
    
    // 管理缓存大小
    if (_frameCache.length >= _maxCacheSize) {
      String? oldestKey = _frameCache.keys.first;
      _frameCache.remove(oldestKey);
      print('🎞️ [AISpriteAvatar] 清理缓存: $oldestKey');
    }
    
    // 添加到缓存
    _frameCache[cacheKey] = frames;
    
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
    
    // 计算帧间隔时间（毫秒）
    int frameInterval = (1000 / widget.fps).round();
    
    _frameTimer = Timer.periodic(Duration(milliseconds: frameInterval), (timer) {
      if (mounted && _frames.isNotEmpty) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % _frames.length;
        });
      }
    });
  }
  
  void _stopAnimation() {
    _frameTimer?.cancel();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _frameTimer?.cancel();
    super.dispose();
  }
  
  Widget _buildFallbackImage() {
    String imagePath = CharacterAssets.getAvatarPath(widget.characterId);
    
    return ClipOval(
      child: Image.asset(
        imagePath,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: widget.size * 0.6,
              color: Colors.white54,
            ),
          );
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    Widget content;
    
    if (_isLoading) {
      // 加载中
      content = Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
          ),
        ),
      );
    } else if (_frames.isNotEmpty) {
      // 显示帧动画
      content = ClipOval(
        child: Container(
          width: widget.size,
          height: widget.size,
          color: Colors.grey[900],
          child: _frames[_currentFrame],
        ),
      );
    } else {
      // 显示静态图片
      content = _buildFallbackImage();
    }
    
    // 添加边框装饰
    if (widget.showBorder) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: content,
      );
    }
    
    return content;
  }
}

/// 使用 AnimatedContainer 的简单实现
class SimpleSpriteAvatar extends StatefulWidget {
  final List<String> imagePaths;
  final double size;
  final Duration duration;
  
  const SimpleSpriteAvatar({
    Key? key,
    required this.imagePaths,
    this.size = 100,
    this.duration = const Duration(milliseconds: 100),
  }) : super(key: key);
  
  @override
  State<SimpleSpriteAvatar> createState() => _SimpleSpriteAvatarState();
}

class _SimpleSpriteAvatarState extends State<SimpleSpriteAvatar> {
  int _currentIndex = 0;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _startAnimation();
  }
  
  void _startAnimation() {
    _timer = Timer.periodic(widget.duration, (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.imagePaths.length;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: AnimatedSwitcher(
        duration: widget.duration,
        child: Image.asset(
          widget.imagePaths[_currentIndex],
          key: ValueKey<int>(_currentIndex),
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
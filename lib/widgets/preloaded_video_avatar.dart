import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/character_config.dart';
import '../utils/logger_utils.dart';

/// 预加载视频头像组件
/// 初始化时加载所有4个视频，切换时只需pause/play
class PreloadedVideoAvatar extends StatefulWidget {
  final String characterId;
  final String emotion;
  final double size;
  final bool showBorder;

  const PreloadedVideoAvatar({
    super.key,
    required this.characterId,
    this.emotion = 'thinking',
    this.size = 120,
    this.showBorder = true,
  });

  @override
  State<PreloadedVideoAvatar> createState() => _PreloadedVideoAvatarState();
}

class _PreloadedVideoAvatarState extends State<PreloadedVideoAvatar> {
  // 所有4个视频控制器
  final Map<String, VideoPlayerController> _controllers = {};
  
  // 当前活动的表情
  String _currentEmotion = 'thinking';
  
  // 初始化状态
  bool _isInitializing = true;
  int _loadedCount = 0;
  
  @override
  void initState() {
    super.initState();
    _currentEmotion = widget.emotion;
    _preloadAllVideos();
  }
  
  /// 预加载所有4个视频
  Future<void> _preloadAllVideos() async {
    LoggerUtils.info('开始预加载4个视频 - 角色: ${widget.characterId}');
    
    for (String emotion in CharacterConfig.coreEmotions) {
      try {
        final videoPath = CharacterConfig.getVideoPath(widget.characterId, emotion);
        final controller = VideoPlayerController.asset(videoPath);
        
        // 初始化视频
        await controller.initialize();
        await controller.setLooping(true);
        
        // 保存控制器
        _controllers[emotion] = controller;
        _loadedCount++;
        
        LoggerUtils.info('已加载视频 $emotion ($_loadedCount/4)');
        
        // 如果是当前表情，立即播放
        if (emotion == _currentEmotion) {
          await controller.play();
          // 更新UI显示第一个视频
          if (mounted) {
            setState(() {});
          }
        }
      } catch (e) {
        LoggerUtils.error('加载视频失败 $emotion: $e');
      }
    }
    
    // 全部加载完成
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
    
    LoggerUtils.info('视频预加载完成 - 成功: $_loadedCount/4');
  }
  
  @override
  void didUpdateWidget(PreloadedVideoAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 角色改变时需要重新加载
    if (oldWidget.characterId != widget.characterId) {
      _disposeAll();
      _controllers.clear();
      _loadedCount = 0;
      _isInitializing = true;
      _preloadAllVideos();
    } 
    // 表情改变时只需切换
    else if (oldWidget.emotion != widget.emotion) {
      _switchToEmotion(widget.emotion);
    }
  }
  
  /// 切换到指定表情
  void _switchToEmotion(String emotion) {
    // 确保是有效的表情
    if (!CharacterConfig.coreEmotions.contains(emotion)) {
      emotion = 'thinking';
    }
    
    // 如果是相同表情，跳过
    if (emotion == _currentEmotion) return;
    
    LoggerUtils.info('切换表情: $_currentEmotion -> $emotion');
    
    // 暂停当前视频
    _controllers[_currentEmotion]?.pause();
    
    // 播放新视频
    final newController = _controllers[emotion];
    if (newController != null && newController.value.isInitialized) {
      newController.seekTo(Duration.zero);  // 从头开始
      newController.play();
    }
    
    setState(() {
      _currentEmotion = emotion;
    });
  }
  
  /// 释放所有资源
  void _disposeAll() {
    for (var controller in _controllers.values) {
      controller.pause();
      controller.dispose();
    }
  }
  
  @override
  void dispose() {
    _disposeAll();
    _controllers.clear();
    super.dispose();
  }
  
  /// 构建静态图片后备
  Widget _buildFallback() {
    return Image.asset(
      CharacterConfig.getAvatarPath(widget.characterId),
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: widget.size,
          height: widget.size,
          color: Colors.grey[700],
          child: Icon(
            Icons.person,
            size: widget.size * 0.6,
            color: Colors.white54,
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    Widget content;
    
    // 获取当前应该显示的控制器
    final currentController = _controllers[_currentEmotion];
    
    if (currentController != null && currentController.value.isInitialized) {
      // 显示视频
      content = Container(
        width: widget.size,
        height: widget.size,
        color: Colors.black,
        child: ClipRect(
          child: Center(
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: currentController.value.size.width,
                  height: currentController.value.size.height,
                  child: VideoPlayer(currentController),
                ),
              ),
            ),
          ),
        ),
      );
    } else if (_isInitializing && _loadedCount == 0) {
      // 初始加载中
      content = Container(
        width: widget.size,
        height: widget.size,
        color: Colors.grey[800],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
              SizedBox(height: 8),
              Text(
                '加载中...',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // 显示静态图片
      content = _buildFallback();
    }
    
    // 添加边框装饰
    if (widget.showBorder) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.pink.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: content,
        ),
      );
    }
    
    return content;
  }
}
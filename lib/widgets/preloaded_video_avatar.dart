import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _PreloadedVideoAvatarState extends State<PreloadedVideoAvatar> 
    with SingleTickerProviderStateMixin {
  // 所有4个视频控制器
  final Map<String, VideoPlayerController> _controllers = {};
  
  // 当前活动的表情
  String _currentEmotion = 'thinking';
  
  // 过渡动画控制
  String _previousEmotion = 'thinking';  // 记录上一个表情，用于过渡
  
  // 初始化状态
  bool _isInitializing = true;
  int _loadedCount = 0;
  
  @override
  void initState() {
    super.initState();
    _currentEmotion = widget.emotion;
    _preloadAllVideos();
  }
  
  /// 预加载所有4个视频（后台静默加载）
  Future<void> _preloadAllVideos() async {
    LoggerUtils.info('开始后台预加载视频 - 角色: ${widget.characterId}');
    
    // 并行加载所有视频，提高加载速度
    final futures = <Future>[];
    
    for (String emotion in CharacterConfig.coreEmotions) {
      futures.add(_loadSingleVideo(emotion));
    }
    
    // 等待所有视频加载完成
    await Future.wait(futures);
    
    // 全部加载完成
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
    
    LoggerUtils.info('视频预加载完成 - 成功: $_loadedCount/4');
  }
  
  /// 加载单个视频
  Future<void> _loadSingleVideo(String emotion) async {
    try {
      // 先尝试本地资源
      final localPath = CharacterConfig.getVideoPath(widget.characterId, emotion);
      VideoPlayerController? controller;
      
      try {
        // 检查本地资源是否存在
        await rootBundle.load(localPath);
        controller = VideoPlayerController.asset(localPath);
        LoggerUtils.debug('使用本地视频: $localPath');
      } catch (e) {
        // 本地资源不存在，使用网络资源
        final networkUrl = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/'
                          'npcs%2F${widget.characterId}%2F$emotion.mp4?alt=media&token=adacfb99-9f79-4002-9aa3-e3a9a97db26b';
        controller = VideoPlayerController.networkUrl(Uri.parse(networkUrl));
        LoggerUtils.info('使用网络视频: $networkUrl');
      }
      
      // 初始化视频
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);  // 静音播放
      
      // 所有视频都开始播放，保持循环状态
      await controller.play();
      
      // 保存控制器
      _controllers[emotion] = controller;
      _loadedCount++;
      
      LoggerUtils.debug('已加载视频 $emotion ($_loadedCount/4)');
      
      // 如果不是当前表情，暂停播放（但保持播放进度）
      if (emotion != _currentEmotion) {
        await controller.pause();
      } else {
        // 当前表情的视频准备好后立即切换显示
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      LoggerUtils.error('加载视频失败 $emotion: $e');
    }
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
  
  /// 切换到指定表情（带淡入淡出过渡）
  void _switchToEmotion(String emotion) {
    // 确保是有效的表情
    if (!CharacterConfig.coreEmotions.contains(emotion)) {
      emotion = 'thinking';
    }
    
    // 如果是相同表情，跳过
    if (emotion == _currentEmotion) return;
    
    LoggerUtils.info('切换表情: $_currentEmotion -> $emotion');
    
    // 准备新视频
    final newController = _controllers[emotion];
    if (newController != null && newController.value.isInitialized) {
      // 方案：从头开始播放，但通过淡入淡出掩盖跳跃
      // 这样每个表情都是完整的动作循环
      newController.seekTo(Duration.zero);
      newController.play();
    }
    
    // 延迟暂停旧视频，等淡出动画完成
    Future.delayed(Duration(milliseconds: 200), () {
      if (_previousEmotion != _currentEmotion && _controllers.containsKey(_previousEmotion)) {
        _controllers[_previousEmotion]?.pause();
      }
    });
    
    setState(() {
      _previousEmotion = _currentEmotion;
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
  
  
  /// 构建后备图片（支持本地和网络资源）
  Future<Widget> _buildFallbackImage() async {
    try {
      // 先尝试本地资源
      final localPath = CharacterConfig.getAvatarPath(widget.characterId);
      try {
        await rootBundle.load(localPath);
        return Image.asset(
          localPath,
          width: 512,
          height: 512,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        );
      } catch (e) {
        // 本地资源不存在，使用网络资源
        final networkUrl = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/'
                          'npcs%2F${widget.characterId}%2F1.png?alt=media&token=adacfb99-9f79-4002-9aa3-e3a9a97db26b';
        LoggerUtils.info('使用网络图片作为后备: $networkUrl');
        return Image.network(
          networkUrl,
          width: 512,
          height: 512,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        );
      }
    } catch (e) {
      LoggerUtils.error('加载后备图片失败: $e');
      return _buildPlaceholder();
    }
  }
  
  Widget _buildPlaceholder() {
    return Container(
      width: 512,
      height: 512,
      color: Colors.grey[700],
      child: Icon(Icons.person, size: 300, color: Colors.white54),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前应该显示的控制器
    final currentController = _controllers[_currentEmotion];
    
    Widget videoContent;
    if (currentController != null && currentController.value.isInitialized) {
      videoContent = FittedBox(
        key: ValueKey(_currentEmotion),
        fit: BoxFit.fill,
        child: SizedBox(
          width: 512,
          height: 512,
          child: VideoPlayer(currentController),
        ),
      );
    } else {
      // 视频未准备好时显示静态图片
      videoContent = FutureBuilder<Widget>(
        future: _buildFallbackImage(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FittedBox(
              fit: BoxFit.fill,
              child: snapshot.data!,
            );
          }
          return Container(
            width: 512,
            height: 512,
            color: Colors.grey[700],
            child: Icon(Icons.person, size: 300, color: Colors.white54),
          );
        },
      );
    }
    
    // 使用AnimatedSwitcher实现淡入淡出
    final content = AnimatedSwitcher(
      duration: Duration(milliseconds: 200),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: videoContent,
    );
    
    // 添加边框装饰
    if (widget.showBorder) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
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
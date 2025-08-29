import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../config/character_config.dart';
import '../utils/logger_utils.dart';

/// 简单网络视频头像组件 - 只加载当前需要的视频，避免内存问题
class SimpleNetworkVideoAvatar extends StatefulWidget {
  final String characterId;
  final String emotion;
  final double size;
  final bool showBorder;

  const SimpleNetworkVideoAvatar({
    super.key,
    required this.characterId,
    this.emotion = 'thinking',
    this.size = 120,
    this.showBorder = true,
  });

  @override
  State<SimpleNetworkVideoAvatar> createState() => _SimpleNetworkVideoAvatarState();
}

class _SimpleNetworkVideoAvatarState extends State<SimpleNetworkVideoAvatar> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String _currentEmotion = 'thinking';
  bool _isDisposing = false;  // 防止dispose期间加载新视频
  DateTime _lastLoadTime = DateTime.now();  // 记录上次加载时间
  static final Map<String, DateTime> _globalLastLoadTime = {};  // 全局防抖
  static VideoPlayerController? _globalController;  // 全局唯一控制器
  static String? _globalControllerKey;  // 当前控制器的视频key
  static int _loadFailures = 0;  // 记录加载失败次数
  static bool _useStaticOnly = false;  // 强制使用静态图片
  static DateTime? _lastVideoLoadTime;  // 上次视频加载完成时间
  
  @override
  void initState() {
    super.initState();
    _currentEmotion = widget.emotion;
    _loadVideo(widget.emotion);
  }
  
  @override
  void didUpdateWidget(SimpleNetworkVideoAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 表情或角色改变时加载新视频
    if (oldWidget.emotion != widget.emotion || 
        oldWidget.characterId != widget.characterId) {
      _currentEmotion = widget.emotion;
      _loadVideo(widget.emotion);
    }
  }
  
  /// 加载单个视频 - 只保持一个视频在内存中
  Future<void> _loadVideo(String emotion) async {
    // 如果强制使用静态图片模式，直接返回
    if (_useStaticOnly) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    // 如果正在释放中，不加载新视频
    if (_isDisposing) return;
    
    // 全局防抖：避免任何组件3秒内重复加载同一视频
    final videoKey = '${widget.characterId}_$emotion';
    final lastLoad = _globalLastLoadTime[videoKey];
    if (lastLoad != null && DateTime.now().difference(lastLoad).inSeconds < 3) {
      LoggerUtils.debug('防抖：跳过加载 $videoKey');
      return;
    }
    
    // 组件级防抖：避免本组件频繁加载
    if (DateTime.now().difference(_lastLoadTime).inMilliseconds < 500) {
      LoggerUtils.debug('组件防抖：跳过加载');
      return;
    }
    
    // 视频播放时间防护：确保当前视频至少播放5秒后才切换
    if (_lastVideoLoadTime != null) {
      final timeSinceLoad = DateTime.now().difference(_lastVideoLoadTime!);
      if (timeSinceLoad.inSeconds < 5) {
        LoggerUtils.debug('视频播放未满5秒，跳过切换 (已播放${timeSinceLoad.inSeconds}秒)');
        return;
      }
    }
    
    // 如果失败次数过多，切换到静态图片模式
    if (_loadFailures >= 3) {
      LoggerUtils.warning('视频加载失败过多，切换到静态图片模式');
      _useStaticOnly = true;
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    _lastLoadTime = DateTime.now();
    _globalLastLoadTime[videoKey] = DateTime.now();
    
    // 使用全局唯一控制器策略
    
    try {
      // 如果已经有全局控制器且是同一个视频，复用它
      if (_globalController != null && _globalControllerKey == videoKey) {
        setState(() {
          _controller = _globalController;
          _isLoading = false;
        });
        return;
      }
      
      // 释放旧的全局控制器
      if (_globalController != null) {
        final oldController = _globalController;
        _globalController = null;
        _globalControllerKey = null;
        await oldController!.pause();
        await oldController.dispose();
        // 等待一下让系统释放资源
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // 释放本地控制器（如果有）
      if (_controller != null && _controller != _globalController) {
        await _controller!.pause();
        await _controller!.dispose();
        _controller = null;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      // 先尝试本地资源
      final localPath = CharacterConfig.getVideoPath(widget.characterId, emotion);
      VideoPlayerController? newController;
      
      try {
        // 检查本地资源是否存在
        await rootBundle.load(localPath);
        newController = VideoPlayerController.asset(localPath);
        LoggerUtils.debug('使用本地视频: $localPath');
      } catch (e) {
        // 本地资源不存在，使用网络资源
        final networkUrl = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/'
                          'npcs%2F${widget.characterId}%2F$emotion.mp4?alt=media&token=adacfb99-9f79-4002-9aa3-e3a9a97db26b';
        newController = VideoPlayerController.networkUrl(
          Uri.parse(networkUrl),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );
        LoggerUtils.info('使用网络视频: $networkUrl');
      }
      
      // 初始化并播放
      await newController.initialize();
      await newController.setLooping(true);
      await newController.setVolume(0);
      await newController.play();
      
      if (mounted) {
        // 设置为全局控制器
        _globalController = newController;
        _globalControllerKey = videoKey;
        _lastVideoLoadTime = DateTime.now();  // 记录视频加载时间
        
        setState(() {
          _controller = newController;
          _isLoading = false;
        });
      } else {
        // 如果组件已卸载，释放控制器
        await newController.dispose();
      }
    } catch (e) {
      LoggerUtils.error('加载视频失败 $emotion: $e');
      _loadFailures++;
      
      // 如果失败次数达到阈值，切换到静态模式
      if (_loadFailures >= 3) {
        LoggerUtils.warning('切换到静态图片模式');
        _useStaticOnly = true;
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _isDisposing = true;
    // 不释放全局控制器，让其他组件可以复用
    // 只是断开本组件与控制器的连接
    _controller = null;
    super.dispose();
  }
  
  /// 构建后备图片
  Widget _buildFallbackImage() {
    // 直接使用网络图片作为后备
    final networkUrl = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/'
                      'npcs%2F${widget.characterId}%2F1.png?alt=media&token=adacfb99-9f79-4002-9aa3-e3a9a97db26b';
    
    return Image.network(
      networkUrl,
      width: 512,
      height: 512,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 512,
          height: 512,
          color: Colors.grey[700],
          child: Icon(Icons.person, size: 300, color: Colors.white54),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    Widget content;
    
    // 如果强制使用静态模式或控制器未初始化，显示静态图片
    if (_useStaticOnly || _controller == null || !_controller!.value.isInitialized) {
      // 显示后备图片
      content = FittedBox(
        fit: BoxFit.fill,
        child: _buildFallbackImage(),
      );
    } else {
      // 显示视频
      content = FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: 512,
          height: 512,
          child: VideoPlayer(_controller!),
        ),
      );
    }
    
    // 使用ClipRect确保不会超出边界
    final clippedContent = ClipRect(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: content,
      ),
    );
    
    // 添加边框
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
        child: clippedContent,
      );
    }
    
    return clippedContent;
  }
}
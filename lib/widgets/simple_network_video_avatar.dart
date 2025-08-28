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
    // 如果正在释放中，不加载新视频
    if (_isDisposing) return;
    
    try {
      // 先释放旧的控制器
      if (_controller != null) {
        final oldController = _controller;
        _controller = null;
        await oldController!.pause();
        await oldController.dispose();
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
    _controller?.pause();
    _controller?.dispose();
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
    
    if (_controller != null && _controller!.value.isInitialized) {
      // 显示视频
      content = FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: 512,
          height: 512,
          child: VideoPlayer(_controller!),
        ),
      );
    } else {
      // 显示后备图片或加载指示器
      content = FittedBox(
        fit: BoxFit.fill,
        child: _buildFallbackImage(),
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
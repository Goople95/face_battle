import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../utils/logger_utils.dart';
import '../models/ai_personality.dart';
import 'dart:math' as math;

/// 自动轮播视频头像组件 - 视频播放完后自动切换到下一个随机视频
class AutoPlayVideoAvatar extends StatefulWidget {
  final String characterId;
  final double size;
  final bool showBorder;
  final AIPersonality? personality;  // 传入personality以获取videoCount

  const AutoPlayVideoAvatar({
    super.key,
    required this.characterId,
    this.size = 120,
    this.showBorder = true,
    this.personality,
  });

  @override
  State<AutoPlayVideoAvatar> createState() => _AutoPlayVideoAvatarState();
}

class _AutoPlayVideoAvatarState extends State<AutoPlayVideoAvatar> {
  VideoPlayerController? _controller;
  int _currentVideoIndex = 1;
  bool _isInitialized = false;
  final _random = math.Random();
  bool _isLoadingNext = false;  // 防止重复加载
  
  @override
  void initState() {
    super.initState();
    _loadAndPlayVideo();
  }
  
  /// 加载并播放视频
  Future<void> _loadAndPlayVideo() async {
    // 保存旧控制器，等新视频准备好后再释放
    final oldController = _controller;
    
    try {
      // 随机选择视频编号
      final videoCount = widget.personality?.videoCount ?? 4;
      LoggerUtils.info('视频数量配置: videoCount=$videoCount, personality=${widget.personality?.id}');
      _currentVideoIndex = _random.nextInt(videoCount) + 1;
      final fileName = '$_currentVideoIndex.mp4';
      
      // 构建网络视频URL (不需要token，使用公开访问)
      final networkUrl = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/'
                        'npcs%2F${widget.characterId}%2F$fileName?alt=media';
      
      LoggerUtils.info('播放视频: ${widget.characterId}/$fileName (从$videoCount个视频中选择)');
      
      // 创建新控制器
      final newController = VideoPlayerController.networkUrl(
        Uri.parse(networkUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
      
      // 初始化新视频
      await newController.initialize();
      await newController.setVolume(0);
      
      // 添加监听器，视频播放完后自动播放下一个
      _isLoadingNext = false;  // 重置标志位
      newController.addListener(() {
        if (!mounted || _isLoadingNext) return;
        
        final value = newController.value;
        // 确保视频真正播放到结尾（position接近duration）
        if (value.duration > Duration.zero && 
            value.position >= value.duration - const Duration(milliseconds: 100)) {
          // 设置标志位，防止重复触发
          _isLoadingNext = true;
          // 视频播放完成，播放下一个随机视频
          _loadAndPlayVideo();
        }
      });
      
      await newController.play();
      
      // 新视频准备好了，现在可以切换
      _controller = newController;
      
      // 释放旧控制器
      if (oldController != null) {
        await oldController.pause();
        oldController.dispose();
      }
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      LoggerUtils.error('视频加载失败: $e');
      
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  
  /// 构建后备静态图片
  Widget _buildFallbackImage() {
    // 使用静态图片1.jpg作为后备
    final networkUrl = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/'
                      'npcs%2F${widget.characterId}%2F1.jpg?alt=media';
    
    return Image.network(
      networkUrl,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: widget.size * 0.3,
            height: widget.size * 0.3,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.7)),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: widget.size,
          height: widget.size,
          color: Colors.grey[800],
          child: Icon(
            Icons.person,
            size: widget.size * 0.6,
            color: Colors.white30,
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    Widget content;
    
    if (_isInitialized && _controller != null && _controller!.value.isInitialized) {
      // 显示视频
      content = ClipRect(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
      );
    } else {
      // 显示后备图片
      content = _buildFallbackImage();
    }
    
    // 添加边框装饰
    if (widget.showBorder) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
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
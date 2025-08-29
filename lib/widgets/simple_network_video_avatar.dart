import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:math' as math;
import '../utils/logger_utils.dart';
import '../models/ai_personality.dart';

/// 极简网络视频头像组件 - 随机播放数字编号的视频
class SimpleNetworkVideoAvatar extends StatefulWidget {
  final String characterId;
  final String emotion;  // 现在只用于'drunk'，其他情况随机播放
  final double size;
  final bool showBorder;
  final AIPersonality? personality;  // 传入personality以获取videoCount

  const SimpleNetworkVideoAvatar({
    super.key,
    required this.characterId,
    this.emotion = '',
    this.size = 120,
    this.showBorder = true,
    this.personality,
  });

  @override
  State<SimpleNetworkVideoAvatar> createState() => _SimpleNetworkVideoAvatarState();
}

class _SimpleNetworkVideoAvatarState extends State<SimpleNetworkVideoAvatar> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  String _currentVideoFile = '';
  int _currentVideoIndex = 1;
  final _random = math.Random();
  
  @override
  void initState() {
    super.initState();
    _loadRandomVideo();
  }
  
  @override
  void didUpdateWidget(SimpleNetworkVideoAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 如果角色改变或emotion从/到'drunk'改变，重新加载
    if (oldWidget.characterId != widget.characterId ||
        (widget.emotion == 'drunk' && oldWidget.emotion != 'drunk') ||
        (widget.emotion != 'drunk' && oldWidget.emotion == 'drunk')) {
      _loadRandomVideo();
    }
  }
  
  /// 加载并播放随机视频
  Future<void> _loadRandomVideo() async {
    // 决定要加载的文件
    String fileName;
    if (widget.emotion == 'drunk') {
      fileName = 'drunk.mp4';
    } else {
      // 随机选择一个视频编号
      final videoCount = widget.personality?.videoCount ?? 4;
      _currentVideoIndex = _random.nextInt(videoCount) + 1;
      fileName = '$_currentVideoIndex.mp4';
    }
    
    // 避免重复加载同一视频
    if (_currentVideoFile == '${widget.characterId}_$fileName' && _isInitialized) {
      return;
    }
    
    // 释放旧控制器
    if (_controller != null) {
      await _controller!.pause();
      await _controller!.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
    
    try {
      // 构建网络视频URL
      final networkUrl = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/'
                        'npcs%2F${widget.characterId}%2F$fileName?alt=media&token=adacfb99-9f79-4002-9aa3-e3a9a97db26b';
      
      LoggerUtils.info('播放视频: ${widget.characterId}/$fileName');
      
      // 创建新控制器
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(networkUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
      
      // 初始化视频
      await _controller!.initialize();
      await _controller!.setVolume(0);
      
      // 根据视频类型设置播放模式
      if (widget.emotion == 'drunk') {
        // 醉酒视频循环播放
        await _controller!.setLooping(true);
      } else {
        // 普通视频播放完后加载下一个
        _controller!.addListener(() {
          if (!mounted) return;
          
          final value = _controller!.value;
          if (value.position >= value.duration && value.duration > Duration.zero) {
            // 视频播放完成，加载下一个随机视频
            _loadRandomVideo();
          }
        });
      }
      
      await _controller!.play();
      
      _currentVideoFile = '${widget.characterId}_$fileName';
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      LoggerUtils.error('视频加载失败 $fileName: $e');
      // 加载失败时显示静态图片作为后备
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
    // 使用新的命名格式: {npcId}.jpg
    final networkUrl = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/'
                      'npcs%2F${widget.characterId}%2F${widget.characterId}.jpg?alt=media&token=adacfb99-9f79-4002-9aa3-e3a9a97db26b';
    
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
    
    // 根据视频初始化状态选择显示内容
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
    
    // 添加边框装饰（如果需要）
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
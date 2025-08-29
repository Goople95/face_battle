import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../config/character_config.dart';
import '../utils/logger_utils.dart';
import 'dart:math' as math;

/// 自动轮播视频头像组件 - 每个视频播放完后自动切换到下一个随机视频
class AutoPlayVideoAvatar extends StatefulWidget {
  final String characterId;
  final double size;
  final bool showBorder;

  const AutoPlayVideoAvatar({
    super.key,
    required this.characterId,
    this.size = 120,
    this.showBorder = true,
  });

  @override
  State<AutoPlayVideoAvatar> createState() => _AutoPlayVideoAvatarState();
}

class _AutoPlayVideoAvatarState extends State<AutoPlayVideoAvatar> {
  VideoPlayerController? _controller;
  String _currentEmotion = 'thinking';
  bool _isLoading = true;
  final _random = math.Random();
  
  // 4种核心表情
  final List<String> _emotions = ['thinking', 'happy', 'confident', 'suspicious'];
  
  @override
  void initState() {
    super.initState();
    // 随机选择初始表情
    _currentEmotion = _emotions[_random.nextInt(_emotions.length)];
    _loadAndPlayVideo();
  }
  
  /// 加载并播放视频
  Future<void> _loadAndPlayVideo() async {
    try {
      // 先释放旧控制器
      if (_controller != null) {
        await _controller!.pause();
        await _controller!.dispose();
        _controller = null;
      }
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
      });
      
      // 构建视频URL（直接使用网络资源）
      final networkUrl = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/'
                        'npcs%2F${widget.characterId}%2F$_currentEmotion.mp4?alt=media&token=adacfb99-9f79-4002-9aa3-e3a9a97db26b';
      
      LoggerUtils.info('播放视频: $_currentEmotion');
      
      final newController = VideoPlayerController.networkUrl(
        Uri.parse(networkUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
      
      // 初始化
      await newController.initialize();
      await newController.setVolume(0);  // 静音
      
      // 监听视频结束事件
      newController.addListener(() {
        if (newController.value.position >= newController.value.duration && 
            newController.value.duration.inSeconds > 0) {
          // 视频播放结束，切换到下一个随机视频
          _playNextVideo();
        }
      });
      
      if (!mounted) {
        await newController.dispose();
        return;
      }
      
      setState(() {
        _controller = newController;
        _isLoading = false;
      });
      
      // 开始播放
      await _controller!.play();
      
    } catch (e) {
      LoggerUtils.error('加载视频失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // 出错后3秒重试
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _playNextVideo();
        }
      });
    }
  }
  
  /// 播放下一个随机视频
  void _playNextVideo() {
    if (!mounted) return;
    
    // 选择下一个随机表情（避免重复）
    final otherEmotions = _emotions.where((e) => e != _currentEmotion).toList();
    _currentEmotion = otherEmotions[_random.nextInt(otherEmotions.length)];
    
    // 加载新视频
    _loadAndPlayVideo();
  }
  
  @override
  void dispose() {
    _controller?.removeListener(() {});
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }
  
  /// 构建后备图片
  Widget _buildFallbackImage() {
    final networkUrl = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/'
                      'npcs%2F${widget.characterId}%2F1.png?alt=media&token=adacfb99-9f79-4002-9aa3-e3a9a97db26b';
    
    return Image.network(
      networkUrl,
      width: 512,
      height: 512,
      fit: BoxFit.cover,
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
      // 显示后备图片
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
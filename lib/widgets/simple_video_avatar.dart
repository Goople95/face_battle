import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/character_assets.dart';

/// 简化版的视频头像组件
/// 一次只播放一个视频，避免资源问题
class SimpleVideoAvatar extends StatefulWidget {
  final String characterId;
  final String emotion;
  final double size;
  final bool showBorder;

  const SimpleVideoAvatar({
    Key? key,
    required this.characterId,
    this.emotion = 'happy',
    this.size = 120,
    this.showBorder = true,
  }) : super(key: key);

  @override
  State<SimpleVideoAvatar> createState() => _SimpleVideoAvatarState();
}

class _SimpleVideoAvatarState extends State<SimpleVideoAvatar> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _currentEmotion;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void didUpdateWidget(SimpleVideoAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有当表情真正改变时才重新加载
    if (oldWidget.emotion != widget.emotion || 
        oldWidget.characterId != widget.characterId) {
      _loadVideo();
    }
  }

  Future<void> _loadVideo() async {
    // 如果是相同的表情，跳过
    if (_currentEmotion == widget.emotion && _controller != null) {
      return;
    }

    // 先释放旧的控制器
    if (_controller != null) {
      await _controller!.pause();
      await _controller!.dispose();
      _controller = null;
    }

    setState(() {
      _isLoading = true;
    });

    // 使用统一的CharacterAssets获取视频路径
    String videoPath = CharacterAssets.getVideoPath(widget.characterId, widget.emotion);
    
    try {
      // 创建新控制器
      final controller = VideoPlayerController.asset(videoPath);
      
      // 初始化
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      
      // 如果组件还在，更新状态
      if (mounted) {
        setState(() {
          _controller = controller;
          _currentEmotion = widget.emotion;
          _isLoading = false;
        });
      } else {
        // 如果组件已卸载，立即释放
        controller.dispose();
      }
    } catch (e) {
      print('❌ 无法加载视频: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildFallback() {
    // 使用统一的CharacterAssets获取头像路径
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
      // 加载中显示静态图片
      content = _buildFallback();
    } else if (_controller != null && _controller!.value.isInitialized) {
      // 显示视频
      content = ClipOval(
        child: Container(
          width: widget.size,
          height: widget.size,
          color: Colors.grey[900],
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
      // 后备图片
      content = _buildFallback();
    }
    
    // 添加边框
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
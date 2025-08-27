import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/character_config.dart';
import '../utils/logger_utils.dart';

/// 简化版的视频头像组件
/// 一次只播放一个视频，避免资源问题
class SimpleVideoAvatar extends StatefulWidget {
  final String characterId;
  final String emotion;
  final double size;
  final bool showBorder;

  const SimpleVideoAvatar({
    super.key,
    required this.characterId,
    this.emotion = 'happy',
    this.size = 120,
    this.showBorder = true,
  });

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
    // 如果是相同的表情且控制器正常，跳过
    if (_currentEmotion == widget.emotion && 
        _controller != null && 
        _controller!.value.isInitialized) {
      return;
    }

    // 保存旧控制器，等新视频加载完成再释放
    final oldController = _controller;
    
    // 不立即设置加载状态，保持旧视频显示

    // 使用简化的CharacterConfig获取视频路径
    String videoPath = CharacterConfig.getVideoPath(widget.characterId, widget.emotion);
    
    try {
      // 创建新控制器
      final controller = VideoPlayerController.asset(videoPath);
      
      // 初始化
      await controller.initialize();
      
      // 只有初始化成功才继续
      if (!controller.value.isInitialized) {
        throw Exception('视频初始化失败');
      }
      
      await controller.setLooping(true);
      await controller.play();
      
      // 如果组件还在，更新状态
      if (mounted) {
        setState(() {
          _controller = controller;
          _currentEmotion = widget.emotion;
          _isLoading = false;
        });
        
        // 新视频加载完成后，释放旧控制器
        if (oldController != null) {
          oldController.pause();
          oldController.dispose();
        }
      } else {
        // 如果组件已卸载，立即释放
        controller.dispose();
      }
    } catch (e) {
      LoggerUtils.error('无法加载视频 $videoPath: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _controller = null;  // 确保控制器为空，显示静态图片
        });
      }
    }
  }

  @override
  void dispose() {
    // 确保先暂停再释放
    if (_controller != null) {
      _controller!.pause();
      _controller!.dispose();
      _controller = null;
    }
    super.dispose();
  }

  Widget _buildFallback() {
    // 使用简化的CharacterConfig获取头像路径
    String imagePath = CharacterConfig.getAvatarPath(widget.characterId);
    
    return Image.asset(
      imagePath,
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
    
    if (_isLoading) {
      // 加载中显示静态图片
      content = _buildFallback();
    } else if (_controller != null && _controller!.value.isInitialized) {
      // 显示视频 - 使用FittedBox确保视频填满容器
      content = Container(
        width: widget.size,
        height: widget.size,
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,  // 使用cover模式确保视频完全覆盖容器
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
    
    // 添加边框 - 移除圆形边框
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
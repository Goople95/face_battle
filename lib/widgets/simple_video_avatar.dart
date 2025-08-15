import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
    this.emotion = 'excited',
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
  
  // 映射表: personality ID -> 文件夹名
  static const Map<String, String> personalityToFolder = {
    'professor': 'man',         // 稳重大叔
    'gambler': 'youngman',       // 冲动小哥
    'provocateur': 'woman',      // 心机御姐
    'youngwoman': 'youngwoman',  // 活泼少女
  };
  
  static const Map<String, String> emotionFileMapping = {
    'thinking': 'thinking',
    'happy': 'happy',
    'confident': 'confident',
    'nervous': 'nervous',
    'angry': 'angry',
    'excited': 'excited',
    'worried': 'worried',
    'surprised': 'suprised',  // 注意拼写
    'disappointed': 'disappointed',
    'suspicious': 'suspicious',
    // 默认映射
    'smirk': 'confident',
    'proud': 'confident',
    'relaxed': 'happy',
    'anxious': 'nervous',
    'cunning': 'suspicious',
    'frustrated': 'angry',
    'determined': 'confident',
    'playful': 'happy',
    'neutral': 'thinking',
    'contemplating': 'thinking',
    // 中文映射
    '思考/沉思': 'thinking',
    '开心/得意': 'happy',
    '兴奋/自信': 'excited',
    '担心/紧张': 'worried',
    '思考': 'thinking',
    '怀疑': 'suspicious',
    '自信': 'confident',
    '紧张': 'nervous',
    '生气': 'angry',
    '兴奋': 'excited',
    '担心': 'worried',
    '惊讶': 'suprised',
    '失望': 'disappointed',
    '得意': 'happy',
    '沉思': 'thinking',
  };

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

    // 构建视频路径
    String fileName = emotionFileMapping[widget.emotion.toLowerCase()] ?? 'excited';
    String folderName = personalityToFolder[widget.characterId] ?? widget.characterId;
    String videoPath = 'assets/people/$folderName/videos/$fileName.mp4';
    
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
    String folderName = personalityToFolder[widget.characterId] ?? widget.characterId;
    String imagePath = 'assets/people/$folderName/$folderName.png';
    
    // woman文件夹已经使用正确的文件名woman.png
    
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
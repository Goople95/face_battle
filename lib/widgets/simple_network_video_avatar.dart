import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:math' as math;
import 'dart:io';
import '../utils/logger_utils.dart';
import '../models/ai_personality.dart';
import '../services/cloud_npc_service.dart';
import 'npc_image_widget.dart';

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
  int _lastVideoIndex = 0;  // 记录上一个视频索引，避免连续重复
  final _random = math.Random();
  bool _isLoadingNext = false;  // 防止重复加载
  
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
    // 如果正在加载，避免重复加载
    if (_isLoadingNext) return;
    
    // 决定要加载的文件
    String fileName;
    if (widget.emotion == 'drunk') {
      fileName = 'drunk.mp4';
    } else {
      // 随机选择一个视频编号，避免连续重复
      final videoCount = widget.personality?.videoCount ?? 4;
      LoggerUtils.info('视频数量配置: videoCount=$videoCount, personality=${widget.personality?.id}');
      
      // 如果只有一个视频，直接用它
      if (videoCount == 1) {
        _currentVideoIndex = 1;
      } else {
        // 避免连续播放同一个视频
        do {
          _currentVideoIndex = _random.nextInt(videoCount) + 1;
        } while (_currentVideoIndex == _lastVideoIndex);
      }
      
      _lastVideoIndex = _currentVideoIndex;
      fileName = '$_currentVideoIndex.mp4';
      LoggerUtils.info('选择视频: $fileName (避免重复上一个: $_lastVideoIndex)');
    }
    
    // 避免重复加载同一视频
    if (_currentVideoFile == '${widget.characterId}_$fileName' && _isInitialized) {
      return;
    }
    
    _isLoadingNext = true;
    
    // 保存旧控制器引用
    final oldController = _controller;
    
    try {
      // 使用智能缓存机制获取视频路径
      final videoPath = await CloudNPCService.getSmartResourcePath(widget.characterId, fileName);
      
      LoggerUtils.info('播放视频: ${widget.characterId}/$fileName');
      
      // 创建新控制器 - 根据路径类型选择合适的控制器
      VideoPlayerController newController;
      if (videoPath.startsWith('http')) {
        // 网络URL
        newController = VideoPlayerController.networkUrl(
          Uri.parse(videoPath),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );
      } else {
        // 本地文件路径
        newController = VideoPlayerController.file(
          File(videoPath),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );
        LoggerUtils.info('使用本地缓存视频: $fileName');
      }
      
      // 初始化新视频
      await newController.initialize();
      await newController.setVolume(0);
      
      // 根据视频类型设置播放模式
      if (widget.emotion == 'drunk') {
        // 醉酒视频循环播放
        await newController.setLooping(true);
      } else {
        // 普通视频播放完后加载下一个
        void videoEndListener() {
          if (!mounted) return;
          
          final value = newController.value;
          // 确保视频真正播放到结尾（position接近duration）
          if (value.duration > Duration.zero && 
              value.position >= value.duration - const Duration(milliseconds: 100)) {
            // 移除监听器避免重复触发
            newController.removeListener(videoEndListener);
            // 视频播放完成，加载下一个随机视频
            _loadRandomVideo();
          }
        }
        
        newController.addListener(videoEndListener);
      }
      
      await newController.play();
      
      // 先释放旧控制器
      if (oldController != null) {
        await oldController.pause();
        await oldController.dispose();
      }
      
      // 再设置新控制器
      _controller = newController;
      _currentVideoFile = '${widget.characterId}_$fileName';
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      LoggerUtils.error('视频加载失败 $fileName: $e');
      
      // 释放失败的控制器
      if (oldController != null && oldController != _controller) {
        await oldController.pause();
        await oldController.dispose();
      }
      
      // 加载失败时显示静态图片作为后备
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    } finally {
      _isLoadingNext = false;
    }
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  
  /// 构建后备静态图片
  Widget _buildFallbackImage() {
    // 使用统一的NPC图片组件
    return NPCImageWidget(
      npcId: widget.characterId,
      fileName: '1.jpg',
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
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
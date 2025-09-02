import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:async';
import '../utils/logger_utils.dart';
import '../models/ai_personality.dart';
import '../services/cloud_npc_service.dart';
import '../services/npc_resource_loader.dart';
import '../services/npc_skin_service.dart';
import '../services/npc_config_service.dart';
import 'npc_image_widget.dart';
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
  int _lastVideoIndex = 0;  // 记录上一个视频索引，避免连续重复
  bool _isInitialized = false;
  final _random = math.Random();
  bool _isLoadingNext = false;  // 防止重复加载
  StreamSubscription<Map<String, int>>? _skinChangeSubscription;
  int? _currentSkinId;
  
  @override
  void initState() {
    super.initState();
    _currentSkinId = NPCSkinService.instance.getSelectedSkinId(widget.characterId);
    _loadAndPlayVideo();
    
    // 监听皮肤变化
    _skinChangeSubscription = NPCSkinService.instance.skinChangesStream.listen((changes) {
      final newSkinId = changes[widget.characterId];
      if (newSkinId != null && newSkinId != _currentSkinId) {
        LoggerUtils.info('AutoPlayVideoAvatar检测到皮肤变化: ${widget.characterId} -> $newSkinId');
        _currentSkinId = newSkinId;
        
        // 立即显示静态图片作为占位
        setState(() {
          _isInitialized = false;
        });
        
        // 重新加载新皮肤的视频
        _loadAndPlayVideo();
      }
    });
  }
  
  /// 加载并播放视频
  Future<void> _loadAndPlayVideo() async {
    // 如果正在加载，避免重复加载
    if (_isLoadingNext) return;
    _isLoadingNext = true;
    
    // 保存旧控制器引用
    final oldController = _controller;
    
    try {
      // 获取当前皮肤的视频数量
      int videoCount = 4; // 默认值
      if (widget.personality != null) {
        // 使用NPCConfigService获取当前皮肤的视频数量
        videoCount = NPCConfigService.instance.getVideoCountForNPC(widget.personality!.id);
      } else if (widget.personality?.videoCount != null) {
        // 如果没有使用新方法，使用personality中的值作为后备
        videoCount = widget.personality!.videoCount;
      }
      
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
      final fileName = '$_currentVideoIndex.mp4';
      LoggerUtils.info('选择视频: $fileName (避免重复上一个: $_lastVideoIndex)');
      
      // 获取当前选择的皮肤ID
      final skinId = NPCSkinService.instance.getSelectedSkinId(widget.characterId);
      
      // 根据personality判断资源类型并获取正确路径
      String videoPath;
      if (widget.personality != null && widget.personality!.avatarPath.startsWith('assets/')) {
        // 本地打包资源，使用NPCResourceLoader
        // avatarPath 类似 "assets/npcs/0001/1/"，视频直接在该目录下
        videoPath = await NPCResourceLoader.getVideoPath(
          widget.characterId,
          widget.personality!.avatarPath,
          _currentVideoIndex,
          skinId: skinId,  // 传递皮肤ID
        );
        LoggerUtils.info('使用本地资源加载器(皮肤$skinId): $videoPath');
      } else {
        // 云端资源，使用智能缓存机制
        videoPath = await CloudNPCService.getSmartResourcePath(
          widget.characterId, 
          fileName,
          skinId: skinId,  // 传递皮肤ID
        );
        LoggerUtils.info('使用云端资源加载器(皮肤$skinId): $videoPath');
      }
      
      LoggerUtils.info('播放视频: ${widget.characterId}/$fileName (从$videoCount个视频中选择)');
      
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
      } else if (videoPath.startsWith('assets/')) {
        // 本地asset资源
        newController = VideoPlayerController.asset(
          videoPath,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );
        LoggerUtils.info('使用本地asset视频: $fileName');
      } else {
        // 本地文件路径（缓存的文件）
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
      
      // 添加监听器，视频播放完后自动播放下一个
      void videoEndListener() {
        if (!mounted) return;
        
        final value = newController.value;
        // 确保视频真正播放到结尾（position接近duration）
        if (value.duration > Duration.zero && 
            value.position >= value.duration - const Duration(milliseconds: 100)) {
          // 移除监听器避免重复触发
          newController.removeListener(videoEndListener);
          // 视频播放完成，播放下一个随机视频
          _loadAndPlayVideo();
        }
      }
      
      newController.addListener(videoEndListener);
      await newController.play();
      
      // 先释放旧控制器
      if (oldController != null) {
        await oldController.pause();
        await oldController.dispose();
      }
      
      // 再设置新控制器
      _controller = newController;
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      LoggerUtils.error('视频加载失败: $e');
      
      // 释放失败的控制器
      if (oldController != null && oldController != _controller) {
        await oldController.pause();
        await oldController.dispose();
      }
      
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
    _skinChangeSubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }
  
  /// 构建后备静态图片
  Widget _buildFallbackImage() {
    // 获取当前选择的皮肤ID
    final skinId = NPCSkinService.instance.getSelectedSkinId(widget.characterId);
    
    // 使用统一的NPC图片组件，包含皮肤ID
    return NPCImageWidget(
      npcId: widget.characterId,
      fileName: '1.jpg',
      skinId: skinId,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
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
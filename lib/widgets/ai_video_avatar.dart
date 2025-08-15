import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

/// AI角色视频播放头像组件
class AIVideoAvatar extends StatefulWidget {
  final String characterId;  // 角色ID (e.g., 'youngwoman', 'man', 'woman', 'youngman')
  final String emotion;      // 表情名称 (e.g., 'thinking', 'happy', 'angry')
  final double size;         // 头像大小
  final bool showBorder;     // 是否显示边框

  const AIVideoAvatar({
    Key? key,
    required this.characterId,
    this.emotion = 'excited',  // 默认播放excited
    this.size = 100,
    this.showBorder = true,
  }) : super(key: key);

  @override
  State<AIVideoAvatar> createState() => _AIVideoAvatarState();
}

class _AIVideoAvatarState extends State<AIVideoAvatar> {
  Map<String, VideoPlayerController> _controllerCache = {};  // 视频控制器缓存
  VideoPlayerController? _currentController;  // 当前活动的控制器
  String? _currentEmotion;
  bool _isInitializing = false;
  bool _hasVideo = false;
  
  // 最大缓存数量 - 减少到1个，避免缓冲区问题
  static const int _maxCacheSize = 1;
  
  // 记录使用频率，用于智能缓存管理
  Map<String, int> _usageCount = {};
  Map<String, DateTime> _lastUsed = {};
  
  // 映射personality ID到文件夹名
  static const Map<String, String> personalityToFolder = {
    'professor': 'man',         // 稳重大叔
    'gambler': 'youngman',       // 冲动小哥
    'provocateur': 'woman',      // 心机御姐
    'youngwoman': 'youngwoman',  // 活泼少女
  };
  
  // 映射表情名称到视频文件名（处理拼写问题）
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
    // 其他表情映射到最接近的视频
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
    '思考/沉思': 'thinking',
    // 中文表情映射
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
    _loadVideo(widget.emotion);
    // 暂时禁用预加载，避免缓冲区溢出问题
    // _preloadCommonEmotions();
  }
  
  // 预加载常用表情以改善响应速度
  Future<void> _preloadCommonEmotions() async {
    // 延迟执行，避免影响初始加载
    await Future.delayed(Duration(milliseconds: 500));
    
    // 最常用的表情列表
    List<String> commonEmotions = ['thinking', 'confident', 'excited'];
    
    for (String emotion in commonEmotions) {
      // 跳过当前正在显示的表情
      if (emotion == widget.emotion) continue;
      
      String fileName = emotionFileMapping[emotion.toLowerCase()] ?? emotion;
      String folderName = personalityToFolder[widget.characterId] ?? widget.characterId;
      String videoPath = 'assets/people/$folderName/videos/$fileName.mp4';
      String cacheKey = '${widget.characterId}_$fileName';
      
      // 如果已经在缓存中，跳过
      if (_controllerCache.containsKey(cacheKey)) continue;
      
      // 如果缓存已满，停止预加载
      if (_controllerCache.length >= _maxCacheSize) break;
      
      try {
        print('🎬 [AIVideoAvatar] 预加载: $emotion');
        final controller = VideoPlayerController.asset(videoPath);
        await controller.initialize();
        await controller.setLooping(true);
        
        // 不自动播放预加载的视频
        if (mounted && _controllerCache.length < _maxCacheSize) {
          _controllerCache[cacheKey] = controller;
          _usageCount[cacheKey] = 0;  // 预加载的初始使用次数为0
          _lastUsed[cacheKey] = DateTime.now();
        } else {
          // 如果组件已卸载或缓存已满，释放控制器
          controller.dispose();
        }
      } catch (e) {
        print('⚠️ [AIVideoAvatar] 预加载失败: $emotion');
      }
    }
  }

  @override
  void didUpdateWidget(AIVideoAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 当表情或角色改变时，加载新视频
    if (oldWidget.emotion != widget.emotion || 
        oldWidget.characterId != widget.characterId) {
      _loadVideo(widget.emotion);
    }
  }

  Future<void> _loadVideo(String emotion) async {
    // 如果正在初始化，等待
    if (_isInitializing) return;
    
    // 如果是相同的表情，不重新加载
    if (_currentEmotion == emotion) {
      print('🎬 [AIVideoAvatar] 相同表情，跳过: $emotion');
      return;
    }
    
    print('🎬 [AIVideoAvatar] 开始加载视频 - characterId: ${widget.characterId}, emotion: $emotion');
    
    setState(() {
      _isInitializing = true;
    });

    // 获取映射后的文件名
    String fileName = emotionFileMapping[emotion.toLowerCase()] ?? 'excited';  // 默认使用excited
    
    // 获取文件夹名
    String folderName = personalityToFolder[widget.characterId] ?? widget.characterId;
    
    // 构建视频路径和缓存键
    String videoPath = 'assets/people/$folderName/videos/$fileName.mp4';
    String cacheKey = '${widget.characterId}_$fileName';
    print('🎬 [AIVideoAvatar] 视频路径: $videoPath, 缓存键: $cacheKey');
    
    try {
      VideoPlayerController? controller;
      
      // 检查缓存中是否已有该视频
      if (_controllerCache.containsKey(cacheKey)) {
        print('🎬 [AIVideoAvatar] 从缓存加载: $cacheKey');
        controller = _controllerCache[cacheKey];
        
        // 更新使用统计
        _usageCount[cacheKey] = (_usageCount[cacheKey] ?? 0) + 1;
        _lastUsed[cacheKey] = DateTime.now();
        
        // 重新播放缓存的视频
        if (controller != null && controller.value.isInitialized) {
          await controller.seekTo(Duration.zero);
          await controller.play();
        }
      } else {
        // 创建新的控制器
        print('🎬 [AIVideoAvatar] 创建新控制器: $cacheKey');
        controller = VideoPlayerController.asset(videoPath);
        
        await controller.initialize();
        await controller.setLooping(true);
        
        // 添加监听器来跟踪播放状态
        controller.addListener(() {
          if (mounted && controller!.value.isInitialized) {
            // 如果视频停止了，重新播放
            if (!controller.value.isPlaying && !controller.value.isBuffering) {
              controller.play();
            }
          }
        });
        
        await controller.play();
        
        // 智能缓存管理 - 使用 LRU 策略
        if (_controllerCache.length >= _maxCacheSize) {
          // 找出最少使用且最久未使用的缓存项
          String? keyToRemove;
          DateTime? oldestTime;
          int lowestUsage = 999999;
          
          for (String key in _controllerCache.keys) {
            // 跳过当前正在使用的
            if (key == cacheKey || _controllerCache[key] == _currentController) {
              continue;
            }
            
            int usage = _usageCount[key] ?? 0;
            DateTime lastUsed = _lastUsed[key] ?? DateTime.now();
            
            // 优先移除使用次数少的，如果次数相同则移除最久未使用的
            if (usage < lowestUsage || 
                (usage == lowestUsage && (oldestTime == null || lastUsed.isBefore(oldestTime)))) {
              keyToRemove = key;
              oldestTime = lastUsed;
              lowestUsage = usage;
            }
          }
          
          if (keyToRemove != null) {
            print('🎬 [AIVideoAvatar] 清理缓存: $keyToRemove (使用次数: $lowestUsage)');
            // 完整的清理流程
            final oldController = _controllerCache[keyToRemove];
            if (oldController != null) {
              await oldController.pause();
              await oldController.seekTo(Duration.zero);
              await oldController.dispose();
            }
            _controllerCache.remove(keyToRemove);
            _usageCount.remove(keyToRemove);
            _lastUsed.remove(keyToRemove);
            
            // 给系统一点时间释放资源
            await Future.delayed(Duration(milliseconds: 100));
          }
        }
        
        // 添加到缓存
        _controllerCache[cacheKey] = controller;
        _usageCount[cacheKey] = 1;  // 初始化使用次数
        _lastUsed[cacheKey] = DateTime.now();
      }
      
      print('🎬 [AIVideoAvatar] 视频加载成功: $videoPath');
      print('🎬 [AIVideoAvatar] 视频尺寸: ${controller?.value.size}');
      print('🎬 [AIVideoAvatar] 初始化后播放状态: ${controller?.value.isPlaying}');
      print('🎬 [AIVideoAvatar] 缓存状态: ${_controllerCache.length}/$_maxCacheSize');
      
      // 暂停之前的控制器（但不释放）
      if (_currentController != null && _currentController != controller) {
        await _currentController!.pause();
      }
      
      if (mounted) {
        setState(() {
          _currentController = controller;
          _currentEmotion = emotion;
          _hasVideo = true;
          _isInitializing = false;
        });
        
        // 确保视频开始播放
        if (_currentController != null && !_currentController!.value.isPlaying) {
          _currentController!.play();
          print('🎬 [AIVideoAvatar] 手动开始播放视频');
        }
      }
    } catch (e) {
      print('❌ [AIVideoAvatar] 无法加载视频 $videoPath: $e');
      // 如果视频不存在，显示静态图片
      if (mounted) {
        setState(() {
          _hasVideo = false;
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // 先暂停所有视频
    for (var controller in _controllerCache.values) {
      controller.pause();
    }
    
    // 然后释放所有缓存的控制器
    for (var controller in _controllerCache.values) {
      controller.dispose();
    }
    _controllerCache.clear();
    _usageCount.clear();
    _lastUsed.clear();
    super.dispose();
  }

  Widget _buildFallbackImage() {
    // 获取文件夹名
    String folderName = personalityToFolder[widget.characterId] ?? widget.characterId;
    
    // 构建静态图片路径
    String imagePath = 'assets/people/$folderName/$folderName.png';
    
    // woman文件夹已经使用正确的文件名woman.png
    
    return ClipOval(
      child: Image.asset(
        imagePath,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // 如果图片也不存在，显示占位符
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
    print('🎬 [AIVideoAvatar] Build - hasVideo: $_hasVideo, initialized: ${_currentController?.value.isInitialized}, emotion: $_currentEmotion');
    
    Widget content;
    
    if (_hasVideo && _currentController != null && _currentController!.value.isInitialized) {
      // 显示视频
      print('🎬 [AIVideoAvatar] 显示视频 - size: ${widget.size}, videoSize: ${_currentController!.value.size}');
      print('🎬 [AIVideoAvatar] 视频正在播放: ${_currentController!.value.isPlaying}');
      // 使用FittedBox让视频填充整个圆形区域
      content = ClipOval(
        child: Container(
          width: widget.size,
          height: widget.size,
          color: Colors.grey[900], // 深灰色背景，便于调试
          child: FittedBox(
            fit: BoxFit.cover,  // 使用cover让人脸填满圆形区域
            child: SizedBox(
              width: _currentController!.value.size.width,
              height: _currentController!.value.size.height,
              child: VideoPlayer(_currentController!),
            ),
          ),
        ),
      );
    } else if (_isInitializing) {
      // 加载中显示进度指示器
      print('🎬 [AIVideoAvatar] 显示加载指示器');
      content = Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
          ),
        ),
      );
    } else {
      // 显示静态图片作为后备
      print('🎬 [AIVideoAvatar] 显示静态图片后备');
      content = _buildFallbackImage();
    }
    
    // 添加边框装饰（如果需要）
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
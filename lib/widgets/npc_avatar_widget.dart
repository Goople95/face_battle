import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/npc_resource_loader.dart';
import '../models/ai_personality.dart';
import '../utils/logger_utils.dart';
import '../config/character_config.dart';

/// NPC头像Widget - 支持本地和云端资源
class NPCAvatarWidget extends StatelessWidget {
  final AIPersonality personality;
  final double size;
  final bool showBorder;
  final bool isUnavailable;
  
  const NPCAvatarWidget({
    super.key,
    required this.personality,
    this.size = 60,
    this.showBorder = true,
    this.isUnavailable = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getAvatarPath(),
      builder: (context, snapshot) {
        Widget imageWidget;
        
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final path = snapshot.data!;
          
          // 判断是本地资源还是云端资源
          if (path.startsWith('assets/')) {
            imageWidget = Image.asset(
              path,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) {
                LoggerUtils.error('加载本地头像失败: $path - $error');
                return _buildPlaceholder();
              },
            );
          } else if (path.startsWith('http')) {
            // 网络图片
            imageWidget = Image.network(
              path,
              width: size,
              height: size,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildLoadingIndicator(loadingProgress);
              },
              errorBuilder: (context, error, stack) {
                // 记录失败的URL，避免下次重复尝试
                _failedUrls.add(path);
                LoggerUtils.error('加载网络头像失败: $path - $error');
                
                // 直接显示占位符，不再尝试其他格式
                return _buildPlaceholder();
              },
            );
          } else {
            // 文件路径
            imageWidget = Image.file(
              File(path),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) {
                LoggerUtils.error('加载文件头像失败: $path - $error');
                return _buildPlaceholder();
              },
            );
          }
        } else if (snapshot.hasError) {
          LoggerUtils.error('获取头像路径失败: ${snapshot.error}');
          imageWidget = _buildPlaceholder();
        } else {
          // 加载中
          imageWidget = _buildLoadingIndicator(null);
        }
        
        // 添加装饰
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: showBorder ? Border.all(
              color: isUnavailable ? Colors.red : Colors.white,
              width: 2,
            ) : null,
          ),
          child: ClipOval(
            child: ColorFiltered(
              colorFilter: isUnavailable 
                ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
              child: imageWidget,
            ),
          ),
        );
      },
    );
  }
  
  // 缓存失败的URL，避免重复请求
  static final Set<String> _failedUrls = {};
  
  Future<String> _getAvatarPath() async {
    try {
      final npcId = personality.id;
      
      // 先检查本地资源是否存在
      if (personality.avatarPath.startsWith('assets/')) {
        final assetPath = CharacterConfig.getFullAvatarPath(personality.avatarPath);
        try {
          // 尝试加载本地资源
          await rootBundle.load(assetPath);
          return assetPath;
        } catch (e) {
          LoggerUtils.info('本地资源不存在，切换到云端资源: $npcId');
        }
      }
      
      // 构建网络URL
      final encodedId = Uri.encodeComponent(npcId);
      
      // 直接使用1.jpg格式
      final jpgUrl = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/'
                     'npcs%2F${encodedId}%2F1.jpg?alt=media';
      
      // 如果.jpg已经失败过，直接返回空
      if (!_failedUrls.contains(jpgUrl)) {
        LoggerUtils.info('加载JPG头像: $jpgUrl');
        return jpgUrl;
      }
      
      // 如果都失败过，返回空字符串显示占位符
      LoggerUtils.warning('NPC头像URL都已失败过: $npcId');
      return '';
      
    } catch (e) {
      LoggerUtils.error('获取NPC头像路径失败: ${personality.id} - $e');
      return '';
    }
  }
  
  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.white54,
      ),
    );
  }
  
  Widget _buildLoadingIndicator(ImageChunkEvent? loadingProgress) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: loadingProgress != null && loadingProgress.expectedTotalBytes != null
          ? CircularProgressIndicator(
              value: loadingProgress.cumulativeBytesLoaded / 
                     loadingProgress.expectedTotalBytes!,
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
      ),
    );
  }
}


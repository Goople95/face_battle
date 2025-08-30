import 'package:flutter/material.dart';
import 'dart:io';
import '../services/cloud_npc_service.dart';
import '../utils/logger_utils.dart';

/// 统一的NPC图片组件 - 自动处理缓存和加载
class NPCImageWidget extends StatelessWidget {
  final String npcId;
  final String fileName;  // 默认 '1.jpg'
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  
  const NPCImageWidget({
    super.key,
    required this.npcId,
    this.fileName = '1.jpg',
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: CloudNPCService.getSmartResourcePath(npcId, fileName),
      builder: (context, snapshot) {
        // 加载中
        if (!snapshot.hasData) {
          return _buildContainer(
            child: placeholder ?? _buildDefaultPlaceholder(),
          );
        }
        
        final imagePath = snapshot.data!;
        
        // 根据路径类型选择合适的Image widget
        Widget imageWidget;
        if (imagePath.startsWith('http')) {
          // 网络图片
          imageWidget = Image.network(
            imagePath,
            width: width,
            height: height,
            fit: fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildContainer(
                child: placeholder ?? _buildDefaultPlaceholder(),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              LoggerUtils.error('NPC图片加载失败: $npcId/$fileName - $error');
              return _buildContainer(
                child: errorWidget ?? _buildDefaultError(),
              );
            },
          );
        } else {
          // 本地缓存图片
          imageWidget = Image.file(
            File(imagePath),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              LoggerUtils.error('NPC本地图片加载失败: $imagePath - $error');
              // 本地文件失败，尝试重新从网络加载
              return _buildNetworkFallback();
            },
          );
        }
        
        // 应用圆角
        if (borderRadius != null) {
          return ClipRRect(
            borderRadius: borderRadius!,
            child: imageWidget,
          );
        }
        
        return imageWidget;
      },
    );
  }
  
  Widget _buildContainer({required Widget child}) {
    return Container(
      width: width,
      height: height,
      child: child,
    );
  }
  
  Widget _buildDefaultPlaceholder() {
    return Center(
      child: SizedBox(
        width: (width ?? 100) * 0.3,
        height: (height ?? 100) * 0.3,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDefaultError() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[800],
      child: Icon(
        Icons.person,
        size: (width ?? height ?? 100) * 0.5,
        color: Colors.white30,
      ),
    );
  }
  
  Widget _buildNetworkFallback() {
    // 本地文件损坏时，直接使用网络URL
    final networkUrl = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/'
                      'npcs%2F$npcId%2F$fileName?alt=media';
    
    return Image.network(
      networkUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return _buildContainer(
          child: errorWidget ?? _buildDefaultError(),
        );
      },
    );
  }
}

/// 圆形NPC头像组件
class NPCCircleAvatar extends StatelessWidget {
  final String npcId;
  final double radius;
  final String fileName;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  const NPCCircleAvatar({
    super.key,
    required this.npcId,
    this.radius = 30,
    this.fileName = '1.jpg',
    this.placeholder,
    this.errorWidget,
  });
  
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: NPCImageWidget(
        npcId: npcId,
        fileName: fileName,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: placeholder,
        errorWidget: errorWidget,
      ),
    );
  }
}

/// 带边框的NPC头像组件
class NPCBorderedAvatar extends StatelessWidget {
  final String npcId;
  final double size;
  final String fileName;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  
  const NPCBorderedAvatar({
    super.key,
    required this.npcId,
    this.size = 100,
    this.fileName = '1.jpg',
    this.borderColor = Colors.white,
    this.borderWidth = 2,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8 - borderWidth),
        child: NPCImageWidget(
          npcId: npcId,
          fileName: fileName,
          width: size - borderWidth * 2,
          height: size - borderWidth * 2,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:io';
import '../services/cloud_npc_service.dart';
import '../services/npc_resource_loader.dart';
import '../services/npc_skin_service.dart';
import '../utils/logger_utils.dart';

/// 统一的NPC图片组件 - 自动处理缓存和加载
class NPCImageWidget extends StatefulWidget {
  final String npcId;
  final String fileName;  // 默认 '1.jpg'
  final int? skinId;  // 可選的皮膚ID，用於預覽特定皮膚
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
    this.skinId,  // 新增參數
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });
  
  @override
  State<NPCImageWidget> createState() => _NPCImageWidgetState();
}

class _NPCImageWidgetState extends State<NPCImageWidget> {
  late Future<String> _pathFuture;
  
  @override
  void initState() {
    super.initState();
    _initPathFuture();
  }
  
  @override
  void didUpdateWidget(NPCImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有当关键属性改变时才重新加载
    if (oldWidget.npcId != widget.npcId || 
        oldWidget.fileName != widget.fileName ||
        oldWidget.skinId != widget.skinId) {
      _initPathFuture();
    }
  }
  
  void _initPathFuture() {
    // 使用傳入的skinId或獲取當前選擇的皮膚ID
    final skinId = widget.skinId ?? NPCSkinService.instance.getSelectedSkinId(widget.npcId);
    
    // 獲取皮膚對應的路徑
    final avatarPath = NPCSkinService.instance.getAvatarPath(widget.npcId);
    
    // 判断是否为本地打包的NPC（0001, 0002等）
    final isLocalNPC = ['0001', '0002'].contains(widget.npcId);
    
    _pathFuture = isLocalNPC 
      ? NPCResourceLoader.getAvatarPath(widget.npcId, avatarPath, skinId: skinId)
      : CloudNPCService.getSmartResourcePath(widget.npcId, widget.fileName, skinId: skinId);
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _pathFuture,
      builder: (context, snapshot) {
        // 加载中
        if (!snapshot.hasData) {
          return _buildContainer(
            child: widget.placeholder ?? _buildDefaultPlaceholder(),
          );
        }
        
        final imagePath = snapshot.data!;
        
        // 根据路径类型选择合适的Image widget
        Widget imageWidget;
        if (imagePath.startsWith('http')) {
          // 网络图片
          imageWidget = Image.network(
            imagePath,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildContainer(
                child: widget.placeholder ?? _buildDefaultPlaceholder(),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              LoggerUtils.error('NPC图片加载失败: ${widget.npcId}/${widget.fileName} - $error');
              return _buildContainer(
                child: widget.errorWidget ?? _buildDefaultError(),
              );
            },
          );
        } else if (imagePath.startsWith('assets/')) {
          // 本地asset资源
          imageWidget = Image.asset(
            imagePath,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              LoggerUtils.error('NPC asset图片加载失败: $imagePath - $error');
              return _buildContainer(
                child: widget.errorWidget ?? _buildDefaultError(),
              );
            },
          );
        } else {
          // 本地缓存图片文件
          final file = File(imagePath);
          imageWidget = Image.file(
            file,
            // 使用文件修改时间作为key，当文件更新时强制刷新图片
            key: ValueKey('${imagePath}_${file.existsSync() ? file.lastModifiedSync().millisecondsSinceEpoch : 0}'),
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              LoggerUtils.error('NPC本地文件加载失败: $imagePath - $error');
              // 本地文件失败，尝试重新从网络加载
              return _buildNetworkFallback();
            },
          );
        }
        
        // 应用圆角
        if (widget.borderRadius != null) {
          return ClipRRect(
            borderRadius: widget.borderRadius!,
            child: imageWidget,
          );
        }
        
        return imageWidget;
      },
    );
  }
  
  Widget _buildContainer({required Widget child}) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: child,
    );
  }
  
  Widget _buildDefaultPlaceholder() {
    return Center(
      child: SizedBox(
        width: (widget.width ?? 100) * 0.3,
        height: (widget.height ?? 100) * 0.3,
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
      width: widget.width,
      height: widget.height,
      color: Colors.grey[800],
      child: Icon(
        Icons.person,
        size: (widget.width ?? widget.height ?? 100) * 0.5,
        color: Colors.white30,
      ),
    );
  }
  
  Widget _buildNetworkFallback() {
    // 本地文件损坏时，直接使用网络URL
    final networkUrl = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/'
                      'npcs%2F${widget.npcId}%2F${widget.fileName}?alt=media';
    
    return Image.network(
      networkUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        return _buildContainer(
          child: widget.errorWidget ?? _buildDefaultError(),
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ai_personality.dart';
import '../utils/logger_utils.dart';
import '../config/character_config.dart';
import 'npc_image_widget.dart';

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
    // 使用统一的NPCImageWidget组件
    Widget imageWidget = NPCImageWidget(
      npcId: personality.id,
      fileName: '1.jpg',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
    
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
  }
}


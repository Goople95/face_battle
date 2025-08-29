/// 分享图片服务 - 简化版
/// 
/// 生成分享图片并分享到社交媒体
library;

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/ai_personality.dart';
import '../models/drinking_state.dart';
import '../utils/logger_utils.dart';

class ShareImageService {
  
  /// 检查资源是否存在
  static Future<bool> _checkAssetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }
  
  /// 分享醉倒胜利（带图片）
  static Future<void> shareVictoryWithImage({
    required BuildContext context,
    required AIPersonality defeatedAI,
    required DrinkingState drinkingState,
    required int intimacyMinutes,
  }) async {
    try {
      // 预加载头像图片 - 先显示加载提示
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.loadingAvatar),
                ],
              ),
            ),
          ),
        ),
      );
      
      // 确保头像加载完成
      final String avatarPath = '${defeatedAI.avatarPath}1.jpg';
      ByteData? avatarData;
      try {
        avatarData = await rootBundle.load(avatarPath);
        LoggerUtils.debug('头像加载成功: $avatarPath');
        
        // 预缓存图片以确保渲染时可用
        if (context.mounted) {
          await precacheImage(
            MemoryImage(avatarData.buffer.asUint8List()),
            context,
          );
        }
      } catch (e) {
        LoggerUtils.warning('无法加载头像: $avatarPath, 错误: $e');
      }
      
      // 关闭第一个加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // 显示第二个加载提示 - 生成图片
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.generatingShareImage),
                ],
              ),
            ),
          ),
        ),
      );
      
      // 生成分享文本
      final shareText = _generateShareText(
        defeatedAI: defeatedAI,
        drinkingState: drinkingState,
        intimacyMinutes: intimacyMinutes,
      );
      
      // 创建并显示分享卡片
      final GlobalKey shareKey = GlobalKey();
      
      // 创建临时覆盖层来渲染图片
      final overlay = Overlay.of(context);
      final entry = OverlayEntry(
        builder: (context) => Positioned(
          left: -1000, // 在屏幕外渲染
          child: RepaintBoundary(
            key: shareKey,
            child: _buildShareCard(
              context: context,
              defeatedAI: defeatedAI,
              drinkingState: drinkingState,
              intimacyMinutes: intimacyMinutes,
              avatarData: avatarData,
            ),
          ),
        ),
      );
      
      overlay.insert(entry);
      
      // 等待渲染完成 - 使用WidgetsBinding确保渲染完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 确保Widget已经完全渲染
      if (context.mounted) {
        await WidgetsBinding.instance.endOfFrame;
        // 额外等待以确保图片完全加载
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      // 截图
      RenderRepaintBoundary? boundary = shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary != null) {
        ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        
        if (byteData != null) {
          // 保存图片
          final directory = await getTemporaryDirectory();
          final imagePath = '${directory.path}/victory_${DateTime.now().millisecondsSinceEpoch}.png';
          final imageFile = File(imagePath);
          await imageFile.writeAsBytes(byteData.buffer.asUint8List());
          
          // 移除覆盖层
          entry.remove();
          
          // 关闭加载对话框
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          
          // 分享图片和文字
          await Share.shareXFiles(
            [XFile(imagePath)],
            text: shareText,
            subject: AppLocalizations.of(context)!.shareSubject,
          );
          
          return;
        }
      }
      
      // 如果图片生成失败，移除覆盖层
      entry.remove();
      
      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // 降级到纯文字分享
      await Share.share(
        shareText,
        subject: AppLocalizations.of(context)!.shareSubject,
      );
      
    } catch (e) {
      LoggerUtils.error('分享失败: $e');
      
      // 确保关闭加载对话框
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      // 降级到纯文字分享
      try {
        final shareText = _generateShareText(
          defeatedAI: defeatedAI,
          drinkingState: drinkingState,
          intimacyMinutes: intimacyMinutes,
        );
        await Share.share(shareText);
      } catch (_) {}
    }
  }
  
  /// 生成分享文本（使用本地化文本）
  static String _generateShareText({
    required AIPersonality defeatedAI,
    required DrinkingState drinkingState,
    required int intimacyMinutes,
  }) {
    // 这个方法现在应该不会被使用，因为share_service已经提供了本地化的分享文本
    // 但作为后备，我们保留这个方法
    final drinks = drinkingState.getAIDrinks(defeatedAI.id);
    return '🎉 Dice Girls - ${defeatedAI.name} - $drinks drinks - $intimacyMinutes minutes #DiceGirls';
  }
  
  /// 构建分享卡片（简化版，确保能正确渲染）
  static Widget _buildShareCard({
    required BuildContext context,
    required AIPersonality defeatedAI,
    required DrinkingState drinkingState,
    required int intimacyMinutes,
    ByteData? avatarData,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 400,
        height: 600,  // 增加高度避免溢出
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Color.fromRGBO(139, 0, 0, 0.9), // 暗红色
              Colors.black87,
              Colors.black,
            ],
            stops: const [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // 标题
            Text(
              AppLocalizations.of(context)!.perfectVictory,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // AI头像区域（简化版）
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.pinkAccent, Colors.purpleAccent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: avatarData != null
                    ? Image.memory(
                        avatarData.buffer.asUint8List(),
                        fit: BoxFit.cover,
                        width: 142,
                        height: 142,
                        errorBuilder: (context, error, stackTrace) {
                          // 如果内存图片加载失败，显示占位符
                          return Container(
                            width: 142,
                            height: 142,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 40,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    defeatedAI.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 142,
                        height: 142,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                defeatedAI.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 醉倒状态 - 直接显示在底图上
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.shade400,
                  Colors.red.shade700,
                ],
              ).createShader(bounds),
              child: Text(
                '${defeatedAI.name} ${AppLocalizations.of(context)!.shareCardDrunk}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(
                      blurRadius: 8,
                      color: Colors.black54,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 25),
            
            // 亲密度展示（核心信息）- 一行显示
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 50),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.pinkAccent.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  // 亲密度在一行显示
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Colors.pinkAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context)!.shareCardIntimacy,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '+$intimacyMinutes',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent,
                          shadows: [
                            Shadow(
                              color: Colors.pinkAccent.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.shareCardPrivateTime(intimacyMinutes),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // 游戏标识区域（简化版）
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.casino,
                    color: Colors.amber,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dice Girls',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.gameSlogan,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.challengeNow,
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
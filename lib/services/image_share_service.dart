import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/ai_personality.dart';
import '../models/drinking_state.dart';
import '../utils/logger_utils.dart';
import '../widgets/simple_share_card.dart';
import 'share_tracking_service.dart';
import 'auth_service.dart';
import 'package:provider/provider.dart';

/// 图片分享服务 - 生成并分享带二维码的图片
class ImageShareService {
  
  /// 分享醉倒胜利（直接生成并分享图片）
  static Future<void> shareDirectly({
    required BuildContext context,
    required AIPersonality defeatedAI,
    required DrinkingState drinkingState,
    required int intimacyMinutes,
  }) async {
    try {
      LoggerUtils.info('开始生成分享图片');
      
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.pinkAccent),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.generatingShareImage,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
      
      // 获取本地化的AI名称
      final locale = Localizations.localeOf(context);
      final languageCode = locale.languageCode;
      String localeCode = languageCode;
      if (languageCode == 'zh') {
        localeCode = 'zh_TW';
      }
      final aiName = defeatedAI.getLocalizedName(localeCode);
      
      // 获取用户ID（用于追踪）
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.uid;
      
      // 生成带追踪参数的Play商店链接
      final trackedUrl = ShareTrackingService.generateTrackedPlayStoreLink(
        aiName: aiName,
        drinkCount: drinkingState.getAIDrinks(defeatedAI.id),
        intimacyMinutes: intimacyMinutes,
        userId: userId,
      );
      
      LoggerUtils.info('生成的追踪链接: $trackedUrl');
      
      // 生成短链接
      String shortUrl = trackedUrl;
      try {
        shortUrl = await ShareTrackingService.generateShortLink(
          longUrl: trackedUrl,
        );
        LoggerUtils.info('生成的短链接: $shortUrl');
      } catch (e) {
        LoggerUtils.error('短链接生成失败，使用原链接: $e');
      }
      
      // 创建简化版分享卡片
      final shareCard = SimpleShareCard(
        defeatedAI: defeatedAI,
        drinkingState: drinkingState,
        intimacyMinutes: intimacyMinutes,
        dynamicLink: shortUrl,
      );
      
      // 使用Screenshot包截图
      final screenshotController = ScreenshotController();
      
      // 生成图片
      final imageBytes = await screenshotController.captureFromWidget(
        Container(
          width: 400,
          height: 600,
          child: shareCard,
        ),
        pixelRatio: 2.0, // 高清图片
        context: context,
      );
      
      // 保存图片到临时目录
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/share_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);
      
      LoggerUtils.info('图片已保存到: $imagePath');
      
      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // 生成分享文本
      final shareText = _generateShareText(
        context: context,
        defeatedAI: defeatedAI,
        drinkingState: drinkingState,
        intimacyMinutes: intimacyMinutes,
        shortUrl: shortUrl,
      );
      
      // 分享图片和文字
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: shareText,
        subject: AppLocalizations.of(context)!.shareSubject,
      );
      
      LoggerUtils.info('图片分享成功');
      
    } catch (e) {
      LoggerUtils.error('分享失败: $e');
      // 关闭可能存在的对话框
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      // 显示错误提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// 显示分享卡片预览（带截图按钮）
  static Future<void> showSharePreview({
    required BuildContext context,
    required AIPersonality defeatedAI,
    required DrinkingState drinkingState,
    required int intimacyMinutes,
  }) async {
    try {
      LoggerUtils.info('显示分享预览');
      
      // 获取本地化的AI名称
      final locale = Localizations.localeOf(context);
      final languageCode = locale.languageCode;
      String localeCode = languageCode;
      if (languageCode == 'zh') {
        localeCode = 'zh_TW';
      }
      final aiName = defeatedAI.getLocalizedName(localeCode);
      
      // 获取用户ID
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.uid;
      
      // 生成链接
      final trackedUrl = ShareTrackingService.generateTrackedPlayStoreLink(
        aiName: aiName,
        drinkCount: drinkingState.getAIDrinks(defeatedAI.id),
        intimacyMinutes: intimacyMinutes,
        userId: userId,
      );
      
      String shortUrl = trackedUrl;
      try {
        shortUrl = await ShareTrackingService.generateShortLink(
          longUrl: trackedUrl,
        );
      } catch (e) {
        LoggerUtils.error('短链接生成失败: $e');
      }
      
      // 创建简化版分享卡片
      final shareCard = SimpleShareCard(
        defeatedAI: defeatedAI,
        drinkingState: drinkingState,
        intimacyMinutes: intimacyMinutes,
        dynamicLink: shortUrl,
      );
      
      // 创建Screenshot控制器
      final screenshotController = ScreenshotController();
      
      // 显示预览对话框
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext dialogContext) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(20),
              child: Stack(
                children: [
                  // 使用Screenshot包装分享卡片
                  Screenshot(
                    controller: screenshotController,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 400,
                        height: 600,
                        child: shareCard,
                      ),
                    ),
                  ),
                  // 关闭按钮
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                  ),
                  // 底部分享按钮
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          // 截图
                          final imageBytes = await screenshotController.capture(
                            pixelRatio: 2.0,
                          );
                          
                          if (imageBytes != null) {
                            // 保存图片
                            final directory = await getTemporaryDirectory();
                            final imagePath = '${directory.path}/share_${DateTime.now().millisecondsSinceEpoch}.png';
                            final imageFile = File(imagePath);
                            await imageFile.writeAsBytes(imageBytes);
                            
                            // 生成分享文本
                            final shareText = _generateShareText(
                              context: context,
                              defeatedAI: defeatedAI,
                              drinkingState: drinkingState,
                              intimacyMinutes: intimacyMinutes,
                              shortUrl: shortUrl,
                            );
                            
                            // 分享图片
                            await Share.shareXFiles(
                              [XFile(imagePath)],
                              text: shareText,
                              subject: AppLocalizations.of(context)!.shareSubject,
                            );
                            
                            LoggerUtils.info('分享成功');
                          }
                        } catch (e) {
                          LoggerUtils.error('分享失败: $e');
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('分享失败，请重试'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.share),
                      label: Text(AppLocalizations.of(context)!.share),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
      
    } catch (e) {
      LoggerUtils.error('显示预览失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('显示预览失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// 生成分享文本
  static String _generateShareText({
    required BuildContext context,
    required AIPersonality defeatedAI,
    required DrinkingState drinkingState,
    required int intimacyMinutes,
    required String shortUrl,
  }) {
    final drinks = drinkingState.getAIDrinks(defeatedAI.id);
    final l10n = AppLocalizations.of(context)!;
    
    // 获取本地化的AI名称
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    String localeCode = languageCode;
    if (languageCode == 'zh') {
      localeCode = 'zh_TW';
    }
    final aiName = defeatedAI.getLocalizedName(localeCode);
    
    // 使用本地化的分享模板
    List<String> templates = [
      l10n.shareTemplate1(aiName, drinks, intimacyMinutes),
      l10n.shareTemplate2(aiName, drinks, intimacyMinutes),
      l10n.shareTemplate3(aiName, drinks, intimacyMinutes),
      l10n.shareTemplate4(aiName, drinks, intimacyMinutes),
    ];
    
    // 随机选择一个模板
    final randomIndex = DateTime.now().millisecond % templates.length;
    final shareText = templates[randomIndex];
    
    // 添加下载链接
    return '$shareText\n\n👉 下载游戏: $shortUrl';
  }
}
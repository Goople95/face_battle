import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/ai_personality.dart';
import '../models/drinking_state.dart';
import '../utils/logger_utils.dart';
import '../widgets/share_card_with_qr.dart';
import 'share_tracking_service.dart';
import 'auth_service.dart';
import 'package:provider/provider.dart';

/// 简化版分享服务 - 直接显示分享卡片对话框
class SimpleShareService {
  
  /// 分享醉倒胜利（简化版：显示对话框让用户截图）
  static Future<void> shareDrunkVictory({
    required BuildContext context,
    required AIPersonality defeatedAI,
    required DrinkingState drinkingState,
    required int intimacyMinutes,
  }) async {
    try {
      LoggerUtils.info('开始分享流程');
      
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
      
      // 生成短链接（可选）
      String shortUrl = trackedUrl;
      try {
        shortUrl = await ShareTrackingService.generateShortLink(
          longUrl: trackedUrl,
        );
        LoggerUtils.info('生成的短链接: $shortUrl');
      } catch (e) {
        LoggerUtils.error('短链接生成失败，使用原链接: $e');
      }
      
      // 创建带二维码的分享卡片
      final shareCard = ShareCardWithQR(
        defeatedAI: defeatedAI,
        drinkingState: drinkingState,
        intimacyMinutes: intimacyMinutes,
        dynamicLink: shortUrl,
      );
      
      // 显示分享卡片对话框
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
                  // 分享卡片
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SingleChildScrollView(
                      child: shareCard,
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
                        // 生成分享文本
                        final shareText = _generateShareText(
                          context: context,
                          defeatedAI: defeatedAI,
                          drinkingState: drinkingState,
                          intimacyMinutes: intimacyMinutes,
                          shortUrl: shortUrl,
                        );
                        
                        // 调用系统分享
                        await Share.share(
                          shareText,
                          subject: AppLocalizations.of(context)!.shareSubject,
                        );
                        
                        LoggerUtils.info('分享成功');
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
      LoggerUtils.error('分享失败: $e');
      // 显示错误提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败: $e'),
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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/ai_personality.dart';
import '../models/drinking_state.dart';
import '../l10n/generated/app_localizations.dart';
import 'npc_avatar_widget.dart';

/// 简化版分享卡片 - 更美观的布局
class SimpleShareCard extends StatelessWidget {
  final AIPersonality defeatedAI;
  final DrinkingState drinkingState;
  final int intimacyMinutes;
  final String dynamicLink;
  
  const SimpleShareCard({
    super.key,
    required this.defeatedAI,
    required this.drinkingState,
    required this.intimacyMinutes,
    required this.dynamicLink,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // 获取本地化的AI名称
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    String localeCode = languageCode;
    if (languageCode == 'zh') {
      localeCode = 'zh_TW';
    }
    final aiName = defeatedAI.getLocalizedName(localeCode);
    
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 400,
        height: 600,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Color.fromRGBO(139, 0, 0, 0.9),
              Colors.black,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // 背景装饰 - 简单的光晕
            Positioned(
              top: 100,
              left: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.pink.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              right: -50,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.purple.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            // 主要内容
            Column(
              children: [
                const SizedBox(height: 30),
                
                // AI美女全图展示（不用圆圈）
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: NPCAvatarWidget(
                      personality: defeatedAI,
                      size: 200,
                      showBorder: false,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // AI名字
                Text(
                  aiName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                
                // 亲密度显示（单行）
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Colors.pinkAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${l10n.shareCardIntimacy} +$intimacyMinutes',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent,
                          shadows: [
                            Shadow(
                              color: Colors.pinkAccent.withValues(alpha: 0.5),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // 私人时间文字
                Text(
                  l10n.shareCardPrivateTime(intimacyMinutes),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                
                const SizedBox(height: 35),
                
                // 二维码部分
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      // 二维码
                      QrImageView(
                        data: dynamicLink,
                        version: QrVersions.auto,
                        size: 100,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                        embeddedImage: const AssetImage('assets/icons/dice-icon-1024.png'),
                        embeddedImageStyle: const QrEmbeddedImageStyle(
                          size: Size(20, 20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dice Girls文字
                      const Text(
                        'Dice Girls',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.gameSlogan,  // "100+等你来挑战"
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                
                // 底部游戏标识
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.casino,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.shareCardGameName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
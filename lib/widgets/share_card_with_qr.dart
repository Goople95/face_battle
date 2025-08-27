import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/ai_personality.dart';
import '../models/drinking_state.dart';
import '../l10n/generated/app_localizations.dart';

/// 带二维码的分享卡片
class ShareCardWithQR extends StatelessWidget {
  final AIPersonality defeatedAI;
  final DrinkingState drinkingState;
  final int intimacyMinutes;
  final String dynamicLink;
  
  const ShareCardWithQR({
    super.key,
    required this.defeatedAI,
    required this.drinkingState,
    required this.intimacyMinutes,
    required this.dynamicLink,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final drinks = drinkingState.getAIDrinks(defeatedAI.id);
    
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
        height: 700,  // 增加高度以容纳二维码
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Color.fromRGBO(139, 0, 0, 0.8),
              Colors.black87,
              Colors.black,
            ],
            stops: const [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // 背景装饰
            _buildBackgroundDecoration(),
            
            // 主要内容
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  
                  // AI照片和醉酒标记
                  _buildAIAvatar(aiName),
                  
                  const SizedBox(height: 20),
                  
                  // AI名字和状态
                  _buildAINameAndStatus(aiName, l10n),
                  
                  const SizedBox(height: 25),
                  
                  // 亲密度展示
                  _buildIntimacyDisplay(l10n),
                  
                  const SizedBox(height: 20),
                  
                  // 喝酒数量
                  _buildDrinkCount(l10n, drinks),
                  
                  const SizedBox(height: 25),
                  
                  // 二维码部分（新增）
                  _buildQRCodeSection(l10n),
                  
                  const SizedBox(height: 20),
                  
                  // 底部游戏标识
                  _buildGameBranding(l10n),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBackgroundDecoration() {
    return Stack(
      children: [
        Positioned(
          top: 150,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.pink.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -50,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAIAvatar(String aiName) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 照片外框装饰
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.pinkAccent, Colors.purpleAccent],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withValues(alpha: 0.6),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        // AI照片
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: ClipOval(
            child: Image.asset(
              '${defeatedAI.avatarPath}avatar.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade800,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          aiName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // 醉酒状态标记
        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Text('🥴', style: TextStyle(fontSize: 20)),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAINameAndStatus(String aiName, AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          aiName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.red.shade400, Colors.red.shade700],
          ).createShader(bounds),
          child: Text(
            '$aiName ${l10n.shareCardDrunk}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildIntimacyDisplay(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pink.withValues(alpha: 0.2),
            Colors.purple.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.pinkAccent.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite, color: Colors.pinkAccent, size: 24),
              const SizedBox(width: 8),
              Text(
                l10n.shareCardIntimacy,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '+$intimacyMinutes',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.pinkAccent,
              shadows: [
                Shadow(
                  color: Colors.pinkAccent.withValues(alpha: 0.5),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          Text(
            l10n.shareCardPrivateTime(intimacyMinutes),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrinkCount(AppLocalizations l10n, int drinks) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.local_bar,
          color: Colors.amber.withValues(alpha: 0.8),
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          l10n.shareCardDrinkCount(drinks),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  Widget _buildQRCodeSection(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // 二维码
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: dynamicLink,
              version: QrVersions.auto,
              size: 120,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              embeddedImage: const AssetImage('assets/icons/dice-icon-1024.png'),
              embeddedImageStyle: const QrEmbeddedImageStyle(
                size: Size(24, 24),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 扫码提示
          Text(
            l10n.challengeNow,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.gameSlogan,  // "100+等你来挑战"
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGameBranding(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.casino,
            color: Colors.white.withValues(alpha: 0.8),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            l10n.shareCardGameName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
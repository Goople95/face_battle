/// 分享服务
/// 
/// 处理游戏截图和社交媒体分享
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/ai_personality.dart';
import '../models/drinking_state.dart';
import '../utils/logger_utils.dart';

class ShareService {
  
  /// 分享醉倒胜利
  static Future<void> shareDrunkVictory({
    required BuildContext context,
    required AIPersonality defeatedAI,
    required DrinkingState drinkingState,
    required int intimacyMinutes,
  }) async {
    try {
      // 生成分享文本
      final shareText = _generateShareText(
        context: context,
        defeatedAI: defeatedAI,
        drinkingState: drinkingState,
        intimacyMinutes: intimacyMinutes,
      );
      
      // 创建分享卡片
      final shareCard = _buildShareCard(
        context: context,
        defeatedAI: defeatedAI,
        drinkingState: drinkingState,
        intimacyMinutes: intimacyMinutes,
      );
      
      // 暂时只分享文字，不生成图片
      final l10n = AppLocalizations.of(context)!;
      await Share.share(
        shareText,
        subject: l10n.shareSubject,
      );
      
    } catch (e) {
      LoggerUtils.error('分享失败: $e');
      // 如果图片分享失败，至少分享文字
      _shareTextOnly(
        context: context,
        defeatedAI: defeatedAI,
        drinkingState: drinkingState,
        intimacyMinutes: intimacyMinutes,
      );
    }
  }
  
  /// 仅分享文字
  static Future<void> _shareTextOnly({
    required BuildContext context,
    required AIPersonality defeatedAI,
    required DrinkingState drinkingState,
    required int intimacyMinutes,
  }) async {
    final shareText = _generateShareText(
      context: context,
      defeatedAI: defeatedAI,
      drinkingState: drinkingState,
      intimacyMinutes: intimacyMinutes,
    );
    final l10n = AppLocalizations.of(context)!;
    
    await Share.share(
      shareText,
      subject: l10n.shareSubject,
    );
  }
  
  /// 生成分享文本
  static String _generateShareText({
    required BuildContext context,
    required AIPersonality defeatedAI,
    required DrinkingState drinkingState,
    required int intimacyMinutes,
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
    return templates[randomIndex];
  }
  
  /// 构建分享卡片 - 重新设计，突出AI照片和亲密度
  static Widget _buildShareCard({
    required BuildContext context,
    required AIPersonality defeatedAI,
    required DrinkingState drinkingState,
    required int intimacyMinutes,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 400,
        height: 600,
      decoration: BoxDecoration(
        // 黑色和暗红色的过渡
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Color.fromRGBO(139, 0, 0, 0.8), // 暗红色
            Colors.black87,
            Colors.black,
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 背景装饰 - 简单的光晕效果
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
          
          // 主要内容
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
              
              // 1. 核心元素：AI真实照片（大尺寸）
              Stack(
                alignment: Alignment.center,
                children: [
                  // 照片外框装饰
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.pinkAccent,
                          Colors.purpleAccent,
                        ],
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
                  // AI真实照片
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipOval(
                      child: Container(
                        width: 170,
                        height: 170,
                        color: Colors.grey.shade800,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 尝试加载图片
                            Image.asset(
                              '${defeatedAI.avatarPath}avatar.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // 图片加载失败时显示备用内容
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.white.withValues(alpha: 0.7),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        (() {
                                          final locale = Localizations.localeOf(context);
                                          final languageCode = locale.languageCode;
                                          String localeCode = languageCode;
                                          if (languageCode == 'zh') {
                                            localeCode = 'zh_TW';
                                          }
                                          return defeatedAI.getLocalizedName(localeCode);
                                        })(),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 醉酒状态标记
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Text(
                        '🥴',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // AI名字
              Text(
                (() {
                  final locale = Localizations.localeOf(context);
                  final languageCode = locale.languageCode;
                  String localeCode = languageCode;
                  if (languageCode == 'zh') {
                    localeCode = 'zh_TW';
                  }
                  return defeatedAI.getLocalizedName(localeCode);
                })(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              
              const SizedBox(height: 8),
              
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
                  '${(() {
                    final locale = Localizations.localeOf(context);
                    final languageCode = locale.languageCode;
                    String localeCode = languageCode;
                    if (languageCode == 'zh') {
                      localeCode = 'zh_TW';
                    }
                    return defeatedAI.getLocalizedName(localeCode);
                  })()} ${AppLocalizations.of(context)!.shareCardDrunk}',
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
              
              const SizedBox(height: 30),
              
              // 2. 核心元素：亲密度展示（突出显示）
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(16),
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
                        Icon(
                          Icons.favorite,
                          color: Colors.pinkAccent,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppLocalizations.of(context)!.shareCardIntimacy,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 大字体显示亲密度增加
                    Text(
                      '+$intimacyMinutes',
                      style: TextStyle(
                        fontSize: 48,
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
                    const SizedBox(height: 5),
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
              
              const SizedBox(height: 20),
              
              // 次要信息：喝酒数量（简洁显示）
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_bar,
                    color: Colors.amber.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.shareCardDrinkCount(drinkingState.getAIDrinks(defeatedAI.id)),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // 底部：游戏标识（简洁）
              Container(
                margin: const EdgeInsets.only(bottom: 20),
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
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.shareCardGameName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
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
  
  /// 构建统计项
  static Widget _buildStatItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  /// 分享到特定平台
  static Future<void> shareToWeChat({
    required String text,
    String? imagePath,
  }) async {
    // 微信分享需要集成微信SDK
    // 这里提供接口，具体实现需要配置微信开放平台
    try {
      if (imagePath != null) {
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: text,
        );
      } else {
        await Share.share(text);
      }
    } catch (e) {
      LoggerUtils.error('微信分享失败: $e');
    }
  }
  
  /// 保存截图到相册
  static Future<bool> saveScreenshot({
    required BuildContext context,
    required AIPersonality defeatedAI,
    required DrinkingState drinkingState,
    required int intimacyMinutes,
  }) async {
    try {
      final shareCard = _buildShareCard(
        context: context,
        defeatedAI: defeatedAI,
        drinkingState: drinkingState,
        intimacyMinutes: intimacyMinutes,
      );
      
      final image = await _captureWidget(shareCard, context);
      
      // 保存到相册需要额外的权限处理
      // 这里先保存到临时目录
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/victory_save_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);
      
      // 显示保存成功提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.screenshotSaved),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      return true;
    } catch (e) {
      LoggerUtils.error('保存截图失败: $e');
      return false;
    }
  }
  
  /// 简化的截图方法 - 直接分享文字，不生成图片
  static Future<Uint8List> _captureWidget(Widget widget, BuildContext context) async {
    // 暂时返回空数组，仅分享文字
    return Uint8List(0);
  }
}
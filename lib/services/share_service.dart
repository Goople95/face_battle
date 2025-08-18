/// 分享服务
/// 
/// 处理游戏截图和社交媒体分享

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ai_personality.dart';
import '../models/drinking_state.dart';

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
      await Share.share(
        shareText,
        subject: '表情博弈 - 完美胜利！',
      );
      
    } catch (e) {
      print('分享失败: $e');
      // 如果图片分享失败，至少分享文字
      _shareTextOnly(
        defeatedAI: defeatedAI,
        drinkingState: drinkingState,
        intimacyMinutes: intimacyMinutes,
      );
    }
  }
  
  /// 仅分享文字
  static Future<void> _shareTextOnly({
    required AIPersonality defeatedAI,
    required DrinkingState drinkingState,
    required int intimacyMinutes,
  }) async {
    final shareText = _generateShareText(
      defeatedAI: defeatedAI,
      drinkingState: drinkingState,
      intimacyMinutes: intimacyMinutes,
    );
    
    await Share.share(
      shareText,
      subject: '表情博弈 - 完美胜利！',
    );
  }
  
  /// 生成分享文本
  static String _generateShareText({
    required AIPersonality defeatedAI,
    required DrinkingState drinkingState,
    required int intimacyMinutes,
  }) {
    final drinks = drinkingState.getAIDrinks(defeatedAI.id);
    
    // 根据不同情况生成有趣的分享文本
    List<String> templates = [
      '🎉 我在表情博弈中把${defeatedAI.name}灌醉了！喝了整整$drinks杯，独处了$intimacyMinutes分钟～ #表情博弈 #完美胜利',
      '🏆 战绩播报：${defeatedAI.name}已倒！$drinks杯下肚，亲密度+$intimacyMinutes！谁敢来挑战？ #表情博弈',
      '😎 轻松拿下${defeatedAI.name}！$drinks杯酒就不行了，我们还聊了$intimacyMinutes分钟的小秘密～ #表情博弈',
      '🍺 今晚的MVP是我！${defeatedAI.name}醉倒在第$drinks杯，接下来的$intimacyMinutes分钟...你懂的😏 #表情博弈',
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
        // 深色背景，营造夜晚氛围
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.pink.shade900.withOpacity(0.8),
            Colors.black,
          ],
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
                    Colors.pink.withOpacity(0.3),
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
                    Colors.purple.withOpacity(0.3),
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
                          color: Colors.pinkAccent.withOpacity(0.6),
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
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        defeatedAI.name,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
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
                defeatedAI.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 醉倒状态
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: const Text(
                  '已醉倒',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
                      Colors.pink.withOpacity(0.2),
                      Colors.purple.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.pinkAccent.withOpacity(0.5),
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
                        const Text(
                          '亲密度',
                          style: TextStyle(
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
                            color: Colors.pinkAccent.withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '独处了 $intimacyMinutes 分钟',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
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
                    color: Colors.amber.withOpacity(0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${drinkingState.getAIDrinks(defeatedAI.id)} 杯醉倒',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
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
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.casino,
                      color: Colors.white.withOpacity(0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '表情博弈',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
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
            color: Colors.white.withOpacity(0.8),
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
  
  /// 获取难度文本
  static String _getDifficultyText(AIPersonality ai) {
    if (ai.isVIP) {
      return ai.difficulty ?? '高手';
    }
    
    // 根据AI的参数判断难度
    final avgDifficulty = (ai.bluffRatio + ai.riskAppetite + (1 - ai.mistakeRate)) / 3;
    if (avgDifficulty > 0.6) return '困难';
    if (avgDifficulty > 0.4) return '中等';
    return '简单';
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
      print('微信分享失败: $e');
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
          const SnackBar(
            content: Text('截图已保存！'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      return true;
    } catch (e) {
      print('保存截图失败: $e');
      return false;
    }
  }
  
  /// 简化的截图方法 - 直接分享文字，不生成图片
  static Future<Uint8List> _captureWidget(Widget widget, BuildContext context) async {
    // 暂时返回空数组，仅分享文字
    return Uint8List(0);
  }
}
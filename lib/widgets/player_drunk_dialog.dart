import 'package:flutter/material.dart';
import 'dart:async';
import '../models/drinking_state.dart';
import '../models/ai_personality.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/npc_image_widget.dart';

/// 玩家醉酒对话框（极简高级风格）
class PlayerDrunkDialog extends StatefulWidget {
  final DrinkingState drinkingState;
  final AIPersonality npcPersonality;
  final VoidCallback onWatchAd;
  final VoidCallback onCancel;
  final bool fromGameScreen;
  
  const PlayerDrunkDialog({
    super.key,
    required this.drinkingState,
    required this.npcPersonality,
    required this.onWatchAd,
    required this.onCancel,
    this.fromGameScreen = false,
  });
  
  @override
  State<PlayerDrunkDialog> createState() => _PlayerDrunkDialogState();
}

class _PlayerDrunkDialogState extends State<PlayerDrunkDialog> with SingleTickerProviderStateMixin {
  // 对话控制
  int _currentDialogIndex = 0;
  Timer? _dialogTimer;
  late AnimationController _textAnimationController;
  late Animation<double> _textAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _textAnimation = CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeIn,
    );
    
    // 开始对话序列
    _startDialogSequence();
  }
  
  void _startDialogSequence() {
    _textAnimationController.forward();
    _dialogTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _currentDialogIndex = (_currentDialogIndex + 1) % 5; // 循环播放5句话
      });
      _textAnimationController.forward(from: 0);
    });
  }
  
  @override
  void dispose() {
    _dialogTimer?.cancel();
    _textAnimationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,  // 添加不透明背景
      insetPadding: EdgeInsets.zero,  // 全屏遮罩
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.black,
          ),
          child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 大方块图片和对话区域
              SizedBox(
                height: 280,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // NPC静态图片 - 完全撑满
                    NPCImageWidget(
                      npcId: widget.npcPersonality.id,
                      fileName: '1.jpg',
                    ),
                    // 渐变遮罩（用于字幕区）
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                              Colors.black.withValues(alpha: 0.95),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 对话文字
                    Positioned(
                      bottom: 15,
                      left: 20,
                      right: 20,
                      child: FadeTransition(
                        opacity: _textAnimation,
                        child: _buildDialogText(context),
                      ),
                    ),
                  ],
                ),
              ),
              // 选项区域
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey.shade900,
                      Colors.black,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 看广告醒酒 - 主要按钮
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          Future.delayed(const Duration(milliseconds: 100), () {
                            widget.onWatchAd();
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.teal.shade700,
                                Colors.teal.shade900,
                              ],
                            ),
                            border: Border.all(
                              color: Colors.teal.withValues(alpha: 0.5),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.teal.withValues(alpha: 0.15),
                                      Colors.teal.withValues(alpha: 0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.teal.withValues(alpha: 0.2),
                                    width: 0.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.play_circle_outline,
                                  color: Colors.teal.shade300,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.watchAdToSoberTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppLocalizations.of(context)!.watchAdToSoberSubtitle,
                                      style: TextStyle(
                                        color: Colors.teal.shade300,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.teal.shade300,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // 返回主页 - 弱化为文字按钮
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (widget.fromGameScreen) {
                          Navigator.of(context).pop();
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.goHomeToRest,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
  
  // 构建对话文本
  Widget _buildDialogText(BuildContext context) {
    String dialogText = '';
    switch (_currentDialogIndex) {
      case 0:
        dialogText = AppLocalizations.of(context)!.playerDrunkDialogue1;
        break;
      case 1:
        dialogText = AppLocalizations.of(context)!.playerDrunkDialogue2(widget.drinkingState.drinksConsumed);
        break;
      case 2:
        dialogText = AppLocalizations.of(context)!.playerDrunkDialogue3;
        break;
      case 3:
        dialogText = AppLocalizations.of(context)!.playerDrunkDialogue4;
        break;
      case 4:
        dialogText = AppLocalizations.of(context)!.playerDrunkDialogue5;
        break;
    }
    
    return Text(
      dialogText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
        shadows: [
          Shadow(
            offset: Offset(0, 1),
            blurRadius: 3,
            color: Colors.black87,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
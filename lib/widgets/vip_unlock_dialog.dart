import 'package:flutter/material.dart';
import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/ai_personality.dart';
import '../services/vip_unlock_service.dart';
import '../services/game_progress_service.dart';
import '../services/purchase_service.dart';
import '../services/analytics_service.dart';
import '../utils/ad_helper.dart';
import '../l10n/generated/app_localizations.dart';
import 'npc_image_widget.dart';

/// VIP解锁对话框
class VIPUnlockDialog extends StatefulWidget {
  final AIPersonality character;
  
  const VIPUnlockDialog({super.key, required this.character});
  
  @override
  State<VIPUnlockDialog> createState() => _VIPUnlockDialogState();
}

class _VIPUnlockDialogState extends State<VIPUnlockDialog> with SingleTickerProviderStateMixin {
  final VIPUnlockService _vipService = VIPUnlockService();
  final PurchaseService _purchaseService = PurchaseService();
  int _userGems = 0;
  ProductDetails? _product;
  bool _isLoading = false;
  
  // 对话控制
  int _currentDialogIndex = 0;
  Timer? _dialogTimer;
  late AnimationController _textAnimationController;
  late Animation<double> _textAnimation;
  
  @override
  void initState() {
    super.initState();
    _loadUserGems();
    _loadProductInfo();
    
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
    
    // 记录对话框显示事件
    AnalyticsService().logDialogShow(
      dialogName: 'vip_unlock_dialog',
      params: {
        'npc_id': widget.character.id,
        'npc_name': widget.character.name,
      },
    );
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
  
  Future<void> _loadUserGems() async {
    int gems = await _vipService.getUserGems();
    setState(() {
      _userGems = gems;
    });
  }
  
  Future<void> _loadProductInfo() async {
    // 检查是否已经购买
    if (_purchaseService.isNPCPurchased(widget.character.id)) {
      // 已经购买，直接关闭对话框
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }
    
    // 加载商品信息
    final product = await _purchaseService.getProductForNPC(widget.character.id);
    if (mounted) {
      setState(() {
        _product = product;
        // 如果无法获取真实商品信息，在测试模式下显示默认价格
        // 这样至少能看到UI界面
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
              // 大方块头像和对话区域
              SizedBox(
                height: 280,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 大方块头像 - 完全撑满
                    NPCImageWidget(
                      npcId: widget.character.id,
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
                    // NPC对话文字
                    Positioned(
                      bottom: 15,
                      left: 20,
                      right: 20,
                      child: FadeTransition(
                        opacity: _textAnimation,
                        child: _buildDialogText(context),
                      ),
                    ),
                    // VIP标志
                    Positioned(
                      top: 15,
                      right: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade400,
                              Colors.amber.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Text(
                          'VIP',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 解锁选项区域
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
                // 看广告临时解锁
                _buildUnlockOption(
                  icon: Icons.play_circle_outline,
                  title: AppLocalizations.of(context)!.watchAdUnlock,
                  subtitle: AppLocalizations.of(context)!.freePlayOneHour,
                  color: Colors.teal.shade400,
                  onTap: () async {
                    // 记录选择看广告
                    AnalyticsService().logDialogAction(
                      dialogName: 'vip_unlock_dialog',
                      action: 'watch_ad',
                      params: {
                        'npc_id': widget.character.id,
                      },
                    );
                    
                    Navigator.of(context).pop(false);
                    await Future.delayed(const Duration(milliseconds: 100));
                    
                    if (context.mounted) {
                      // 记录广告展示事件
                      AnalyticsService().logAdShow(
                        adType: 'vip_unlock',
                        placement: 'vip_dialog',
                        rewarded: true,
                      );
                      
                      AdHelper.showRewardedAdWithLoading(
                        context: context,
                        adType: AdType.vip,  // 使用VIP解锁专用广告
                      onRewarded: (reward) async {
                        // 记录广告完成事件
                        AnalyticsService().logAdComplete(
                          adType: 'vip_unlock',
                          placement: 'vip_dialog',
                          rewardAmount: 1,
                        );
                        await _vipService.temporaryUnlock(widget.character.id);
                        // 记录看广告解锁VIP的次数
                        await GameProgressService.instance.recordAdUnlockVIP(widget.character.id);
                        if (context.mounted) {
                          final locale = Localizations.localeOf(context);
                          final languageCode = locale.languageCode;
                          String localeCode = languageCode;
                          if (languageCode == 'zh') {
                            localeCode = 'zh_TW';
                          }
                          final localizedName = widget.character.getLocalizedName(localeCode);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.tempUnlocked(localizedName)),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                        loadingText: '正在加载广告...',
                      );
                    }
                  },
                ),
                
                // 真实付费永久解锁
                const SizedBox(height: 10),
                _buildUnlockOption(
                  icon: Icons.diamond,
                  title: AppLocalizations.of(context)!.permanentUnlock,
                  subtitle: _product?.price ?? '\$0.99',  // 显示实际价格或默认价格
                  color: Colors.amber.shade600,
                  enabled: !_isLoading,
                  onTap: () async {
                    // 记录点击购买按钮
                    AnalyticsService().logDialogAction(
                      dialogName: 'vip_unlock_dialog',
                      action: 'purchase',
                      params: {
                        'npc_id': widget.character.id,
                        'price': _product?.price ?? '\$0.99',
                      },
                    );
                    
                    // 如果没有商品信息，显示提示
                    if (_product == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('内购服务暂时不可用，请稍后再试'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    
                    // 记录购买开始
                    AnalyticsService().logPurchaseStart(
                      itemId: _product!.id,
                      npcId: widget.character.id,
                      price: _product!.price,
                    );
                    
                      setState(() {
                        _isLoading = true;
                      });
                      
                      await _purchaseService.purchaseNPC(
                        widget.character.id,
                        (npcId, success, error) {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                            
                            if (success) {
                              // 购买成功
                              final locale = Localizations.localeOf(context);
                              final languageCode = locale.languageCode;
                              String localeCode = languageCode;
                              if (languageCode == 'zh') {
                                localeCode = 'zh_TW';
                              }
                              final localizedName = widget.character.getLocalizedName(localeCode);
                              
                              Navigator.of(context).pop(true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)!.permanentUnlocked(localizedName)),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              // 购买失败
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error ?? '购买失败'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                // 取消按钮
                TextButton(
                  onPressed: () {
                    // 记录取消操作
                    AnalyticsService().logDialogAction(
                      dialogName: 'vip_unlock_dialog',
                      action: 'cancel',
                      params: {
                        'npc_id': widget.character.id,
                      },
                    );
                    Navigator.of(context).pop(false);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.laterDecide,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
  
  // 构建对话文本
  Widget _buildDialogText(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    String localeCode = languageCode;
    if (languageCode == 'zh') {
      localeCode = 'zh_TW';
    }
    final localizedName = widget.character.getLocalizedName(localeCode);
    
    String dialogText = '';
    switch (_currentDialogIndex) {
      case 0:
        dialogText = AppLocalizations.of(context)!.vipDialogue1(localizedName);
        break;
      case 1:
        dialogText = AppLocalizations.of(context)!.vipDialogue2;
        break;
      case 2:
        dialogText = AppLocalizations.of(context)!.vipDialogue3;
        break;
      case 3:
        dialogText = AppLocalizations.of(context)!.vipDialogue4;
        break;
      case 4:
        dialogText = AppLocalizations.of(context)!.vipDialogue5;
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
  
  Widget _buildUnlockOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled
                  ? [
                      Colors.grey.shade900.withValues(alpha: 0.9),
                      Colors.black.withValues(alpha: 0.7),
                    ]
                  : [
                      Colors.grey.withValues(alpha: 0.1),
                      Colors.grey.withValues(alpha: 0.05),
                    ],
            ),
            border: Border.all(
              color: enabled ? color.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: enabled
                        ? [
                            color.withValues(alpha: 0.15),
                            color.withValues(alpha: 0.08),
                          ]
                        : [
                            Colors.grey.withValues(alpha: 0.1),
                            Colors.grey.withValues(alpha: 0.05),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: enabled ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: enabled ? color.withValues(alpha: 0.9) : Colors.grey,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled ? Colors.white : Colors.grey.shade400,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: enabled 
                            ? color.withValues(alpha: 0.8)
                            : Colors.grey.shade600,
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
                color: enabled ? color.withValues(alpha: 0.7) : Colors.grey.shade600,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}
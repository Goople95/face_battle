import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/ai_personality.dart';
import '../services/vip_unlock_service.dart';
import '../services/game_progress_service.dart';
import '../services/purchase_service.dart';
import '../services/analytics_service.dart';
import '../utils/ad_helper.dart';
import '../l10n/generated/app_localizations.dart';
import 'npc_avatar_widget.dart';

/// VIP解锁对话框
class VIPUnlockDialog extends StatefulWidget {
  final AIPersonality character;
  
  const VIPUnlockDialog({super.key, required this.character});
  
  @override
  State<VIPUnlockDialog> createState() => _VIPUnlockDialogState();
}

class _VIPUnlockDialogState extends State<VIPUnlockDialog> {
  final VIPUnlockService _vipService = VIPUnlockService();
  final PurchaseService _purchaseService = PurchaseService();
  int _userGems = 0;
  ProductDetails? _product;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserGems();
    _loadProductInfo();
    
    // 记录对话框显示事件
    AnalyticsService().logDialogShow(
      dialogName: 'vip_unlock_dialog',
      params: {
        'npc_id': widget.character.id,
        'npc_name': widget.character.name,
      },
    );
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black87,
              Colors.grey.shade900,
            ],
          ),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          children: [
            // 主要内容
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                
                // 角色头像 - 增大并添加装饰
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: NPCAvatarWidget(
                  personality: widget.character,
                  size: 120,
                  showBorder: false,
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // 角色名称和VIP标签在同一行
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Builder(
                  builder: (context) {
                    final locale = Localizations.localeOf(context);
                    final languageCode = locale.languageCode;
                    
                    // 处理中文的特殊情况
                    String localeCode = languageCode;
                    if (languageCode == 'zh') {
                      // 只支持繁体中文
                      localeCode = 'zh_TW';
                    }
                    
                    return Text(
                      widget.character.getLocalizedName(localeCode),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                // VIP标志移到名字旁边
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 解锁说明标题
            Text(
              AppLocalizations.of(context)!.unlockVIPCharacter,
              style: TextStyle(
                color: Colors.amber.shade300,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // 解锁选项
            Column(
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
              ],
            ),
            const SizedBox(height: 20),
            
            // 取消按钮 - 更精致的样式
            const SizedBox(height: 8),
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
              ],
            ),
            // 关闭按钮
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey.shade400,
                    size: 18,
                  ),
                ),
                onPressed: () {
                  AnalyticsService().logDialogAction(
                    dialogName: 'vip_unlock_dialog',
                    action: 'close',
                    params: {
                      'npc_id': widget.character.id,
                    },
                  );
                  Navigator.of(context).pop(false);
                },
              ),
            ),
          ],
        ),
      ),
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
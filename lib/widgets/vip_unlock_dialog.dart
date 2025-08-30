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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade900,
              Colors.deepPurple.shade900,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // VIP标志
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'VIP',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // 角色头像
            SizedBox(
              width: 100,
              height: 100,
              child: ClipOval(
                child: NPCAvatarWidget(
                  personality: widget.character,
                  size: 100,
                  showBorder: false,
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // 角色名称
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            
            // 角色描述
            Builder(
              builder: (context) {
                final locale = Localizations.localeOf(context);
                final languageCode = locale.languageCode;
                final countryCode = locale.countryCode;
                
                // 处理中文的特殊情况
                String localeCode = languageCode;
                if (languageCode == 'zh') {
                  // 只支持繁体中文
                  localeCode = 'zh_TW';
                }
                
                return Text(
                  widget.character.getLocalizedDescription(localeCode),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
            const SizedBox(height: 15),
            
const SizedBox(height: 20),
            
            // 解锁说明
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.unlockVIPCharacter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.chooseUnlockMethod,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // 解锁选项
            Column(
              children: [
                // 看广告临时解锁
                _buildUnlockOption(
                  icon: Icons.play_circle_outline,
                  title: AppLocalizations.of(context)!.watchAdUnlock,
                  subtitle: AppLocalizations.of(context)!.freePlayOneHour,
                  color: Colors.blue,
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
                  color: Colors.amber,
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
              child: Text(
                AppLocalizations.of(context)!.laterDecide,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
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
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? color.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: enabled ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled ? color : Colors.grey,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: enabled ? Colors.white : Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: enabled ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: enabled ? color : Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
}
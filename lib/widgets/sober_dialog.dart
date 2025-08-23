import 'package:flutter/material.dart';
import '../models/drinking_state.dart';
import '../l10n/generated/app_localizations.dart';

/// 醒酒选项对话框
class SoberDialog extends StatelessWidget {
  final DrinkingState drinkingState;
  final VoidCallback onWatchAd;
  final VoidCallback onUsePotion;
  final VoidCallback onCancel;
  
  const SoberDialog({
    super.key,
    required this.drinkingState,
    required this.onWatchAd,
    required this.onUsePotion,
    required this.onCancel,
  });
  
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
              Colors.red.shade900,
              Colors.orange.shade900,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            const Text(
              '🥴 醉酒警告！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            
            // 状态说明
            Text(
              '你已经喝了${drinkingState.drinksConsumed}杯酒',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            Text(
              drinkingState.statusDescription,
              style: TextStyle(
                fontSize: 16,
                color: Colors.yellow.shade300,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // 醉酒提示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.drunkStatus,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.soberTip,
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // 醒酒选项
            Column(
              children: [
                // 使用醒酒药水
                if (drinkingState.soberPotions > 0)
                  _buildOption(
                    icon: Icons.medication_liquid,
                    title: AppLocalizations.of(context)!.useSoberPotion,
                    subtitle: '剩余 ${drinkingState.soberPotions} 瓶',
                    color: Colors.green,
                    onTap: () {
                      Navigator.of(context).pop();
                      // 延迟执行以确保对话框关闭后再执行
                      Future.delayed(const Duration(milliseconds: 100), () {
                        onUsePotion();
                      });
                    },
                  ),
                
                const SizedBox(height: 10),
                
                // 看广告醒酒
                _buildOption(
                  icon: Icons.play_circle_outline,
                  title: AppLocalizations.of(context)!.watchAdToSoberTitle,
                  subtitle: '免费，立即完全清醒',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.of(context).pop();
                    // 延迟执行以确保对话框关闭后再显示广告
                    Future.delayed(const Duration(milliseconds: 100), () {
                      onWatchAd();
                    });
                  },
                ),
                
                const SizedBox(height: 10),
                
                // 放弃（返回主页）
                _buildOption(
                  icon: Icons.home,
                  title: '回家休息',
                  subtitle: AppLocalizations.of(context)!.returnToHome,
                  color: Colors.grey,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // 返回主页
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
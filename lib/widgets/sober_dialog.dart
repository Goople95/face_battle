import 'package:flutter/material.dart';
import '../models/drinking_state.dart';

/// 醒酒选项对话框
class SoberDialog extends StatelessWidget {
  final DrinkingState drinkingState;
  final VoidCallback onWatchAd;
  final VoidCallback onUsePotion;
  final VoidCallback onCancel;
  
  const SoberDialog({
    Key? key,
    required this.drinkingState,
    required this.onWatchAd,
    required this.onUsePotion,
    required this.onCancel,
  }) : super(key: key);
  
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
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Text(
                    '你已经烂醉如泥，无法继续游戏！\n需要醒酒才能继续',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '💡 提示：10分钟自然醒酒1杯，1小时完全恢复',
                    style: TextStyle(
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
                    title: '使用醒酒药水',
                    subtitle: '剩余 ${drinkingState.soberPotions} 瓶',
                    color: Colors.green,
                    onTap: () {
                      onUsePotion();
                      Navigator.of(context).pop();
                    },
                  ),
                
                const SizedBox(height: 10),
                
                // 看广告醒酒
                _buildOption(
                  icon: Icons.play_circle_outline,
                  title: '观看广告醒酒',
                  subtitle: '免费，立即完全清醒',
                  color: Colors.blue,
                  onTap: () {
                    onWatchAd();
                    Navigator.of(context).pop();
                  },
                ),
                
                const SizedBox(height: 10),
                
                // 放弃（返回主页）
                _buildOption(
                  icon: Icons.home,
                  title: '回家休息',
                  subtitle: '返回主页，自然醒酒',
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
          color: color.withOpacity(0.2),
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
                      color: color.withOpacity(0.8),
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
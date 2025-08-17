import 'package:flutter/material.dart';
import '../models/ai_personality.dart';
import '../services/vip_unlock_service.dart';
import '../utils/ad_helper.dart';
import '../config/character_assets.dart';

/// VIP解锁对话框
class VIPUnlockDialog extends StatefulWidget {
  final AIPersonality character;
  
  const VIPUnlockDialog({Key? key, required this.character}) : super(key: key);
  
  @override
  State<VIPUnlockDialog> createState() => _VIPUnlockDialogState();
}

class _VIPUnlockDialogState extends State<VIPUnlockDialog> {
  final VIPUnlockService _vipService = VIPUnlockService();
  int _userGems = 0;
  
  @override
  void initState() {
    super.initState();
    _loadUserGems();
  }
  
  Future<void> _loadUserGems() async {
    int gems = await _vipService.getUserGems();
    setState(() {
      _userGems = gems;
    });
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
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(CharacterAssets.getFullAvatarPath(widget.character.avatarPath)),
            ),
            const SizedBox(height: 10),
            
            // 角色名称
            Text(
              widget.character.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // 角色描述
            Text(
              widget.character.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            
            // 难度标签
            if (widget.character.difficulty != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(int.tryParse(widget.character.difficulty!) ?? 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getDifficultyText(int.tryParse(widget.character.difficulty!) ?? 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            
            // 解锁说明
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Text(
                    '解锁VIP角色',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '选择以下方式解锁此VIP角色',
                    style: TextStyle(
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
                  title: '观看广告',
                  subtitle: '免费游玩1小时',
                  color: Colors.blue,
                  onTap: () async {
                    Navigator.of(context).pop(false);
                    await Future.delayed(const Duration(milliseconds: 100));
                    
                    AdHelper.showRewardedAdWithLoading(
                      context: context,
                      onRewarded: (reward) async {
                        await _vipService.temporaryUnlock(widget.character.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✨ 已临时解锁${widget.character.name}，有效期1小时'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      loadingText: '正在加载广告...',
                    );
                  },
                ),
                
                const SizedBox(height: 10),
                
                // 永久解锁
                _buildUnlockOption(
                  icon: Icons.diamond,
                  title: '永久解锁',
                  subtitle: '${VIPUnlockService.vipUnlockPrice}宝石 (你有$_userGems宝石)',
                  color: _userGems >= VIPUnlockService.vipUnlockPrice
                      ? Colors.amber
                      : Colors.grey,
                  enabled: _userGems >= VIPUnlockService.vipUnlockPrice,
                  onTap: () async {
                    if (_userGems >= VIPUnlockService.vipUnlockPrice) {
                      bool success = await _vipService.permanentUnlock(widget.character.id);
                      if (success && context.mounted) {
                        Navigator.of(context).pop(true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 成功永久解锁${widget.character.name}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 取消按钮
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                '稍后再说',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
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
            color: enabled ? color.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: enabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
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
  
  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1:
        return '简单';
      case 2:
        return '中等';
      case 3:
        return '困难';
      default:
        return '未知';
    }
  }
}
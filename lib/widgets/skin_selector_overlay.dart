import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import '../models/npc_skin.dart';
import '../services/npc_skin_service.dart';
import '../services/intimacy_service.dart';
import '../widgets/npc_image_widget.dart';
import '../utils/logger_utils.dart';
import '../l10n/generated/app_localizations.dart';

/// 轻奢风格的皮肤选择悬浮层
class SkinSelectorOverlay extends StatefulWidget {
  final String npcId;
  final String npcName;
  final Offset anchorPosition;
  final VoidCallback onClose;
  
  const SkinSelectorOverlay({
    super.key,
    required this.npcId,
    required this.npcName,
    required this.anchorPosition,
    required this.onClose,
  });
  
  @override
  State<SkinSelectorOverlay> createState() => _SkinSelectorOverlayState();
}

class _SkinSelectorOverlayState extends State<SkinSelectorOverlay> 
    with SingleTickerProviderStateMixin {
  List<SkinInfo> _skins = [];
  int? _selectedSkinId;
  String? _unlockHint;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _loadSkins();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSkins() async {
    try {
      _skins = NPCSkinService.instance.getNPCSkins(widget.npcId);
      final selected = _skins.firstWhere(
        (s) => s.isSelected,
        orElse: () => _skins.first,
      );
      _selectedSkinId = selected.skin.id;
      setState(() {});
    } catch (e) {
      LoggerUtils.error('加載皮膚列表失敗: $e');
    }
  }
  
  Future<void> _onConfirm() async {
    if (_selectedSkinId == null) return;
    
    final success = await NPCSkinService.instance.setSelectedSkin(
      widget.npcId,
      _selectedSkinId!,
    );
    
    if (success) {
      LoggerUtils.info('已選擇皮膚: NPC=${widget.npcId}, Skin=$_selectedSkinId');
      _close();
    }
  }
  
  void _close() async {
    await _animationController.reverse();
    widget.onClose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final t = AppLocalizations.of(context)!;
    
    return GestureDetector(
      onTap: _close,
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 半透明背景
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
            
            // 皮肤选择卡片
            Positioned(
              top: widget.anchorPosition.dy + 40,
              right: 20,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.topRight,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 280,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.red.shade900.withValues(alpha: 0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.shade300.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 皮肤图片横向排列
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _skins.length,
                              itemBuilder: (context, index) {
                                final skinInfo = _skins[index];
                                final isSelected = skinInfo.skin.id == _selectedSkinId;
                                
                                return GestureDetector(
                                  onTap: () async {
                                    if (skinInfo.isUnlocked) {
                                      // 如果是已解锁的皮肤，直接切换
                                      if (!skinInfo.isSelected) {
                                        // 只有不是当前选中的皮肤才需要切换
                                        _selectedSkinId = skinInfo.skin.id;
                                        await _onConfirm();
                                      }
                                    } else {
                                      // 显示解锁条件
                                      _showUnlockHint(skinInfo, t);
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 10),
                                    width: 80,
                                    child: Stack(
                                      children: [
                                        // 皮肤图片
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                ? Colors.pink.shade300
                                                : Colors.transparent,
                                              width: 2,
                                            ),
                                            boxShadow: isSelected ? [
                                              BoxShadow(
                                                color: Colors.pink.withValues(alpha: 0.5),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              ),
                                            ] : null,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Stack(
                                              children: [
                                                NPCImageWidget(
                                                  npcId: widget.npcId,
                                                  fileName: '1.jpg',
                                                  skinId: skinInfo.skin.id,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                                
                                                // 未解锁遮罩
                                                if (!skinInfo.isUnlocked)
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                        colors: [
                                                          Colors.black.withValues(alpha: 0.4),
                                                          Colors.black.withValues(alpha: 0.8),
                                                        ],
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        _getUnlockIcon(skinInfo.skin.unlockCondition),
                                                        style: const TextStyle(fontSize: 24),
                                                      ),
                                                    ),
                                                  ),
                                                
                                                // 已装备标记
                                                if (skinInfo.isSelected)
                                                  Positioned(
                                                    top: 4,
                                                    right: 4,
                                                    child: Container(
                                                      padding: EdgeInsets.all(4.r),
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            Colors.pink.shade400,
                                                            Colors.purple.shade400,
                                                          ],
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.check,
                                                        color: Colors.white,
                                                        size: 12,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          // 解锁条件提示
                          if (_unlockHint != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  _unlockHint!,
                                  key: ValueKey(_unlockHint),
                                  style: TextStyle(
                                    color: Colors.amber.shade300,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getUnlockIcon(UnlockCondition condition) {
    switch (condition.type) {
      case 'intimacy':
        return '🔒';
      case 'payment':
      case 'vip_exclusive':
        return '💎';
      default:
        return '🔒';
    }
  }
  
  void _showUnlockHint(SkinInfo skinInfo, AppLocalizations t) {
    final currentIntimacy = IntimacyService().getIntimacyLevel(widget.npcId);
    String hint = '';
    
    switch (skinInfo.skin.unlockCondition.type) {
      case 'intimacy':
        final level = skinInfo.skin.unlockCondition.level!;
        final needed = level - currentIntimacy;
        if (needed > 0) {
          hint = t.skinUnlockAtLevel(level, needed);
        } else {
          hint = t.skinUnlockAtLevel(level, 0);
        }
        break;
      case 'payment':
      case 'vip_exclusive':
        hint = t.skinUnlockWithGems;
        break;
      default:
        hint = t.skinCurrentlyUnavailable;
    }
    
    setState(() {
      _unlockHint = hint;
    });
    
    // 3秒后自动清除提示
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _unlockHint = null;
        });
      }
    });
  }
}
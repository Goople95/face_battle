import 'package:flutter/material.dart';
import '../models/npc_skin.dart';
import '../services/npc_skin_service.dart';
import '../services/intimacy_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/npc_image_widget.dart';
import '../utils/logger_utils.dart';

/// 皮膚選擇器對話框 - 簡化版UI
class SkinSelectorDialog extends StatefulWidget {
  final String npcId;
  final String npcName;
  
  const SkinSelectorDialog({
    super.key,
    required this.npcId,
    required this.npcName,
  });
  
  @override
  State<SkinSelectorDialog> createState() => _SkinSelectorDialogState();
}

class _SkinSelectorDialogState extends State<SkinSelectorDialog> {
  List<SkinInfo> _skins = [];
  int? _selectedSkinId;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSkins();
  }
  
  Future<void> _loadSkins() async {
    try {
      // 獲取皮膚列表
      _skins = NPCSkinService.instance.getNPCSkins(widget.npcId);
      
      // 找到當前選中的皮膚
      final selected = _skins.firstWhere(
        (s) => s.isSelected,
        orElse: () => _skins.first,
      );
      _selectedSkinId = selected.skin.id;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      LoggerUtils.error('加載皮膚列表失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final currentLang = Localizations.localeOf(context).languageCode;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade900.withValues(alpha: 0.95),
              Colors.purple.shade900.withValues(alpha: 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.pink.shade300.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題欄
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.pink.shade300.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // NPC頭像
                  NPCCircleAvatar(
                    npcId: widget.npcId,
                    radius: 25,
                  ),
                  const SizedBox(width: 12),
                  // 標題
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.npcName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '👙 ${currentLang == 'zh' ? '换装' : 'Wardrobe'}',
                          style: TextStyle(
                            color: Colors.pink.shade200,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 關閉按鈕
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.pink.shade200),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // 皮膚網格（3列）
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(50),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _skins.length,
                  itemBuilder: (context, index) {
                    final skinInfo = _skins[index];
                    return _buildSkinGridItem(skinInfo, currentLang);
                  },
                ),
              ),
            
            // 底部按鈕
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.pink.shade300.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 返回按鈕
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.pink.shade200,
                    ),
                    child: Text(
                      currentLang == 'zh' ? '返回' : 'Back',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 換裝按鈕
                  ElevatedButton(
                    onPressed: (_selectedSkinId != null && 
                             _skins.any((s) => s.skin.id == _selectedSkinId && s.isUnlocked))
                        ? () => _onConfirm()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[800]?.withValues(alpha: 0.3),
                      disabledForegroundColor: Colors.white30,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shadowColor: Colors.pink,
                      elevation: 0,
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return Colors.grey[800]?.withValues(alpha: 0.3);
                        }
                        return null;
                      }),
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.pressed)) {
                          return Colors.pink.withValues(alpha: 0.2);
                        }
                        return Colors.pink.withValues(alpha: 0.1);
                      }),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: (_selectedSkinId != null && 
                                 _skins.any((s) => s.skin.id == _selectedSkinId && s.isUnlocked))
                            ? LinearGradient(
                                colors: [
                                  Colors.pink.shade400,
                                  Colors.purple.shade400,
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        currentLang == 'zh' ? '💋 換上' : '💋 Wear',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
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
  
  Widget _buildSkinGridItem(SkinInfo skinInfo, String lang) {
    final skin = skinInfo.skin;
    final isSelected = skin.id == _selectedSkinId;
    final currentIntimacy = IntimacyService().getIntimacyLevel(widget.npcId);
    
    return Tooltip(
      message: _getTooltipMessage(skinInfo, lang, currentIntimacy),
      preferBelow: false,
      verticalOffset: 20,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
      child: GestureDetector(
        onTap: skinInfo.isUnlocked 
          ? () => setState(() => _selectedSkinId = skin.id)
          : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                ? Colors.pink.shade300
                : skinInfo.isUnlocked 
                  ? Colors.pink.shade200.withValues(alpha: 0.3)
                  : Colors.white12,
              width: isSelected ? 3 : 1.5,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.pink.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ] : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              children: [
                // 背景圖片
                NPCImageWidget(
                  npcId: widget.npcId,
                  fileName: '1.jpg',
                  skinId: skin.id,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
                
                // 未解鎖遮罩
                if (!skinInfo.isUnlocked)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getUnlockIcon(skin.unlockCondition),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                
                
                // 已裝備標識
                if (skinInfo.isSelected)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.pink.shade400,
                            Colors.purple.shade400,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                
                // 選中框
                if (isSelected && !skinInfo.isSelected)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: Colors.pink.shade300.withValues(alpha: 0.4),
                        width: 4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Tooltip信息
  String _getTooltipMessage(SkinInfo skinInfo, String lang, int currentIntimacy) {
    final skin = skinInfo.skin;
    String message = '${skin.getLocalizedName(lang)}\n\n';
    
    if (skinInfo.isSelected) {
      message += lang == 'zh' ? '✅ 當前造型' : '✅ Currently Wearing';
    } else if (skinInfo.isUnlocked) {
      message += lang == 'zh' ? '🎭 點擊選擇此造型' : '🎭 Click to select this style';
    } else {
      switch (skin.unlockCondition.type) {
        case 'intimacy':
          final needed = skin.unlockCondition.level! - currentIntimacy;
          message += lang == 'zh' 
            ? '🔒 需要親密度等級 ${skin.unlockCondition.level}\n(還差 $needed 級)'
            : '🔒 Requires intimacy level ${skin.unlockCondition.level}\n($needed more levels needed)';
          break;
        case 'payment':
        case 'vip_exclusive':
          message += lang == 'zh' 
            ? '💎 使用寶石解鎖此造型'
            : '💎 Use gems to unlock this style';
          break;
        default:
          message += lang == 'zh' ? '🔒 未解鎖' : '🔒 Locked';
      }
    }
    
    return message;
  }
  
  // 解鎖圖標
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
  
  // 解鎖短文本
  String _getUnlockShortText(UnlockCondition condition, String lang) {
    switch (condition.type) {
      case 'intimacy':
        return lang == 'zh' 
          ? 'Lv.${condition.level}'
          : 'Lv.${condition.level}';
      case 'payment':
      case 'vip_exclusive':
        return lang == 'zh' ? '寶石' : 'Gems';
      default:
        return '';
    }
  }
  
  Future<void> _onConfirm() async {
    if (_selectedSkinId == null) return;
    
    // 保存選擇的皮膚
    final success = await NPCSkinService.instance.setSelectedSkin(
      widget.npcId,
      _selectedSkinId!,
    );
    
    if (success) {
      LoggerUtils.info('已選擇皮膚: NPC=${widget.npcId}, Skin=$_selectedSkinId');
      if (mounted) {
        Navigator.of(context).pop(true);  // 返回true表示有更改
      }
    } else {
      LoggerUtils.error('選擇皮膚失敗');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.skinSelectFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
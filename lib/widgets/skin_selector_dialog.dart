import 'package:flutter/material.dart';
import '../models/npc_skin.dart';
import '../services/npc_skin_service.dart';
import '../services/intimacy_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/npc_image_widget.dart';
import '../utils/logger_utils.dart';

/// 皮膚選擇器對話框
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
          color: Colors.black.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white24,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題欄
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white24,
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
                          'Skin Selector',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 關閉按鈕
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // 皮膚列表
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
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _skins.length,
                  itemBuilder: (context, index) {
                    final skinInfo = _skins[index];
                    return _buildSkinItem(skinInfo, currentLang, t);
                  },
                ),
              ),
            
            // 底部按鈕
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white24,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 取消按鈕
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      t?.cancel ?? 'Cancel',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 確認按鈕
                  ElevatedButton(
                    onPressed: (_selectedSkinId != null && 
                             _skins.any((s) => s.skin.id == _selectedSkinId && s.isUnlocked))
                        ? () => _onConfirm()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey[800],
                    ),
                    child: Text(
                      t?.confirm ?? 'Confirm',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
  
  Widget _buildSkinItem(SkinInfo skinInfo, String lang, AppLocalizations? t) {
    final skin = skinInfo.skin;
    final isSelected = skin.id == _selectedSkinId;
    final currentIntimacy = IntimacyService().getIntimacyLevel(widget.npcId);
    
    return GestureDetector(
      onTap: skinInfo.isUnlocked 
        ? () => setState(() => _selectedSkinId = skin.id)
        : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
            ? Colors.amber.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? Colors.amber
              : skinInfo.isUnlocked 
                ? Colors.white24
                : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 皮膚預覽圖
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white24,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Stack(
                  children: [
                    // 預覽圖（未來可以根據皮膚ID顯示不同圖片）
                    NPCImageWidget(
                      npcId: widget.npcId,
                      fileName: '1.jpg',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                    // 鎖定遮罩
                    if (!skinInfo.isUnlocked)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Icon(
                            Icons.lock,
                            color: Colors.white54,
                            size: 30,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 皮膚信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 皮膚名稱
                  Row(
                    children: [
                      Text(
                        skin.getLocalizedName(lang),
                        style: TextStyle(
                          color: skinInfo.isUnlocked 
                            ? Colors.white
                            : Colors.white54,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (skinInfo.isSelected)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Equipped',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 皮膚描述
                  Text(
                    skin.getLocalizedDescription(lang),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                  // 解鎖條件
                  if (!skinInfo.isUnlocked && skin.unlockCondition.description != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getUnlockText(skin.unlockCondition, lang, currentIntimacy),
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // 選擇指示器
            if (skinInfo.isUnlocked)
              Radio<int>(
                value: skin.id,
                groupValue: _selectedSkinId,
                onChanged: (value) => setState(() => _selectedSkinId = value),
                activeColor: Colors.amber,
              ),
          ],
        ),
      ),
    );
  }
  
  String _getUnlockText(UnlockCondition condition, String lang, int currentIntimacy) {
    final desc = condition.getLocalizedDescription(lang);
    
    // 如果是親密度條件，顯示進度
    if (condition.type == 'intimacy' && condition.level != null) {
      return '$desc ($currentIntimacy/${condition.level})';
    }
    
    return desc;
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
          const SnackBar(
            content: Text('Failed to select skin'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
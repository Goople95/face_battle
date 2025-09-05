import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import '../services/cloud_npc_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/logger_utils.dart';

/// NPC资源管理器组件
class NPCManagerWidget extends StatefulWidget {
  final Function(NPCConfig) onNPCSelected;
  final String currentNPCId;
  
  const NPCManagerWidget({
    super.key,
    required this.onNPCSelected,
    required this.currentNPCId,
  });

  @override
  State<NPCManagerWidget> createState() => _NPCManagerWidgetState();
}

class _NPCManagerWidgetState extends State<NPCManagerWidget> {
  List<NPCConfig> _npcConfigs = [];
  bool _isLoading = true;
  Map<String, double> _downloadProgress = {};
  Set<String> _downloadingNPCs = {};
  
  @override
  void initState() {
    super.initState();
    _loadNPCConfigs();
  }
  
  /// 加载NPC配置
  Future<void> _loadNPCConfigs() async {
    try {
      setState(() => _isLoading = true);
      
      // 获取NPC配置（优先云端，失败则本地）
      final configs = await CloudNPCService.fetchNPCConfigs();
      
      setState(() {
        _npcConfigs = configs;
        _isLoading = false;
      });
      
      // 后台检查更新
      CloudNPCService.checkForUpdates();
      
    } catch (e) {
      LoggerUtils.error('加载NPC配置失败: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.loadConfigFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// 下载NPC资源
  Future<void> _downloadNPC(NPCConfig npc) async {
    if (_downloadingNPCs.contains(npc.id)) return;
    
    setState(() {
      _downloadingNPCs.add(npc.id);
      _downloadProgress[npc.id] = 0.0;
    });
    
    try {
      await CloudNPCService.downloadNPCResources(
        npc.id,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress[npc.id] = progress;
            });
          }
        },
      );
      
      // 下载完成
      if (mounted) {
        setState(() {
          _downloadingNPCs.remove(npc.id);
          _downloadProgress.remove(npc.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.downloadComplete),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      LoggerUtils.error('下载NPC资源失败: $e');
      
      if (mounted) {
        setState(() {
          _downloadingNPCs.remove(npc.id);
          _downloadProgress.remove(npc.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.downloadFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode == 'zh' ? 'zh_TW' : locale.languageCode;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.purple.shade900,
            Colors.indigo.shade900,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.people_alt, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.selectNPC,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // NPC列表
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16.r),
                    itemCount: _npcConfigs.length,
                    itemBuilder: (context, index) {
                      final npc = _npcConfigs[index];
                      final isSelected = npc.id == widget.currentNPCId;
                      final isDownloading = _downloadingNPCs.contains(npc.id);
                      final downloadProgress = _downloadProgress[npc.id] ?? 0.0;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isSelected 
                            ? Colors.amber.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? Colors.amber : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: isDownloading ? null : () {
                            if (npc.isLocal) {
                              // 本地资源，直接选择
                              widget.onNPCSelected(npc);
                              Navigator.pop(context);
                            } else {
                              // 云端资源，需要先下载
                              _downloadNPC(npc);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.all(12.r),
                            child: Row(
                              children: [
                                // NPC头像
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: npc.isLocal
                                        ? Image.asset(
                                            '${npc.avatarPath}avatar.jpg',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stack) {
                                              return Container(
                                                color: Colors.grey,
                                                child: const Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              );
                                            },
                                          )
                                        : FutureBuilder<String>(
                                            future: CloudNPCService.getNPCResourcePath(
                                              npc.id,
                                              'avatar.jpg',
                                            ),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return Image.asset(
                                                  snapshot.data!,
                                                  fit: BoxFit.cover,
                                                );
                                              }
                                              return Container(
                                                color: Colors.grey,
                                                child: const Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // NPC信息
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            npc.getName(languageCode),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (npc.isVIP)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'VIP',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(width: 8),
                                          if (!npc.isLocal)
                                            Icon(
                                              Icons.cloud_download,
                                              color: Colors.blue.shade300,
                                              size: 16,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        npc.getDescription(languageCode),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (npc.country.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              color: Colors.white.withOpacity(0.5),
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              npc.country,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.5),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                
                                // 操作按钮/进度
                                if (isDownloading)
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          value: downloadProgress,
                                          color: Colors.amber,
                                          backgroundColor: Colors.white24,
                                        ),
                                        Text(
                                          '${(downloadProgress * 100).toInt()}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (isSelected)
                                  Container(
                                    padding: EdgeInsets.all(8.r),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  )
                                else if (!npc.isLocal)
                                  Container(
                                    padding: EdgeInsets.all(8.r),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.download,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // 底部提示
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.cloudNPCTip,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
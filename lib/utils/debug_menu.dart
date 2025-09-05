import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage_debug_tool.dart';
import '../utils/logger_utils.dart';

/// 调试菜单组件
/// 可以添加到任何页面的AppBar或Drawer中
class DebugMenu extends StatelessWidget {
  const DebugMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.bug_report),
      tooltip: '调试工具',
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view_storage',
          child: ListTile(
            leading: Icon(Icons.storage),
            title: Text('查看本地存储'),
            subtitle: Text('查看SharedPreferences数据'),
          ),
        ),
        const PopupMenuItem(
          value: 'print_storage',
          child: ListTile(
            leading: Icon(Icons.print),
            title: Text('打印到控制台'),
            subtitle: Text('在日志中输出所有数据'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'export_data',
          child: ListTile(
            leading: Icon(Icons.download),
            title: Text('导出数据'),
            subtitle: Text('导出为JSON格式'),
          ),
        ),
        const PopupMenuItem(
          value: 'storage_size',
          child: ListTile(
            leading: Icon(Icons.info),
            title: Text('存储统计'),
            subtitle: Text('查看存储大小和数量'),
          ),
        ),
        const PopupMenuItem(
          value: 'npc_cache',
          child: ListTile(
            leading: Icon(Icons.people_alt, color: Colors.blue),
            title: Text('NPC缓存'),
            subtitle: Text('查看NPC资源缓存详情'),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'clear_user_data',
          enabled: FirebaseAuth.instance.currentUser != null,
          child: ListTile(
            leading: const Icon(Icons.person_remove, color: Colors.orange),
            title: const Text('清除当前用户数据'),
            subtitle: Text(
              FirebaseAuth.instance.currentUser?.uid ?? '未登录',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
        const PopupMenuItem(
          value: 'clear_all',
          child: ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: Text('清除所有数据', style: TextStyle(color: Colors.red)),
            subtitle: Text('危险操作！'),
          ),
        ),
      ],
    );
  }

  void _handleMenuSelection(BuildContext context, String value) async {
    switch (value) {
      case 'view_storage':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LocalStorageDebugPage(),
          ),
        );
        break;
        
      case 'print_storage':
        await LocalStorageDebugTool.printAllData();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('数据已打印到控制台，请查看日志')),
          );
        }
        break;
        
      case 'export_data':
        final jsonString = await LocalStorageDebugTool.exportToJson();
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('导出的数据'),
              content: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonString,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // TODO: 实现复制到剪贴板
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('数据已复制到剪贴板')),
                    );
                  },
                  child: const Text('复制'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
              ],
            ),
          );
        }
        break;
        
      case 'storage_size':
        final data = await LocalStorageDebugTool.getAllLocalData();
        final size = await LocalStorageDebugTool.getStorageSize();
        final sizeText = _formatSize(size);
        
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('存储统计'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('数据条目: ${data.length} 个'),
                  const SizedBox(height: 8),
                  Text('总大小: $sizeText'),
                  const SizedBox(height: 16),
                  const Text('分类统计:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...LocalStorageDebugTool.categorizeData(data).entries.map(
                    (e) => Text('${e.key}: ${e.value.length} 个'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        }
        break;
        
      case 'npc_cache':
        final cacheInfo = await LocalStorageDebugTool.getNPCCacheInfo();
        if (context.mounted) {
          _showNPCCacheDialog(context, cacheInfo);
        }
        break;
        
      case 'clear_user_data':
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('用户未登录')),
          );
          return;
        }
        
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认清除'),
            content: Text('确定要清除用户 $userId 的所有本地数据吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('清除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        
        if (confirm == true) {
          await LocalStorageDebugTool.clearUserData(userId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('用户数据已清除')),
            );
          }
        }
        break;
        
      case 'clear_all':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('危险操作'),
            content: const Text(
              '确定要清除所有本地存储数据吗？\n'
              '这将删除所有用户的游戏进度、设置等数据！\n'
              '此操作不可恢复！',
              style: TextStyle(color: Colors.red),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确认清除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        
        if (confirm == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          LoggerUtils.info('已清除所有本地存储数据');
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('所有本地数据已清除'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
    }
  }
  
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  
  void _showNPCCacheDialog(BuildContext context, Map<String, dynamic> cacheInfo) {
    showDialog(
      context: context,
      builder: (context) => _NPCCacheDialog(initialCacheInfo: cacheInfo),
    );
  }
}

// NPC缓存对话框 - 改为StatefulWidget以支持刷新
class _NPCCacheDialog extends StatefulWidget {
  final Map<String, dynamic> initialCacheInfo;
  
  const _NPCCacheDialog({required this.initialCacheInfo});
  
  @override
  State<_NPCCacheDialog> createState() => _NPCCacheDialogState();
}

class _NPCCacheDialogState extends State<_NPCCacheDialog> {
  late Map<String, dynamic> cacheInfo;
  bool isLoading = false;
  
  @override
  void initState() {
    super.initState();
    cacheInfo = widget.initialCacheInfo;
  }
  
  // 刷新缓存信息
  Future<void> _refreshCacheInfo() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final newCacheInfo = await LocalStorageDebugTool.getNPCCacheInfo();
      if (mounted) {
        setState(() {
          cacheInfo = newCacheInfo;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  
  @override
  Widget build(BuildContext context) {
    final totalSize = cacheInfo['totalSizeBytes'] ?? 0;
    final npcCount = cacheInfo['npcCount'] ?? 0;
    final npcs = cacheInfo['npcs'] as Map<String, dynamic>? ?? {};
    
    return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.people_alt, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NPC缓存详情'),
                  Text(
                    '总大小: ${_formatSize(totalSize)} | 角色数: $npcCount',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 400, maxWidth: 500),
          child: isLoading 
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(40.r),
                  child: CircularProgressIndicator(),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (npcs.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.r),
                          child: Text('暂无缓存的NPC资源'),
                        ),
                      )
                    else
                  ...npcs.entries.map((entry) {
                    final npcId = entry.key;
                    final npcData = entry.value as Map<String, dynamic>;
                    final sizeBytes = npcData['sizeBytes'] ?? 0;
                    final fileCount = npcData['fileCount'] ?? 0;
                    final files = npcData['files'] as List<dynamic>? ?? [];
                    final lastAccessed = npcData['lastAccessed'] as String?;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            child: Text(
                              npcId.startsWith('0') ? npcId.substring(2, 4) : npcId.substring(0, 2),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            'NPC #$npcId',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('大小: ${_formatSize(sizeBytes)}'),
                              Text('文件数: $fileCount'),
                              if (lastAccessed != null)
                                Text(
                                  '最后访问: ${_formatLastAccessed(lastAccessed)}',
                                  style: TextStyle(fontSize: 11),
                                ),
                            ],
                          ),
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.r),
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '缓存文件列表:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // 按皮膚ID分組顯示文件
                                  ...() {
                                    // 將文件按皮膚ID分組
                                    final Map<String, List<String>> filesBySkin = {};
                                    
                                    for (final file in files) {
                                      final filePath = file.toString();
                                      final pathParts = filePath.split('/');
                                      
                                      String skinId = '1';  // 默認皮膚ID
                                      String fileName = pathParts.last;
                                      
                                      if (pathParts.length >= 2) {
                                        skinId = pathParts[pathParts.length - 2];
                                      }
                                      
                                      filesBySkin.putIfAbsent(skinId, () => []).add(fileName);
                                    }
                                    
                                    // 按皮膚ID排序並生成UI
                                    final sortedSkins = filesBySkin.keys.toList()..sort();
                                    final List<Widget> widgets = [];
                                    
                                    for (final skinId in sortedSkins) {
                                      // 添加皮膚標題
                                      widgets.add(
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 2),
                                          child: Text(
                                            '皮膚 $skinId:',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ),
                                      );
                                      
                                      // 添加該皮膚的文件列表
                                      for (final fileName in filesBySkin[skinId]!) {
                                        final fileType = _getFileType(fileName);
                                        widgets.add(
                                          Padding(
                                            padding: const EdgeInsets.only(left: 24, bottom: 2),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _getFileIcon(fileType),
                                                  size: 14,
                                                  color: _getFileColor(fileType),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  fileName,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                    
                                    return widgets;
                                  }(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        // 执行智能清理
                        await LocalStorageDebugTool.smartCleanNPCCache();
                        // 刷新缓存信息显示
                        await _refreshCacheInfo();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('NPC缓存已智能清理')),
                          );
                        }
                      },
                      icon: const Icon(Icons.cleaning_services, size: 16),
                      label: const Text('智能清理'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        LoggerUtils.info('点击清除全部按钮');
                        
                        // 清除所有NPC缓存
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认清除'),
                            content: const Text('确定要清除所有NPC缓存吗？'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  LoggerUtils.info('用户点击取消');
                                  Navigator.pop(context, false);
                                },
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () {
                                  LoggerUtils.info('用户点击确认清除');
                                  Navigator.pop(context, true);
                                },
                                child: const Text('清除', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        
                        LoggerUtils.info('对话框返回值: $confirm');
                        
                        if (confirm == true) {
                          if (!context.mounted) {
                            LoggerUtils.error('context已卸载，无法执行清除操作');
                            return;
                          }
                          
                          LoggerUtils.info('开始执行清除NPC缓存');
                          
                          try {
                            await LocalStorageDebugTool.clearAllNPCCache();
                            LoggerUtils.info('清除操作完成，开始刷新UI');
                            
                            // 刷新缓存信息显示
                            await _refreshCacheInfo();
                            LoggerUtils.info('UI刷新完成');
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('所有NPC缓存已清除')),
                              );
                            }
                          } catch (e) {
                            LoggerUtils.error('清除缓存时出错: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('清除失败: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } else {
                          LoggerUtils.info('用户取消清除NPC缓存');
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      label: const Text('清除全部', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
  
  String _formatLastAccessed(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays > 0) {
        return '${diff.inDays}天前';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}小时前';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return timestamp;
    }
  }
  
  String _getFileType(String fileName) {
    if (fileName.endsWith('.mp4')) return 'video';
    if (fileName.endsWith('.png') || fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) return 'image';
    if (fileName.endsWith('.json')) return 'json';
    return 'other';
  }
  
  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'video':
        return Icons.videocam;
      case 'image':
        return Icons.image;
      case 'json':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  Color _getFileColor(String fileType) {
    switch (fileType) {
      case 'video':
        return Colors.purple;
      case 'image':
        return Colors.green;
      case 'json':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

/// 快速调试按钮
/// 可以悬浮在任何页面上
class DebugFloatingButton extends StatelessWidget {
  final Widget child;
  final bool enabled;
  
  const DebugFloatingButton({
    Key? key,
    required this.child,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    
    return Stack(
      children: [
        child,
        Positioned(
          right: 16,
          bottom: 80,
          child: FloatingActionButton.small(
            heroTag: 'debug_fab',
            backgroundColor: Colors.orange,
            onPressed: () async {
              await LocalStorageDebugTool.printAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('调试信息已输出到控制台'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Icon(Icons.bug_report, size: 20),
          ),
        ),
      ],
    );
  }
}

/// 在开发环境中自动添加调试菜单
class DebugWrapper extends StatelessWidget {
  final Widget child;
  final bool showInRelease;
  
  const DebugWrapper({
    Key? key,
    required this.child,
    this.showInRelease = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 只在调试模式下显示，或者明确允许在发布版本显示
    const bool isDebugMode = !bool.fromEnvironment('dart.vm.product');
    
    if (!isDebugMode && !showInRelease) {
      return child;
    }
    
    return DebugFloatingButton(
      enabled: true,
      child: child,
    );
  }
}
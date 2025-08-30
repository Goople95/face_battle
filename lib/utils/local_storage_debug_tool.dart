import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/logger_utils.dart';
import '../services/cloud_npc_service.dart';

/// 本地存储调试工具
/// 用于读取和显示SharedPreferences中的所有数据
class LocalStorageDebugTool {
  
  /// 获取所有本地存储的数据
  static Future<Map<String, dynamic>> getAllLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> allData = {};
    
    // 获取所有的keys
    final keys = prefs.getKeys();
    LoggerUtils.info('本地存储共有 ${keys.length} 个键值对');
    
    for (String key in keys) {
      try {
        // 尝试不同类型的获取方法
        final value = prefs.get(key);
        
        if (value != null) {
          // 尝试解析JSON字符串
          if (value is String) {
            try {
              final jsonValue = jsonDecode(value);
              allData[key] = {
                'type': 'json',
                'raw': value,
                'parsed': jsonValue,
                'length': value.length,
              };
            } catch (e) {
              // 不是JSON，保存为普通字符串
              allData[key] = {
                'type': 'string',
                'value': value,
                'length': value.length,
              };
            }
          } else if (value is int) {
            allData[key] = {
              'type': 'int',
              'value': value,
            };
          } else if (value is double) {
            allData[key] = {
              'type': 'double',
              'value': value,
            };
          } else if (value is bool) {
            allData[key] = {
              'type': 'bool',
              'value': value,
            };
          } else if (value is List<String>) {
            allData[key] = {
              'type': 'stringList',
              'value': value,
              'count': value.length,
            };
          } else {
            allData[key] = {
              'type': 'unknown',
              'value': value.toString(),
            };
          }
        }
      } catch (e) {
        LoggerUtils.error('读取键 $key 时出错: $e');
        allData[key] = {
          'type': 'error',
          'error': e.toString(),
        };
      }
    }
    
    return allData;
  }
  
  /// 按类别整理数据
  static Map<String, List<MapEntry<String, dynamic>>> categorizeData(Map<String, dynamic> allData) {
    final Map<String, List<MapEntry<String, dynamic>>> categorized = {
      '游戏进度': [],
      '用户设置': [],
      'VIP解锁': [],
      '饮酒状态': [],
      'NPC解锁': [],
      '其他': [],
    };
    
    for (var entry in allData.entries) {
      final key = entry.key;
      
      if (key.contains('game_progress') || key.contains('unified_game_progress')) {
        categorized['游戏进度']!.add(entry);
      } else if (key.contains('vip_unlocked') || key.contains('vip_temp_unlock')) {
        categorized['VIP解锁']!.add(entry);
      } else if (key.contains('drinking_state')) {
        categorized['饮酒状态']!.add(entry);
      } else if (key.contains('npc_unlock')) {
        categorized['NPC解锁']!.add(entry);
      } else if (key.contains('user_') || key.contains('settings')) {
        categorized['用户设置']!.add(entry);
      } else {
        categorized['其他']!.add(entry);
      }
    }
    
    return categorized;
  }
  
  /// 打印所有数据到控制台
  static Future<void> printAllData() async {
    final allData = await getAllLocalData();
    final categorized = categorizeData(allData);
    
    LoggerUtils.info('========== 本地存储数据调试信息 ==========');
    LoggerUtils.info('总计: ${allData.length} 个键值对');
    LoggerUtils.info('');
    
    for (var category in categorized.entries) {
      if (category.value.isEmpty) continue;
      
      LoggerUtils.info('【${category.key}】(${category.value.length}个)');
      LoggerUtils.info('----------------------------------------');
      
      for (var item in category.value) {
        final key = item.key;
        final data = item.value as Map<String, dynamic>;
        final type = data['type'];
        
        LoggerUtils.info('键名: $key');
        LoggerUtils.info('类型: $type');
        
        if (type == 'json') {
          LoggerUtils.info('原始长度: ${data['length']} 字符');
          LoggerUtils.info('解析后:');
          final parsed = data['parsed'];
          if (parsed is Map) {
            parsed.forEach((k, v) {
              LoggerUtils.info('  $k: $v');
            });
          } else {
            LoggerUtils.info('  $parsed');
          }
        } else if (type == 'stringList') {
          LoggerUtils.info('数量: ${data['count']}');
          LoggerUtils.info('值: ${data['value']}');
        } else {
          LoggerUtils.info('值: ${data['value']}');
        }
        
        LoggerUtils.info('');
      }
      
      LoggerUtils.info('');
    }
    
    LoggerUtils.info('========== 调试信息结束 ==========');
  }
  
  /// 清除特定用户的所有数据
  static Future<void> clearUserData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    int count = 0;
    
    for (String key in keys) {
      if (key.contains(userId)) {
        await prefs.remove(key);
        count++;
        LoggerUtils.info('删除: $key');
      }
    }
    
    LoggerUtils.info('共删除 $count 个与用户 $userId 相关的键值对');
  }
  
  /// 获取存储大小估算（字节）
  static Future<int> getStorageSize() async {
    final allData = await getAllLocalData();
    int totalSize = 0;
    
    for (var entry in allData.entries) {
      // 键的大小
      totalSize += entry.key.length * 2; // UTF-16编码
      
      // 值的大小
      final data = entry.value as Map<String, dynamic>;
      if (data['type'] == 'string' || data['type'] == 'json') {
        totalSize += (data['length'] as int? ?? 0) * 2;
      } else if (data['type'] == 'int' || data['type'] == 'double') {
        totalSize += 8; // 64位数字
      } else if (data['type'] == 'bool') {
        totalSize += 1;
      } else if (data['type'] == 'stringList') {
        final list = data['value'] as List<String>;
        for (var item in list) {
          totalSize += item.length * 2;
        }
      }
    }
    
    return totalSize;
  }
  
  /// 导出所有数据为JSON字符串
  static Future<String> exportToJson() async {
    final allData = await getAllLocalData();
    final exportData = <String, dynamic>{};
    
    for (var entry in allData.entries) {
      final data = entry.value as Map<String, dynamic>;
      if (data['type'] == 'json') {
        exportData[entry.key] = data['parsed'];
      } else if (data['type'] != 'error') {
        exportData[entry.key] = data['value'];
      }
    }
    
    // 添加导出元数据
    final metadata = {
      '_metadata': {
        'exportTime': DateTime.now().toIso8601String(),
        'totalEntries': allData.length,
        'appName': 'Face Battle',
        'dataVersion': '1.0',
      }
    };
    
    return const JsonEncoder.withIndent('  ').convert({...metadata, ...exportData});
  }
  
  /// 保存JSON到文件并分享
  static Future<void> saveAndShareJson(BuildContext context) async {
    try {
      // 获取JSON数据
      final jsonString = await exportToJson();
      
      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      
      // 创建文件名（包含时间戳）
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);
      final fileName = 'face_battle_debug_$timestamp.json';
      
      // 创建文件
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);
      
      LoggerUtils.info('调试数据已保存到: ${file.path}');
      
      // 使用share_plus分享文件
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Face Battle 调试数据',
        text: 'Face Battle 调试数据导出\n时间: $timestamp\n数据量: ${jsonString.length} 字符',
      );
      
      if (context.mounted) {
        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文件已成功分享')),
          );
        }
      }
    } catch (e) {
      LoggerUtils.error('保存或分享文件失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// 复制到剪贴板
  static Future<void> copyToClipboard(String text, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制到剪贴板')),
      );
    }
  }
  
  /// 获取NPC缓存详细信息
  static Future<Map<String, dynamic>> getNPCCacheInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final npcsDir = Directory('${appDir.path}/npcs');
      
      if (!await npcsDir.exists()) {
        return {
          'totalSize': 0,
          'totalSizeMB': 0.0,
          'npcCount': 0,
          'npcs': [],
        };
      }
      
      final List<Map<String, dynamic>> npcList = [];
      int totalSize = 0;
      
      await for (final entity in npcsDir.list()) {
        if (entity is Directory) {
          final npcId = entity.path.split(Platform.pathSeparator).last;
          final stat = await entity.stat();
          
          // 计算文件夹大小和文件列表
          int folderSize = 0;
          final List<Map<String, dynamic>> files = [];
          
          await for (final file in entity.list(recursive: true)) {
            if (file is File) {
              final fileSize = await file.length();
              folderSize += fileSize;
              
              final fileName = file.path.split(Platform.pathSeparator).last;
              files.add({
                'name': fileName,
                'size': fileSize,
                'sizeText': _formatFileSize(fileSize),
                'type': _getFileType(fileName),
              });
            }
          }
          
          totalSize += folderSize;
          
          npcList.add({
            'id': npcId,
            'path': entity.path,
            'size': folderSize,
            'sizeText': _formatFileSize(folderSize),
            'sizeMB': folderSize / (1024 * 1024),
            'lastAccessed': stat.accessed.toIso8601String(),
            'daysSinceAccess': DateTime.now().difference(stat.accessed).inDays,
            'fileCount': files.length,
            'files': files,
          });
        }
      }
      
      // 按大小排序
      npcList.sort((a, b) => (b['size'] as int).compareTo(a['size'] as int));
      
      return {
        'totalSize': totalSize,
        'totalSizeMB': totalSize / (1024 * 1024),
        'totalSizeText': _formatFileSize(totalSize),
        'npcCount': npcList.length,
        'npcs': npcList,
        'cacheDir': npcsDir.path,
      };
    } catch (e) {
      LoggerUtils.error('获取NPC缓存信息失败: $e');
      return {
        'error': e.toString(),
        'totalSize': 0,
        'totalSizeMB': 0.0,
        'npcCount': 0,
        'npcs': [],
      };
    }
  }
  
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  static String _getFileType(String fileName) {
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png')) {
      return '图片';
    } else if (fileName.endsWith('.mp4')) {
      return '视频';
    } else if (fileName.endsWith('.json')) {
      return '配置';
    }
    return '其他';
  }
  
  /// 智能清理NPC缓存
  static Future<void> smartCleanNPCCache() async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final npcCacheDir = Directory('${cacheDir.path}/npcs');
      
      if (!await npcCacheDir.exists()) {
        LoggerUtils.info('NPC缓存目录不存在，无需清理');
        return;
      }
      
      // 调用CloudNPCService的智能清理方法
      await CloudNPCService.smartCleanCache(
        maxCacheSizeMB: 300.0,  // 清理到300MB以下
        maxCacheDays: 14,       // 清理14天未使用的
        minKeepNPCs: 3,         // 至少保留3个最近使用的
      );
      
      LoggerUtils.info('NPC缓存智能清理完成');
    } catch (e) {
      LoggerUtils.error('智能清理NPC缓存失败: $e');
    }
  }
  
  /// 清除所有NPC缓存
  static Future<void> clearAllNPCCache() async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final npcCacheDir = Directory('${cacheDir.path}/npcs');
      
      if (await npcCacheDir.exists()) {
        await npcCacheDir.delete(recursive: true);
        LoggerUtils.info('已清除所有NPC缓存');
      }
    } catch (e) {
      LoggerUtils.error('清除NPC缓存失败: $e');
    }
  }
  
  /// 从JSON字符串导入数据
  static Future<bool> importFromJson(String jsonString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = jsonDecode(jsonString);
      
      for (var entry in data.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is List) {
          final stringList = value.map((e) => e.toString()).toList();
          await prefs.setStringList(key, stringList);
        } else if (value is Map) {
          // 将Map转换为JSON字符串存储
          await prefs.setString(key, jsonEncode(value));
        }
      }
      
      LoggerUtils.info('成功导入 ${data.length} 个键值对');
      return true;
    } catch (e) {
      LoggerUtils.error('导入失败: $e');
      return false;
    }
  }
}

/// 调试页面Widget
class LocalStorageDebugPage extends StatefulWidget {
  const LocalStorageDebugPage({Key? key}) : super(key: key);

  @override
  State<LocalStorageDebugPage> createState() => _LocalStorageDebugPageState();
}

class _LocalStorageDebugPageState extends State<LocalStorageDebugPage> {
  Map<String, dynamic> _data = {};
  Map<String, List<MapEntry<String, dynamic>>> _categorizedData = {};
  bool _isLoading = true;
  int _storageSize = 0;
  String _selectedCategory = '全部';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final data = await LocalStorageDebugTool.getAllLocalData();
    final categorized = LocalStorageDebugTool.categorizeData(data);
    final size = await LocalStorageDebugTool.getStorageSize();
    
    setState(() {
      _data = data;
      _categorizedData = categorized;
      _storageSize = size;
      _isLoading = false;
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Widget _buildDataItem(String key, Map<String, dynamic> data) {
    final type = data['type'];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        title: Text(
          key,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('类型: $type'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (type == 'json') ...[
                  Text('原始长度: ${data['length']} 字符'),
                  const SizedBox(height: 8),
                  const Text('解析后数据:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],  // 深灰色背景
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(data['parsed']),
                      style: const TextStyle(
                        fontSize: 12, 
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,  // 亮绿色文字，类似终端
                      ),
                    ),
                  ),
                ] else if (type == 'stringList') ...[
                  Text('数量: ${data['count']}'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],  // 深灰色背景
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: SelectableText(
                      data['value'].join('\n'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.greenAccent,  // 亮绿色文字
                      ),
                    ),
                  ),
                ] else ...[
                  SelectableText(
                    '值: ${data['value']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('复制键名'),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: key));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已复制: $key')),
                          );
                        }
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      label: const Text('删除', style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认删除'),
                            content: Text('确定要删除 "$key" 吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('删除', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove(key);
                          _loadData();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本地存储调试工具'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => LocalStorageDebugTool.printAllData(),
            tooltip: '打印到控制台',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'export':
                  final json = await LocalStorageDebugTool.exportToJson();
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('导出数据'),
                        content: SingleChildScrollView(
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 400),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[700]!),
                            ),
                            child: SelectableText(
                              json,
                              style: const TextStyle(
                                fontSize: 12, 
                                fontFamily: 'monospace',
                                color: Colors.greenAccent,
                              ),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton.icon(
                            icon: const Icon(Icons.copy),
                            label: const Text('复制全部'),
                            onPressed: () async {
                              await LocalStorageDebugTool.copyToClipboard(json, context);
                              Navigator.pop(context);
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.share),
                            label: const Text('分享文件'),
                            onPressed: () async {
                              Navigator.pop(context);
                              await LocalStorageDebugTool.saveAndShareJson(context);
                            },
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
                case 'share':
                  await LocalStorageDebugTool.saveAndShareJson(context);
                  break;
                case 'npc_cache':
                  final cacheInfo = await LocalStorageDebugTool.getNPCCacheInfo();
                  if (mounted) {
                    _showNPCCacheDialog(context, cacheInfo);
                  }
                  break;
                case 'clear':
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('清除所有数据'),
                      content: const Text('确定要清除所有本地存储数据吗？此操作不可恢复！'),
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
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    _loadData();
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.code),
                  title: Text('查看JSON'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('分享文件'),
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'npc_cache',
                child: ListTile(
                  leading: Icon(Icons.people_alt, color: Colors.blue),
                  title: Text('NPC缓存'),
                  subtitle: Text('查看NPC资源缓存'),
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red),
                  title: Text('清除所有', style: TextStyle(color: Colors.red)),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 统计信息
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('总数据量', style: TextStyle(fontSize: 12)),
                          Text(
                            '${_data.length} 个',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('存储大小', style: TextStyle(fontSize: 12)),
                          Text(
                            _formatSize(_storageSize),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 分类选择
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('全部'),
                        selected: _selectedCategory == '全部',
                        onSelected: (selected) {
                          setState(() => _selectedCategory = '全部');
                        },
                      ),
                      const SizedBox(width: 8),
                      ..._categorizedData.entries
                          .where((e) => e.value.isNotEmpty)
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text('${e.key} (${e.value.length})'),
                                  selected: _selectedCategory == e.key,
                                  onSelected: (selected) {
                                    setState(() => _selectedCategory = e.key);
                                  },
                                ),
                              )),
                    ],
                  ),
                ),
                
                // 数据列表
                Expanded(
                  child: ListView(
                    children: [
                      if (_selectedCategory == '全部')
                        ..._data.entries.map((e) => _buildDataItem(e.key, e.value))
                      else if (_categorizedData[_selectedCategory] != null)
                        ..._categorizedData[_selectedCategory]!
                            .map((e) => _buildDataItem(e.key, e.value)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  void _showNPCCacheDialog(BuildContext context, Map<String, dynamic> cacheInfo) {
    final totalSize = cacheInfo['totalSize'] ?? 0;
    final npcCount = cacheInfo['npcCount'] ?? 0;
    final npcs = cacheInfo['npcs'] as List<dynamic>? ?? [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                    '总大小: ${LocalStorageDebugTool._formatFileSize(totalSize)} | 角色数: $npcCount',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 400, maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (npcs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('暂无缓存的NPC资源'),
                    ),
                  )
                else
                  ...npcs.map((npcData) {
                    final npcMap = npcData as Map<String, dynamic>;
                    final npcId = npcMap['id'] ?? '';
                    final sizeBytes = npcMap['size'] ?? 0;
                    final fileCount = npcMap['fileCount'] ?? 0;
                    final files = npcMap['files'] as List<dynamic>? ?? [];
                    final lastAccessed = npcMap['lastAccessed'] as String?;
                    
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
                              npcId.substring(0, min(2, npcId.length)),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            'NPC #$npcId',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('大小: ${LocalStorageDebugTool._formatFileSize(sizeBytes)}'),
                              Text('文件数: $fileCount'),
                              if (lastAccessed != null)
                                Text(
                                  '最后访问: ${_formatLastAccessed(lastAccessed)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                            ],
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
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
                                  ...files.map((file) {
                                    final fileMap = file as Map<String, dynamic>;
                                    final fileName = fileMap['name'] ?? '';
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getFileIcon(fileName),
                                            size: 16,
                                            color: _getFileColor(fileName),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              fileName,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontFamily: 'monospace',
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
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
                        Navigator.pop(context);
                        await LocalStorageDebugTool.smartCleanNPCCache();
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
                        Navigator.pop(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认清除'),
                            content: const Text('确定要清除所有NPC缓存吗？'),
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
                        
                        if (confirm == true && context.mounted) {
                          await LocalStorageDebugTool.clearAllNPCCache();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('所有NPC缓存已清除')),
                          );
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
  
  IconData _getFileIcon(String fileName) {
    if (fileName.endsWith('.mp4')) return Icons.videocam;
    if (fileName.endsWith('.png') || fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) return Icons.image;
    if (fileName.endsWith('.json')) return Icons.code;
    return Icons.insert_drive_file;
  }
  
  Color _getFileColor(String fileName) {
    if (fileName.endsWith('.mp4')) return Colors.purple;
    if (fileName.endsWith('.png') || fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) return Colors.green;
    if (fileName.endsWith('.json')) return Colors.orange;
    return Colors.grey;
  }
}

/// 使用示例：
/// 
/// 1. 在任何地方调用打印功能：
/// ```dart
/// await LocalStorageDebugTool.printAllData();
/// ```
/// 
/// 2. 在应用中添加调试页面：
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const LocalStorageDebugPage()),
/// );
/// ```
/// 
/// 3. 导出数据：
/// ```dart
/// final jsonString = await LocalStorageDebugTool.exportToJson();
/// print(jsonString);
/// ```
/// 
/// 4. 清除特定用户数据：
/// ```dart
/// await LocalStorageDebugTool.clearUserData('userId123');
/// ```
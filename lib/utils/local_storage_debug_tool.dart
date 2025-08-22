import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/logger_utils.dart';

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
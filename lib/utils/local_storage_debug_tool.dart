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
import '../services/resource_version_manager.dart';
import '../services/storage/local_storage_service.dart';

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
  
  /// 获取NPC缓存详细信息（包含版本信息）
  static Future<Map<String, dynamic>> getNPCCacheInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final npcsDir = Directory('${appDir.path}/npcs');
      
      LoggerUtils.info('获取NPC缓存信息，路径: ${npcsDir.path}');
      LoggerUtils.info('目录存在: ${await npcsDir.exists()}');
      
      // 获取所有资源的版本信息
      final prefs = await SharedPreferences.getInstance();
      final Map<String, int> localVersions = {};
      final Map<String, int> remoteVersions = {};
      
      // 获取远程版本配置
      try {
        final remoteVersionsStr = prefs.getString('resource_versions_cache');
        if (remoteVersionsStr != null) {
          final data = json.decode(remoteVersionsStr);
          if (data['versions'] != null) {
            data['versions'].forEach((key, value) {
              remoteVersions[key] = value as int;
            });
          }
        }
      } catch (e) {
        LoggerUtils.debug('获取远程版本信息失败: $e');
      }
      
      // 从ResourceVersionManager获取本地版本（新方式）
      try {
        // 确保ResourceVersionManager已加载
        await ResourceVersionManager.instance.load();
        
        // 获取所有本地版本信息
        final localVersionsData = await LocalStorageService.instance.getGlobalJson('device_file_versions_v4');
        if (localVersionsData != null && localVersionsData['versions'] != null) {
          final versions = localVersionsData['versions'] as Map;
          versions.forEach((key, value) {
            localVersions[key] = value as int;
          });
          LoggerUtils.debug('从ResourceVersionManager读取到 ${localVersions.length} 个版本记录');
        }
      } catch (e) {
        LoggerUtils.debug('从ResourceVersionManager读取版本信息失败: $e');
        
        // 备用方案：读取旧格式（res_ver_前缀）以兼容旧数据
        for (String key in prefs.getKeys()) {
          if (key.startsWith('res_ver_')) {
            final resourcePath = key.substring(8); // 移除 'res_ver_' 前缀
            final version = prefs.getInt(key) ?? 0;
            localVersions[resourcePath] = version;
          }
        }
        if (localVersions.isNotEmpty) {
          LoggerUtils.debug('使用旧格式读取到 ${localVersions.length} 个版本记录');
        }
      }
      
      if (!await npcsDir.exists()) {
        LoggerUtils.info('NPC缓存目录不存在');
        return {
          'totalSize': 0,
          'totalSizeMB': 0.0,
          'totalSizeText': '0 B',
          'npcCount': 0,
          'npcs': [],
          'cacheDir': npcsDir.path,
          'localVersions': localVersions,
          'remoteVersions': remoteVersions,
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
          
          // 遍历皮肤ID子目录
          await for (final skinEntity in entity.list()) {
            if (skinEntity is Directory) {
              final skinId = skinEntity.path.split(Platform.pathSeparator).last;
              
              await for (final file in skinEntity.list()) {
                if (file is File) {
                  final fileSize = await file.length();
                  folderSize += fileSize;
                  
                  final fileName = file.path.split(Platform.pathSeparator).last;
                  final resourcePath = 'npcs/$npcId/$skinId/$fileName';
                  
                  // 获取版本信息
                  final localVersion = localVersions[resourcePath] ?? 0;
                  final remoteVersion = remoteVersions[resourcePath] ?? 0;
                  final needsUpdate = remoteVersion > localVersion;
                  
                  files.add({
                    'name': '$skinId/$fileName',  // 包含皮肤ID的相对路径
                    'size': fileSize,
                    'sizeText': _formatFileSize(fileSize),
                    'type': _getFileType(fileName),
                    'skinId': skinId,
                    'resourcePath': resourcePath,
                    'localVersion': localVersion,
                    'remoteVersion': remoteVersion,
                    'needsUpdate': needsUpdate,
                    'versionText': localVersion > 0 ? 'v$localVersion' : '未记录',
                  });
                }
              }
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
        'localVersions': localVersions,
        'remoteVersions': remoteVersions,
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
      
      LoggerUtils.info('========== 开始清除NPC缓存 ==========');
      LoggerUtils.info('缓存目录路径: ${npcCacheDir.path}');
      LoggerUtils.info('目录是否存在: ${await npcCacheDir.exists()}');
      
      if (await npcCacheDir.exists()) {
        // 统计删除前的状态
        int totalFiles = 0;
        int totalSize = 0;
        
        // 先统计所有文件
        await for (final entity in npcCacheDir.list(recursive: true)) {
          if (entity is File) {
            totalFiles++;
            totalSize += await entity.length();
            LoggerUtils.debug('找到文件: ${entity.path}');
          }
        }
        
        LoggerUtils.info('删除前统计: $totalFiles 个文件，总大小: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB');
        
        // 使用递归删除整个目录
        LoggerUtils.info('开始递归删除整个目录...');
        await npcCacheDir.delete(recursive: true);
        LoggerUtils.info('✓ 递归删除完成');
        
        // 验证删除结果
        if (await npcCacheDir.exists()) {
          LoggerUtils.error('❌ 错误：目录仍然存在！');
          
          // 列出残留文件
          final remaining = npcCacheDir.listSync(recursive: true);
          LoggerUtils.error('残留文件数: ${remaining.length}');
          for (var item in remaining) {
            LoggerUtils.error('残留: ${item.path}');
          }
        } else {
          LoggerUtils.info('✅ NPC缓存目录已完全删除');
        }
      } else {
        LoggerUtils.info('NPC缓存目录不存在，无需清理');
      }
      
      // 清除缓存元数据（如果有的话）
      final prefs = await SharedPreferences.getInstance();
      
      // 列出所有与NPC相关的SharedPreferences键
      final keys = prefs.getKeys();
      int removedKeys = 0;
      for (final key in keys) {
        if (key.contains('npc') || key.contains('cache')) {
          await prefs.remove(key);
          removedKeys++;
          LoggerUtils.debug('删除SharedPreferences键: $key');
        }
      }
      
      LoggerUtils.info('已清除 $removedKeys 个相关的SharedPreferences键');
      
      // 最终验证
      LoggerUtils.info('========== 清除操作完成 ==========');
      
      // 再次检查目录状态
      final finalCheck = await npcCacheDir.exists();
      LoggerUtils.info('最终检查 - 目录存在: $finalCheck');
      
      if (!finalCheck) {
        LoggerUtils.info('✅ 成功：NPC缓存已完全清除');
      } else {
        LoggerUtils.error('❌ 失败：NPC缓存目录仍然存在');
      }
      
    } catch (e, stackTrace) {
      LoggerUtils.error('清除NPC缓存失败: $e');
      LoggerUtils.error('堆栈跟踪: $stackTrace');
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
    final localVersions = cacheInfo['localVersions'] as Map<String, int>? ?? {};
    final remoteVersions = cacheInfo['remoteVersions'] as Map<String, int>? ?? {};
    
    // 统计需要更新的资源数量
    int needUpdateCount = 0;
    remoteVersions.forEach((key, remoteVer) {
      final localVer = localVersions[key] ?? 0;
      if (remoteVer > localVer) {
        needUpdateCount++;
      }
    });
    
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
                  Row(
                    children: [
                      const Text('NPC缓存详情'),
                      if (needUpdateCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$needUpdateCount个待更新',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '总大小: ${LocalStorageDebugTool._formatFileSize(totalSize)} | 角色数: $npcCount | 版本记录: ${localVersions.length}个',
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
                                  // 按皮肤ID分组显示文件
                                  ...() {
                                    // 将文件按皮肤ID分组
                                    final Map<String, List<Map<String, dynamic>>> filesBySkin = {};
                                    
                                    for (final file in files) {
                                      final fileMap = file as Map<String, dynamic>;
                                      final fileName = fileMap['name'] ?? '';
                                      
                                      // 从文件名中提取皮肤ID（假设格式为 skinId/fileName）
                                      String skinId = '1';  // 默认皮肤ID
                                      String displayName = fileName;
                                      
                                      if (fileName.contains('/')) {
                                        final parts = fileName.split('/');
                                        if (parts.length >= 2) {
                                          skinId = parts[parts.length - 2];
                                          displayName = parts.last;
                                          fileMap['displayName'] = displayName;
                                        }
                                      } else {
                                        fileMap['displayName'] = fileName;
                                      }
                                      
                                      filesBySkin.putIfAbsent(skinId, () => []).add(fileMap);
                                    }
                                    
                                    // 按皮肤ID排序并生成UI
                                    final sortedSkins = filesBySkin.keys.toList()..sort();
                                    final List<Widget> widgets = [];
                                    
                                    for (final skinId in sortedSkins) {
                                      // 添加皮肤标题
                                      widgets.add(
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 2),
                                          child: Text(
                                            '皮肤 $skinId:',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ),
                                      );
                                      
                                      // 添加该皮肤的文件列表
                                      for (final fileMap in filesBySkin[skinId]!) {
                                        final displayName = fileMap['displayName'] ?? '';
                                        final fileSize = fileMap['size'] ?? 0;
                                        final localVersion = fileMap['localVersion'] ?? 0;
                                        final remoteVersion = fileMap['remoteVersion'] ?? 0;
                                        final needsUpdate = fileMap['needsUpdate'] ?? false;
                                        final versionText = fileMap['versionText'] ?? '';
                                        
                                        widgets.add(
                                          Padding(
                                            padding: const EdgeInsets.only(left: 24, bottom: 4),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _getFileIcon(displayName),
                                                  size: 14,
                                                  color: _getFileColor(displayName),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    displayName,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontFamily: 'monospace',
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // 版本标签
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: needsUpdate 
                                                      ? Colors.orange.withValues(alpha: 0.2)
                                                      : (localVersion > 0 
                                                        ? Colors.green.withValues(alpha: 0.2) 
                                                        : Colors.grey.withValues(alpha: 0.2)),
                                                    borderRadius: BorderRadius.circular(3),
                                                  ),
                                                  child: Text(
                                                    needsUpdate 
                                                      ? 'v$localVersion→v$remoteVersion'
                                                      : versionText,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: needsUpdate 
                                                        ? Colors.orange 
                                                        : (localVersion > 0 ? Colors.green : Colors.grey),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  LocalStorageDebugTool._formatFileSize(fileSize),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
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
                        LoggerUtils.info('点击NPC缓存详情对话框的清除全部按钮');
                        
                        // 保存原始context，因为关闭对话框后context会失效
                        final scaffoldContext = context;
                        
                        // 先关闭当前对话框
                        Navigator.pop(context);
                        
                        final confirm = await showDialog<bool>(
                          context: scaffoldContext,
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
                        
                        LoggerUtils.info('确认对话框返回值: $confirm, context.mounted: ${scaffoldContext.mounted}');
                        
                        if (confirm == true) {
                          LoggerUtils.info('开始清除所有NPC缓存...');
                          try {
                            await LocalStorageDebugTool.clearAllNPCCache();
                            LoggerUtils.info('清除完成，显示提示');
                            
                            if (scaffoldContext.mounted) {
                              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                const SnackBar(content: Text('所有NPC缓存已清除')),
                              );
                            }
                          } catch (e) {
                            LoggerUtils.error('清除缓存失败: $e');
                            if (scaffoldContext.mounted) {
                              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                SnackBar(
                                  content: Text('清除失败: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } else {
                          LoggerUtils.info('用户取消了清除操作');
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
import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_personality.dart';
import '../utils/logger_utils.dart';
import 'resource_version_manager.dart';

/// 云端NPC资源管理服务 - 使用Firebase Storage SDK
class CloudNPCService {
  // Firebase Storage实例
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // LiarsDice项目的Firebase Storage URL (用于直接HTTP访问)
  static const String _baseUrl = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o';
  
  // 访问token (公开读取权限)
  static const String _accessToken = 'adacfb99-9f79-4002-9aa3-e3a9a97db26b';
  static const String _cacheVersionKey = 'npc_cache_version';
  static const String _cachedConfigsKey = 'npc_cached_configs';
  
  // 资源版本缓存（仅在应用启动时加载一次）
  static Map<String, int>? _resourceVersions;
  static bool _hasCheckedCloudVersions = false;  // 标记是否已检查云端版本
  
  /// 获取所有可用的NPC配置（始终使用云端最新配置，不缓存JSON）
  static Future<List<NPCConfig>> fetchNPCConfigs({bool forceRefresh = false}) async {
    try {
      // 始终从云端获取最新版本，JSON文件很小不需要缓存
      LoggerUtils.info('从云端获取最新NPC配置...');
      
      try {
        // 使用Firebase Storage API
        final ref = _storage.ref('npcs/npc_config.json');
        final data = await ref.getData();
        
        if (data != null) {
          final jsonStr = utf8.decode(data);
          final jsonData = json.decode(jsonStr);
          final configs = _parseNPCConfigs(jsonData);
          
          LoggerUtils.info('成功获取${configs.length}个NPC配置（Firebase Storage）');
          return configs;
        }
      } catch (firebaseError) {
        LoggerUtils.warning('Firebase Storage访问失败，尝试HTTP: $firebaseError');
        
        // 回退到HTTP方式
        final response = await http.get(
          Uri.parse('$_baseUrl/npcs%2Fnpc_config.json?alt=media&token=$_accessToken')
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final configs = _parseNPCConfigs(data);
          
          LoggerUtils.info('成功获取${configs.length}个NPC配置（HTTP）');
          return configs;
        }
      }
      
      throw Exception('无法从云端获取NPC配置');
      
    } catch (e) {
      LoggerUtils.error('获取NPC配置失败: $e');
      // JSON配置必须联网获取，没有网络就无法游戏
      throw Exception('需要网络连接：NPC配置必须从云端获取');
    }
  }
  
  /// 獲取原始的NPC配置JSON數據（供NPCRawConfigService使用）
  static Future<Map<String, dynamic>?> fetchRawNPCConfig() async {
    try {
      LoggerUtils.info('從雲端獲取原始NPC配置...');
      
      try {
        // 使用Firebase Storage API
        final ref = _storage.ref('npcs/npc_config.json');
        final data = await ref.getData();
        
        if (data != null) {
          final jsonStr = utf8.decode(data);
          final jsonData = json.decode(jsonStr) as Map<String, dynamic>;
          LoggerUtils.info('成功獲取原始NPC配置（Firebase Storage）');
          return jsonData;
        }
      } catch (firebaseError) {
        LoggerUtils.warning('Firebase Storage訪問失敗，嘗試HTTP: $firebaseError');
        
        // 回退到HTTP方式
        final response = await http.get(
          Uri.parse('$_baseUrl/npcs%2Fnpc_config.json?alt=media&token=$_accessToken')
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          LoggerUtils.info('成功獲取原始NPC配置（HTTP）');
          return data;
        }
      }
      
      return null;
      
    } catch (e) {
      LoggerUtils.error('獲取原始NPC配置失敗: $e');
      return null;
    }
  }
  
  
  /// 获取NPC资源的本地路径（支持皮肤ID）
  static Future<String> getNPCResourcePath(String npcId, String resourcePath, {int skinId = 1}) async {
    final dir = await _getNPCDirectory(npcId, skinId: skinId);
    final localPath = '${dir.path}/$resourcePath';
    
    // 检查本地文件是否存在
    if (await File(localPath).exists()) {
      return localPath;
    }
    
    // 如果不存在，尝试从云端下载
    final encodedPath = Uri.encodeComponent(resourcePath);
    await _downloadFile(
      url: '$_baseUrl/npcs%2F$npcId%2F$skinId%2F$encodedPath?alt=media&token=$_accessToken',
      savePath: localPath,
    );
    
    return localPath;
  }
  
  /// 获取资源版本信息
  static Future<Map<String, int>> _getResourceVersions() async {
    // 如果已缓存，直接返回
    if (_resourceVersions != null) {
      // 应用启动后首次访问资源时，后台检查云端版本
      if (!_hasCheckedCloudVersions) {
        _hasCheckedCloudVersions = true;
        _checkCloudVersionsInBackground();
      }
      return _resourceVersions!;
    }
    
    try {
      // 优先从SharedPreferences读取上次保存的云端版本
      final prefs = await SharedPreferences.getInstance();
      final cachedVersionsStr = prefs.getString('resource_versions_cache');
      if (cachedVersionsStr != null) {
        try {
          final cachedData = json.decode(cachedVersionsStr);
          // 确保值都是int类型（处理可能的字符串）
          final versionsMap = cachedData['versions'] as Map<String, dynamic>? ?? {};
          _resourceVersions = {};
          versionsMap.forEach((key, value) {
            if (value is int) {
              _resourceVersions![key] = value;
            } else if (value is String) {
              _resourceVersions![key] = int.tryParse(value) ?? 0;
            }
          });
          LoggerUtils.info('使用缓存的云端资源版本配置');
        } catch (e) {
          LoggerUtils.debug('缓存版本解析失败: $e');
        }
      }
      
      // 如果没有缓存，使用空配置
      if (_resourceVersions == null) {
        LoggerUtils.info('首次启动，等待云端版本信息');
        _resourceVersions = {};
      }
      
      // 标记需要检查云端版本
      if (!_hasCheckedCloudVersions) {
        _hasCheckedCloudVersions = true;
        _checkCloudVersionsInBackground();
      }
      
      return _resourceVersions!;
    } catch (e) {
      LoggerUtils.error('获取资源版本信息失败: $e');
      return {};
    }
  }
  
  /// 后台检查云端版本（不阻塞）
  static void _checkCloudVersionsInBackground() {
    Future(() async {
      try {
        LoggerUtils.info('后台检查云端资源版本更新...');
        
        // 尝试从Firebase Storage获取
        try {
          final ref = _storage.ref('npcs/resource_versions.json');
          final data = await ref.getData();
          if (data != null) {
            final jsonStr = utf8.decode(data);
            final cloudData = json.decode(jsonStr);
            // 确保值都是int类型（处理可能的字符串）
            final versionsMap = cloudData['versions'] as Map<String, dynamic>? ?? {};
            _resourceVersions = {};
            versionsMap.forEach((key, value) {
              if (value is int) {
                _resourceVersions![key] = value;
              } else if (value is String) {
                _resourceVersions![key] = int.tryParse(value) ?? 0;
              }
            });
            
            // 保存到本地缓存
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('resource_versions_cache', jsonStr);
            
            // 同步版本信息到ResourceVersionManager（优化：避免重复调用）
            await ResourceVersionManager.instance.syncWithCloud(_resourceVersions!);
            
            LoggerUtils.info('云端资源版本更新成功（Firebase Storage）');
            return;
          }
        } catch (e) {
          LoggerUtils.debug('Firebase Storage获取版本失败，尝试HTTP: $e');
        }
        
        // 回退到HTTP方式
        final response = await http.get(
          Uri.parse('$_baseUrl/npcs%2Fresource_versions.json?alt=media&token=$_accessToken')
        );
        
        if (response.statusCode == 200) {
          final cloudData = json.decode(response.body);
          // 确保值都是int类型（处理可能的字符串）
          final versionsMap = cloudData['versions'] as Map<String, dynamic>? ?? {};
          _resourceVersions = {};
          versionsMap.forEach((key, value) {
            if (value is int) {
              _resourceVersions![key] = value;
            } else if (value is String) {
              _resourceVersions![key] = int.tryParse(value) ?? 0;
            }
          });
          
          // 保存到本地缓存
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('resource_versions_cache', response.body);
          
          // 同步版本信息到ResourceVersionManager（优化：避免重复调用）
          await ResourceVersionManager.instance.syncWithCloud(_resourceVersions!);
          
          LoggerUtils.info('云端资源版本更新成功（HTTP）');
        }
      } catch (e) {
        LoggerUtils.debug('后台更新版本信息失败（使用本地版本）: $e');
      }
    });
  }
  
  /// 主动刷新版本信息（可在特定时机调用，如用户登录、进入游戏等）
  static Future<void> refreshResourceVersions() async {
    LoggerUtils.info('主动刷新资源版本信息...');
    _resourceVersions = null;  // 清除缓存
    _hasCheckedCloudVersions = false;  // 重置检查标记
    await _getResourceVersions();  // 重新获取
  }
  
  /// 检查资源是否需要更新（优化版：文件级别版本控制）
  static Future<bool> _needsUpdate(String npcId, String resourcePath, int skinId, File localFile) async {
    // 如果文件不存在，肯定需要下载
    if (!await localFile.exists()) return true;
    
    // 构建资源路径key（与云端resource_versions.json的key格式一致）
    final resourceKey = 'npcs/$npcId/$skinId/$resourcePath';
    
    // 获取云端版本信息
    final cloudVersions = await _getResourceVersions();
    if (!cloudVersions.containsKey(resourceKey)) {
      // 云端没有该文件的版本信息，说明不需要版本控制，文件存在即可
      return false;
    }
    
    // 确保版本管理器已加载
    await ResourceVersionManager.instance.ensureLoaded();
    
    // 直接使用文件级别的版本比较
    final remoteVersion = cloudVersions[resourceKey]!;
    if (ResourceVersionManager.instance.needsUpdate(resourceKey, remoteVersion)) {
      final localVersion = ResourceVersionManager.instance.getFileVersion(resourceKey);
      LoggerUtils.info('资源需要更新: $resourceKey (本地v$localVersion -> 远程v$remoteVersion)');
      return true;
    }
    
    return false;
  }
  
  /// 保存资源版本号（优化版：文件级别版本控制）
  static Future<void> _saveResourceVersion(String npcId, String resourcePath, int skinId) async {
    final resourceKey = 'npcs/$npcId/$skinId/$resourcePath';
    
    // 获取云端版本信息
    final cloudVersions = await _getResourceVersions();
    
    // 只有在云端JSON中明确定义了版本的文件才记录版本
    // 否则不记录版本（保持NO_VERSION = 0）
    if (cloudVersions.containsKey(resourceKey)) {
      final version = cloudVersions[resourceKey]!;
      // 使用文件级别的版本保存
      await ResourceVersionManager.instance.setFileVersion(resourceKey, version);
      LoggerUtils.debug('保存资源版本: $resourceKey = v$version');
    } else {
      // 文件不在版本控制中，不记录版本号
      // 这样getFileVersion会返回NO_VERSION (0)
      LoggerUtils.debug('资源不在版本控制中，不记录版本: $resourceKey');
    }
  }
  
  /// 智能获取NPC资源路径（优先本地，否则返回云端URL并后台下载）
  /// @param skinId 皮肤ID，默认为1（第一套皮肤）
  static Future<String> getSmartResourcePath(String npcId, String resourcePath, {int skinId = 1}) async {
    final dir = await _getNPCDirectory(npcId, skinId: skinId);
    final localPath = '${dir.path}/$resourcePath';
    final localFile = File(localPath);
    
    // 检查是否需要更新（版本控制）
    final needsUpdate = await _needsUpdate(npcId, resourcePath, skinId, localFile);
    
    // 如果本地文件存在且不需要更新，直接使用
    if (await localFile.exists() && !needsUpdate) {
      LoggerUtils.debug('使用本地缓存: $localPath');
      return localPath;
    }
    
    // 如果需要更新，先删除旧文件
    if (needsUpdate && await localFile.exists()) {
      try {
        await localFile.delete();
        LoggerUtils.info('删除旧版本资源: $resourcePath');
      } catch (e) {
        LoggerUtils.warning('删除旧资源失败: $e');
      }
    }
    
    // 构建云端URL（添加皮肤ID子目录）
    final encodedId = Uri.encodeComponent(npcId);
    final encodedSkinId = Uri.encodeComponent(skinId.toString());
    final encodedPath = Uri.encodeComponent(resourcePath);
    final cloudUrl = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/'
                     'npcs%2F$encodedId%2F$encodedSkinId%2F$encodedPath?alt=media';
    
    // 后台下载到本地（不阻塞返回）
    _downloadFileInBackgroundWithVersion(cloudUrl, localPath, npcId, resourcePath, skinId);
    
    // 立即返回云端URL供使用
    LoggerUtils.debug('使用云端URL并后台缓存: $cloudUrl');
    return cloudUrl;
  }
  
  /// 后台下载文件（不阻塞）
  static void _downloadFileInBackground(String url, String savePath) {
    Future(() async {
      try {
        final file = File(savePath);
        if (await file.exists()) return; // 双重检查
        
        // 创建目录
        await file.parent.create(recursive: true);
        
        // 下载文件
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          LoggerUtils.info('后台缓存成功: ${savePath.split('/').last}');
        }
      } catch (e) {
        LoggerUtils.debug('后台缓存失败（不影响使用）: $e');
      }
    });
  }
  
  /// 后台下载文件并保存版本（不阻塞）
  static void _downloadFileInBackgroundWithVersion(
    String url, 
    String savePath, 
    String npcId, 
    String resourcePath, 
    int skinId
  ) {
    Future(() async {
      try {
        final file = File(savePath);
        
        // 创建目录
        await file.parent.create(recursive: true);
        
        // 下载文件
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          
          // 保存版本号
          await _saveResourceVersion(npcId, resourcePath, skinId);
          
          LoggerUtils.info('后台缓存成功(带版本): ${savePath.split('/').last}');
        }
      } catch (e) {
        LoggerUtils.debug('后台缓存失败（不影响使用）: $e');
      }
    });
  }
  
  /// 获取缓存大小（MB）
  static Future<double> getCacheSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final npcsDir = Directory('${appDir.path}/npcs');
      
      if (!await npcsDir.exists()) return 0.0;
      
      int totalBytes = 0;
      await for (final entity in npcsDir.list(recursive: true)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
      
      return totalBytes / (1024 * 1024); // 转换为MB
    } catch (e) {
      LoggerUtils.error('获取缓存大小失败: $e');
      return 0.0;
    }
  }
  
  /// 智能清理缓存（基于大小和时间）
  static Future<void> smartCleanCache({
    double maxCacheSizeMB = 500.0,  // 最大缓存500MB
    int maxCacheDays = 30,          // 最长保留30天
    int minKeepNPCs = 5,            // 至少保留5个最近使用的NPC
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final npcsDir = Directory('${appDir.path}/npcs');
      
      if (!await npcsDir.exists()) return;
      
      // 获取当前缓存大小
      final currentSizeMB = await getCacheSize();
      LoggerUtils.info('当前NPC缓存大小: ${currentSizeMB.toStringAsFixed(2)}MB');
      
      // 如果缓存未超限，只清理过期的
      if (currentSizeMB <= maxCacheSizeMB) {
        await _cleanExpiredNPCs(maxCacheDays);
        return;
      }
      
      // 缓存超限，需要清理
      LoggerUtils.warning('缓存超限，开始智能清理...');
      
      // 收集所有NPC信息（支持皮肤子目录）
      final npcInfoList = <Map<String, dynamic>>[];
      await for (final npcEntity in npcsDir.list()) {
        if (npcEntity is Directory) {
          final npcId = npcEntity.path.split('/').last;
          
          // 遍历皮肤子目录
          await for (final skinEntity in npcEntity.list()) {
            if (skinEntity is Directory) {
              final skinId = skinEntity.path.split('/').last;
              final stat = await skinEntity.stat();
              
              // 计算皮肤文件夹大小
              int folderSize = 0;
              await for (final file in skinEntity.list(recursive: true)) {
                if (file is File) {
                  folderSize += await file.length();
                }
              }
              
              npcInfoList.add({
                'id': npcId,
                'skinId': skinId,
                'path': skinEntity.path,
                'accessed': stat.accessed,
                'size': folderSize,
                'sizeMB': folderSize / (1024 * 1024),
              });
            }
          }
        }
      }
      
      // 按最后访问时间排序（最近的在前）
      npcInfoList.sort((a, b) => 
        (b['accessed'] as DateTime).compareTo(a['accessed'] as DateTime));
      
      // 保留最近使用的NPC，删除其他的直到缓存大小合适
      double totalSizeMB = currentSizeMB;
      
      for (int i = 0; i < npcInfoList.length; i++) {
        // 至少保留指定数量的NPC
        if (i < minKeepNPCs) continue;
        
        // 如果缓存已经小于限制，停止清理
        if (totalSizeMB <= maxCacheSizeMB * 0.8) break; // 清理到80%以下
        
        final npcInfo = npcInfoList[i];
        final npcId = npcInfo['id'] as String;
        final skinId = npcInfo['skinId'] as String;
        final sizeMB = npcInfo['sizeMB'] as double;
        
        // 删除NPC皮肤资源
        await Directory(npcInfo['path'] as String).delete(recursive: true);
        totalSizeMB -= sizeMB;
        
        LoggerUtils.info('清理NPC缓存: $npcId/皮肤$skinId (${sizeMB.toStringAsFixed(2)}MB)');
      }
      
      LoggerUtils.info('缓存清理完成，当前大小: ${totalSizeMB.toStringAsFixed(2)}MB');
      
    } catch (e) {
      LoggerUtils.error('智能清理缓存失败: $e');
    }
  }
  
  /// 清理过期的NPC（内部方法，支持皮肤子目录）
  static Future<void> _cleanExpiredNPCs(int maxCacheDays) async {
    final appDir = await getApplicationDocumentsDirectory();
    final npcsDir = Directory('${appDir.path}/npcs');
    
    if (!await npcsDir.exists()) return;
    
    final now = DateTime.now();
    
    await for (final npcEntity in npcsDir.list()) {
      if (npcEntity is Directory) {
        final npcId = npcEntity.path.split('/').last;
        
        // 遍历皮肤子目录
        await for (final skinEntity in npcEntity.list()) {
          if (skinEntity is Directory) {
            final skinId = skinEntity.path.split('/').last;
            final stat = await skinEntity.stat();
            final age = now.difference(stat.accessed);
            
            if (age.inDays > maxCacheDays) {
              LoggerUtils.info('清理过期NPC: $npcId/皮肤$skinId (${age.inDays}天未使用)');
              await skinEntity.delete(recursive: true);
            }
          }
        }
        
        // 如果NPC目录空了，删除它
        if (await npcEntity.list().isEmpty) {
          await npcEntity.delete();
        }
      }
    }
  }
  
  // ========== 私有方法 ==========
  
  /// 解析NPC配置（兼容现有JSON结构）
  static List<NPCConfig> _parseNPCConfigs(Map<String, dynamic> data) {
    final configs = <NPCConfig>[];
    
    // 处理现有的npcs对象结构
    final npcsData = data['npcs'] as Map<String, dynamic>;
    for (final entry in npcsData.entries) {
      configs.add(NPCConfig.fromJson(entry.key, entry.value));
    }
    
    return configs;
  }
  
  // 已移除配置文件缓存相关方法，因为JSON配置始终从云端获取
  
  /// 获取NPC目录（支持皮肤ID）
  static Future<Directory> _getNPCDirectory(String npcId, {int skinId = 1}) async {
    final appDir = await getApplicationDocumentsDirectory();
    // 添加皮肤ID子目录：npcs/1001/1/
    final npcDir = Directory('${appDir.path}/npcs/$npcId/$skinId');
    
    if (!await npcDir.exists()) {
      await npcDir.create(recursive: true);
    }
    
    return npcDir;
  }
  
  
  /// 获取资源列表（根据实际Storage结构）
  static Future<List<Map<String, String>>> _getResourceList(String npcId) async {
    // 根据实际上传的文件结构
    final encodedId = Uri.encodeComponent(npcId);
    
    // 尝试从配置中获取videoCount，默认为4
    int videoCount = 4;
    try {
      // 尝试从已加载的配置中获取
      final configs = await fetchNPCConfigs();
      final npcConfig = configs.firstWhere(
        (config) => config.id == npcId,
        orElse: () => NPCConfig(
          id: npcId,
          names: {'en': npcId},
          descriptions: {'en': ''},
          avatarPath: '',
          videosPath: '',
          isVIP: false,
          unlocked: true,
          videoCount: 4,
          personality: AIPersonality(
            id: npcId,
            name: npcId,
            description: '',
            avatarPath: '',
            bluffRatio: 0.3,
            challengeThreshold: 0.4,
            riskAppetite: 0.4,
            mistakeRate: 0.02,
            tellExposure: 0.08,
            reverseActingProb: 0.25,
            bidPreferenceThreshold: 0.1,
          ),
          country: '',
        ),
      );
      videoCount = npcConfig.videoCount;
    } catch (e) {
      LoggerUtils.debug('获取NPC videoCount失败，使用默认值4: $e');
    }
    
    List<Map<String, String>> resources = [
      {'path': '1.jpg', 'url': '$_baseUrl/npcs%2F$encodedId%2F1.jpg?alt=media&token=$_accessToken'},
      {'path': 'dialogue_$npcId.json', 'url': '$_baseUrl/npcs%2F$encodedId%2Fdialogue_$npcId.json?alt=media&token=$_accessToken'},
    ];
    
    // 动态添加视频资源
    for (int i = 1; i <= videoCount; i++) {
      resources.add({
        'path': '$i.mp4',
        'url': '$_baseUrl/npcs%2F$encodedId%2F$i.mp4?alt=media&token=$_accessToken'
      });
    }
    
    // 添加drunk视频
    resources.add({
      'path': 'drunk.mp4',
      'url': '$_baseUrl/npcs%2F$encodedId%2Fdrunk.mp4?alt=media&token=$_accessToken'
    });
    
    return resources;
  }
  
  /// 下载文件 - 优先使用Firebase Storage SDK
  static Future<void> _downloadFile({
    required String url,
    required String savePath,
  }) async {
    try {
      final file = File(savePath);
      await file.parent.create(recursive: true);
      
      // 尝试从URL中提取Firebase Storage路径
      if (url.contains('firebasestorage.googleapis.com')) {
        // 从URL中提取存储路径
        final match = RegExp(r'o/([^?]+)').firstMatch(url);
        if (match != null) {
          final storagePath = Uri.decodeComponent(match.group(1)!);
          
          try {
            // 使用Firebase Storage SDK下载
            final ref = _storage.ref(storagePath);
            await ref.writeToFile(file);
            LoggerUtils.debug('文件通过Firebase SDK下载成功: $savePath');
            return;
          } catch (e) {
            LoggerUtils.warning('Firebase SDK下载失败，回退到HTTP: $e');
          }
        }
      }
      
      // 回退到HTTP下载
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        LoggerUtils.debug('文件通过HTTP下载成功: $savePath');
      } else {
        throw Exception('下载失败: ${response.statusCode}');
      }
    } catch (e) {
      LoggerUtils.error('下载文件失败: $url - $e');
      rethrow;
    }
  }
  
  /// 清理缓存
  static Future<void> _clearCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final npcDir = Directory('${appDir.path}/npcs');
      
      if (await npcDir.exists()) {
        await npcDir.delete(recursive: true);
      }
      
      // 不再需要清除SharedPreferences中的记录
      
    } catch (e) {
      LoggerUtils.error('清理缓存失败: $e');
    }
  }
  
  /// 获取默认配置（离线模式，兼容现有结构）
  static List<NPCConfig> _getDefaultConfigs() {
    // 返回内置的默认NPC配置
    return [
      NPCConfig(
        id: '0001',
        names: {
          'en': 'Lena',
          'zh_TW': '萊娜',
          'es': 'Lena',
          'pt': 'Lena',
          'id': 'Lena',
        },
        descriptions: {
          'en': 'Her calm gaze hides a quiet allure.',
          'zh_TW': '冷靜的眼神裡，藏著低調的魅力。',
        },
        avatarPath: 'assets/npcs/0001/1/',
        videosPath: 'assets/npcs/0001/1/',
        personality: AIPersonality(
          id: '0001',
          name: 'Lena',
          description: 'Her calm gaze hides a quiet allure.',
          avatarPath: 'assets/npcs/0001/1/',
          bluffRatio: 0.25,
          challengeThreshold: 0.4,
          riskAppetite: 0.3,
          mistakeRate: 0.02,
          tellExposure: 0.08,
          reverseActingProb: 0.25,
          bidPreferenceThreshold: 0.1,
        ),
        country: 'Germany',
        videoCount: 5,  // 0001有5个视频
        isLocal: true,
      ),
      NPCConfig(
        id: '0002',
        names: {
          'en': 'Katerina',
          'zh_TW': '卡捷琳娜',
          'es': 'Katerina',
          'pt': 'Katerina',
          'id': 'Katerina',
        },
        descriptions: {
          'en': 'Graceful and distant, she draws you closer without a word.',
          'zh_TW': '高貴而疏離，她無聲地吸引著你靠近。',
        },
        avatarPath: 'assets/npcs/0002/1/',
        videosPath: 'assets/npcs/0002/1/',
        personality: AIPersonality(
          id: '0002',
          name: 'Katerina',
          description: 'Graceful and distant, she draws you closer without a word.',
          avatarPath: 'assets/npcs/0002/1/',
          bluffRatio: 0.4,
          challengeThreshold: 0.38,
          riskAppetite: 0.5,
          mistakeRate: 0.025,
          tellExposure: 0.1,
          reverseActingProb: 0.35,
          bidPreferenceThreshold: 0.12,
        ),
        country: 'Russia',
        isLocal: true,
      ),
    ];
  }
}

/// NPC配置数据模型（兼容现有JSON结构）
class NPCConfig {
  final String id;
  final Map<String, String> names; // 多语言名称
  final Map<String, String> descriptions; // 多语言描述
  final String avatarPath;
  final String videosPath;
  final bool isVIP;
  final bool unlocked;
  final int? unlockPrice;
  final String? unlockItemId;
  final AIPersonality personality;
  final int drinkCapacity;
  final String country;
  final int videoCount; // 视频数量
  final bool isLocal; // 是否为本地资源
  final String? cloudUrl; // 云端资源URL基础路径
  final int version; // 资源版本号
  
  NPCConfig({
    required this.id,
    required this.names,
    required this.descriptions,
    required this.avatarPath,
    required this.videosPath,
    this.isVIP = false,
    this.unlocked = true,
    this.unlockPrice,
    this.unlockItemId,
    required this.personality,
    this.drinkCapacity = 6,
    required this.country,
    this.videoCount = 4,
    this.isLocal = false,
    this.cloudUrl,
    this.version = 1,
  });
  
  /// 从现有JSON结构解析
  factory NPCConfig.fromJson(String id, Map<String, dynamic> json) {
    return NPCConfig(
      id: id,
      names: Map<String, String>.from(json['names'] ?? {}),
      descriptions: Map<String, String>.from(json['descriptions'] ?? {}),
      avatarPath: json['avatarPath'] ?? 'assets/people/$id/',
      videosPath: json['videosPath'] ?? 'assets/npcs/$id/1/',
      isVIP: json['isVIP'] ?? false,
      unlocked: json['unlocked'] ?? true,
      unlockPrice: json['unlockPrice'],
      unlockItemId: json['unlockItemId'],
      personality: AIPersonality.fromJson(json['personality'] ?? {}),
      drinkCapacity: json['drinkCapacity'] ?? 6,
      country: json['country'] ?? '',
      videoCount: json['videoCount'] ?? 4,
      isLocal: json['isLocal'] ?? true, // 默认为本地资源
      cloudUrl: json['cloudUrl'],
      version: json['version'] ?? 1,
    );
  }
  
  /// 获取特定语言的名称
  String getName(String languageCode) {
    // 尝试获取特定语言，如果没有则使用英文，最后使用第一个可用的
    return names[languageCode] ?? 
           names['en'] ?? 
           (names.isNotEmpty ? names.values.first : 'Unknown');
  }
  
  /// 获取特定语言的描述
  String getDescription(String languageCode) {
    return descriptions[languageCode] ?? 
           descriptions['en'] ?? 
           (descriptions.isNotEmpty ? descriptions.values.first : '');
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'names': names,
      'descriptions': descriptions,
      'avatarPath': avatarPath,
      'videosPath': videosPath,
      'isVIP': isVIP,
      'unlocked': unlocked,
      if (unlockPrice != null) 'unlockPrice': unlockPrice,
      if (unlockItemId != null) 'unlockItemId': unlockItemId,
      'personality': personality.toJson(),
      'drinkCapacity': drinkCapacity,
      'country': country,
      'videoCount': videoCount,
      'isLocal': isLocal,
      if (cloudUrl != null) 'cloudUrl': cloudUrl,
      'version': version,
    };
  }
  
  NPCConfig copyWith({
    String? id,
    Map<String, String>? names,
    Map<String, String>? descriptions,
    String? avatarPath,
    String? videosPath,
    bool? isVIP,
    bool? unlocked,
    int? unlockPrice,
    String? unlockItemId,
    AIPersonality? personality,
    int? drinkCapacity,
    String? country,
    bool? isLocal,
    String? cloudUrl,
    int? version,
  }) {
    return NPCConfig(
      id: id ?? this.id,
      names: names ?? this.names,
      descriptions: descriptions ?? this.descriptions,
      avatarPath: avatarPath ?? this.avatarPath,
      videosPath: videosPath ?? this.videosPath,
      isVIP: isVIP ?? this.isVIP,
      unlocked: unlocked ?? this.unlocked,
      unlockPrice: unlockPrice ?? this.unlockPrice,
      unlockItemId: unlockItemId ?? this.unlockItemId,
      personality: personality ?? this.personality,
      drinkCapacity: drinkCapacity ?? this.drinkCapacity,
      country: country ?? this.country,
      isLocal: isLocal ?? this.isLocal,
      cloudUrl: cloudUrl ?? this.cloudUrl,
      version: version ?? this.version,
    );
  }
}
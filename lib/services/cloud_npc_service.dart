import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_personality.dart';
import '../utils/logger_utils.dart';

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
  
  
  /// 获取NPC资源的本地路径
  static Future<String> getNPCResourcePath(String npcId, String resourcePath) async {
    final dir = await _getNPCDirectory(npcId);
    final localPath = '${dir.path}/$resourcePath';
    
    // 检查本地文件是否存在
    if (await File(localPath).exists()) {
      return localPath;
    }
    
    // 如果不存在，尝试从云端下载
    final encodedPath = Uri.encodeComponent(resourcePath);
    await _downloadFile(
      url: '$_baseUrl/npcs%2F$npcId%2F$encodedPath?alt=media&token=$_accessToken',
      savePath: localPath,
    );
    
    return localPath;
  }
  
  /// 智能获取NPC资源路径（优先本地，否则返回云端URL并后台下载）
  static Future<String> getSmartResourcePath(String npcId, String resourcePath) async {
    final dir = await _getNPCDirectory(npcId);
    final localPath = '${dir.path}/$resourcePath';
    final localFile = File(localPath);
    
    // 检查本地文件是否存在
    if (await localFile.exists()) {
      LoggerUtils.debug('使用本地缓存: $localPath');
      return localPath;
    }
    
    // 构建云端URL
    final encodedId = Uri.encodeComponent(npcId);
    final encodedPath = Uri.encodeComponent(resourcePath);
    final cloudUrl = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/'
                     'npcs%2F$encodedId%2F$encodedPath?alt=media';
    
    // 后台下载到本地（不阻塞返回）
    _downloadFileInBackground(cloudUrl, localPath);
    
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
      
      // 收集所有NPC信息
      final npcInfoList = <Map<String, dynamic>>[];
      await for (final entity in npcsDir.list()) {
        if (entity is Directory) {
          final npcId = entity.path.split('/').last;
          final stat = await entity.stat();
          
          // 计算文件夹大小
          int folderSize = 0;
          await for (final file in entity.list(recursive: true)) {
            if (file is File) {
              folderSize += await file.length();
            }
          }
          
          npcInfoList.add({
            'id': npcId,
            'path': entity.path,
            'accessed': stat.accessed,
            'size': folderSize,
            'sizeMB': folderSize / (1024 * 1024),
          });
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
        final sizeMB = npcInfo['sizeMB'] as double;
        
        // 删除NPC资源
        await Directory(npcInfo['path'] as String).delete(recursive: true);
        totalSizeMB -= sizeMB;
        
        LoggerUtils.info('清理NPC缓存: $npcId (${sizeMB.toStringAsFixed(2)}MB)');
      }
      
      LoggerUtils.info('缓存清理完成，当前大小: ${totalSizeMB.toStringAsFixed(2)}MB');
      
    } catch (e) {
      LoggerUtils.error('智能清理缓存失败: $e');
    }
  }
  
  /// 清理过期的NPC（内部方法）
  static Future<void> _cleanExpiredNPCs(int maxCacheDays) async {
    final appDir = await getApplicationDocumentsDirectory();
    final npcsDir = Directory('${appDir.path}/npcs');
    
    if (!await npcsDir.exists()) return;
    
    final now = DateTime.now();
    
    await for (final entity in npcsDir.list()) {
      if (entity is Directory) {
        final stat = await entity.stat();
        final age = now.difference(stat.accessed);
        
        if (age.inDays > maxCacheDays) {
          final npcId = entity.path.split('/').last;
          LoggerUtils.info('清理过期NPC: $npcId (${age.inDays}天未使用)');
          await entity.delete(recursive: true);
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
  
  /// 获取NPC目录
  static Future<Directory> _getNPCDirectory(String npcId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final npcDir = Directory('${appDir.path}/npcs/$npcId');
    
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
        avatarPath: 'assets/people/0001/',
        videosPath: 'assets/people/0001/videos/',
        personality: AIPersonality(
          id: '0001',
          name: 'Lena',
          description: 'Her calm gaze hides a quiet allure.',
          avatarPath: 'assets/people/0001/',
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
        avatarPath: 'assets/people/0002/',
        videosPath: 'assets/people/0002/videos/',
        personality: AIPersonality(
          id: '0002',
          name: 'Katerina',
          description: 'Graceful and distant, she draws you closer without a word.',
          avatarPath: 'assets/people/0002/',
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
      videosPath: json['videosPath'] ?? 'assets/people/$id/videos/',
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
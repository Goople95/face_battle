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
  static const String _cacheVersion = 'npc_cache_version';
  static const int _currentVersion = 1;
  
  /// 获取所有可用的NPC配置
  static Future<List<NPCConfig>> fetchNPCConfigs({bool forceRefresh = false}) async {
    try {
      // 检查是否需要更新
      if (!forceRefresh && await _isCacheValid()) {
        final cached = await _loadCachedConfigs();
        if (cached != null) {
          LoggerUtils.info('使用缓存的NPC配置');
          return cached;
        }
      }
      
      // 从云端获取配置 - 使用Firebase Storage SDK
      LoggerUtils.info('从云端获取NPC配置...');
      
      try {
        // 使用Firebase Storage API
        final ref = _storage.ref('npcs/npc_config.json');
        final data = await ref.getData();
        
        if (data != null) {
          final jsonStr = utf8.decode(data);
          final jsonData = json.decode(jsonStr);
          final configs = _parseNPCConfigs(jsonData);
          
          // 缓存配置
          await _cacheConfigs(configs);
          
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
          
          // 缓存配置
          await _cacheConfigs(configs);
          
          return configs;
        }
      }
      
      throw Exception('获取NPC配置失败');
      
    } catch (e) {
      LoggerUtils.error('获取NPC配置出错: $e');
      // 尝试使用本地缓存
      final cached = await _loadCachedConfigs();
      if (cached != null) {
        return cached;
      }
      // 如果没有缓存，返回默认配置
      return _getDefaultConfigs();
    }
  }
  
  /// 下载NPC资源（头像和视频）
  static Future<void> downloadNPCResources(String npcId, {
    Function(double)? onProgress,
  }) async {
    try {
      final dir = await _getNPCDirectory(npcId);
      
      // 检查是否已下载
      if (await _isNPCDownloaded(npcId)) {
        LoggerUtils.info('NPC $npcId 资源已存在');
        return;
      }
      
      // 下载资源列表
      final resources = await _getResourceList(npcId);
      int downloaded = 0;
      
      for (final resource in resources) {
        await _downloadFile(
          url: resource['url']!,
          savePath: '${dir.path}/${resource['path']}',
        );
        
        downloaded++;
        if (onProgress != null) {
          onProgress(downloaded / resources.length);
        }
      }
      
      // 标记为已下载
      await _markAsDownloaded(npcId);
      
    } catch (e) {
      LoggerUtils.error('下载NPC资源失败: $e');
      rethrow;
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
  
  /// 检查并更新NPC资源
  static Future<void> checkForUpdates() async {
    try {
      // 暂时跳过版本检查，因为version.json可能不存在
      // 可以通过检查npc_config.json的metadata来判断更新
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt('last_update_check') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // 每24小时检查一次
      if (now - lastCheck > 86400000) {
        LoggerUtils.info('检查NPC资源更新...');
        await fetchNPCConfigs(forceRefresh: true);
        await prefs.setInt('last_update_check', now);
      }
    } catch (e) {
      LoggerUtils.error('检查更新失败: $e');
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
  
  /// 加载缓存的配置
  static Future<List<NPCConfig>?> _loadCachedConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('npc_configs');
      
      if (cached != null) {
        final data = json.decode(cached);
        return _parseNPCConfigs(data);
      }
    } catch (e) {
      LoggerUtils.error('加载缓存配置失败: $e');
    }
    return null;
  }
  
  /// 缓存配置（保持现有JSON结构）
  static Future<void> _cacheConfigs(List<NPCConfig> configs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 转换回原始的对象格式
      final npcsMap = <String, dynamic>{};
      for (final config in configs) {
        npcsMap[config.id] = config.toJson();
      }
      
      final data = {
        'npcs': npcsMap,
      };
      
      await prefs.setString('npc_configs', json.encode(data));
      await prefs.setInt(_cacheVersion, _currentVersion);
    } catch (e) {
      LoggerUtils.error('缓存配置失败: $e');
    }
  }
  
  /// 检查缓存是否有效
  static Future<bool> _isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getInt(_cacheVersion) ?? 0;
    return version == _currentVersion;
  }
  
  /// 获取NPC目录
  static Future<Directory> _getNPCDirectory(String npcId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final npcDir = Directory('${appDir.path}/npcs/$npcId');
    
    if (!await npcDir.exists()) {
      await npcDir.create(recursive: true);
    }
    
    return npcDir;
  }
  
  /// 检查NPC是否已下载
  static Future<bool> _isNPCDownloaded(String npcId) async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getStringList('downloaded_npcs') ?? [];
    return downloaded.contains(npcId);
  }
  
  /// 标记NPC为已下载
  static Future<void> _markAsDownloaded(String npcId) async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getStringList('downloaded_npcs') ?? [];
    if (!downloaded.contains(npcId)) {
      downloaded.add(npcId);
      await prefs.setStringList('downloaded_npcs', downloaded);
    }
  }
  
  /// 获取资源列表（根据实际Storage结构）
  static Future<List<Map<String, String>>> _getResourceList(String npcId) async {
    // 根据实际上传的文件结构
    final encodedId = Uri.encodeComponent(npcId);
    return [
      {'path': '1.png', 'url': '$_baseUrl/npcs%2F$encodedId%2F1.png?alt=media&token=$_accessToken'},
      {'path': 'dialogue_$npcId.json', 'url': '$_baseUrl/npcs%2F$encodedId%2Fdialogue_$npcId.json?alt=media&token=$_accessToken'},
      {'path': 'happy.mp4', 'url': '$_baseUrl/npcs%2F$encodedId%2Fhappy.mp4?alt=media&token=$_accessToken'},
      {'path': 'confident.mp4', 'url': '$_baseUrl/npcs%2F$encodedId%2Fconfident.mp4?alt=media&token=$_accessToken'},
      {'path': 'suspicious.mp4', 'url': '$_baseUrl/npcs%2F$encodedId%2Fsuspicious.mp4?alt=media&token=$_accessToken'},
      {'path': 'thinking.mp4', 'url': '$_baseUrl/npcs%2F$encodedId%2Fthinking.mp4?alt=media&token=$_accessToken'},
      {'path': 'drunk.mp4', 'url': '$_baseUrl/npcs%2F$encodedId%2Fdrunk.mp4?alt=media&token=$_accessToken'},
    ];
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
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('npc_configs');
      await prefs.remove('downloaded_npcs');
      
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
        personality: AIPersonality.defaultPersonality(),
        country: 'Germany',
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
        personality: AIPersonality.defaultPersonality().copyWith(
          bluffRatio: 0.4,
          challengeThreshold: 0.38,
          riskAppetite: 0.5,
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
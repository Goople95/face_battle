import 'storage/local_storage_service.dart';
import '../utils/logger_utils.dart';

/// 资源版本管理器 - 管理文件级别的资源版本信息
/// 使用设备级别存储，与云端resource_versions.json保持一致
class ResourceVersionManager {
  static const String VERSION_KEY = 'device_file_versions_v4';  // 文件级别版本管理
  static const int NO_VERSION = 0;      // 无版本信息
  static const int INITIAL_VERSION = 1; // 初始版本
  
  static ResourceVersionManager? _instance;
  static ResourceVersionManager get instance => _instance ??= ResourceVersionManager._();
  
  ResourceVersionManager._();
  
  // 存储格式：{ "npcs/1001/1/1.jpg": 1, "npcs/1001/1/2.mp4": 2, ... }
  // 与云端resource_versions.json格式完全一致
  Map<String, int> _localVersions = {};
  bool _isLoaded = false;
  
  /// 加载版本信息（设备级别，使用全局存储）
  Future<void> load() async {
    if (_isLoaded) return;
    
    try {
      // 使用LocalStorageService的全局存储（不需要用户ID）
      final json = await LocalStorageService.instance.getGlobalJson(VERSION_KEY);
      if (json != null && json['versions'] != null) {
        _localVersions = Map<String, int>.from(json['versions'] as Map);
        LoggerUtils.info('加载了 ${_localVersions.length} 个文件的版本信息（设备级别）');
      } else {
        _localVersions = {};
        LoggerUtils.info('版本信息为空，初始化为空Map');
      }
      _isLoaded = true;
    } catch (e) {
      LoggerUtils.error('加载版本信息失败: $e');
      _localVersions = {};
      _isLoaded = true;
    }
  }
  
  /// 保存版本信息（设备级别，使用全局存储）
  Future<bool> save() async {
    try {
      final json = {'versions': _localVersions};
      // 使用LocalStorageService的全局存储（不需要用户ID）
      final result = await LocalStorageService.instance.setGlobalJson(VERSION_KEY, json);
      if (result) {
        LoggerUtils.debug('保存了 ${_localVersions.length} 个文件的版本信息（设备级别）');
      }
      return result;
    } catch (e) {
      LoggerUtils.error('保存版本信息失败: $e');
      return false;
    }
  }
  
  /// 获取文件的版本号
  int getFileVersion(String resourceKey) {
    return _localVersions[resourceKey] ?? NO_VERSION;
  }
  
  /// 设置文件的版本号
  Future<void> setFileVersion(String resourceKey, int version) async {
    if (_localVersions[resourceKey] != version) {
      _localVersions[resourceKey] = version;
      await save();
      LoggerUtils.debug('更新文件版本: $resourceKey = v$version');
    }
  }
  
  /// 兼容旧接口（废弃，建议使用getFileVersion）
  @Deprecated('使用 getFileVersion 代替')
  int getVersion(String npcId, int skinId) {
    // 返回该NPC/皮肤下任意文件的最高版本号（兼容旧逻辑）
    final prefix = 'npcs/$npcId/$skinId/';
    int maxVersion = NO_VERSION;
    _localVersions.forEach((key, version) {
      if (key.startsWith(prefix) && version > maxVersion) {
        maxVersion = version;
      }
    });
    return maxVersion;
  }
  
  /// 兼容旧接口（废弃，建议使用setFileVersion）
  @Deprecated('使用 setFileVersion 代替')
  Future<void> setVersion(String npcId, int skinId, int version) async {
    // 这个方法不再使用，保留只是为了兼容
    LoggerUtils.warning('setVersion已废弃，请使用setFileVersion');
  }
  
  /// 批量更新版本信息（直接从云端同步）
  Future<void> syncWithCloud(Map<String, int> cloudVersions) async {
    bool hasChanges = false;
    cloudVersions.forEach((resourceKey, version) {
      if (_localVersions[resourceKey] != version) {
        _localVersions[resourceKey] = version;
        hasChanges = true;
        LoggerUtils.debug('同步云端版本: $resourceKey = v$version');
      }
    });
    
    if (hasChanges) {
      await save();
      LoggerUtils.info('同步了 ${cloudVersions.length} 个文件的云端版本');
    }
  }
  
  /// 检查文件是否需要更新
  bool needsUpdate(String resourceKey, int remoteVersion) {
    final localVersion = getFileVersion(resourceKey);
    // 无版本信息或本地版本低于远程版本时需要更新
    return localVersion == NO_VERSION || localVersion < remoteVersion;
  }
  
  /// 清除所有版本信息
  Future<void> clear() async {
    _localVersions.clear();
    await save();
    LoggerUtils.info('清除所有版本信息');
  }
  
  /// 获取所有版本信息（用于调试）
  Map<String, int> getAllVersions() => Map.unmodifiable(_localVersions);
  
  /// 确保已加载
  Future<void> ensureLoaded() async {
    if (!_isLoaded) {
      await load();
    }
  }
}
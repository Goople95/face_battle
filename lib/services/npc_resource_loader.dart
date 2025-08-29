import 'dart:io';
import 'package:flutter/services.dart';
import '../utils/logger_utils.dart';
import 'cloud_npc_service.dart';

/// NPC资源加载器 - 支持本地和云端资源的无缝切换
class NPCResourceLoader {
  static final Map<String, bool> _loadingStatus = {};
  static final Map<String, Future<void>> _loadingFutures = {};
  
  /// 获取NPC头像路径（自动处理云端资源）
  static Future<String> getAvatarPath(String npcId, String basePath) async {
    // 如果是本地资源路径，直接返回
    if (basePath.startsWith('assets/')) {
      return '$basePath/avatar.jpg';
    }
    
    // 云端资源，检查是否已下载
    await _ensureResourcesLoaded(npcId);
    return await CloudNPCService.getNPCResourcePath(npcId, '1.jpg');  // 云端使用1.jpg
  }
  
  /// 获取NPC视频路径（自动处理云端资源）
  static Future<String> getVideoPath(String npcId, String basePath, dynamic indexOrEmotion) async {
    // 处理文件名
    String fileName;
    if (indexOrEmotion == 'drunk') {
      fileName = 'drunk.mp4';
    } else if (indexOrEmotion is int) {
      fileName = '$indexOrEmotion.mp4';
    } else {
      // 默认使用1.mp4
      fileName = '1.mp4';
    }
    
    // 如果是本地资源路径，直接返回
    if (basePath.startsWith('assets/')) {
      return '$basePath/$fileName';
    }
    
    // 云端资源，检查是否已下载
    await _ensureResourcesLoaded(npcId);
    return await CloudNPCService.getNPCResourcePath(npcId, fileName);
  }
  
  /// 获取NPC对话文件路径（云端新增）
  static Future<String> getDialoguePath(String npcId, String basePath) async {
    // 如果是本地资源路径
    if (basePath.startsWith('assets/')) {
      return 'assets/dialogues/dialogue_$npcId.json';
    }
    
    // 云端资源
    await _ensureResourcesLoaded(npcId);
    return await CloudNPCService.getNPCResourcePath(npcId, 'dialogue_$npcId.json');
  }
  
  /// 确保NPC资源已加载
  static Future<void> _ensureResourcesLoaded(String npcId) async {
    // 如果正在加载，等待加载完成
    if (_loadingFutures.containsKey(npcId)) {
      await _loadingFutures[npcId];
      return;
    }
    
    // 如果已加载，直接返回
    if (_loadingStatus[npcId] == true) {
      return;
    }
    
    // 开始加载资源
    LoggerUtils.info('开始加载NPC资源: $npcId');
    final future = _downloadResources(npcId);
    _loadingFutures[npcId] = future;
    
    try {
      await future;
      _loadingStatus[npcId] = true;
      LoggerUtils.info('NPC资源加载完成: $npcId');
    } catch (e) {
      LoggerUtils.error('NPC资源加载失败: $npcId - $e');
      rethrow;
    } finally {
      _loadingFutures.remove(npcId);
    }
  }
  
  /// 下载NPC资源
  static Future<void> _downloadResources(String npcId) async {
    await CloudNPCService.downloadNPCResources(npcId);
  }
  
  /// 预加载NPC资源（后台静默下载）
  static Future<void> preloadResources(String npcId) async {
    // 如果已加载或正在加载，跳过
    if (_loadingStatus[npcId] == true || _loadingFutures.containsKey(npcId)) {
      return;
    }
    
    try {
      await _ensureResourcesLoaded(npcId);
    } catch (e) {
      // 预加载失败不抛出异常，只记录日志
      LoggerUtils.error('预加载NPC资源失败: $npcId - $e');
    }
  }
  
  /// 检查资源是否为本地资源
  static bool isLocalResource(String path) {
    return path.startsWith('assets/');
  }
  
  /// 加载资源（支持本地和云端）
  static Future<ByteData> loadAsset(String path) async {
    if (isLocalResource(path)) {
      // 本地资源，使用Flutter的资源加载器
      return await rootBundle.load(path);
    } else {
      // 云端资源，从文件系统加载
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return ByteData.view(bytes.buffer);
      } else {
        throw Exception('资源文件不存在: $path');
      }
    }
  }
  
  /// 清理缓存
  static void clearCache() {
    _loadingStatus.clear();
    _loadingFutures.clear();
  }
}
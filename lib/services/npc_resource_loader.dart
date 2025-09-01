import 'dart:io';
import 'package:flutter/services.dart';
import '../utils/logger_utils.dart';
import 'cloud_npc_service.dart';

/// NPC资源加载器 - 支持本地和云端资源的无缝切换
class NPCResourceLoader {
  static final Map<String, bool> _loadingStatus = {};
  static final Map<String, Future<void>> _loadingFutures = {};
  
  /// 获取NPC头像路径（自动处理云端资源）
  /// @param skinId 皮肤ID，默认为1
  static Future<String> getAvatarPath(String npcId, String basePath, {int skinId = 1}) async {
    // 如果是本地资源路径
    if (basePath.startsWith('assets/')) {
      // 构建包含皮肤ID的完整路径
      final localPath = 'assets/npcs/$npcId/$skinId/1.jpg';
      
      // 检查本地资源是否存在
      try {
        await rootBundle.load(localPath);
        LoggerUtils.debug('使用本地打包资源: $localPath');
        return localPath;
      } catch (e) {
        // 本地不存在，直接尝试从云端获取（不回退到默认皮肤）
        LoggerUtils.info('本地资源不存在 $localPath，尝试云端获取');
        return await CloudNPCService.getSmartResourcePath(npcId, '1.jpg', skinId: skinId);
      }
    }
    
    // 云端资源，检查是否已下载
    await _ensureResourcesLoaded(npcId, skinId: skinId);
    return await CloudNPCService.getNPCResourcePath(npcId, '1.jpg', skinId: skinId);  // 云端使用1.jpg
  }
  
  /// 获取NPC视频路径（自动处理云端资源）
  /// @param skinId 皮肤ID，默认为1
  static Future<String> getVideoPath(String npcId, String basePath, dynamic indexOrEmotion, {int skinId = 1}) async {
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
    
    // 如果是本地资源路径
    if (basePath.startsWith('assets/')) {
      // 构建包含皮肤ID的完整路径
      final localPath = 'assets/npcs/$npcId/$skinId/$fileName';
      
      // 检查本地资源是否存在
      try {
        await rootBundle.load(localPath);
        LoggerUtils.debug('使用本地打包视频: $localPath');
        return localPath;
      } catch (e) {
        // 本地不存在，直接尝试从云端获取（不回退到默认皮肤）
        LoggerUtils.info('本地视频不存在 $localPath，尝试云端获取');
        return await CloudNPCService.getSmartResourcePath(npcId, fileName, skinId: skinId);
      }
    }
    
    // 云端资源，检查是否已下载
    await _ensureResourcesLoaded(npcId, skinId: skinId);
    return await CloudNPCService.getNPCResourcePath(npcId, fileName, skinId: skinId);
  }
  
  /// 获取NPC对话文件路径（云端新增）
  /// @param skinId 皮肤ID，默认为1
  static Future<String> getDialoguePath(String npcId, String basePath, {int skinId = 1}) async {
    // 如果是本地资源路径
    if (basePath.startsWith('assets/')) {
      // 统一后，对话文件也在NPC目录下，与其他资源在一起
      // basePath 类似 "assets/npcs/0001/1/"
      final cleanPath = basePath.endsWith('/') ? basePath.substring(0, basePath.length - 1) : basePath;
      final localPath = '$cleanPath/dialogue_$npcId.json';
      
      // 检查本地资源是否存在
      try {
        await rootBundle.load(localPath);
        LoggerUtils.debug('使用本地对话文件: $localPath');
        return localPath;
      } catch (e) {
        // 本地不存在，尝试从云端获取
        LoggerUtils.info('本地对话文件不存在 $localPath，尝试云端获取');
        return await CloudNPCService.getSmartResourcePath(npcId, 'dialogue_$npcId.json', skinId: skinId);
      }
    }
    
    // 云端资源
    await _ensureResourcesLoaded(npcId, skinId: skinId);
    return await CloudNPCService.getNPCResourcePath(npcId, 'dialogue_$npcId.json', skinId: skinId);
  }
  
  /// 确保NPC资源已加载
  static Future<void> _ensureResourcesLoaded(String npcId, {int skinId = 1}) async {
    // 使用npcId和skinId组合作为键
    final key = '${npcId}_$skinId';
    
    // 如果正在加载，等待加载完成
    if (_loadingFutures.containsKey(key)) {
      await _loadingFutures[key];
      return;
    }
    
    // 如果已加载，直接返回
    if (_loadingStatus[key] == true) {
      return;
    }
    
    // 开始加载资源（使用空Future，因为getSmartResourcePath会自动处理下载）
    LoggerUtils.info('标记NPC资源为加载中: $npcId/皮肤$skinId');
    final future = Future.value();
    _loadingFutures[key] = future;
    
    try {
      await future;
      _loadingStatus[key] = true;
      LoggerUtils.info('NPC资源加载完成: $npcId/皮肤$skinId');
    } catch (e) {
      LoggerUtils.error('NPC资源加载失败: $npcId/皮肤$skinId - $e');
      rethrow;
    } finally {
      _loadingFutures.remove(key);
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
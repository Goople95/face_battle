import 'package:flutter/material.dart';
import '../models/ai_personality.dart';
import '../widgets/vip_unlock_dialog.dart';
import '../utils/logger_utils.dart';
import 'storage/local_storage_service.dart';

/// VIP解锁管理服务（精简版）
class VIPUnlockService {
  static final VIPUnlockService _instance = VIPUnlockService._internal();
  factory VIPUnlockService() => _instance;
  VIPUnlockService._internal();

  // 存储键
  static const String _vipUnlockPrefix = 'vip_unlocked_';
  static const String _tempUnlockPrefix = 'vip_temp_unlock_';
  static const String _gemsKey = 'user_gems';
  
  // 价格配置
  static const int vipUnlockPrice = 30;
  static const Duration tempUnlockDuration = Duration(hours: 1);

  /// 检查VIP角色是否已解锁
  Future<bool> isUnlocked(String characterId) async {
    final storage = LocalStorageService.instance;
    
    // 检查永久解锁
    bool permanentUnlock = await storage.getBool('$_vipUnlockPrefix$characterId') ?? false;
    if (permanentUnlock) return true;
    
    // 检查临时解锁
    String? tempUnlockTime = await storage.getString('$_tempUnlockPrefix$characterId');
    if (tempUnlockTime != null) {
      DateTime unlockTime = DateTime.parse(tempUnlockTime);
      if (DateTime.now().isBefore(unlockTime.add(tempUnlockDuration))) {
        return true;
      } else {
        // 过期清除
        await storage.remove('$_tempUnlockPrefix$characterId');
      }
    }
    
    return false;
  }

  /// 永久解锁VIP角色
  Future<bool> permanentUnlock(String characterId) async {
    final storage = LocalStorageService.instance;
    
    // 检查宝石余额
    int gems = await storage.getInt(_gemsKey) ?? 0;
    if (gems < vipUnlockPrice) {
      LoggerUtils.info('宝石不足，无法解锁VIP角色 $characterId');
      return false;
    }
    
    // 扣除宝石并解锁
    await storage.setInt(_gemsKey, gems - vipUnlockPrice);
    // 保存解锁状态
    await storage.setBool('$_vipUnlockPrefix$characterId', true);
    
    LoggerUtils.info('成功永久解锁VIP角色 $characterId');
    return true;
  }

  /// 临时解锁VIP角色（看广告）
  Future<void> temporaryUnlock(String characterId) async {
    final storage = LocalStorageService.instance;
    await storage.setString(
      '$_tempUnlockPrefix$characterId',
      DateTime.now().toIso8601String(),
    );
    LoggerUtils.info('临时解锁VIP角色 $characterId，有效期1小时');
  }

  /// 获取用户宝石数量
  Future<int> getUserGems() async {
    final storage = LocalStorageService.instance;
    return await storage.getInt(_gemsKey) ?? 0;
  }

  /// 添加宝石
  Future<void> addGems(int amount) async {
    final storage = LocalStorageService.instance;
    int currentGems = await storage.getInt(_gemsKey) ?? 0;
    await storage.setInt(_gemsKey, currentGems + amount);
    LoggerUtils.info('添加 $amount 宝石，当前余额: ${currentGems + amount}');
  }

  /// 获取VIP角色的解锁状态
  Future<VIPStatus> getVIPStatus(String characterId) async {
    final storage = LocalStorageService.instance;
    
    // 检查永久解锁
    if (await storage.getBool('$_vipUnlockPrefix$characterId') ?? false) {
      return VIPStatus.unlocked;
    }
    
    // 检查临时解锁
    String? tempUnlockTime = await storage.getString('$_tempUnlockPrefix$characterId');
    if (tempUnlockTime != null) {
      DateTime unlockTime = DateTime.parse(tempUnlockTime);
      DateTime expireTime = unlockTime.add(tempUnlockDuration);
      if (DateTime.now().isBefore(expireTime)) {
        return VIPStatus.tempUnlocked;
      }
    }
    
    return VIPStatus.locked;
  }

  /// 获取临时解锁剩余时间
  Future<Duration?> getTempUnlockRemaining(String characterId) async {
    final storage = LocalStorageService.instance;
    String? tempUnlockTime = await storage.getString('$_tempUnlockPrefix$characterId');
    
    if (tempUnlockTime != null) {
      DateTime unlockTime = DateTime.parse(tempUnlockTime);
      DateTime expireTime = unlockTime.add(tempUnlockDuration);
      if (DateTime.now().isBefore(expireTime)) {
        return expireTime.difference(DateTime.now());
      }
    }
    
    return null;
  }

  /// 显示VIP解锁对话框
  static Future<bool> showVIPUnlockDialog({
    required BuildContext context,
    required AIPersonality character,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => VIPUnlockDialog(character: character),
    ) ?? false;
  }
}

/// VIP状态枚举
enum VIPStatus {
  locked,        // 未解锁
  tempUnlocked,  // 临时解锁
  unlocked,      // 永久解锁
}
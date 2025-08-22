import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger_utils.dart';

/// 设备信息服务 - 收集和记录设备信息
class DeviceInfoService {
  static DeviceInfoService? _instance;
  static DeviceInfoService get instance => _instance ??= DeviceInfoService._();
  
  DeviceInfoService._();
  
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 获取当前用户ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  
  /// 收集设备信息（不保存，只返回数据）
  Future<Map<String, dynamic>> collectDeviceInfo() async {
    try {
      Map<String, dynamic> deviceData = {};
      
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceData = {
          'platform': 'Android',
          'manufacturer': androidInfo.manufacturer,
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'androidVersion': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
          // 扁平化支持的架构信息
          'supported32BitAbis': androidInfo.supported32BitAbis.join(','),
          'supported64BitAbis': androidInfo.supported64BitAbis.join(','),
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceData = {
          'platform': 'iOS',
          'name': iosInfo.name,
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'localizedModel': iosInfo.localizedModel,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
          'machine': iosInfo.utsname.machine,
        };
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        deviceData = {
          'platform': 'Windows',
          'computerName': windowsInfo.computerName,
          'numberOfCores': windowsInfo.numberOfCores,
          'systemMemoryMB': windowsInfo.systemMemoryInMegabytes,
          'displayVersion': windowsInfo.displayVersion,
          'editionId': windowsInfo.editionId,
        };
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        deviceData = {
          'platform': 'macOS',
          'model': macInfo.model,
          'osRelease': macInfo.osRelease,
          'activeCPUs': macInfo.activeCPUs,
          'memorySize': macInfo.memorySize,
          'arch': macInfo.arch,
          'computerName': macInfo.computerName,
        };
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        deviceData = {
          'platform': 'Linux',
          'name': linuxInfo.name,
          'version': linuxInfo.version,
          'prettyName': linuxInfo.prettyName,
        };
      }
      
      // 添加通用信息
      deviceData['locale'] = Platform.localeName;
      deviceData['numberOfProcessors'] = Platform.numberOfProcessors;
      deviceData['operatingSystem'] = Platform.operatingSystem;
      deviceData['operatingSystemVersion'] = Platform.operatingSystemVersion;
      
      LoggerUtils.info('设备信息已收集: ${deviceData['platform']} ${deviceData['model'] ?? deviceData['computerName'] ?? ''}');
      return deviceData;
    } catch (e) {
      LoggerUtils.error('收集设备信息失败: $e');
      return {};
    }
  }
  
  /// 收集设备信息并保存到Firestore（保留兼容性）
  Future<void> collectAndSaveDeviceInfo() async {
    if (currentUserId == null) {
      LoggerUtils.warning('DeviceInfoService: 无法保存设备信息，用户未登录');
      return;
    }
    
    try {
      final deviceData = await collectDeviceInfo();
      if (deviceData.isNotEmpty) {
        await _saveDeviceInfo(deviceData);
      }
    } catch (e) {
      LoggerUtils.error('收集并保存设备信息失败: $e');
    }
  }
  
  /// 保存设备信息到Firestore
  Future<void> _saveDeviceInfo(Map<String, dynamic> deviceData) async {
    if (currentUserId == null) return;
    
    try {
      // 直接保存到 users/{userId} 文档的 device 字段（不再使用设备ID作为key）
      // 注意：登录时间已在profile.lastLoginAt中记录，无需重复
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set({
            'device': deviceData
          }, SetOptions(merge: true));
      
      LoggerUtils.info('设备信息已保存到Firestore');
    } catch (e) {
      LoggerUtils.error('保存设备信息到Firestore失败: $e');
    }
  }
  
  /// 获取用户的设备信息
  Future<Map<String, dynamic>?> getUserDevice() async {
    if (currentUserId == null) return null;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      if (doc.exists && doc.data()?['device'] != null) {
        return doc.data()!['device'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      LoggerUtils.error('获取设备信息失败: $e');
      return null;
    }
  }
  
  /// 获取当前设备的ID
  Future<String> getCurrentDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return windowsInfo.deviceId;
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        return macInfo.systemGUID ?? 'unknown';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return linuxInfo.machineId ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      LoggerUtils.error('获取设备ID失败: $e');
      return 'unknown';
    }
  }
  
  /// 获取内存信息（仅Android）
  String _getTotalMemory() {
    // 这里可以通过其他方式获取更准确的内存信息
    // 暂时返回估算值
    return 'N/A';
  }
}
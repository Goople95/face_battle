import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger_utils.dart';

/// 显示设置信息服务 - 收集和记录影响游戏显示的设置
class DisplayInfoService {
  static DisplayInfoService? _instance;
  static DisplayInfoService get instance => _instance ??= DisplayInfoService._();
  
  DisplayInfoService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 获取当前用户ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  
  /// 收集显示相关设置（Flutter原生API，无需插件）
  Map<String, dynamic> collectDisplaySettings(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    // 获取文字缩放因子（兼容旧版本）
    double textScale;
    try {
      // Flutter 3.16+ 使用 textScaler
      textScale = mediaQuery.textScaler.scale(1.0);
    } catch (e) {
      // 旧版本使用 textScaleFactor
      textScale = mediaQuery.textScaleFactor;
    }
    
    final displayData = {
      // 屏幕信息
      'screen': {
        'width': mediaQuery.size.width,
        'height': mediaQuery.size.height,
        'pixelRatio': mediaQuery.devicePixelRatio,
        'aspectRatio': mediaQuery.size.aspectRatio,
        'orientation': mediaQuery.orientation.toString().split('.').last,
        'physicalWidth': mediaQuery.size.width * mediaQuery.devicePixelRatio,
        'physicalHeight': mediaQuery.size.height * mediaQuery.devicePixelRatio,
      },
      
      // 字体和文字设置
      'text': {
        'scaleFactor': textScale,
        'scaleCategory': _getTextScaleCategory(textScale),
        'boldText': mediaQuery.boldText,
      },
      
      // 时间戳
      'lastUpdated': FieldValue.serverTimestamp(),
    };
    
    return displayData;
  }
  
  /// 获取文字缩放级别分类
  String _getTextScaleCategory(double scale) {
    if (scale < 0.85) return 'extra_small';
    if (scale < 0.95) return 'small';
    if (scale < 1.05) return 'normal';
    if (scale < 1.15) return 'large';
    if (scale < 1.30) return 'extra_large';
    if (scale < 1.50) return 'huge';
    return 'extra_huge';
  }
  
  /// 保存显示设置到Firestore
  Future<void> saveDisplaySettings(BuildContext context) async {
    if (currentUserId == null) {
      LoggerUtils.warning('无法保存显示设置：用户未登录');
      return;
    }
    
    try {
      final displayData = collectDisplaySettings(context);
      
      // 保存到用户文档的display字段（与profile、device等平级）
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set({
            'display': displayData,
          }, SetOptions(merge: true));
      
      LoggerUtils.info('显示设置已保存');
      LoggerUtils.debug('显示设置详情: $displayData');
    } catch (e) {
      LoggerUtils.error('保存显示设置失败: $e');
    }
  }
  
  /// 获取显示设置
  Future<Map<String, dynamic>?> getDisplaySettings() async {
    if (currentUserId == null) return null;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        return data?['display'] as Map<String, dynamic>?;
      }
    } catch (e) {
      LoggerUtils.error('获取显示设置失败: $e');
    }
    
    return null;
  }
  
  /// 检查是否需要特殊适配
  static bool needsAccessibilityAdaptation(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    // 获取文字缩放
    double textScale;
    try {
      textScale = mediaQuery.textScaler.scale(1.0);
    } catch (e) {
      textScale = mediaQuery.textScaleFactor;
    }
    
    // 如果满足以下任一条件，需要特殊适配
    return textScale > 1.2 ||  // 文字放大超过120%
           mediaQuery.boldText ||  // 启用粗体文字
           mediaQuery.highContrast ||  // 高对比度
           mediaQuery.accessibleNavigation ||  // 无障碍导航
           mediaQuery.disableAnimations;  // 禁用动画
  }
  
  /// 检查是否是小屏幕设备
  static bool isSmallScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width < 360 || size.height < 600;
  }
  
  /// 检查是否是平板设备
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonal = (size.width * size.width + size.height * size.height);
    return diagonal > 1100 * 1100; // 大约7英寸以上
  }
}
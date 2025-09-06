import 'package:flutter/material.dart';
import 'dart:ui' show View;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger_utils.dart';
import 'storage/local_storage_service.dart';

/// 显示设置信息服务 - 收集和记录影响游戏显示的设置
class DisplayInfoService {
  static DisplayInfoService? _instance;
  static DisplayInfoService get instance => _instance ??= DisplayInfoService._();
  
  DisplayInfoService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 获取当前用户ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  
  /// 收集显示相关设置（Flutter原生API，无需插件）
  Future<Map<String, dynamic>> collectDisplaySettings(BuildContext context) async {
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
    
    // 获取用户原始的文字显示设置（系统设置的值）
    final originalTextScale = await LocalStorageService.instance.getOriginalTextScaleFactor();
    final originalBoldText = await LocalStorageService.instance.getOriginalBoldText();
    
    // 直接从View获取更多系统信息
    final view = View.of(context);
    final physicalSize = view.physicalSize;
    final viewPadding = view.padding;
    final viewInsets = view.viewInsets;
    
    final displayData = {
      // 屏幕信息（当前实际值，不做强制修改）
      'screen': {
        'width': mediaQuery.size.width,  // 当前逻辑宽度（MediaQuery直接提供）
        'height': mediaQuery.size.height,  // 当前逻辑高度（MediaQuery直接提供）
        'pixelRatio': view.devicePixelRatio,  // 像素密度（View直接提供）
        'physicalWidth': physicalSize.width,  // 物理像素宽度（View直接提供）
        'physicalHeight': physicalSize.height,  // 物理像素高度（View直接提供）
        'aspectRatio': mediaQuery.size.aspectRatio,  // 宽高比（MediaQuery计算值）
        'orientation': mediaQuery.orientation.toString().split('.').last,  // 方向（MediaQuery直接提供）
        'statusBarHeight': viewPadding.top / view.devicePixelRatio,  // 状态栏高度（逻辑像素）
        'navigationBarHeight': viewPadding.bottom / view.devicePixelRatio,  // 导航栏高度（逻辑像素）
        'keyboardHeight': viewInsets.bottom / view.devicePixelRatio,  // 键盘高度（逻辑像素）
      },
      
      // 字体和文字设置（保存原始值和强制值）
      'text': {
        'scaleFactor': textScale,  // 应用内强制的缩放因子（始终为1.0）
        'originalScaleFactor': originalTextScale ?? textScale,  // 用户系统设置的原始缩放因子
        'scaleCategory': _getTextScaleCategory(originalTextScale ?? textScale),  // 基于原始值分类
        'boldText': mediaQuery.boldText,  // 应用内的粗体设置（强制为false）
        'originalBoldText': originalBoldText ?? mediaQuery.boldText,  // 用户系统的原始粗体设置
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
      final displayData = await collectDisplaySettings(context);
      
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
import 'package:flutter/material.dart';
import '../utils/logger_utils.dart';

/// 设备字体信息工具类
class DeviceFontInfo {
  /// 获取并记录设备字体设置
  static Map<String, dynamic> getDeviceFontSettings(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    // Flutter 3.16+ 使用 textScaler，旧版本使用 textScaleFactor
    final textScale = mediaQuery.textScaler.scale(1.0);
    
    final fontSettings = {
      'textScaleFactor': textScale,
      'boldText': mediaQuery.boldText,
      'platformBrightness': mediaQuery.platformBrightness.toString(),
      'devicePixelRatio': mediaQuery.devicePixelRatio,
      'screenWidth': mediaQuery.size.width,
      'screenHeight': mediaQuery.size.height,
      'viewPadding': {
        'top': mediaQuery.viewPadding.top,
        'bottom': mediaQuery.viewPadding.bottom,
        'left': mediaQuery.viewPadding.left,
        'right': mediaQuery.viewPadding.right,
      },
      'accessibleNavigation': mediaQuery.accessibleNavigation,
      'disableAnimations': mediaQuery.disableAnimations,
      'invertColors': mediaQuery.invertColors,
      'highContrast': mediaQuery.highContrast,
    };
    
    LoggerUtils.info('设备字体设置: $fontSettings');
    return fontSettings;
  }
  
  /// 根据用户字体设置调整文字大小
  static double getAdjustedFontSize(BuildContext context, double baseFontSize) {
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    
    // 限制缩放范围，避免文字过大或过小
    final clampedScale = textScale.clamp(0.8, 1.5);
    
    return baseFontSize * clampedScale;
  }
  
  /// 检查是否需要使用更易读的字体样式
  static bool shouldUseAccessibleFont(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    // 如果用户启用了以下任一辅助功能，使用更易读的字体
    return mediaQuery.boldText || 
           mediaQuery.accessibleNavigation ||
           mediaQuery.textScaler.scale(1.0) > 1.2;
  }
  
  /// 获取字体缩放级别描述
  static String getTextScaleDescription(BuildContext context) {
    final scale = MediaQuery.of(context).textScaler.scale(1.0);
    
    if (scale < 0.9) return '小';
    if (scale < 1.1) return '标准';
    if (scale < 1.3) return '大';
    if (scale < 1.5) return '特大';
    return '超大';
  }
}
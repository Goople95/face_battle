import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 响应式工具类
/// 提供屏幕适配的便捷方法
class ResponsiveUtils {
  /// 获取适配后的宽度
  static double width(double width) => width.w;
  
  /// 获取适配后的高度
  static double height(double height) => height.h;
  
  /// 获取适配后的字体大小
  static double fontSize(double fontSize) => fontSize.sp;
  
  /// 获取适配后的半径
  static double radius(double r) => r.r;
  
  /// 获取屏幕宽度
  static double get screenWidth => 1.sw;
  
  /// 获取屏幕高度  
  static double get screenHeight => 1.sh;
  
  /// 获取状态栏高度
  static double get statusBarHeight => ScreenUtil().statusBarHeight;
  
  /// 获取底部安全区高度
  static double get bottomBarHeight => ScreenUtil().bottomBarHeight;
  
  /// 是否是平板
  static bool get isTablet => 1.sw > 600;
  
  /// 是否是小屏幕手机
  static bool get isSmallPhone => 1.sw < 360;
  
  /// 获取水平内边距（根据屏幕大小自适应）
  static double get horizontalPadding {
    if (isTablet) return 40.w;
    if (isSmallPhone) return 12.w;
    return 20.w;
  }
  
  /// 获取垂直间距（根据屏幕大小自适应）
  static double get verticalSpacing {
    if (isTablet) return 24.h;
    if (isSmallPhone) return 12.h;
    return 16.h;
  }
  
  /// 获取卡片高度（根据屏幕大小自适应）
  static double get cardHeight {
    if (isTablet) return 240.h;
    if (isSmallPhone) return 180.h;
    return 200.h;
  }
  
  /// 获取按钮高度
  static double get buttonHeight {
    if (isTablet) return 56.h;
    if (isSmallPhone) return 44.h;
    return 48.h;
  }
  
  /// 获取图标大小
  static double iconSize(double baseSize) {
    if (isTablet) return (baseSize * 1.2).w;
    if (isSmallPhone) return (baseSize * 0.9).w;
    return baseSize.w;
  }
}
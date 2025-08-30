import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

/// 带自动Analytics追踪的按钮包装器
/// 自动记录所有按钮点击事件
class TrackedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String trackName;
  final String? trackScreen;
  final Map<String, Object>? trackParams;
  final ButtonStyle? style;
  
  const TrackedButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.trackName,
    this.trackScreen,
    this.trackParams,
    this.style,
  });
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: style,
      onPressed: onPressed == null ? null : () {
        // 记录点击事件
        AnalyticsService().logButtonClick(
          buttonName: trackName,
          screen: trackScreen ?? _getCurrentRoute(context),
          additionalParams: trackParams,
        );
        
        // 执行原始回调
        onPressed!();
      },
      child: child,
    );
  }
  
  String _getCurrentRoute(BuildContext context) {
    final route = ModalRoute.of(context);
    return route?.settings.name ?? 'unknown';
  }
}

/// 带自动追踪的TextButton
class TrackedTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String trackName;
  final String? trackScreen;
  final Map<String, Object>? trackParams;
  final ButtonStyle? style;
  
  const TrackedTextButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.trackName,
    this.trackScreen,
    this.trackParams,
    this.style,
  });
  
  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: style,
      onPressed: onPressed == null ? null : () {
        // 记录点击事件
        AnalyticsService().logButtonClick(
          buttonName: trackName,
          screen: trackScreen ?? _getCurrentRoute(context),
          additionalParams: trackParams,
        );
        
        // 执行原始回调
        onPressed!();
      },
      child: child,
    );
  }
  
  String _getCurrentRoute(BuildContext context) {
    final route = ModalRoute.of(context);
    return route?.settings.name ?? 'unknown';
  }
}

/// 带自动追踪的IconButton
class TrackedIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String trackName;
  final String? trackScreen;
  final Map<String, Object>? trackParams;
  final double? iconSize;
  final Color? color;
  final String? tooltip;
  
  const TrackedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.trackName,
    this.trackScreen,
    this.trackParams,
    this.iconSize,
    this.color,
    this.tooltip,
  });
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon,
      iconSize: iconSize,
      color: color,
      tooltip: tooltip,
      onPressed: onPressed == null ? null : () {
        // 记录点击事件
        AnalyticsService().logButtonClick(
          buttonName: trackName,
          screen: trackScreen ?? _getCurrentRoute(context),
          additionalParams: trackParams,
        );
        
        // 执行原始回调
        onPressed!();
      },
    );
  }
  
  String _getCurrentRoute(BuildContext context) {
    final route = ModalRoute.of(context);
    return route?.settings.name ?? 'unknown';
  }
}

/// 带自动追踪的InkWell
class TrackedInkWell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String trackName;
  final String? trackScreen;
  final Map<String, Object>? trackParams;
  final BorderRadius? borderRadius;
  
  const TrackedInkWell({
    super.key,
    required this.child,
    required this.onTap,
    required this.trackName,
    this.trackScreen,
    this.trackParams,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: borderRadius,
      onTap: onTap == null ? null : () {
        // 记录点击事件
        AnalyticsService().logButtonClick(
          buttonName: trackName,
          screen: trackScreen ?? _getCurrentRoute(context),
          additionalParams: trackParams,
        );
        
        // 执行原始回调
        onTap!();
      },
      child: child,
    );
  }
  
  String _getCurrentRoute(BuildContext context) {
    final route = ModalRoute.of(context);
    return route?.settings.name ?? 'unknown';
  }
}

/// 带自动追踪的GestureDetector
class TrackedGestureDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String trackName;
  final String? trackScreen;
  final Map<String, Object>? trackParams;
  
  const TrackedGestureDetector({
    super.key,
    required this.child,
    required this.onTap,
    required this.trackName,
    this.trackScreen,
    this.trackParams,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null ? null : () {
        // 记录点击事件
        AnalyticsService().logButtonClick(
          buttonName: trackName,
          screen: trackScreen ?? _getCurrentRoute(context),
          additionalParams: trackParams,
        );
        
        // 执行原始回调
        onTap!();
      },
      child: child,
    );
  }
  
  String _getCurrentRoute(BuildContext context) {
    final route = ModalRoute.of(context);
    return route?.settings.name ?? 'unknown';
  }
}
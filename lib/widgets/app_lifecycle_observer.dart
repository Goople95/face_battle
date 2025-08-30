import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../utils/logger_utils.dart';

/// 应用生命周期观察者
/// 用于追踪应用进入后台、前台和退出事件
class AppLifecycleObserver extends StatefulWidget {
  final Widget child;
  
  const AppLifecycleObserver({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 应用退出时记录
    AnalyticsService().logAppLeave();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // 应用进入前台
        LoggerUtils.info('应用进入前台');
        AnalyticsService().logAppForeground();
        break;
        
      case AppLifecycleState.paused:
        // 应用进入后台
        LoggerUtils.info('应用进入后台');
        AnalyticsService().logAppBackground();
        break;
        
      case AppLifecycleState.detached:
        // 应用即将退出
        LoggerUtils.info('应用即将退出');
        AnalyticsService().logAppLeave();
        break;
        
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // 不需要特别处理
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
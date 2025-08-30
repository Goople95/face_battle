import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger_utils.dart';

/// Firebase Analytics 服务
/// 负责追踪所有用户交互事件和应用使用情况
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late FirebaseAnalytics _analytics;
  FirebaseAnalyticsObserver? _observer;
  
  // 存储最后一个事件，用于leave_app时记录
  String _lastEvent = 'app_start';
  Map<String, Object> _lastEventParams = {};
  
  // 会话开始时间
  DateTime? _sessionStartTime;
  
  /// 获取Firebase Analytics Observer用于路由追踪
  FirebaseAnalyticsObserver get observer {
    _observer ??= FirebaseAnalyticsObserver(analytics: _analytics);
    return _observer!;
  }
  
  /// 初始化Analytics服务
  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      
      // 开启自动收集
      await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
      
      // 记录会话开始
      _sessionStartTime = DateTime.now();
      await _logEvent('app_start');
      
      LoggerUtils.info('Analytics服务初始化成功');
    } catch (e) {
      LoggerUtils.error('Analytics服务初始化失败: $e');
    }
  }
  
  /// 设置用户ID
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      if (userId != null) {
        await _analytics.setUserProperty(name: 'user_type', value: 'registered');
      } else {
        await _analytics.setUserProperty(name: 'user_type', value: 'guest');
      }
    } catch (e) {
      LoggerUtils.error('设置用户ID失败: $e');
    }
  }
  
  /// 设置用户属性
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      LoggerUtils.error('设置用户属性失败: $e');
    }
  }
  
  /// 内部日志事件方法，自动更新last_event
  Future<void> _logEvent(String name, [Map<String, Object>? parameters]) async {
    try {
      // 标准化事件名（Firebase要求：小写，下划线分隔，最多40字符）
      final eventName = name.toLowerCase().replaceAll('-', '_').substring(0, name.length.clamp(0, 40));
      
      // 添加通用参数，确保类型为Map<String, Object>
      final enrichedParams = <String, Object>{
        ...?parameters,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'session_duration': _sessionStartTime != null 
            ? DateTime.now().difference(_sessionStartTime!).inSeconds 
            : 0,
      };
      
      // 记录事件
      await _analytics.logEvent(
        name: eventName,
        parameters: enrichedParams,
      );
      
      // 更新last_event
      _lastEvent = eventName;
      _lastEventParams = enrichedParams;
      await _saveLastEvent();
      
      LoggerUtils.debug('Analytics事件: $eventName, 参数: $enrichedParams');
    } catch (e) {
      LoggerUtils.error('记录Analytics事件失败: $e');
    }
  }
  
  /// 保存最后事件到本地
  Future<void> _saveLastEvent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_event', _lastEvent);
      await prefs.setString('last_event_time', DateTime.now().toIso8601String());
    } catch (e) {
      LoggerUtils.error('保存last_event失败: $e');
    }
  }
  
  /// 获取最后事件
  String getLastEvent() => _lastEvent;
  Map<String, Object> getLastEventParams() => _lastEventParams;
  
  // ===== 游戏相关事件 =====
  
  /// 记录游戏开始
  Future<void> logGameStart({
    required String npcId,
    required String npcName,
    required bool isVip,
    required int playerDrinks,
    required int npcDrinks,
  }) async {
    await _logEvent('game_start', {
      'npc_id': npcId,
      'npc_name': npcName,
      'is_vip': isVip ? 1 : 0,  // 转换为数字
      'player_drinks': playerDrinks,
      'npc_drinks': npcDrinks,
    });
  }
  
  /// 记录游戏结束
  Future<void> logGameEnd({
    required String npcId,
    required bool playerWon,
    required int rounds,
    required int duration,
    required String endReason, // 'challenge_win', 'challenge_lose', 'drunk', 'quit'
  }) async {
    await _logEvent('game_end', {
      'npc_id': npcId,
      'player_won': playerWon ? 1 : 0,  // 转换为数字
      'rounds': rounds,
      'duration_seconds': duration,
      'end_reason': endReason,
    });
  }
  
  // 移除了过于细节的出价和挑战追踪
  // 保留游戏开始和结束的宏观追踪即可
  
  // ===== UI交互事件 =====
  
  /// 记录按钮点击
  Future<void> logButtonClick({
    required String buttonName,
    required String screen,
    Map<String, Object>? additionalParams,
  }) async {
    await _logEvent('button_click', {
      'button_name': buttonName,
      'screen': screen,
      ...?additionalParams,
    });
  }
  
  /// 记录屏幕查看
  Future<void> logScreenView({
    required String screenName,
    String? previousScreen,
  }) async {
    final params = <String, Object>{
      'screen_name': screenName,
    };
    if (previousScreen != null) {
      params['previous_screen'] = previousScreen;
    }
    await _logEvent('screen_view', params);
  }
  
  /// 记录对话框显示
  Future<void> logDialogShow({
    required String dialogName,
    Map<String, Object>? params,
  }) async {
    await _logEvent('dialog_show', {
      'dialog_name': dialogName,
      ...?params,
    });
  }
  
  /// 记录对话框操作
  Future<void> logDialogAction({
    required String dialogName,
    required String action, // 'confirm', 'cancel', 'dismiss'
    Map<String, Object>? params,
  }) async {
    await _logEvent('dialog_action', {
      'dialog_name': dialogName,
      'action': action,
      ...?params,
    });
  }
  
  // ===== 广告事件 =====
  
  /// 记录广告展示
  Future<void> logAdShow({
    required String adType, // 'sobering', 'vip_unlock', 'banner'
    required String placement,
    bool rewarded = false,
  }) async {
    await _logEvent('ad_show', {
      'ad_type': adType,
      'placement': placement,
      'rewarded': rewarded ? 1 : 0,  // 转换为数字
    });
  }
  
  /// 记录广告完成
  Future<void> logAdComplete({
    required String adType,
    required String placement,
    int? rewardAmount,
  }) async {
    final params = <String, Object>{
      'ad_type': adType,
      'placement': placement,
    };
    if (rewardAmount != null) {
      params['reward_amount'] = rewardAmount;
    }
    await _logEvent('ad_complete', params);
  }
  
  /// 记录广告失败
  Future<void> logAdFailed({
    required String adType,
    required String placement,
    String? errorMessage,
  }) async {
    final params = <String, Object>{
      'ad_type': adType,
      'placement': placement,
    };
    if (errorMessage != null) {
      params['error'] = errorMessage;
    }
    await _logEvent('ad_failed', params);
  }
  
  // ===== 内购事件 =====
  
  /// 记录内购开始
  Future<void> logPurchaseStart({
    required String itemId,
    required String npcId,
    String? price,
  }) async {
    final params = <String, Object>{
      'item_id': itemId,
      'npc_id': npcId,
    };
    if (price != null) {
      params['price'] = price;
    }
    await _logEvent('purchase_start', params);
  }
  
  /// 记录内购成功
  Future<void> logPurchaseSuccess({
    required String itemId,
    required String npcId,
    String? price,
  }) async {
    final params = <String, Object>{
      'item_id': itemId,
      'npc_id': npcId,
    };
    if (price != null) {
      params['price'] = price;
    }
    await _logEvent('purchase_success', params);
    
    // 同时记录Firebase预定义的购买事件
    await _analytics.logPurchase(
      currency: 'USD',
      value: 0.99, // 从price解析
      transactionId: itemId,
      items: [
        AnalyticsEventItem(
          itemId: itemId,
          itemName: npcId,
          itemCategory: 'vip_npc',
          quantity: 1,
          price: 0.99,
        ),
      ],
    );
  }
  
  /// 记录内购失败
  Future<void> logPurchaseFailed({
    required String itemId,
    required String npcId,
    String? reason,
  }) async {
    final params = <String, Object>{
      'item_id': itemId,
      'npc_id': npcId,
    };
    if (reason != null) {
      params['reason'] = reason;
    }
    await _logEvent('purchase_failed', params);
  }
  
  // ===== 社交事件 =====
  
  /// 记录分享
  Future<void> logShare({
    required String contentType, // 'victory', 'achievement', 'invite'
    required String method, // 'wechat', 'qq', 'facebook', 'other'
    Map<String, Object>? additionalParams,
  }) async {
    await _logEvent('share', {
      'content_type': contentType,
      'method': method,
      ...?additionalParams,
    });
    
    // 同时记录Firebase预定义的分享事件
    final itemId = additionalParams?['item_id'];
    await _analytics.logShare(
      contentType: contentType,
      method: method,
      itemId: itemId is String ? itemId : contentType,  // 使用contentType作为默认itemId
    );
  }
  
  /// 记录登录
  Future<void> logLogin({
    required String method, // 'google', 'facebook', 'guest'
    bool isNewUser = false,
  }) async {
    await _logEvent('login', {
      'method': method,
      'is_new_user': isNewUser ? 1 : 0,  // 转换为数字
    });
    
    // 同时记录Firebase预定义的登录事件
    await _analytics.logLogin(loginMethod: method);
    
    if (isNewUser) {
      await _analytics.logSignUp(signUpMethod: method);
    }
  }
  
  /// 记录登出
  Future<void> logLogout() async {
    await _logEvent('logout');
  }
  
  // ===== 亲密度事件 =====
  
  /// 记录亲密度增加
  Future<void> logIntimacyGained({
    required String npcId,
    required int points,
    required int newLevel,
    required String source, // 'victory', 'drunk', 'achievement'
    bool isVipBonus = false,
  }) async {
    await _logEvent('intimacy_gained', {
      'npc_id': npcId,
      'points': points,
      'new_level': newLevel,
      'source': source,
      'is_vip_bonus': isVipBonus ? 1 : 0,  // 转换为数字
    });
  }
  
  /// 记录亲密度升级
  Future<void> logIntimacyLevelUp({
    required String npcId,
    required int oldLevel,
    required int newLevel,
  }) async {
    await _logEvent('intimacy_level_up', {
      'npc_id': npcId,
      'old_level': oldLevel,
      'new_level': newLevel,
    });
  }
  
  // ===== 应用生命周期事件 =====
  
  /// 记录应用进入后台
  Future<void> logAppBackground() async {
    await _logEvent('app_background', {
      'last_screen': _lastEvent,
      'session_duration': _sessionStartTime != null 
          ? DateTime.now().difference(_sessionStartTime!).inSeconds 
          : 0,
    });
  }
  
  /// 记录应用进入前台
  Future<void> logAppForeground() async {
    _sessionStartTime = DateTime.now();
    await _logEvent('app_foreground');
  }
  
  /// 记录应用退出（重要：包含last_event）
  Future<void> logAppLeave() async {
    await _logEvent('app_leave', {
      'last_event': _lastEvent,
      'last_event_params': _lastEventParams,
      'session_duration': _sessionStartTime != null 
          ? DateTime.now().difference(_sessionStartTime!).inSeconds 
          : 0,
    });
  }
  
  // ===== 错误和性能事件 =====
  
  /// 记录错误
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    Map<String, Object>? context,
  }) async {
    final params = <String, Object>{
      'error_type': errorType,
      'error_message': errorMessage,
    };
    if (stackTrace != null) {
      params['stack_trace'] = stackTrace.substring(0, stackTrace.length.clamp(0, 100));
    }
    if (context != null) {
      params.addAll(context);
    }
    await _logEvent('app_error', params);
  }
  
  /// 记录性能指标
  Future<void> logPerformance({
    required String metric,
    required double value,
    String? unit,
    Map<String, Object>? additionalParams,
  }) async {
    final params = <String, Object>{
      'metric': metric,
      'value': value,
    };
    if (unit != null) {
      params['unit'] = unit;
    }
    if (additionalParams != null) {
      params.addAll(additionalParams);
    }
    await _logEvent('performance_metric', params);
  }
  
  // ===== 特殊事件 =====
  
  /// 记录教程完成
  Future<void> logTutorialComplete() async {
    await _logEvent('tutorial_complete');
    await _analytics.logTutorialComplete();
  }
  
  /// 记录成就解锁
  Future<void> logAchievementUnlocked({
    required String achievementId,
    required String achievementName,
  }) async {
    await _logEvent('achievement_unlocked', {
      'achievement_id': achievementId,
      'achievement_name': achievementName,
    });
    
    await _analytics.logUnlockAchievement(id: achievementId);
  }
  
  /// 记录自定义事件
  Future<void> logCustomEvent(String name, Map<String, Object>? parameters) async {
    await _logEvent(name, parameters);
  }
}
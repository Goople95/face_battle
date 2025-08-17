import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import '../utils/logger_utils.dart';

/// AdMob广告服务 - 管理激励视频广告
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // 广告单元ID配置
  // ⚠️ 重要：应用上架前必须使用测试ID，否则可能导致账号被封
  
  // 当前使用：Google官方测试广告ID（开发阶段必须使用）
  static const String _androidRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _iosRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313';
  
  // 你的真实广告ID（仅在应用上架Google Play后启用）
  // App ID: ca-app-pub-2288762492133689~6576676662
  // 广告单元ID: ca-app-pub-2288762492133689/6016072338
  // 
  // ⚠️ 上架后取消下面的注释，并注释掉上面的测试ID
  // static const String _androidRewardedAdUnitId = 'ca-app-pub-2288762492133689/6016072338';
  // static const String _iosRewardedAdUnitId = 'ca-app-pub-2288762492133689/6016072338'; // iOS需要单独创建

  RewardedAd? _rewardedAd;
  bool _isAdReady = false;
  Function(int)? _onRewardCallback;
  Function()? _onAdClosedCallback;

  /// 获取当前平台的广告单元ID
  String get _adUnitId {
    if (Platform.isAndroid) {
      return _androidRewardedAdUnitId;
    } else if (Platform.isIOS) {
      return _iosRewardedAdUnitId;
    } else {
      throw UnsupportedError('不支持的平台');
    }
  }

  /// 初始化AdMob
  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      LoggerUtils.info('AdMob初始化成功');
      
      // 配置测试设备（开发阶段使用）
      // 需要替换为你的测试设备ID
      final testDeviceIds = <String>[
        'YOUR_TEST_DEVICE_ID', // 使用adb logcat查看
      ];
      
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testDeviceIds),
      );
      
      // 预加载第一个广告
      AdMobService().loadRewardedAd();
    } catch (e) {
      LoggerUtils.error('AdMob初始化失败: $e');
    }
  }

  /// 加载激励视频广告
  void loadRewardedAd() {
    if (_rewardedAd != null) {
      LoggerUtils.info('激励视频广告已经加载');
      return;
    }

    LoggerUtils.info('开始加载激励视频广告');
    
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          LoggerUtils.info('激励视频广告加载成功');
          _rewardedAd = ad;
          _isAdReady = true;
          _setAdCallbacks();
        },
        onAdFailedToLoad: (LoadAdError error) {
          LoggerUtils.error('激励视频广告加载失败: ${error.message}');
          _rewardedAd = null;
          _isAdReady = false;
        },
      ),
    );
  }

  /// 设置广告回调
  void _setAdCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        LoggerUtils.info('🎬 激励视频广告开始播放');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        LoggerUtils.info('🔚 激励视频广告关闭');
        
        // 保存回调的引用，因为dispose会清空它
        final callback = _onAdClosedCallback;
        
        // 先处理广告清理
        ad.dispose();
        _rewardedAd = null;
        _isAdReady = false;
        _onAdClosedCallback = null;
        
        // 调用关闭回调
        if (callback != null) {
          callback.call();
        }
        
        // 立即加载下一个广告
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        LoggerUtils.error('❌ 激励视频广告显示失败: ${error.message}');
        
        // 保存回调的引用
        final callback = _onAdClosedCallback;
        
        ad.dispose();
        _rewardedAd = null;
        _isAdReady = false;
        _onAdClosedCallback = null;
        
        // 失败时也需要调用关闭回调来关闭对话框
        if (callback != null) {
          callback.call();
        }
        
        // 重新加载广告
        loadRewardedAd();
      },
    );
  }

  /// 检查广告是否准备好
  bool get isAdReady => _isAdReady && _rewardedAd != null;

  /// 显示激励视频广告
  /// [onRewarded] 用户完成观看后的回调，参数为获得的奖励数量
  /// [onAdClosed] 广告关闭后的回调
  /// [onAdFailed] 广告加载或显示失败的回调
  Future<void> showRewardedAd({
    required Function(int rewardAmount) onRewarded,
    Function()? onAdClosed,
    Function()? onAdFailed,
  }) async {
    if (!isAdReady) {
      LoggerUtils.warning('激励视频广告还未准备好');
      onAdFailed?.call();
      
      // 尝试重新加载
      loadRewardedAd();
      return;
    }

    // 保存回调
    _onRewardCallback = onRewarded;
    _onAdClosedCallback = onAdClosed;
    
    // 重新设置回调以确保最新的_onAdClosedCallback被使用
    _setAdCallbacks();

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          LoggerUtils.info('🎁 用户获得奖励: ${reward.amount} ${reward.type}');
          
          // 给用户发放奖励（醒酒）
          _onRewardCallback?.call(reward.amount.toInt());
          _onRewardCallback = null;
        },
      );
    } catch (e) {
      LoggerUtils.error('❌ 显示激励视频广告失败: $e');
      
      // 关闭对话框
      if (onAdClosed != null) {
        onAdClosed();
      }
      
      onAdFailed?.call();
      
      // 重置状态并重新加载
      _rewardedAd = null;
      _isAdReady = false;
      _onAdClosedCallback = null;
      loadRewardedAd();
    }
  }

  /// 释放资源
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdReady = false;
    _onRewardCallback = null;
    _onAdClosedCallback = null;
  }
}
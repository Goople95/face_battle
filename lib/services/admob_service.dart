import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import '../utils/logger_utils.dart';

/// AdMob广告服务 - 管理激励视频广告
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // 广告单元ID配置
  // ⚠️ 重要：应用已上架Google Play，现在使用正式广告ID
  
  // 测试广告ID（仅开发阶段使用）
  // static const String _androidRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  // static const String _iosRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313';
  
  // 正式广告ID（应用已上架，现在启用）
  // App ID: ca-app-pub-2288762492133689~6576676662
  
  // 醒酒功能 - 视频广告单元
  static const String _androidSoberAdUnitId = 'ca-app-pub-2288762492133689/6016072338';
  static const String _iosSoberAdUnitId = 'ca-app-pub-2288762492133689/6016072338'; // iOS需要单独创建
  
  // VIP解锁 - 解锁VIP NPC广告单元
  static const String _androidVipAdUnitId = 'ca-app-pub-2288762492133689/4185800125';
  static const String _iosVipAdUnitId = 'ca-app-pub-2288762492133689/4185800125'; // iOS需要单独创建

  // 醒酒广告
  RewardedAd? _soberAd;
  bool _isSoberAdReady = false;
  
  // VIP解锁广告
  RewardedAd? _vipAd;
  bool _isVipAdReady = false;
  
  // 回调函数
  Function(int)? _onRewardCallback;
  Function()? _onAdClosedCallback;

  /// 获取醒酒广告单元ID
  String get _soberAdUnitId {
    if (Platform.isAndroid) {
      return _androidSoberAdUnitId;
    } else if (Platform.isIOS) {
      return _iosSoberAdUnitId;
    } else {
      throw UnsupportedError('不支持的平台');
    }
  }
  
  /// 获取VIP解锁广告单元ID
  String get _vipAdUnitId {
    if (Platform.isAndroid) {
      return _androidVipAdUnitId;
    } else if (Platform.isIOS) {
      return _iosVipAdUnitId;
    } else {
      throw UnsupportedError('不支持的平台');
    }
  }

  /// 初始化AdMob
  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      LoggerUtils.info('AdMob初始化成功');
      
      // 配置测试设备（防止被判定为恶意刷广告）
      // 你的Pixel 7设备ID
      final testDeviceIds = <String>[
        'AFFBC83F4469166E45CE55FF9B702A1D', // Pixel 7 (wireless)
      ];
      
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testDeviceIds),
      );
      
      // 预加载广告
      AdMobService().loadSoberAd();
      AdMobService().loadVipAd();
    } catch (e) {
      LoggerUtils.error('AdMob初始化失败: $e');
    }
  }

  /// 加载醒酒激励视频广告
  void loadSoberAd() {
    if (_soberAd != null) {
      LoggerUtils.info('醒酒广告已经加载');
      return;
    }

    LoggerUtils.info('开始加载醒酒广告');
    
    RewardedAd.load(
      adUnitId: _soberAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          LoggerUtils.info('醒酒广告加载成功');
          _soberAd = ad;
          _isSoberAdReady = true;
          _setSoberAdCallbacks();
        },
        onAdFailedToLoad: (LoadAdError error) {
          LoggerUtils.error('醒酒广告加载失败: ${error.message}');
          _soberAd = null;
          _isSoberAdReady = false;
        },
      ),
    );
  }
  
  /// 加载VIP解锁激励视频广告
  void loadVipAd() {
    if (_vipAd != null) {
      LoggerUtils.info('VIP解锁广告已经加载');
      return;
    }

    LoggerUtils.info('开始加载VIP解锁广告');
    
    RewardedAd.load(
      adUnitId: _vipAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          LoggerUtils.info('VIP解锁广告加载成功');
          _vipAd = ad;
          _isVipAdReady = true;
          _setVipAdCallbacks();
        },
        onAdFailedToLoad: (LoadAdError error) {
          LoggerUtils.error('VIP解锁广告加载失败: ${error.message}');
          _vipAd = null;
          _isVipAdReady = false;
        },
      ),
    );
  }

  /// 设置醒酒广告回调
  void _setSoberAdCallbacks() {
    _soberAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        LoggerUtils.info('🎬 醒酒广告开始播放');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        LoggerUtils.info('🔚 醒酒广告关闭');
        
        // 保存回调的引用，因为dispose会清空它
        final callback = _onAdClosedCallback;
        
        // 先处理广告清理
        ad.dispose();
        _soberAd = null;
        _isSoberAdReady = false;
        _onAdClosedCallback = null;
        
        // 调用关闭回调
        if (callback != null) {
          callback.call();
        }
        
        // 立即加载下一个广告
        loadSoberAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        LoggerUtils.error('❌ 醒酒广告显示失败: ${error.message}');
        
        // 保存回调的引用
        final callback = _onAdClosedCallback;
        
        ad.dispose();
        _soberAd = null;
        _isSoberAdReady = false;
        _onAdClosedCallback = null;
        
        // 失败时也需要调用关闭回调来关闭对话框
        if (callback != null) {
          callback.call();
        }
        
        // 重新加载广告
        loadSoberAd();
      },
    );
  }
  
  /// 设置VIP解锁广告回调
  void _setVipAdCallbacks() {
    _vipAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        LoggerUtils.info('🎬 VIP解锁广告开始播放');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        LoggerUtils.info('🔚 VIP解锁广告关闭');
        
        // 保存回调的引用，因为dispose会清空它
        final callback = _onAdClosedCallback;
        
        // 先处理广告清理
        ad.dispose();
        _vipAd = null;
        _isVipAdReady = false;
        _onAdClosedCallback = null;
        
        // 调用关闭回调
        if (callback != null) {
          callback.call();
        }
        
        // 立即加载下一个广告
        loadVipAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        LoggerUtils.error('❌ VIP解锁广告显示失败: ${error.message}');
        
        // 保存回调的引用
        final callback = _onAdClosedCallback;
        
        ad.dispose();
        _vipAd = null;
        _isVipAdReady = false;
        _onAdClosedCallback = null;
        
        // 失败时也需要调用关闭回调来关闭对话框
        if (callback != null) {
          callback.call();
        }
        
        // 重新加载广告
        loadVipAd();
      },
    );
  }

  /// 检查醒酒广告是否准备好
  bool get isSoberAdReady => _isSoberAdReady && _soberAd != null;
  
  /// 检查VIP解锁广告是否准备好
  bool get isVipAdReady => _isVipAdReady && _vipAd != null;
  
  /// 检查广告是否准备好（兼容旧代码）
  bool get isAdReady => isSoberAdReady;

  /// 显示醒酒激励视频广告
  /// [onRewarded] 用户完成观看后的回调，参数为获得的奖励数量
  /// [onAdClosed] 广告关闭后的回调
  /// [onAdFailed] 广告加载或显示失败的回调
  Future<void> showSoberAd({
    required Function(int rewardAmount) onRewarded,
    Function()? onAdClosed,
    Function()? onAdFailed,
  }) async {
    if (!isSoberAdReady) {
      LoggerUtils.warning('醒酒广告还未准备好');
      onAdFailed?.call();
      
      // 尝试重新加载
      loadSoberAd();
      return;
    }

    // 保存回调
    _onRewardCallback = onRewarded;
    _onAdClosedCallback = onAdClosed;
    
    // 重新设置回调以确保最新的_onAdClosedCallback被使用
    _setSoberAdCallbacks();

    try {
      await _soberAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          LoggerUtils.info('🎁 用户获得醒酒奖励: ${reward.amount} ${reward.type}');
          
          // 给用户发放奖励（醒酒）
          _onRewardCallback?.call(reward.amount.toInt());
          _onRewardCallback = null;
        },
      );
    } catch (e) {
      LoggerUtils.error('❌ 显示醒酒广告失败: $e');
      
      // 关闭对话框
      if (onAdClosed != null) {
        onAdClosed();
      }
      
      onAdFailed?.call();
      
      // 重置状态并重新加载
      _soberAd = null;
      _isSoberAdReady = false;
      _onAdClosedCallback = null;
      loadSoberAd();
    }
  }
  
  /// 显示VIP解锁激励视频广告
  /// [onRewarded] 用户完成观看后的回调，参数为获得的奖励数量
  /// [onAdClosed] 广告关闭后的回调
  /// [onAdFailed] 广告加载或显示失败的回调
  Future<void> showVipAd({
    required Function(int rewardAmount) onRewarded,
    Function()? onAdClosed,
    Function()? onAdFailed,
  }) async {
    if (!isVipAdReady) {
      LoggerUtils.warning('VIP解锁广告还未准备好');
      onAdFailed?.call();
      
      // 尝试重新加载
      loadVipAd();
      return;
    }

    // 保存回调
    _onRewardCallback = onRewarded;
    _onAdClosedCallback = onAdClosed;
    
    // 重新设置回调以确保最新的_onAdClosedCallback被使用
    _setVipAdCallbacks();

    try {
      await _vipAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          LoggerUtils.info('🎁 用户获得VIP解锁奖励: ${reward.amount} ${reward.type}');
          
          // 给用户发放奖励（VIP解锁）
          _onRewardCallback?.call(reward.amount.toInt());
          _onRewardCallback = null;
        },
      );
    } catch (e) {
      LoggerUtils.error('❌ 显示VIP解锁广告失败: $e');
      
      // 关闭对话框
      if (onAdClosed != null) {
        onAdClosed();
      }
      
      onAdFailed?.call();
      
      // 重置状态并重新加载
      _vipAd = null;
      _isVipAdReady = false;
      _onAdClosedCallback = null;
      loadVipAd();
    }
  }
  
  /// 显示激励视频广告（兼容旧代码，默认显示醒酒广告）
  Future<void> showRewardedAd({
    required Function(int rewardAmount) onRewarded,
    Function()? onAdClosed,
    Function()? onAdFailed,
  }) async {
    return showSoberAd(
      onRewarded: onRewarded,
      onAdClosed: onAdClosed,
      onAdFailed: onAdFailed,
    );
  }

  /// 释放资源
  void dispose() {
    _soberAd?.dispose();
    _soberAd = null;
    _isSoberAdReady = false;
    
    _vipAd?.dispose();
    _vipAd = null;
    _isVipAdReady = false;
    
    _onRewardCallback = null;
    _onAdClosedCallback = null;
  }
}
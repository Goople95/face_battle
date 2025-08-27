import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import '../utils/logger_utils.dart';

/// Firebase Dynamic Links 服务
/// 用于生成可追踪的动态链接
class DynamicLinkService {
  static FirebaseDynamicLinks dynamicLinks = FirebaseDynamicLinks.instance;
  
  /// 生成带追踪参数的动态链接
  static Future<String> generateShareLink({
    required String aiName,
    required int drinkCount,
    required int intimacyMinutes,
    String? userId,
  }) async {
    try {
      // 生成唯一的campaign ID
      final campaignId = 'share_${DateTime.now().millisecondsSinceEpoch}';
      
      // Google Play 商店链接，带UTM参数
      final playStoreUrl = Uri.parse('https://play.google.com/store/apps/details'
          '?id=com.odt.liarsdice'
          '&utm_source=qr_share'
          '&utm_medium=social'
          '&utm_campaign=$campaignId'
          '&referrer=utm_source%3Dqr_share%26utm_medium%3Dsocial');
      
      // 创建动态链接参数
      final DynamicLinkParameters parameters = DynamicLinkParameters(
        // 使用你的Firebase项目的动态链接域名
        // 需要在Firebase Console中设置
        uriPrefix: 'https://dicegirls.page.link',
        link: playStoreUrl,
        androidParameters: AndroidParameters(
          packageName: 'com.odt.liarsdice',
          minimumVersion: 0,
          // 如果未安装，跳转到Play商店
          fallbackUrl: playStoreUrl,
        ),
        iosParameters: IOSParameters(
          bundleId: 'com.odt.liarsdice',
          minimumVersion: '0',
          // iOS商店链接（需要上架后替换）
          appStoreId: 'YOUR_APP_STORE_ID',
          fallbackUrl: playStoreUrl,
        ),
        // 社交媒体分享的元数据
        socialMetaTagParameters: SocialMetaTagParameters(
          title: 'Dice Girls - 完美胜利！',
          description: '我把$aiName灌醉了！喝了$drinkCount杯，独处了$intimacyMinutes分钟～',
          imageUrl: Uri.parse('https://yourdomain.com/share_image.png'), // 需要替换为真实的分享图片URL
        ),
        // Google Analytics参数
        googleAnalyticsParameters: GoogleAnalyticsParameters(
          campaign: campaignId,
          medium: 'social',
          source: 'qr_share',
        ),
        // 导航参数
        navigationInfoParameters: NavigationInfoParameters(
          forcedRedirectEnabled: false,
        ),
      );
      
      // 生成短链接
      final shortLink = await dynamicLinks.buildShortLink(
        parameters,
        shortLinkType: ShortDynamicLinkType.unguessable,
      );
      
      LoggerUtils.info('生成动态链接成功: ${shortLink.shortUrl}');
      LoggerUtils.debug('追踪参数: campaign=$campaignId');
      
      return shortLink.shortUrl.toString();
      
    } catch (e) {
      LoggerUtils.error('生成动态链接失败: $e');
      // 如果动态链接失败，返回原始Play商店链接
      return 'https://play.google.com/store/apps/details?id=com.odt.liarsdice';
    }
  }
  
  /// 初始化动态链接监听（在app启动时调用）
  static Future<void> initDynamicLinks() async {
    try {
      // 处理app未运行时点击的链接
      final PendingDynamicLinkData? initialLink = 
          await FirebaseDynamicLinks.instance.getInitialLink();
      if (initialLink != null) {
        _handleDynamicLink(initialLink);
      }
      
      // 处理app运行时点击的链接
      FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
        _handleDynamicLink(dynamicLinkData);
      }).onError((error) {
        LoggerUtils.error('动态链接监听错误: $error');
      });
      
    } catch (e) {
      LoggerUtils.error('初始化动态链接失败: $e');
    }
  }
  
  /// 处理动态链接数据
  static void _handleDynamicLink(PendingDynamicLinkData data) {
    final Uri deepLink = data.link;
    LoggerUtils.info('接收到动态链接: $deepLink');
    
    // 解析UTM参数
    final utmSource = deepLink.queryParameters['utm_source'];
    final utmMedium = deepLink.queryParameters['utm_medium'];
    final utmCampaign = deepLink.queryParameters['utm_campaign'];
    
    LoggerUtils.info('UTM参数: source=$utmSource, medium=$utmMedium, campaign=$utmCampaign');
    
    // 这里可以根据参数做进一步处理
    // 比如记录到Firebase Analytics
    _trackInstallSource(utmSource, utmMedium, utmCampaign);
  }
  
  /// 追踪安装来源
  static void _trackInstallSource(String? source, String? medium, String? campaign) {
    // 这里可以集成Firebase Analytics或其他分析工具
    // 记录安装来源
    LoggerUtils.info('记录安装来源: source=$source, medium=$medium, campaign=$campaign');
    
    // 示例：保存到SharedPreferences，后续可以在app内使用
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('install_source', source ?? 'unknown');
    // await prefs.setString('install_campaign', campaign ?? 'unknown');
  }
  
  /// 获取分享统计数据（从Firebase或你的后端）
  static Future<Map<String, dynamic>> getShareStatistics(String campaignId) async {
    try {
      // 这里可以从Firebase Firestore获取统计数据
      // 或者从你的后端API获取
      return {
        'scans': 0,  // 扫码次数
        'installs': 0,  // 安装次数
        'conversions': 0,  // 转化率
      };
    } catch (e) {
      LoggerUtils.error('获取分享统计失败: $e');
      return {};
    }
  }
}
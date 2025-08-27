import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 分享追踪服务（不依赖Firebase Dynamic Links）
/// 使用UTM参数和短链接服务
class ShareTrackingService {
  
  /// 生成带追踪参数的Play商店链接
  static String generateTrackedPlayStoreLink({
    required String aiName,
    required int drinkCount,
    required int intimacyMinutes,
    String? userId,
  }) {
    // 生成唯一的campaign ID
    final campaignId = 'share_${DateTime.now().millisecondsSinceEpoch}';
    
    // 基础Play商店链接
    const baseUrl = 'https://play.google.com/store/apps/details';
    
    // 构建UTM参数
    final queryParams = {
      'id': 'com.odt.liarsdice',
      'utm_source': 'qr_share',
      'utm_medium': 'social', 
      'utm_campaign': campaignId,
      'utm_content': 'ai_${aiName}_drinks_$drinkCount',
      // referrer参数会被Google Play记录
      'referrer': Uri.encodeComponent(
        'utm_source=qr_share'
        '&utm_medium=social'
        '&utm_campaign=$campaignId'
        '${userId != null ? '&uid=$userId' : ''}'
      ),
    };
    
    // 构建完整URL
    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    final fullUrl = uri.toString();
    
    LoggerUtils.info('生成追踪链接: $fullUrl');
    LoggerUtils.debug('Campaign ID: $campaignId');
    
    // 保存分享记录到本地（可选）
    _saveShareRecord(campaignId, aiName, drinkCount, intimacyMinutes);
    
    return fullUrl;
  }
  
  /// 使用短链接服务（可选：Bitly, TinyURL等）
  static Future<String> generateShortLink({
    required String longUrl,
    String? customAlias,
  }) async {
    // 方案1：使用Bitly API（需要注册获取token）
    // return await _shortenWithBitly(longUrl);
    
    // 方案2：使用TinyURL（免费，无需认证）
    return await _shortenWithTinyUrl(longUrl);
    
    // 方案3：直接返回原链接（如果短链服务失败）
    // return longUrl;
  }
  
  /// 使用TinyURL生成短链接（免费服务）
  static Future<String> _shortenWithTinyUrl(String longUrl) async {
    try {
      final apiUrl = 'https://tinyurl.com/api-create.php?url=${Uri.encodeComponent(longUrl)}';
      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final shortUrl = response.body;
        LoggerUtils.info('TinyURL短链接生成成功: $shortUrl');
        return shortUrl;
      } else {
        LoggerUtils.error('TinyURL请求失败: ${response.statusCode}');
        return longUrl; // 失败时返回原链接
      }
    } catch (e) {
      LoggerUtils.error('生成短链接失败: $e');
      return longUrl; // 出错时返回原链接
    }
  }
  
  /// 使用Bitly生成短链接（需要API token）
  static Future<String> _shortenWithBitly(String longUrl) async {
    // Bitly API需要注册账号获取token
    // 免费账号每月1000个链接，可以看详细统计
    const bitlyToken = 'YOUR_BITLY_TOKEN'; // 需要替换为实际token
    
    if (bitlyToken == 'YOUR_BITLY_TOKEN') {
      // 如果没有配置token，使用TinyURL
      return _shortenWithTinyUrl(longUrl);
    }
    
    try {
      final response = await http.post(
        Uri.parse('https://api-ssl.bitly.com/v4/shorten'),
        headers: {
          'Authorization': 'Bearer $bitlyToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'long_url': longUrl,
          'domain': 'bit.ly',
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final shortUrl = data['link'];
        LoggerUtils.info('Bitly短链接生成成功: $shortUrl');
        return shortUrl;
      } else {
        LoggerUtils.error('Bitly请求失败: ${response.statusCode}');
        return longUrl;
      }
    } catch (e) {
      LoggerUtils.error('Bitly生成短链接失败: $e');
      return longUrl;
    }
  }
  
  /// 保存分享记录到本地
  static Future<void> _saveShareRecord(
    String campaignId,
    String aiName,
    int drinkCount,
    int intimacyMinutes,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取现有记录
      final existingRecords = prefs.getStringList('share_records') ?? [];
      
      // 创建新记录
      final newRecord = json.encode({
        'campaign_id': campaignId,
        'timestamp': DateTime.now().toIso8601String(),
        'ai_name': aiName,
        'drink_count': drinkCount,
        'intimacy_minutes': intimacyMinutes,
      });
      
      // 添加新记录（最多保存最近100条）
      existingRecords.insert(0, newRecord);
      if (existingRecords.length > 100) {
        existingRecords.removeRange(100, existingRecords.length);
      }
      
      // 保存
      await prefs.setStringList('share_records', existingRecords);
      
      // 更新分享次数统计
      final shareCount = prefs.getInt('total_share_count') ?? 0;
      await prefs.setInt('total_share_count', shareCount + 1);
      
      LoggerUtils.debug('分享记录已保存: $campaignId');
    } catch (e) {
      LoggerUtils.error('保存分享记录失败: $e');
    }
  }
  
  /// 获取分享统计
  static Future<Map<String, dynamic>> getShareStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final totalShares = prefs.getInt('total_share_count') ?? 0;
      final records = prefs.getStringList('share_records') ?? [];
      
      // 解析最近的分享记录
      final recentShares = records.take(10).map((record) {
        try {
          return json.decode(record);
        } catch (e) {
          return null;
        }
      }).where((item) => item != null).toList();
      
      return {
        'total_shares': totalShares,
        'recent_shares': recentShares,
        'last_share_date': recentShares.isNotEmpty 
            ? recentShares.first['timestamp'] 
            : null,
      };
    } catch (e) {
      LoggerUtils.error('获取分享统计失败: $e');
      return {
        'total_shares': 0,
        'recent_shares': [],
        'last_share_date': null,
      };
    }
  }
  
  /// 追踪安装来源（在app启动时调用）
  static Future<void> trackInstallSource() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 检查是否已经记录过安装来源
      final hasTrackedInstall = prefs.getBool('has_tracked_install') ?? false;
      if (hasTrackedInstall) {
        return;
      }
      
      // 这里可以通过其他方式获取安装来源
      // 例如：通过剪贴板、深度链接等
      
      // 标记已追踪
      await prefs.setBool('has_tracked_install', true);
      
      LoggerUtils.info('安装来源追踪完成');
    } catch (e) {
      LoggerUtils.error('追踪安装来源失败: $e');
    }
  }
}
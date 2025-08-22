import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger_utils.dart';

/// IP地理位置服务 - 获取用户所在国家
class IpLocationService {
  static IpLocationService? _instance;
  static IpLocationService get instance => _instance ??= IpLocationService._();
  
  IpLocationService._();
  
  // 使用多个免费的IP地理位置API作为备选
  static const List<String> _apiEndpoints = [
    'http://ip-api.com/json/',           // 主要API，免费限制：45次/分钟
    'https://ipapi.co/json/',             // 备选API1，免费限制：1000次/天
    'https://api.ipgeolocation.io/ipgeo?apiKey=free',  // 备选API2，免费版
  ];
  
  /// 获取用户当前IP的国家信息
  Future<Map<String, dynamic>> getUserCountryInfo() async {
    for (final endpoint in _apiEndpoints) {
      try {
        final result = await _fetchFromEndpoint(endpoint);
        if (result != null) {
          return result;
        }
      } catch (e) {
        LoggerUtils.warning('从 $endpoint 获取IP信息失败: $e');
        continue; // 尝试下一个API
      }
    }
    
    // 所有API都失败，返回默认值
    return {
      'country': 'Unknown',
      'countryCode': 'XX',
      'city': 'Unknown',
      'ip': 'Unknown',
    };
  }
  
  /// 从特定端点获取IP信息
  Future<Map<String, dynamic>?> _fetchFromEndpoint(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse(endpoint),
      ).timeout(Duration(seconds: 5)); // 5秒超时
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 标准化不同API的返回格式
        if (endpoint.contains('ip-api.com')) {
          return {
            'country': data['country'] ?? 'Unknown',
            'countryCode': data['countryCode'] ?? 'XX',
            'city': data['city'] ?? 'Unknown',
            'region': data['regionName'] ?? 'Unknown',
            'ip': data['query'] ?? 'Unknown',
            'timezone': data['timezone'] ?? 'Unknown',
            'isp': data['isp'] ?? 'Unknown',
          };
        } else if (endpoint.contains('ipapi.co')) {
          return {
            'country': data['country_name'] ?? 'Unknown',
            'countryCode': data['country_code'] ?? 'XX',
            'city': data['city'] ?? 'Unknown',
            'region': data['region'] ?? 'Unknown',
            'ip': data['ip'] ?? 'Unknown',
            'timezone': data['timezone'] ?? 'Unknown',
            'isp': data['org'] ?? 'Unknown',
          };
        } else if (endpoint.contains('ipgeolocation.io')) {
          return {
            'country': data['country_name'] ?? 'Unknown',
            'countryCode': data['country_code2'] ?? 'XX',
            'city': data['city'] ?? 'Unknown',
            'region': data['state_prov'] ?? 'Unknown',
            'ip': data['ip'] ?? 'Unknown',
            'timezone': data['time_zone']?['name'] ?? 'Unknown',
            'isp': data['isp'] ?? 'Unknown',
          };
        }
      }
      
      return null;
    } catch (e) {
      LoggerUtils.error('获取IP地理位置失败: $e');
      return null;
    }
  }
  
  /// 获取简化的国家代码（仅国家代码）
  Future<String> getCountryCode() async {
    try {
      final info = await getUserCountryInfo();
      return info['countryCode'] ?? 'XX';
    } catch (e) {
      LoggerUtils.error('获取国家代码失败: $e');
      return 'XX';
    }
  }
  
  /// 将时区名称转换为UTC偏移量（如 UTC+8）
  static String getUTCOffset(String? timezone) {
    if (timezone == null || timezone == 'Unknown') {
      return 'UTC+0';
    }
    
    // 常见时区的UTC偏移量映射
    final Map<String, String> timezoneOffsets = {
      // 美洲
      'America/Los_Angeles': 'UTC-8',      // 美国西海岸
      'America/Denver': 'UTC-7',           // 美国山地时间
      'America/Chicago': 'UTC-6',          // 美国中部
      'America/New_York': 'UTC-5',         // 美国东海岸
      'America/Sao_Paulo': 'UTC-3',        // 巴西
      'America/Mexico_City': 'UTC-6',      // 墨西哥
      'America/Toronto': 'UTC-5',          // 加拿大东部
      'America/Vancouver': 'UTC-8',        // 加拿大西部
      
      // 欧洲
      'Europe/London': 'UTC+0',            // 英国
      'Europe/Paris': 'UTC+1',             // 法国
      'Europe/Berlin': 'UTC+1',            // 德国
      'Europe/Madrid': 'UTC+1',            // 西班牙
      'Europe/Rome': 'UTC+1',              // 意大利
      'Europe/Moscow': 'UTC+3',            // 俄罗斯
      'Europe/Istanbul': 'UTC+3',          // 土耳其
      'Europe/Amsterdam': 'UTC+1',         // 荷兰
      
      // 亚洲
      'Asia/Shanghai': 'UTC+8',            // 中国
      'Asia/Hong_Kong': 'UTC+8',           // 香港
      'Asia/Taipei': 'UTC+8',              // 台湾
      'Asia/Tokyo': 'UTC+9',               // 日本
      'Asia/Seoul': 'UTC+9',               // 韩国
      'Asia/Singapore': 'UTC+8',           // 新加坡
      'Asia/Bangkok': 'UTC+7',             // 泰国
      'Asia/Jakarta': 'UTC+7',             // 印尼
      'Asia/Kolkata': 'UTC+5:30',          // 印度
      'Asia/Dubai': 'UTC+4',               // 阿联酋
      'Asia/Manila': 'UTC+8',              // 菲律宾
      'Asia/Kuala_Lumpur': 'UTC+8',        // 马来西亚
      
      // 大洋洲
      'Australia/Sydney': 'UTC+10',        // 澳大利亚东部
      'Australia/Melbourne': 'UTC+10',     // 墨尔本
      'Australia/Perth': 'UTC+8',          // 澳大利亚西部
      'Pacific/Auckland': 'UTC+12',        // 新西兰
      
      // 非洲
      'Africa/Cairo': 'UTC+2',             // 埃及
      'Africa/Johannesburg': 'UTC+2',      // 南非
      'Africa/Lagos': 'UTC+1',             // 尼日利亚
    };
    
    // 如果找到匹配的时区，返回对应的UTC偏移
    if (timezoneOffsets.containsKey(timezone)) {
      return timezoneOffsets[timezone]!;
    }
    
    // 尝试从时区字符串推断（处理其他格式）
    // 例如：GMT+8, UTC+8 等格式
    if (timezone.contains('GMT+') || timezone.contains('UTC+')) {
      final match = RegExp(r'[+-]\d+').firstMatch(timezone);
      if (match != null) {
        return 'UTC${match.group(0)}';
      }
    }
    
    // 默认返回UTC+0
    return 'UTC+0';
  }
  
  /// 获取国家名称
  Future<String> getCountryName() async {
    try {
      final info = await getUserCountryInfo();
      return info['country'] ?? 'Unknown';
    } catch (e) {
      LoggerUtils.error('获取国家名称失败: $e');
      return 'Unknown';
    }
  }
}
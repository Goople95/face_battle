import 'package:flutter/widgets.dart';
import '../services/npc_config_service.dart';

/// AI personality configuration
class AIPersonality {
  final String id;
  final String name;
  final String description;
  final Map<String, String>? namesMap;        // 多语言名称映射
  final Map<String, String>? descriptionsMap; // 多语言描述映射
  final String avatarPath;        // 头像图片路径
  final double bluffRatio;        // 虚张声势的概率 (0-1)
  final double challengeThreshold; // 质疑的阈值 (0-1)
  final double riskAppetite;      // 风险偏好 (0-1)
  final double mistakeRate;       // 错误率 (0-1)
  final double tellExposure;      // 暴露破绽的概率 (0-1)
  final double reverseActingProb; // 反向表演的概率
  final double bidPreferenceThreshold; // 叫牌偏好阈值（叫牌成功率超过质疑成功率多少时选择叫牌）
  final bool isVIP;               // 是否是VIP角色
  final String? country;          // 国家/地区
  final int drinkCapacity;        // 酒量（能喝几杯）
  
  const AIPersonality({
    required this.id,
    required this.name,
    required this.description,
    this.namesMap,
    this.descriptionsMap,
    required this.avatarPath,
    required this.bluffRatio,
    required this.challengeThreshold,
    required this.riskAppetite,
    required this.mistakeRate,
    required this.tellExposure,
    required this.reverseActingProb,
    required this.bidPreferenceThreshold,
    this.isVIP = false,
    this.country,
    this.drinkCapacity = 4,  // 默认4杯
  });
  
  // 根据指定的locale获取名称
  String getLocalizedName(String localeCode) {
    if (namesMap == null || namesMap!.isEmpty) {
      return name;
    }
    return namesMap![localeCode] ?? namesMap!['en'] ?? name;
  }
  
  // 根据指定的locale获取描述
  String getLocalizedDescription(String localeCode) {
    if (descriptionsMap == null || descriptionsMap!.isEmpty) {
      return description;
    }
    return descriptionsMap![localeCode] ?? descriptionsMap!['en'] ?? description;
  }
  
  // 保留旧的getter以保持兼容性（使用系统语言）
  String get localizedName {
    if (namesMap == null || namesMap!.isEmpty) {
      return name;
    }
    
    // 使用PlatformDispatcher替代deprecated的window
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;
    
    // 处理中文的特殊情况
    String localeCode = languageCode;
    if (languageCode == 'zh') {
      if (countryCode == 'TW' || countryCode == 'HK' || countryCode == 'MO') {
        localeCode = 'zh_TW';
      } else {
        localeCode = 'zh';
      }
    }
    
    // 尝试获取对应语言的名称，如果没有则使用英文或默认名称
    return namesMap![localeCode] ?? namesMap!['en'] ?? name;
  }
  
  // 保留旧的getter以保持兼容性（使用系统语言）
  String get localizedDescription {
    if (descriptionsMap == null || descriptionsMap!.isEmpty) return description;
    
    // 使用PlatformDispatcher替代deprecated的window
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;
    
    // 处理中文的特殊情况
    String localeCode = languageCode;
    if (languageCode == 'zh') {
      if (countryCode == 'TW' || countryCode == 'HK' || countryCode == 'MO') {
        localeCode = 'zh_TW';
      } else {
        localeCode = 'zh';
      }
    }
    
    // 尝试获取对应语言的描述，如果没有则使用英文或默认描述
    return descriptionsMap![localeCode] ?? descriptionsMap!['en'] ?? description;
  }
}

// AI角色配置现在从JSON文件加载
// 为了兼容旧代码，保留AIPersonalities类但改为代理到NPCConfigService

class AIPersonalities {
  static final _service = NPCConfigService();
  
  // 代理到配置服务 - 只保留女性角色
  static AIPersonality get provocateur => _service.provocateur;
  static AIPersonality get youngwoman => _service.youngwoman;
  static AIPersonality get aki => _service.aki;
  static AIPersonality get katerina => _service.katerina;
  static AIPersonality get lena => _service.lena;
  static AIPersonality get isabella => _service.isabella;
  
  static List<AIPersonality> get normalCharacters => _service.normalCharacters;
  static List<AIPersonality> get vipCharacters => _service.vipCharacters;
  static List<AIPersonality> get allCharacters => _service.allCharacters;
}
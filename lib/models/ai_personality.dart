import '../services/npc_config_service.dart';

/// AI personality configuration
class AIPersonality {
  final String id;
  final String name;
  final String description;
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
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
  final List<String> taunts;      // 嘲讽语句
  
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
    required this.taunts,
  });
}

// Predefined AI personalities
class AIPersonalities {
  static const professor = AIPersonality(
    id: 'professor',
    name: '稳重大叔',
    description: '精于计算，善于分析',
    avatarPath: 'assets/people/man/man.png',
    bluffRatio: 0.25,         // 稍微提高虚张率，更合理
    challengeThreshold: 0.4,   // 40%以下才质疑（更理性）
    riskAppetite: 0.3,
    mistakeRate: 0.03,         // 降低错误率，保持精准
    tellExposure: 0.1,
    reverseActingProb: 0.05,
    bidPreferenceThreshold: 0.05,  // 只要叫牌成功率比质疑高5%就选择叫牌（非常稳健）
    taunts: [
      '根据我的计算，你在虚张声势',
      '概率论不会骗人',
      '让我教你什么是数学',
    ],
  );
  
  static const gambler = AIPersonality(
    id: 'gambler',
    name: '冲动小哥',
    description: '大胆激进，喜欢冒险',
    avatarPath: 'assets/people/youngman/youngman.png',
    bluffRatio: 0.5,           // 稍降低虚张率，避免过度冲动
    challengeThreshold: 0.35,  // 35%以下才质疑（更理性）
    riskAppetite: 0.7,         // 稍降低风险偏好
    mistakeRate: 0.08,         // 大幅降低错误率
    tellExposure: 0.25,        // 稍降低破绽暴露
    reverseActingProb: 0.1,
    bidPreferenceThreshold: 0.20,  // 叫牌成功率要比质疑高20%才选择叫牌（喜欢冒险）
    taunts: [
      '敢不敢跟我赌一把大的？',
      '运气总是站在勇敢者这边',
      '你太保守了，朋友',
    ],
  );
  
  static const provocateur = AIPersonality(
    id: 'provocateur',
    name: '心机御姐',
    description: '善于心理战，喜欢误导',
    avatarPath: 'assets/people/woman/woman.png',
    bluffRatio: 0.35,          // 稍降低虚张率
    challengeThreshold: 0.4,   // 40%以下才质疑（更理性）
    riskAppetite: 0.5,
    mistakeRate: 0.05,         // 降低错误率
    tellExposure: 0.15,        // 稍降低破绽暴露
    reverseActingProb: 0.2,
    bidPreferenceThreshold: 0.10,  // 叫牌成功率比质疑高10%就选择叫牌（平衡型）
    taunts: [
      '你确定要这么叫吗？',
      '我知道你在想什么',
      '你的表情出卖了你',
      '别紧张，放轻松',
    ],
  );
  
  static const youngwoman = AIPersonality(
    id: 'youngwoman',
    name: '活泼少女',
    description: '直觉敏锐，偶尔任性',
    avatarPath: 'assets/people/youngwoman/youngwoman.png',
    bluffRatio: 0.4,           // 稍降低虚张率
    challengeThreshold: 0.38,  // 38%以下才质疑（更理性）
    riskAppetite: 0.55,        // 稍降低风险偏好
    mistakeRate: 0.06,         // 大幅降低错误率
    tellExposure: 0.2,         // 稍降低破绽暴露
    reverseActingProb: 0.15,
    bidPreferenceThreshold: 0.15,  // 叫牌成功率比质疑高15%就选择叫牌（稍偏激进）
    taunts: [
      '我的直觉告诉我你在骗人',
      '哼，你肯定没有那么多',
      '让本小姐来教训你',
      '你的运气到此为止了',
    ],
  );
}
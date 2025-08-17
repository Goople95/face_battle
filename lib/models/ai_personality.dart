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
  final bool isVIP;               // 是否是VIP角色
  final String? country;          // 国家/地区
  final String? difficulty;       // 难度等级
  
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
    this.isVIP = false,
    this.country,
    this.difficulty,
  });
}

// Predefined AI personalities
class AIPersonalities {
  static const professor = AIPersonality(
    id: '0001',
    name: '稳重大叔',
    description: '精于计算，善于分析',
    avatarPath: 'assets/people/0001/',
    bluffRatio: 0.3,          // 适度虚张，不完全诚实
    challengeThreshold: 0.45,  // 45%以下才质疑（理性但不过度保守）
    riskAppetite: 0.35,        // 稍微提高风险偏好
    mistakeRate: 0.02,         // 极低错误率，几乎不出错
    tellExposure: 0.08,        // 很少暴露破绽
    reverseActingProb: 0.1,    // 偶尔反向表演
    bidPreferenceThreshold: 0.08,
    taunts: [
      '根据我的计算，你在虚张声势',
      '概率论不会骗人',
      '让我教你什么是数学',
    ],
  );
  
  static const gambler = AIPersonality(
    id: '0002',
    name: '冲动小哥',
    description: '大胆激进，喜欢冒险',
    avatarPath: 'assets/people/0002/',
    bluffRatio: 0.55,          // 经常虚张，大胆冒险
    challengeThreshold: 0.5,   // 50%以下就质疑（激进）
    riskAppetite: 0.75,        // 高风险偏好
    mistakeRate: 0.05,         // 适度错误率
    tellExposure: 0.2,         // 一定破绽暴露
    reverseActingProb: 0.15,   // 偶尔反向表演
    bidPreferenceThreshold: 0.15,
    taunts: [
      '敢不敢跟我赌一把大的？',
      '运气总是站在勇敢者这边',
      '你太保守了，朋友',
    ],
  );
  
  static const provocateur = AIPersonality(
    id: '0003',
    name: '心机御姐',
    description: '善于心理战，喜欢误导',
    avatarPath: 'assets/people/0003/',
    bluffRatio: 0.45,          // 经常虚张误导
    challengeThreshold: 0.48,  // 48%以下就质疑（敏锐）
    riskAppetite: 0.55,        // 中等风险偏好
    mistakeRate: 0.03,         // 极低错误率，心思缜密
    tellExposure: 0.1,         // 很少暴露真实情绪
    reverseActingProb: 0.3,    // 经常反向表演迷惑对手
    bidPreferenceThreshold: 0.12,
    taunts: [
      '你确定要这么叫吗？',
      '我知道你在想什么',
      '你的表情出卖了你',
      '别紧张，放轻松',
    ],
  );
  
  static const youngwoman = AIPersonality(
    id: '0004',
    name: '活泼少女',
    description: '直觉敏锐，偶尔任性',
    avatarPath: 'assets/people/0004/',
    bluffRatio: 0.42,          // 适度虚张，变化多端
    challengeThreshold: 0.46,  // 46%以下就质疑（直觉型）
    riskAppetite: 0.6,         // 中高风险偏好
    mistakeRate: 0.04,         // 较低错误率
    tellExposure: 0.15,        // 适度破绽暴露
    reverseActingProb: 0.2,    // 经常任性表演
    bidPreferenceThreshold: 0.13,
    taunts: [
      '我的直觉告诉我你在骗人',
      '哼，你肯定没有那么多',
      '让本小姐来教训你',
      '你的运气到此为止了',
    ],
  );
  
  // VIP Characters
  static const aki = AIPersonality(
    id: '1001',
    name: '亚希',
    description: '温柔可爱，暗藏心机',
    avatarPath: 'assets/people/1001/',
    bluffRatio: 0.48,          // 较高虚张，表里不一
    challengeThreshold: 0.42,  // 42%以下就质疑（敏锐）
    riskAppetite: 0.65,        // 中高风险偏好
    mistakeRate: 0.025,        // 极低错误率
    tellExposure: 0.05,        // 很少暴露破绽
    reverseActingProb: 0.35,   // 经常反向表演
    bidPreferenceThreshold: 0.1,
    isVIP: true,
    country: 'Japan',
    difficulty: 'hard',
    taunts: [
      '啊啦，你在说谎吧？',
      '真可怜呢~',
      '是我赢了哦',
      '再想想看吧',
    ],
  );
  
  static const katerina = AIPersonality(
    id: '1002',
    name: '卡捷琳娜',
    description: '冷艳高贵，算无遗策',
    avatarPath: 'assets/people/1002/',
    bluffRatio: 0.4,           // 适度虚张，深不可测
    challengeThreshold: 0.38,  // 38%以下就质疑（精准）
    riskAppetite: 0.5,         // 中等风险偏好
    mistakeRate: 0.015,        // 极低错误率
    tellExposure: 0.03,        // 几乎不暴露破绽
    reverseActingProb: 0.4,    // 频繁反向表演
    bidPreferenceThreshold: 0.06,
    isVIP: true,
    country: 'Russia',
    difficulty: 'expert',
    taunts: [
      '你在虚张声势，亲爱的',
      '这太简单了',
      '我看透你了',
      '下次祝你好运',
    ],
  );
  
  static const lena = AIPersonality(
    id: '1003',
    name: '莱娜',
    description: '严谨理性，精确计算',
    avatarPath: 'assets/people/1003/',
    bluffRatio: 0.25,          // 很少虚张，实事求是
    challengeThreshold: 0.4,   // 40%以下就质疑（理性）
    riskAppetite: 0.3,         // 低风险偏好
    mistakeRate: 0.01,         // 几乎不出错
    tellExposure: 0.02,        // 极少暴露破绽
    reverseActingProb: 0.25,   // 偶尔反向表演
    bidPreferenceThreshold: 0.05,
    isVIP: true,
    country: 'Germany',
    difficulty: 'expert',
    taunts: [
      '这在数学上是不可能的',
      '我已经计算好了一切',
      '你犯了一个错误',
      '很好，但还不够好',
    ],
  );
  
  // 获取所有普通角色列表
  static List<AIPersonality> get normalCharacters => [
    professor,
    gambler,
    provocateur,
    youngwoman,
  ];
  
  // 获取所有VIP角色列表
  static List<AIPersonality> get vipCharacters => [
    aki,
    katerina,
    lena,
  ];
  
  // 获取所有角色列表
  static List<AIPersonality> get allCharacters => [
    ...normalCharacters,
    ...vipCharacters,
  ];
}
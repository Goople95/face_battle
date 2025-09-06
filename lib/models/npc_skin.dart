/// NPC皮膚數據模型
class NPCSkin {
  final int id;
  final Map<String, String> name;  // 多語言名稱
  final Map<String, String>? description;  // 多語言描述（可選）
  final bool unlocked;  // 是否已解鎖
  final UnlockCondition unlockCondition;  // 解鎖條件
  final String? avatarPath;  // 頭像路徑（可選，默認使用NPC路徑+皮膚ID）
  final String? videosPath;  // 視頻路徑（可選，默認使用NPC路徑+皮膚ID）
  final int? videoCount;  // 該皮膚的視頻數量（可選）
  
  NPCSkin({
    required this.id,
    required this.name,
    this.description,
    required this.unlocked,
    required this.unlockCondition,
    this.avatarPath,
    this.videosPath,
    this.videoCount,
  });
  
  factory NPCSkin.fromJson(Map<String, dynamic> json) {
    // 生成默认的皮肤名称
    final skinId = json['id'] as int;
    final defaultName = {
      'en': 'Skin $skinId',
      'zh_TW': '皮膚 $skinId',
      'es': 'Aspecto $skinId',
      'pt': 'Visual $skinId',
      'id': 'Kulit $skinId',
    };
    
    return NPCSkin(
      id: skinId,
      name: json['name'] != null 
        ? Map<String, String>.from(json['name'] as Map)
        : defaultName,  // 如果没有name字段，使用默认名称
      description: json['description'] != null 
        ? Map<String, String>.from(json['description'] as Map)
        : null,
      unlocked: json['unlocked'] as bool? ?? false,
      unlockCondition: UnlockCondition.fromJson(json['unlockCondition'] as Map<String, dynamic>),
      avatarPath: json['avatarPath'] as String?,
      videosPath: json['videosPath'] as String?,
      videoCount: json['videoCount'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'unlocked': unlocked,
      'unlockCondition': unlockCondition.toJson(),
      if (avatarPath != null) 'avatarPath': avatarPath,
      if (videosPath != null) 'videosPath': videosPath,
      if (videoCount != null) 'videoCount': videoCount,
    };
  }
  
  /// 獲取本地化名稱
  String getLocalizedName(String languageCode) {
    return name[languageCode] ?? name['en'] ?? 'Unknown';
  }
  
  /// 獲取本地化描述
  String getLocalizedDescription(String languageCode) {
    if (description == null) return '';
    return description![languageCode] ?? description!['en'] ?? '';
  }
}

/// 解鎖條件
class UnlockCondition {
  final String type;  // default, intimacy, payment, vip_exclusive
  final int? level;  // 親密度等級（僅intimacy類型）
  final String? itemId;  // 商品ID（僅payment類型）
  final Map<String, String>? description;  // 條件描述
  
  UnlockCondition({
    required this.type,
    this.level,
    this.itemId,
    this.description,
  });
  
  factory UnlockCondition.fromJson(Map<String, dynamic> json) {
    return UnlockCondition(
      type: json['type'] as String,
      level: json['level'] as int?,
      itemId: json['itemId'] as String?,
      description: json['description'] != null 
        ? Map<String, String>.from(json['description'] as Map)
        : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (level != null) 'level': level,
      if (itemId != null) 'itemId': itemId,
      if (description != null) 'description': description,
    };
  }
  
  /// 獲取本地化條件描述
  String getLocalizedDescription(String languageCode) {
    if (description == null) return '';
    return description![languageCode] ?? description!['en'] ?? '';
  }
  
  /// 檢查是否滿足解鎖條件
  bool checkUnlocked({
    int currentIntimacy = 0,
    bool isVIP = false,
    Set<String>? purchasedItems,
  }) {
    switch (type) {
      case 'default':
        return true;  // 默認皮膚總是解鎖
      
      case 'intimacy':
        return level != null && currentIntimacy >= level!;
      
      case 'payment':
        return itemId != null && (purchasedItems?.contains(itemId) ?? false);
      
      case 'vip_exclusive':
        return isVIP;
      
      default:
        return false;
    }
  }
}

/// 皮膚管理器擴展
extension NPCSkinExtension on Map<String, dynamic> {
  /// 從NPC配置中提取皮膚列表
  List<NPCSkin> get skins {
    final skinsData = this['skins'] as List?;
    if (skinsData == null) {
      // 如果沒有配置皮膚，創建默認皮膚
      return [
        NPCSkin(
          id: 1,
          name: {'en': 'Skin 1', 'zh_TW': '皮膚 1', 'es': 'Aspecto 1', 'pt': 'Visual 1', 'id': 'Kulit 1'},
          description: null,  // 不再使用描述
          unlocked: true,
          unlockCondition: UnlockCondition(type: 'default'),
        ),
      ];
    }
    
    return skinsData
        .map((skin) => NPCSkin.fromJson(skin as Map<String, dynamic>))
        .toList();
  }
  
  /// 獲取默認皮膚（第一個或ID為1的）
  NPCSkin get defaultSkin {
    final skinList = skins;
    return skinList.firstWhere(
      (skin) => skin.id == 1,
      orElse: () => skinList.first,
    );
  }
  
  /// 根據ID獲取皮膚
  NPCSkin? getSkinById(int skinId) {
    final skinList = skins;
    try {
      return skinList.firstWhere((skin) => skin.id == skinId);
    } catch (_) {
      return null;
    }
  }
}
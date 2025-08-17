/// 角色资源配置
class CharacterAssets {
  /// 统一的角色ID映射表 - 兼容新旧ID
  static const Map<String, String> idMapping = {
    // 新ID直接映射到自己
    '0001': '0001',
    '0002': '0002',
    '0003': '0003',
    '0004': '0004',
    '1001': '1001',
    '1002': '1002',
    '1003': '1003',
    // 兼容旧ID
    'professor': '0001',
    'gambler': '0002',
    'provocateur': '0003',
    'youngwoman': '0004',
    'aki': '1001',
    'katerina': '1002',
    'lena': '1003',
    // 旧的文件夹名映射（兼容sprite相关的旧资源）
    'man': '0001',
    'youngman': '0002',
    'woman': '0003',
  };
  
  /// 情绪到视频文件名的映射（实际只有4个视频文件）
  static const Map<String, String> emotionMapping = {
    // 实际存在的视频文件
    'thinking': 'thinking',
    'happy': 'happy',
    'confident': 'confident',
    'suspicious': 'suspicious',
    // 其他情绪映射到最接近的视频
    'nervous': 'suspicious',
    'angry': 'suspicious',
    'excited': 'happy',
    'worried': 'suspicious',
    'surprised': 'happy',
    'disappointed': 'thinking',
    'smirk': 'confident',
    'proud': 'confident',
    'relaxed': 'happy',
    'anxious': 'suspicious',
    'cunning': 'suspicious',
    'frustrated': 'suspicious',
    'determined': 'confident',
    'playful': 'happy',
    'neutral': 'thinking',
    'contemplating': 'thinking',
    // 中文情绪映射
    '思考': 'thinking',
    '思考/沉思': 'thinking',
    '沉思': 'thinking',
    '开心': 'happy',
    '开心/得意': 'happy',
    '得意': 'happy',
    '兴奋': 'happy',
    '兴奋/自信': 'happy',
    '自信': 'confident',
    '怀疑': 'suspicious',
    '紧张': 'suspicious',
    '担心': 'suspicious',
    '担心/紧张': 'suspicious',
    '生气': 'suspicious',
    '惊讶': 'happy',
    '失望': 'thinking',
  };
  
  /// 获取标准化的角色ID
  static String getNormalizedId(String characterId) {
    return idMapping[characterId] ?? characterId;
  }
  
  /// 获取角色头像路径 - 现在所有图片都统一命名为1.png
  static String getAvatarPath(String characterId) {
    String normalizedId = getNormalizedId(characterId);
    return 'assets/people/$normalizedId/1.png';
  }
  
  /// 从avatarPath获取完整的图片路径
  static String getFullAvatarPath(String avatarPath) {
    // 如果avatarPath以/结尾，说明是目录，补充1.png
    if (avatarPath.endsWith('/')) {
      return '${avatarPath}1.png';
    }
    // 否则返回原路径
    return avatarPath;
  }
  
  /// 获取角色视频路径
  static String getVideoPath(String characterId, String emotion) {
    String normalizedId = getNormalizedId(characterId);
    String normalizedEmotion = emotionMapping[emotion.toLowerCase()] ?? 'happy';
    return 'assets/people/$normalizedId/videos/$normalizedEmotion.mp4';
  }
  
  /// 获取角色视频目录路径
  static String getVideoDirectory(String characterId) {
    String normalizedId = getNormalizedId(characterId);
    return 'assets/people/$normalizedId/videos/';
  }
  
  /// 获取角色目录路径
  static String getCharacterDirectory(String characterId) {
    String normalizedId = getNormalizedId(characterId);
    return 'assets/people/$normalizedId/';
  }
  
  /// 获取精灵帧图片路径（用于sprite动画）
  static String getSpritePath(String characterId, String emotion, int frameNumber) {
    String normalizedId = getNormalizedId(characterId);
    String frameStr = frameNumber.toString().padLeft(3, '0');
    return 'assets/people/$normalizedId/frames/${emotion}_$frameStr.png';
  }
  
  /// 获取透明图片路径
  static String getTransparentPath(String characterId, String emotion, int frameNumber) {
    String normalizedId = getNormalizedId(characterId);
    String frameStr = frameNumber.toString().padLeft(3, '0');
    return 'assets/people/$normalizedId/transparent/${emotion}_$frameStr.png';
  }
  
  /// 检查是否是VIP角色
  static bool isVIP(String characterId) {
    String normalizedId = getNormalizedId(characterId);
    return normalizedId.startsWith('1');
  }
}
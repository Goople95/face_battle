/// 简化的角色配置 - 只保留核心功能
class CharacterConfig {
  /// 4种核心表情
  static const List<String> coreEmotions = [
    'thinking',    // 思考/中性
    'happy',       // 开心/兴奋
    'confident',   // 自信/得意
    'suspicious',  // 怀疑/紧张
  ];
  
  /// 获取角色头像路径
  static String getAvatarPath(String characterId) {
    return 'assets/people/$characterId/1.png';
  }
  
  /// 获取角色视频路径
  static String getVideoPath(String characterId, String emotion) {
    // 确保emotion是4种核心表情之一
    if (!coreEmotions.contains(emotion)) {
      emotion = 'thinking'; // 默认表情
    }
    return 'assets/people/$characterId/videos/$emotion.mp4';
  }
  
  /// 获取所有视频路径（用于预加载）
  static List<String> getAllVideoPaths(String characterId) {
    return coreEmotions
        .map((emotion) => getVideoPath(characterId, emotion))
        .toList();
  }
  
  /// 检查是否是VIP角色
  static bool isVIP(String characterId) {
    return characterId.startsWith('1');
  }
  
  /// 从avatarPath获取完整的图片路径（兼容旧格式）
  static String getFullAvatarPath(String avatarPath) {
    // 如果avatarPath以/结尾，说明是目录，补充1.png
    if (avatarPath.endsWith('/')) {
      return '${avatarPath}1.png';
    }
    // 否则返回原路径
    return avatarPath;
  }
}
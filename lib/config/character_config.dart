/// 简化的角色配置 - 只保留核心功能
class CharacterConfig {
  /// 视频文件名格式（数字编号）
  /// drunk.mp4 保留特殊处理
  static const String drunkVideo = 'drunk';
  
  /// 获取角色头像路径
  static String getAvatarPath(String characterId) {
    return 'assets/people/$characterId/1.jpg';
  }
  
  /// 获取角色视频路径
  static String getVideoPath(String characterId, dynamic indexOrEmotion, {int videoCount = 4}) {
    // 如果是'drunk'，保留特殊处理
    if (indexOrEmotion == 'drunk') {
      return 'assets/people/$characterId/videos/drunk.mp4';
    }
    
    // 如果是数字，直接使用
    if (indexOrEmotion is int) {
      return 'assets/people/$characterId/videos/$indexOrEmotion.mp4';
    }
    
    // 否则随机选择一个视频
    final randomIndex = 1 + (DateTime.now().millisecondsSinceEpoch % videoCount);
    return 'assets/people/$characterId/videos/$randomIndex.mp4';
  }
  
  /// 获取所有视频路径（用于预加载）
  static List<String> getAllVideoPaths(String characterId, {int videoCount = 4}) {
    List<String> paths = [];
    // 添加数字编号的视频
    for (int i = 1; i <= videoCount; i++) {
      paths.add('assets/people/$characterId/videos/$i.mp4');
    }
    // 添加drunk视频
    paths.add('assets/people/$characterId/videos/drunk.mp4');
    return paths;
  }
  
  /// 检查是否是VIP角色
  static bool isVIP(String characterId) {
    return characterId.startsWith('1');
  }
  
  /// 从avatarPath获取完整的图片路径（兼容旧格式）
  static String getFullAvatarPath(String avatarPath) {
    // 如果avatarPath以/结尾，说明是目录，补充1.jpg
    if (avatarPath.endsWith('/')) {
      return '${avatarPath}1.jpg';
    }
    // 否则返回原路径
    return avatarPath;
  }
}
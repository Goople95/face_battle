/// ID迁移工具类，用于兼容旧版本数据
class IdMigration {
  /// 旧ID到新ID的映射
  static const Map<String, String> oldToNewId = {
    'professor': '0001',
    'gambler': '0002',
    'provocateur': '0003',
    'youngwoman': '0004',
    'aki': '1001',
    'katerina': '1002',
    'lena': '1003',
  };
  
  /// 新ID到旧ID的映射（反向）
  static const Map<String, String> newToOldId = {
    '0001': 'professor',
    '0002': 'gambler',
    '0003': 'provocateur',
    '0004': 'youngwoman',
    '1001': 'aki',
    '1002': 'katerina',
    '1003': 'lena',
  };
  
  /// 将ID转换为新格式
  static String toNewId(String id) {
    return oldToNewId[id] ?? id;
  }
  
  /// 将ID转换为旧格式（如果需要）
  static String toOldId(String id) {
    return newToOldId[id] ?? id;
  }
  
  /// 检查是否是新ID格式
  static bool isNewId(String id) {
    return RegExp(r'^\d{4}$').hasMatch(id);
  }
  
  /// 检查是否是VIP ID
  static bool isVipId(String id) {
    // 转换为新ID格式后检查
    String newId = toNewId(id);
    return newId.startsWith('1');
  }
}
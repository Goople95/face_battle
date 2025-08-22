import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../utils/logger_utils.dart';

/// 统一的本地存储服务
/// 所有本地存储操作都通过此服务进行，确保用户数据隔离
class LocalStorageService {
  static LocalStorageService? _instance;
  static LocalStorageService get instance => _instance ??= LocalStorageService._();
  
  LocalStorageService._();
  
  // 当前用户ID
  String? _currentUserId;
  
  /// 设置当前用户ID
  void setUserId(String? userId) {
    _currentUserId = userId;
    if (userId != null) {
      LoggerUtils.info('LocalStorageService: 设置用户ID为 $userId');
    } else {
      LoggerUtils.info('LocalStorageService: 清除用户ID');
    }
  }
  
  /// 获取当前用户ID
  String? get currentUserId => _currentUserId;
  
  /// 构建包含用户ID的键
  String _buildKey(String baseKey) {
    if (_currentUserId == null) {
      throw Exception('LocalStorageService: 未设置用户ID，无法进行存储操作');
    }
    return '${_currentUserId}_$baseKey';
  }
  
  /// 构建可选用户ID的键（用于某些不需要用户ID的全局设置）
  String _buildOptionalUserKey(String baseKey, {bool useUserId = true}) {
    if (useUserId && _currentUserId != null) {
      return '${_currentUserId}_$baseKey';
    }
    return baseKey;
  }
  
  // === 基础存储方法 ===
  
  /// 保存字符串
  Future<bool> setString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullKey = _buildKey(key);
      final result = await prefs.setString(fullKey, value);
      LoggerUtils.debug('保存字符串: $fullKey');
      return result;
    } catch (e) {
      LoggerUtils.error('保存字符串失败 [$key]: $e');
      return false;
    }
  }
  
  /// 获取字符串
  Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullKey = _buildKey(key);
      return prefs.getString(fullKey);
    } catch (e) {
      LoggerUtils.error('获取字符串失败 [$key]: $e');
      return null;
    }
  }
  
  /// 保存整数
  Future<bool> setInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullKey = _buildKey(key);
      final result = await prefs.setInt(fullKey, value);
      LoggerUtils.debug('保存整数: $fullKey = $value');
      return result;
    } catch (e) {
      LoggerUtils.error('保存整数失败 [$key]: $e');
      return false;
    }
  }
  
  /// 获取整数
  Future<int?> getInt(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullKey = _buildKey(key);
      return prefs.getInt(fullKey);
    } catch (e) {
      LoggerUtils.error('获取整数失败 [$key]: $e');
      return null;
    }
  }
  
  /// 保存布尔值
  Future<bool> setBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullKey = _buildKey(key);
      final result = await prefs.setBool(fullKey, value);
      LoggerUtils.debug('保存布尔值: $fullKey = $value');
      return result;
    } catch (e) {
      LoggerUtils.error('保存布尔值失败 [$key]: $e');
      return false;
    }
  }
  
  /// 获取布尔值
  Future<bool?> getBool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullKey = _buildKey(key);
      return prefs.getBool(fullKey);
    } catch (e) {
      LoggerUtils.error('获取布尔值失败 [$key]: $e');
      return null;
    }
  }
  
  /// 保存JSON对象
  Future<bool> setJson(String key, Map<String, dynamic> json) async {
    try {
      final jsonString = jsonEncode(json);
      return await setString(key, jsonString);
    } catch (e) {
      LoggerUtils.error('保存JSON失败 [$key]: $e');
      return false;
    }
  }
  
  /// 获取JSON对象
  Future<Map<String, dynamic>?> getJson(String key) async {
    try {
      final jsonString = await getString(key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      LoggerUtils.error('获取JSON失败 [$key]: $e');
      return null;
    }
  }
  
  /// 删除指定键
  Future<bool> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullKey = _buildKey(key);
      final result = await prefs.remove(fullKey);
      LoggerUtils.debug('删除键: $fullKey');
      return result;
    } catch (e) {
      LoggerUtils.error('删除键失败 [$key]: $e');
      return false;
    }
  }
  
  /// 检查键是否存在
  Future<bool> containsKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullKey = _buildKey(key);
      return prefs.containsKey(fullKey);
    } catch (e) {
      LoggerUtils.error('检查键失败 [$key]: $e');
      return false;
    }
  }
  
  // === 批量操作 ===
  
  /// 获取所有属于当前用户的键
  Future<Set<String>> getUserKeys() async {
    if (_currentUserId == null) {
      return {};
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final userPrefix = '${_currentUserId}_';
      
      // 筛选出属于当前用户的键，并去掉前缀
      return allKeys
          .where((key) => key.startsWith(userPrefix))
          .map((key) => key.substring(userPrefix.length))
          .toSet();
    } catch (e) {
      LoggerUtils.error('获取用户键列表失败: $e');
      return {};
    }
  }
  
  /// 清除当前用户的所有数据
  Future<bool> clearUserData() async {
    if (_currentUserId == null) {
      LoggerUtils.warning('LocalStorageService: 无法清除数据，未设置用户ID');
      return false;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final userPrefix = '${_currentUserId}_';
      
      // 找出所有属于当前用户的键
      final userKeys = allKeys.where((key) => key.startsWith(userPrefix));
      
      // 删除所有用户数据
      for (final key in userKeys) {
        await prefs.remove(key);
      }
      
      LoggerUtils.info('清除用户 $_currentUserId 的所有本地数据，共 ${userKeys.length} 条');
      return true;
    } catch (e) {
      LoggerUtils.error('清除用户数据失败: $e');
      return false;
    }
  }
  
  // === 全局设置（不需要用户ID） ===
  
  /// 保存全局设置（如语言设置等）
  Future<bool> setGlobalString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(key, value);
      LoggerUtils.debug('保存全局设置: $key');
      return result;
    } catch (e) {
      LoggerUtils.error('保存全局设置失败 [$key]: $e');
      return false;
    }
  }
  
  /// 获取全局设置
  Future<String?> getGlobalString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      LoggerUtils.error('获取全局设置失败 [$key]: $e');
      return null;
    }
  }
  
  // === 数据迁移支持 ===
  
  /// 从旧键迁移数据到新键（用于版本升级）
  Future<bool> migrateKey(String oldKey, String newKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 检查旧键是否存在
      if (!prefs.containsKey(oldKey)) {
        return false;
      }
      
      // 获取旧数据
      final value = prefs.get(oldKey);
      if (value == null) {
        return false;
      }
      
      // 构建新键
      final fullNewKey = _buildKey(newKey);
      
      // 根据类型保存数据
      bool success = false;
      if (value is String) {
        success = await prefs.setString(fullNewKey, value);
      } else if (value is int) {
        success = await prefs.setInt(fullNewKey, value);
      } else if (value is bool) {
        success = await prefs.setBool(fullNewKey, value);
      } else if (value is double) {
        success = await prefs.setDouble(fullNewKey, value);
      } else if (value is List<String>) {
        success = await prefs.setStringList(fullNewKey, value);
      }
      
      // 如果迁移成功，删除旧键
      if (success) {
        await prefs.remove(oldKey);
        LoggerUtils.info('数据迁移成功: $oldKey -> $fullNewKey');
      }
      
      return success;
    } catch (e) {
      LoggerUtils.error('数据迁移失败 [$oldKey -> $newKey]: $e');
      return false;
    }
  }
  
  /// 批量迁移旧数据到新的用户隔离键
  Future<void> migrateToUserIsolatedKeys(List<String> keys) async {
    if (_currentUserId == null) {
      LoggerUtils.warning('无法迁移数据，未设置用户ID');
      return;
    }
    
    for (final key in keys) {
      await migrateKey(key, key);
    }
  }
}
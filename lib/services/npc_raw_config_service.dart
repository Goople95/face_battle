import '../models/npc_skin.dart';
import '../utils/logger_utils.dart';
import 'cloud_npc_service.dart';

/// NPC原始配置服務 - 提供完整的NPC配置數據（包含皮膚信息）
class NPCRawConfigService {
  static NPCRawConfigService? _instance;
  static NPCRawConfigService get instance => _instance ??= NPCRawConfigService._();
  
  NPCRawConfigService._();
  
  Map<String, dynamic>? _rawConfig;
  bool _isLoaded = false;
  
  /// 初始化並加載配置
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    try {
      // 從CloudNPCService獲取配置
      final config = await CloudNPCService.fetchRawNPCConfig();
      
      if (config != null && config['npcs'] != null) {
        _rawConfig = config;
        _isLoaded = true;
        LoggerUtils.info('NPCRawConfigService: 成功從雲端加載NPC原始配置');
      } else {
        // 如果雲端加載失敗，使用空配置
        _rawConfig = {'npcs': {}};
        _isLoaded = true;
        LoggerUtils.warning('NPCRawConfigService: 雲端配置為空，使用默認配置');
      }
    } catch (e) {
      LoggerUtils.error('NPCRawConfigService: 加載配置失敗: $e');
      _rawConfig = {'npcs': {}};
      _isLoaded = true;
    }
  }
  
  /// 確保已加載
  Future<void> ensureLoaded() async {
    if (!_isLoaded) {
      await initialize();
    }
  }
  
  /// 根據ID獲取NPC的原始配置
  Map<String, dynamic>? getNPCById(String npcId) {
    if (_rawConfig == null) return null;
    final npcs = _rawConfig!['npcs'];
    if (npcs == null) return null;
    final npcData = npcs[npcId];
    if (npcData == null) return null;
    // 確保返回正確的類型
    return Map<String, dynamic>.from(npcData as Map);
  }
  
  /// 獲取所有NPC的原始配置
  List<Map<String, dynamic>> getAllNPCs() {
    if (_rawConfig == null) return [];
    final npcs = _rawConfig!['npcs'];
    if (npcs == null) return [];
    
    // 安全地處理類型轉換
    try {
      final List<Map<String, dynamic>> result = [];
      if (npcs is Map) {
        // npcs 是 Map，遍歷其 values
        for (final value in npcs.values) {
          if (value is Map) {
            result.add(Map<String, dynamic>.from(value));
          }
        }
      } else if (npcs is List) {
        // npcs 是 List，直接遍歷
        for (final item in npcs) {
          if (item is Map) {
            result.add(Map<String, dynamic>.from(item));
          }
        }
      }
      return result;
    } catch (e) {
      LoggerUtils.error('getAllNPCs 類型轉換失敗: $e');
      return [];
    }
  }
  
  /// 獲取VIP配置
  Map<String, dynamic>? getVIPConfig() {
    return _rawConfig?['vipConfig'] as Map<String, dynamic>?;
  }
}
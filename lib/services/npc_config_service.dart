import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../models/ai_personality.dart';
import '../utils/logger_utils.dart';
import 'cloud_npc_service.dart';

/// NPC配置服务
/// 负责从JSON文件加载和管理所有NPC配置
class NPCConfigService {
  static final NPCConfigService _instance = NPCConfigService._internal();
  factory NPCConfigService() => _instance;
  NPCConfigService._internal();

  // NPC数据存储
  final Map<String, AIPersonality> _npcs = {};
  final List<AIPersonality> _normalCharacters = [];
  final List<AIPersonality> _vipCharacters = [];
  bool _isLoaded = false;

  // 获取所有普通角色
  List<AIPersonality> get normalCharacters => List.unmodifiable(_normalCharacters);
  
  // 获取所有VIP角色
  List<AIPersonality> get vipCharacters => List.unmodifiable(_vipCharacters);
  
  // 获取所有角色
  List<AIPersonality> get allCharacters => [
    ..._normalCharacters,
    ..._vipCharacters,
  ];

  // 根据ID获取NPC
  AIPersonality? getNPCById(String id) => _npcs[id];

  // 根据名称获取NPC（兼容旧代码）
  AIPersonality? getNPCByName(String name) {
    return _npcs.values.firstWhere(
      (npc) => npc.name == name,
      orElse: () => _npcs.values.first,
    );
  }

  // 获取特定NPC（兼容旧代码的静态引用）
  AIPersonality get lena => getNPCById('0001') ?? _normalCharacters.first;  // Lena - 德国
  AIPersonality get katerina => getNPCById('0002') ?? _normalCharacters.first;   // Katerina - 俄罗斯
  
  // 向后兼容（旧名称映射到新角色）
  AIPersonality get provocateur => lena;  // 映射到Lena
  AIPersonality get youngwoman => katerina;     // 映射到Katerina
  AIPersonality get professor => lena;  // 映射到Lena
  AIPersonality get gambler => katerina;     // 映射到Katerina
  
  // VIP角色
  AIPersonality get aki => getNPCById('1001') ?? _vipCharacters.first;  // Aki - 日本
  AIPersonality get isabella => getNPCById('1002') ?? (_vipCharacters.length > 1 ? _vipCharacters[1] : _vipCharacters.first);  // Isabella - 巴西

  // 获取当前系统语言代码
  String _getCurrentLocaleCode() {
    // 使用PlatformDispatcher替代deprecated的window
    final locale = ui.PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;
    
    // 处理中文的特殊情况
    if (languageCode == 'zh') {
      if (countryCode == 'TW' || countryCode == 'HK' || countryCode == 'MO') {
        return 'zh_TW';
      }
      return 'zh';
    }
    
    // 对于其他语言，直接返回语言代码
    return languageCode;
  }

  // 初始化：加载JSON配置
  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      LoggerUtils.info('开始加载NPC配置...');
      
      // 优先从云端加载配置
      List<NPCConfig> cloudConfigs;
      try {
        cloudConfigs = await CloudNPCService.fetchNPCConfigs(forceRefresh: false);
        LoggerUtils.info('成功从云端加载了${cloudConfigs.length}个NPC配置');
      } catch (e) {
        LoggerUtils.warning('云端加载失败，回退到本地配置: $e');
        // 如果云端加载失败，使用本地配置
        final String jsonString = await rootBundle.loadString('assets/config/npc_config.json');
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        final npcsData = jsonData['npcs'] as Map<String, dynamic>;
        
        // 转换为NPCConfig列表
        cloudConfigs = [];
        for (final entry in npcsData.entries) {
          cloudConfigs.add(NPCConfig.fromJson(entry.key, entry.value));
        }
      }
      
      // 处理配置数据
      final Map<String, dynamic> npcsData = {};
      for (final config in cloudConfigs) {
        npcsData[config.id] = config.toJson();
      }
      
      for (final entry in npcsData.entries) {
        final String id = entry.key;
        final Map<String, dynamic> npcData = entry.value;
        
        // 解析personality数据
        final personalityData = npcData['personality'] as Map<String, dynamic>;
        
        // 解析多语言名称和描述
        final namesMap = npcData['names'] as Map<String, dynamic>?;
        final descriptionsMap = npcData['descriptions'] as Map<String, dynamic>?;
        
        // 获取默认名称和描述（用于向后兼容）
        String name = '';
        String description = '';
        
        if (namesMap != null) {
          // 使用英文作为默认值
          name = namesMap['en'] ?? 
                 namesMap['zh'] ?? 
                 npcData['name'] ?? '';
        } else {
          // 兼容旧格式
          name = npcData['name'] ?? '';
        }
        
        if (descriptionsMap != null) {
          // 使用英文作为默认值
          description = descriptionsMap['en'] ?? 
                       descriptionsMap['zh_TW'] ?? 
                       npcData['description'] ?? '';
        } else {
          // 兼容旧格式
          description = npcData['description'] ?? '';
        }
        
        // 调试输出
        LoggerUtils.info('Loading NPC $id:');
        LoggerUtils.info('  namesMap: $namesMap');
        LoggerUtils.info('  descriptionsMap: $descriptionsMap');
        
        // 创建AIPersonality对象
        final personality = AIPersonality(
          id: id,
          name: name,
          description: description,
          namesMap: namesMap?.cast<String, String>(),
          descriptionsMap: descriptionsMap?.cast<String, String>(),
          avatarPath: npcData['avatarPath'] ?? '',
          bluffRatio: (personalityData['bluffRatio'] ?? 0.5).toDouble(),
          challengeThreshold: (personalityData['challengeThreshold'] ?? 0.5).toDouble(),
          riskAppetite: (personalityData['riskAppetite'] ?? 0.5).toDouble(),
          mistakeRate: (personalityData['mistakeRate'] ?? 0.05).toDouble(),
          tellExposure: (personalityData['tellExposure'] ?? 0.1).toDouble(),
          reverseActingProb: (personalityData['reverseActingProb'] ?? 0.2).toDouble(),
          bidPreferenceThreshold: (personalityData['bidPreferenceThreshold'] ?? 0.1).toDouble(),
          isVIP: npcData['isVIP'] ?? false,
          country: npcData['country'],
          drinkCapacity: npcData['drinkCapacity'] ?? 4, // 默认酒量4杯
        );
        
        // 存储NPC
        _npcs[id] = personality;
        
        // 分类存储
        if (personality.isVIP) {
          _vipCharacters.add(personality);
        } else {
          _normalCharacters.add(personality);
        }
      }
      
      _isLoaded = true;
      LoggerUtils.info('NPC配置加载完成: ${_npcs.length}个角色 (普通: ${_normalCharacters.length}, VIP: ${_vipCharacters.length})');
      
    } catch (e) {
      LoggerUtils.error('加载NPC配置失败: $e');
      // 如果加载失败，使用默认配置
      _loadDefaultConfig();
    }
  }

  // 加载默认配置（作为后备方案）
  void _loadDefaultConfig() {
    LoggerUtils.warning('使用默认NPC配置');
    
    // 创建默认的NPC
    final defaultNPC = AIPersonality(
      id: '0001',
      name: '默认对手',
      description: '标准AI对手',
      avatarPath: 'assets/people/0001/',
      bluffRatio: 0.4,
      challengeThreshold: 0.5,
      riskAppetite: 0.5,
      mistakeRate: 0.05,
      tellExposure: 0.1,
      reverseActingProb: 0.2,
      bidPreferenceThreshold: 0.1,
      drinkCapacity: 4,
    );
    
    _npcs['0001'] = defaultNPC;
    _normalCharacters.add(defaultNPC);
    _isLoaded = true;
  }

  // 重新加载配置
  Future<void> reload() async {
    _npcs.clear();
    _normalCharacters.clear();
    _vipCharacters.clear();
    _isLoaded = false;
    await initialize();
  }
}
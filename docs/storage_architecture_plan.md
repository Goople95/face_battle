# 存储架构重构计划

## 📁 现有文件结构分析

### 1. 已存在的存储服务文件

#### ✅ 已有合理结构的文件
- `services/storage/local_storage_service.dart` - 本地存储基础服务（已存在）
- `services/storage/cloud_storage_service.dart` - 云端存储基础服务（已存在）
- `services/game_progress_service.dart` - 游戏进度同步服务（已存在但需改进）

#### ❌ 需要废弃或合并的文件
- `services/local_storage_service.dart` - 与storage目录下的重复
- `services/data_storage_service.dart` - 旧版本，混合了各种数据
- `services/data_storage_service_improved.dart` - 改进版但仍然混乱

### 2. 模型文件
- `models/game_progress.dart` - 需要创建新的模型定义
- `models/drinking_state.dart` - 临时状态，纯本地
- `models/player_profile.dart` - 玩家行为分析，纯本地

## 🎯 重构目标

### 数据分类
```
纯本地数据                     需要同步的数据
├── 临时游戏状态               ├── 游戏进度统计
│   ├── 当前喝酒数             │   ├── 总场数/胜负
│   ├── AI当前状态             │   ├── 历史最高记录
│   └── 醒酒倒计时             │   └── 累计喝酒总数
├── 设备偏好                   ├── NPC亲密度
│   ├── 音效设置               │   ├── 亲密度等级
│   └── 语言设置               │   └── 互动记录
└── 玩家行为分析               └── 成就系统
    ├── 叫牌习惯                   ├── 已解锁成就
    └── 最近游戏记录               └── 进度时间戳
```

## 📝 实施步骤

### Step 1: 创建新的数据模型
```dart
// models/game_progress.dart
class GameProgress {
  // 用户ID
  final String userId;
  
  // 永久统计数据
  int totalGames;
  int totalWins;
  // ... 其他永久数据
  
  // 关键：同步时间戳
  DateTime lastUpdated;  // 数据最后修改时间
  DateTime? lastSyncTime; // 最后同步到云端时间
}

// models/temp_game_state.dart  
class TempGameState {
  // 临时状态（不同步）
  int currentPlayerDrinks;
  Map<String, int> currentAIDrinks;
  DateTime? lastDrinkTime;
}
```

### Step 2: 重构服务层

#### 2.1 LocalStorageService 分离职责
```dart
// services/storage/local_storage_service.dart
class LocalStorageService {
  // 只提供基础的读写方法
  Future<bool> setJson(String key, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getJson(String key);
}

// services/temp_state_service.dart (新建)
class TempStateService {
  // 管理临时游戏状态（纯本地）
  Future<void> saveDrinkingState(TempGameState state);
  Future<TempGameState?> loadDrinkingState();
}
```

#### 2.2 GameProgressService 改进同步机制
```dart
// services/game_progress_service.dart
class GameProgressService {
  /// 核心同步逻辑：基于时间戳比较
  Future<GameProgress> loadProgress() async {
    final local = await _loadLocal();
    final cloud = await _loadCloud();
    
    // 关键：时间戳比较
    if (local == null && cloud == null) {
      return GameProgress(userId: currentUserId);
    }
    if (local == null) return cloud!;  // 新设备首次安装
    if (cloud == null) return local;   // 首次同步到云端
    
    // 比较lastUpdated时间戳
    if (local.lastUpdated.isAfter(cloud.lastUpdated)) {
      // 本地更新，需要同步到云端
      await _syncToCloud(local);
      return local;
    } else {
      // 云端更新（可能是其他设备修改）
      await _saveLocal(cloud);
      return cloud;
    }
  }
  
  /// 保存时自动更新时间戳
  Future<void> saveProgress(GameProgress progress) async {
    progress.lastUpdated = DateTime.now(); // 关键！
    await _saveLocal(progress);
    
    // 批量同步策略
    if (_shouldSync(progress)) {
      await _syncToCloud(progress);
    }
  }
}
```

### Step 3: 数据迁移策略

由于是开发阶段，不需要数据迁移，直接：
1. 清除所有旧数据
2. 使用新结构

### Step 4: 文件操作计划

#### 需要创建的文件
1. `models/temp_game_state.dart` - 临时状态模型
2. `services/temp_state_service.dart` - 临时状态服务

#### 需要修改的文件
1. `models/game_progress.dart` - 添加时间戳字段
2. `services/game_progress_service.dart` - 实现时间戳同步
3. `models/drinking_state.dart` - 移除永久数据字段

#### 需要删除的文件（确认后）
1. `services/local_storage_service.dart` (根目录的)
2. `services/data_storage_service.dart`
3. `services/data_storage_service_improved.dart`

## 🔄 同步流程图

```
应用启动
    ↓
加载GameProgress
    ↓
┌─────────────────┐
│ 本地时间戳 vs   │
│ 云端时间戳      │
└─────────────────┘
    ↓
┌─────────────────────────────────┐
│ 本地更新？→ 使用本地，同步云端   │
│ 云端更新？→ 使用云端，更新本地   │
│ 都没有？ → 创建新的              │
└─────────────────────────────────┘
    ↓
游戏进行中（每次更新都带时间戳）
    ↓
┌─────────────────┐
│ 批量同步策略：   │
│ - 每5局         │
│ - 破纪录时      │
│ - 退出应用时    │
└─────────────────┘
```

## ✅ 实施清单

- [ ] 1. 确认文件结构规划
- [ ] 2. 创建temp_game_state.dart模型
- [ ] 3. 更新game_progress.dart添加时间戳
- [ ] 4. 创建temp_state_service.dart服务
- [ ] 5. 重构game_progress_service.dart同步逻辑
- [ ] 6. 更新drinking_state.dart移除永久数据
- [ ] 7. 测试时间戳同步机制
- [ ] 8. 清理废弃文件

## 🎯 预期效果

1. **数据清晰分离**：临时状态不会错误同步
2. **同步简单可靠**：基于时间戳的简单比较
3. **成本优化**：批量同步减少Firestore操作
4. **用户体验**：换设备能恢复进度，临时状态重新开始
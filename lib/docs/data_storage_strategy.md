# 数据存储策略文档

## 存储原则

1. **明确分离**：每个数据只在一个地方存储（本地或云端），除了GameProgress需要同步
2. **用户隔离**：所有用户相关数据都使用userId进行隔离
3. **性能优先**：频繁访问的数据存本地，重要持久化数据存云端

## 数据分类

### 🔵 仅本地存储（Local Only）

这些数据只存在本地，不同步到云端：

#### 1. 游戏状态类
- **DrinkingState（饮酒状态）**
  - 键：`{userId}_drinking_state`
  - 内容：当前饮酒数量、清醒计时器、醉酒状态
  - 原因：临时状态，每次游戏会重置，无需云端备份

- **CurrentGameRound（当前游戏回合）**
  - 键：`{userId}_current_round`
  - 内容：当前回合的骰子、出价、游戏状态
  - 原因：临时数据，游戏结束就清空

#### 2. 临时解锁类
- **VIP临时解锁状态**
  - 键：`{userId}_vip_temp_unlock_{characterId}`
  - 内容：解锁时间戳
  - 原因：临时解锁，1小时后失效，仅用于缓存

#### 3. 缓存类
- **NPC对话缓存**
  - 键：`{userId}_dialogue_cache_{npcId}`
  - 内容：最近显示的对话ID列表
  - 原因：避免重复，纯缓存用途

### 🔴 仅云端存储（Cloud Only）

这些数据只存在云端，需要时从云端获取：

#### 1. 用户档案类
- **UserProfile（用户基本信息）**
  - 路径：`users/{userId}`
  - 内容：
    - userId：用户ID
    - username：用户名
    - displayName：显示名称
    - email：邮箱
    - photoUrl：头像URL
    - accountCreatedAt：账号创建时间
    - lastLoginAt：最后登录时间
    - loginProvider：登录方式（google/facebook）
  - 原因：账号核心信息，需要跨设备同步

#### 2. 社交关系类
- **好友列表**（如果有）
  - 路径：`users/{userId}/friends/{friendId}`
  - 内容：好友ID、添加时间
  - 原因：社交数据需要云端维护

- **排行榜数据**
  - 路径：`leaderboard/{userId}`
  - 内容：最高分、排名
  - 原因：全局数据，需要服务器端统计

#### 3. 成就系统类
- **解锁的成就**
  - 路径：`users/{userId}/achievements/{achievementId}`
  - 内容：成就ID、解锁时间、进度
  - 原因：重要的永久记录

#### 4. 交易记录类
- **购买历史**（如果有内购）
  - 路径：`users/{userId}/purchases/{purchaseId}`
  - 内容：购买时间、物品、金额
  - 原因：财务相关，需要可追溯

#### 5. 虚拟货币和解锁类
- **用户宝石数量**
  - 路径：`users/{userId}/wallet`
  - 内容：gems（宝石数量）、更新时间
  - 原因：虚拟货币，防作弊需要服务器端管理

- **VIP永久解锁状态**
  - 路径：`users/{userId}/vipUnlocks/{characterId}`
  - 内容：解锁时间、消费宝石数量
  - 原因：涉及消费，需要云端记录，防止作弊

### 🟢 双向同步（Local + Cloud Sync）

只有GameProgress需要双向同步：

#### UnifiedGameProgress（统一游戏进度）
- **本地键**：`{userId}_game_progress`
- **云端路径**：`gameProgress/{userId}`
- **同步策略**：基于时间戳的智能同步
- **包含内容**：
  ```dart
  - userId：用户ID
  - totalGames：总游戏数
  - totalWins：总胜利数
  - totalLosses：总失败数
  - currentWinStreak：当前连胜
  - highestWinStreak：最高连胜
  - totalDrinks：总饮酒数
  - npcIntimacy：Map<String, int> NPC亲密度数据
  - unlockedNPCs：List<String> 已解锁的NPC
  - achievements：List<String> 获得的成就
  - lastSyncTimestamp：最后同步时间戳
  ```
- **同步时机**：
  - 每5局游戏自动同步
  - 获得新成就时同步
  - 破纪录时同步
  - 用户登录/登出时同步

### ⚪ 全局设置（Global - 不需要userId）

这些设置与用户无关，全局存储：

- **语言设置**
  - 键：`language_preference`
  - 内容：语言代码（zh_CN, en等）
  - 存储：仅本地

- **设备标识**
  - 键：`device_id`
  - 内容：设备唯一ID
  - 存储：仅本地

- **首次启动标记**
  - 键：`first_launch`
  - 内容：布尔值
  - 存储：仅本地

## 实现建议

### 1. 简化后的 DataStorageService

```dart
class DataStorageService {
  // 仅管理本地数据
  - DrinkingState
  - VIP解锁状态
  - 用户偏好设置
  - 缓存数据
  
  // GameProgress通过专门的服务管理
}
```

### 2. 简化后的 FirestoreService

```dart
class FirestoreService {
  // 仅管理云端数据
  - UserProfile
  - Achievements
  - Leaderboard
  
  // GameProgress通过专门的服务管理
}
```

### 3. 专门的 GameProgressService

```dart
class GameProgressService {
  // 专门处理GameProgress的双向同步
  - 本地存储
  - 云端备份
  - 智能同步逻辑
  - 冲突解决
}
```

## 数据流程图

```
用户登录
  ├─> 加载本地数据
  │   ├─> DrinkingState（饮酒状态）
  │   ├─> VIP解锁状态
  │   └─> 用户偏好设置
  │
  ├─> 加载云端数据
  │   └─> UserProfile（用户档案）
  │
  └─> 同步GameProgress
      ├─> 加载本地GameProgress
      ├─> 加载云端GameProgress
      └─> 时间戳比较，决定同步方向
```

## 注意事项

1. **亲密度数据**：现在包含在GameProgress中的npcIntimacy字段，不再单独存储
2. **NPC解锁状态**：VIP NPC的解锁状态存本地，普通NPC默认解锁
3. **避免重复**：每个数据只在一个地方存储（除了GameProgress）
4. **性能考虑**：频繁读写的数据都在本地，减少网络请求
5. **隐私保护**：敏感数据（如饮酒状态）只存本地，不上传云端

## 迁移计划

1. **第一阶段**：重构IntimacyService，将亲密度数据合并到GameProgress
2. **第二阶段**：简化DataStorageService，只管理本地数据
3. **第三阶段**：创建GameProgressService专门处理同步
4. **第四阶段**：清理冗余代码和废弃的存储键
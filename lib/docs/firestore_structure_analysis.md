# Firestore 存储结构分析

## 当前实际使用的集合和字段

### 1. 主要集合

#### `users/{userId}` - 用户主文档
根据 `FirestoreService.dart` 的实际代码，当前存储了大量混合字段：

```dart
// Profile相关字段
accountCreatedAt: Timestamp      // 账号创建时间
lastLoginAt: Timestamp           // 最后登录时间
loginProvider: String            // 登录方式 (google/facebook)
username: String                 // 用户名
displayName: String              // 显示名称
email: String                    // 邮箱
photoUrl: String                 // 头像URL
language: String                 // 语言设置
country: String                  // 国家
isActive: bool                   // 是否活跃

// GameProgress相关字段（混在同一文档）
totalGames: int                  // 总游戏数
totalWins: int                   // 总胜利数
totalLosses: int                 // 总失败数
winRate: double                  // 胜率
totalChallenges: int            // 总挑战数
successfulChallenges: int       // 成功挑战数
totalBids: int                  // 总出价数
successfulBids: int             // 成功出价数
highestWinStreak: int           // 最高连胜
currentWinStreak: int           // 当前连胜
favoriteOpponent: String        // 最喜欢的对手
lastPlayedAt: Timestamp         // 最后游戏时间
totalPlayTimeMinutes: int       // 总游戏时长
achievements: List<String>      // 成就列表
vsAIWins: Map<String, int>      // 对各AI的胜利数
vsAILosses: Map<String, int>    // 对各AI的失败数
```

#### `gameProgress/{userId}` - 独立的游戏进度集合
根据 `CloudStorageService.dart` 和 `UnifiedGameProgress`：

```dart
userId: String
totalGames: int
totalWins: int
totalLosses: int
currentWinStreak: int
highestWinStreak: int
totalDrinks: int
npcIntimacy: Map<String, int>   // NPC亲密度数据
unlockedNPCs: List<String>
achievements: List<String>
lastSyncTimestamp: DateTime
```

### 2. 子集合

#### `users/{userId}/wallet/gems` - 宝石钱包
```dart
amount: int                      // 当前宝石数量
lastUpdated: Timestamp          // 最后更新时间
lastReason: String              // 最后更新原因
createdAt: Timestamp            // 创建时间
```

#### `users/{userId}/vipUnlocks/{characterId}` - VIP解锁记录
```dart
unlockedAt: Timestamp           // 解锁时间
gemsCost: int                   // 花费的宝石数
```

#### `users/{userId}/gemHistory/{transactionId}` - 宝石交易历史
```dart
amount: int                     // 交易金额（正负）
balance: int                    // 交易后余额
reason: String                  // 交易原因
timestamp: Timestamp            // 交易时间
```

#### `users/{userId}/achievements/{achievementId}` - 成就记录
```dart
unlockedAt: Timestamp           // 解锁时间
// 其他自定义数据
```

#### `users/{userId}/intimacy/{npcId}` - NPC亲密度（旧系统）
**注意：这是旧的IntimacyService使用的，应该被移除**
```dart
level: int                      // 亲密度等级
points: int                     // 亲密度点数
milestones: List<String>        // 达成的里程碑
lastInteractionAt: Timestamp    // 最后互动时间
```

## 问题分析

### 1. 数据冗余
- **游戏进度数据重复**：
  - `users/{userId}` 文档中有游戏进度字段
  - `gameProgress/{userId}` 独立集合也有游戏进度
  - 两处数据可能不一致

- **亲密度数据重复**：
  - `users/{userId}/intimacy/` 子集合（旧系统）
  - `gameProgress/{userId}` 中的 npcIntimacy 字段（新系统）

- **成就数据重复**：
  - `users/{userId}` 中的 achievements 字段
  - `users/{userId}/achievements/` 子集合
  - `gameProgress/{userId}` 中的 achievements 字段

### 2. 结构混乱
- `users/{userId}` 文档混合了用户档案和游戏进度
- 应该清晰分离：用户基本信息 vs 游戏数据

### 3. 废弃的字段
- `country` - 未使用
- `favoriteOpponent` - 未实现
- `totalChallenges`, `successfulChallenges` - 统计不准确
- `totalBids`, `successfulBids` - 统计不准确

## 建议的优化方案

### 1. 清理 `users/{userId}` 文档
只保留用户基本信息：
```yaml
users/{userId}:
  # 基本信息
  userId: String
  email: String
  displayName: String
  photoUrl: String
  
  # 账号信息
  accountCreatedAt: Timestamp
  lastLoginAt: Timestamp
  loginProvider: String
  
  # 设置（从本地移过来）
  languagePreference: String
  deviceIds: List<String>
  currentDeviceId: String
  firstLaunchDone: bool
```

### 2. 统一游戏进度存储
只使用 `gameProgress/{userId}` 集合，包含所有游戏相关数据和NPC亲密度

### 3. 删除冗余集合
- 删除 `users/{userId}/intimacy/` 子集合
- 删除 `users/{userId}` 中的所有游戏进度字段

### 4. 保留必要的子集合
- `users/{userId}/wallet/gems` - 宝石管理
- `users/{userId}/vipUnlocks/` - VIP解锁记录
- `users/{userId}/gemHistory/` - 交易历史（审计用）
- `users/{userId}/achievements/` - 成就详情（可选）

## 迁移步骤

1. **第一步**：修改 `FirestoreService.createOrUpdateUserProfile()`
   - 移除所有游戏进度相关字段
   - 只创建用户基本信息

2. **第二步**：删除 `IntimacyService` 的 Firestore 操作
   - 亲密度数据统一由 `GameProgressService` 管理

3. **第三步**：清理 `getUserProfile()` 和 `getGameProgress()`
   - 确保从正确的位置读取数据

4. **第四步**：数据迁移脚本
   - 将现有用户的游戏进度从 `users/{userId}` 迁移到 `gameProgress/{userId}`
   - 合并亲密度数据
# 数据存储策略文档

## 📊 数据分类和存储位置

### 1. 🔒 纯本地存储 (SharedPreferences)
**永远不同步到云端，每个设备独立**

#### 游戏状态数据
- **位置**: `user_{userId}_gameState`
- **内容**:
  - `playerDrinks` - 当前喝酒数
  - `lastDrinkTime` - 最后喝酒时间
  - `soberPotions` - 醒酒药水数量
- **原因**: 临时状态，与设备相关

#### AI饮酒状态
- **位置**: `user_{userId}_aiStates`
- **内容**:
  - 每个AI的当前喝酒数
  - 每个AI的最后喝酒时间
- **原因**: 临时游戏状态，醒酒机制是本地的

#### VIP解锁状态（临时）
- **位置**: `user_{userId}_vipUnlocks`
- **内容**:
  - 临时解锁记录（看广告解锁）
  - 过期时间
- **原因**: 临时权益，不跨设备

#### 用户偏好设置
- **位置**: `global_settings`
- **内容**:
  - 音效开关
  - 音乐开关
  - 震动开关
  - 语言设置
- **原因**: 设备相关的偏好

### 2. ☁️ 需要同步到Firestore
**跨设备同步，永久保存**

#### 游戏进度 (gameProgress集合)
- **Firestore路径**: `gameProgress/{userId}`
- **本地缓存**: `user_{userId}_gameProgress`
- **内容**:
  ```javascript
  {
    // 基础统计
    totalGames: 150,
    gamesWon: 75,
    gamesLost: 75,
    winRate: 0.5,
    currentWinStreak: 3,
    highestWinStreak: 10,
    
    // 游戏行为统计
    totalChallenges: 50,
    successfulChallenges: 30,
    totalBids: 500,
    successfulBids: 250,
    totalDrinks: 100,        // 累计喝酒总数（历史记录）
    maxDrinksInGame: 5,      // 单局最多喝酒数
    
    // AI对战记录（永久）
    aiRecords: {
      "0001": { wins: 10, losses: 5 },
      "0002": { wins: 8, losses: 7 }
    },
    
    // NPC亲密度（永久）
    npcIntimacy: {
      "0001": { level: 3, points: 150 },
      "0002": { level: 2, points: 80 }
    }
  }
  ```

#### 用户档案 (users集合)
- **Firestore路径**: `users/{userId}`
- **内容**:
  ```javascript
  {
    profile: {
      userId: "xxx",
      email: "user@gmail.com",
      displayName: "玩家名",
      accountCreatedAt: Timestamp,
      lastLoginAt: Timestamp
    },
    
    wallet: {
      gems: 245,              // 宝石数量（永久）
      totalEarned: 500,
      totalSpent: 255
    },
    
    vipUnlocks: {
      "1001": {               // 永久VIP解锁
        unlockType: "permanent",
        unlockDate: Timestamp,
        unlockMethod: "gems"
      }
    },
    
    achievements: {           // 成就系统
      "first_win": { unlockedAt: Timestamp },
      "win_streak_10": { unlockedAt: Timestamp }
    }
  }
  ```

### 3. 🔄 混合存储策略

#### 玩家行为分析 (PlayerProfile)
- **本地存储**: `user_{userId}_playerProfile`
- **Firestore存储**: 定期汇总上传
- **策略**:
  - 本地：详细的每局记录
  - 云端：汇总统计数据
  - 原因：减少写操作，降低成本

## 🎯 关键区别

### 本地存储特点
1. **临时性**: 醒酒状态、当前局游戏
2. **设备相关**: 音效设置、语言偏好
3. **高频更新**: 每次喝酒都更新
4. **无需同步**: 换设备重新开始

### 云端存储特点
1. **永久性**: 总胜场、成就、亲密度
2. **账号相关**: 宝石、VIP永久解锁
3. **低频更新**: 批量或重要时刻
4. **必须同步**: 换设备保留进度

## 📝 实现建议

### 当前问题
- LocalStorageService 混合了所有数据
- 没有明确的同步机制
- gameProgress数据结构不清晰

### 改进方案

#### 方案A：分离服务（推荐）
```dart
// 纯本地
class LocalGameStateService {
  // 只管理临时游戏状态
  saveDrinkingState()
  saveAIStates()
  saveSettings()
}

// 需要同步
class GameProgressService {
  // 管理永久进度
  saveToLocal()
  syncToFirestore()
  mergeConflicts()
}
```

#### 方案B：统一服务+标记
```dart
class LocalStorageService {
  // 添加同步标记
  saveData(key, data, {bool needSync = false})
  
  // 获取需要同步的数据
  getDataForSync()
}
```

## 🔐 数据安全

### 本地数据
- 卸载应用会清除
- 清除缓存会保留
- 无备份机制

### 云端数据
- 永久保存
- 自动备份
- 账号绑定

## 📊 成本考虑

### 高成本操作（避免）
- 每次喝酒都同步到Firestore
- 实时同步AI状态
- 频繁更新亲密度

### 低成本操作（推荐）
- 批量同步（每5局）
- 重要时刻同步（升级、成就）
- 退出时同步

## ✅ 实施清单

- [ ] 明确区分LocalStorageService的数据类型
- [ ] 实现GameProgressService的同步机制
- [ ] 添加同步冲突解决逻辑
- [ ] 实现批量同步策略
- [ ] 添加离线模式支持
- [ ] 实现数据版本控制
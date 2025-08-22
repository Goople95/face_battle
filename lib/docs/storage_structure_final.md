# 精简后的存储结构设计

## 设计原则
1. **零冗余**：每个数据只存一个地方
2. **最小化同步**：只有GameProgress需要同步
3. **清晰分离**：本地临时数据 vs 云端持久数据
4. **用户隔离**：所有用户数据都带userId前缀

---

## 📱 本地存储 (SharedPreferences)

### 键值结构
```yaml
# ========== 需要同步的数据 ==========
{userId}_game_progress:           # 游戏进度（与云端同步）
  {
    totalGames: 0,
    totalWins: 0, 
    totalLosses: 0,
    currentWinStreak: 0,
    highestWinStreak: 0,
    npcIntimacy: {                # NPC亲密度全部在这里
      "0001": 100,
      "0002": 50,
      "1001": 200
    },
    lastSyncTimestamp: "2025-08-21T10:00:00Z"
  }

# ========== 纯本地数据 ==========
{userId}_drinking_state:          # 饮酒状态（临时）
  {
    playerDrinks: 0,
    aiDrinks: {"0001": 0},
    lastDrinkTime: "2025-08-21T10:00:00Z",
    soberingUntil: null
  }

{userId}_current_round:           # 当前回合（游戏中断恢复）
  {
    playerDice: [1,2,3,4,5],
    aiDice: [2,2,3,4,5],
    currentBid: {quantity: 3, value: 4},
    roundNumber: 5
  }

{userId}_temp_vip_{characterId}:  # VIP临时解锁（1小时缓存）
  "2025-08-21T10:00:00Z"          # 解锁时间

{userId}_dialogue_shown:          # 对话去重缓存
  ["dialogue_001", "dialogue_045"] # 最近20条
```

---

## ☁️ 云端存储 (Firestore)

### 集合结构
```yaml
# ========== 用户主文档（所有数据都是嵌套字段） ==========
users/{userId}:
  # 用户档案
  profile: {
    userId: "xxx"
    email: "user@example.com"
    displayName: "玩家名称"
    photoUrl: "https://..."
    accountCreatedAt: Timestamp
    lastLoginAt: Timestamp
    loginProvider: "google.com"    # google.com/facebook.com
    languagePreference: "zh_CN"
    deviceIds: ["xxx-xxx", "yyy-yyy"]
    firstLaunchDone: true
    currentDeviceId: "xxx-xxx"
  }
  
  # 设备信息
  devices: {
    "device-id-1": {
      platform: "Android"
      model: "Galaxy S21"
      manufacturer: "Samsung"
      androidVersion: "11"
      sdkInt: 30
      isPhysicalDevice: true
      displayInfo: {
        widthPx: 1080,
        heightPx: 2400,
        xDpi: 420.0,
        yDpi: 420.0
      }
      numberOfProcessors: 8
      locale: "zh_CN"
      operatingSystem: "android"
      operatingSystemVersion: "11"
    },
    "device-id-2": {...}           # 其他设备
  }
  
  # 虚拟货币
  wallet: {
    gems: 100                      # 当前宝石数
    lastUpdated: Timestamp
    lastReason: "purchase:xxx"
    createdAt: Timestamp
  }
  
  # VIP解锁记录
  vipUnlocks: {
    "1001": {                      # characterId作为key
      unlockedAt: Timestamp
      gemsCost: 30
    },
    "1002": {...}
  }
  
  # 交易历史
  gemHistory: {
    "1234567890123": {             # 时间戳作为key
      amount: -30
      balance: 70
      reason: "vip_unlock_1001"
      timestamp: Timestamp
    },
    "1234567890456": {...}
  }
  
  # 成就记录
  achievements: {
    "first_win": {                 # 成就ID作为key
      unlockedAt: Timestamp
      progress: 100
      tier: "gold"
    },
    "streak_10": {...}
  }

# ========== 游戏进度（独立集合，需要同步） ==========
gameProgress/{userId}:
  # 游戏统计
  totalGames: 100
  totalWins: 60
  totalLosses: 40
  winRate: 0.6
  
  # 连胜记录
  currentWinStreak: 3
  highestWinStreak: 10
  
  # NPC亲密度（所有NPC数据都在这里）
  npcIntimacy: {
    "0001": 500,                   # 教授
    "0002": 300,                   # 赌徒
    "1001": 1000,                  # VIP角色1
    "1002": 200                    # VIP角色2
  }
  
  # 里程碑
  milestones: [
    "first_win",
    "streak_10",
    "intimacy_1000"
  ]
  
  # 同步信息
  lastSyncTimestamp: Timestamp
  deviceId: "xxx-xxx-xxx"         # 最后同步设备
```

---

## 🔄 数据对比表

| 数据类型 | 本地存储 | 云端存储 | 同步策略 |
|---------|---------|---------|---------|
| **游戏进度** | ✅ `{userId}_game_progress` | ✅ `gameProgress/{userId}` | 双向同步 |
| **NPC亲密度** | ✅ 在game_progress内 | ✅ 在gameProgress内 | 随游戏进度同步 |
| **用户档案** | ❌ | ✅ `users/{userId}.profile` | 只读 |
| **设备信息** | ❌ | ✅ `users/{userId}.devices` | 只写 |
| **宝石数量** | ❌ | ✅ `users/{userId}.wallet` | 只读 |
| **VIP永久解锁** | ❌ | ✅ `users/{userId}.vipUnlocks` | 只读 |
| **VIP临时解锁** | ✅ `{userId}_temp_vip_{id}` | ❌ | 不同步 |
| **饮酒状态** | ✅ `{userId}_drinking_state` | ❌ | 不同步 |
| **当前回合** | ✅ `{userId}_current_round` | ❌ | 不同步 |
| **成就记录** | ❌ | ✅ `users/{userId}.achievements` | 只读 |
| **交易历史** | ❌ | ✅ `users/{userId}.gemHistory` | 只写 |
| **对话缓存** | ✅ `{userId}_dialogue_shown` | ❌ | 不同步 |
| **语言设置** | ❌ | ✅ `users/{userId}.profile.languagePreference` | 只读 |
| **设备ID** | ❌ | ✅ `users/{userId}.profile.deviceIds` | 只写 |
| **首次启动** | ❌ | ✅ `users/{userId}.profile.firstLaunchDone` | 只读 |

---

## 🎯 关键改进

### 1. 消除的冗余
- ❌ ~~本地多个player_profile版本~~ → 不存储
- ❌ ~~Firestore的intimacy子集合~~ → 合并到gameProgress
- ❌ ~~本地存储宝石和VIP永久解锁~~ → 只在云端
- ❌ ~~多套饮酒状态系统~~ → 统一格式

### 2. 新的统一规则
- 本地键统一格式：`{userId}_功能名称_{子ID}`
- 云端路径统一：`users/{userId}` 单文档，所有数据作为嵌套字段
- 时间戳统一：ISO 8601格式字符串

### 3. 同步简化
- **只有一个需要同步**：GameProgress
- **同步时机**：
  - 每5局游戏
  - 获得成就时
  - 破纪录时
  - 登录/登出时

### 4. 安全性提升
- 宝石只在云端（防修改）
- VIP解锁只在云端（防作弊）
- 交易历史完整记录（可审计）

---

## 📊 存储大小估算

### 本地存储
- game_progress: ~2KB
- drinking_state: ~500B
- 其他缓存: ~500B
- **总计**: ~3KB/用户

### 云端存储
- 用户文档: ~10KB（包含所有嵌套字段）
- gameProgress: ~2KB
- **总计**: ~12KB/用户

### Firestore 操作数估算
- 登录: 2次读取（用户文档 + gameProgress）
- 游戏结束: 1次写入（gameProgress）
- VIP解锁: 1次写入（用户文档更新多个字段）
- **日均操作**: ~20-50次/活跃用户
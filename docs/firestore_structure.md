# Firestore 数据库结构文档

## 概述
Face Battle (表情博弈) 游戏的 Firestore 数据库采用扁平化设计，主要包含用户数据和游戏进度两大部分。

最后更新时间：2025-08-22

## 1. 集合结构

### 1.1 users 集合
路径：`users/{userId}`

主要存储用户的所有相关数据，包括个人信息、设备信息、虚拟货币、解锁记录等。

### 1.2 gameProgress 集合  
路径：`gameProgress/{userId}`

独立存储游戏进度数据，便于排行榜查询和数据分析。

## 2. users 集合详细结构

### 2.1 profile 字段（用户基本信息）

| 字段名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| userId | string | 用户唯一标识 | "Agf7ErkVw4aLKEKukqHwW6kTDMa2" |
| email | string | 用户邮箱 | "user@gmail.com" |
| displayName | string | 显示名称 | "John Smith" |
| photoUrl | string? | 头像URL | "https://lh3.googleusercontent.com/..." |
| accountCreatedAt | Timestamp | 账号创建时间 | 2025-08-20T10:30:00Z |
| lastLoginAt | Timestamp | 最后登录时间 | 2025-08-22T14:55:00Z |
| loginMethod | string | 登录方式 | "google" / "facebook" |
| userType | string | 用户类型 | "normal" / "internal" / "test" |
| deviceLanguage | string? | 设备系统语言 | "zh_CN" / "en_US" |
| userSelectedLanguage | string? | 用户选择的语言 | "zh_CN" / "en" |
| country | string? | 国家名称 | "China" / "United States" |
| countryCode | string? | 国家代码 | "CN" / "US" |
| region | string? | 省/州 | "广东省" / "California" |
| city | string? | 城市 | "深圳" / "San Francisco" |
| timezone | string? | 时区名称 | "Asia/Shanghai" |
| utcOffset | string? | UTC偏移 | "UTC+8" / "UTC-5" |
| isp | string? | 网络运营商 | "China Telecom" / "AT&T" |

### 2.2 device 字段（设备信息）

| 字段名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| platform | string | 平台 | "Android" / "iOS" / "Windows" |
| manufacturer | string? | 制造商 | "Samsung" / "Apple" |
| model | string? | 设备型号 | "Galaxy S24" / "iPhone 15" |
| brand | string? | 品牌 | "samsung" / "apple" |
| androidVersion | string? | Android版本 | "14" |
| systemVersion | string? | iOS系统版本 | "17.0" |
| sdkInt | number? | Android SDK版本 | 34 |
| isPhysicalDevice | boolean | 是否物理设备 | true / false |
| supported32BitAbis | string? | 32位架构支持 | "armeabi-v7a,armeabi" |
| supported64BitAbis | string? | 64位架构支持 | "arm64-v8a" |
| locale | string | 系统语言 | "zh_CN" |
| numberOfProcessors | number | 处理器核心数 | 8 |
| operatingSystem | string | 操作系统 | "android" / "ios" |
| operatingSystemVersion | string | 系统版本详情 | "14" |

### 2.3 wallet 字段（虚拟货币钱包）

| 字段名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| gems | number | 当前宝石数量 | 245 |
| totalEarned | number? | 总共获得的宝石 | 500 |
| totalSpent | number? | 总共花费的宝石 | 255 |
| lastUpdated | Timestamp | 最后更新时间 | 2025-08-22T14:50:00Z |
| lastDailyBonus | Timestamp? | 上次领取每日奖励 | 2025-08-22T00:00:00Z |

### 2.4 vipUnlocks 字段（VIP角色解锁记录）

结构：`vipUnlocks/{characterId}`

| 字段名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| unlockType | string | 解锁类型 | "permanent" / "temporary" |
| unlockDate | Timestamp | 解锁时间 | 2025-08-21T15:30:00Z |
| unlockMethod | string | 解锁方式 | "gems" / "ad" / "promotion" |
| cost | number | 花费宝石数 | 30 |
| expiresAt | Timestamp? | 过期时间（临时解锁） | 2025-08-22T14:00:00Z |
| expired | boolean? | 是否已过期 | false |

### 2.5 gemHistory 字段（宝石交易历史）

数组结构，每个元素包含：

| 字段名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| type | string | 交易类型 | "earn" / "spend" |
| amount | number | 交易数量 | 20 |
| reason | string | 交易原因 | "daily_login" / "unlock_vip" |
| description | string? | 详细描述 | "每日登录奖励" |
| relatedId | string? | 相关ID | "1001" (角色ID) |
| timestamp | Timestamp | 交易时间 | 2025-08-22T00:00:00Z |
| balance | number? | 交易后余额 | 265 |

#### 交易原因类型 (reason)
- **获得宝石**：
  - `daily_login` - 每日登录
  - `achievement` - 成就奖励
  - `watch_ad` - 观看广告
  - `level_up` - 等级提升
  - `event_reward` - 活动奖励
  - `referral` - 推荐奖励

- **消费宝石**：
  - `unlock_vip` - 解锁VIP角色
  - `continue_game` - 游戏续命
  - `buy_item` - 购买道具
  - `skip_ad` - 跳过广告

### 2.6 achievements 字段（成就系统）

结构：`achievements/{achievementId}`

| 字段名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| unlockedAt | Timestamp? | 解锁时间 | 2025-08-20T11:00:00Z |
| progress | number | 当前进度 | 45 |
| target | number | 目标值 | 50 |
| reward | object | 奖励内容 | {gems: 30, title: "骰子大师"} |
| claimed | boolean | 是否已领取奖励 | false |

#### 成就类型示例
- `first_win` - 首次胜利
- `win_streak_5` - 5连胜
- `win_streak_10` - 10连胜
- `play_100_games` - 玩100局
- `master_bluffer` - 虚张声势大师
- `drunk_master` - 千杯不醉
- `challenge_king` - 挑战之王

### 2.7 settings 字段（游戏设置）

| 字段名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| soundEnabled | boolean | 音效开关 | true |
| musicEnabled | boolean | 音乐开关 | false |
| vibrationEnabled | boolean | 震动开关 | true |
| notificationsEnabled | boolean | 通知开关 | true |
| autoSave | boolean | 自动保存 | true |
| difficulty | string | 难度设置 | "easy" / "normal" / "hard" |
| theme | string | 主题设置 | "light" / "dark" / "auto" |
| lastUpdated | Timestamp | 最后更新时间 | 2025-08-22T10:00:00Z |

## 3. gameProgress 集合详细结构

路径：`gameProgress/{userId}`

### 3.1 基础统计

| 字段名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| userId | string | 用户ID | "Agf7ErkVw4aLKEKukqHwW6kTDMa2" |
| totalGames | number | 总游戏局数 | 150 |
| gamesWon | number | 胜利局数 | 75 |
| gamesLost | number | 失败局数 | 75 |
| winRate | number | 胜率 | 0.5 |
| currentWinStreak | number | 当前连胜 | 3 |
| highestWinStreak | number | 最高连胜 | 10 |

### 3.2 游戏行为统计

| 字段名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| totalChallenges | number | 总挑战次数 | 50 |
| successfulChallenges | number | 成功挑战次数 | 30 |
| challengeSuccessRate | number | 挑战成功率 | 0.6 |
| totalBids | number | 总出价次数 | 500 |
| successfulBids | number | 成功出价次数 | 250 |
| bidSuccessRate | number | 出价成功率 | 0.5 |
| totalDrinks | number | 总饮酒数 | 100 |
| maxDrinksInGame | number | 单局最多饮酒 | 5 |

### 3.3 AI对战记录

结构：`aiRecords/{aiId}`

| 字段名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| wins | number | 对该AI胜利次数 | 10 |
| losses | number | 对该AI失败次数 | 5 |
| lastPlayed | Timestamp | 最后对战时间 | 2025-08-22T12:00:00Z |
| winRate | number? | 对该AI胜率 | 0.667 |

### 3.4 NPC亲密度

结构：`npcIntimacy/{npcId}`

| 字段名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| level | number | 亲密度等级 | 3 |
| points | number | 亲密度点数 | 150 |
| interactions | number | 互动次数 | 20 |
| lastInteraction | Timestamp? | 最后互动时间 | 2025-08-22T14:00:00Z |

### 3.5 元数据

| 字段名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| lastUpdated | Timestamp | 最后更新时间 | 2025-08-22T14:55:00Z |
| lastSyncTimestamp | Timestamp | 最后同步时间 | 2025-08-22T14:00:00Z |
| dataVersion | number? | 数据版本 | 1 |

## 4. 数据同步策略

### 4.1 实时更新字段
- `profile.lastLoginAt` - 每次登录更新
- `profile.deviceLanguage` - 每次登录更新
- `profile.country/region/city` - 每次登录更新
- `device` - 每次登录更新

### 4.2 按需更新字段
- `wallet` - 宝石变化时更新
- `vipUnlocks` - 解锁新角色时更新
- `achievements` - 达成新成就时更新
- `settings` - 用户修改设置时更新

### 4.3 批量同步字段
- `gameProgress` - 每5局或重要成就时同步
- `gemHistory` - 定期批量写入（避免频繁写操作）

## 5. 数据量预估

### 5.1 单用户文档大小
- **新用户**：2-3 KB（仅profile和device）
- **活跃用户**：5-10 KB（包含wallet、部分history）
- **重度用户**：15-30 KB（完整数据）
- **理论上限**：1 MB（Firestore单文档限制）

### 5.2 存储成本估算
按1万活跃用户计算：
- 平均文档大小：10 KB
- 总存储量：10 KB × 10,000 = 100 MB
- 月存储成本：约 $0.02（Firestore存储价格：$0.18/GB/月）

### 5.3 读写成本估算
- 每用户每日平均读取：10次
- 每用户每日平均写入：5次
- 月总读取：10 × 10,000 × 30 = 3,000,000次
- 月总写入：5 × 10,000 × 30 = 1,500,000次

## 6. 安全规则建议

```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用户只能读写自己的数据
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 游戏进度同样限制
    match /gameProgress/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // NPC配置所有人可读，仅管理员可写
    match /npcConfig/{npcId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.profile.userType == 'admin';
    }
  }
}
```

## 7. 索引配置

建议创建以下复合索引以优化查询性能：

1. **排行榜查询**
   - Collection: `gameProgress`
   - Fields: `winRate (DESC)`, `totalGames (DESC)`

2. **活跃用户查询**
   - Collection: `users`
   - Fields: `profile.lastLoginAt (DESC)`, `profile.userType (ASC)`

3. **地区统计**
   - Collection: `users`
   - Fields: `profile.country (ASC)`, `profile.userType (ASC)`

## 8. 数据迁移和版本管理

### 8.1 版本标识
- 在 `metadata.documentVersion` 中记录文档结构版本
- 当前版本：v2

### 8.2 向后兼容
- 读取时检查字段是否存在，提供默认值
- 新增字段使用可选类型（nullable）
- 保留旧字段名的读取兼容（如 loginProvider → loginMethod）

### 8.3 数据清理
- 定期清理过期的临时解锁记录
- 归档超过30天的 gemHistory 到子集合
- 删除超过90天未登录的测试账号数据

## 9. 监控指标

建议监控以下关键指标：

1. **性能指标**
   - 平均文档大小
   - 读写操作延迟
   - 同步失败率

2. **业务指标**
   - 日活跃用户数（DAU）
   - 付费转化率（解锁VIP角色）
   - 用户留存率

3. **成本指标**
   - 每日读写操作数
   - 存储使用量增长率
   - 每用户平均成本

## 10. 最佳实践

1. **减少读写操作**
   - 使用本地缓存，减少重复读取
   - 批量更新而非频繁单次更新
   - 使用 FieldValue.increment() 进行原子操作

2. **数据结构优化**
   - 保持文档扁平化，避免深层嵌套
   - 大数据集使用子集合而非数组
   - 合理使用索引提升查询性能

3. **安全性**
   - 严格的安全规则，防止越权访问
   - 敏感数据加密存储
   - 定期备份重要数据

4. **可扩展性**
   - 预留字段扩展空间
   - 使用版本控制管理结构变更
   - 模块化设计便于功能扩展

---

*文档版本：1.0*  
*最后更新：2025-08-22*  
*维护者：开发团队*
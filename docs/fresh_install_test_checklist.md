# 全新安装测试清单

## 测试前准备
1. ✅ 完全卸载应用（长按图标 → 卸载）
2. ✅ 清除Google Play/App Store的云备份（如果有）
3. ✅ 重新安装应用

## 初值检查清单

### 1. 游戏状态 (DrinkingState)
- [ ] `playerDrinks` = 0（玩家喝酒数）
- [ ] `soberPotions` = 0（醒酒药水）
- [ ] `totalLosses` = 0（总失败次数）
- [ ] `consecutiveLosses` = 0（连续失败）
- [ ] `playerLastDrinkTime` = null
- [ ] 所有AI的 `aiDrinks[id]` = 0
- [ ] 所有AI的 `aiLastDrinkTimes[id]` = null

### 2. 玩家档案 (PlayerProfile)
- [ ] `totalGames` = 0（总游戏数）
- [ ] `totalWins` = 0（总胜利数）
- [ ] `totalChallenges` = 0（总质疑次数）
- [ ] `successfulChallenges` = 0（成功质疑）
- [ ] `totalBluffs` = 0（虚张次数）
- [ ] `caughtBluffing` = 0（被抓虚张）
- [ ] `bluffingTendency` = 0.3（默认虚张倾向）
- [ ] `challengeTendency` = 0.4（默认质疑倾向）
- [ ] `aggressiveness` = 0.5（默认激进度）
- [ ] `predictability` = 0.5（默认可预测性）
- [ ] `preferredValues` = {}（空）
- [ ] `patterns` = 各项为0
- [ ] `recentGames` = []（空数组）
- [ ] `vsAIRecords` = {}（空）
- [ ] `npcIntimacy` = {}（空）

### 3. 亲密度系统 (IntimacyData)
- [ ] 所有NPC的亲密度 = 0
- [ ] `intimacyLevel` = 0（初遇）
- [ ] `totalGames` = 0
- [ ] `wins` = 0
- [ ] `losses` = 0
- [ ] `unlockedDialogues` = []（空）
- [ ] `achievedMilestones` = []（空）

### 4. VIP解锁
- [ ] 所有VIP角色显示为锁定状态
- [ ] 无解锁记录

### 5. 全局设置
- [ ] `soundEnabled` = true
- [ ] `musicEnabled` = true
- [ ] `vibrationEnabled` = true
- [ ] `language` = 'zh'（或系统语言）

## 功能测试

### 首次游戏
1. [ ] 能正常开始游戏
2. [ ] AI头像正常显示（未解锁的显示锁定）
3. [ ] 骰子能正常摇动
4. [ ] 叫牌功能正常

### 首次失败
1. [ ] 喝酒动画正常播放
2. [ ] `playerDrinks` 增加到 1
3. [ ] `totalLosses` 增加到 1
4. [ ] 醉酒提示正确（应显示"小酌一杯"）

### 首次胜利
1. [ ] AI喝酒动画正常
2. [ ] AI的 `aiDrinks[id]` 增加到 1
3. [ ] `totalWins` 增加到 1
4. [ ] 亲密度增加

### 数据持久化
1. [ ] 退出应用再进入，数据保持
2. [ ] 切换用户，数据独立
3. [ ] 游客模式数据独立保存

## 边界情况

### 空数据处理
- [ ] LocalStorage未初始化时的错误提示
- [ ] userId为null时的处理
- [ ] 网络断开时本地数据正常工作

### 数据完整性
- [ ] 所有数字字段不会出现NaN
- [ ] 所有百分比在0-1范围内
- [ ] 时间字段格式正确

## 已知问题修复确认

1. ✅ AI管理统一使用数字ID
2. ✅ 命名规范统一为驼峰式
3. ✅ 用户数据完全隔离
4. ✅ 移除旧的兼容代码

## 测试结果

- 测试日期：_______
- 测试版本：_______
- 测试设备：_______
- 测试结果：□ 通过 □ 失败

## 问题记录

如发现问题，请记录：
1. 问题描述：
2. 复现步骤：
3. 期望结果：
4. 实际结果：
5. 截图/日志：
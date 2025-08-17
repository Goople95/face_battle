# 📱 Google AdMob 集成指南

## 功能说明

游戏已集成Google AdMob激励视频广告，用于醒酒机制：
- **玩家醉酒**：观看广告立即完全清醒
- **AI醉酒**：玩家可选择观看广告帮AI醒酒继续游戏，或直接获胜

## 当前配置（测试模式）

项目默认使用Google提供的测试广告ID，可以在开发阶段正常测试广告功能。

### 测试广告ID
- **App ID**: `ca-app-pub-3940256099942544~3347511713` 
- **激励视频广告单元ID (Android)**: `ca-app-pub-3940256099942544/5224354917`
- **激励视频广告单元ID (iOS)**: `ca-app-pub-3940256099942544/1712485313`

## 正式发布前的配置步骤

### 1. 创建AdMob账号

1. 访问 [Google AdMob](https://admob.google.com/)
2. 使用Google账号登录
3. 完成账号设置和付款信息

### 2. 创建应用

1. 在AdMob控制台点击"应用" → "添加应用"
2. 选择平台（Android/iOS）
3. 输入应用信息：
   - 应用名称：骰子吹牛
   - 包名：com.odt.liarsdice

### 3. 创建广告单元

1. 选择广告格式：**激励广告**
2. 配置广告单元：
   - 广告单元名称：醒酒广告
   - 奖励设置：
     - 奖励类型：醒酒
     - 奖励数量：1

### 4. 替换测试ID为真实ID

#### 4.1 更新AdMob服务类

编辑 `lib/services/admob_service.dart`：

```dart
// 注释掉测试ID
// static const String _androidRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
// static const String _iosRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313';

// 使用真实ID
static const String _androidRewardedAdUnitId = 'ca-app-pub-你的发布者ID/你的广告单元ID';
static const String _iosRewardedAdUnitId = 'ca-app-pub-你的发布者ID/你的广告单元ID';
```

#### 4.2 更新Android配置

编辑 `android/app/src/main/AndroidManifest.xml`：

```xml
<!-- 替换为真实App ID -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-你的发布者ID~你的应用ID"/>
```

#### 4.3 更新iOS配置（如需支持iOS）

编辑 `ios/Runner/Info.plist`：

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-你的发布者ID~你的应用ID</string>
```

### 5. 添加测试设备（开发阶段）

在开发阶段，即使使用真实广告ID，也应该配置测试设备避免违规：

1. 运行应用并查看日志
2. 找到类似这样的日志：
   ```
   I/Ads: Use RequestConfiguration.Builder.setTestDeviceIds(Arrays.asList("33BE2250B43518CCDA7DE426D04EE231"))
   ```
3. 复制设备ID并更新 `lib/services/admob_service.dart`：
   ```dart
   final testDeviceIds = <String>[
     '33BE2250B43518CCDA7DE426D04EE231', // 你的测试设备ID
   ];
   ```

## 广告策略建议

### 频率限制
- 建议限制每小时最多观看3-5次广告
- 可以增加醒酒药水作为付费道具

### 用户体验优化
- 预加载广告，减少等待时间
- 提供跳过选项（如使用道具）
- 广告失败时提供备用方案

### 收益优化
- 设置合理的eCPM底价
- 使用中介功能接入多个广告网络
- 监控广告填充率和收益数据

## 何时切换到真实广告ID

### ✅ 可以使用真实广告ID的时机：
1. **应用已成功上架Google Play商店**
2. **应用通过Google Play的审核并公开发布**
3. **AdMob账号已审核通过**
4. **应用在AdMob后台已关联到Google Play**

### ❌ 必须使用测试广告ID的情况：
1. **本地开发阶段**
2. **内部测试阶段**
3. **Google Play Console的封闭测试/开放测试阶段**
4. **应用未上架或审核中**

### 切换步骤：
1. 确认应用已在Google Play上架
2. 在AdMob后台关联应用商店链接
3. 修改`lib/services/admob_service.dart`中的广告单元ID
4. 修改`AndroidManifest.xml`中的App ID
5. 发布更新版本

## 注意事项

⚠️ **重要提醒**：
1. **测试阶段**必须使用测试广告ID或将设备添加为测试设备
2. **严禁**在开发阶段点击真实广告，会导致账号被封
3. **应用未上架前使用真实ID会被视为无效流量**
4. 遵守AdMob政策，不要诱导用户点击广告
5. 切换到真实ID后，仍需添加开发设备为测试设备

## 常见问题

### Q: 广告不显示
- 检查网络连接
- 确认AdMob账号审核通过
- 查看日志中的错误信息

### Q: 广告加载失败
- 可能是填充率问题，某些地区广告库存不足
- 检查广告单元ID是否正确
- 确认应用包名与AdMob配置一致

### Q: 收益很低
- 新应用需要时间积累数据
- 优化用户留存和活跃度
- 考虑接入广告中介

## 相关链接

- [AdMob官方文档](https://developers.google.com/admob)
- [Flutter广告插件](https://pub.dev/packages/google_mobile_ads)
- [AdMob政策中心](https://support.google.com/admob/answer/6128543)
- [广告实施最佳做法](https://support.google.com/admob/answer/9989474)
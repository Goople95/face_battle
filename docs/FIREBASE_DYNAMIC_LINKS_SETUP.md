# Firebase Dynamic Links 设置指南

## 📋 概览
本文档说明如何设置Firebase Dynamic Links，以实现分享追踪功能。通过Dynamic Links，你可以：
- 追踪二维码被扫描的次数
- 统计通过分享带来的安装量
- 分析不同分享渠道的效果

## 🚀 设置步骤

### 1. 在Firebase Console中启用Dynamic Links

1. 打开 [Firebase Console](https://console.firebase.google.com)
2. 选择你的项目 (Dice Girls)
3. 在左侧菜单中找到 **Engage** → **Dynamic Links**
4. 点击 **Get started**

### 2. 创建动态链接域名

1. 点击 **New Dynamic Link**
2. 设置URL前缀，例如：
   - `https://dicegirls.page.link`
   - 或使用自定义域名：`https://share.yourdomain.com`
3. 如果使用自定义域名，需要验证域名所有权

### 3. 配置Android应用

在Firebase Console的Dynamic Links设置中：

1. **Android应用设置**：
   - 包名：`com.odt.liarsdice`
   - 最低版本：21（或你的minSdkVersion）
   - Play商店链接：`https://play.google.com/store/apps/details?id=com.odt.liarsdice`

2. **添加SHA证书指纹**（重要）：
   ```bash
   # 获取debug证书指纹
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # 获取release证书指纹
   keytool -list -v -keystore your-release-key.keystore -alias your-alias-name
   ```
   将SHA-1和SHA-256指纹添加到Firebase项目设置中

### 4. 更新代码中的配置

在 `lib/services/dynamic_link_service.dart` 中更新：

```dart
// 将这行改为你的实际域名
uriPrefix: 'https://dicegirls.page.link',  // 修改为你的Dynamic Link域名

// 如果有自己的分享图片服务器，更新这里
imageUrl: Uri.parse('https://yourdomain.com/share_image.png'),
```

### 5. Android配置

确保 `android/app/src/main/AndroidManifest.xml` 包含：

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data 
        android:host="dicegirls.page.link" 
        android:scheme="https"/>
</intent-filter>
```

## 📊 追踪数据

### 在Firebase Console查看数据

1. 进入 **Dynamic Links** → **Analytics**
2. 可以查看：
   - 点击次数（Click）
   - 首次打开（First Open）
   - 重新打开（Re-open）

### 使用UTM参数

代码已配置UTM参数，可在Google Analytics中追踪：
- `utm_source=qr_share` - 来源是二维码分享
- `utm_medium=social` - 媒介是社交分享
- `utm_campaign=share_[timestamp]` - 每次分享的唯一标识

### 在Google Play Console查看

如果集成了Google Play的安装追踪：
1. 进入 **Google Play Console** → **用户获取** → **获取报告**
2. 可以看到通过UTM参数带来的安装量

## 🔧 测试

### 测试动态链接

1. 运行应用生成分享卡片
2. 扫描二维码或点击链接
3. 检查是否正确跳转到Play商店
4. 安装应用后检查是否记录了来源

### 调试模式

在 `dynamic_link_service.dart` 中已添加日志：
```dart
LoggerUtils.info('生成动态链接成功: ${shortLink.shortUrl}');
LoggerUtils.debug('追踪参数: campaign=$campaignId');
```

## 📈 进阶功能

### 1. 自定义落地页

如果用户未安装应用，可以创建一个落地页：
- 展示游戏介绍
- 显示分享者的战绩
- 提供下载按钮

### 2. 奖励机制

可以追踪谁带来了新用户：
```dart
// 在处理动态链接时
final referrerId = deepLink.queryParameters['referrer'];
// 给分享者奖励
```

### 3. A/B测试

使用不同的campaign参数测试：
- 不同的分享文案
- 不同的分享图片
- 不同的奖励机制

## ⚠️ 注意事项

1. **Firebase Dynamic Links即将停用**
   - Google计划在2025年8月25日停用Dynamic Links
   - 建议同时准备备用方案（如Branch.io或自建短链服务）

2. **隐私合规**
   - 确保遵守GDPR等隐私法规
   - 在隐私政策中说明追踪行为

3. **测试环境**
   - Debug和Release使用不同的SHA证书
   - 确保两个证书都已添加到Firebase

## 🔗 相关资源

- [Firebase Dynamic Links文档](https://firebase.google.com/docs/dynamic-links)
- [UTM参数说明](https://support.google.com/analytics/answer/1033863)
- [Google Play安装追踪](https://support.google.com/googleplay/android-developer/answer/6263332)
- [替代方案：Branch.io](https://branch.io/)

## 📝 检查清单

- [ ] Firebase Console中启用Dynamic Links
- [ ] 创建并验证动态链接域名
- [ ] 添加SHA证书指纹
- [ ] 更新代码中的域名配置
- [ ] 测试链接生成和跳转
- [ ] 在Analytics中查看数据
- [ ] 制定Dynamic Links停用后的迁移计划
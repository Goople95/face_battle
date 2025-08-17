# Facebook登录配置指南

## ✅ 已完成的配置

1. **Flutter依赖**: 已添加 `flutter_facebook_auth: ^6.0.3`
2. **Android配置文件**: 已创建并配置
   - `strings.xml` - 包含Facebook配置占位符
   - `AndroidManifest.xml` - 已添加Facebook Activities
3. **代码实现**: 已完成Facebook登录逻辑

## ⚠️ 您需要完成的步骤

### 1. 创建Facebook应用

1. 访问 [Facebook Developers](https://developers.facebook.com/)
2. 点击"我的应用" → "创建应用"
3. 选择应用类型：**消费者**
4. 填写应用信息：
   - 应用名称：骰子吹牛 (Liar's Dice)
   - 应用联系邮箱：您的邮箱

### 2. 配置Facebook登录

1. 在应用面板中，点击"添加产品"
2. 找到"Facebook登录"，点击"设置"
3. 选择"Android"平台

### 3. 配置Android设置

填写以下信息：
- **包名**: `com.odt.liarsdice`
- **默认Activity类名**: `com.odt.liarsdice.MainActivity`

### 4. 生成并添加密钥哈希

#### 开发密钥哈希（Debug）
```bash
keytool -exportcert -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore | openssl sha1 -binary | openssl base64
```
密码: `android`

#### 生产密钥哈希（Release）
需要您的发布密钥库文件

将生成的哈希值添加到Facebook应用设置中。

### 5. 获取Facebook App ID和Client Token

1. 在Facebook应用面板，进入"设置" → "基本"
2. 复制以下信息：
   - **应用ID** (App ID)
   - **客户端令牌** (Client Token) - 需要先生成

### 6. 更新项目配置

编辑 `android/app/src/main/res/values/strings.xml`：
```xml
<string name="facebook_app_id">您的Facebook应用ID</string>
<string name="facebook_client_token">您的Client Token</string>
<string name="fb_login_protocol_scheme">fb您的Facebook应用ID</string>
```

例如，如果您的App ID是 `123456789`：
```xml
<string name="facebook_app_id">123456789</string>
<string name="facebook_client_token">abcdef123456...</string>
<string name="fb_login_protocol_scheme">fb123456789</string>
```

### 7. 在Firebase启用Facebook登录

1. 打开 [Firebase Console](https://console.firebase.google.com/)
2. 选择您的项目 `liarsdice-fd930`
3. 进入 Authentication → Sign-in method
4. 启用 Facebook
5. 填入：
   - **App ID**: 您的Facebook应用ID
   - **App Secret**: 从Facebook应用设置中获取
6. 复制OAuth重定向URI，添加到Facebook应用的"有效OAuth重定向URI"中

### 8. Facebook应用审核设置

为了让其他用户能够使用Facebook登录：
1. 在Facebook应用中，进入"应用审核"
2. 将应用切换为"上线"模式（用于生产环境）
3. 或保持"开发"模式（仅供测试）

## 测试步骤

1. 清理并重建项目：
```bash
flutter clean
flutter pub get
flutter run
```

2. 点击Facebook登录按钮测试

## 常见问题

### 错误：Invalid key hash
- 确保添加了正确的密钥哈希
- 开发和生产环境需要不同的哈希值

### 错误：App not set up
- 检查Facebook App ID是否正确
- 确保在Firebase中启用了Facebook登录

### 错误：This app has no Android platform
- 在Facebook应用设置中添加Android平台
- 填写正确的包名

## 注意事项

- Facebook App Secret不要提交到代码仓库
- 开发环境和生产环境使用不同的密钥哈希
- 确保Facebook应用的隐私政策和服务条款URL已设置（生产环境必需）
# Facebook 登录配置说明

## 问题说明
应用启动时出现 Facebook 相关错误：
```
Error validating application. Invalid application ID.
```

这是因为应用使用了默认的占位符 `YOUR_FACEBOOK_APP_ID` 而不是实际的 Facebook 应用ID。

## 解决方案

### 选项1：配置实际的 Facebook 应用（推荐用于生产环境）

1. 前往 [Facebook Developers](https://developers.facebook.com/)
2. 创建一个新应用或选择现有应用
3. 获取您的应用ID和客户端令牌
4. 更新以下文件：

**android/app/src/main/res/values/strings.xml**
```xml
<string name="facebook_app_id">您的实际Facebook应用ID</string>
<string name="facebook_client_token">您的实际Facebook客户端令牌</string>
<string name="fb_login_protocol_scheme">fb您的实际Facebook应用ID</string>
```

**ios/Runner/Info.plist**
```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>fb您的实际Facebook应用ID</string>
</array>
...
<key>FacebookAppID</key>
<string>您的实际Facebook应用ID</string>
<key>FacebookClientToken</key>
<string>您的实际Facebook客户端令牌</string>
<key>FacebookDisplayName</key>
<string>您的应用名称</string>
```

### 选项2：暂时禁用 Facebook 登录（开发环境）

如果您暂时不需要 Facebook 登录功能，可以：

1. 在登录界面隐藏 Facebook 登录按钮
2. 或者使用测试应用ID（仅用于开发）

## 注意事项

- 这些错误不会影响 Google 登录功能
- Facebook SDK 会在后台尝试初始化，即使不使用也会产生日志
- 生产环境必须使用有效的 Facebook 应用ID

## 测试应用ID（仅开发环境）

如果只是为了消除错误日志，可以使用 Facebook 的测试应用ID：
- App ID: `1234567890123456`（示例，不能用于实际登录）

**重要**：测试ID只能消除错误日志，不能实现实际的登录功能。
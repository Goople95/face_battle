# Facebook登录配置总结

## 已完成的配置

### 1. Android配置
✅ **strings.xml** (android/app/src/main/res/values/strings.xml)
- facebook_app_id: 4095236344097179
- fb_login_protocol_scheme: fb4095236344097179
- facebook_client_token: **需要更新**

✅ **AndroidManifest.xml** 
- Facebook Activity配置已添加
- Meta-data引用已配置

### 2. iOS配置
✅ **Info.plist** (ios/Runner/Info.plist)
- FacebookAppID: 4095236344097179
- FacebookDisplayName: Dice Girls
- CFBundleURLSchemes: fb4095236344097179
- FacebookClientToken: **需要更新**
- LSApplicationQueriesSchemes: fbapi, fb-messenger-share-api

### 3. Flutter代码
✅ **auth_service.dart**
- signInWithFacebook() 方法已实现
- 移除了测试配置警告

✅ **login_screen.dart**
- Facebook登录按钮已启用
- UI已完善（蓝色按钮，白色logo）
- 本地化文本已配置

## 需要从Facebook开发者控制台获取的信息

### 必需：Client Token
1. 登录 https://developers.facebook.com/
2. 选择你的应用 (App ID: 4095236344097179)
3. 进入 设置 > 高级
4. 找到 "Client Token" 并复制

### 需要更新Client Token的位置：
1. `android/app/src/main/res/values/strings.xml` - 第9行
2. `ios/Runner/Info.plist` - 第63行

## Facebook开发者控制台配置检查清单

请确认以下配置已在Facebook开发者控制台完成：

### 基本设置
- [ ] 应用名称：Dice Girls（或你的应用名）
- [ ] 应用域名：已配置（如果有）
- [ ] 隐私政策URL：已填写
- [ ] 服务条款URL：已填写

### Facebook登录设置
- [ ] 已启用Facebook登录产品
- [ ] 有效的OAuth重定向URI：已配置
- [ ] Android平台设置：
  - [ ] 包名：com.odt.liarsdice
  - [ ] 类名：com.odt.liarsdice.MainActivity
  - [ ] Key Hashes：已添加（开发和发布）
- [ ] iOS平台设置：
  - [ ] Bundle ID：已配置

### 权限和功能
- [ ] email权限：已启用
- [ ] public_profile权限：已启用

## 生成Android Key Hash的方法

### 开发环境Key Hash:
```bash
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
```
密码：android

### 发布环境Key Hash:
```bash
keytool -exportcert -alias your-key-alias -keystore your-keystore-path | openssl sha1 -binary | openssl base64
```

## 测试步骤

1. 获取并更新Client Token
2. 运行应用：`flutter run`
3. 点击"使用 Facebook 账号登录"
4. 完成Facebook OAuth流程
5. 验证登录成功并跳转到主界面

## 注意事项

- Facebook登录使用的是Firebase Authentication的Facebook provider
- 用户数据会根据Firebase UID自动隔离存储
- Google登录和Facebook登录的用户数据完全独立
- 首次登录会创建新的用户记录
# Firebase配置指南

## 问题说明
当前Google登录失败是因为Firebase配置文件与应用包名不匹配：
- **应用包名**: `com.odt.liarsdice`
- **Firebase配置包名**: `com.example.face_battle`

## 解决步骤

### 1. 访问Firebase控制台
打开 [Firebase Console](https://console.firebase.google.com/)

### 2. 选择项目
选择您的项目 `liarsdice-fd930`

### 3. 添加Android应用
1. 点击项目设置（齿轮图标）
2. 在"您的应用"部分，点击"添加应用"
3. 选择Android平台

### 4. 注册应用
- **Android包名**: `com.odt.liarsdice`
- **应用昵称**: Face Battle（可选）
- **调试签名证书SHA-1**: （可选，但建议添加以确保Google登录正常工作）

#### 获取SHA-1指纹（Windows）
```bash
cd android
./gradlew signingReport
```
或使用keytool：
```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### 5. 下载配置文件
1. 下载新的 `google-services.json` 文件
2. 替换项目中的文件：`android/app/google-services.json`

### 6. 配置OAuth 2.0客户端ID
1. 在Firebase控制台中，进入"Authentication" > "Sign-in method"
2. 确保"Google"已启用
3. 在Google Cloud Console中：
   - 访问 [Google Cloud Console](https://console.cloud.google.com/)
   - 选择您的项目
   - 进入"APIs & Services" > "Credentials"
   - 创建OAuth 2.0客户端ID（如果还没有）
   - 类型选择"Android"
   - 包名填写：`com.odt.liarsdice`
   - SHA-1证书指纹：填写上面获取的SHA-1

### 7. 重要配置
确保在Firebase控制台的Authentication设置中：
- 已启用Google登录
- 已添加支持的域名（如果需要）
- OAuth同意屏幕已配置

## 测试步骤
1. 清理并重建项目：
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. 测试Google登录功能

## 常见问题

### ApiException: 10
- 原因：配置不匹配或SHA-1未添加
- 解决：确保包名匹配，添加正确的SHA-1指纹

### ApiException: 12500
- 原因：SHA-1指纹不正确
- 解决：重新生成并添加SHA-1

### 登录后立即退出
- 原因：Firebase Auth配置问题
- 解决：检查Firebase控制台的认证设置

## 注意事项
- 开发环境和生产环境需要不同的SHA-1指纹
- 发布版本需要使用发布密钥的SHA-1
- 确保google-services.json文件不要提交到公开仓库
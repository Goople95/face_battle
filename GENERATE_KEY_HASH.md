# 生成 Android Key Hash 指南

## 需要生成两个 Key Hash

### 1. 开发环境 Key Hash（Debug）
用于开发和测试阶段

**Windows (PowerShell):**
```powershell
keytool -exportcert -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore | openssl sha1 -binary | openssl base64
```

**Mac/Linux:**
```bash
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
```

**密码：** android（默认密码）

### 2. 生产环境 Key Hash（Release）
用于发布到 Google Play 的正式版本

```bash
keytool -exportcert -alias [你的密钥别名] -keystore [你的密钥库路径] | openssl sha1 -binary | openssl base64
```

需要输入你的密钥库密码

## 如何添加到 Facebook？

1. 登录 [Facebook Developers](https://developers.facebook.com/)
2. 选择你的应用（App ID: 4095236344097179）
3. 进入 **设置** > **基本**
4. 向下滚动找到 **Android** 平台
5. 在 **Key Hashes** 字段中添加生成的 hash（可以添加多个，每行一个）

## 常见问题

### Q: 没有安装 OpenSSL 怎么办？

**Windows:**
- 下载 OpenSSL: https://slproweb.com/products/Win32OpenSSL.html
- 或使用 Git Bash（已包含 OpenSSL）

**Mac:**
- 通常已预装，如果没有：`brew install openssl`

**Linux:**
- Ubuntu/Debian: `sudo apt-get install openssl`
- CentOS/RHEL: `sudo yum install openssl`

### Q: 找不到 debug.keystore？

debug.keystore 位置：
- Windows: `C:\Users\[用户名]\.android\debug.keystore`
- Mac/Linux: `~/.android/debug.keystore`

如果不存在，运行一次 `flutter run` 会自动生成

### Q: 生成的 hash 看起来像什么？

正常的 hash 类似：`ga0RGNYHvNM5d0SLGQfpQWAPGJ8=`
（28个字符，包含字母、数字、+、/、=）

## 重要提示

1. **开发阶段**：只需要添加 Debug Key Hash
2. **发布前**：必须添加 Release Key Hash
3. **Google Play App Signing**：如果使用 Google Play 应用签名，还需要添加 Google Play 的签名 hash
4. **多台开发机器**：每台机器的 debug.keystore 不同，都需要添加对应的 hash

## 验证是否正确

添加后测试 Facebook 登录：
- 成功登录 = Key Hash 正确
- 报错 "Invalid key hash" = 需要添加报错信息中显示的 hash
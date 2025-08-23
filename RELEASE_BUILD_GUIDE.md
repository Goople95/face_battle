# 发布版本构建指南

## 密钥信息
- **密钥库文件**: `android/app/release-key.keystore`
- **密钥别名**: `odt-release`
- **密钥库密码**: `MyStorePass123`
- **密钥密码**: `MyKeyPass123`

## 生成 Facebook Release Key Hash

### 方法1：使用 PowerShell 脚本（推荐）
```powershell
.\generate_release_hash.ps1
```
输入密码：`MyStorePass123`

### 方法2：直接命令
```bash
cd android
keytool -exportcert -alias odt-release -keystore app/release-key.keystore | openssl sha1 -binary | openssl base64
```
输入密码：`MyStorePass123`

## 构建发布版本

### 构建 APK（用于直接分发）
```bash
flutter build apk --release
```
输出位置：`build/app/outputs/flutter-apk/app-release.apk`

### 构建 App Bundle（推荐，用于 Google Play）
```bash
flutter build appbundle --release
```
输出位置：`build/app/outputs/bundle/release/app-release.aab`

## Facebook Key Hashes 配置

需要在 Facebook 开发者控制台添加两个 Key Hash：

1. **Debug Key Hash**（开发测试）
   - 已添加的：`huw/cUAjXXIHRsAKR+nLDB3BhxM=`

2. **Release Key Hash**（发布版本）
   - 运行上述命令生成并添加

## 检查清单

### 发布前确认：
- [ ] Release Key Hash 已添加到 Facebook
- [ ] 版本号已更新（pubspec.yaml）
- [ ] 所有功能测试通过
- [ ] Release 版本构建成功
- [ ] APK/AAB 文件大小合理（通常 < 100MB）

### Google Play 发布（如适用）：
- [ ] 应用截图准备完成
- [ ] 应用描述已更新
- [ ] 隐私政策链接有效
- [ ] 内容分级已完成

## 故障排除

### 问题：签名失败
**解决**：检查 `android/app/key.properties` 文件路径和密码

### 问题：Facebook 登录失败（Invalid key hash）
**解决**：
1. 确认添加了正确的 Key Hash
2. 等待几分钟让 Facebook 更新配置
3. 清除应用缓存后重试

### 问题：构建失败
**解决**：
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## 重要提醒

1. **保护密钥文件**：
   - 不要将 `release-key.keystore` 提交到公开仓库
   - 不要将 `key.properties` 提交到公开仓库
   - 备份这两个文件到安全位置

2. **密钥丢失后果**：
   - 无法更新已发布的应用
   - 需要创建新应用重新发布

3. **Google Play App Signing**：
   - 建议启用，Google 会管理你的签名密钥
   - 需要额外添加 Google Play 的签名 Hash 到 Facebook
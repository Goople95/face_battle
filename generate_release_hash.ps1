# 生成 Facebook Release Key Hash
Write-Host "生成 Facebook Release Key Hash" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

# 切换到 android 目录
Set-Location android

# 生成 Release Key Hash
Write-Host "请输入密钥库密码 (storePassword): MyStorePass123" -ForegroundColor Yellow
$hash = keytool -exportcert -alias odt-release -keystore app/release-key.keystore | openssl sha1 -binary | openssl base64

Write-Host ""
Write-Host "生成的 Release Key Hash:" -ForegroundColor Green
Write-Host $hash -ForegroundColor Cyan
Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "请将上面的 Hash 添加到 Facebook 开发者控制台" -ForegroundColor Yellow
Write-Host "位置: 设置 > 基本 > Android > Key Hashes" -ForegroundColor Yellow
Write-Host ""

# 返回项目根目录
Set-Location ..

Write-Host "按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
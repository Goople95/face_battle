# setup_firebase.ps1
# 完整配置 Firebase 和包名的脚本

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Firebase 项目配置脚本" -ForegroundColor Cyan
Write-Host "  包名: com.odt.liarsdice" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 步骤 1: 创建 MainActivity.kt
Write-Host "[1/5] 创建 MainActivity.kt..." -ForegroundColor Yellow

$mainDir = "android/app/src/main/kotlin/com/odt/liarsdice"

# 检查目录是否存在
if (!(Test-Path $mainDir)) {
    New-Item -ItemType Directory -Force -Path $mainDir | Out-Null
    Write-Host "  ✓ 创建目录: $mainDir" -ForegroundColor Green
}

# 创建 MainActivity.kt
$mainActivityContent = @"
package com.odt.liarsdice

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()
"@

$mainActivityPath = "$mainDir/MainActivity.kt"
$mainActivityContent | Out-File -FilePath $mainActivityPath -Encoding UTF8
Write-Host "  ✓ MainActivity.kt 创建完成" -ForegroundColor Green

# 步骤 2: 删除旧的目录（如果存在）
Write-Host "[2/5] 清理旧文件..." -ForegroundColor Yellow

$oldDir = "android/app/src/main/kotlin/com/example"
if (Test-Path $oldDir) {
    Remove-Item -Recurse -Force $oldDir -ErrorAction SilentlyContinue
    Write-Host "  ✓ 删除旧目录: $oldDir" -ForegroundColor Green
} else {
    Write-Host "  - 没有旧目录需要清理" -ForegroundColor Gray
}

# 步骤 3: 验证配置
Write-Host "[3/5] 验证配置..." -ForegroundColor Yellow

# 检查 build.gradle.kts
$gradleCheck = Select-String -Path "android/app/build.gradle.kts" -Pattern "com.odt.liarsdice" -Quiet
if ($gradleCheck) {
    Write-Host "  ✓ Android 包名配置正确" -ForegroundColor Green
} else {
    Write-Host "  ✗ Android 包名可能需要手动检查" -ForegroundColor Red
}

# 检查 iOS
$iosCheck = Select-String -Path "ios/Runner.xcodeproj/project.pbxproj" -Pattern "com.odt.liarsdice" -Quiet
if ($iosCheck) {
    Write-Host "  ✓ iOS Bundle ID 配置正确" -ForegroundColor Green
} else {
    Write-Host "  ! iOS Bundle ID 可能需要检查" -ForegroundColor Yellow
}

# 步骤 4: 清理 Flutter 项目
Write-Host "[4/5] 清理 Flutter 项目..." -ForegroundColor Yellow
flutter clean
Write-Host "  ✓ Flutter 清理完成" -ForegroundColor Green

# 步骤 5: 删除旧的 Firebase 配置
Write-Host "[5/5] 准备 Firebase 配置..." -ForegroundColor Yellow

$firebaseOptions = "lib/firebase_options.dart"
if (Test-Path $firebaseOptions) {
    Remove-Item $firebaseOptions -Force
    Write-Host "  ✓ 删除旧的 firebase_options.dart" -ForegroundColor Green
} else {
    Write-Host "  - 没有旧的 Firebase 配置文件" -ForegroundColor Gray
}

# 完成提示
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ✅ 准备工作完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "现在运行以下命令配置 Firebase：" -ForegroundColor Cyan
Write-Host ""
Write-Host "  flutterfire configure --project=liarsdice-fd930" -ForegroundColor White
Write-Host ""
Write-Host "配置时会自动检测到包名：com.odt.liarsdice" -ForegroundColor Gray
Write-Host ""

# 询问是否自动运行
$response = Read-Host "是否立即运行 Firebase 配置？(y/n)"
if ($response -eq 'y' -or $response -eq 'Y') {
    Write-Host ""
    Write-Host "正在运行 Firebase 配置..." -ForegroundColor Yellow
    flutterfire configure --project=liarsdice-fd930
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  🎉 Firebase 配置完成！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "下一步：" -ForegroundColor Cyan
    Write-Host "1. 添加 Firebase 依赖到 pubspec.yaml：" -ForegroundColor White
    Write-Host "   flutter pub add firebase_core firebase_auth google_sign_in" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. 初始化 Firebase (在 main.dart)：" -ForegroundColor White
    Write-Host "   import 'firebase_options.dart';" -ForegroundColor Gray
    Write-Host "   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);" -ForegroundColor Gray
} else {
    Write-Host "脚本结束。请手动运行 Firebase 配置命令。" -ForegroundColor Yellow
}
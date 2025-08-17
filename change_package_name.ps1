# fix_package_name.ps1
Write-Host "开始修改包名为 com.odt.liarsdice" -ForegroundColor Green

# 1. 检查并修改 Android build.gradle
$gradlePath = "android/app/build.gradle"
if (Test-Path $gradlePath) {
    Write-Host "修改 Android build.gradle..." -ForegroundColor Yellow
    $content = Get-Content $gradlePath
    $content = $content -replace 'applicationId\s+"[^"]*"', 'applicationId "com.odt.liarsdice"'
    Set-Content $gradlePath $content
    Write-Host "✓ Android build.gradle 修改完成" -ForegroundColor Green
} else {
    Write-Host "✗ 找不到 android/app/build.gradle" -ForegroundColor Red
}

# 2. 检查 MainActivity 路径并修改
$oldMainPath = "android/app/src/main/kotlin/com/example/face_battle/MainActivity.kt"
$newMainDir = "android/app/src/main/kotlin/com/odt/liarsdice"
$newMainPath = "$newMainDir/MainActivity.kt"

if (Test-Path $oldMainPath) {
    Write-Host "修改 MainActivity.kt..." -ForegroundColor Yellow
    
    # 创建新目录
    New-Item -ItemType Directory -Force -Path $newMainDir | Out-Null
    
    # 读取并修改内容
    $content = Get-Content $oldMainPath -Raw
    $content = $content -replace 'package\s+com\.example\.face_battle', 'package com.odt.liarsdice'
    
    # 写入新位置
    Set-Content $newMainPath $content
    
    # 删除旧目录
    Remove-Item -Recurse -Force "android/app/src/main/kotlin/com/example" -ErrorAction SilentlyContinue
    Write-Host "✓ MainActivity.kt 修改完成" -ForegroundColor Green
} else {
    Write-Host "! MainActivity.kt 不在预期位置，尝试查找..." -ForegroundColor Yellow
    
    # 尝试 Java 路径
    $javaMainPath = "android/app/src/main/java/com/example/face_battle/MainActivity.java"
    if (Test-Path $javaMainPath) {
        Write-Host "找到 Java MainActivity" -ForegroundColor Yellow
        # 处理 Java 版本...
    }
}

# 3. 修改 iOS Bundle ID
$pbxPath = "ios/Runner.xcodeproj/project.pbxproj"
if (Test-Path $pbxPath) {
    Write-Host "修改 iOS Bundle ID..." -ForegroundColor Yellow
    $content = Get-Content $pbxPath -Raw
    $content = $content -replace 'com\.example\.face[_]?[Bb]attle', 'com.odt.liarsdice'
    Set-Content $pbxPath $content
    Write-Host "✓ iOS Bundle ID 修改完成" -ForegroundColor Green
}

# 4. 验证结果
Write-Host "`n========== 验证结果 ==========" -ForegroundColor Cyan
Write-Host "Android:" -ForegroundColor Yellow
Select-String -Path "android/app/build.gradle" -Pattern "applicationId" | ForEach-Object { Write-Host $_.Line }

Write-Host "`niOS:" -ForegroundColor Yellow  
Select-String -Path "ios/Runner.xcodeproj/project.pbxproj" -Pattern "PRODUCT_BUNDLE_IDENTIFIER" | Select-Object -First 1 | ForEach-Object { Write-Host $_.Line }

Write-Host "`n✅ 完成！下一步：" -ForegroundColor Green
Write-Host "1. flutter clean" -ForegroundColor White
Write-Host "2. flutterfire configure --project=liarsdice-fd930" -ForegroundColor White
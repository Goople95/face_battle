param(
  [string]$File = ""
)

function Resolve-Target {
  param([string]$f)
  if ($f -and (Test-Path $f)) { return $f }
  $candidates = @(
    "build\app\outputs\bundle\release\app-release.aab",
    "build\app\outputs\flutter-apk\app-release.apk"
  )
  foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
  throw "未找到文件，请传入 .aab 或 .apk 路径：`n  .\check-android-version.ps1 <path-to-file>"
}

$target = Resolve-Target -f $File
$ext = [System.IO.Path]::GetExtension($target).ToLower()
if ($ext -notin @(".aab",".apk")) { throw "仅支持 .aab 或 .apk 文件。" }

$work = Join-Path ([System.IO.Path]::GetDirectoryName($target)) "ver_tmp"
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory -Path $work | Out-Null

# 解压
Expand-Archive -Path $target -DestinationPath $work

# 查找 AndroidManifest.xml（AAB 在 base/manifest/ 下；APK 在 AndroidManifest.xml 或 manifest/）
$manifest = Get-ChildItem -Recurse $work | Where-Object { $_.Name -eq "AndroidManifest.xml" } | Select-Object -First 1
if (-not $manifest) { throw "未找到 AndroidManifest.xml" }

# 提取版本信息
$lines = Get-Content $manifest.FullName
$versionCode = ($lines -match 'android:versionCode="([0-9]+)"') | Out-Null; $versionCode = ($matches[1])
$versionName = ($lines -match 'android:versionName="([0-9A-Za-z\.\-\+]+)"') | Out-Null; $versionName = ($matches[1])

Write-Host "File: $target"
Write-Host "versionName: $versionName"
Write-Host "versionCode: $versionCode"

# 可选：清理临时目录
Remove-Item $work -Recurse -Force

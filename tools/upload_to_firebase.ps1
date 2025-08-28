# Firebase Storage 上传脚本
# 使用前请确保：
# 1. 已安装 gsutil (通过 gcloud SDK)
# 2. 已登录 gcloud auth login
# 3. 修改下面的项目名称

param(
    [string]$ProjectName = "liarsdice-fd930",  # LiarsDice Firebase项目
    [string]$LocalPath = "./firebase_upload/npcs",
    [switch]$DryRun = $false
)

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Firebase Storage Upload Script" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$bucket = "gs://$ProjectName.appspot.com"
Write-Host "Target bucket: $bucket" -ForegroundColor Yellow
Write-Host "Source path: $LocalPath" -ForegroundColor Yellow
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN MODE - No files will be uploaded" -ForegroundColor Magenta
    Write-Host ""
}

# 检查gsutil是否安装
try {
    gsutil version | Out-Null
} catch {
    Write-Host "ERROR: gsutil not found!" -ForegroundColor Red
    Write-Host "Please install Google Cloud SDK first:" -ForegroundColor Red
    Write-Host "https://cloud.google.com/sdk/docs/install" -ForegroundColor Red
    exit 1
}

# 检查本地文件夹
if (-not (Test-Path $LocalPath)) {
    Write-Host "ERROR: Local path not found: $LocalPath" -ForegroundColor Red
    exit 1
}

# 上传函数
function Upload-File {
    param(
        [string]$Local,
        [string]$Remote
    )
    
    if (Test-Path $Local) {
        Write-Host "Uploading: " -NoNewline
        Write-Host $Local -ForegroundColor Green -NoNewline
        Write-Host " -> " -NoNewline
        Write-Host $Remote -ForegroundColor Blue
        
        if (-not $DryRun) {
            gsutil cp "$Local" "$Remote"
        }
    } else {
        Write-Host "Warning: File not found - $Local" -ForegroundColor Yellow
    }
}

# 上传配置文件
Write-Host "`n=== Uploading Configuration Files ===" -ForegroundColor Cyan
Upload-File "$LocalPath/config.json" "$bucket/npcs/config.json"
Upload-File "$LocalPath/version.json" "$bucket/npcs/version.json"

# 获取所有NPC文件夹
$npcFolders = Get-ChildItem -Path $LocalPath -Directory

foreach ($npcFolder in $npcFolders) {
    $npcId = $npcFolder.Name
    Write-Host "`n=== Uploading NPC: $npcId ===" -ForegroundColor Cyan
    
    # 上传头像
    $avatarPath = "$LocalPath/$npcId/avatar.jpg"
    Upload-File $avatarPath "$bucket/npcs/$npcId/avatar.jpg"
    
    # 上传视频文件
    $videosPath = "$LocalPath/$npcId/videos"
    if (Test-Path $videosPath) {
        Write-Host "Uploading videos..." -ForegroundColor Yellow
        
        $videoFiles = @(
            "happy.mp4", "angry.mp4", "confident.mp4", "nervous.mp4",
            "suspicious.mp4", "surprised.mp4", "drunk.mp4", 
            "thinking.mp4", "laughing.mp4", "crying.mp4"
        )
        
        foreach ($video in $videoFiles) {
            Upload-File "$videosPath/$video" "$bucket/npcs/$npcId/videos/$video"
        }
    }
}

# 设置权限和缓存
if (-not $DryRun) {
    Write-Host "`n=== Setting Permissions ===" -ForegroundColor Cyan
    
    # 设置公开读取权限
    Write-Host "Making files public..." -ForegroundColor Yellow
    gsutil -m acl ch -r -u AllUsers:R "$bucket/npcs/"
    
    # 设置缓存策略
    Write-Host "Setting cache headers..." -ForegroundColor Yellow
    # 配置文件 - 短缓存
    gsutil -m setmeta -h "Cache-Control:public, max-age=3600" "$bucket/npcs/config.json"
    gsutil -m setmeta -h "Cache-Control:public, max-age=3600" "$bucket/npcs/version.json"
    
    # 资源文件 - 长缓存
    gsutil -m setmeta -r -h "Cache-Control:public, max-age=604800" "$bucket/npcs/*/avatar.jpg"
    gsutil -m setmeta -r -h "Cache-Control:public, max-age=604800" "$bucket/npcs/*/videos/*.mp4"
}

Write-Host "`n================================" -ForegroundColor Green
Write-Host "Upload Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# 显示访问URL示例
$httpUrl = "https://firebasestorage.googleapis.com/v0/b/$ProjectName.appspot.com/o"
Write-Host "`nExample URLs:" -ForegroundColor Cyan
Write-Host "Config: $httpUrl/npcs%2Fconfig.json?alt=media" -ForegroundColor White
Write-Host "Avatar: $httpUrl/npcs%2F2001%2Favatar.jpg?alt=media" -ForegroundColor White
Write-Host "Video:  $httpUrl/npcs%2F2001%2Fvideos%2Fhappy.mp4?alt=media" -ForegroundColor White
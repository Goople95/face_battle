# Flutter 运行和日志脚本 (优化版)
# 使用方法: .\flutter_run_log.ps1 [参数]

# 解析命令行参数
$DebugMode = $false
$ReleaseMode = $false
$ProfileMode = $false
$VerboseMode = $false
$NoFilterMode = $false
$DeviceId = ""
$TargetFile = ""

# 处理参数
for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i].ToLower()) {
        "-debug" { $DebugMode = $true }
        "-release" { $ReleaseMode = $true }
        "-profile" { $ProfileMode = $true }
        "-verbose" { $VerboseMode = $true }
        "-nofilter" { $NoFilterMode = $true }
        "-device" { 
            if ($i + 1 -lt $args.Count) {
                $DeviceId = $args[$i + 1]
                $i++
            }
        }
        "-target" { 
            if ($i + 1 -lt $args.Count) {
                $TargetFile = $args[$i + 1]
                $i++
            }
        }
    }
}

# 设置输出编码为 UTF-8（防止中文乱码）
$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 创建 logs 目录（如不存在）
$logDir = "logs"
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

# 确定构建模式
$mode = "debug"
if ($ReleaseMode) { $mode = "release" }
elseif ($ProfileMode) { $mode = "profile" }

# 日志文件名
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$logFile = "$logDir/flutter_${mode}_$timestamp.txt"

# 构建 Flutter 命令参数
$flutterArgs = @("run", "--color")

# 添加构建模式
if ($ReleaseMode) {
    $flutterArgs += "--release"
} elseif ($ProfileMode) {
    $flutterArgs += "--profile"
} else {
    $flutterArgs += "--debug"
}

# 添加其他参数
if ($VerboseMode) {
    $flutterArgs += "--verbose"
}

if ($DeviceId -ne "") {
    $flutterArgs += "--device-id", $DeviceId
}

if ($TargetFile -ne "") {
    $flutterArgs += "--target", $TargetFile
}

# 系统日志过滤列表
$systemLogFilters = @(
    "avc:",                    # SELinux 权限警告
    "audit:",                  # 审计日志
    "Choreographer",           # 主线程性能警告
    "CCodecConfig",            # 视频编解码器配置
    "WindowOnBackDispatcher",  # 窗口返回调度器
    "MediaCodec",              # 媒体编解码器
    "BufferQueueProducer",     # 缓冲区队列
    "chatty",                  # 重复日志标记
    "SurfaceFlinger",          # 界面渲染器
    "ActivityManager",         # 活动管理器系统日志
    "InputMethodManager",      # 输入法管理器
    "ViewRootImpl",            # 视图根实现
    "WindowManager",           # 窗口管理器
    "MetadataUtil.*Skipped"    # 视频元数据警告
)

# 日志过滤函数
function Test-ShouldFilterLine {
    param([string]$line)
    
    if ($NoFilterMode) {
        return $false  # 不过滤
    }
    
    foreach ($filter in $systemLogFilters) {
        if ($line -like "*$filter*") {
            return $true  # 需要过滤
        }
    }
    
    return $false  # 不需要过滤
}

# 显示启动信息
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚀 Flutter 运行脚本 (优化版)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 模式: $mode" -ForegroundColor Yellow
Write-Host "📄 日志文件: $logFile" -ForegroundColor Yellow
Write-Host "🔧 命令: flutter $($flutterArgs -join ' ')" -ForegroundColor Yellow

if (!$NoFilterMode) {
    Write-Host "🔍 日志过滤: 已启用 (过滤系统调试信息)" -ForegroundColor Green
    Write-Host "   - 使用 -NoFilter 参数可以显示完整日志" -ForegroundColor Gray
} else {
    Write-Host "🔍 日志过滤: 已禁用 (显示完整日志)" -ForegroundColor Red
}

Write-Host ""
Write-Host "⚡ 正在启动应用..." -ForegroundColor Green
Write-Host ""

# 创建日志头部信息
$logHeader = @"
========================================
Flutter 运行日志
========================================
时间: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
模式: $mode
命令: flutter $($flutterArgs -join ' ')
过滤: $(if (!$NoFilterMode) { "启用" } else { "禁用" })
========================================

"@

# 写入日志头部
$logHeader | Out-File -FilePath $logFile -Encoding UTF8

# 运行 Flutter 并处理日志
try {
    # 使用管道运行 Flutter 并实时处理输出
    & flutter.bat @flutterArgs 2>&1 | ForEach-Object {
        $line = $_.ToString()
        
        if ($line.Trim() -ne "") {
            # 检查是否需要过滤
            $shouldFilter = Test-ShouldFilterLine -line $line
            
            if (!$shouldFilter) {
                # 在控制台显示
                Write-Host $line
                
                # 写入日志文件
                $line | Out-File -FilePath $logFile -Append -Encoding UTF8
            }
        }
    }
    
} catch {
    Write-Error "运行 Flutter 时出错: $($_.Exception.Message)"
    $_.Exception.Message | Out-File -FilePath $logFile -Append -Encoding UTF8
} finally {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "📄 日志已保存到: $logFile" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
}

# 使用说明
Write-Host ""
Write-Host "💡 使用提示:" -ForegroundColor Yellow
Write-Host "   .\flutter_run_log.ps1                    # 默认调试模式"
Write-Host "   .\flutter_run_log.ps1 -Release           # 发布模式"
Write-Host "   .\flutter_run_log.ps1 -Profile           # 性能分析模式"
Write-Host "   .\flutter_run_log.ps1 -Verbose           # 详细日志"
Write-Host "   .\flutter_run_log.ps1 -NoFilter          # 不过滤系统日志"
Write-Host "   .\flutter_run_log.ps1 -Device 'device-id' # 指定设备"
Write-Host ""
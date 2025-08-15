#!/usr/bin/env python3
"""
使用 FFmpeg 的 MP4视频批量压缩工具
将当前目录下的所有MP4文件压缩并调整分辨率为512x512
"""

import os
import sys
import subprocess
from pathlib import Path
import time
import shutil

def check_ffmpeg():
    """检查系统是否安装了 FFmpeg"""
    try:
        result = subprocess.run(['ffmpeg', '-version'], 
                              capture_output=True, 
                              text=True, 
                              check=False)
        if result.returncode == 0:
            return True
    except FileNotFoundError:
        pass
    return False

def get_video_info(input_path):
    """获取视频文件信息"""
    try:
        cmd = [
            'ffprobe',
            '-v', 'error',
            '-show_entries', 'format=duration,size',
            '-show_entries', 'stream=width,height',
            '-of', 'json',
            str(input_path)
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        import json
        info = json.loads(result.stdout)
        
        # 提取信息
        duration = float(info.get('format', {}).get('duration', 0))
        size = int(info.get('format', {}).get('size', 0))
        
        # 获取视频流信息
        for stream in info.get('streams', []):
            if stream.get('width'):
                width = stream.get('width', 0)
                height = stream.get('height', 0)
                return duration, size, width, height
        
        return duration, size, 0, 0
    except:
        return 0, 0, 0, 0

def compress_video_ffmpeg(input_path, output_path, resolution=512, crf=23):
    """
    使用 FFmpeg 压缩视频
    
    Args:
        input_path: 输入视频文件路径
        output_path: 输出视频文件路径
        resolution: 目标分辨率（正方形）
        crf: 质量控制参数
    """
    try:
        print(f"正在处理: {input_path}")
        
        # 获取原始视频信息
        duration, original_size, width, height = get_video_info(input_path)
        
        # 构建 FFmpeg 命令
        cmd = [
            'ffmpeg',
            '-i', str(input_path),           # 输入文件
            '-vf', f'scale={resolution}:{resolution}',  # 缩放到 512x512
            '-c:v', 'libx264',                # 视频编码器
            '-preset', 'medium',              # 编码速度预设
            '-crf', str(crf),                 # 质量控制（23 = 高质量）
            '-c:a', 'aac',                    # 音频编码器
            '-b:a', '128k',                   # 音频比特率
            '-y',                             # 覆盖输出文件
            str(output_path)
        ]
        
        # 执行压缩
        start_time = time.time()
        result = subprocess.run(cmd, 
                              capture_output=True, 
                              text=True,
                              check=True)
        
        process_time = time.time() - start_time
        
        # 获取压缩后的文件大小
        compressed_size = os.path.getsize(output_path)
        
        # 计算压缩率
        if original_size > 0:
            compression_ratio = (1 - compressed_size / original_size) * 100
        else:
            compression_ratio = 0
        
        print(f"✓ 完成: {input_path}")
        print(f"  原始: {width}x{height}, {original_size/(1024*1024):.2f} MB")
        print(f"  处理后: {resolution}x{resolution}, {compressed_size/(1024*1024):.2f} MB")
        if compression_ratio > 0:
            print(f"  文件减小: {compression_ratio:.1f}%")
        else:
            print(f"  文件增大: {abs(compression_ratio):.1f}%")
        print(f"  处理时间: {process_time:.1f} 秒\n")
        
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"✗ 处理失败: {input_path}")
        print(f"  错误信息: {e.stderr if e.stderr else str(e)}\n")
        return False
    except Exception as e:
        print(f"✗ 处理失败: {input_path}")
        print(f"  错误信息: {str(e)}\n")
        return False

def batch_compress_with_ffmpeg():
    """批量压缩 - 直接使用 FFmpeg 命令"""
    # 获取当前目录
    current_dir = Path.cwd()
    
    # 创建输出目录
    output_dir = current_dir / "compressed_videos"
    output_dir.mkdir(exist_ok=True)
    
    # 查找所有MP4文件
    mp4_files = list(current_dir.glob("*.mp4"))
    
    if not mp4_files:
        print("当前目录下没有找到MP4文件")
        return
    
    print(f"找到 {len(mp4_files)} 个MP4文件")
    print(f"输出目录: {output_dir}")
    print(f"目标分辨率: 512x512")
    print(f"质量设置: CRF 23 (高质量)\n")
    print("=" * 50)
    
    # 统计信息
    success_count = 0
    failed_count = 0
    total_start_time = time.time()
    
    # 处理每个视频文件
    for i, mp4_file in enumerate(mp4_files, 1):
        print(f"\n[{i}/{len(mp4_files)}] 处理中...")
        
        # 保持原文件名，只是放在不同目录
        output_file = output_dir / mp4_file.name
        
        # 压缩视频
        if compress_video_ffmpeg(mp4_file, output_file):
            success_count += 1
        else:
            failed_count += 1
    
    # 打印总结
    total_time = time.time() - total_start_time
    print("=" * 50)
    print("\n处理完成!")
    print(f"成功: {success_count} 个文件")
    print(f"失败: {failed_count} 个文件")
    print(f"总用时: {total_time:.1f} 秒")
    print(f"\n处理后的文件保存在: {output_dir}")
    print("文件名保持不变，与原文件相同")

def create_batch_script():
    """创建批处理脚本（Windows/Linux/Mac）"""
    current_dir = Path.cwd()
    
    # 创建输出目录
    output_dir = current_dir / "compressed_videos"
    output_dir.mkdir(exist_ok=True)
    
    # 判断操作系统
    is_windows = sys.platform.startswith('win')
    
    if is_windows:
        # Windows 批处理脚本
        script_name = "compress_all.bat"
        script_content = f"""@echo off
echo 开始批量处理MP4文件...
echo 目标分辨率: 512x512
echo 质量设置: CRF 23
echo.
mkdir compressed_videos 2>nul

for %%f in (*.mp4) do (
    echo 处理: %%f
    ffmpeg -i "%%f" -vf scale=512:512 -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k -y "compressed_videos\\%%f"
    echo 完成: %%f
    echo.
)

echo 所有文件处理完成！
echo 文件保存在 compressed_videos 文件夹中
pause
"""
    else:
        # Linux/Mac Shell 脚本
        script_name = "compress_all.sh"
        script_content = f"""#!/bin/bash
echo "开始批量处理MP4文件..."
echo "目标分辨率: 512x512"
echo "质量设置: CRF 23"
echo ""
mkdir -p compressed_videos

for f in *.mp4; do
    if [ -f "$f" ]; then
        echo "处理: $f"
        ffmpeg -i "$f" -vf scale=512:512 -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k -y "compressed_videos/$f"
        echo "完成: $f"
        echo ""
    fi
done

echo "所有文件处理完成！"
echo "文件保存在 compressed_videos 文件夹中"
"""
    
    # 写入脚本文件
    with open(script_name, 'w', encoding='utf-8') as f:
        f.write(script_content)
    
    # 如果是 Unix 系统，添加执行权限
    if not is_windows:
        os.chmod(script_name, 0o755)
    
    print(f"已创建批处理脚本: {script_name}")
    print(f"你可以直接运行这个脚本来处理所有视频")
    
    return script_name

def main():
    """主函数"""
    
    # 检查 FFmpeg 是否安装
    if not check_ffmpeg():
        print("错误: 系统未安装 FFmpeg")
        print("\n请先安装 FFmpeg:")
        print("  Windows: 下载 https://ffmpeg.org/download.html")
        print("  Mac: brew install ffmpeg")
        print("  Linux: sudo apt install ffmpeg (Ubuntu/Debian)")
        print("         sudo yum install ffmpeg (CentOS/RHEL)")
        sys.exit(1)
    
    print("MP4视频批量处理工具 (FFmpeg版)")
    print("-" * 40)
    print("处理参数:")
    print("  • 分辨率: 512x512")
    print("  • 质量: CRF 23 (高质量)")
    print("  • 输出: compressed_videos 文件夹")
    print("  • 文件名: 保持原名不变")
    print("-" * 40)
    print("\n选择操作模式:")
    print("1. 使用 Python 脚本批量处理")
    print("2. 生成批处理脚本（可重复使用）")
    print("3. 显示单个文件的 FFmpeg 命令示例")
    
    choice = input("\n请选择 (1/2/3): ").strip()
    
    if choice == '1':
        response = input("\n是否开始批量处理? (y/n): ").strip().lower()
        if response == 'y':
            batch_compress_with_ffmpeg()
        else:
            print("已取消操作")
    
    elif choice == '2':
        script_name = create_batch_script()
        print(f"\n使用方法:")
        if sys.platform.startswith('win'):
            print(f"  双击运行 {script_name} 或在命令行输入: {script_name}")
        else:
            print(f"  在终端运行: ./{script_name}")
    
    elif choice == '3':
        print("\n单个文件处理命令示例:")
        print("-" * 40)
        print("基础命令:")
        print("ffmpeg -i input.mp4 -vf scale=512:512 -c:v libx264 -crf 23 output.mp4")
        print("\n当前配置参数说明:")
        print("  -i input.mp4        : 输入文件")
        print("  -vf scale=512:512   : 缩放到 512x512")
        print("  -c:v libx264        : 使用 H.264 编码")
        print("  -crf 23             : 高质量 (视觉无损)")
        print("  -preset medium      : 编码速度适中")
        print("  -c:a aac            : AAC 音频编码")
        print("  -b:a 128k           : 音频比特率 128kbps")
        print("\n批量处理命令:")
        print("Windows:")
        print('  for %f in (*.mp4) do ffmpeg -i "%f" -vf scale=512:512 -c:v libx264 -crf 23 "compressed_videos\\%f"')
        print("\nLinux/Mac:")
        print('  for f in *.mp4; do ffmpeg -i "$f" -vf scale=512:512 -c:v libx264 -crf 23 "compressed_videos/$f"; done')
        print("\n注意: CRF 23 是高质量设置")
    
    else:
        print("无效选择")

if __name__ == "__main__":
    main()
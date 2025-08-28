# Firebase Upload Directory

这个文件夹用于准备要上传到Firebase Storage的NPC资源。

## 文件夹结构

```
firebase_upload/
└── npcs/
    ├── config.json      # NPC配置文件（必需）
    ├── version.json     # 版本信息文件（必需）
    └── [npc_id]/       # 每个NPC的资源文件夹
        ├── avatar.jpg   # 头像图片（必需，512x512px）
        └── videos/      # 视频文件夹
            ├── happy.mp4       # 开心表情
            ├── angry.mp4       # 生气表情
            ├── confident.mp4   # 自信表情
            ├── nervous.mp4     # 紧张表情
            ├── suspicious.mp4  # 怀疑表情
            ├── surprised.mp4   # 惊讶表情
            ├── drunk.mp4       # 醉酒表情
            ├── thinking.mp4    # 思考表情
            ├── laughing.mp4    # 大笑表情
            └── crying.mp4      # 哭泣表情
```

## 准备资源

### 1. 头像要求
- 格式：JPG
- 尺寸：512x512像素
- 大小：建议小于200KB

### 2. 视频要求
- 格式：MP4 (H.264编码)
- 分辨率：720p (1280x720) 或 1080p
- 时长：3-5秒循环
- 大小：每个视频建议小于2MB

### 3. 配置文件
- 确保config.json中的ID与文件夹名称一致
- 提供所有支持语言的名称和描述

## 上传步骤

1. 将NPC资源放入对应文件夹
2. 运行上传脚本：
   ```powershell
   cd tools
   .\upload_to_firebase.ps1 -ProjectName "your-project-name"
   ```

3. 验证上传：
   - 检查Firebase Console
   - 测试访问URL

## 注意事项

- 确保所有10个表情视频都存在
- 文件名必须完全匹配（区分大小写）
- 上传前先用 `-DryRun` 参数测试

## 示例NPC

已包含示例NPC 2001 (Emma)的配置，你需要：
1. 添加avatar.jpg到2001文件夹
2. 添加10个表情视频到2001/videos文件夹
3. 运行上传脚本
# Cloud NPC Setup Guide

## 概述

本指南说明如何配置Firebase Storage来存储云端NPC资源，实现动态加载新角色。

## Firebase Storage结构

```
Firebase Storage Root/
├── npcs/
│   ├── config.json              # NPC配置文件（格式同本地npc_config.json）
│   ├── version.json             # 版本控制文件
│   └── {npc_id}/               # 每个NPC的资源文件夹
│       ├── avatar.jpg          # 头像图片
│       └── videos/             # 视频文件夹
│           ├── happy.mp4       # 开心
│           ├── angry.mp4       # 生气
│           ├── confident.mp4   # 自信
│           ├── nervous.mp4     # 紧张
│           ├── suspicious.mp4  # 怀疑
│           ├── surprised.mp4   # 惊讶
│           ├── drunk.mp4       # 醉酒
│           ├── thinking.mp4    # 思考
│           ├── laughing.mp4    # 大笑
│           └── crying.mp4      # 哭泣
```

## 设置步骤

### 1. 准备Firebase Storage

1. 在Firebase控制台创建Storage bucket
2. 设置存储规则（允许读取，限制写入）：

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 允许所有用户读取NPC资源
    match /npcs/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == 'ADMIN_UID';
    }
  }
}
```

### 2. 更新配置文件

修改 `lib/services/cloud_npc_service.dart`：

```dart
// 替换为你的Firebase项目URL
static const String _baseUrl = 'https://firebasestorage.googleapis.com/v0/b/YOUR_PROJECT.appspot.com/o';
```

### 3. 上传NPC配置

#### config.json示例

```json
{
  "npcs": {
    "2001": {
      "id": "2001",
      "names": {
        "en": "Sophia",
        "zh_TW": "索菲亞",
        "es": "Sophia",
        "pt": "Sophia",
        "id": "Sophia"
      },
      "descriptions": {
        "en": "Her eyes hold mysteries waiting to be discovered.",
        "zh_TW": "她的眼睛裡藏著等待被發現的秘密。"
      },
      "avatarPath": "cloud",
      "videosPath": "cloud",
      "personality": {
        "bluffRatio": 0.35,
        "challengeThreshold": 0.45,
        "riskAppetite": 0.4,
        "mistakeRate": 0.018,
        "tellExposure": 0.09,
        "reverseActingProb": 0.28,
        "bidPreferenceThreshold": 0.11
      },
      "drinkCapacity": 6,
      "country": "France",
      "isLocal": false,
      "cloudUrl": "npcs/2001"
    }
  }
}
```

#### version.json示例

```json
{
  "version": 2,
  "lastUpdate": "2024-01-15T10:00:00Z",
  "changes": [
    "Added new NPC: Sophia",
    "Added new NPC: Mia"
  ]
}
```

### 4. 上传NPC资源

使用Firebase CLI或控制台上传：

```bash
# 使用Firebase CLI
firebase storage:upload npcs/config.json --project YOUR_PROJECT

# 上传NPC资源
firebase storage:upload npcs/2001/avatar.jpg --project YOUR_PROJECT
firebase storage:upload npcs/2001/videos/*.mp4 --project YOUR_PROJECT
```

### 5. 资源命名规范

- 头像：`avatar.jpg` (建议尺寸: 512x512px)
- 视频：`{emotion}.mp4` (建议格式: H.264, 720p, 3-5秒)
  - 必需的情绪视频：
    - happy.mp4 - 开心
    - angry.mp4 - 生气
    - confident.mp4 - 自信
    - nervous.mp4 - 紧张
    - suspicious.mp4 - 怀疑
    - surprised.mp4 - 惊讶
    - drunk.mp4 - 醉酒
    - thinking.mp4 - 思考
    - laughing.mp4 - 大笑
    - crying.mp4 - 哭泣

## 工作原理

1. **首次启动**：应用从云端获取NPC配置列表
2. **选择NPC**：用户选择云端NPC时，自动下载所需资源
3. **缓存机制**：已下载的资源缓存在设备上，避免重复下载
4. **版本检查**：定期检查云端版本，有更新时提示用户

## 优势

- ✅ 无需更新应用即可添加新NPC
- ✅ 按需下载，节省初始包大小
- ✅ 支持A/B测试不同的NPC配置
- ✅ 可以根据地区提供不同的NPC

## 注意事项

1. **网络要求**：首次加载云端NPC需要网络连接
2. **存储空间**：每个NPC约需10-20MB存储空间
3. **流量消耗**：建议在WiFi环境下预加载
4. **兼容性**：保持config.json格式与本地版本一致

## 测试

1. 上传一个测试NPC到Firebase Storage
2. 清除应用缓存
3. 启动应用，选择云端NPC
4. 验证资源自动下载和显示

## 常见问题

**Q: 资源下载失败怎么办？**
A: 应用会自动回退到本地NPC，确保游戏可玩性

**Q: 如何更新已有的云端NPC？**
A: 更新资源文件，增加version.json中的版本号

**Q: 支持多少个云端NPC？**
A: 理论上无限制，建议控制在50个以内以优化加载速度
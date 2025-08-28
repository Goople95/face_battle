# Firebase Cloud Storage 部署完整指南

## 第一步：Firebase项目设置

### 1.1 创建或选择Firebase项目

1. 访问 [Firebase Console](https://console.firebase.google.com/)
2. 点击"创建项目"或选择现有项目
3. 项目名称建议：`face-battle-prod`

### 1.2 启用Cloud Storage

1. 在Firebase控制台左侧菜单，点击 **Storage**
2. 点击 **开始使用**
3. 选择存储位置（建议选择离用户最近的区域）：
   - 亚洲用户：`asia-northeast1` (东京)
   - 美国用户：`us-central1` (爱荷华)
4. 选择生产模式或测试模式（建议先选测试模式）

## 第二步：获取项目配置

### 2.1 获取Storage Bucket URL

1. 在Storage页面，找到你的bucket URL，格式如：
   ```
   gs://your-project-name.appspot.com
   ```

2. 转换为HTTP URL格式：
   ```
   https://firebasestorage.googleapis.com/v0/b/your-project-name.appspot.com/o
   ```

### 2.2 更新应用配置

编辑 `lib/services/cloud_npc_service.dart`：

```dart
class CloudNPCService {
  // 替换为你的实际URL
  static const String _baseUrl = 'https://firebasestorage.googleapis.com/v0/b/your-project-name.appspot.com/o';
```

## 第三步：设置Storage安全规则

### 3.1 配置安全规则

在Firebase Console > Storage > Rules，设置以下规则：

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 允许所有人读取npcs目录
    match /npcs/{allPaths=**} {
      allow read: if true;
      // 只允许认证用户上传（可选）
      allow write: if request.auth != null;
    }
    
    // 其他文件默认不允许访问
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### 3.2 发布规则

点击"发布"按钮使规则生效。

## 第四步：准备NPC资源文件

### 4.1 创建文件夹结构

在本地创建以下文件夹结构：

```
firebase_upload/
├── npcs/
│   ├── config.json          # NPC配置文件
│   ├── version.json         # 版本信息
│   └── 2001/               # 新NPC示例
│       ├── avatar.jpg      # 头像 (建议512x512px)
│       └── videos/
│           ├── happy.mp4   
│           ├── angry.mp4   
│           ├── confident.mp4
│           ├── nervous.mp4 
│           ├── suspicious.mp4
│           ├── surprised.mp4
│           ├── drunk.mp4   
│           ├── thinking.mp4
│           ├── laughing.mp4
│           └── crying.mp4 
```

### 4.2 创建config.json

创建 `firebase_upload/npcs/config.json`：

```json
{
  "npcs": {
    "2001": {
      "id": "2001",
      "names": {
        "en": "Emma",
        "zh_TW": "艾瑪",
        "es": "Emma",
        "pt": "Emma",
        "id": "Emma"
      },
      "descriptions": {
        "en": "A mysterious beauty from the cloud.",
        "zh_TW": "來自雲端的神秘美人。",
        "es": "Una belleza misteriosa de la nube.",
        "pt": "Uma beleza misteriosa da nuvem.",
        "id": "Kecantikan misterius dari awan."
      },
      "avatarPath": "cloud",
      "videosPath": "cloud",
      "isVIP": false,
      "unlocked": true,
      "personality": {
        "bluffRatio": 0.35,
        "challengeThreshold": 0.42,
        "riskAppetite": 0.45,
        "mistakeRate": 0.02,
        "tellExposure": 0.08,
        "reverseActingProb": 0.3,
        "bidPreferenceThreshold": 0.1
      },
      "drinkCapacity": 6,
      "country": "Cloud City",
      "isLocal": false,
      "version": 1
    }
  }
}
```

### 4.3 创建version.json

创建 `firebase_upload/npcs/version.json`：

```json
{
  "version": 1,
  "lastUpdate": "2024-01-20T10:00:00Z",
  "minAppVersion": "1.0.0",
  "changes": [
    "Added first cloud NPC: Emma"
  ]
}
```

## 第五步：安装Firebase CLI

### 5.1 Windows安装

```powershell
# 方法1：使用npm（需要先安装Node.js）
npm install -g firebase-tools

# 方法2：下载独立安装包
# 访问：https://firebase.google.com/docs/cli#windows
```

### 5.2 登录Firebase

```bash
firebase login
```

### 5.3 初始化项目

在 `firebase_upload` 文件夹中：

```bash
firebase init storage
# 选择你的项目
# 使用默认设置
```

## 第六步：上传文件到Storage

### 6.1 使用Firebase CLI上传（推荐）

创建上传脚本 `upload_npcs.ps1`：

```powershell
# Windows PowerShell脚本
$project = "your-project-name"

Write-Host "Uploading NPC resources to Firebase Storage..." -ForegroundColor Green

# 上传配置文件
gsutil -m cp npcs/config.json gs://$project.appspot.com/npcs/
gsutil -m cp npcs/version.json gs://$project.appspot.com/npcs/

# 上传NPC资源
gsutil -m cp -r npcs/2001 gs://$project.appspot.com/npcs/

Write-Host "Upload complete!" -ForegroundColor Green
```

运行脚本：
```powershell
.\upload_npcs.ps1
```

### 6.2 使用Firebase Console手动上传

1. 打开Firebase Console > Storage
2. 创建 `npcs` 文件夹
3. 上传 `config.json` 和 `version.json`
4. 创建 `2001` 子文件夹
5. 上传 `avatar.jpg`
6. 创建 `2001/videos` 子文件夹
7. 上传所有视频文件

### 6.3 使用Node.js脚本上传

创建 `upload.js`：

```javascript
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// 初始化Admin SDK
const serviceAccount = require('./service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'your-project-name.appspot.com'
});

const bucket = admin.storage().bucket();

async function uploadFile(localPath, remotePath) {
  console.log(`Uploading ${localPath} to ${remotePath}`);
  await bucket.upload(localPath, {
    destination: remotePath,
    metadata: {
      cacheControl: 'public, max-age=3600',
    }
  });
}

async function uploadNPCResources() {
  // 上传配置文件
  await uploadFile('./npcs/config.json', 'npcs/config.json');
  await uploadFile('./npcs/version.json', 'npcs/version.json');
  
  // 上传NPC 2001资源
  await uploadFile('./npcs/2001/avatar.jpg', 'npcs/2001/avatar.jpg');
  
  // 上传视频文件
  const videos = ['happy', 'angry', 'confident', 'nervous', 'suspicious', 
                  'surprised', 'drunk', 'thinking', 'laughing', 'crying'];
  
  for (const video of videos) {
    await uploadFile(
      `./npcs/2001/videos/${video}.mp4`,
      `npcs/2001/videos/${video}.mp4`
    );
  }
  
  console.log('Upload complete!');
}

uploadNPCResources().catch(console.error);
```

运行：
```bash
npm install firebase-admin
node upload.js
```

## 第七步：验证部署

### 7.1 检查文件是否上传成功

在Firebase Console > Storage中查看文件结构：

```
npcs/
  ├── config.json
  ├── version.json
  └── 2001/
      ├── avatar.jpg
      └── videos/
          ├── happy.mp4
          └── ...
```

### 7.2 测试文件访问

构造测试URL：
```
https://firebasestorage.googleapis.com/v0/b/your-project-name.appspot.com/o/npcs%2Fconfig.json?alt=media
```

在浏览器中访问，应该能看到JSON内容。

### 7.3 在应用中测试

1. 更新 `lib/services/cloud_npc_service.dart` 中的URL
2. 运行应用
3. 查看是否能获取到云端NPC配置

## 第八步：优化设置

### 8.1 设置CORS（如果需要Web访问）

创建 `cors.json`：

```json
[
  {
    "origin": ["*"],
    "method": ["GET"],
    "maxAgeSeconds": 3600
  }
]
```

应用CORS设置：
```bash
gsutil cors set cors.json gs://your-project-name.appspot.com
```

### 8.2 设置缓存策略

更新文件元数据以优化缓存：

```bash
# 设置长期缓存（适用于不常变的资源）
gsutil -m setmeta -h "Cache-Control:public, max-age=31536000" gs://your-project-name.appspot.com/npcs/2001/**

# 设置短期缓存（适用于配置文件）
gsutil setmeta -h "Cache-Control:public, max-age=3600" gs://your-project-name.appspot.com/npcs/config.json
```

## 故障排除

### 问题1：403 Forbidden错误

**解决方案**：
1. 检查Storage安全规则是否正确
2. 确认文件路径正确
3. 检查项目配置是否正确

### 问题2：文件下载很慢

**解决方案**：
1. 选择离用户更近的Storage位置
2. 启用CDN（Firebase Hosting）
3. 压缩视频文件大小

### 问题3：应用无法获取配置

**解决方案**：
1. 检查URL格式是否正确
2. 确认网络连接正常
3. 查看应用日志中的错误信息

## 成本估算

Firebase Storage定价（免费层）：
- 存储：5GB免费
- 下载：1GB/天免费
- 操作：20K/天免费

对于100个用户，每个下载20MB资源：
- 每日流量：2GB
- 建议购买Blaze计划以避免限制

## 下一步

1. ✅ 完成基础部署
2. 📝 添加更多NPC资源
3. 📊 监控使用情况
4. 🚀 优化加载性能
5. 💰 评估成本并优化

---

需要帮助？查看 [Firebase Storage文档](https://firebase.google.com/docs/storage)
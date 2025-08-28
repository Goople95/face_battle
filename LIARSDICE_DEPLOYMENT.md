# LiarsDice Firebase Storage 部署步骤

## ✅ 已完成
- Firebase项目：`LiarsDice` 
- Storage Bucket：`liarsdice-fd930.firebasestorage.app`
- 付费账号：已绑定

## 🚀 接下来的步骤

### 步骤1：设置Storage安全规则

1. 在Firebase Console，点击顶部的 **规则** 标签
2. 替换为以下规则：

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 允许所有用户读取npcs文件夹
    match /npcs/{allPaths=**} {
      allow read: if true;
      // 只允许管理员写入（可选，用于后台上传）
      allow write: if request.auth != null && request.auth.uid == 'YOUR_ADMIN_UID';
    }
    
    // 其他路径禁止访问
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

3. 点击 **发布** 按钮

### 步骤2：创建文件夹结构

在Storage页面：

1. 点击 **上传文件** 按钮旁边的文件夹图标
2. 创建文件夹名：`npcs`
3. 进入npcs文件夹

### 步骤3：上传配置文件

#### 方法A：Web界面上传（推荐首次使用）

1. 在 `npcs` 文件夹中，上传这两个文件：
   - `firebase_upload/npcs/config.json`
   - `firebase_upload/npcs/version.json`

2. 创建NPC资源文件夹：
   - 点击创建文件夹：`2001`
   - 进入2001文件夹
   - 上传 `avatar.jpg`（你需要准备一个512x512的头像图片）
   
3. 在2001文件夹中创建 `videos` 子文件夹
4. 上传10个表情视频（每个3-5秒）：
   ```
   happy.mp4      - 开心
   angry.mp4      - 生气  
   confident.mp4  - 自信
   nervous.mp4    - 紧张
   suspicious.mp4 - 怀疑
   surprised.mp4  - 惊讶
   drunk.mp4      - 醉酒
   thinking.mp4   - 思考
   laughing.mp4   - 大笑
   crying.mp4     - 哭泣
   ```

#### 方法B：命令行批量上传

1. 安装Google Cloud SDK（如果还没安装）：
   - 下载：https://cloud.google.com/sdk/docs/install
   - 安装后运行：`gcloud init`
   - 选择项目：`liarsdice-fd930`

2. 准备资源文件：
   ```
   face_battle/firebase_upload/npcs/
   ├── config.json
   ├── version.json
   └── 2001/
       ├── avatar.jpg
       └── videos/
           └── (10个mp4文件)
   ```

3. 运行上传脚本：
   ```powershell
   cd D:\projects\CompeteWithAI\face_battle
   .\tools\upload_to_firebase.ps1
   ```

   或者手动上传：
   ```bash
   # 上传配置文件
   gsutil cp firebase_upload/npcs/config.json gs://liarsdice-fd930.appspot.com/npcs/
   gsutil cp firebase_upload/npcs/version.json gs://liarsdice-fd930.appspot.com/npcs/
   
   # 上传NPC资源
   gsutil -m cp -r firebase_upload/npcs/2001 gs://liarsdice-fd930.appspot.com/npcs/
   ```

### 步骤4：验证上传

1. 测试配置文件访问：
   ```
   https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.appspot.com/o/npcs%2Fconfig.json?alt=media
   ```
   
2. 测试头像访问：
   ```
   https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.appspot.com/o/npcs%2F2001%2Favatar.jpg?alt=media
   ```

### 步骤5：测试应用

1. 运行Flutter应用：
   ```powershell
   .\flutter_run_log.ps1
   ```

2. 观察日志，应该看到：
   ```
   从云端获取NPC配置...
   ```

3. 如果配置加载成功，新的云端NPC会出现在选择列表中

## 📁 最终的Storage结构

```
Storage Root (liarsdice-fd930.firebasestorage.app)
└── npcs/
    ├── config.json       # NPC配置列表
    ├── version.json      # 版本信息
    └── 2001/            # Emma (示例NPC)
        ├── avatar.jpg
        └── videos/
            ├── happy.mp4
            ├── angry.mp4
            ├── confident.mp4
            ├── nervous.mp4
            ├── suspicious.mp4
            ├── surprised.mp4
            ├── drunk.mp4
            ├── thinking.mp4
            ├── laughing.mp4
            └── crying.mp4
```

## 🎨 资源准备提示

如果你还没有NPC资源，可以：

1. **头像**：使用AI生成工具（如Midjourney、Stable Diffusion）
   - 提示词：`beautiful woman portrait, game character, anime style`
   - 尺寸：512x512px
   - 格式：JPG

2. **视频**：可以用现有NPC的视频作为模板
   - 复制 `assets/people/0001/videos/` 中的视频
   - 或使用视频编辑工具创建3-5秒的循环动画

## ⚠️ 注意事项

1. **文件命名**：必须完全匹配（区分大小写）
2. **文件大小**：建议每个视频小于2MB
3. **网络**：首次加载需要良好的网络连接
4. **缓存**：已下载的NPC会缓存在设备上

## 🔧 故障排除

### 问题：403 Forbidden
- 检查Storage Rules是否已发布
- 确认文件路径正确

### 问题：找不到配置
- 检查URL中的项目名是否正确
- 确认config.json已上传到npcs文件夹

### 问题：视频无法播放
- 确保视频格式为MP4 (H.264编码)
- 检查文件名是否完全匹配

## 📊 监控使用情况

在Firebase Console可以查看：
- Storage使用量
- 下载带宽
- 请求次数

## 🎉 完成

配置完成后，你的应用就支持云端NPC了！用户选择云端NPC时会自动下载并缓存。
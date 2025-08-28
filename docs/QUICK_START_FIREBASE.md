# Firebase Storage 快速部署指南

## 前置要求

- [ ] Google账号
- [ ] Firebase项目（如果没有，下面会创建）
- [ ] NPC资源文件（头像+10个视频）

## 5分钟快速部署

### 步骤1：创建Firebase项目

1. 打开 https://console.firebase.google.com/
2. 点击"添加项目"
3. 输入项目名称：`face-battle-prod`
4. 关闭Google Analytics（可选）
5. 点击"创建项目"

### 步骤2：启用Storage

1. 左侧菜单点击 **Storage**
2. 点击"开始使用"
3. 选择"以测试模式启动"（先测试，后面再改安全规则）
4. 选择位置：`asia-northeast1`（亚洲）或 `us-central1`（美国）
5. 点击"完成"

### 步骤3：获取项目信息

在Storage页面，你会看到类似这样的URL：
```
gs://face-battle-prod.appspot.com
```

记下项目ID（例如：`face-battle-prod`）

### 步骤4：更新应用代码

打开 `lib/services/cloud_npc_service.dart`，修改第12行：

```dart
// 将 YOUR_PROJECT 替换为你的项目ID
static const String _baseUrl = 'https://firebasestorage.googleapis.com/v0/b/face-battle-prod.appspot.com/o';
```

### 步骤5：上传文件（最简单方法）

#### 方法A：使用Web界面（推荐新手）

1. 在Firebase Console > Storage页面
2. 点击"上传文件"按钮旁边的"新建文件夹"
3. 创建文件夹：`npcs`
4. 进入npcs文件夹
5. 上传这两个文件：
   - `firebase_upload/npcs/config.json`
   - `firebase_upload/npcs/version.json`

6. 在npcs文件夹中，创建子文件夹：`2001`
7. 进入2001文件夹，上传：
   - `avatar.jpg`（你的NPC头像）
   
8. 在2001文件夹中，创建子文件夹：`videos`
9. 进入videos文件夹，上传10个视频文件：
   - happy.mp4
   - angry.mp4
   - confident.mp4
   - nervous.mp4
   - suspicious.mp4
   - surprised.mp4
   - drunk.mp4
   - thinking.mp4
   - laughing.mp4
   - crying.mp4

#### 方法B：使用命令行（适合批量上传）

1. 安装 [gcloud CLI](https://cloud.google.com/sdk/docs/install)
2. 登录：
   ```bash
   gcloud auth login
   ```
3. 运行上传脚本：
   ```powershell
   cd tools
   .\upload_to_firebase.ps1 -ProjectName "face-battle-prod"
   ```

### 步骤6：设置访问权限

在Firebase Console > Storage > Rules，替换为：

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 允许所有人读取npcs文件夹
    match /npcs/{allPaths=**} {
      allow read: if true;
      allow write: if false;  // 禁止写入
    }
  }
}
```

点击"发布"。

### 步骤7：测试

1. 构造测试URL（替换项目名）：
   ```
   https://firebasestorage.googleapis.com/v0/b/face-battle-prod.appspot.com/o/npcs%2Fconfig.json?alt=media
   ```

2. 在浏览器访问，应该看到JSON内容

3. 运行Flutter应用，新NPC应该会出现在列表中

## 常见问题

### Q: 上传的文件在哪里？
A: Firebase Console > Storage，可以看到文件树结构

### Q: 如何知道URL格式？
A: 点击任何文件，在右侧详情面板可以看到"下载URL"

### Q: 403错误？
A: 检查Security Rules是否设置为允许读取

### Q: 文件找不到？
A: 检查路径是否正确，注意大小写

### Q: 如何添加更多NPC？

1. 在config.json中添加新NPC配置：
```json
"2002": {
  "id": "2002",
  "names": {...},
  // ... 其他配置
}
```

2. 上传对应的资源文件到 `npcs/2002/` 文件夹

## 成本

Firebase免费层限制：
- 存储：5GB
- 下载：1GB/天
- 操作：20,000次/天

一个NPC约15MB，免费层可存储300+个NPC。

## 完成！

现在你的应用支持云端NPC了。用户选择云端NPC时会自动下载资源。

需要帮助？
- 查看详细文档：`docs/FIREBASE_STORAGE_DEPLOYMENT.md`
- Firebase官方文档：https://firebase.google.com/docs/storage
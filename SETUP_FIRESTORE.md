# 🔥 Firestore数据库设置指南

## 紧急修复步骤

### 1. 启用Firestore API（必须立即完成）

#### 方法A：通过Firebase控制台（推荐）
1. 访问 [Firebase Console](https://console.firebase.google.com/)
2. 选择您的项目 `liarsdice-fd930`
3. 左侧菜单选择 **Firestore Database**
4. 点击 **"创建数据库"** 按钮
5. 选择模式：
   - **测试模式**（推荐用于开发，30天内所有人可读写）
   - 生产模式（需要配置安全规则）
6. 选择地区：建议选择 `asia-east1`（台湾）或 `asia-northeast1`（东京）
7. 点击"启用"

#### 方法B：通过Google Cloud Console
1. 直接访问：https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=liarsdice-fd930
2. 点击 **"启用"** 按钮
3. 等待几分钟让更改生效

### 2. 配置Firestore安全规则

在Firebase控制台 → Firestore Database → 规则，设置以下规则：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用户只能读写自己的数据
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 排行榜所有人可读（读取用户文档的winRate字段）
    match /users/{userId} {
      allow read: if resource.data.keys().hasAny(['winRate', 'totalWins', 'totalGames']);
    }
  }
}
```

### 3. 初始化Firestore索引

在Firebase控制台 → Firestore Database → 索引，添加复合索引：

1. **排行榜索引**：
   - 集合：`users`
   - 字段：`winRate` (降序)
   - 查询范围：集合

## 常见错误解决

### 错误：PERMISSION_DENIED
- **原因**：Firestore API未启用
- **解决**：按照上述步骤1启用API

### 错误：The service is currently unavailable
- **原因**：首次启用需要时间生效
- **解决**：等待2-3分钟后重试

### 错误：Missing or insufficient permissions
- **原因**：安全规则配置错误
- **解决**：检查Firestore安全规则

## 验证步骤

1. 启用Firestore后，在Firebase控制台应该能看到Firestore Database页面
2. 运行应用，登录后检查Firestore中是否创建了用户数据
3. 数据结构应该是单个文档：`users/{userId}`，包含所有profile和progress字段

## 注意事项

- **测试模式有效期**：30天后需要更新安全规则
- **计费**：Firestore有免费配额（每天5万次读取，2万次写入）
- **地区选择**：一旦选择无法更改，建议选择离用户最近的地区

## 快速测试

启用Firestore后，运行以下命令测试：
```bash
flutter clean
flutter pub get
flutter run
```

登录后应该能在Firestore控制台看到自动创建的用户数据。
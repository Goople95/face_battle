# Firestore 配置指南

## 问题说明
当前遇到的错误 `PERMISSION_DENIED` 是因为Firestore的安全规则没有配置，默认规则不允许任何读写操作。

## 解决步骤

### 1. 登录Firebase控制台
1. 访问 https://console.firebase.google.com/
2. 选择您的项目

### 2. 更新Firestore安全规则
1. 在左侧菜单中选择 **Firestore Database**
2. 点击顶部的 **规则(Rules)** 标签
3. 将现有规则替换为以下内容：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用户只能访问自己的数据
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }
    
    // users集合 - 用户档案（只存云端）
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow write: if isOwner(userId);
    }
    
    // gameProgress集合 - 游戏进度（本地为主，云端备份）
    match /gameProgress/{userId} {
      allow read: if isOwner(userId);
      allow write: if isOwner(userId);
    }
    
    // npcConfigs集合 - NPC配置（公开读取）
    match /npcConfigs/{document=**} {
      allow read: if true;
      allow write: if false; // 只能通过控制台修改
    }
    
    // 其他集合的规则...
    match /gameHistory/{userId}/games/{gameId} {
      allow read: if isOwner(userId);
      allow write: if isOwner(userId);
    }
  }
}
```

4. 点击 **发布(Publish)** 按钮保存规则

### 3. 验证规则是否生效
1. 规则发布后会立即生效
2. 重新运行应用测试同步功能

## 安全规则说明

### 数据访问权限设计
- **users集合**：每个用户只能读写自己的用户档案
- **gameProgress集合**：每个用户只能读写自己的游戏进度
- **npcConfigs集合**：所有人都可以读取，但只能通过控制台修改

### 关键函数
- `isOwner(userId)`：检查当前请求用户是否是数据的所有者
- `request.auth.uid`：获取当前认证用户的ID

## 开发环境临时规则（不推荐用于生产）

如果您只是在开发测试阶段，可以使用以下更宽松的规则：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 警告：仅用于开发测试！
    // 允许所有已认证用户读写所有数据
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**注意**：上述规则仅用于开发测试，生产环境必须使用严格的安全规则！

## 故障排查

### 如果仍然出现权限错误
1. 确认用户已经成功登录（检查日志中是否有用户ID）
2. 确认规则已经发布生效
3. 检查集合名称是否正确（区分大小写）
4. 在Firebase控制台的Firestore中手动创建集合测试

### 常见错误
- `PERMISSION_DENIED`：权限不足，检查安全规则
- `NOT_FOUND`：集合或文档不存在，会自动创建
- `UNAUTHENTICATED`：用户未登录

## 相关文档
- [Firestore安全规则官方文档](https://firebase.google.com/docs/firestore/security/get-started)
- [规则语言参考](https://firebase.google.com/docs/firestore/security/rules-structure)
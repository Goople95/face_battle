# Facebook 登录权限说明

## 当前权限配置

### ✅ 已启用权限
- **public_profile**：获取用户的公开资料（名字、ID、头像等）
  - 状态：默认可用，无需审核
  - 包含信息：name, first_name, last_name, id, picture

### ❌ 需要审核的权限
- **email**：获取用户的电子邮件地址
  - 状态：需要 Facebook 应用审核
  - 当前：已从代码中移除，避免报错

## 权限审核流程（如需要 email）

### 1. 开发测试阶段
- 添加**测试用户**或**开发者账号**可以使用 email 权限
- 步骤：
  1. 进入 Facebook 开发者控制台
  2. 应用设置 > 角色 > 测试用户
  3. 添加测试账号
  4. 这些账号可以使用所有权限，包括 email

### 2. 正式发布前
如需要 email 权限，需要提交应用审核：
1. 进入 Facebook 开发者控制台
2. 应用审核 > 权限和功能
3. 申请 email 权限
4. 提供使用场景说明
5. 录制演示视频
6. 等待 Facebook 审核（通常 5-7 天）

## 当前解决方案

### 不使用 Email 的替代方案
1. **使用 Facebook ID 作为唯一标识**
   - 每个 Facebook 用户都有唯一的 ID
   - Firebase Auth 会自动创建对应的 UID
   - 无需 email 也能正常工作

2. **显示名称使用 Facebook 名字**
   - public_profile 权限包含用户名字
   - 可以正常显示用户信息

## 代码已更新

```dart
// 之前（会报错）
permissions: ['email', 'public_profile']

// 现在（正常工作）
permissions: ['public_profile']
```

## 测试步骤

1. **清理并重新运行**
```bash
flutter clean
flutter pub get
flutter run
```

2. **测试 Facebook 登录**
- 点击"使用 Facebook 账号登录"
- 应该能正常弹出 Facebook 登录界面
- 登录后返回应用

## 常见问题

### Q: 为什么不能获取 email？
A: email 权限需要 Facebook 应用审核，未审核的应用只能使用基础权限。

### Q: 如何在开发阶段测试 email 权限？
A: 
1. 将你的 Facebook 账号添加为应用的开发者或测试用户
2. 在代码中添加 email 权限
3. 只有开发者和测试用户可以使用

### Q: 用户数据如何区分？
A: 
- 每个 Facebook 用户有唯一的 Facebook ID
- Firebase Auth 会为每个用户生成唯一的 UID
- 本地存储按 UID 隔离，无需 email 也能正常工作

## 未来优化

如果需要 email（用于发送通知等）：
1. 提交应用审核申请 email 权限
2. 或在用户首次登录后，提示补充 email 信息
3. 或使用 Firebase Auth 的匿名邮箱功能
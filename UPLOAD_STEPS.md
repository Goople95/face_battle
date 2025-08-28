# 📸 Firebase Storage Web界面上传步骤（带截图说明）

## 步骤1：进入Storage页面
你已经在这里了 ✅

## 步骤2：创建npcs文件夹

1. 点击右上角蓝色的 **"上传文件"** 按钮旁边的 **文件夹图标** 📁
2. 在弹出框中输入：`npcs`
3. 点击 **"创建文件夹"**

## 步骤3：进入npcs文件夹

点击刚创建的 `npcs` 文件夹进入

## 步骤4：上传配置文件

1. 现在你应该在 `gs://liarsdice-fd930.appspot.com/npcs` 路径下
2. 点击 **"上传文件"** 按钮
3. 在文件选择器中，导航到：
   ```
   D:\projects\CompeteWithAI\face_battle\firebase_upload\npcs\
   ```
4. 选择这两个文件（按住Ctrl可多选）：
   - `config.json`
   - `version.json`
5. 点击 **"打开"**
6. 等待上传完成（会显示进度）

## 步骤5：验证文件

上传完成后，你应该看到：
```
📁 npcs/
   📄 config.json
   📄 version.json
```

## 步骤6：测试访问

在浏览器新标签页访问：
```
https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.appspot.com/o/npcs%2Fconfig.json?alt=media
```

应该看到JSON内容而不是404错误！

## 步骤7：（可选）上传测试NPC资源

如果要添加云端NPC：

1. 在npcs文件夹中，创建子文件夹：`2001`
2. 进入2001文件夹
3. 上传：
   - `avatar.jpg`（需要你准备一个512x512的图片）
   - 创建`videos`子文件夹
   - 上传10个表情视频

## 🎯 快速测试

只上传config.json和version.json就够了！应用会识别到现有的本地NPC（0001, 0002等）。

## ⚠️ 常见问题

### 文件没有显示？
- 刷新页面
- 检查是否在正确的文件夹路径

### 仍然404？
- 确认文件名完全匹配（区分大小写）
- 确认URL中的路径正确
- 等待几秒让Firebase处理

### 权限错误？
- 检查Storage Rules是否已设置为允许读取

## 📝 文件内容检查

`config.json` 应该包含：
```json
{
  "npcs": {
    "0001": { ... },
    "0002": { ... }
  }
}
```

`version.json` 应该包含：
```json
{
  "version": 1,
  "lastUpdate": "2024-01-20T10:00:00Z"
}
```

---

💡 **提示**：先只上传这两个JSON文件测试，确认工作后再上传NPC资源！
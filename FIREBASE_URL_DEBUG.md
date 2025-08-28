# Firebase Storage URL调试

## 问题诊断

文件已上传但URL返回404，可能的原因：

### 1. 确认文件路径
在Firebase Console中，请确认：
- 文件确实在 `npcs/npc_config.json` 路径下
- 不是在 `npcs/npc-config.json`（注意是下划线还是横线）
- 文件名大小写正确

### 2. 直接从Console获取URL
请在Firebase Console中：
1. 点击 `npc_config.json` 文件
2. 在右侧面板，应该有一个"下载URL"部分
3. 那里会显示完整的URL，类似：
   ```
   https://firebasestorage.googleapis.com/...
   ```
4. **直接复制这个完整的URL给我**

### 3. 测试其他文件
试试访问其他文件，看是否有同样问题：
1. 点击 `0001` 文件夹
2. 点击 `1.png` 文件
3. 获取它的下载URL
4. 在浏览器中测试是否能打开

### 4. 可能的URL格式

Firebase Storage可能使用不同的URL格式：

**格式1**（标准）：
```
https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.appspot.com/o/npcs%2Fnpc_config.json?alt=media&token=xxx
```

**格式2**（备用）：
```
https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/npcs%2Fnpc_config.json?alt=media&token=xxx
```

### 需要确认的信息

1. **Storage bucket名称**：
   - 是 `liarsdice-fd930.appspot.com` 
   - 还是 `liarsdice-fd930.firebasestorage.app`？

2. **文件的确切路径**：
   - 是 `npcs/npc_config.json`
   - 还是其他？

3. **完整的下载URL**：
   - 请从Firebase Console直接复制

## 临时解决方案

如果公开URL有问题，可以：

1. **重新上传文件**
   - 删除现有的 `npc_config.json`
   - 重新上传
   - 创建新的访问令牌

2. **检查Storage位置**
   - 确认Storage的区域设置
   - 可能影响URL格式

3. **使用Firebase SDK**
   - 在应用中使用Firebase SDK直接访问
   - 而不是通过HTTP URL

请提供Console中显示的完整下载URL，我来帮你解决这个问题。
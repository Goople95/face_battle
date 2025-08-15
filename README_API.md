# 配置Gemini API

## 步骤

1. **获取API密钥**
   - 访问 https://aistudio.google.com/
   - 点击"Get API key"
   - 创建或选择项目
   - 复制生成的API密钥

2. **配置项目**
   - 打开 `lib/config/api_config.dart`
   - 将 `YOUR_API_KEY_HERE` 替换为你的实际API密钥
   - 将 `useRealAI` 设置为 `true` 以启用AI功能

3. **安装依赖**
   ```bash
   flutter pub get
   ```

4. **运行项目**
   ```bash
   flutter run
   ```

## 注意事项

- **保密性**：永远不要将包含真实API密钥的文件提交到Git
- **免费额度**：Gemini API提供每分钟60次免费调用
- **降级方案**：如果API调用失败，系统会自动使用本地算法

## 切换AI模式

在 `lib/config/api_config.dart` 中：
- `useRealAI = true`：使用Gemini AI（需要配置API密钥）
- `useRealAI = false`：使用本地算法（无需API密钥）
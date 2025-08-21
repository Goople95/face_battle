# Dice Girls 🎲

<div align="center">
  <img src="assets/logo.png" alt="Dice Girls Logo" width="200" height="200">
  
  **一款结合AI表情识别与骗子骰子玩法的Flutter游戏**
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.0+-blue)](https://dart.dev)
  [![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
</div>

## 📖 游戏介绍

Face Battle（表情博弈）是一款创新的骗子骰子（Liar's Dice）游戏，融合了动态表情系统和AI对战。玩家与不同性格的AI角色进行心理博弈，通过观察对手的表情变化来判断其是否在虚张声势。

### 🎮 游戏特色

- **智能AI对手**：4种不同性格的AI角色，各有独特的游戏风格和表情反应
- **动态表情系统**：AI会根据游戏局势展现不同的面部表情
- **心理博弈**：通过观察对手的微表情判断其是否在虚张声势
- **双重AI系统**：Gemini AI云端决策 + 本地算法降级方案
- **饮酒惩罚机制**：输家需要喝酒，醉酒状态影响游戏体验

## 🚀 快速开始

### 环境要求

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / VS Code
- Android 5.0+ / iOS 12.0+

### 安装步骤

1. **克隆仓库**
```bash
git clone https://github.com/yourusername/face_battle.git
cd face_battle
```

2. **安装依赖**
```bash
flutter pub get
```

3. **配置API密钥**（可选，启用云端AI）
```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String geminiApiKey = 'YOUR_API_KEY_HERE';
  static const bool useRealAI = true;
}
```
> 获取Gemini API密钥：https://aistudio.google.com/

4. **运行游戏**
```bash
flutter run
```

## 🎯 游戏规则

### 基础规则
- 双方各有5个骰子（1-6点）
- 点数1是万能牌，可当作任何点数（除非已被叫过）
- 轮流叫牌，必须比前一个叫牌更高
- 可以选择质疑对方，猜对则对方喝酒，猜错则自己喝酒

### 叫牌规则
- 增加数量：3个4 → 4个4
- 提高点数：3个4 → 3个5  
- 点数顺序：2 < 3 < 4 < 5 < 6 < 1

### 胜负判定
- 质疑成功：对方实际骰子数少于其叫牌数
- 质疑失败：对方实际骰子数达到或超过叫牌数
- 输家喝酒，累计3杯进入醉酒状态

## 🤖 AI系统架构

### 双层决策系统

```
本地计算引擎 → 生成所有选项和概率 → Gemini AI根据性格选择 → 表情和对话生成
```

### AI性格特征

| 角色 | 性格特点 | 游戏风格 |
|------|---------|----------|
| 🎭 心机御姐 | 狡猾、善于虚张 | 高虚张倾向，适度质疑 |
| 🔥 冲动小哥 | 激进、爱冒险 | 经常冒险，容易冲动 |
| 👨‍🏫 理性教授 | 保守、重分析 | 很少虚张，理性决策 |
| 🌸 活泼少女 | 活泼、偶尔调皮 | 平衡型，偶尔意外 |

## 🎨 技术栈

- **前端框架**：Flutter 3.0+
- **状态管理**：Provider
- **AI服务**：Google Gemini API
- **动画系统**：Flutter Animation API + Rive
- **持久化**：SharedPreferences
- **日志系统**：Logger

## 📂 项目结构

```
face_battle/
├── lib/
│   ├── models/          # 数据模型
│   ├── screens/         # 游戏界面
│   ├── services/        # AI和游戏服务
│   ├── widgets/         # UI组件
│   ├── utils/           # 工具类
│   └── config/          # 配置文件
├── assets/
│   ├── images/          # 图片资源
│   ├── people/          # AI角色资源
│   └── sounds/          # 音效文件
└── test/                # 测试文件
```

## 🔧 开发命令

```bash
# 运行调试模式
flutter run

# 构建APK
flutter build apk --release

# 运行测试
flutter test

# 代码格式化
dart format .

# 代码分析
flutter analyze
```

## 📝 开发日志

- **v1.0.0** - 初始版本发布
  - 实现基础游戏逻辑
  - 集成Gemini AI
  - 添加4个AI角色
  - 实现动态表情系统

## 🤝 贡献指南

欢迎提交Issue和Pull Request！

1. Fork本仓库
2. 创建Feature分支：`git checkout -b feature/AmazingFeature`
3. 提交更改：`git commit -m 'Add some AmazingFeature'`
4. 推送到分支：`git push origin feature/AmazingFeature`
5. 提交Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 👥 作者

- **Your Name** - *Initial work* - [GitHub](https://github.com/yourusername)

## 🙏 致谢

- Google Gemini Team - AI服务支持
- Flutter Team - 优秀的跨平台框架
- 所有贡献者和测试者

---

<div align="center">
  Made with ❤️ using Flutter
</div>

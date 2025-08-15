# AI表情动画实现指南

## 当前实现

目前使用`CustomPainter`绘制了动态表情，支持：
- 😐 neutral - 中性
- 😄 happy - 开心（弯月眼+微笑+红晕）
- 😎 confident - 自信（斜嘴笑）
- 😏 smirk - 得意
- 😰 nervous - 紧张（波浪嘴+汗滴）
- 😟 worried - 担心
- 🤔 thinking - 思考（一只眼睛眯着）
- 🤩 excited - 兴奋（星星眼）
- 😡 angry - 生气（怒眉）

## 升级到Rive动画

### 为什么选择Rive？
1. **专业效果**：平滑的骨骼动画
2. **小文件**：矢量动画，文件极小
3. **状态机**：支持复杂的状态转换
4. **实时控制**：可以用代码控制参数

### 创建步骤

#### 1. 注册Rive账号
访问 https://rive.app 注册免费账号

#### 2. 创建AI角色
在Rive编辑器中创建一个角色：
- 基础形状：圆形脸
- 眼睛：支持多种状态（睁开、眯眼、弯月、星星眼）
- 嘴巴：支持多种曲线（微笑、沮丧、波浪、O形）
- 额外元素：汗滴、红晕、怒气符号

#### 3. 设置状态机
创建名为`EmotionStateMachine`的状态机：

**输入参数**：
- `valence` (Number, -1到1) - 情绪效价
- `arousal` (Number, 0到1) - 情绪唤醒度
- `blink` (Trigger) - 眨眼触发
- `talk` (Trigger) - 说话触发

**状态**：
- Idle - 待机状态
- Happy - 开心
- Sad - 难过
- Angry - 生气
- Thinking - 思考
- Nervous - 紧张

**转换条件**：
```
If valence > 0.5 && arousal > 0.5 → Happy
If valence < -0.5 && arousal > 0.5 → Angry
If valence < -0.5 && arousal < 0.5 → Sad
If valence ≈ 0 && arousal > 0.7 → Nervous
```

#### 4. 添加动画细节

**眨眼动画**（自动循环）：
- 每3-5秒眨眼一次
- 持续时间：0.2秒

**呼吸动画**（持续）：
- 轻微的缩放：0.98-1.02
- 周期：2秒

**说话动画**（触发时）：
- 嘴巴开合
- 持续时间：根据对话长度

#### 5. 导出并集成

1. 导出为`.riv`文件
2. 放入`assets/rive/ai_face.riv`
3. 在`pubspec.yaml`添加：
```yaml
flutter:
  assets:
    - assets/rive/
```

#### 6. 代码集成
组件已准备好，只需要：
1. 将`_useCustomPainter`设为`false`
2. Rive会自动加载并显示动画

## 高级功能

### 1. 微表情
添加细微的表情变化：
- 嘴角轻微抽动
- 眼神飘移
- 眉毛微动

### 2. 个性化
为不同AI个性创建不同的基础表情：
- 教授：戴眼镜
- 赌徒：牛仔帽
- 挑衅者：邪魅笑容

### 3. 过渡动画
状态之间的平滑过渡：
- 从开心到生气：先变中性，再变生气
- 使用缓动函数

### 4. 粒子效果
添加情绪粒子：
- 开心时：爱心飘出
- 生气时：蒸汽冒出
- 思考时：问号浮现

## Live2D替代方案

如果想要更逼真的效果，可以考虑Live2D：

### 优点
- 极其逼真的2D动画
- 支持物理模拟（头发、衣服）
- 大量免费模型

### 实现步骤
1. 下载Live2D Cubism SDK
2. 使用Flutter插件：`flutter_live2d`
3. 导入模型文件（.model3.json）
4. 控制参数：
```dart
live2dController.setParameter('ParamEyeLOpen', 0.5);
live2dController.setParameter('ParamMouthOpenY', 0.8);
```

## 资源推荐

### 免费动画资源
- **Rive社区**：https://rive.app/community
- **LottieFiles**：https://lottiefiles.com
- **Mixamo**：3D动画（可转2D）

### 学习资源
- Rive官方教程：https://rive.app/learn
- Flutter动画课程：https://flutter.dev/docs/development/ui/animations

## 性能优化

1. **缓存动画状态**：避免频繁重建
2. **使用RepaintBoundary**：隔离重绘区域
3. **限制帧率**：30fps足够流畅
4. **预加载资源**：游戏开始时加载所有动画

## 测试建议

1. 在不同设备测试性能
2. 确保动画不会阻塞主线程
3. 测试所有表情转换
4. 验证与AI情绪同步
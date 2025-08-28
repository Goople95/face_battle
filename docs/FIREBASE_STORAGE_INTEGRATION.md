# Firebase Storage 集成指南

## 已完成的配置

### 1. Firebase Storage 设置
- **项目**: liarsdice-fd930
- **存储桶**: gs://liarsdice-fd930.firebaseastorage.app
- **计费方案**: Blaze (按需付费)

### 2. 已上传的NPC资源结构
```
npcs/
├── 0001/           # 第一个NPC角色
│   ├── 1.png       # 角色头像
│   ├── confident.mp4
│   ├── drunk.mp4
│   ├── happy.mp4
│   ├── suspicious.mp4
│   ├── thinking.mp4
│   └── dialogue_0001.json  # 对话配置
├── 0002/           # 第二个NPC角色
│   ├── 1.png
│   ├── confident.mp4
│   ├── drunk.mp4
│   ├── happy.mp4
│   ├── suspicious.mp4
│   ├── thinking.mp4
│   └── dialogue_0002.json
├── 1001/           # 第三个NPC角色
│   ├── 1.png
│   ├── confident.mp4
│   ├── drunk.mp4
│   ├── happy.mp4
│   ├── suspicious.mp4
│   ├── thinking.mp4
│   └── dialogue_1001.json
├── 1002/           # 第四个NPC角色
│   ├── 1.png
│   ├── confident.mp4
│   ├── drunk.mp4
│   ├── happy.mp4
│   ├── suspicious.mp4
│   ├── thinking.mp4
│   └── dialogue_1002.json
└── npc_config.json  # NPC总配置文件
```

### 3. Firebase Storage 安全规则
```javascript
service firebase.storage {
  match /b/{bucket}/o {
    // 允许所有用户读取npcs文件夹
    match /npcs/{allPaths=**} {
      allow read: if true;
      allow write: if false;
    }
    
    // 其他文件夹禁止访问
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

## Flutter集成步骤

### 1. 添加Firebase依赖
在 `pubspec.yaml` 中添加：
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_storage: ^11.5.5
```

### 2. 初始化Firebase
在 `main.dart` 中：
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

### 3. 实现云端资源加载服务
创建 `lib/services/cloud_npc_service.dart`：
- 从Firebase Storage下载NPC配置
- 缓存资源到本地
- 提供资源访问接口

### 4. 资源URL格式
Firebase Storage公开访问URL格式：
```
https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.appspot.com/o/npcs%2F{npcId}%2F{filename}?alt=media
```

示例：
- 头像: `https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.appspot.com/o/npcs%2F0001%2F1.png?alt=media`
- 视频: `https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.appspot.com/o/npcs%2F0001%2Fhappy.mp4?alt=media`
- 配置: `https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.appspot.com/o/npcs%2Fnpc_config.json?alt=media`

## 注意事项

1. **成本控制**：
   - Blaze计划按使用量计费
   - 监控下载流量避免超支
   - 实现本地缓存减少重复下载

2. **性能优化**：
   - 预加载常用资源
   - 使用渐进式加载
   - 实现离线模式

3. **错误处理**：
   - 网络连接失败时使用本地资源
   - 实现重试机制
   - 提供用户友好的错误提示
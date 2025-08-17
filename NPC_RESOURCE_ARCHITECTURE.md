# NPC资源处理架构文档

## 概述
所有NPC资源路径处理已统一到 `lib/config/character_assets.dart` 文件中的 `CharacterAssets` 类。

## 核心公用方法

### CharacterAssets 类 (`lib/config/character_assets.dart`)

这是处理所有NPC资源的唯一入口点，提供以下核心方法：

#### 1. ID标准化
```dart
static String getNormalizedId(String characterId)
```
- 将所有新旧ID映射到标准的数字ID (0001-0004, 1001-1003)
- 兼容旧ID: professor, gambler, provocateur, youngwoman, aki, katerina, lena

#### 2. 头像路径
```dart
static String getAvatarPath(String characterId)
```
- 返回角色的静态头像路径
- 所有头像统一命名为 `1.png`
- 路径格式: `assets/people/{normalizedId}/1.png`

```dart
static String getFullAvatarPath(String avatarPath)
```
- 处理目录路径，自动补充 `1.png`
- 兼容以 `/` 结尾的目录路径

#### 3. 视频路径
```dart
static String getVideoPath(String characterId, String emotion)
```
- 返回角色特定情绪的视频路径
- 自动映射情绪到实际存在的4个视频文件
- 路径格式: `assets/people/{normalizedId}/videos/{emotion}.mp4`

#### 4. 目录路径
```dart
static String getCharacterDirectory(String characterId)
static String getVideoDirectory(String characterId)
```
- 获取角色的基础目录和视频目录

#### 5. 特殊资源路径
```dart
static String getSpritePath(String characterId, String emotion, int frameNumber)
static String getTransparentPath(String characterId, String emotion, int frameNumber)
```
- 用于精灵动画和透明图片序列

#### 6. VIP检查
```dart
static bool isVIP(String characterId)
```
- 检查角色是否为VIP (ID以1开头)

## 统一映射表

### ID映射
- **普通NPC**: 0001-0004
- **VIP NPC**: 1001-1003
- 所有旧ID自动映射到新ID

### 情绪映射
实际只有4个视频文件，所有情绪自动映射：
- `thinking`: 思考类情绪
- `happy`: 开心/兴奋类情绪
- `confident`: 自信类情绪
- `suspicious`: 紧张/生气/担心类情绪

## 已更新的组件

所有视频和图片组件已更新为使用统一的 `CharacterAssets`:
- `simple_video_avatar.dart`
- `ai_video_avatar.dart`
- `ai_sprite_avatar.dart`
- `ai_transparent_avatar.dart`
- `game_screen.dart`
- `home_screen.dart`

## 移除的冗余代码

以下冗余映射表已从各组件中移除：
- `personalityToFolder` 映射表
- `emotionFileMapping` 映射表
- 所有硬编码的资源路径构建逻辑

## 使用示例

```dart
// 获取头像
String avatar = CharacterAssets.getAvatarPath('professor'); // 返回 'assets/people/0001/1.png'

// 获取视频
String video = CharacterAssets.getVideoPath('aki', 'excited'); // 返回 'assets/people/1001/videos/happy.mp4'

// 检查VIP
bool isVip = CharacterAssets.isVIP('1002'); // 返回 true
```

## 优势

1. **单一责任**: 所有资源路径逻辑集中在一处
2. **易于维护**: 修改路径规则只需更新一个文件
3. **向后兼容**: 支持所有旧ID，无需修改现有代码
4. **类型安全**: 使用静态方法，编译时检查
5. **性能优化**: 使用const映射表，无运行时开销
# Dice Girls Firebase Storage 资源架构详细文档

## 1. Firebase Storage 基础信息

### 项目配置
- **项目ID**: `liarsdice-fd930`
- **Storage Bucket**: `liarsdice-fd930.firebasestorage.app`
- **访问Token**: `adacfb99-9f79-4002-9aa3-e3a9a97db26b` (公开读取权限)
- **基础URL**: `https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/`

### 访问方式
1. **HTTP直接访问**: 
```
{基础URL}/{URL编码的文件路径}?alt=media&token={访问Token}
```

2. **Firebase SDK访问**:
```dart
final ref = FirebaseStorage.instance.ref('npcs/1001/1/1.jpg');
final data = await ref.getData();
```

## 2. Storage 文件结构

```
/npcs/
├── npc_config.json              # 核心配置文件（所有NPC的元数据）
├── resource_versions.json       # 资源版本控制文件
├── 0001/                        # 普通NPC - Lena
│   ├── 1/                       # 皮肤1（默认）
│   │   ├── 1.jpg                # 头像
│   │   ├── dialogue_0001.json   # 对话配置
│   │   ├── 0.mp4               # 表情视频 (happy)
│   │   ├── 1.mp4               # 表情视频 (angry)
│   │   ├── 2.mp4               # 表情视频 (sad)
│   │   ├── 3.mp4               # 表情视频 (confident)
│   │   ├── 4.mp4               # 表情视频 (nervous)
│   │   ├── 5.mp4               # 表情视频 (surprised)
│   │   ├── 6.mp4               # 表情视频 (thinking)
│   │   └── drunk.mp4           # 醉酒状态视频
│   └── 2/                       # 皮肤2（夏日海滩）
│       └── (同上结构)
├── 0002/                        # 普通NPC - Katerina
│   └── (同上结构)
├── 1001/                        # VIP NPC - Aki
│   └── 1/
│       └── (同上结构)
└── 1002/                        # VIP NPC - Isabella
    └── 1/
        └── (同上结构)
```

## 3. 核心配置文件详解

### 3.1 npc_config.json 结构
```json
{
  "npcs": {
    "0001": {
      "id": "0001",
      "names": {
        "en": "Lena",
        "zh_TW": "Lena",
        "es": "Lena",
        "pt": "Lena",
        "id": "Lena"
      },
      "descriptions": {
        "en": "Her calm gaze hides a quiet allure.",
        "zh_TW": "冷靜的眼神裡，藏著低調的魅力。",
        "es": "...",
        "pt": "...",
        "id": "..."
      },
      "avatarPath": "assets/npcs/0001/1/",  // 默认路径
      "videosPath": "assets/npcs/0001/1/",
      "isVIP": false,                        // 是否VIP角色
      "unlockItemId": null,                  // Google Play商品ID（VIP用）
      "personality": {
        "bluffRatio": 0.25,      // 虚张声势倾向 (0-1)
        "challengeThreshold": 0.4, // 挑战阈值 (0-1)
        "riskAppetite": 0.3      // 冒险偏好 (0-1)
      },
      "drinkCapacity": 2,         // 醉酒容量
      "country": "Germany",       // 国籍
      "skins": [                  // 皮肤配置
        {
          "id": 1,
          "name": {
            "en": "Classic",
            "zh_TW": "經典"
          },
          "unlocked": true,
          "unlockCondition": {
            "type": "default"     // default/intimacy/purchase
          },
          "videoCount": 7         // 该皮肤的视频数量
        },
        {
          "id": 2,
          "name": {
            "en": "Summer Beach",
            "zh_TW": "夏日海灘"
          },
          "unlocked": false,
          "unlockCondition": {
            "type": "intimacy",
            "level": 3
          },
          "videoCount": 7
        }
      ]
    },
    "1001": {
      "id": "1001",
      "isVIP": true,
      "unlockItemId": "vip_npc_1001",  // Google Play商品ID
      // ... 其他配置同上
    }
  }
}
```

### 3.2 dialogue_xxxx.json 结构
```json
{
  "npc_id": "0001",
  "version": "1.0.0",
  "dialogues": {
    "greeting": {
      "en": ["Hello!", "Hi there!"],
      "zh_TW": ["你好！", "嗨！"],
      "es": ["¡Hola!"],
      "pt": ["Olá!"],
      "id": ["Halo!"]
    },
    "winning": {
      "en": ["I win!", "Got you!"],
      "zh_TW": ["我贏了！", "抓到你了！"]
    },
    "losing": {
      "en": ["You're good!", "Nice play!"],
      "zh_TW": ["你很厲害！", "玩得好！"]
    },
    "thinking": {
      "en": ["Let me think..."],
      "zh_TW": ["讓我想想..."]
    },
    "drunk": {
      "light": {
        "en": ["I feel good!"],
        "zh_TW": ["感覺不錯！"]
      },
      "heavy": {
        "en": ["Everything is spinning..."],
        "zh_TW": ["天旋地轉..."]
      }
    },
    "emotions": {
      "happy": {
        "en": "I'm so happy!",
        "zh_TW": "我好開心！"
      },
      "angry": {
        "en": "This is annoying!",
        "zh_TW": "真煩人！"
      }
    },
    "strategy_dialogue": {
      "challenge_action": {
        "en": ["I don't believe you", "You're bluffing"],
        "zh_TW": ["我不信", "你在虛張"]
      },
      "value_bet": {
        "en": ["I have the goods"],
        "zh_TW": ["我有貨"]
      }
    }
  }
}
```

### 3.3 resource_versions.json 结构
```json
{
  "versions": {
    "npcs/0001/1": 2,    // 版本号，用于缓存控制
    "npcs/0001/2": 1,
    "npcs/0002/1": 2,
    "npcs/1001/1": 1,
    "npcs/1002/1": 1
  },
  "last_updated": "2024-09-01T10:00:00Z"
}
```

## 4. 资源使用规则

### 4.1 视频文件命名规则
- **表情视频**: `0.mp4` - `N.mp4` (N由videoCount决定)
- **特殊视频**: `drunk.mp4` (醉酒状态)
- **表情映射**:
  - 0: happy (开心)
  - 1: angry (生气)
  - 2: sad (悲伤)
  - 3: confident (自信)
  - 4: nervous (紧张)
  - 5: surprised (惊讶)
  - 6: thinking (思考)

### 4.2 皮肤系统规则
- **默认皮肤**: ID=1，始终解锁
- **解锁条件类型**:
  - `default`: 默认解锁
  - `intimacy`: 亲密度解锁（需要达到指定等级）
  - `purchase`: 内购解锁
  - `achievement`: 成就解锁

### 4.3 资源加载优先级
1. 检查本地缓存版本
2. 对比云端版本号
3. 如需更新则下载新资源
4. 缓存到本地供离线使用

## 5. Web App 集成建议

### 5.1 资源访问示例
```javascript
// 构建资源URL
function getResourceUrl(npcId, skinId, filename) {
  const basePath = `npcs/${npcId}/${skinId}/${filename}`;
  const encodedPath = encodeURIComponent(basePath).replace(/%2F/g, '%2F');
  return `https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/${encodedPath}?alt=media&token=adacfb99-9f79-4002-9aa3-e3a9a97db26b`;
}

// 获取NPC配置
async function getNPCConfig() {
  const url = getResourceUrl('', '', 'npc_config.json').replace('npcs%2F%2F', 'npcs%2F');
  const response = await fetch(url);
  return await response.json();
}

// 获取头像
function getAvatarUrl(npcId, skinId = 1) {
  return getResourceUrl(npcId, skinId, '1.jpg');
}

// 获取视频
function getVideoUrl(npcId, skinId = 1, videoIndex) {
  return getResourceUrl(npcId, skinId, `${videoIndex}.mp4`);
}
```

### 5.2 管理功能建议
1. **NPC编辑器**:
   - 读取/修改 npc_config.json
   - 支持多语言编辑
   - 皮肤管理界面

2. **资源上传器**:
   - 批量上传视频文件
   - 自动重命名（按0-N规则）
   - 图片压缩优化

3. **对话编辑器**:
   - 可视化编辑dialogue_xxxx.json
   - 多语言并排编辑
   - 策略对话管理

4. **版本控制**:
   - 自动更新resource_versions.json
   - 版本回滚功能
   - 变更日志记录

### 5.3 注意事项
1. **CORS配置**: Firebase Storage已配置允许跨域访问
2. **文件大小限制**: 视频建议控制在5MB以内
3. **缓存策略**: 利用版本号实现智能缓存
4. **权限管理**: 当前token仅支持读取，写入需要Firebase Admin SDK

## 6. 快速测试URL

```bash
# 获取NPC配置
https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/npcs%2Fnpc_config.json?alt=media&token=adacfb99-9f79-4002-9aa3-e3a9a97db26b

# 获取Lena的头像（皮肤1）
https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/npcs%2F0001%2F1%2F1.jpg?alt=media&token=adacfb99-9f79-4002-9aa3-e3a9a97db26b

# 获取Aki的对话文件
https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/npcs%2F1001%2F1%2Fdialogue_1001.json?alt=media&token=adacfb99-9f79-4002-9aa3-e3a9a97db26b

# 获取Katerina的happy视频（皮肤1）
https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/npcs%2F0002%2F1%2F0.mp4?alt=media&token=adacfb99-9f79-4002-9aa3-e3a9a97db26b
```

## 7. NPC ID映射表

| NPC ID | 名称 | 类型 | Google Play商品ID | 说明 |
|--------|------|------|-------------------|------|
| 0001 | Lena | 普通 | - | 德国，默认解锁 |
| 0002 | Katerina | 普通 | - | 俄罗斯，默认解锁 |
| 1001 | Aki (Suzuki) | VIP | vip_npc_1001 | 日本，需购买 |
| 1002 | Isabella (Yasmin) | VIP | vip_npc_1002 | 巴西，需购买 |

## 8. 多语言支持

支持的语言代码：
- `en`: 英语（默认）
- `zh`: 简体中文
- `zh_TW`: 繁体中文
- `es`: 西班牙语
- `pt`: 葡萄牙语
- `id`: 印尼语

## 9. 动态更新机制

### 9.1 热更新支持
- **配置热更新**: 修改 npc_config.json 即可新增NPC，无需客户端更新
- **资源热更新**: 上传新资源到对应目录即可
- **版本控制**: 更新 resource_versions.json 触发客户端重新下载

### 9.2 新增VIP NPC流程
1. 在 npc_config.json 添加新NPC配置
2. 设置 `isVIP: true` 和 `unlockItemId: "vip_npc_xxxx"`
3. 上传资源到 `/npcs/{npc_id}/{skin_id}/` 目录
4. 在Google Play Console创建对应商品
5. 更新 resource_versions.json

## 10. 资源规格建议

### 10.1 图片规格
- **头像 (1.jpg)**: 512x512px, JPG格式, <500KB
- **缩略图**: 256x256px（如需要）

### 10.2 视频规格
- **格式**: MP4 (H.264编码)
- **分辨率**: 720p (1280x720) 或 1080p (1920x1080)
- **帧率**: 30fps
- **时长**: 3-5秒循环
- **文件大小**: <5MB per video
- **音频**: 可选，AAC编码

### 10.3 JSON文件
- **编码**: UTF-8
- **格式**: 标准JSON，建议压缩
- **大小**: <100KB

## 11. 错误处理

### 11.1 常见错误码
- `403`: Token无效或过期
- `404`: 资源不存在
- `PERMISSION_DENIED`: 权限不足（写入操作）

### 11.2 降级策略
1. 云端加载失败 → 使用本地缓存
2. 视频加载失败 → 显示静态头像
3. 对话加载失败 → 使用默认对话

## 12. 安全注意事项

- **只读Token**: `adacfb99-9f79-4002-9aa3-e3a9a97db26b` 仅用于读取
- **写入权限**: 需要Firebase Admin SDK或服务账号
- **敏感信息**: 不要在Storage中存储用户个人信息
- **访问控制**: 通过Firebase Rules控制访问权限

---

*此文档用于Web App开发参考，包含Dice Girls完整的Storage架构信息*
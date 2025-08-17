# Gemini Service 清理计划

## 需要保留的核心方法

### 主要公开方法
1. `makeCompleteDecision()` - 主要入口，被game_screen.dart调用

### 必要的私有方法
1. `_callGeminiAPI()` - API调用核心
2. `_buildPersonalityDecisionPrompt()` - 构建prompt
3. `_parsePersonalityChoice()` - 解析响应
4. `_fallbackDecision()` - 降级决策
5. `_fallbackBid()` - 降级叫牌
6. `_calculateFirstBidProbability()` - 首轮概率计算
7. `_getPersonalityDescription()` - 获取性格描述

## 可以删除的方法（约1400行）

### 完全未使用的方法（约500行）
- `decideActionWithEmotion()` (行95-143)
- `decideAction()` (行148-150)
- `_buildDecisionPrompt()` (行154-296)
- `_buildBidPrompt()` (行299-426)
- `_parseAIDecision()` (行1234-1237)
- `_parseAIBid()` (行1304-1307)

### 重复的计算方法（约400行）
- `_calculateAllOptions()` (行507-675) - 使用BidOptionsCalculator代替
- `_addTacticalBluffOptions()` (行679-771)
- `_calculateBinomialProbability()` (行774-795)
- `_calculateSuccessRate()` (行798-804)

### 调试/分析方法（约200行）
- `_analyzeAllOptions()` (行808-883)
- `_analyzeMyBidOptions()` (行887-992)
- `_analyzeOpponentStyle()` (行996-1047)

### 未使用的解析方法（约200行）
- `_parseAIDecisionWithEmotion()` (行1144-1230)
- `_parseAIBidWithEmotion()` (行1240-1300)

### 重复的辅助方法（约100行）
- `_generateFirstBidOptions()` (行429-503) - 已被BidOptionsCalculator取代
- `_calculateOwnCounts()` (行1050-1055) - 简单重复

## 优化后的文件结构

```dart
class GeminiService {
  // 构造函数和成员变量（约20行）
  
  // 主要方法
  Future<...> makeCompleteDecision() // 约60行
  
  // API相关
  Future<String> _callGeminiAPI() // 约40行
  String _buildPersonalityDecisionPrompt() // 约100行
  
  // 解析
  _parsePersonalityChoice() // 简化到约200行（原600+行）
  
  // 降级处理
  AIDecision _fallbackDecision() // 约80行
  Bid _fallbackBid() // 约100行
  
  // 辅助方法
  String _getPersonalityDescription() // 约40行
  double _calculateFirstBidProbability() // 约20行
  
  // 对话生成（如果需要）
  Future<...> generateDialogue() // 约100行
}
```

## 预期结果
- **原始文件**: 2198行
- **清理后**: 约700-800行
- **减少**: 65%+

## 执行步骤

1. **删除未使用的公开方法**
2. **删除重复的计算方法，改用BidOptionsCalculator**
3. **删除调试/分析方法**
4. **简化_parsePersonalityChoice方法**
5. **整理剩余代码**
import 'package:flutter/material.dart';
import '../models/drinking_state.dart';

/// 醉酒效果覆盖层
class DrunkOverlay extends StatefulWidget {
  final DrinkingState drinkingState;
  final Widget child;
  
  const DrunkOverlay({
    super.key,
    required this.drinkingState,
    required this.child,
  });
  
  @override
  State<DrunkOverlay> createState() => _DrunkOverlayState();
}

class _DrunkOverlayState extends State<DrunkOverlay> with TickerProviderStateMixin {
  late AnimationController _swayController;
  late AnimationController _blurController;
  late Animation<double> _swayAnimation;
  late Animation<double> _blurAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // 摇晃动画
    _swayController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // 模糊动画
    _blurController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _swayAnimation = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _swayController,
      curve: Curves.easeInOut,
    ));
    
    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _blurController,
      curve: Curves.easeInOut,
    ));
    
    _updateAnimations();
  }
  
  @override
  void didUpdateWidget(DrunkOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drinkingState.drinksConsumed != widget.drinkingState.drinksConsumed) {
      _updateAnimations();
    }
  }
  
  void _updateAnimations() {
    if (widget.drinkingState.isTipsy || widget.drinkingState.isDrunk) {
      _swayController.repeat(reverse: true);
      _blurController.repeat(reverse: true);
    } else {
      _swayController.stop();
      _blurController.stop();
    }
  }
  
  @override
  void dispose() {
    _swayController.dispose();
    _blurController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final drunkLevel = widget.drinkingState.drunkLevel;
    
    if (drunkLevel == 0) {
      return widget.child;
    }
    
    return Stack(
      children: [
        // 主界面（无摇晃效果）
        widget.child,
        
        // 醉酒遮罩
        if (drunkLevel > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: drunkLevel * 0.3),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 饮酒状态指示器
class DrinkingIndicator extends StatelessWidget {
  final DrinkingState drinkingState;
  final String? currentAiId;
  
  const DrinkingIndicator({
    super.key,
    required this.drinkingState,
    this.currentAiId,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 玩家饮酒状态
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _getPlayerBorderColor(),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // 玩家状态
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    drinkingState.statusEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '玩家',
                    style: TextStyle(
                      color: _getPlayerTextColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // 玩家酒杯
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  DrinkingState.maxDrinks,
                  (index) => Icon(
                    Icons.local_bar,
                    size: 16,
                    color: index < drinkingState.drinksConsumed
                      ? Colors.amber
                      : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // AI饮酒状态
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _getAIBorderColor(),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // AI状态
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentAiId != null 
                      ? drinkingState.getAIStatusEmoji(currentAiId!)
                      : '😎',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI',
                    style: TextStyle(
                      color: _getAITextColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // AI酒杯
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  DrinkingState.maxDrinks,
                  (index) => Icon(
                    Icons.local_bar,
                    size: 16,
                    color: index < (currentAiId != null 
                            ? drinkingState.getAIDrinks(currentAiId!)
                            : 0)
                      ? Colors.red
                      : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
          
      ],
    );
  }
  
  Color _getPlayerBorderColor() {
    if (drinkingState.isDrunk) return Colors.red;
    if (drinkingState.isTipsy) return Colors.orange;
    return Colors.green;
  }
  
  Color _getAIBorderColor() {
    if (currentAiId != null && drinkingState.isAIDrunk(currentAiId!)) return Colors.red;
    if (currentAiId != null && drinkingState.isAITipsy(currentAiId!)) return Colors.orange;
    return Colors.green;
  }
  
  Color _getPlayerTextColor() {
    if (drinkingState.isDrunk) return Colors.red;
    if (drinkingState.isTipsy) return Colors.orange;
    return Colors.white;
  }
  
  Color _getAITextColor() {
    if (currentAiId != null && drinkingState.isAIDrunk(currentAiId!)) return Colors.red;
    if (currentAiId != null && drinkingState.isAITipsy(currentAiId!)) return Colors.orange;
    return Colors.white;
  }
}
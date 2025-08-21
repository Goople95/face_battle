import 'package:flutter/material.dart';
import 'intimacy_display.dart';

class AnimatedIntimacyDisplay extends StatefulWidget {
  final String npcId;
  final bool showDetails;
  final VoidCallback? onTap;
  
  const AnimatedIntimacyDisplay({
    super.key,
    required this.npcId,
    this.showDetails = false,
    this.onTap,
  });
  
  @override
  State<AnimatedIntimacyDisplay> createState() => _AnimatedIntimacyDisplayState();
}

class _AnimatedIntimacyDisplayState extends State<AnimatedIntimacyDisplay> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,  // 更小的缩放幅度
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,  // 更柔和的发光
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withValues(alpha: _glowAnimation.value),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: IntimacyDisplay(
              npcId: widget.npcId,
              showDetails: widget.showDetails,
              onTap: widget.onTap,
            ),
          ),
        );
      },
    );
  }
}
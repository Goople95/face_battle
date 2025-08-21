import 'package:flutter/material.dart';
import 'dart:math' as math;

/// AI face expression widget with animated emotions
class AIFaceWidget extends StatefulWidget {
  final Map<String, double> emotionalState;
  final String personality;
  
  const AIFaceWidget({
    super.key,
    required this.emotionalState,
    required this.personality,
  });
  
  @override
  State<AIFaceWidget> createState() => _AIFaceWidgetState();
}

class _AIFaceWidgetState extends State<AIFaceWidget>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _expressionController;
  late Animation<double> _blinkAnimation;
  late Animation<double> _expressionAnimation;
  
  // Expression parameters
  double _eyebrowHeight = 0.0;
  double _mouthCurve = 0.0;
  double _eyeSize = 1.0;
  
  @override
  void initState() {
    super.initState();
    
    // Blink animation
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _blinkAnimation = Tween<double>(
      begin: 1.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    ));
    
    // Expression animation
    _expressionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _expressionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expressionController,
      curve: Curves.easeInOut,
    ));
    
    // Start random blinking
    _startBlinking();
    
    // Update expression
    _updateExpression();
  }
  
  void _startBlinking() async {
    while (mounted) {
      await Future.delayed(Duration(seconds: 2 + math.Random().nextInt(4)));
      if (mounted) {
        await _blinkController.forward();
        await _blinkController.reverse();
      }
    }
  }
  
  void _updateExpression() {
    final valence = widget.emotionalState['valence'] ?? 0.0;
    final arousal = widget.emotionalState['arousal'] ?? 0.5;
    final confidence = widget.emotionalState['confidence'] ?? 0.5;
    final bluff = widget.emotionalState['bluff'] ?? 0.0;
    
    setState(() {
      // Eyebrows: raised when confident, furrowed when tense
      _eyebrowHeight = confidence * 10 - arousal * 5;
      
      // Mouth: smile when positive valence, frown when negative
      _mouthCurve = valence * 20;
      
      // Eyes: wider when aroused, narrower when bluffing
      _eyeSize = 1.0 + arousal * 0.2 - bluff * 0.1;
    });
    
    _expressionController.forward();
  }
  
  @override
  void didUpdateWidget(AIFaceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotionalState != widget.emotionalState) {
      _updateExpression();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.blue.shade100,
            Colors.blue.shade300,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_blinkAnimation, _expressionAnimation]),
        builder: (context, child) {
          return CustomPaint(
            painter: FacePainter(
              blinkValue: _blinkAnimation.value,
              eyebrowHeight: _eyebrowHeight * _expressionAnimation.value,
              mouthCurve: _mouthCurve * _expressionAnimation.value,
              eyeSize: _eyeSize,
            ),
          );
        },
      ),
    );
  }
  
  @override
  void dispose() {
    _blinkController.dispose();
    _expressionController.dispose();
    super.dispose();
  }
}

class FacePainter extends CustomPainter {
  final double blinkValue;
  final double eyebrowHeight;
  final double mouthCurve;
  final double eyeSize;
  
  FacePainter({
    required this.blinkValue,
    required this.eyebrowHeight,
    required this.mouthCurve,
    required this.eyeSize,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    
    // Eyes
    paint.color = Colors.black87;
    final eyeY = center.dy - 15;
    final eyeWidth = 15.0 * eyeSize;
    final eyeHeight = 20.0 * eyeSize * blinkValue;
    
    // Left eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - 25, eyeY),
        width: eyeWidth,
        height: eyeHeight,
      ),
      paint,
    );
    
    // Right eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + 25, eyeY),
        width: eyeWidth,
        height: eyeHeight,
      ),
      paint,
    );
    
    // Eyebrows
    paint.color = Colors.brown.shade700;
    final eyebrowY = eyeY - 20 - eyebrowHeight;
    
    // Left eyebrow
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx - 25, eyebrowY),
        width: 25,
        height: 10,
      ),
      math.pi,
      math.pi * 0.8,
      false,
      paint,
    );
    
    // Right eyebrow
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx + 25, eyebrowY),
        width: 25,
        height: 10,
      ),
      math.pi,
      math.pi * 0.8,
      false,
      paint,
    );
    
    // Mouth
    paint.color = Colors.red.shade400;
    final mouthPath = Path();
    final mouthY = center.dy + 30;
    
    mouthPath.moveTo(center.dx - 25, mouthY);
    mouthPath.quadraticBezierTo(
      center.dx,
      mouthY + mouthCurve,
      center.dx + 25,
      mouthY,
    );
    
    canvas.drawPath(mouthPath, paint);
  }
  
  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return blinkValue != oldDelegate.blinkValue ||
           eyebrowHeight != oldDelegate.eyebrowHeight ||
           mouthCurve != oldDelegate.mouthCurve ||
           eyeSize != oldDelegate.eyeSize;
  }
}
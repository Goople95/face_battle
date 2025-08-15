import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:math' as Math;
import '../utils/logger_utils.dart';

/// AI动画表情组件
/// 
/// 使用Rive动画显示AI的表情变化
/// 支持的表情：neutral, happy, sad, angry, thinking, confident, nervous, excited
class AnimatedAIFace extends StatefulWidget {
  final String emotion;
  final double size;
  final Map<String, double>? emotionalState;
  
  const AnimatedAIFace({
    Key? key,
    required this.emotion,
    this.size = 100,
    this.emotionalState,
  }) : super(key: key);
  
  @override
  State<AnimatedAIFace> createState() => _AnimatedAIFaceState();
}

class _AnimatedAIFaceState extends State<AnimatedAIFace> {
  // Rive动画控制器
  StateMachineController? _controller;
  SMIInput<double>? _valenceInput;    // 情绪效价 (-1到1)
  SMIInput<double>? _arousalInput;    // 情绪唤醒度 (0到1)
  SMIInput<bool>? _blinkTrigger;      // 眨眼触发
  SMIInput<bool>? _talkTrigger;       // 说话触发
  
  // 如果没有Rive文件，使用CustomPainter作为备选
  bool _useCustomPainter = true;
  
  @override
  void initState() {
    super.initState();
    _checkRiveAsset();
  }
  
  Future<void> _checkRiveAsset() async {
    // 检查是否有Rive动画文件
    // 如果没有，使用CustomPainter
    try {
      // 尝试加载Rive文件
      // await RiveFile.asset('assets/rive/ai_face.riv');
      // setState(() => _useCustomPainter = false);
    } catch (e) {
      GameLogger.logGameState('使用CustomPainter绘制AI表情');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_useCustomPainter) {
      // 使用CustomPainter绘制简单但有效的表情
      return Container(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: EmotionalFacePainter(
            emotion: widget.emotion,
            emotionalState: widget.emotionalState,
          ),
          child: Container(),
        ),
      );
    } else {
      // 使用Rive动画（需要创建.riv文件）
      return Container(
        width: widget.size,
        height: widget.size,
        child: RiveAnimation.asset(
          'assets/rive/ai_face.riv',
          stateMachines: ['EmotionStateMachine'],
          onInit: _onRiveInit,
        ),
      );
    }
  }
  
  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'EmotionStateMachine',
    );
    
    if (controller != null) {
      artboard.addController(controller);
      _controller = controller;
      
      // 获取输入控制
      _valenceInput = controller.findInput('valence');
      _arousalInput = controller.findInput('arousal');
      _blinkTrigger = controller.findInput('blink');
      _talkTrigger = controller.findInput('talk');
      
      // 更新表情
      _updateEmotion();
    }
  }
  
  void _updateEmotion() {
    if (widget.emotionalState != null) {
      _valenceInput?.value = widget.emotionalState!['valence'] ?? 0;
      _arousalInput?.value = widget.emotionalState!['arousal'] ?? 0.5;
    }
  }
  
  @override
  void didUpdateWidget(AnimatedAIFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotion != widget.emotion) {
      _updateEmotion();
    }
  }
}

/// 自定义表情绘制器
class EmotionalFacePainter extends CustomPainter {
  final String emotion;
  final Map<String, double>? emotionalState;
  
  EmotionalFacePainter({
    required this.emotion,
    this.emotionalState,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.9;
    
    // 绘制脸部轮廓
    final facePaint = Paint()
      ..color = _getFaceColor()
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, facePaint);
    
    // 绘制边框
    final borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, radius, borderPaint);
    
    // 绘制眼睛
    _drawEyes(canvas, size, center, radius);
    
    // 绘制嘴巴
    _drawMouth(canvas, size, center, radius);
    
    // 绘制额外特征（如汗滴、红晕等）
    _drawEmotionFeatures(canvas, size, center, radius);
  }
  
  Color _getFaceColor() {
    switch (emotion) {
      case 'happy':
        return Colors.yellow.shade100;
      case 'angry':
        return Colors.red.shade100;
      case 'nervous':
        return Colors.blue.shade50;
      case 'excited':
        return Colors.orange.shade100;
      case 'confident':
        return Colors.green.shade50;
      default:
        return Colors.amber.shade50;
    }
  }
  
  void _drawEyes(Canvas canvas, Size size, Offset center, double radius) {
    final eyePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    
    final leftEye = Offset(center.dx - radius * 0.3, center.dy - radius * 0.2);
    final rightEye = Offset(center.dx + radius * 0.3, center.dy - radius * 0.2);
    
    switch (emotion) {
      case 'happy':
        // 弯月眼
        final path = Path();
        path.moveTo(leftEye.dx - 10, leftEye.dy);
        path.quadraticBezierTo(leftEye.dx, leftEye.dy + 10, leftEye.dx + 10, leftEye.dy);
        canvas.drawPath(path, eyePaint..strokeWidth = 3..style = PaintingStyle.stroke);
        
        path.reset();
        path.moveTo(rightEye.dx - 10, rightEye.dy);
        path.quadraticBezierTo(rightEye.dx, rightEye.dy + 10, rightEye.dx + 10, rightEye.dy);
        canvas.drawPath(path, eyePaint);
        break;
        
      case 'angry':
        // 生气的眼睛
        canvas.drawCircle(leftEye, 5, eyePaint);
        canvas.drawCircle(rightEye, 5, eyePaint);
        // 眉毛
        canvas.drawLine(
          Offset(leftEye.dx - 15, leftEye.dy - 15),
          Offset(leftEye.dx + 10, leftEye.dy - 5),
          eyePaint..strokeWidth = 3..style = PaintingStyle.stroke,
        );
        canvas.drawLine(
          Offset(rightEye.dx + 15, rightEye.dy - 15),
          Offset(rightEye.dx - 10, rightEye.dy - 5),
          eyePaint,
        );
        break;
        
      case 'thinking':
        // 思考的眼睛（一个睁开，一个眯着）
        canvas.drawCircle(leftEye, 5, eyePaint..style = PaintingStyle.fill);
        canvas.drawLine(
          Offset(rightEye.dx - 10, rightEye.dy),
          Offset(rightEye.dx + 10, rightEye.dy),
          eyePaint..strokeWidth = 3..style = PaintingStyle.stroke,
        );
        break;
        
      default:
        // 普通圆眼睛
        canvas.drawCircle(leftEye, 5, eyePaint);
        canvas.drawCircle(rightEye, 5, eyePaint);
    }
  }
  
  void _drawMouth(Canvas canvas, Size size, Offset center, double radius) {
    final mouthPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final mouthCenter = Offset(center.dx, center.dy + radius * 0.3);
    
    switch (emotion) {
      case 'happy':
      case 'excited':
        // 微笑
        final path = Path();
        path.moveTo(mouthCenter.dx - radius * 0.3, mouthCenter.dy);
        path.quadraticBezierTo(
          mouthCenter.dx, mouthCenter.dy + radius * 0.2,
          mouthCenter.dx + radius * 0.3, mouthCenter.dy,
        );
        canvas.drawPath(path, mouthPaint);
        break;
        
      case 'sad':
      case 'worried':
        // 沮丧
        final path = Path();
        path.moveTo(mouthCenter.dx - radius * 0.2, mouthCenter.dy + radius * 0.1);
        path.quadraticBezierTo(
          mouthCenter.dx, mouthCenter.dy - radius * 0.1,
          mouthCenter.dx + radius * 0.2, mouthCenter.dy + radius * 0.1,
        );
        canvas.drawPath(path, mouthPaint);
        break;
        
      case 'nervous':
        // 波浪嘴
        final path = Path();
        path.moveTo(mouthCenter.dx - radius * 0.2, mouthCenter.dy);
        for (int i = 0; i < 4; i++) {
          final x = mouthCenter.dx - radius * 0.2 + i * radius * 0.1;
          final y = mouthCenter.dy + (i % 2 == 0 ? -3 : 3);
          path.lineTo(x, y);
        }
        canvas.drawPath(path, mouthPaint);
        break;
        
      case 'confident':
      case 'smirk':
        // 自信的斜嘴笑
        final path = Path();
        path.moveTo(mouthCenter.dx - radius * 0.2, mouthCenter.dy + 5);
        path.quadraticBezierTo(
          mouthCenter.dx, mouthCenter.dy,
          mouthCenter.dx + radius * 0.3, mouthCenter.dy - 5,
        );
        canvas.drawPath(path, mouthPaint);
        break;
        
      default:
        // 中性表情
        canvas.drawLine(
          Offset(mouthCenter.dx - radius * 0.2, mouthCenter.dy),
          Offset(mouthCenter.dx + radius * 0.2, mouthCenter.dy),
          mouthPaint,
        );
    }
  }
  
  void _drawEmotionFeatures(Canvas canvas, Size size, Offset center, double radius) {
    switch (emotion) {
      case 'nervous':
        // 汗滴
        final sweatPaint = Paint()
          ..color = Colors.blue.shade300
          ..style = PaintingStyle.fill;
        final sweatPos = Offset(center.dx + radius * 0.6, center.dy - radius * 0.4);
        canvas.drawCircle(sweatPos, 3, sweatPaint);
        final path = Path();
        path.moveTo(sweatPos.dx - 3, sweatPos.dy);
        path.lineTo(sweatPos.dx, sweatPos.dy - 6);
        path.lineTo(sweatPos.dx + 3, sweatPos.dy);
        path.close();
        canvas.drawPath(path, sweatPaint);
        break;
        
      case 'excited':
        // 星星眼效果
        final starPaint = Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.fill;
        _drawStar(canvas, Offset(center.dx - radius * 0.5, center.dy - radius * 0.4), 5, starPaint);
        _drawStar(canvas, Offset(center.dx + radius * 0.5, center.dy - radius * 0.4), 5, starPaint);
        break;
        
      case 'happy':
        // 红晕
        final blushPaint = Paint()
          ..color = Colors.pink.shade200.withOpacity(0.5)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(center.dx - radius * 0.5, center.dy + radius * 0.05),
          radius * 0.15,
          blushPaint,
        );
        canvas.drawCircle(
          Offset(center.dx + radius * 0.5, center.dy + radius * 0.05),
          radius * 0.15,
          blushPaint,
        );
        break;
    }
  }
  
  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = i * 36 * 3.14159 / 180;
      final r = i % 2 == 0 ? size : size / 2;
      final x = center.dx + r * Math.cos(angle);
      final y = center.dy + r * Math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(EmotionalFacePainter oldDelegate) {
    return oldDelegate.emotion != emotion ||
           oldDelegate.emotionalState != emotionalState;
  }
}
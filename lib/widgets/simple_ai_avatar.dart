import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/logger_utils.dart';

/// 简化版AI头像组件 - 支持精细表情控制
/// 基于ChatGPT建议的参数系统
class SimpleAIAvatar extends StatefulWidget {
  final double size;
  const SimpleAIAvatar({super.key, this.size = 200});
  
  @override
  State<SimpleAIAvatar> createState() => SimpleAIAvatarState();
}

class SimpleAIAvatarState extends State<SimpleAIAvatar>
    with TickerProviderStateMixin {
  // 核心情绪参数（与未来Rive一致）
  double _valence = 0.0;     // -1..1  负/正情绪 -> 嘴角弧度
  double _arousal = 0.3;     // 0..1   紧张度 -> 眼睑收缩、眉角上扬
  double _confidence = 0.5;  // 0..1   自信 -> 眉形/嘴角稳定度
  double _bluff = 0.0;       // 0..1   诈唬 -> 夸张度/挑眉
  double _gazeX = 0.0;       // -1..1  视线左右
  double _gazeY = 0.0;       // -1..1  视线上下
  
  // 目标值（用于平滑过渡）
  double _targetValence = 0.0;
  double _targetArousal = 0.3;
  double _targetConfidence = 0.5;
  double _targetBluff = 0.0;
  double _targetGazeX = 0.0;
  double _targetGazeY = 0.0;

  // 动画控制
  late final AnimationController _blinkCtrl;
  late final AnimationController _talkCtrl;
  late final AnimationController _transitionCtrl;
  
  // 自动眨眼计时
  DateTime _lastBlink = DateTime.now();
  Duration _nextBlinkInterval = const Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 140),
    );
    
    _talkCtrl = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 260),
    );
    
    _transitionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateTransition)
     ..repeat();
    
    // 启动自动眨眼
    _scheduleNextBlink();
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    _talkCtrl.dispose();
    _transitionCtrl.dispose();
    super.dispose();
  }
  
  void _updateTransition() {
    setState(() {
      // EMA平滑过渡
      const k = 0.15; // 平滑系数
      _valence += (_targetValence - _valence) * k;
      _arousal += (_targetArousal - _arousal) * k;
      _confidence += (_targetConfidence - _confidence) * k;
      _bluff += (_targetBluff - _bluff) * k;
      _gazeX += (_targetGazeX - _gazeX) * k;
      _gazeY += (_targetGazeY - _gazeY) * k;
      
      // 检查自动眨眼
      final now = DateTime.now();
      if (now.difference(_lastBlink) > _nextBlinkInterval) {
        _triggerBlink();
        _lastBlink = now;
        _scheduleNextBlink();
      }
    });
  }
  
  void _scheduleNextBlink() {
    // 随机间隔2-5秒，紧张时更频繁
    final baseInterval = 3000 - (_arousal * 1500).toInt();
    final randomOffset = (math.Random().nextDouble() * 2000).toInt();
    _nextBlinkInterval = Duration(milliseconds: baseInterval + randomOffset);
  }
  
  void _triggerBlink([String type = 'soft']) {
    if (type == 'fast') {
      _blinkCtrl.duration = const Duration(milliseconds: 100);
    } else {
      _blinkCtrl.duration = const Duration(milliseconds: 140);
    }
    _blinkCtrl.forward(from: 0).then((_) {
      _blinkCtrl.reverse();
    });
  }

  // 对外接口：应用表情指令
  void applyEmotion({
    double? valence,
    double? arousal,
    double? confidence,
    double? bluff,
    double? gazeX,
    double? gazeY,
    String? blink,
    bool? talking,
    String? emotion,
  }) {
    setState(() {
      if (valence != null) _targetValence = valence.clamp(-1.0, 1.0);
      if (arousal != null) _targetArousal = arousal.clamp(0.0, 1.0);
      if (confidence != null) _targetConfidence = confidence.clamp(0.0, 1.0);
      if (bluff != null) _targetBluff = bluff.clamp(0.0, 1.0);
      if (gazeX != null) _targetGazeX = gazeX.clamp(-1.0, 1.0);
      if (gazeY != null) _targetGazeY = gazeY.clamp(-1.0, 1.0);
      
      if (blink != null && blink != 'none') {
        _triggerBlink(blink);
      }
      
      if (talking != null) {
        if (talking) {
          if (!_talkCtrl.isAnimating) {
            _talkCtrl.repeat(reverse: true);
          }
        } else {
          _talkCtrl.stop();
          _talkCtrl.value = 0.0;
        }
      }
      
      // 根据emotion预设调整参数
      if (emotion != null) {
        _applyEmotionPreset(emotion);
      }
    });
    
    GameLogger.logGameState('表情更新', details: {
      'valence': valence,
      'arousal': arousal,
      'confidence': confidence,
      'bluff': bluff,
      'emotion': emotion,
    });
  }
  
  void _applyEmotionPreset(String emotion) {
    switch (emotion) {
      case 'happy':
        _targetValence = 0.7;
        _targetArousal = 0.4;
        _targetConfidence = 0.7;
        break;
      case 'confident':
        _targetValence = 0.3;
        _targetArousal = 0.2;
        _targetConfidence = 0.9;
        break;
      case 'nervous':
        _targetValence = -0.2;
        _targetArousal = 0.8;
        _targetConfidence = 0.3;
        break;
      case 'angry':
        _targetValence = -0.7;
        _targetArousal = 0.9;
        _targetConfidence = 0.6;
        break;
      case 'thinking':
        _targetValence = 0.0;
        _targetArousal = 0.3;
        _targetConfidence = 0.5;
        _targetGazeX = 0.3;
        _targetGazeY = -0.2;
        break;
      case 'excited':
        _targetValence = 0.8;
        _targetArousal = 0.9;
        _targetConfidence = 0.6;
        break;
      case 'worried':
        _targetValence = -0.3;
        _targetArousal = 0.6;
        _targetConfidence = 0.2;
        break;
      case 'smirk':
        _targetValence = 0.4;
        _targetArousal = 0.3;
        _targetConfidence = 0.8;
        _targetBluff = 0.6;
        break;
      case 'surprised':
        _targetValence = 0.1;
        _targetArousal = 0.8;
        _targetConfidence = 0.4;
        _targetGazeX = 0.0;
        _targetGazeY = 0.1;
        break;
      case 'disappointed':
        _targetValence = -0.5;
        _targetArousal = 0.3;
        _targetConfidence = 0.3;
        _targetGazeY = 0.2;
        break;
      case 'suspicious':
        _targetValence = -0.1;
        _targetArousal = 0.5;
        _targetConfidence = 0.6;
        _targetBluff = 0.4;
        _targetGazeX = 0.2;
        break;
      case 'proud':
        _targetValence = 0.6;
        _targetArousal = 0.3;
        _targetConfidence = 0.95;
        _targetGazeY = -0.1;
        break;
      case 'relaxed':
        _targetValence = 0.4;
        _targetArousal = 0.1;
        _targetConfidence = 0.7;
        break;
      case 'anxious':
        _targetValence = -0.4;
        _targetArousal = 0.85;
        _targetConfidence = 0.25;
        _targetGazeX = -0.1;
        _targetGazeY = 0.1;
        break;
      case 'cunning':
        _targetValence = 0.3;
        _targetArousal = 0.4;
        _targetConfidence = 0.7;
        _targetBluff = 0.8;
        _targetGazeX = 0.1;
        break;
      case 'frustrated':
        _targetValence = -0.6;
        _targetArousal = 0.7;
        _targetConfidence = 0.4;
        break;
      case 'determined':
        _targetValence = 0.2;
        _targetArousal = 0.6;
        _targetConfidence = 0.85;
        _targetGazeY = -0.05;
        break;
      case 'playful':
        _targetValence = 0.6;
        _targetArousal = 0.5;
        _targetConfidence = 0.6;
        _targetBluff = 0.5;
        _targetGazeX = -0.2;
        break;
      case 'neutral':
        _targetValence = 0.0;
        _targetArousal = 0.3;
        _targetConfidence = 0.5;
        _targetGazeX = 0.0;
        _targetGazeY = 0.0;
        break;
      case 'contemplating':
        _targetValence = 0.0;
        _targetArousal = 0.35;
        _targetConfidence = 0.55;
        _targetGazeX = 0.4;
        _targetGazeY = -0.3;
        break;
    }
  }
  
  // 从JSON应用表情
  void applyEmotionFromJson(Map<String, dynamic> json) {
    applyEmotion(
      valence: json['valence']?.toDouble(),
      arousal: json['arousal']?.toDouble(),
      confidence: json['confidence']?.toDouble(),
      bluff: json['bluff']?.toDouble(),
      gazeX: (json['gaze'] ?? {})['x']?.toDouble(),
      gazeY: (json['gaze'] ?? {})['y']?.toDouble(),
      blink: json['blink'],
      talking: json['say'] != null,
      emotion: json['emotion'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_blinkCtrl, _talkCtrl, _transitionCtrl]),
      builder: (_, __) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _AdvancedFacePainter(
            valence: _valence,
            arousal: _arousal,
            confidence: _confidence,
            bluff: _bluff,
            gazeX: _gazeX,
            gazeY: _gazeY,
            blinkT: _blinkCtrl.value,
            talkT: _talkCtrl.value,
          ),
        );
      },
    );
  }
}

class _AdvancedFacePainter extends CustomPainter {
  final double valence, arousal, confidence, bluff, gazeX, gazeY, blinkT, talkT;
  
  _AdvancedFacePainter({
    required this.valence,
    required this.arousal,
    required this.confidence,
    required this.bluff,
    required this.gazeX,
    required this.gazeY,
    required this.blinkT,
    required this.talkT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width/2, size.height/2);
    final r = size.width/2;

    // 背景脸部
    _drawFace(canvas, c, r);
    
    // 眼睛
    _drawEyes(canvas, c, r);
    
    // 眉毛
    _drawEyebrows(canvas, c, r);
    
    // 嘴巴
    _drawMouth(canvas, c, r);
    
    // 额外特征
    _drawEmotionalFeatures(canvas, c, r);
  }
  
  void _drawFace(Canvas canvas, Offset c, double r) {
    // 脸部颜色根据情绪微调
    final hue = 30.0 + valence * 10; // 正情绪偏黄，负情绪偏红
    final saturation = 0.1 + arousal * 0.15; // 紧张时饱和度增加
    final lightness = 0.98 - arousal * 0.02; // 紧张时略暗
    
    final faceColor = HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
    final facePaint = Paint()..color = faceColor;
    canvas.drawCircle(c, r * 0.95, facePaint);

    // 边框
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.02
      ..color = Colors.black.withOpacity(0.1);
    canvas.drawCircle(c, r * 0.95, border);
  }
  
  void _drawEyes(Canvas canvas, Offset c, double r) {
    final eyeCx = r * 0.35;
    final eyeCy = r * 0.15;
    final eyeWidth = r * 0.35;
    final eyeHeight = r * 0.25;
    
    // 眼睛开合度
    final openness = (1.0 - blinkT) * (1.0 - arousal * 0.3);
    
    // 左右眼位置
    final leftEyeCenter = c + Offset(-eyeCx, -eyeCy);
    final rightEyeCenter = c + Offset(eyeCx, -eyeCy);
    
    // 眼白
    final eyeWhite = Paint()..color = Colors.white;
    final leftEyeRect = Rect.fromCenter(
      center: leftEyeCenter,
      width: eyeWidth,
      height: eyeHeight * openness.clamp(0.1, 1.0),
    );
    final rightEyeRect = Rect.fromCenter(
      center: rightEyeCenter,
      width: eyeWidth,
      height: eyeHeight * openness.clamp(0.1, 1.0),
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(leftEyeRect, Radius.circular(r * 0.1)),
      eyeWhite,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rightEyeRect, Radius.circular(r * 0.1)),
      eyeWhite,
    );
    
    // 瞳孔（带视线控制）
    final pupilRadius = r * 0.08 * (1.0 + arousal * 0.2); // 紧张时瞳孔放大
    final pupilOffset = Offset(
      gazeX * r * 0.08,
      gazeY * r * 0.06,
    );
    
    final pupilPaint = Paint()..color = Color(0xFF2C3E50);
    canvas.drawCircle(leftEyeCenter + pupilOffset, pupilRadius, pupilPaint);
    canvas.drawCircle(rightEyeCenter + pupilOffset, pupilRadius, pupilPaint);
    
    // 虹膜细节
    final irisPaint = Paint()..color = Color(0xFF34495E).withOpacity(0.5);
    canvas.drawCircle(leftEyeCenter + pupilOffset, pupilRadius * 0.7, irisPaint);
    canvas.drawCircle(rightEyeCenter + pupilOffset, pupilRadius * 0.7, irisPaint);
  }
  
  void _drawEyebrows(Canvas canvas, Offset c, double r) {
    final browPaint = Paint()
      ..color = Color(0xFF2C3E50)
      ..strokeWidth = r * 0.04
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final eyeCx = r * 0.35;
    final eyeCy = r * 0.15;
    final browY = -eyeCy - r * 0.18;
    
    // 眉毛高度和角度
    final browLift = arousal * r * 0.05; // 紧张时眉毛上扬
    final browAngle = valence * 0.2; // 正情绪外扬，负情绪内收
    final asymmetry = bluff * r * 0.03; // 诈唬时不对称
    
    // 左眉
    final leftBrowPath = Path();
    leftBrowPath.moveTo(
      c.dx - eyeCx - r * 0.12,
      c.dy + browY - browLift + asymmetry,
    );
    leftBrowPath.quadraticBezierTo(
      c.dx - eyeCx,
      c.dy + browY - browLift * 1.2 - browAngle * r * 0.05,
      c.dx - eyeCx + r * 0.15,
      c.dy + browY - browLift + browAngle * r * 0.03,
    );
    canvas.drawPath(leftBrowPath, browPaint);
    
    // 右眉
    final rightBrowPath = Path();
    rightBrowPath.moveTo(
      c.dx + eyeCx + r * 0.12,
      c.dy + browY - browLift - asymmetry,
    );
    rightBrowPath.quadraticBezierTo(
      c.dx + eyeCx,
      c.dy + browY - browLift * 1.2 - browAngle * r * 0.05,
      c.dx + eyeCx - r * 0.15,
      c.dy + browY - browLift + browAngle * r * 0.03,
    );
    canvas.drawPath(rightBrowPath, browPaint);
  }
  
  void _drawMouth(Canvas canvas, Offset c, double r) {
    final mouthY = r * 0.35;
    final mouthWidth = r * 0.5 * (1.0 + confidence * 0.2); // 自信时嘴角更宽
    
    // 嘴角弧度
    final curve = valence * r * 0.15; // 正值上扬，负值下垂
    final openAmount = talkT * r * 0.08 * (1.0 + confidence * 0.3);
    
    // 上嘴唇
    final upperLipPath = Path();
    upperLipPath.moveTo(c.dx - mouthWidth/2, c.dy + mouthY);
    upperLipPath.quadraticBezierTo(
      c.dx,
      c.dy + mouthY - curve,
      c.dx + mouthWidth/2,
      c.dy + mouthY,
    );
    
    final lipPaint = Paint()
      ..color = Color(0xFFE74C3C)
      ..strokeWidth = r * 0.03
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(upperLipPath, lipPaint);
    
    // 下嘴唇（说话时张开）
    if (openAmount > 0.01) {
      final lowerLipPath = Path();
      lowerLipPath.moveTo(c.dx - mouthWidth/2, c.dy + mouthY);
      lowerLipPath.quadraticBezierTo(
        c.dx,
        c.dy + mouthY - curve + openAmount,
        c.dx + mouthWidth/2,
        c.dy + mouthY,
      );
      canvas.drawPath(lowerLipPath, lipPaint);
      
      // 口腔内部
      final mouthInterior = Paint()..color = Color(0xFF2C3E50).withOpacity(0.3);
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(0, mouthY + openAmount/2),
          width: mouthWidth * 0.4,
          height: openAmount * 0.8,
        ),
        mouthInterior,
      );
    }
  }
  
  void _drawEmotionalFeatures(Canvas canvas, Offset c, double r) {
    // 腮红（紧张/兴奋时）
    if (arousal > 0.5) {
      final blushIntensity = (arousal - 0.5) * 0.4;
      final blushPaint = Paint()
        ..color = Colors.pink.withOpacity(blushIntensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.05);
      
      canvas.drawCircle(c + Offset(-r * 0.4, r * 0.1), r * 0.12, blushPaint);
      canvas.drawCircle(c + Offset(r * 0.4, r * 0.1), r * 0.12, blushPaint);
    }
    
    // 汗滴（极度紧张时）
    if (arousal > 0.8) {
      final sweatPaint = Paint()
        ..color = Colors.blue.shade200
        ..style = PaintingStyle.fill;
      
      final sweatPos = c + Offset(r * 0.55, -r * 0.3);
      final sweatPath = Path();
      sweatPath.moveTo(sweatPos.dx, sweatPos.dy - r * 0.03);
      sweatPath.quadraticBezierTo(
        sweatPos.dx - r * 0.02,
        sweatPos.dy,
        sweatPos.dx,
        sweatPos.dy + r * 0.04,
      );
      sweatPath.quadraticBezierTo(
        sweatPos.dx + r * 0.02,
        sweatPos.dy,
        sweatPos.dx,
        sweatPos.dy - r * 0.03,
      );
      canvas.drawPath(sweatPath, sweatPaint);
    }
    
    // 自信光环（高自信时）
    if (confidence > 0.7 && bluff < 0.3) {
      final glowPaint = Paint()
        ..color = Colors.yellow.withOpacity((confidence - 0.7) * 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.1);
      
      canvas.drawCircle(c, r * 1.05, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AdvancedFacePainter old) =>
      old.valence != valence || 
      old.arousal != arousal || 
      old.confidence != confidence ||
      old.bluff != bluff || 
      old.gazeX != gazeX || 
      old.gazeY != gazeY ||
      old.blinkT != blinkT || 
      old.talkT != talkT;
}
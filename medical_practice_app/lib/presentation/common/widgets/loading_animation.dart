import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../config/theme.dart';
import '../../../config/constants.dart';

class LoadingAnimation extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration duration;
  final String? message;
  final TextStyle? messageStyle;
  
  const LoadingAnimation({
    Key? key,
    this.size = 60.0,
    this.color,
    this.duration = const Duration(milliseconds: 1500),
    this.message,
    this.messageStyle,
  }) : super(key: key);

  @override
  _LoadingAnimationState createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? AppTheme.primaryColor;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: LoadingPainter(
                progress: _progressAnimation.value,
                rotation: _rotationAnimation.value,
                color: color,
              ),
              size: Size(widget.size, widget.size),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: 0.5 + (_progressAnimation.value * 0.5),
                child: Text(
                  widget.message!,
                  style: widget.messageStyle ??
                      theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onBackground,
                      ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class LoadingPainter extends CustomPainter {
  final double progress;
  final double rotation;
  final Color color;

  LoadingPainter({
    required this.progress,
    required this.rotation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.15;
    
    // Draw background circle
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);
    
    // Save canvas state
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    
    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    
    // Progress calculation with slight pulsation
    final pulsation = math.sin(progress * math.pi * 2) * 0.1 + 0.9;
    final sweepAngle = 2 * math.pi * progress * pulsation;
    
    canvas.drawArc(rect, 0, sweepAngle, false, progressPaint);
    
    // Draw leading dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final dotX = center.dx + (radius - strokeWidth / 2) * math.cos(sweepAngle);
    final dotY = center.dy + (radius - strokeWidth / 2) * math.sin(sweepAngle);
    final dotRadius = strokeWidth * 0.6;
    
    canvas.drawCircle(Offset(dotX, dotY), dotRadius, dotPaint);
    
    // Restore canvas state
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LoadingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.rotation != rotation ||
        oldDelegate.color != color;
  }
}

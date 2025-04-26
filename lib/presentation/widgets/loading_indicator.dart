import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class LoadingIndicator extends StatefulWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const LoadingIndicator({
    Key? key,
    this.size = 50,
    this.color = AppTheme.primaryColor,
    this.strokeWidth = 4.0,
  }) : super(key: key);

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              painter: _LoadingPainter(
                progress: _animation.value,
                color: widget.color,
                strokeWidth: widget.strokeWidth,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _LoadingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5 * 3.14 + (progress * 2 * 3.14), // Start from top, go clockwise
      0.7 * 3.14, // Length of the arc
      false,
      progressPaint,
    );

    // Draw small circle at the end of the arc
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double angle = -0.5 * 3.14 + (progress * 2 * 3.14) + (0.7 * 3.14);
    final dotX = center.dx + radius * cos(angle);
    final dotY = center.dy + radius * sin(angle);

    canvas.drawCircle(
      Offset(dotX, dotY),
      strokeWidth / 2,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(_LoadingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }

  // Helper function to calculate position
  double cos(double angle) {
    return Math.cos(angle);
  }

  double sin(double angle) {
    return Math.sin(angle);
  }
}

class Math {
  static double cos(double angle) {
    return math.cos(angle);
  }

  static double sin(double angle) {
    return math.sin(angle);
  }
}

// Simplified math implementation for the example
// In a real app, you'd use dart:math
class math {
  static double cos(double angle) {
    // A simplified implementation of cosine
    return _cosSeries(angle);
  }

  static double sin(double angle) {
    // A simplified implementation of sine using cos(x - PI/2)
    return cos(angle - (3.14159 / 2));
  }

  // Taylor series approximation of cosine
  static double _cosSeries(double x) {
    // Normalize angle to -PI to PI
    while (x > 3.14159) x -= 2 * 3.14159;
    while (x < -3.14159) x += 2 * 3.14159;
    
    double result = 1;
    double term = 1;
    double x2 = x * x;
    
    for (int i = 2; i <= 10; i += 2) {
      term *= -x2 / ((i - 1) * i);
      result += term;
      if (term.abs() < 1e-10) break;
    }
    
    return result;
  }
}
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class LoadingAnimation extends StatefulWidget {
  final double size;
  final Color color;

  const LoadingAnimation({
    super.key,
    this.size = 50.0,
    this.color = Colors.blue, // Default color that can be overridden
  });

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation> with SingleTickerProviderStateMixin {
  static final _log = Logger('LoadingAnimation');
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    try {
      _controller = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      );

      _animation = Tween<double>(begin: 0, end: 2 * 3.14159)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.linear))
        ..addListener(() {
          setState(() {});
        });

      _controller.repeat();
    } catch (e, stackTrace) {
      _log.severe('Error initializing loading animation', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error initializing loading animation'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _animation.value,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.size / 2),
          border: Border.all(
            color: widget.color,
            width: 4,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
          gradient: SweepGradient(
            center: Alignment.center,
            colors: [
              widget.color.withOpacity(0.1),
              widget.color,
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingPainter extends CustomPainter {
  final double progress;
  final Color color;

  LoadingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Draw background circle
    paint.color = color.withOpacity(0.2);
    canvas.drawCircle(center, radius, paint);

    // Draw progress arc
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5 * 3.14 + (progress * 2 * 3.14),
      0.7 * 3.14,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant LoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
// button_animation.dart
import 'package:flutter/material.dart';
import '../../presentation/themes/app_theme.dart';

class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const AnimatedButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.color = AppTheme.primaryColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    setState(() {
      _isPressed = true;
    });
    _controller.forward();
  }

  void _handleTapUp(_) {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: widget.borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(_isPressed ? 0.3 : 0.5),
                    blurRadius: _isPressed ? 5 : 10,
                    offset: Offset(0, _isPressed ? 2 : 5),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
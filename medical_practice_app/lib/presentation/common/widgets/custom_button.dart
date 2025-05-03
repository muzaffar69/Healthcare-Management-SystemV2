import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';

enum ButtonType { primary, secondary, text, success, warning, error }

class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final EdgeInsets padding;
  final double borderRadius;
  final bool isDisabled;
  final bool showAnimation;

  const CustomButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.type = ButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 50,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.borderRadius = 12,
    this.isDisabled = false,
    this.showAnimation = true,
  }) : super(key: key);

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppConstants.shortAnimationDuration),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isDisabled || !widget.showAnimation || widget.isLoading) return;
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isDisabled || !widget.showAnimation || widget.isLoading) return;
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _handleTapCancel() {
    if (widget.isDisabled || !widget.showAnimation || widget.isLoading) return;
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  Color _getButtonColor() {
    final theme = Theme.of(context);
    if (widget.isDisabled) {
      return theme.disabledColor;
    }

    switch (widget.type) {
      case ButtonType.primary:
        return AppTheme.primaryColor;
      case ButtonType.secondary:
        return Colors.transparent;
      case ButtonType.text:
        return Colors.transparent;
      case ButtonType.success:
        return AppTheme.success;
      case ButtonType.warning:
        return AppTheme.warning;
      case ButtonType.error:
        return AppTheme.error;
    }
  }

  Color _getTextColor() {
    final theme = Theme.of(context);
    if (widget.isDisabled) {
      return theme.disabledColor.withOpacity(0.7);
    }

    switch (widget.type) {
      case ButtonType.primary:
      case ButtonType.success:
      case ButtonType.warning:
      case ButtonType.error:
        return Colors.white;
      case ButtonType.secondary:
        return AppTheme.primaryColor;
      case ButtonType.text:
        return AppTheme.primaryColor;
    }
  }

  BorderSide _getBorderSide() {
    if (widget.isDisabled) {
      return BorderSide.none;
    }

    switch (widget.type) {
      case ButtonType.primary:
      case ButtonType.success:
      case ButtonType.warning:
      case ButtonType.error:
      case ButtonType.text:
        return BorderSide.none;
      case ButtonType.secondary:
        return BorderSide(color: AppTheme.primaryColor, width: 1.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: Container(
          width: widget.isFullWidth ? double.infinity : null,
          height: widget.height,
          decoration: BoxDecoration(
            color: _getButtonColor(),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.fromBorderSide(_getBorderSide()),
            boxShadow: widget.type != ButtonType.text && !widget.isDisabled
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (widget.isDisabled || widget.isLoading) ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              splashColor: widget.type != ButtonType.text
                  ? Colors.white.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.1),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: widget.padding,
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: _getTextColor(),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: _getTextColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

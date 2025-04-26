import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final bool autofocus;
  final bool showFilterButton;
  final VoidCallback? onFilterPressed;

  const SearchBar({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    this.autofocus = false,
    this.showFilterButton = false,
    this.onFilterPressed,
  }) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;
  bool _isExpanded = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _widthAnimation = Tween<double>(
      begin: 56,
      end: 300,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _expand();
      });
    }

    widget.controller.addListener(() {
      if (widget.controller.text.isNotEmpty && !_isExpanded) {
        _expand();
      }
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_isExpanded) {
        _expand();
      } else if (!_focusNode.hasFocus && widget.controller.text.isEmpty) {
        _collapse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() {
      _isExpanded = true;
    });
    _animationController.forward();
    _focusNode.requestFocus();
  }

  void _collapse() {
    if (widget.controller.text.isEmpty) {
      setState(() {
        _isExpanded = false;
      });
      _animationController.reverse();
    }
  }

  void _clearSearch() {
    widget.controller.clear();
    widget.onChanged('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.textColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(Icons.search),
                  color: _isExpanded ? AppTheme.primaryColor : AppTheme.textLightColor,
                  onPressed: () {
                    if (!_isExpanded) {
                      _expand();
                    } else {
                      widget.onSubmitted(widget.controller.text);
                    }
                  },
                ),
              ),
              if (_isExpanded || _animationController.value > 0)
                Expanded(
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: AppTheme.textLightColor),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                    ),
                  ),
                ),
              if (_isExpanded && widget.controller.text.isNotEmpty)
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    color: AppTheme.textLightColor,
                    onPressed: _clearSearch,
                    iconSize: 20,
                  ),
                ),
              if (_isExpanded && widget.showFilterButton)
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Icons.filter_list),
                    color: AppTheme.primaryColor,
                    onPressed: widget.onFilterPressed,
                    iconSize: 20,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
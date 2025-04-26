// search_bar_animation.dart
import 'package:flutter/material.dart';
import '../../presentation/themes/app_theme.dart';

class AnimatedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;

  const AnimatedSearchBar({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
  }) : super(key: key);

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _widthAnimation = Tween<double>(
      begin: 60,
      end: 300,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    widget.controller.addListener(() {
      if (widget.controller.text.isNotEmpty && !_isExpanded) {
        _expand();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() {
      _isExpanded = true;
    });
    _controller.forward();
  }

  void _collapse() {
    if (widget.controller.text.isEmpty) {
      setState(() {
        _isExpanded = false;
      });
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppTheme.textColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(Icons.search),
                  color: _isExpanded ? AppTheme.primaryColor : AppTheme.textLightColor,
                  onPressed: () {
                    if (!_isExpanded) {
                      _expand();
                      FocusScope.of(context).requestFocus(FocusNode());
                    } else {
                      widget.onSubmitted(widget.controller.text);
                    }
                  },
                ),
              ),
              if (_isExpanded || _controller.value > 0)
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      border: InputBorder.none,
                      hintStyle: const TextStyle(color: AppTheme.textLightColor),
                    ),
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                  ),
                ),
              if (_isExpanded)
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    color: AppTheme.textLightColor,
                    onPressed: () {
                      widget.controller.clear();
                      _collapse();
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

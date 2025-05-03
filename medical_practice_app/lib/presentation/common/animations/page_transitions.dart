import 'package:flutter/material.dart';
import '../../../config/constants.dart';

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;
  final Duration duration;
  final Curve curve;
  
  SlidePageRoute({
    required this.page,
    this.direction = SlideDirection.right,
    this.duration = const Duration(milliseconds: AppConstants.mediumAnimationDuration),
    this.curve = Curves.easeInOutCubic,
    RouteSettings? settings,
  }) : super(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var begin = Offset.zero;
      
      switch (direction) {
        case SlideDirection.right:
          begin = const Offset(-1.0, 0.0);
          break;
        case SlideDirection.left:
          begin = const Offset(1.0, 0.0);
          break;
        case SlideDirection.up:
          begin = const Offset(0.0, 1.0);
          break;
        case SlideDirection.down:
          begin = const Offset(0.0, -1.0);
          break;
      }
      
      const end = Offset.zero;
      
      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );
      
      var offsetAnimation = animation.drive(tween);
      
      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
    transitionDuration: duration,
  );
}

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Curve curve;
  
  FadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: AppConstants.mediumAnimationDuration),
    this.curve = Curves.easeIn,
    RouteSettings? settings,
  }) : super(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: curve,
        ),
        child: child,
      );
    },
    transitionDuration: duration,
  );
}

class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Curve curve;
  final Alignment alignment;
  
  ScalePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: AppConstants.mediumAnimationDuration),
    this.curve = Curves.easeInOutCubic,
    this.alignment = Alignment.center,
    RouteSettings? settings,
  }) : super(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: curve,
        ),
        alignment: alignment,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
    transitionDuration: duration,
  );
}

class SlideScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;
  final Duration duration;
  final Curve curve;
  
  SlideScalePageRoute({
    required this.page,
    this.direction = SlideDirection.right,
    this.duration = const Duration(milliseconds: AppConstants.mediumAnimationDuration),
    this.curve = Curves.easeInOutCubic,
    RouteSettings? settings,
  }) : super(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var begin = Offset.zero;
      
      switch (direction) {
        case SlideDirection.right:
          begin = const Offset(-0.5, 0.0);
          break;
        case SlideDirection.left:
          begin = const Offset(0.5, 0.0);
          break;
        case SlideDirection.up:
          begin = const Offset(0.0, 0.5);
          break;
        case SlideDirection.down:
          begin = const Offset(0.0, -0.5);
          break;
      }
      
      const end = Offset.zero;
      
      var slideTween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );
      
      var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
        CurveTween(curve: curve),
      );
      
      var offsetAnimation = animation.drive(slideTween);
      var scaleAnimation = animation.drive(scaleTween);
      
      return SlideTransition(
        position: offsetAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
      );
    },
    transitionDuration: duration,
  );
}

enum SlideDirection {
  right,  // Slide from right to left (page enters from right)
  left,   // Slide from left to right (page enters from left)
  up,     // Slide from bottom to top (page enters from bottom)
  down,   // Slide from top to bottom (page enters from top)
}

class HeroPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  
  HeroPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: AppConstants.mediumAnimationDuration),
    RouteSettings? settings,
  }) : super(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: duration,
  );
}

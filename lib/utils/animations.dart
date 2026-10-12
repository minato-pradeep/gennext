import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PageAnimations {
  // Slide transition from right
  static Route<T> slideRight<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: AppTheme.animationPage,
    );
  }
  
  // Slide transition from left
  static Route<T> slideLeft<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: AppTheme.animationPage,
    );
  }
  
  // Fade transition
  static Route<T> fade<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
          child: child,
        );
      },
      transitionDuration: AppTheme.animationNormal,
    );
  }
  
  // Scale transition
  static Route<T> scale<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(CurveTween(curve: Curves.easeOutBack)),
          child: child,
        );
      },
      transitionDuration: AppTheme.animationNormal,
    );
  }
}

class WidgetAnimations {
  // Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = AppTheme.animationNormal,
    Curve curve = Curves.easeOut,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }
  
  // Slide up animation
  static Widget slideUp({
    required Widget child,
    Duration duration = AppTheme.animationNormal,
    Curve curve = Curves.easeOut,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return SlideTransition(position: value as Animation<Offset>, child: child);
      },
      child: child,
    );
  }
  
  // Scale animation on tap
  static Widget scaleOnTap({
    required Widget child,
    required VoidCallback onTap,
    Duration duration = AppTheme.animationFast,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        duration: duration,
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: child,
      ),
    );
  }
}
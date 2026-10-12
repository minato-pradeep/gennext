import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/haptic_service.dart';

class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  
  const AnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = 50,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AppTheme.animationFast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ?? 
        (isDark ? AppTheme.brand(context) : AppTheme.brand(context));
    final textColor = widget.textColor ?? Colors.white;
    
    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : () async {
          await HapticService.light();
          _scaleController.forward();
          await Future.delayed(AppTheme.animationFast);
          _scaleController.reverse();
          widget.onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
          minimumSize: widget.isFullWidth
              ? Size(widget.width ?? double.infinity, widget.height)
              : Size(widget.width ?? 120, widget.height),
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.radiusM,
          ),
        ),
        child: widget.isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : Row(
                mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18),
                    const SizedBox(width: AppTheme.spacingS),
                  ],
                  Text(
                    widget.text,
                    style: AppTheme.buttonText.copyWith(color: textColor),
                  ),
                ],
              ),
      ),
    );
    
    return button;
  }
}
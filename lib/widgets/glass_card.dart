import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool withBorder;
  
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.withBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget card = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingL),
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard.withOpacity(0.8) : Colors.white,
        borderRadius: AppTheme.radiusL,
        border: withBorder ? Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
          width: 0.5,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
    
    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.radiusL,
          child: card,
        ),
      );
    }
    
    return card;
  }
}

class GlassMorphicCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  
  const GlassMorphicCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget card = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
              : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
        ),
        borderRadius: AppTheme.radiusL,
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppTheme.radiusL,
        child: BackdropFilter(
          filter: isDark
              ? throw UnimplementedError()
              : throw UnimplementedError(),
          child: child,
        ),
      ),
    );
    
    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.radiusL,
          child: card,
        ),
      );
    }
    
    return card;
  }
}
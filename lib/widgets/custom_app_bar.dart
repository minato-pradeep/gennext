import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final bool withGradient;
  
  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.withGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: withGradient && !isDark
            ? AppTheme.brandGradient(context)
            : null,
        color: backgroundColor ?? (isDark ? AppTheme.darkSurface : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingL,
            vertical: AppTheme.spacingS,
          ),
          child: Row(
            children: [
              if (showBackButton)
                GestureDetector(
                  onTap: () {
                    if (onBackPressed != null) {
                      onBackPressed!();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: AppTheme.radiusM,
                    ),
                    child: const Icon(Icons.arrow_back_ios, size: 18),
                  ),
                ),
              if (leading != null) leading!,
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.titleLarge.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(70);
}
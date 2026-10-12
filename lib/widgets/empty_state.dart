import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.onAction,
    this.actionText,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: (iconColor ?? AppTheme.brand(context)).withOpacity(0.1),
              borderRadius: AppTheme.radiusXL,
            ),
            child: Icon(
              icon,
              size: 50,
              color: iconColor ?? (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppTheme.titleLarge.copyWith(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTheme.bodyMedium.copyWith(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionText != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionText!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brand(context),
                shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusM),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
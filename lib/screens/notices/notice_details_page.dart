import 'package:flutter/material.dart';
import '../../models/notice.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/glass_card.dart';

class NoticeDetailsPage extends StatelessWidget {
  final Notice notice;
  final String userRole;
  final String userName;

  const NoticeDetailsPage({
    super.key,
    required this.notice,
    required this.userRole,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = userRole.toLowerCase() == 'master' || 
                    userRole.toLowerCase() == 'admin' ||
                    notice.createdBy == userName;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: Text('Notice Details', style: AppTheme.titleLarge.copyWith(color: Colors.white)),
        backgroundColor: notice.priorityColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusL),
                    title: const Text('Delete Notice'),
                    content: Text('Are you sure you want to delete "${notice.title}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notice deleted'), backgroundColor: AppTheme.success),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                    : [const Color(0xFFE8F4FD), const Color(0xFFD6EEFC), const Color(0xFFC5E8FB)],
              ),
            ),
          ),
          
          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: notice.priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(notice.priorityIcon, color: notice.priorityColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          notice.tags.contains('urgent') ? 'URGENT NOTICE' : 
                          (notice.tags.contains('important') ? 'IMPORTANT NOTICE' :
                          (notice.tags.contains('event') ? 'EVENT' : 'NOTICE')),
                          style: AppTheme.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: notice.priorityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    notice.title,
                    style: AppTheme.heading3.copyWith(
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Meta Info
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Posted by', style: AppTheme.caption),
                              const SizedBox(height: 4),
                              Text(notice.createdBy, style: AppTheme.titleSmall),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date', style: AppTheme.caption),
                              const SizedBox(height: 4),
                              Text(notice.formattedDateTime, style: AppTheme.titleSmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Description
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description', style: AppTheme.titleMedium),
                        const SizedBox(height: 12),
                        Text(
                          notice.description,
                          style: AppTheme.bodyMedium.copyWith(
                            height: 1.6,
                            color: isDark ? AppTheme.darkTextSecondary : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (notice.expiryDate != null) ...[
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Row(
                        children: [
                          const Icon(Icons.timer, color: AppTheme.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Expiry Date', style: AppTheme.caption),
                                const SizedBox(height: 4),
                                Text(
                                  '${notice.expiryDate!.day}/${notice.expiryDate!.month}/${notice.expiryDate!.year}',
                                  style: AppTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Close Button
                  AnimatedButton(
                    text: 'Close',
                    onPressed: () => Navigator.pop(context),
                    backgroundColor: AppTheme.brand(context),
                    isFullWidth: true,
                    height: 48,
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
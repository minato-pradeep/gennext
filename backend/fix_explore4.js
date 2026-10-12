const fs = require('fs');
let c = fs.readFileSync('../lib/screens/explore_page.dart', 'utf8');

// Find the broken spot - after events block closes, insert missing options + return
const insertAfter = `        description: 'Create and manage community events'));\n    }\n`;
const missingOptions = `
    if (isAdminOrMaster) {
      allOptions.add(ExploreOption(id: 16, title: 'Create Payment', icon: Icons.add_card,
        imagePath: 'assets/icons/payments.png', iconColor: AppTheme.secondaryGreen,
        gradientColors: [AppTheme.secondaryGreen, AppTheme.secondaryDarkGreen],
        description: 'Create new bills'));
    }
    if (permissionService.hasPermission('payments')) {
      allOptions.add(ExploreOption(id: 7, title: 'Payments', icon: Icons.payments,
        imagePath: 'assets/icons/payments.png', iconColor: const Color(0xFF607D8B),
        gradientColors: [const Color(0xFF607D8B), const Color(0xFF455A64)],
        description: 'Pay your bills, download receipts'));
    }
    if (permissionService.hasPermission('visitors')) {
      allOptions.add(ExploreOption(id: 8, title: 'Visitors', icon: Icons.people,
        imagePath: 'assets/icons/visitors.png', iconColor: AppTheme.success,
        gradientColors: [AppTheme.success, const Color(0xFF388E3C)],
        description: 'Register visitors for your apartment'));
    }
    if (permissionService.hasPermission('visitorApproval')) {
      allOptions.add(ExploreOption(id: 9, title: 'Visitor Approval', icon: Icons.security,
        imagePath: 'assets/icons/visitor_approval.png', iconColor: AppTheme.error,
        gradientColors: [AppTheme.error, const Color(0xFFC62828)],
        description: 'Approve visitor entries'));
    }
    if (permissionService.hasPermission('polls')) {
      allOptions.add(ExploreOption(id: 10, title: 'Polls', icon: Icons.poll,
        imagePath: 'assets/icons/polls.png', iconColor: AppTheme.accentTeal,
        gradientColors: [AppTheme.accentTeal, const Color(0xFF00695C)],
        description: 'Community voting and polls'));
    }
    if (permissionService.hasPermission('maintenance')) {
      allOptions.add(ExploreOption(id: 12, title: 'Create Notice', icon: Icons.announcement,
        imagePath: 'assets/icons/maintenance.png', iconColor: AppTheme.primaryBlue,
        gradientColors: [AppTheme.primaryBlue, AppTheme.primaryDarkBlue],
        description: 'Create announcements for the community'));
    }
    if (permissionService.hasPermission('noticeBoard')) {
      allOptions.add(ExploreOption(id: 13, title: 'Notice Board', icon: Icons.announcement,
        imagePath: 'assets/icons/notice_board.png', iconColor: AppTheme.info,
        gradientColors: [AppTheme.info, const Color(0xFF1976D2)],
        description: 'View official announcements'));
    }
    if (isAdminOrMaster) {
      allOptions.add(ExploreOption(id: 15, title: 'Payment Manage', icon: Icons.analytics,
        imagePath: 'assets/icons/payments.png', iconColor: AppTheme.accentPurple,
        gradientColors: [AppTheme.accentPurple, const Color(0xFF7B1FA2)],
        description: 'View all members payment status'));
    }
    allOptions.add(ExploreOption(id: 99, title: 'App Master', icon: Icons.admin_panel_settings,
      imagePath: 'assets/icons/nextgen_icon.png', iconColor: const Color(0xFF9C27B0),
      gradientColors: [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)],
      description: 'Manage users and permissions'));
    return allOptions;
  }

  Map<String, String> getUserProfile() {
    return {
      'name': widget.userName, 'role': widget.userRole,
      'phone': '+91 98765 43210', 'unitNumber': 'A-101',
      'address': 'BlueBug Community', 'memberSince': 'January 2024',
      'panNumber': 'ABCDE1234F', 'aadharNumber': 'XXXX-XXXX-1234',
      'vehicleNumber': 'MH 01 AB 1234', 'email': 'user@bluebug.com',
    };
  }
  String getUserPhone() => '+91 98765 43210';
  String getUserId() => '2';

`;

c = c.replace(insertAfter, insertAfter + missingOptions);
fs.writeFileSync('../lib/screens/explore_page.dart', c, 'utf8');
console.log('done');

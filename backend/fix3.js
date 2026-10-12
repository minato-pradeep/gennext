const fs = require('fs');
let c = fs.readFileSync('../lib/screens/explore_page.dart', 'utf8');

const insertBefore = '  @override\n  Widget build(BuildContext context) {';

const methods = `
  Map<String, String> getUserProfile() => {
    'name': widget.userName, 'role': widget.userRole,
    'phone': '+91 98765 43210', 'unitNumber': 'A-101',
    'address': 'BlueBug Community', 'memberSince': 'January 2024',
    'panNumber': 'ABCDE1234F', 'aadharNumber': 'XXXX-XXXX-1234',
    'vehicleNumber': 'MH 01 AB 1234', 'email': 'user@bluebug.com',
  };
  String getUserPhone() => '+91 98765 43210';
  String getUserId() => '2';

  void _showProfileSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = getUserProfile();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: DraggableScrollableSheet(initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.9, expand: false,
          builder: (_, sc) => ListView(controller: sc, padding: const EdgeInsets.all(20), children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            Row(children: [
              Container(width: 60, height: 60, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.white, size: 32)),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(profile['name']!, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(profile['role']!, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.primaryBlue)),
              ]),
            ]),
            const SizedBox(height: 20),
            _pTile(Icons.phone, 'Phone', profile['phone']!, isDark),
            _pTile(Icons.apartment, 'Unit', profile['unitNumber']!, isDark),
            _pTile(Icons.home, 'Address', profile['address']!, isDark),
            _pTile(Icons.calendar_today, 'Member Since', profile['memberSince']!, isDark),
          ]),
        ),
      ),
    );
  }

  Widget _pTile(IconData icon, String label, String value, bool isDark) {
    return Padding(padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: Colors.white)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45)),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ]));
  }

  void _showOptionDetail(BuildContext context, ExploreOption option) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(gradient: LinearGradient(colors: option.gradientColors), borderRadius: BorderRadius.circular(14)),
              child: Icon(option.icon, color: Colors.white, size: 26)),
            const SizedBox(width: 14),
            Expanded(child: Text(option.title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700))),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 12),
          Text(option.description, style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 24),
          if (option.id == 1) _buildEmergencyOption(context),
          if (option.id == 2) _buildBuySellOptions(context),
          if (option.id == 3) AnimatedButton(text: 'Raise a Complaint', onPressed: () { Navigator.pop(context); Navigator.push(context, PageAnimations.slideRight(RaiseComplaintPage(userRole: widget.userRole, userName: widget.userName, userProfile: getUserProfile()))); }, icon: Icons.report_problem, backgroundColor: AppTheme.accentOrange, isFullWidth: true),
          if (option.id == 4) AnimatedButton(text: 'View All Complaints', onPressed: () { Navigator.pop(context); Navigator.push(context, PageAnimations.slideRight(AllComplaintsPage(userRole: widget.userRole, userName: widget.userName))); }, icon: Icons.list_alt, backgroundColor: AppTheme.accentPurple, isFullWidth: true),
          if (option.id == 14) AnimatedButton(text: 'Check Complaints', onPressed: () { Navigator.pop(context); Navigator.push(context, PageAnimations.slideRight(CheckComplaintPage(userRole: widget.userRole, userName: widget.userName))); }, icon: Icons.edit_note, backgroundColor: AppTheme.primaryBlue, isFullWidth: true),
          if (option.id == 5) AnimatedButton(text: 'Create New Event', onPressed: () { Navigator.pop(context); Navigator.push(context, PageAnimations.slideRight(CreateEventPage(userRole: widget.userRole, userName: widget.userName))); }, icon: Icons.add, backgroundColor: AppTheme.primaryBlue, isFullWidth: true),
          if (option.id == 6) AnimatedButton(text: 'Book Facilities', onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon!'))); }, icon: Icons.fitness_center, backgroundColor: AppTheme.accentTeal, isFullWidth: true),
          if (option.id == 16) AnimatedButton(text: 'Create New Bill', onPressed: () { Navigator.pop(context); Navigator.push(context, PageAnimations.slideRight(CreatePaymentPage(userName: widget.userName, userRole: widget.userRole))); }, icon: Icons.add_card, backgroundColor: AppTheme.secondaryGreen, isFullWidth: true),
          if (option.id == 7) AnimatedButton(text: 'Go to Payments', onPressed: () { Navigator.pop(context); Navigator.push(context, PageAnimations.slideRight(PaymentDashboard(userId: getUserId(), userName: widget.userName, userRole: widget.userRole, apartment: 'A-101', phone: getUserPhone()))); }, icon: Icons.payment, backgroundColor: const Color(0xFF607D8B), isFullWidth: true),
          if (option.id == 8) AnimatedButton(text: 'Register New Visitor', onPressed: () { Navigator.pop(context); Navigator.push(context, PageAnimations.slideRight(VisitorFormPage(userRole: widget.userRole, userName: widget.userName, userProfile: getUserProfile()))); }, icon: Icons.people, backgroundColor: AppTheme.success, isFullWidth: true),
          if (option.id == 9) AnimatedButton(text: 'Visitor Approval', onPressed: () { Navigator.pop(context); Navigator.push(context, PageAnimations.slideRight(VisitorApprovalPage(userRole: widget.userRole, userName: widget.userName))); }, icon: Icons.security, backgroundColor: AppTheme.error, isFullWidth: true),
          if (option.id == 10) AnimatedButton(text: 'Go to Polls', onPressed: () { Navigator.pop(context); Navigator.push(context, PageAnimations.slideRight(PollsPage(userRole: widget.userRole, userName: widget.userName, userProfile: getUserProfile(), isAdmin: false))); }, icon: Icons.poll, backgroundColor: AppTheme.accentTeal, isFullWidth: true),
          if (option.id == 12) AnimatedButton(text: 'Create New Notice', onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => CreateNoticePage(userName: widget.userName, userRole: widget.userRole))); }, icon: Icons.announcement, backgroundColor: AppTheme.primaryBlue, isFullWidth: true),
          if (option.id == 13) AnimatedButton(text: 'Go to Notice Board', onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => NoticeBoardPage(userRole: widget.userRole, userName: widget.userName))); }, icon: Icons.notifications, backgroundColor: AppTheme.info, isFullWidth: true),
          if (option.id == 15) AnimatedButton(text: 'Payment Management', onPressed: () { Navigator.pop(context); Navigator.push(context, PageAnimations.slideRight(PaymentManagementPage(userRole: widget.userRole, userName: widget.userName))); }, icon: Icons.analytics, backgroundColor: AppTheme.accentPurple, isFullWidth: true),
          if (option.id == 99) AnimatedButton(text: 'Go to Master Login', onPressed: () { Navigator.pop(context); Navigator.of(context).pushNamed('/login'); }, icon: Icons.admin_panel_settings, backgroundColor: const Color(0xFF9C27B0), isFullWidth: true),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _buildEmergencyOption(BuildContext context) => Column(children: [
    AnimatedButton(text: 'View Emergency Numbers', onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyNumbersPage())); }, icon: Icons.emergency, backgroundColor: const Color(0xFFB71C1C), isFullWidth: true),
    const SizedBox(height: 12),
    AnimatedButton(text: 'Setup SOS Contacts', onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SosSetupScreen())); }, icon: Icons.contacts, backgroundColor: const Color(0xFF880E4F), isFullWidth: true),
    const SizedBox(height: 12),
    AnimatedButton(text: 'Trigger SOS Now', onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SosActiveScreen())); }, icon: Icons.warning_rounded, backgroundColor: const Color(0xFF4A0000), isFullWidth: true),
  ]);

  Widget _buildBuySellOptions(BuildContext context) => Column(children: [
    AnimatedButton(text: 'Sell an Item', onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => SellItemPage(userRole: widget.userRole, userName: widget.userName, userProfile: getUserProfile()))); }, icon: Icons.sell, backgroundColor: AppTheme.secondaryGreen, isFullWidth: true),
    const SizedBox(height: 12),
    AnimatedButton(text: 'Buy Items', onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => BuyItemsPage(userRole: widget.userRole, userName: widget.userName, userProfile: getUserProfile()))); }, icon: Icons.shopping_cart, backgroundColor: AppTheme.primaryBlue, isFullWidth: true),
  ]);

`;

c = c.replace(insertBefore, methods + insertBefore);
fs.writeFileSync('../lib/screens/explore_page.dart', c, 'utf8');
console.log('done');

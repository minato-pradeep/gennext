import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/permission_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/animations.dart';
import 'visitor_form_page.dart';
import 'visitor_approval_page.dart';
import 'raise_complaint_page.dart';
import 'all_complaints_page.dart';
import 'check_complaint_page.dart';
import 'sell_item_page.dart';
import 'polls_page.dart';
import 'events_list_page.dart';
import 'hall_booking_page.dart';
import 'payments/payment_dashboard.dart';
import 'payments/payment_management_page.dart';
import 'notices/create_notice_page.dart';
import 'notices/notice_board_page.dart';
import 'buy_items_page.dart';
import 'profile_page.dart';
import 'rent/rent_rentout_page.dart';
import 'maid_servant_page.dart';
import '../widgets/animated_button.dart';

class ExplorePage extends StatefulWidget {
  final String userRole;
  final String userName;

  const ExplorePage({
    super.key,
    required this.userRole,
    required this.userName,
  });

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with TickerProviderStateMixin {
  double _scrollOffset = 0;
  int? _expandedIndex;
  late AnimationController _gridController;
  late Animation<double> _gridAnimation;
  final ScrollController _scrollController = ScrollController();
  int _navIndex = 1; // Community tab

  @override
  void initState() {
    super.initState();
    _gridController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _gridAnimation =
        CurvedAnimation(parent: _gridController, curve: Curves.easeOut);
    _gridController.forward();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _gridController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, String> get _userProfile => {
        'name': widget.userName,
        'role': widget.userRole,
        'phone': '',
        'unitNumber': '',
        'apartment': '',
        'id': '',
      };

  List<ExploreOption> get _exploreOptions {
    final permissionService = PermissionService();
    final normalizedRole = widget.userRole.toLowerCase();
    final isOwnerOrSecurity =
        (normalizedRole == 'owner' || normalizedRole == 'security');
    final isAdminOrMaster = (normalizedRole == 'master' ||
        normalizedRole == 'admin' ||
        normalizedRole == 'owner');

    final List<ExploreOption> allOptions = [];

    if (permissionService.hasPermission('buySell')) {
      allOptions.add(ExploreOption(
          id: 2,
          title: 'Buy & Sell',
          icon: Icons.storefront,
          imagePath: 'assets/icons/icon1.png',
          iconColor: AppTheme.brand(context),
          gradientColors: [
            AppTheme.brand(context),
            AppTheme.brandLight(context)
          ],
          description: 'Sell or buy items within community'));
    }
    if (permissionService.hasPermission('buySell')) {
      allOptions.add(ExploreOption(
          id: 16,
          title: 'Rent & Rentout',
          icon: Icons.house_rounded,
          imagePath: 'assets/icons/icon2.png',
          iconColor: const Color(0xFF7F56D9),
          gradientColors: [const Color(0xFF7F56D9), const Color(0xFF9E77ED)],
          description: 'Find a rental or list your property'));
    }
    if (permissionService.hasPermission('raiseComplaint')) {
      allOptions.add(ExploreOption(
          id: 3,
          title: 'Raise Complaint',
          icon: Icons.report_problem,
          imagePath: 'assets/icons/icon4.png',
          iconColor: AppTheme.brand(context),
          gradientColors: [
            AppTheme.brand(context),
            AppTheme.brandLight(context)
          ],
          description: 'Raise a complaint or view your complaint status'));
    }
    if (permissionService.hasPermission('checkComplaint') &&
        isOwnerOrSecurity) {
      allOptions.add(ExploreOption(
          id: 14,
          title: 'Check Complaints',
          icon: Icons.edit_note,
          imagePath: 'assets/icons/icon12.png',
          iconColor: AppTheme.brand(context),
          gradientColors: [
            AppTheme.brand(context),
            AppTheme.brandLight(context)
          ],
          description: 'Check and update complaint status'));
    }

    if (permissionService.hasPermission('maintenance')) {
      allOptions.add(ExploreOption(
          id: 5,
          title: 'Events',
          icon: Icons.event,
          imagePath: 'assets/icons/icon6.png',
          iconColor: AppTheme.brand(context),
          gradientColors: [
            AppTheme.brand(context),
            AppTheme.brandLight(context)
          ],
          description: 'Create and manage community events'));
    }

    if (permissionService.hasPermission('payments')) {
      allOptions.add(ExploreOption(
          id: 7,
          title: 'Demands',
          icon: Icons.payments,
          imagePath: 'assets/icons/icon7.png',
          iconColor: AppTheme.brand(context),
          gradientColors: [
            AppTheme.brand(context),
            AppTheme.brandLight(context)
          ],
          description: 'Pay your bills, download receipts'));
    }
    if (permissionService.hasPermission('visitors')) {
      allOptions.add(ExploreOption(
          id: 8,
          title: 'Visitors',
          icon: Icons.people,
          imagePath: 'assets/icons/icon13.png',
          iconColor: AppTheme.brand(context),
          gradientColors: [
            AppTheme.brand(context),
            AppTheme.brandLight(context)
          ],
          description: 'Register visitors for your apartment'));
    }
    if (permissionService.hasPermission('visitorApproval')) {
      allOptions.add(ExploreOption(
          id: 9,
          title: 'Visitor Approval',
          icon: Icons.security,
          imagePath: 'assets/icons/icon14.png',
          iconColor: AppTheme.brand(context),
          gradientColors: [
            AppTheme.brand(context),
            AppTheme.brandLight(context)
          ],
          description: 'Approve visitor entries'));
    }
    if (permissionService.hasPermission('polls')) {
      allOptions.add(ExploreOption(
          id: 10,
          title: 'Polls',
          icon: Icons.poll,
          imagePath: 'assets/icons/icon8.png',
          iconColor: AppTheme.brand(context),
          gradientColors: [
            AppTheme.brand(context),
            AppTheme.brandLight(context)
          ],
          description: 'Community voting and polls'));
    }
    if (permissionService.hasPermission('maintenance')) {
      allOptions.add(ExploreOption(
          id: 12,
          title: 'Create Notice',
          icon: Icons.announcement,
          imagePath: 'assets/icons/icon9.png',
          iconColor: AppTheme.brand(context),
          gradientColors: [
            AppTheme.brand(context),
            AppTheme.brandLight(context)
          ],
          description: 'Create announcements for the community'));
    }
    if (permissionService.hasPermission('noticeBoard')) {
      allOptions.add(ExploreOption(
          id: 13,
          title: 'Notice Board',
          icon: Icons.announcement,
          imagePath: 'assets/icons/icon10.png',
          iconColor: AppTheme.brand(context),
          gradientColors: [
            AppTheme.brand(context),
            AppTheme.brandLight(context)
          ],
          description: 'View official announcements'));
    }
    allOptions.add(ExploreOption(
        id: 17,
        title: 'Servant Maid',
        icon: Icons.cleaning_services_rounded,
        imagePath: 'assets/icons/icon13.png',
        iconColor: const Color(0xFF00897B),
        gradientColors: [const Color(0xFF00897B), const Color(0xFF4DB6AC)],
        description: 'Manage servant maid details'));
    allOptions.add(ExploreOption(
        id: 99,
        title: 'App Master',
        icon: Icons.key_rounded,
        imagePath: 'assets/icons/nextgen_icon.png',
        iconColor: const Color(0xFF7F56D9),
        gradientColors: [const Color(0xFF172033), const Color(0xFF1D2939)],
        description: 'Manage users and permissions'));
    return allOptions;
  }

  void _showDemandsSheet(
    BuildContext context, {
    required String userId,
    required String userName,
    required String userRole,
    required String apartment,
    required String phone,
  }) {
    void go(String category) {
      Navigator.pop(context);
      Navigator.push(
          context,
          PageAnimations.slideRight(PaymentDashboard(
            userId: userId,
            userName: userName,
            userRole: userRole,
            apartment: apartment,
            phone: phone,
            billCategory: category,
          )));
    }

    final brandColor = AppTheme.brand(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Demands',
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF172033)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select the type of demand to view',
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 13,
                  color: Color(0xFF667085)),
            ),
            const SizedBox(height: 24),
            // Row 1 — Maintenance Fee · Water Bill · Electricity Bill
            Row(
              children: [
                Expanded(
                  child: _demandOption(
                    context,
                    icon: Icons.build_circle_outlined,
                    label: 'Maintenance\nFee',
                    color: brandColor,
                    onTap: () => go('maintenance'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _demandOption(
                    context,
                    icon: Icons.water_drop_outlined,
                    label: 'Water\nBill',
                    color: const Color(0xFF0288D1),
                    onTap: () => go('water'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _demandOption(
                    context,
                    icon: Icons.flash_on_outlined,
                    label: 'Electricity\nBill',
                    color: const Color(0xFFF59E0B),
                    onTap: () => go('electricity'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Row 2 — All · Others
            Row(
              children: [
                Expanded(
                  child: _demandOption(
                    context,
                    icon: Icons.grid_view_rounded,
                    label: 'All',
                    color: const Color(0xFF10B981),
                    onTap: () => go('all'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _demandOption(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: 'Others',
                    color: const Color(0xFF7F56D9),
                    onTap: () => go('others'),
                  ),
                ),
                // spacer so "All" + "Others" stay left-aligned like 2 of 3
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _demandOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> getUserProfile() {
    return {
      'name': widget.userName,
      'role': widget.userRole,
      'phone': '+91 98765 43210',
      'unitNumber': 'A-101',
      'address': 'BlueBug Community',
      'memberSince': 'January 2024',
      'panNumber': 'ABCDE1234F',
      'aadharNumber': 'XXXX-XXXX-1234',
      'vehicleNumber': 'MH 01 AB 1234',
      'email': 'user@bluebug.com',
    };
  }

  String getUserPhone() => '+91 98765 43210';
  String getUserId() => '2';

  void _showProfileSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = getUserProfile();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28))),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, sc) => ListView(
              controller: sc,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2)))),
                Row(children: [
                  Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                          gradient: AppTheme.brandGradient(context),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 32)),
                  const SizedBox(width: 16),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile['name']!,
                            style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF172033))),
                        Text(profile['role']!,
                            style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 13,
                                color: AppTheme.brand(context))),
                      ]),
                ]),
                const SizedBox(height: 20),
                _pTile(Icons.phone, 'Phone', profile['phone']!, isDark),
                _pTile(Icons.apartment, 'Unit', profile['unitNumber']!, isDark),
                _pTile(Icons.home, 'Address', profile['address']!, isDark),
                _pTile(Icons.calendar_today, 'Member Since',
                    profile['memberSince']!, isDark),
              ]),
        ),
      ),
    );
  }

  Widget _pTile(IconData icon, String label, String value, bool isDark) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient(context),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: Colors.white)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 11,
                    color: isDark ? Colors.white54 : const Color(0xFF667085))),
            Text(value,
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF172033))),
          ]),
        ]));
  }

  void _showOptionDetail(BuildContext context, ExploreOption option) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.all(24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: option.gradientColors),
                        borderRadius: AppTheme.radiusL),
                    child: Icon(option.icon, color: Colors.white, size: 26)),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(option.title,
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor(context)))),
                IconButton(
                    icon: Icon(Icons.close, color: AppTheme.textColor(context)),
                    onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 12),
              Text(option.description,
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 13,
                      color: AppTheme.textColor(context).withOpacity(0.6))),
              const SizedBox(height: 24),
              if (option.id == 2) _buildBuySellOptions(context),
              if (option.id == 3) ...[
                AnimatedButton(
                    text: 'Raise a Complaint',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          PageAnimations.slideRight(RaiseComplaintPage(
                              userRole: widget.userRole,
                              userName: widget.userName,
                              userProfile: getUserProfile())));
                    },
                    icon: Icons.report_problem,
                    backgroundColor: AppTheme.brand(context),
                    isFullWidth: true),
                const SizedBox(height: 12),
                AnimatedButton(
                    text: 'View My Complaints',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          PageAnimations.slideRight(AllComplaintsPage(
                              userRole: widget.userRole,
                              userName: widget.userName)));
                    },
                    icon: Icons.list_alt,
                    backgroundColor: AppTheme.brand(context),
                    isFullWidth: true),
              ],
              if (option.id == 14)
                AnimatedButton(
                    text: 'Check Complaints',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          PageAnimations.slideRight(CheckComplaintPage(
                              userRole: widget.userRole,
                              userName: widget.userName)));
                    },
                    icon: Icons.edit_note,
                    backgroundColor: AppTheme.brand(context),
                    isFullWidth: true),
              if (option.id == 5) ...[
                AnimatedButton(
                    text: 'All Events',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          PageAnimations.slideRight(EventsListPage(
                              userRole: widget.userRole,
                              userName: widget.userName,
                              isAdmin: true)));
                    },
                    icon: Icons.event,
                    backgroundColor: AppTheme.brand(context),
                    isFullWidth: true),
                const SizedBox(height: 12),
                AnimatedButton(
                    text: 'Book a Hall',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          PageAnimations.slideRight(
                              HallBookingPage(userName: widget.userName)));
                    },
                    icon: Icons.meeting_room_outlined,
                    backgroundColor: AppTheme.brand(context),
                    isFullWidth: true),
              ],
              if (option.id == 7)
                AnimatedButton(
                    text: 'View Demands',
                    onPressed: () {
                      Navigator.pop(context);
                      _showDemandsSheet(
                        context,
                        userId: getUserId(),
                        userName: widget.userName,
                        userRole: widget.userRole,
                        apartment: 'A-101',
                        phone: getUserPhone(),
                      );
                    },
                    icon: Icons.receipt_long,
                    backgroundColor: AppTheme.brand(context),
                    isFullWidth: true),
              if (option.id == 16)
                AnimatedButton(
                    text: 'Find a Rental & List My Property',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          PageAnimations.slideRight(RentRentoutPage(
                              userName: widget.userName,
                              userRole: widget.userRole,
                              userProfile: getUserProfile())));
                    },
                    icon: Icons.house_rounded,
                    backgroundColor: AppTheme.brand(context),
                    isFullWidth: true),
              if (option.id == 8)
                AnimatedButton(
                    text: 'Register New Visitor',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          PageAnimations.slideRight(VisitorFormPage(
                              userRole: widget.userRole,
                              userName: widget.userName,
                              userProfile: getUserProfile())));
                    },
                    icon: Icons.people,
                    backgroundColor: AppTheme.brand(context),
                    isFullWidth: true),
              if (option.id == 9)
                AnimatedButton(
                    text: 'Visitor Approval',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          PageAnimations.slideRight(VisitorApprovalPage(
                              userRole: widget.userRole,
                              userName: widget.userName)));
                    },
                    icon: Icons.security,
                    backgroundColor: AppTheme.brand(context),
                    isFullWidth: true),
              if (option.id == 10)
                AnimatedButton(
                    text: 'Go to Polls',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          PageAnimations.slideRight(PollsPage(
                              userRole: widget.userRole,
                              userName: widget.userName,
                              userProfile: getUserProfile(),
                              isAdmin: false)));
                    },
                    icon: Icons.poll,
                    backgroundColor: AppTheme.brand(context),
                    isFullWidth: true),
              if (option.id == 12)
                AnimatedButton(
                    text: 'Create New Notice',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CreateNoticePage(
                                  userName: widget.userName,
                                  userRole: widget.userRole)));
                    },
                    icon: Icons.announcement,
                    backgroundColor: AppTheme.brand(context),
                    isFullWidth: true),
              if (option.id == 13)
                AnimatedButton(
                    text: 'Go to Notice Board',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => NoticeBoardPage(
                                  userRole: widget.userRole,
                                  userName: widget.userName)));
                    },
                    icon: Icons.notifications,
                    backgroundColor: AppTheme.brand(context),
                    isFullWidth: true),
              if (option.id == 17) ...[
                AnimatedButton(
                    text: 'Maid Details',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          PageAnimations.slideRight(MaidDetailsPage(
                              userRole: widget.userRole,
                              userName: widget.userName)));
                    },
                    icon: Icons.cleaning_services_rounded,
                    backgroundColor: const Color(0xFF00695C),
                    isFullWidth: true),
              ],
              if (option.id == 99) _appMasterLoginBtn(context),
              const SizedBox(height: 16),
            ]),
      ),
    );
  }

  Widget _buildBuySellOptions(BuildContext context) => Column(children: [
        AnimatedButton(
            text: 'Sell an Item',
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SellItemPage(
                          userRole: widget.userRole,
                          userName: widget.userName,
                          userProfile: getUserProfile())));
            },
            icon: Icons.sell,
            backgroundColor: AppTheme.brand(context),
            isFullWidth: true),
        const SizedBox(height: 12),
        AnimatedButton(
            text: 'Buy Items',
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BuyItemsPage(
                          userRole: widget.userRole,
                          userName: widget.userName,
                          userProfile: getUserProfile())));
            },
            icon: Icons.shopping_cart,
            backgroundColor: AppTheme.brand(context),
            isFullWidth: true),
      ]);

  Widget _appMasterLoginBtn(BuildContext context) {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('App Master Login',
                style: TextStyle(
                    fontFamily: 'Arial Narrow', fontWeight: FontWeight.w700)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: userCtrl,
                  decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 12),
              TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)))),
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brand(context)),
                onPressed: () async {
                  final username = userCtrl.text.trim().toLowerCase();
                  final password = passCtrl.text.trim();

                  // Local Hardcoded Defaults (Bypass API)
                  if ((username == 'macs' && password == 'macs') ||
                      (username == 'master' && password == 'master')) {
                    // Close dialog first, then navigate after a short delay
                    Navigator.of(context).pop();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (context.mounted) {
                        Navigator.of(context)
                            .pushNamed('/app_master', arguments: {
                          'name':
                              username == 'macs' ? 'Macs Admin' : 'Master User'
                        });
                      }
                    });
                    return;
                  }

                  try {
                    final res = await http
                        .post(
                          Uri.parse('${ApiService.baseUrl}/api/auth/login'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode(
                              {'username': username, 'password': password}),
                        )
                        .timeout(const Duration(seconds: 30));

                    final data = jsonDecode(res.body);
                    if (data['success'] == true &&
                        data['user'] != null &&
                        data['user']['role'] == 'master') {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/app_master',
                          arguments: {'name': data['user']['name']});
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              data['message'] ?? 'Invalid master credentials'),
                          backgroundColor: Colors.red));
                    }
                  } catch (e) {
                    if (e is TimeoutException) {
                      // Specific handling for TimeoutException
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Login timed out. Please check your network and try again.'),
                          backgroundColor: Colors.red));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              '🔴 Server is down or an unexpected error occurred. Please try again later.'),
                          backgroundColor: Colors.red));
                    }
                  }
                },
                child:
                    const Text('Login', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
      label: const Text('Open App Master',
          style: TextStyle(
              fontFamily: 'Arial Narrow',
              color: Colors.white,
              fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF172033),
          minimumSize: const Size(double.infinity, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final options = _exploreOptions;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(children: [
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF1C1C1E) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ]),
                        child: Icon(Icons.arrow_back_ios_new,
                            size: 18, color: AppTheme.textColor(context)))),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Community',
                          style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textColor(context))),
                      Text('${options.length} services',
                          style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              fontSize: 12,
                              color: AppTheme.textColor(context)
                                  .withOpacity(0.5))),
                    ])),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()));
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.brand(context),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.brand(context).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.userName.isNotEmpty
                            ? widget.userName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            // Options grid
            Expanded(
              child: options.isEmpty
                  ? Center(
                      child: Text('No options available',
                          style: AppTheme.titleMedium))
                  : GridView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        return _GridCard(
                          option: option,
                          onTap: () => _showOptionDetail(context, option),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFooter(isDark),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE4E7EC),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _footerItem(0, 'assets/icons/homepage_footer.png', 'Home', isDark),
              _footerItem(1, 'assets/icons/community_footer.png', 'Community', isDark),
              _footerItem(2, 'assets/icons/demand_footer.png', 'Demand', isDark),
              _footerItem(3, 'assets/icons/visiter_footer.png', 'Visitor', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footerItem(int index, String imagePath, String label, bool isDark) {
    final selected = _navIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onFooterTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(imagePath, width: 26, height: 26, fit: BoxFit.contain),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: Colors.black,
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _onFooterTap(int index) async {
    if (index == 1) return; // already here
    setState(() => _navIndex = index);
    if (index == 0) {
      Navigator.pop(context);
    } else if (index == 2) {
      await Navigator.push(
          context,
          PageAnimations.slideRight(PaymentDashboard(
              userId: _userProfile['id'] ?? '',
              userName: widget.userName,
              userRole: widget.userRole,
              apartment: _userProfile['apartment'] ?? '',
              phone: _userProfile['phone'] ?? '')));
      if (mounted) setState(() => _navIndex = 1);
    } else if (index == 3) {
      await Navigator.push(
          context,
          PageAnimations.slideRight(VisitorFormPage(
              userRole: widget.userRole,
              userName: widget.userName,
              userProfile: _userProfile)));
      if (mounted) setState(() => _navIndex = 1);
    }
  }
}

class _GridCard extends StatelessWidget {
  final ExploreOption option;
  final VoidCallback onTap;

  static const _appMasterBg = Color(0xFF172033);

  const _GridCard({required this.option, required this.onTap});

  bool get _isAppMaster => option.id == 99;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Low-contrast card: barely-there fill, no border, no shadow
    final bg = _isAppMaster
        ? _appMasterBg
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF4F5F7));
    final titleClr = _isAppMaster
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF1A1A2E));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          // No border, no shadow — fully flat minimal style
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: _isAppMaster
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(option.icon, color: Colors.white, size: 24),
                    )
                  : Image.asset(
                      option.imagePath,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        option.icon,
                        color: AppTheme.brand(context),
                        size: 26,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              option.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: titleClr,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExploreOption {
  final int id;
  final String title;
  final IconData icon;
  final String imagePath;
  final Color iconColor;
  final List<Color> gradientColors;
  final String description;

  ExploreOption({
    required this.id,
    required this.title,
    required this.icon,
    required this.imagePath,
    required this.iconColor,
    required this.gradientColors,
    required this.description,
  });
}

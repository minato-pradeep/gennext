import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../screens/notices/notice_board_page.dart';
import '../services/event_service.dart';
import '../models/event.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/animations.dart';
import 'explore_page.dart';
import 'offers_page.dart';
import '../widgets/profile_avatar.dart';

class CommunityDashboard extends StatefulWidget {
  final String userRole;
  final String userName;

  const CommunityDashboard({
    super.key,
    required this.userRole,
    required this.userName,
  });

  @override
  State<CommunityDashboard> createState() => _CommunityDashboardState();
}

class _CommunityDashboardState extends State<CommunityDashboard> {
  final _api = ApiService();
  Event? _nextEvent;
  bool _loadingEvent = false;
  List<Map<String, dynamic>> _pendingBills = [];
  bool _loadingBills = false;
  String _userId = '';
  String _flatNumber = '';
  String _apartment = '';
  String _phone = '';
  int _avatarKey = 0;
  int _unreadNotices = 0;
  int _carouselIndex = 0;
  late PageController _pageController;
  late final _autoScrollTimer;

  // Offers â€” no network images, instant load
  final List<Map<String, dynamic>> _offers = [
    {'store': 'Amazon', 'product': 'Smart Watch', 'discount': '80% OFF', 'icon': Icons.watch, 'color': const Color(0xFFFF9900), 'offerId': '1'},
    {'store': 'Flipkart', 'product': 'Headphones', 'discount': '50% OFF', 'icon': Icons.headphones, 'color': const Color(0xFF2874F0), 'offerId': '2'},
    {'store': 'Croma', 'product': 'Laptop', 'discount': 'â‚¹2000 OFF', 'icon': Icons.laptop, 'color': const Color(0xFF00B5AD), 'offerId': '6'},
    {'store': 'Myntra', 'product': 'Shoes', 'discount': '40% OFF', 'icon': Icons.shopping_bag, 'color': const Color(0xFFFF3F6C), 'offerId': '7'},
    {'store': 'Swiggy', 'product': 'Food', 'discount': 'â‚¹100 OFF', 'icon': Icons.fastfood, 'color': const Color(0xFFFC8019), 'offerId': '4'},
  ];



  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78);
    _loadEvents();
    _loadBills();
    _loadUnreadNotices();
    _loadUserProfile();
    EventService().addListener(_loadEvents);
    PaymentService().addListener(_loadBills);
    // Auto-scroll carousel
    _autoScrollTimer = Stream.periodic(const Duration(seconds: 3)).listen((_) {
      if (_pageController.hasClients && mounted) {
        final next = (_carouselIndex + 1) % _offers.length;
        _pageController.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    EventService().removeListener(_loadEvents);
    PaymentService().removeListener(_loadBills);
    _pageController.dispose();
    _autoScrollTimer.cancel();
    super.dispose();
  }

  void _loadEvents() {
    if (mounted) setState(() => _loadingEvent = true);
    EventService().fetchEvents().then((events) {
      if (mounted) {
        setState(() {
        _nextEvent = EventService().getNextEvent(events);
        _loadingEvent = false;
      });
      }
    }).catchError((_) {
      if (mounted) setState(() => _loadingEvent = false);
    });
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('user_id') ?? '';
    if (id.isEmpty) return;
    try {
      final info = await _api.getUserInfo(id);
      if (mounted && info != null) {
        setState(() {
        _flatNumber = info['flat_number']?.toString() ?? '';
        _apartment = info['apartment']?.toString() ?? '';
        _phone = info['phone']?.toString() ?? '';
      });
      }
    } catch (_) {}
  }

  Future<void> _loadUnreadNotices() async {
    try {
      final res = await http.get(Uri.parse('${ApiService.baseUrl}/api/notices')).timeout(const Duration(seconds: 5));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() => _unreadNotices = (data['notices'] as List).length);
      }
    } catch (_) {}
  }

  Future<void> _loadBills() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? '';
    if (_userId.isEmpty) return;
    setState(() => _loadingBills = true);
    try {
      final res = await http.get(Uri.parse('${ApiService.baseUrl}/api/bills?user_id=$_userId')).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        final all = List<Map<String, dynamic>>.from(data['bills']);
        setState(() {
          _pendingBills = all.where((b) => b['pay_status'] != 'paid').toList();
          _loadingBills = false;
        });
      } else {
        if (mounted) setState(() => _loadingBills = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBills = false);
    }
  }

  Future<void> _logout() async {
    await _api.clearSession();
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  String get _roleDisplay {
    switch (widget.userRole.toLowerCase()) {
      case 'owner': return 'House Owner';
      case 'security': return 'Security';
      case 'visitor': return 'Visitor';
      default: return widget.userRole;
    }
  }

  String get _unitNumber {
    switch (widget.userRole.toLowerCase()) {
      case 'owner': return 'B12';
      case 'security': return 'Gate';
      default: return 'G01';
    }
  }

  String _formatDate(String s) {
    try {
      final d = DateTime.parse(s.replaceAll(' ', 'T'));
      final now = DateTime.now();
      if (d.day == now.day && d.month == now.month) return 'Today';
      if (d.day == now.day + 1 && d.month == now.month) return 'Tomorrow';
      return '${d.day}/${d.month}';
    } catch (_) { return s.split(' ').first; }
  }

  String _formatTime(String s) {
    try {
      final d = DateTime.parse(s.replaceAll(' ', 'T'));
      return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    } catch (_) { return ''; }
  }

  void _showSettings() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeNotifierProvider.value(
        value: themeProvider,
        child: Consumer<ThemeProvider>(
          builder: (ctx, tp, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text('Settings', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 20, fontWeight: FontWeight.w700, color: tp.isDarkMode ? Colors.white : Colors.black87)),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(tp.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: AppTheme.primaryBlue),
                  title: Text('Dark Mode', style: TextStyle(fontFamily: 'Arial Narrow', fontWeight: FontWeight.w500, color: tp.isDarkMode ? Colors.white : Colors.black87)),
                  trailing: Switch(
                    value: tp.isDarkMode,
                    onChanged: (_) => tp.toggleTheme(),
                    activeColor: AppTheme.primaryBlue,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(fontFamily: 'Arial Narrow', fontWeight: FontWeight.w500, color: Colors.red)),
                  onTap: () { Navigator.pop(context); _logout(); },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bg = isDark ? const Color(0xFF0F0F0F) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSub = isDark ? Colors.white54 : Colors.black45;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ HEADER â”€â”€
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    // Avatar
                    ProfileAvatar(key: ValueKey(_avatarKey), size: 52, borderRadius: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back, ${widget.userName}',
                            style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                          Text(
                            [if (_flatNumber.isNotEmpty) _flatNumber, if (_apartment.isNotEmpty) _apartment, if (_phone.isNotEmpty) _phone].join(' • '),
                            style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 13, color: textSub)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _showSettings,
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.settings_outlined, color: isDark ? Colors.white54 : Colors.black45, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => NoticeBoardPage(userRole: widget.userRole, userName: widget.userName)));
                        _loadUnreadNotices();
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.notifications_outlined, color: isDark ? Colors.white54 : Colors.black45, size: 22),
                          ),
                          if (_unreadNotices > 0)
                            Positioned(
                              right: 0, top: 0,
                              child: Container(
                                width: 18, height: 18,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: Center(child: Text(_unreadNotices > 9 ? '9+' : '$_unreadNotices', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // â”€â”€ EVENT CARD â”€â”€
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: _nextEvent != null ? () => _showEventDetail(_nextEvent!) : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _nextEvent != null
                            ? [const Color(0xFF1565C0), const Color(0xFF42A5F5)]
                            : [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: (_nextEvent != null ? const Color(0xFF1565C0) : const Color(0xFF2E7D32)).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: _loadingEvent
                        ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                        : _nextEvent == null
                            ? Row(children: [
                                Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3))),
                                  child: const Icon(Icons.wb_sunny, color: Colors.white, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Good Day! 🌟', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_dayName()}, ${DateTime.now().day} ${_monthName()}',
                                    style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 12, color: Colors.white70),
                                  ),
                                  const Text('No upcoming events', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 11, color: Colors.white60)),
                                ])),
                              ])
                            : Row(children: [
                        // Glassmorphism calendar icon
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.calendar_month, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nextEvent?.title ?? 'No Upcoming Events',
                                style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              if (_nextEvent != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_formatDate(_nextEvent!.dateTime)}  â€¢  ${_formatTime(_nextEvent!.dateTime)}',
                                    style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                                  ),
                                )
                              else
                                const Text('Check back later', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                        ),
                                const Icon(Icons.chevron_right, color: Colors.white70, size: 22),
                              ],
                            ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // â”€â”€ OFFERS CAROUSEL â”€â”€
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Special Deals & Coupons',
                      style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, PageAnimations.slideRight(
                        OffersPage(userRole: widget.userRole, userName: widget.userName, isAdmin: false))),
                      child: const Text('See All', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 150,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _carouselIndex = i),
                  itemCount: _offers.length,
                  itemBuilder: (context, index) {
                    final offer = _offers[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, PageAnimations.slideRight(
                        OffersPage(userRole: widget.userRole, userName: widget.userName, isAdmin: false, selectedOfferId: offer['offerId']))),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Container(
                                width: 60, height: 60,
                                decoration: BoxDecoration(
                                  color: (offer['color'] as Color).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(offer['icon'] as IconData, color: offer['color'] as Color, size: 30),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(offer['store']!, style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                                    const SizedBox(height: 4),
                                    Text(offer['product']!, style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 12, color: textSub)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
                                      child: Text(offer['discount']!, style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.red.shade600)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Pagination dots
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_offers.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _carouselIndex == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _carouselIndex == i ? AppTheme.primaryBlue : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
              ),

              const SizedBox(height: 28),
              // ── PENDING BILLS (from DB) ──
              if (_loadingBills)
                const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Center(child: CircularProgressIndicator()))
              else if (_pendingBills.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: Row(children: [
                      const Text('😊', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('No Pending Bills!', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.green)),
                        Text('You are all caught up 🎉', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
                      ]),
                    ]),
                  ),
                )
              else if (_pendingBills.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.receipt_long, color: Colors.white, size: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Pending Bills', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text('${_pendingBills.length} bill(s) pending', style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 12, color: Colors.white70)),
                          ])),
                        ]),
                        const SizedBox(height: 18),
                        ..._pendingBills.take(3).map((bill) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(children: [
                            Container(width: 36, height: 36,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.receipt, color: Colors.orange, size: 18)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(bill['title']?.toString() ?? '', style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('Due: ${bill['due_date']?.toString().substring(0, 10) ?? ''}', style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 11, color: Colors.white60)),
                            ])),
                            Text('₹${bill['amount']}', style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => Navigator.push(context, PageAnimations.slideRight(ExplorePage(userRole: widget.userRole, userName: widget.userName))),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                child: const Text('Pay Now', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0D47A1))),
                              ),
                            ),
                          ]),
                        )),
                      ]),
                    ),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),

      // â”€â”€ EXPLORE BUTTON â”€â”€
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(context, PageAnimations.slideRight(
                ExplorePage(userRole: widget.userRole, userName: widget.userName)));
              setState(() => _avatarKey++);
            },
            icon: const Icon(Icons.explore, color: Colors.white, size: 20),
            label: const Text('Explore Services',
              style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }

  String _dayName() {
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return days[DateTime.now().weekday - 1];
  }

  String _monthName() {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[DateTime.now().month - 1];
  }

  void _showEventDetail(Event event) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return Transform.scale(
          scale: curved.value,
          child: Opacity(opacity: anim.value.clamp(0.0, 1.0), child: child),
        );
      },
      pageBuilder: (ctx, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20)),
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header gradient
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28), topRight: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.event, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(event.title,
                            style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date & Time row
                        Row(
                          children: [
                            _infoChip(Icons.calendar_today, _formatDate(event.dateTime), isDark),
                            const SizedBox(width: 10),
                            _infoChip(Icons.access_time, _formatTime(event.dateTime), isDark),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Description', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 13, fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black45)),
                        const SizedBox(height: 6),
                        Text(event.description,
                          style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.5)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('Posted by ${event.postedBy}',
                              style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            child: const Text('Close', style: TextStyle(fontFamily: 'Arial Narrow', fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryBlue),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 12, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1565C0))),
        ],
      ),
    );
  }
}


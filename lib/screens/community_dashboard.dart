import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../services/sos_service.dart';
import '../screens/notices/notice_board_page.dart';
import '../screens/sos_partner_alert_screen.dart';
import '../services/event_service.dart';
import '../models/event.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/animations.dart';
import 'explore_page.dart';
import 'offers_page.dart';
import 'emergency_numbers_page.dart';
import 'raise_complaint_page.dart';
import 'payments/payment_dashboard.dart';
import 'visitor_form_page.dart';

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

class _CommunityDashboardState extends State<CommunityDashboard>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _api = ApiService();
  Event? _nextEvent;
  bool _loadingEvent = false;
  List<Map<String, dynamic>> _pendingBills = [];
  bool _loadingBills = false;
  String _userId = '';
  String _flatNumber = '';
  String _apartment = '';
  String _phone = '';
  bool _partnerAlertOpen = false;
  int _avatarKey = 0;
  Timer? _refreshTimer;
  int _unreadNotices = 0;
  int _carouselIndex = 0;
  int _carouselDirection = 1;
  int _navIndex = 0;
  late PageController _pageController;
  late final _autoScrollTimer;
  Timer? _partnerAlertTimer;

  // ── Rolling-ball animation for the N logo ──
  late AnimationController _logoController;
  late Animation<double> _logoTranslateX;
  late Animation<double> _logoRotate;

  // Offers — local 1080p photos matched to each brand/category
  final List<Map<String, dynamic>> _offers = [
    {
      'store': 'Amazon',
      'product': 'Smart Watch',
      'discount': '80% OFF',
      'price': '₹1,999',
      'icon': Icons.watch,
      'color': const Color(0xFFFF9900),
      'offerId': '1',
      'image': 'assets/offers/amazon_watch.jpg',
    },
    {
      'store': 'Flipkart',
      'product': 'Fashion',
      'discount': '50% OFF',
      'price': '₹499',
      'icon': Icons.style_rounded,
      'color': const Color(0xFF2874F0),
      'offerId': '2',
      'image': 'assets/offers/flipkart_fashion.jpg',
    },
    {
      'store': 'Croma',
      'product': 'Laptop',
      'discount': '₹2000 OFF',
      'price': '₹42,990',
      'icon': Icons.laptop,
      'color': const Color(0xFF00B5AD),
      'offerId': '6',
      'image': 'assets/offers/croma_laptop.jpg',
    },
    {
      'store': 'Myntra',
      'product': 'Shoes',
      'discount': '40% OFF',
      'price': '₹1,199',
      'icon': Icons.shopping_bag,
      'color': const Color(0xFFFF3F6C),
      'offerId': '7',
      'image': 'assets/offers/myntra_shoes.jpg',
    },
    {
      'store': 'Swiggy',
      'product': 'Food',
      'discount': '₹100 OFF',
      'price': '₹299',
      'icon': Icons.fastfood,
      'color': const Color(0xFFFC8019),
      'offerId': '4',
      'image': 'assets/offers/swiggy_food.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ── Rolling-ball animation setup ──
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // Roll 28px to the right then back (forward → reverse)
    _logoTranslateX = Tween<double>(begin: 0, end: 28).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    // One full clockwise rotation (2π radians) while rolling right
    _logoRotate = Tween<double>(begin: 0, end: 2 * 3.141592653589793).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    _pageController = PageController(viewportFraction: 0.78);
    _refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) {
        _loadEvents();
        _loadBills();
        _loadUnreadNotices();
      }
    });
    _loadEvents();
    _loadBills();
    _loadUnreadNotices();
    _loadUserProfile();
    EventService().addListener(_loadEvents);
    PaymentService().addListener(_loadBills);
    _partnerAlertTimer =
        Timer.periodic(const Duration(seconds: 6), (_) => _checkPartnerAlert());
    // Auto-scroll carousel: forward then reverse (no jump back to start)
    _autoScrollTimer = Stream.periodic(const Duration(seconds: 3)).listen((_) {
      if (!_pageController.hasClients || !mounted || _offers.length < 2) return;
      var next = _carouselIndex + _carouselDirection;
      if (next >= _offers.length) {
        _carouselDirection = -1;
        next = _carouselIndex - 1;
      } else if (next < 0) {
        _carouselDirection = 1;
        next = _carouselIndex + 1;
      }
      _pageController.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    EventService().removeListener(_loadEvents);
    PaymentService().removeListener(_loadBills);
    _pageController.dispose();
    _partnerAlertTimer?.cancel();
    _autoScrollTimer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadEvents();
      _loadBills();
      _loadUnreadNotices();
    }
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

  Future<void> _checkPartnerAlert() async {
    if (_partnerAlertOpen || _phone.isEmpty) return;

    // First check for native SOS triggers
    final nativeTrigger = await SosService.checkNativeSosTrigger();
    if (nativeTrigger && mounted) {
      _partnerAlertOpen = true;
      // Create a mock alert for native trigger
      final mockAlert = {
        'id': -1,
        'partner_phone': await SosService.getNativePartnerNumber() ?? 'Unknown',
        'triggered_at': DateTime.now().toIso8601String(),
        'is_native_trigger': true,
      };
      await Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => SosPartnerAlertScreen(alert: mockAlert)),
      );
      _partnerAlertOpen = false;
      return;
    }

    // Then check for regular partner alerts
    final alert = await SosService.getIncomingPartnerAlert(_phone);
    if (alert != null && mounted) {
      _partnerAlertOpen = true;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SosPartnerAlertScreen(alert: alert)),
      );
      _partnerAlertOpen = false;
    }
  }

  Future<void> _loadUnreadNotices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final res = await http
          .get(Uri.parse('${ApiService.baseUrl}/api/notices')
              .replace(queryParameters: {
            if (userId != null && userId.isNotEmpty) 'user_id': userId,
          }))
          .timeout(const Duration(seconds: 5));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() => _unreadNotices = (data['notices'] as List).length);
      }
    } catch (_) {}
  }

  Future<void> _loadBills() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? '';
    setState(() => _loadingBills = true);
    try {
      // Load from company_payments (the same source as the Demands screen)
      final payments = await PaymentService().getCompanyPayments();
      if (mounted) {
        setState(() {
          _pendingBills =
              payments.where((b) => b['payment_status'] != 'paid').toList();
          _loadingBills = false;
        });
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
      case 'owner':
        return 'House Owner';
      case 'security':
        return 'Security';
      case 'visitor':
        return 'Visitor';
      default:
        return widget.userRole;
    }
  }

  String get _unitNumber {
    switch (widget.userRole.toLowerCase()) {
      case 'owner':
        return 'B12';
      case 'security':
        return 'Gate';
      default:
        return 'G01';
    }
  }

  String _normalizeDateTime(String value) {
    var normalized = value.trim();
    if (normalized.isEmpty) return normalized;

    normalized = normalized.replaceAll(RegExp(r'\.\d+'), '');

    if (normalized.contains('T')) {
      final tzPattern = RegExp(r'([+-]\d{1,2}:?\d{2}|Z)$');
      final match = tzPattern.firstMatch(normalized);
      if (match != null) {
        normalized = normalized.substring(0, match.start);
      }
    }

    if (normalized.contains('T')) {
      normalized = normalized.replaceFirst('T', ' ');
    }

    return normalized;
  }

  String _ordinalDay(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  String _formatBillDate(Map<String, dynamic> bill) {
    final raw = bill['due_date'] ??
        bill['bill_date'] ??
        bill['payment_date'] ??
        bill['created_at'];
    if (raw == null) return '';
    try {
      final d = DateTime.tryParse(raw.toString()) ??
          EventService().parseEventDateTime(raw.toString());
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${_ordinalDay(d.day)} ${months[d.month - 1]}';
    } catch (_) {
      return raw.toString().split(' ').first;
    }
  }

  String _formatDate(String s) {
    try {
      final d = EventService().parseEventDateTime(s);
      final now = DateTime.now();
      if (d.day == now.day && d.month == now.month) return 'Today';
      if (d.day == now.day + 1 && d.month == now.month) return 'Tomorrow';
      return '${d.day}/${d.month}';
    } catch (_) {
      return s.split(' ').first;
    }
  }

  String _formatTime(String s) {
    try {
      final d = EventService().parseEventDateTime(s);
      final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final minute = d.minute.toString().padLeft(2, '0');
      final suffix = d.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $suffix';
    } catch (_) {
      return '';
    }
  }

  void _showSettings() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        var showThemeColors = false;
        var pendingBrandId = themeProvider.brandId;
        return ChangeNotifierProvider.value(
          value: themeProvider,
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return Consumer<ThemeProvider>(
                builder: (ctx, tp, _) {
                  final titleColor = Theme.of(ctx).colorScheme.onSurface;
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 24,
                      bottom:
                          24 + MediaQuery.of(sheetContext).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 20),
                        Text('Settings',
                            style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: titleColor)),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                              tp.isDarkMode
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                              color: tp.primaryColor),
                          title: Text('Dark Mode',
                              style: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  fontWeight: FontWeight.w500,
                                  color: titleColor)),
                          trailing: Switch(
                            value: tp.isDarkMode,
                            onChanged: (_) => tp.toggleTheme(),
                            activeColor: tp.primaryColor,
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.palette_outlined,
                              color: tp.primaryColor),
                          title: Text('Change theme',
                              style: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  fontWeight: FontWeight.w500,
                                  color: titleColor)),
                          trailing: Icon(
                            showThemeColors
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: titleColor,
                          ),
                          onTap: () => setSheetState(
                              () => showThemeColors = !showThemeColors),
                        ),
                        if (showThemeColors) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: ThemeProvider.brandOptions.map((option) {
                              final selected = pendingBrandId == option.id;
                              return GestureDetector(
                                onTap: () => setSheetState(
                                    () => pendingBrandId = option.id),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: option.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selected
                                          ? titleColor
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: option.color.withOpacity(0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: selected
                                      ? Icon(Icons.check,
                                          size: 20, color: option.onColor)
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                await tp.saveBrandColor(pendingBrandId);
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tp.primaryColor,
                                foregroundColor: tp.onPrimaryColor,
                              ),
                              child: const Text('Save',
                                  style: TextStyle(
                                      fontFamily: 'Arial Narrow',
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.color_lens_outlined,
                              color: tp.primaryColor),
                          title: Text('Color Picker',
                              style: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  fontWeight: FontWeight.w500,
                                  color: titleColor)),
                          subtitle: tp.hasCustomColors
                              ? Row(children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      color: tp.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.grey.shade400,
                                          width: 0.5),
                                    ),
                                  ),
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: tp.onPrimaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.grey.shade400,
                                          width: 0.5),
                                    ),
                                  ),
                                  Text('Custom active',
                                      style: TextStyle(
                                          fontFamily: 'Arial Narrow',
                                          fontSize: 11,
                                          color: tp.primaryColor)),
                                ])
                              : null,
                          trailing: Icon(Icons.arrow_forward_ios,
                              size: 16, color: titleColor),
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            await _showColorPickerDialog(tp);
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Logout',
                              style: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red)),
                          onTap: () {
                            Navigator.pop(context);
                            _logout();
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showColorPickerDialog(ThemeProvider tp) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ColorPickerDialog(tp: tp),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF7F8FA);
    final textPrimary = AppTheme.textColor(context);
    final textSub = isDark ? Colors.white54 : const Color(0xFF667085);

    final headerBand =
        isDark ? const Color(0xFF1B2A3D) : const Color(0xFFDCEEFF);

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              clipBehavior: Clip.none,
              decoration: BoxDecoration(
                color: headerBand,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // â”€â”€ HEADER â”€â”€
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final travelDistance = constraints.maxWidth - 52.0;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // ── Base row — layout unchanged ──
                              Row(
                                children: [
                                  // Invisible placeholder holds the logo's space
                                  const SizedBox(width: 52, height: 52),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hi, ${widget.userName}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontFamily: 'Arial Narrow',
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: textPrimary),
                                        ),
                                        Text(
                                            [
                                              if (_flatNumber.isNotEmpty) _flatNumber,
                                              if (_apartment.isNotEmpty) _apartment,
                                              if (_phone.isNotEmpty) _phone
                                            ].join(' • '),
                                            style: TextStyle(
                                                fontFamily: 'Arial Narrow',
                                                fontSize: 12,
                                                color: textSub)),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _showSettings,
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E1E1E)
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black.withOpacity(0.07),
                                              blurRadius: 8)
                                        ],
                                      ),
                                      child: Icon(Icons.settings_outlined,
                                          color: isDark
                                              ? Colors.white54
                                              : AppTheme.brand(context),
                                          size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => NoticeBoardPage(
                                                  userRole: widget.userRole,
                                                  userName: widget.userName)));
                                      _loadUnreadNotices();
                                    },
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1E1E1E)
                                                : Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black.withOpacity(0.07),
                                                  blurRadius: 8)
                                            ],
                                          ),
                                          child: Icon(Icons.notifications_outlined,
                                              color: isDark
                                                  ? Colors.white54
                                                  : AppTheme.brand(context),
                                              size: 22),
                                        ),
                                        if (_unreadNotices > 0)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              width: 18,
                                              height: 18,
                                              decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle),
                                              child: Center(
                                                  child: Text(
                                                      _unreadNotices > 9
                                                          ? '9+'
                                                          : '$_unreadNotices',
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold))),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // ── Animated logo — top layer, overlays everything ──
                              AnimatedBuilder(
                                animation: _logoController,
                                builder: (context, child) {
                                  final dx = (_logoTranslateX.value / 28.0) * travelDistance;
                                  return Positioned(
                                    left: dx,
                                    top: 0,
                                    child: Transform.rotate(
                                      angle: _logoRotate.value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    if (_logoController.isAnimating) return;
                                    _logoController.forward().then((_) {
                                      _logoController.reverse();
                                    });
                                  },
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Color(0x4D000000),
                                            blurRadius: 12,
                                            offset: Offset(0, 4))
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.asset(
                                      'assets/icons/nextgen_icon.png',
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── EVENT CARD ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Transform.translate(
                        offset: const Offset(0, 22),
                        child: GestureDetector(
                          onTap: _nextEvent != null
                              ? () => _showEventDetail(_nextEvent!)
                              : null,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: double.infinity,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4))
                                ],
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // background photo — community building with people
                                  Image.asset(
                                    'assets/images/community_banner.jpg',
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                  ),
                                  // dark-left gradient overlay so text is readable
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withOpacity(0.62),
                                          Colors.black.withOpacity(0.25),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                  ),
                                  // card content
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 14),
                                    child: _loadingEvent
                                        ? const Center(
                                            child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2)))
                                        : _nextEvent == null
                                            ? Row(children: [
                                                Container(
                                                  width: 52,
                                                  height: 52,
                                                  decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(14),
                                                      border: Border.all(
                                                          color: Colors.white.withOpacity(0.3))),
                                                  child: Icon(_timeIcon(), color: Colors.white, size: 26),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                    child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                      const Text('Good Day!',
                                                          style: TextStyle(
                                                              fontFamily: 'Arial Narrow',
                                                              fontSize: 22,
                                                              fontWeight: FontWeight.w800,
                                                              color: Colors.white,
                                                              shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '${_dayName()}, ${DateTime.now().day} ${_monthName()} ${DateTime.now().year}',
                                                        style: const TextStyle(
                                                            fontFamily: 'Arial Narrow',
                                                            fontSize: 12,
                                                            color: Colors.white,
                                                            shadows: [Shadow(color: Colors.black45, blurRadius: 3)]),
                                                      ),
                                                    ])),
                                              ])
                                            : Row(
                                                children: [
                                                  Container(
                                                    width: 52,
                                                    height: 52,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(14),
                                                      border: Border.all(
                                                          color: Colors.white.withOpacity(0.3)),
                                                    ),
                                                    child: const Icon(Icons.calendar_month,
                                                        color: Colors.white, size: 26),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          _nextEvent?.title ?? 'No Upcoming Events',
                                                          style: const TextStyle(
                                                              fontFamily: 'Arial Narrow',
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.w700,
                                                              color: Colors.white,
                                                              shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 6),
                                                        if (_nextEvent != null)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                                horizontal: 10, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: Colors.white.withOpacity(0.2),
                                                              borderRadius: BorderRadius.circular(20),
                                                            ),
                                                            child: Text(
                                                              '${_formatDate(_nextEvent!.dateTime)} ${_formatTime(_nextEvent!.dateTime)}',
                                                              style: const TextStyle(
                                                                  fontFamily: 'Arial Narrow',
                                                                  fontSize: 11,
                                                                  color: Colors.white,
                                                                  fontWeight: FontWeight.w500),
                                                            ),
                                                          )
                                                        else
                                                          const Text('Check back later',
                                                              style: TextStyle(
                                                                  fontFamily: 'Arial Narrow',
                                                                  fontSize: 12,
                                                                  color: Colors.white)),
                                                      ],
                                                    ),
                                                  ),
                                                  const Icon(Icons.chevron_right,
                                                      color: Colors.white70, size: 22),
                                                ],
                                              ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 44),

            // â”€â”€ OFFERS CAROUSEL â”€â”€
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Special Deals & Coupons',
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        PageAnimations.slideRight(OffersPage(
                            userRole: widget.userRole,
                            userName: widget.userName,
                            isAdmin: false))),
                    child: Text('SeeAll',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 13,
                            color: AppTheme.brand(context),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 198,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _carouselIndex = i),
                itemCount: _offers.length,
                itemBuilder: (context, index) {
                  final offer = _offers[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        PageAnimations.slideRight(OffersPage(
                            userRole: widget.userRole,
                            userName: widget.userName,
                            isAdmin: false,
                            selectedOfferId: offer['offerId']))),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 8))
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              offer['image'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: offer['color'] as Color,
                                child: Icon(offer['icon'] as IconData,
                                    color: Colors.white, size: 48),
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.05),
                                    Colors.black.withOpacity(0.82),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        offer['discount'] as String,
                                        style: TextStyle(
                                          fontFamily: 'Arial Narrow',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: offer['color'] as Color,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    offer['store'] as String,
                                    style: const TextStyle(
                                      fontFamily: 'Arial Narrow',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          offer['product'] as String,
                                          style: TextStyle(
                                            fontFamily: 'Arial Narrow',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white
                                                .withValues(alpha: 0.88),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // ── Flipkart-style price badge ──
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          offer['price'] as String,
                                          style: TextStyle(
                                            fontFamily: 'Arial Narrow',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: offer['color'] as Color,
                                          ),
                                        ),
                                      ),
                                    ],
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
              children: List.generate(
                  _offers.length,
                  (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _carouselIndex == i ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _carouselIndex == i
                              ? AppTheme.brand(context)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )),
            ),

            const SizedBox(height: 28),
            // ── PENDING BILLS (from DB) ──
            if (_loadingBills)
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Center(child: CircularProgressIndicator()))
            else if (_pendingBills.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF12B76A).withOpacity(0.35)),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF12B76A).withOpacity(0.08),
                          blurRadius: 12)
                    ],
                  ),
                  child: Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF12B76A).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF12B76A), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('No Pending Bills!',
                              style: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF12B76A))),
                          Text('You\'re all caught up — great work',
                              style: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  fontSize: 12,
                                  color: textPrimary.withOpacity(0.6))),
                        ]),
                  ]),
                ),
              )
            else if (_pendingBills.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppTheme.brand(context),
                      AppTheme.brandLight(context)
                    ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.brand(context).withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: AppTheme.onBrand(context)
                                        .withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.receipt_long,
                                    color: AppTheme.onBrand(context),
                                    size: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('Pending Bills',
                                      style: TextStyle(
                                          fontFamily: 'Arial Narrow',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.onBrand(context))),
                                  Text(
                                      '${_pendingBills.length} bill(s) pending',
                                      style: TextStyle(
                                          fontFamily: 'Arial Narrow',
                                          fontSize: 12,
                                          color: AppTheme.onBrand(context))),
                                ])),
                          ]),
                          const SizedBox(height: 18),
                          ..._pendingBills.take(3).map((bill) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                            color: AppTheme.onBrand(context)
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Icon(Icons.receipt,
                                            color: AppTheme.onBrand(context)
                                                .withOpacity(0.7),
                                            size: 18)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Text(
                                      _formatBillDate(bill),
                                      style: TextStyle(
                                          fontFamily: 'Arial Narrow',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.onBrand(context)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                    const SizedBox(width: 8),
                                    Text(
                                        '₹${bill['payment_amount'] ?? bill['amount'] ?? '0'}',
                                        style: TextStyle(
                                            fontFamily: 'Arial Narrow',
                                            fontSize: 21,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.onBrand(context))),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                          context,
                                          PageAnimations.slideRight(
                                              PaymentDashboard(
                                                  userId: _userId,
                                                  userName: widget.userName,
                                                  userRole: widget.userRole,
                                                  apartment: _apartment,
                                                  phone: _phone))),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 7),
                                        decoration: BoxDecoration(
                                            color: AppTheme.onBrand(context),
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: Text('Pay Now',
                                            style: TextStyle(
                                                fontFamily: 'Arial Narrow',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    AppTheme.brand(context))),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ]),
                  ),
                ),
              ),

            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Quick Actions',
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
                children: [
                  _quickAction('assets/icons/emergency.png', 'Emergency',
                      isDark, () {
                    Navigator.push(
                        context,
                        PageAnimations.slideRight(
                            const EmergencyNumbersPage()));
                  }),
                  _quickAction('assets/icons/icon4.png', 'Complaints',
                      isDark, () {
                    Navigator.push(
                        context,
                        PageAnimations.slideRight(RaiseComplaintPage(
                          userRole: widget.userRole,
                          userName: widget.userName,
                          userProfile: {
                            'flat_number': _flatNumber,
                            'apartment': _apartment,
                            'phone': _phone
                          },
                        )));
                  }),
                  _quickAction('assets/icons/icon7.png', 'Demands',
                      isDark, () {
                    _showDemandsSheet(context);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
      ),
    );
  }

  // Returns a sun icon between 06:00–18:00, moon otherwise.
  IconData _timeIcon() {
    final hour = DateTime.now().hour;
    return (hour >= 6 && hour < 18)
        ? Icons.wb_sunny_rounded
        : Icons.nightlight_round;
  }

  String _dayName() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[DateTime.now().weekday - 1];
  }

  String _monthName() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[DateTime.now().month - 1];
  }

  void _showEventDetail(Event event) {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
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
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 20)),
                  BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header gradient
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.brand(context),
                          AppTheme.brandLight(context)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.event,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(event.title,
                              style: const TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 18),
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
                            _infoChip(Icons.calendar_today,
                                _formatDate(event.dateTime), isDark),
                            const SizedBox(width: 10),
                            _infoChip(Icons.access_time,
                                _formatTime(event.dateTime), isDark),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Description',
                            style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark ? Colors.white54 : Colors.black45)),
                        const SizedBox(height: 6),
                        Text(event.description,
                            style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black87,
                                height: 1.5)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('Posted by ${event.postedBy}',
                                style: const TextStyle(
                                    fontFamily: 'Arial Narrow',
                                    fontSize: 12,
                                    color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brand(context),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            child: const Text('Close',
                                style: TextStyle(
                                    fontFamily: 'Arial Narrow',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
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

  void _showDemandsSheet(BuildContext context) {
    void go(String category) {
      Navigator.pop(context);
      Navigator.push(
          context,
          PageAnimations.slideRight(PaymentDashboard(
            userId: _userId,
            userName: widget.userName,
            userRole: widget.userRole,
            apartment: _apartment,
            phone: _phone,
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
                // spacer to keep row aligned with the 3-column row above
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

  Future<void> _onFooterTap(int index) async {
    if (index == 0) {
      setState(() => _navIndex = 0);
      return;
    }
    setState(() => _navIndex = index);
    if (index == 1) {
      await Navigator.push(
          context,
          PageAnimations.slideRight(ExplorePage(
              userRole: widget.userRole, userName: widget.userName)));
      if (mounted)
        setState(() {
          _navIndex = 0;
          _avatarKey++;
        });
    } else if (index == 2) {
      await Navigator.push(
          context,
          PageAnimations.slideRight(PaymentDashboard(
              userId: _userId,
              userName: widget.userName,
              userRole: widget.userRole,
              apartment: _apartment,
              phone: _phone)));
      if (mounted) setState(() => _navIndex = 0);
    } else if (index == 3) {
      await Navigator.push(
          context,
          PageAnimations.slideRight(VisitorFormPage(
            userRole: widget.userRole,
            userName: widget.userName,
            userProfile: {
              'flat_number': _flatNumber,
              'apartment': _apartment,
              'phone': _phone
            },
          )));
      if (mounted) setState(() => _navIndex = 0);
    }
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
            Image.asset(
              imagePath,
              width: 26,
              height: 26,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(String imagePath, String label, bool isDark,
      VoidCallback onTap) {
    final isDarkMode = isDark;
    final bg = isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF4F5F7);
    final titleClr = isDarkMode ? Colors.white : const Color(0xFF1A1A2E);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Image.asset(
                imagePath,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 9,
                  color: Colors.white60,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.brand(context)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.brand(context))),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Color Picker Dialog
// ──────────────────────────────────────────────────────────────────────────────

class _ColorPickerDialog extends StatefulWidget {
  final ThemeProvider tp;
  const _ColorPickerDialog({required this.tp});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  Color? _pendingBg;
  Color? _pendingText;

  @override
  void initState() {
    super.initState();
    // Pre-select current colors if already set
    _pendingBg = widget.tp.customBgColor ?? widget.tp.primaryColor;
    _pendingText = widget.tp.customTextColor ?? widget.tp.onPrimaryColor;
  }

  static const List<PickerColor> _colors = ThemeProvider.pickerColors;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.tp.isDarkMode;
    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF172033);
    final subColor = isDark ? Colors.white54 : const Color(0xFF667085);
    final dividerColor =
        isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE4E7EC);
    final brand = widget.tp.primaryColor;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(children: [
              Icon(Icons.color_lens_rounded, color: brand, size: 22),
              const SizedBox(width: 10),
              Text('Color Picker',
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: titleColor)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, color: subColor, size: 20),
              ),
            ]),
            const SizedBox(height: 6),
            Text('Choose a background color and a text color.',
                style: TextStyle(
                    fontFamily: 'Arial Narrow', fontSize: 12, color: subColor)),

            const SizedBox(height: 16),

            // ── Preview strip ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _pendingBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dividerColor),
              ),
              child: Text('Preview Text',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _pendingText)),
            ),

            const SizedBox(height: 16),
            Divider(color: dividerColor, height: 1),
            const SizedBox(height: 12),

            // ── Two-column grid header ────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Background Color column ──────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Background',
                              style: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor)),
                          const SizedBox(height: 10),
                          _colorGrid(
                            selectedColor: _pendingBg,
                            onSelect: (c) => setState(() => _pendingBg = c),
                            isDark: isDark,
                            titleColor: titleColor,
                          ),
                        ],
                      ),
                    ),

                    // ── Vertical divider ─────────────────────────────────
                    Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: dividerColor),

                    // ── Text Color column ────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Text Color',
                              style: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor)),
                          const SizedBox(height: 10),
                          _colorGrid(
                            selectedColor: _pendingText,
                            onSelect: (c) => setState(() => _pendingText = c),
                            isDark: isDark,
                            titleColor: titleColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Divider(color: dividerColor, height: 1),
            const SizedBox(height: 12),

            // ── Action buttons ────────────────────────────────────────────
            Row(children: [
              // Reset button
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await widget.tp.clearCustomColors();
                    if (mounted) Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: dividerColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Reset',
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontWeight: FontWeight.w600,
                          color: subColor)),
                ),
              ),
              const SizedBox(width: 12),
              // Apply button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: (_pendingBg != null && _pendingText != null)
                      ? () async {
                          await widget.tp.saveCustomColors(
                            bgColor: _pendingBg!,
                            textColor: _pendingText!,
                          );
                          if (mounted) Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brand,
                    foregroundColor: widget.tp.onPrimaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('Apply',
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _colorGrid({
    required Color? selectedColor,
    required ValueChanged<Color> onSelect,
    required bool isDark,
    required Color titleColor,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _colors.map((pc) {
        final isSelected = selectedColor == pc.color;
        final isLight = pc.color.computeLuminance() > 0.6;
        return Tooltip(
          message: pc.name,
          child: GestureDetector(
            onTap: () => onSelect(pc.color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: pc.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? (isLight ? Colors.black87 : Colors.white)
                      : Colors.grey.withOpacity(0.3),
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: pc.color.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: isLight ? Colors.black87 : Colors.white,
                    )
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

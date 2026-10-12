import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/animations.dart';
import '../explore_page.dart';
import '../visitor_form_page.dart';
import 'payment_invoice_page.dart';

class PaymentDashboard extends StatefulWidget {
  final String userId;
  final String userName;
  final String userRole;
  final String apartment;
  final String phone;
  // 'maintenance' | 'others' | null (show all)
  final String? billCategory;

  const PaymentDashboard(
      {super.key,
      required this.userId,
      required this.userName,
      required this.userRole,
      required this.apartment,
      required this.phone,
      this.billCategory});

  @override
  State<PaymentDashboard> createState() => _PaymentDashboardState();
}

class _PaymentDashboardState extends State<PaymentDashboard> {
  List<Map<String, dynamic>> _bills = [];
  bool _loading = true;
  String _userId = '';
  int _navIndex = 2; // Payment tab

  @override
  void initState() {
    super.initState();
    _init();
    PaymentService().addListener(_load);
  }

  String _methodName(String id) {
    switch (id) {
      case 'gpay':
        return 'Google Pay';
      case 'phonepe':
        return 'PhonePe';
      case 'paytm':
        return 'Paytm';
      case 'upi':
        return 'UPI';
      case 'card':
        return 'Card';
      default:
        return id;
    }
  }

  @override
  void dispose() {
    PaymentService().removeListener(_load);
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? widget.userId;
    _load();
  }

  Future<void> _load() async {
    if (_userId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final payments = await PaymentService().getCompanyPayments(
        paymentType: widget.billCategory == 'maintenance'
            ? 'maintenance'
            : widget.billCategory == 'others'
                ? 'others'
                : null,
      );
      if (mounted) {
        setState(() {
          _bills = payments;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _pending =>
      _filteredBills.where((b) => b['payment_status'] != 'paid').toList();
  List<Map<String, dynamic>> get _paid =>
      _filteredBills.where((b) => b['payment_status'] == 'paid').toList();
  double get _totalPending => _pending.fold(0.0, (s, b) => s + _billAmount(b));

  // Filter bills by category using payment_type from company_payments table
  List<Map<String, dynamic>> get _filteredBills {
    if (widget.billCategory == null || widget.billCategory == 'all') {
      return _bills;
    }
    if (widget.billCategory == 'others') {
      // everything except maintenance, water, electricity
      return _bills.where((b) {
        final t = (b['payment_type'] ?? b['bill_type'] ?? b['type'] ?? '')
            .toString()
            .toLowerCase();
        return t != 'maintenance' && t != 'water' && t != 'electricity';
      }).toList();
    }
    // exact match for maintenance, water, electricity
    return _bills
        .where((b) =>
            (b['payment_type'] ?? b['bill_type'] ?? b['type'] ?? '')
                .toString()
                .toLowerCase() ==
            widget.billCategory!.toLowerCase())
        .toList();
  }

  String get _categoryTitle {
    switch (widget.billCategory) {
      case 'maintenance':
        return 'Maintenance Fee';
      case 'water':
        return 'Water Bill';
      case 'electricity':
        return 'Electricity Bill';
      case 'others':
        return 'Other Demands';
      case 'all':
        return 'All Demands';
      default:
        return 'My Demands';
    }
  }

  double _billAmount(Map<String, dynamic> bill) {
    return double.tryParse(bill['payment_amount']?.toString() ??
            bill['amount']?.toString() ??
            '0') ??
        0.0;
  }

  void _showPaymentSuccess(
      BuildContext context, double amount, String method) {
    final txnId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF12B76A), size: 52),
              ),
              const SizedBox(height: 20),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1B1B)),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${amount.toStringAsFixed(0)} paid via ${_methodName(method)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 14,
                    color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                txnId,
                style: const TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 11,
                    color: Colors.black38),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentInvoicePage(
                          userName: widget.userName,
                          apartment: widget.apartment,
                          amount: amount,
                          paymentMethod: method,
                          feeType: widget.billCategory == 'maintenance'
                              ? 'Maintenance Fee'
                              : widget.billCategory == 'water'
                                  ? 'Water Bill'
                                  : widget.billCategory == 'electricity'
                                      ? 'Electricity Bill'
                                      : widget.billCategory == 'others'
                                          ? 'Other Fee'
                                          : 'Community Fee',
                          transactionId: txnId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brand(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'View Invoice',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Skip',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 14,
                        color: Colors.black45)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPayDialog(Map<String, dynamic> bill) {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final amount = _billAmount(bill);
    String? selectedMethod;

    final methods = [
      {
        'id': 'gpay',
        'name': 'Google Pay',
        'icon': Icons.g_mobiledata_rounded,
        'color': const Color(0xFF4285F4),
        'bg': const Color(0xFFE8F0FE),
      },
      {
        'id': 'phonepe',
        'name': 'PhonePe',
        'icon': Icons.phone_android_rounded,
        'color': const Color(0xFF5F259F),
        'bg': const Color(0xFFF0E6FF),
      },
      {
        'id': 'paytm',
        'name': 'Paytm',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF00BAF2),
        'bg': const Color(0xFFE0F7FF),
      },
      {
        'id': 'upi',
        'name': 'Other UPI',
        'icon': Icons.qr_code_scanner_rounded,
        'color': const Color(0xFF43A047),
        'bg': const Color(0xFFE8F5E9),
      },
      {
        'id': 'card',
        'name': 'Credit / Debit Card',
        'icon': Icons.credit_card_rounded,
        'color': const Color(0xFFE53935),
        'bg': const Color(0xFFFFEBEE),
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),

              // Bill info header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill['plot_name'] ??
                                bill['payment_company_name'] ??
                                'Payment',
                            style: const TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bill['company_name'] != null
                                ? 'Company: ${bill['company_name']}'
                                : _categoryTitle,
                            style: const TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 12,
                                color: Colors.white70),
                          ),
                        ]),
                  ),
                  Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ]),
              ),

              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose Payment Method',
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              const SizedBox(height: 12),

              // Payment method cards
              ...methods.map((m) {
                final isSelected = selectedMethod == m['id'];
                return GestureDetector(
                  onTap: () {
                    setSheet(() => selectedMethod = m['id'] as String);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (m['bg'] as Color)
                          : (isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF8F8F8)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? (m['color'] as Color)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: (m['bg'] as Color),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(m['icon'] as IconData,
                            color: m['color'] as Color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          m['name'] as String,
                          style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: m['color'] as Color, size: 22)
                      else
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color:
                                isDark ? Colors.white38 : Colors.black26),
                    ]),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: selectedMethod == null
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _showPaymentSuccess(context, amount, selectedMethod!);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brand(context),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    selectedMethod == null
                        ? 'Select a Payment Method'
                        : 'Confirm Payment  ₹${amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? AppTheme.darkBackground : const Color(0xFFF0F4F8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(_categoryTitle,
            style: AppTheme.titleLarge.copyWith(color: Colors.white)),
        backgroundColor: AppTheme.brand(context),
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load)
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Reference-style Header Card ──
                      _buildHeaderCard(isDark),

                      const SizedBox(height: 22),

                      if (_filteredBills.isEmpty)
                        Center(
                            child: Column(children: [
                          const SizedBox(height: 40),
                          Icon(Icons.receipt_long_outlined,
                              size: 64,
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No bills assigned yet',
                              style: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black45)),
                        ]))
                      else ...[
                        if (_pending.isNotEmpty) ...[
                          Text(
                            'Current Invoices (${_pending.length})',
                            style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E)),
                          ),
                          const SizedBox(height: 12),
                          ..._pending
                              .map((b) => _billCard(b, isDark, isPaid: false)),
                          const SizedBox(height: 20),
                        ],
                        if (_paid.isNotEmpty) ...[
                          Text(
                            'Paid Invoices (${_paid.length})',
                            style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E)),
                          ),
                          const SizedBox(height: 12),
                          ..._paid
                              .map((b) => _billCard(b, isDark, isPaid: true)),
                        ],
                      ],
                    ]),
              ),
            ),
      bottomNavigationBar: _buildFooter(isDark),
    );
  }

  /// Light-blue header card matching the reference image
  Widget _buildHeaderCard(bool isDark) {
    final brandColor = AppTheme.brand(context);
    // Use a soft light-blue tint for light mode; dark-mode keeps brand dark
    final cardBg = isDark
        ? const Color(0xFF1E2A3A)
        : const Color(0xFFBDD9F2);
    final cardBorder = isDark
        ? Colors.white12
        : const Color(0xFF90C4E8);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            // ── The Image (2.5x larger, clipped inside the box) ──
            Positioned(
              right: -50,
              top: 0,
              bottom: 0,
              child: Transform.scale(
                scale: 2.5,
                alignment: Alignment.centerRight,
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Image.asset(
                    'assets/icons/demand.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // ── The Content ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar circle
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.white12 : Colors.white.withValues(alpha: 0.7),
                          border: Border.all(
                            color: isDark ? Colors.white24 : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 28,
                          color: isDark ? Colors.white70 : const Color(0xFF3A7BD5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name + apartment
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.apartment.isNotEmpty
                                  ? widget.apartment
                                  : widget.userRole,
                              style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF3A7BD5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── Total Due label ──
                  Text(
                    'Total Due:',
                    style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : const Color(0xFF3A7BD5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_totalPending.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    if (index == 2) return; // already here
    setState(() => _navIndex = index);
    if (index == 0) {
      Navigator.pop(context);
    } else if (index == 1) {
      await Navigator.push(
          context,
          PageAnimations.slideRight(ExplorePage(
              userRole: widget.userRole, userName: widget.userName)));
      if (mounted) setState(() => _navIndex = 2);
    } else if (index == 3) {
      await Navigator.push(
          context,
          PageAnimations.slideRight(VisitorFormPage(
              userRole: widget.userRole,
              userName: widget.userName,
              userProfile: {
                'flat_number': '',
                'apartment': widget.apartment,
                'phone': widget.phone,
              })));
      if (mounted) setState(() => _navIndex = 2);
    }
  }

  Widget _billCard(Map<String, dynamic> bill, bool isDark,
      {required bool isPaid}) {
    final amount = _billAmount(bill);

    // Parse pay date
    final rawDate = bill['due_date'] ?? bill['pay_date'] ?? bill['created_at'];
    String payDateStr = 'N/A';
    if (rawDate != null) {
      try {
        final dt = DateTime.parse(rawDate.toString());
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        payDateStr = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
      } catch (_) {
        payDateStr = rawDate.toString();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white12
              : const Color(0xFFDDE6EF),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Main row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendar / invoice icon with warm yellow background
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isPaid
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFEF3CD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPaid ? Icons.receipt_long : Icons.calendar_month_rounded,
                    color: isPaid
                        ? const Color(0xFF12B76A)
                        : const Color(0xFFE08C00),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),

                // Title + plot + company
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill['plot_name'] ?? bill['type'] ?? 'Customer',
                        style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Plot: ${bill['plot_id'] ?? 'N/A'}',
                        style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 12,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Company: ${bill['company_name'] ?? ''}',
                        style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 12,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount + PAY NOW / PAID badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!isPaid)
                      GestureDetector(
                        onTap: () => _showPayDialog(bill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E9E4F),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'PAY NOW',
                            style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12B76A).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF12B76A).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'PAID',
                          style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF12B76A),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Divider ──
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white10 : const Color(0xFFEBF0F5),
          ),

          // ── Pay date row ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: isDark
                      ? Colors.white38
                      : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 6),
                Text(
                  'Pay date: $payDateStr',
                  style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 12,
                    color: isDark
                        ? Colors.white54
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.event_rounded,
                  size: 14,
                  color: isDark
                      ? Colors.white38
                      : const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


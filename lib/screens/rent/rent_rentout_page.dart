import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/theme_provider.dart';
import '../../utils/animations.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';
import '../explore_page.dart';
import '../payments/payment_dashboard.dart';
import '../visitor_form_page.dart';

class RentRentoutPage extends StatefulWidget {
  final String userName;
  final String userRole;
  final Map<String, String> userProfile;

  const RentRentoutPage({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userProfile,
  });

  @override
  State<RentRentoutPage> createState() => _RentRentoutPageState();
}

class _RentRentoutPageState extends State<RentRentoutPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _navIndex = -1; // no tab highlighted

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: const Text('Rent & Rentout',
            style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        backgroundColor: AppTheme.brand(context),
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
              fontFamily: 'Arial Narrow',
              fontSize: 14,
              fontWeight: FontWeight.w600),
          tabs: const [
            Tab(
                icon: Icon(Icons.search_rounded, size: 18),
                text: 'Find a House'),
            Tab(
                icon: Icon(Icons.add_home_rounded, size: 18),
                text: 'List My House'),
            Tab(
                icon: Icon(Icons.manage_accounts_rounded, size: 18),
                text: 'My Listings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BrowseListingsTab(isDark: isDark, userProfile: widget.userProfile),
          _PostListingTab(
            isDark: isDark,
            userName: widget.userName,
            userProfile: widget.userProfile,
            onPosted: () => _tabController.animateTo(0),
          ),
          _MyListingsTab(
            isDark: isDark,
            userName: widget.userName,
            userProfile: widget.userProfile,
          ),
        ],
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
    setState(() => _navIndex = index);
    if (index == 0) {
      Navigator.pop(context);
    } else if (index == 1) {
      await Navigator.push(
          context,
          PageAnimations.slideRight(ExplorePage(
              userRole: widget.userRole, userName: widget.userName)));
      if (mounted) setState(() => _navIndex = -1);
    } else if (index == 2) {
      await Navigator.push(
          context,
          PageAnimations.slideRight(PaymentDashboard(
              userId: '',
              userName: widget.userName,
              userRole: widget.userRole,
              apartment: widget.userProfile['apartment'] ?? '',
              phone: widget.userProfile['phone'] ?? '')));
      if (mounted) setState(() => _navIndex = -1);
    } else if (index == 3) {
      await Navigator.push(
          context,
          PageAnimations.slideRight(VisitorFormPage(
              userRole: widget.userRole,
              userName: widget.userName,
              userProfile: widget.userProfile)));
      if (mounted) setState(() => _navIndex = -1);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 1 — Browse / Find a House
// ─────────────────────────────────────────────────────────────
class _BrowseListingsTab extends StatefulWidget {
  final bool isDark;
  final Map<String, String> userProfile;
  const _BrowseListingsTab({required this.isDark, required this.userProfile});

  @override
  State<_BrowseListingsTab> createState() => _BrowseListingsTabState();
}

class _BrowseListingsTabState extends State<_BrowseListingsTab> {
  static String get _base => '${AppConstants.baseUrl}/api/rentals';

  List<Map<String, dynamic>> _listings = [];
  bool _loading = true;
  String _filterBhk = 'All';

  final List<String> _bhkFilters = [
    'All',
    '1 BHK',
    '2 BHK',
    '3 BHK',
    '4+ BHK',
    'Studio'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final q = _filterBhk != 'All'
          ? '?bhk_type=${Uri.encodeQueryComponent(_filterBhk)}'
          : '';
      final res = await http
          .get(Uri.parse('$_base$q'))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _listings = List<Map<String, dynamic>>.from(data['listings']);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _contactOwner(Map<String, dynamic> listing) {
    final phone = listing['owner_phone']?.toString() ?? '';
    final title = listing['title']?.toString() ?? 'the property';
    if (phone.isEmpty) return;
    final num = phone.startsWith('+') ? phone.replaceAll('+', '') : '91$phone';
    final msg = Uri.encodeComponent(
        '👋 Hi! I saw your rental listing *"$title"* on GenNext Community App. I\'m interested. Please contact me.');
    launchUrl(Uri.parse('https://wa.me/$num?text=$msg'),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Column(children: [
      // Header banner
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [AppTheme.brand(context), AppTheme.brandLight(context)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          const Icon(Icons.house_rounded, color: Colors.white, size: 36),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Find Your Home',
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Text('${_listings.length} properties available',
                style: const TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 12,
                    color: Colors.white70)),
          ]),
        ]),
      ),

      // BHK filter chips
      SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _bhkFilters.length,
          itemBuilder: (_, i) {
            final f = _bhkFilters[i];
            final selected = _filterBhk == f;
            return GestureDetector(
              onTap: () {
                setState(() => _filterBhk = f);
                _load();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.brand(context)
                      : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : (isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300)),
                ),
                child: Text(f,
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black54))),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),

      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _listings.isEmpty
                ? _empty(isDark)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: _listings.length,
                      itemBuilder: (_, i) => _listingCard(_listings[i], isDark),
                    ),
                  ),
      ),
    ]);
  }

  Widget _empty(bool isDark) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.house_outlined,
              size: 72,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No listings found',
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 16,
                  color: AppTheme.textColor(context).withOpacity(0.45))),
          const SizedBox(height: 6),
          Text('Be the first to list a property!',
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 12,
                  color: AppTheme.textColor(context).withOpacity(0.38))),
        ]),
      );

  Widget _listingCard(Map<String, dynamic> l, bool isDark) {
    final images = l['images'] as List?;
    final firstImage = normalizeRentalImageValue(images?.first);
    final hasImage = firstImage.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // House image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: hasImage
              ? _Base64Image(
                  base64Str: firstImage,
                  height: 180,
                )
              : Container(
                  height: 160,
                  color:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  child: Center(
                      child: Icon(Icons.house_rounded,
                          size: 64,
                          color:
                              isDark ? Colors.white24 : Colors.grey.shade300)),
                ),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Title + BHK badge
            Row(children: [
              Expanded(
                child: Text(l['title'] ?? '',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (l['bhk_type'] != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppTheme.brand(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(l['bhk_type'],
                      style: const TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6A1B9A))),
                ),
            ]),
            const SizedBox(height: 6),

            // Location
            if (l['location'] != null && l['location'].toString().isNotEmpty)
              Row(children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: AppTheme.brand(context)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(l['location'],
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 12,
                          color: AppTheme.textColor(context).withOpacity(0.54)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            const SizedBox(height: 8),

            // Rent + Advance
            Row(children: [
              Expanded(
                child: _amountBox(
                  icon: Icons.currency_rupee,
                  label: 'Rent / month',
                  value: '₹${l['rent_amount']}',
                  color: const Color(0xFF2E7D32),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _amountBox(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Advance',
                  value: l['advance_amount'] != null
                      ? '₹${l['advance_amount']}'
                      : 'Negotiable',
                  color: const Color(0xFFE65100),
                  isDark: isDark,
                ),
              ),
            ]),
            const SizedBox(height: 10),

            // Furnishing badge
            if (l['furnishing'] != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                    l['furnishing']
                        .toString()
                        .replaceAll('_', ' ')
                        .toUpperCase(),
                    style: const TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.teal)),
              ),

            if (l['description'] != null &&
                l['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l['description'],
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 12,
                      color: AppTheme.textColor(context).withOpacity(0.54)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Owner info + Contact button
            Row(children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    '${l['owner_name'] ?? 'Owner'} • ${l['owner_apartment'] ?? ''}',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 12,
                        color: AppTheme.textColor(context).withOpacity(0.45))),
              ),
              GestureDetector(
                onTap: () => _contactOwner(l),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Row(children: [
                    Icon(Icons.chat, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('WhatsApp',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ]),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _amountBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 10,
                color: AppTheme.textColor(context).withOpacity(0.45))),
        const SizedBox(height: 2),
        Row(children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 2),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 2 — Post / List My House
// ─────────────────────────────────────────────────────────────
class _PostListingTab extends StatefulWidget {
  final bool isDark;
  final String userName;
  final Map<String, String> userProfile;
  final VoidCallback onPosted;

  const _PostListingTab({
    required this.isDark,
    required this.userName,
    required this.userProfile,
    required this.onPosted,
  });

  @override
  State<_PostListingTab> createState() => _PostListingTabState();
}

class _PostListingTabState extends State<_PostListingTab> {
  static String get _base => '${AppConstants.baseUrl}/api/rentals';

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _advanceCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _bhkType = '2 BHK';
  String _furnishing = 'unfurnished';
  final List<File> _images = [];
  bool _submitting = false;

  final List<String> _bhkOptions = [
    '1 BHK',
    '2 BHK',
    '3 BHK',
    '4+ BHK',
    'Studio'
  ];
  final List<Map<String, String>> _furnishingOptions = [
    {'value': 'unfurnished', 'label': 'Unfurnished'},
    {'value': 'semi_furnished', 'label': 'Semi Furnished'},
    {'value': 'fully_furnished', 'label': 'Fully Furnished'},
  ];

  @override
  void initState() {
    super.initState();
    // Contact number left empty — creator fills it in themselves
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _rentCtrl.dispose();
    _advanceCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 60, limit: 5);
    if (picked.isNotEmpty && mounted) {
      setState(() {
        for (final x in picked) {
          if (_images.length < 5) _images.add(File(x.path));
        }
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 60);
    if (picked != null && mounted && _images.length < 5) {
      setState(() => _images.add(File(picked.path)));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Add House Photo',
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: _srcBtn(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: AppTheme.brand(context),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _srcBtn(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: AppTheme.brand(context),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages();
                  }),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _srcBtn(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final phone = _phoneCtrl.text.trim().isNotEmpty
          ? _phoneCtrl.text.trim()
          : (prefs.getString('user_phone') ??
              widget.userProfile['phone'] ??
              '');

      // Convert images to base64
      final imageBase64List = <String>[];
      for (final f in _images) {
        final bytes = await f.readAsBytes();
        imageBase64List.add('data:image/jpeg;base64,${base64Encode(bytes)}');
      }

      final res = await http
          .post(
            Uri.parse(_base),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'owner_id': userId != null ? int.tryParse(userId) : null,
              'owner_name': widget.userName,
              'owner_phone': phone,
              'owner_apartment': widget.userProfile['unitNumber'] ??
                  widget.userProfile['apartment'] ??
                  '',
              'title': _titleCtrl.text.trim(),
              'description': _descCtrl.text.trim(),
              'location': _locationCtrl.text.trim(),
              'rent_amount': _rentCtrl.text.trim(),
              'advance_amount': _advanceCtrl.text.trim().isNotEmpty
                  ? _advanceCtrl.text.trim()
                  : null,
              'bhk_type': _bhkType,
              'furnishing': _furnishing,
              'images': imageBase64List,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (data['success'] == true) {
        _showSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data['message'] ?? 'Failed'),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(children: [
          Icon(Icons.check_circle, color: Color(0xFF6A1B9A), size: 60),
          SizedBox(height: 10),
          Text('Listing Posted!',
              style: TextStyle(
                  fontFamily: 'Arial Narrow', fontWeight: FontWeight.w700)),
        ]),
        content: const Text(
            'Your property is now listed. Interested people will contact you via WhatsApp.',
            style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 13),
            textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _titleCtrl.clear();
              _descCtrl.clear();
              _locationCtrl.clear();
              _rentCtrl.clear();
              _advanceCtrl.clear();
              setState(() => _images.clear());
              widget.onPosted(); // switch to browse tab
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brand(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('View Listings',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppTheme.brand(context),
                AppTheme.brandLight(context)
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.add_home_rounded, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text('List Your Property',
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  SizedBox(height: 4),
                  Text(
                      'Fill in the details — renters will WhatsApp you directly',
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 12,
                          color: Colors.white70)),
                ]),
          ),
          const SizedBox(height: 20),

          // ── House Photos ──────────────────────────────────────
          _sectionLabel('House Photos (up to 5)', isDark),
          const SizedBox(height: 8),
          _imageGrid(isDark),
          const SizedBox(height: 18),

          // ── Title ─────────────────────────────────────────────
          _sectionLabel('Property Title *', isDark),
          const SizedBox(height: 6),
          _field(_titleCtrl, 'e.g. 2BHK Flat in Green Park', isDark,
              validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 14),

          // ── Location ──────────────────────────────────────────
          _sectionLabel('Location / Area *', isDark),
          const SizedBox(height: 6),
          _field(_locationCtrl, 'e.g. Anna Nagar, Chennai', isDark,
              icon: Icons.location_on_outlined,
              validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 14),

          // ── BHK Type ──────────────────────────────────────────
          _sectionLabel('BHK Type', isDark),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bhkOptions
                .map((b) => GestureDetector(
                      onTap: () => setState(() => _bhkType = b),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _bhkType == b
                              ? AppTheme.brand(context)
                              : (isDark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _bhkType == b
                                  ? Colors.transparent
                                  : (isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300)),
                        ),
                        child: Text(b,
                            style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _bhkType == b
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black54))),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),

          // ── Furnishing ────────────────────────────────────────
          _sectionLabel('Furnishing', isDark),
          const SizedBox(height: 8),
          Row(
            children: _furnishingOptions.map((opt) {
              final selected = _furnishing == opt['value'];
              final isLast = opt == _furnishingOptions.last;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _furnishing = opt['value']!),
                  child: Container(
                    margin: EdgeInsets.only(right: isLast ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.brand(context)
                          : (isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : (isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300)),
                    ),
                    child: Center(
                      child: Text(opt['label']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.white70
                                      : Colors.black54))),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // ── Rent Amount ───────────────────────────────────────
          _sectionLabel('Monthly Rent (₹) *', isDark),
          const SizedBox(height: 6),
          _field(_rentCtrl, 'e.g. 12000', isDark,
              icon: Icons.currency_rupee,
              type: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 14),

          // ── Advance Amount ────────────────────────────────────
          _sectionLabel('Advance Amount (₹)  — optional', isDark),
          const SizedBox(height: 6),
          _field(_advanceCtrl, 'e.g. 50000 or leave blank', isDark,
              icon: Icons.account_balance_wallet_outlined,
              type: TextInputType.number),
          const SizedBox(height: 14),

          // ── Contact Phone ─────────────────────────────────────
          _sectionLabel('Your Contact Number *', isDark),
          const SizedBox(height: 6),
          _field(_phoneCtrl, 'Enter Your Number ', isDark,
              icon: Icons.phone_outlined,
              type: TextInputType.phone,
              validator: (v) => v!.length < 10 ? 'Enter valid number' : null),
          const SizedBox(height: 14),

          // ── Description ───────────────────────────────────────
          _sectionLabel('Description  — optional', isDark),
          const SizedBox(height: 6),
          _field(_descCtrl,
              'Any extra details: floor, parking, nearby landmarks...', isDark,
              maxLines: 4),
          const SizedBox(height: 28),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Icon(Icons.publish_rounded, color: Colors.white),
              label: const Text('Post Listing',
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brand(context),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _imageGrid(bool isDark) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add button
          if (_images.length < 5)
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: 90,
                height: 90,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 28,
                          color:
                              isDark ? Colors.white38 : Colors.grey.shade400),
                      const SizedBox(height: 4),
                      Text('Add',
                          style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade500)),
                    ]),
              ),
            ),
          // Picked images
          ..._images.asMap().entries.map((e) => Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    margin: const EdgeInsets.only(right: 8),
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(e.value, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(e.key)),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(3),
                        child: const Icon(Icons.close,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) => Text(text,
      style: TextStyle(
          fontFamily: 'Arial Narrow',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textColor(context)));

  Widget _field(
    TextEditingController ctrl,
    String hint,
    bool isDark, {
    IconData icon = Icons.edit_outlined,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
          fontFamily: 'Arial Narrow',
          fontSize: 14,
          color: AppTheme.textColor(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: 'Arial Narrow',
            fontSize: 13,
            color: AppTheme.textColor(context).withOpacity(0.38)),
        prefixIcon: Icon(icon, size: 20, color: AppTheme.brand(context)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.brand(context), width: 2)),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 3 — My Listings (creator view with delete)
// ─────────────────────────────────────────────────────────────
class _MyListingsTab extends StatefulWidget {
  final bool isDark;
  final String userName;
  final Map<String, String> userProfile;

  const _MyListingsTab({
    required this.isDark,
    required this.userName,
    required this.userProfile,
  });

  @override
  State<_MyListingsTab> createState() => _MyListingsTabState();
}

class _MyListingsTabState extends State<_MyListingsTab> {
  static String get _base => '${AppConstants.baseUrl}/api/rentals';

  List<Map<String, dynamic>> _listings = [];
  bool _loading = true;
  String _ownerId = '';

  @override
  void initState() {
    super.initState();
    _loadOwnerId();
  }

  Future<void> _loadOwnerId() async {
    final prefs = await SharedPreferences.getInstance();
    _ownerId = prefs.getString('user_id') ?? '';
    await _load();
  }

  Future<void> _load() async {
    if (_ownerId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http
          .get(Uri.parse('$_base/my-listings/$_ownerId'))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _listings = List<Map<String, dynamic>>.from(data['listings']);
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteListing(Map<String, dynamic> listing) async {
    final id = listing['id'];
    final title = listing['title']?.toString() ?? 'this listing';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.delete_outline, color: Colors.red, size: 26),
          SizedBox(width: 10),
          Text('Delete Listing',
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ]),
        content: Text(
          'Are you sure you want to delete "$title"?\nThis cannot be undone.',
          style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Arial Narrow')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete',
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    color: Colors.white,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await http
          .delete(Uri.parse('$_base/$id'))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data['success'] == true) {
        setState(() => _listings.removeWhere((l) => l['id'] == id));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Listing deleted',
              style: TextStyle(fontFamily: 'Arial Narrow')),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message'] ?? 'Delete failed',
              style: const TextStyle(fontFamily: 'Arial Narrow')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e',
              style: const TextStyle(fontFamily: 'Arial Narrow')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Column(children: [
      // Header banner
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [AppTheme.brand(context), AppTheme.brandLight(context)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          const Icon(Icons.manage_accounts_rounded,
              color: Colors.white, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('My Listed Properties',
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              Text(
                  '${_listings.length} listing${_listings.length == 1 ? '' : 's'} by you',
                  style: const TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 12,
                      color: Colors.white70)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ]),
      ),

      // List
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _listings.isEmpty
                ? _empty(isDark)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _listings.length,
                      itemBuilder: (_, i) =>
                          _myListingCard(_listings[i], isDark),
                    ),
                  ),
      ),
    ]);
  }

  Widget _empty(bool isDark) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.home_work_outlined,
              size: 72,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          const SizedBox(height: 12),
          Text("You haven't listed any properties yet",
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 15,
                  color: AppTheme.textColor(context).withOpacity(0.45))),
          const SizedBox(height: 6),
          Text('Go to "List My House" to post one!',
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 12,
                  color: AppTheme.textColor(context).withOpacity(0.38))),
        ]),
      );

  Widget _myListingCard(Map<String, dynamic> l, bool isDark) {
    final images = l['images'] as List?;
    final firstImage = normalizeRentalImageValue(images?.first);
    final hasImage = firstImage.isNotEmpty;
    final status = l['status']?.toString() ?? 'available';
    final isRented = status == 'rented';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
                isRented ? Colors.green.withOpacity(0.4) : Colors.transparent,
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Image
        if (hasImage)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: _Base64Image(base64Str: firstImage, height: 160),
          ),

        Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Title + status badge
            Row(children: [
              Expanded(
                child: Text(l['title'] ?? '',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: isRented
                        ? Colors.green.withOpacity(0.15)
                        : AppTheme.brand(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(isRented ? 'Rented' : 'Available',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isRented
                            ? Colors.green.shade700
                            : const Color(0xFF6A1B9A))),
              ),
            ]),
            const SizedBox(height: 6),

            // Location
            if (l['location'] != null && l['location'].toString().isNotEmpty)
              Row(children: [
                Icon(Icons.location_on_outlined,
                    size: 13, color: AppTheme.brand(context)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(l['location'],
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 12,
                          color: AppTheme.textColor(context).withOpacity(0.54)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            const SizedBox(height: 8),

            // Rent + BHK row
            Row(children: [
              const Icon(Icons.currency_rupee,
                  size: 14, color: Color(0xFF2E7D32)),
              Text('${l['rent_amount']} / mo',
                  style: const TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32))),
              const SizedBox(width: 12),
              if (l['bhk_type'] != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppTheme.brand(context).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(l['bhk_type'],
                      style: const TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6A1B9A))),
                ),
              const Spacer(),
              // Contact phone display
              if (l['owner_phone'] != null &&
                  l['owner_phone'].toString().isNotEmpty)
                Row(children: [
                  const Icon(Icons.phone_outlined,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text(l['owner_phone'],
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 11,
                          color:
                              AppTheme.textColor(context).withOpacity(0.45))),
                ]),
            ]),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Action row — delete button
            Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(_formatDate(l['created_at']?.toString() ?? ''),
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 11,
                      color: AppTheme.textColor(context).withOpacity(0.38))),
              const Spacer(),
              // Delete button
              GestureDetector(
                onTap: () => _deleteListing(l),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.3))),
                  child: const Row(children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 15),
                    SizedBox(width: 4),
                    Text('Delete',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.red)),
                  ]),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = [
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
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

String normalizeRentalImageValue(dynamic value) {
  if (value == null) return '';

  if (value is List && value.isNotEmpty) {
    return normalizeRentalImageValue(value.first);
  }

  if (value is! String) {
    return value.toString();
  }

  var imageValue = value.trim();
  if (imageValue.isEmpty) return '';

  if (imageValue.startsWith('[') && imageValue.endsWith(']')) {
    imageValue = imageValue.substring(1, imageValue.length - 1).trim();
  }

  if (imageValue.startsWith('{') && imageValue.endsWith('}')) {
    final jsonText = imageValue.replaceAll(RegExp(r'^[{\[]|[}\]]$'), '').trim();
    if (jsonText.isNotEmpty) {
      imageValue =
          jsonText.replaceAll('"', '').replaceAll(RegExp(r'^,|,$'), '').trim();
    }
  }

  if (imageValue.startsWith('"') && imageValue.endsWith('"')) {
    imageValue = imageValue.substring(1, imageValue.length - 1).trim();
  }

  if (imageValue.contains('data:image') ||
      imageValue.startsWith('http://') ||
      imageValue.startsWith('https://') ||
      imageValue.startsWith('file:') ||
      imageValue.startsWith('/') ||
      imageValue.contains('.jpg') ||
      imageValue.contains('.jpeg') ||
      imageValue.contains('.png') ||
      imageValue.contains('.webp')) {
    return imageValue;
  }

  if (imageValue.startsWith('[') ||
      imageValue.contains(',') && !imageValue.contains('base64,')) {
    final cleaned = imageValue.replaceAll(RegExp(r'^[\[\{]+|[\]\}]+$'), '');
    final firstPart = cleaned.split(',').first.trim();
    return firstPart.isNotEmpty ? firstPart : imageValue;
  }

  return imageValue;
}

// ─────────────────────────────────────────────────────────────
// Helper — decode base64 image stored in DB
// ─────────────────────────────────────────────────────────────
class _Base64Image extends StatelessWidget {
  final String base64Str;
  final double height;

  const _Base64Image({required this.base64Str, required this.height});

  @override
  Widget build(BuildContext context) {
    try {
      final raw =
          base64Str.contains(',') ? base64Str.split(',').last : base64Str;
      final bytes = base64Decode(raw);
      return Image.memory(bytes,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(height));
    } catch (_) {
      return _placeholder(height);
    }
  }

  Widget _placeholder(double h) => Container(
        height: h,
        color: Colors.grey.shade200,
        child: const Center(
            child: Icon(Icons.broken_image_outlined,
                size: 40, color: Colors.grey)),
      );
}

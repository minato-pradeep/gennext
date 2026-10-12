import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class Offer {
  final int id;
  final String title;
  final String description;
  final String storeName;
  final String couponCode;
  final String discount;
  final String validUntil;
  final String category;
  final IconData icon;
  final List<Color> gradient;
  final String imageAsset;

  Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.storeName,
    required this.couponCode,
    required this.discount,
    required this.validUntil,
    required this.category,
    required this.icon,
    required this.gradient,
    required this.imageAsset,
  });
}

class OffersPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final bool isAdmin;
  final String? selectedOfferId;

  const OffersPage({
    super.key,
    required this.userRole,
    required this.userName,
    this.isAdmin = false,
    this.selectedOfferId,
  });

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> with TickerProviderStateMixin {
  String _selectedCategory = 'All';
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final List<String> _categories = ['All', 'Shopping', 'Fashion', 'Grocery', 'Electronics', 'Food', 'Travel'];

  List<Offer> get _offers => [
    Offer(id: 1, title: 'Amazon Great Sale', description: 'Up to 80% off on electronics, mobiles, laptops & accessories. Limited period!', storeName: 'Amazon', couponCode: 'AMZN80', discount: '80% OFF', validUntil: '31 Dec', category: 'Shopping', icon: Icons.shopping_bag_rounded, gradient: [AppTheme.brand(context), AppTheme.brand(context)], imageAsset: 'assets/offers/amazon_watch.jpg'),
    Offer(id: 2, title: 'Flipkart Big Days', description: 'Flat 50% off on fashion, footwear & watches. Extra 10% off on bank cards.', storeName: 'Flipkart', couponCode: 'FLIP50', discount: '50% OFF', validUntil: '25 Dec', category: 'Fashion', icon: Icons.style_rounded, gradient: [AppTheme.brand(context), AppTheme.brand(context)], imageAsset: 'assets/offers/flipkart_fashion.jpg'),
    Offer(id: 3, title: 'FreshMart Supermarket', description: '20% off on first order above ₹500. Free delivery on orders above ₹300.', storeName: 'FreshMart', couponCode: 'FRESH20', discount: '20% OFF', validUntil: '20 Dec', category: 'Grocery', icon: Icons.local_grocery_store_rounded, gradient: [const Color(0xFF12B76A), const Color(0xFF0E9558)], imageAsset: 'assets/offers/freshmart_grocery.jpg'),
    Offer(id: 4, title: 'Swiggy Food Delivery', description: 'Flat ₹100 off on orders above ₹300. Valid for first 5 orders.', storeName: 'Swiggy', couponCode: 'SWIGGY100', discount: '₹100 OFF', validUntil: '28 Dec', category: 'Food', icon: Icons.fastfood_rounded, gradient: [const Color(0xFFF79009), const Color(0xFFE67A00)], imageAsset: 'assets/offers/swiggy_food.jpg'),
    Offer(id: 5, title: 'MakeMyTrip Travel', description: '10% cashback on flight and hotel bookings. Max cashback ₹1500.', storeName: 'MakeMyTrip', couponCode: 'MMT10', discount: '10% OFF', validUntil: '30 Dec', category: 'Travel', icon: Icons.flight_rounded, gradient: [AppTheme.brand(context), AppTheme.brand(context)], imageAsset: 'assets/offers/mmt_travel.jpg'),
    Offer(id: 6, title: 'Croma Electronics', description: 'Extra ₹2000 off on purchase above ₹25000. All electronics included.', storeName: 'Croma', couponCode: 'CROMA2K', discount: '₹2000 OFF', validUntil: '27 Dec', category: 'Electronics', icon: Icons.devices_rounded, gradient: [AppTheme.brand(context), AppTheme.brand(context)], imageAsset: 'assets/offers/croma_laptop.jpg'),
    Offer(id: 7, title: 'Myntra Fashion Sale', description: 'Flat 40% off on all branded fashion. Extra 15% off on first purchase.', storeName: 'Myntra', couponCode: 'MYNTRA40', discount: '40% OFF', validUntil: '29 Dec', category: 'Fashion', icon: Icons.checkroom_rounded, gradient: [AppTheme.brand(context), AppTheme.brand(context)], imageAsset: 'assets/offers/myntra_shoes.jpg'),
    Offer(id: 8, title: 'BigBasket Grocery', description: '25% off on first order. Min order ₹400. Free delivery above ₹600.', storeName: 'BigBasket', couponCode: 'BIG25', discount: '25% OFF', validUntil: '26 Dec', category: 'Grocery', icon: Icons.shopping_basket_rounded, gradient: [const Color(0xFF12B76A), const Color(0xFF0E9558)], imageAsset: 'assets/offers/bigbasket_grocery.jpg'),
  ];

  List<Offer> get _filtered => _selectedCategory == 'All' ? _offers : _offers.where((o) => o.category == _selectedCategory).toList();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('"$code" copied!', style: const TextStyle(fontFamily: 'Arial Narrow', fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: AppTheme.brand(context),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // iOS-style large title app bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_ios_new, size: 16, color: isDark ? Colors.white : Colors.black87),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              title: null,
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('Deals & Coupons', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                  Text('${filtered.length} offers available', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 13, color: isDark ? Colors.white54 : Colors.black45)),
                ]),
              ),
            ),
          ),

          // Category pills
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedCategory = cat); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.brand(context) : (isDark ? Colors.white.withOpacity(0.08) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected ? [BoxShadow(color: AppTheme.brand(context).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))] : [],
                      ),
                      child: Text(cat, style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54))),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Offers list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final offer = filtered[i];
                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: _offerCard(offer, isDark, i),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _offerCard(Offer offer, bool isDark, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SizedBox(
            height: 168,
            width: double.infinity,
            child: Stack(fit: StackFit.expand, children: [
              Image.asset(
                offer.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: offer.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.12), Colors.black.withOpacity(0.78)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: Icon(offer.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(offer.storeName, style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                      child: Text(offer.category, style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Text(offer.discount, style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 16, fontWeight: FontWeight.w800, color: offer.gradient[0])),
                  ),
                ]),
              ),
            ]),
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(offer.title, style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87))),
              Row(children: [
                Icon(Icons.access_time_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                const SizedBox(width: 4),
                Text('Till ${offer.validUntil}', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
              ]),
            ]),
            const SizedBox(height: 6),
            Text(offer.description, style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 12, height: 1.5, color: isDark ? Colors.white54 : Colors.black45), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),

            // Coupon code row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : offer.gradient[0].withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: offer.gradient[0].withOpacity(0.2), width: 1.5),
              ),
              child: Row(children: [
                Icon(Icons.confirmation_number_rounded, color: offer.gradient[0], size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Coupon Code', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
                  Text(offer.couponCode, style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 15, fontWeight: FontWeight.w800, color: offer.gradient[0], letterSpacing: 1.5)),
                ])),
                GestureDetector(
                  onTap: () => _copyCode(offer.couponCode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: offer.gradient),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: offer.gradient[0].withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: const Row(children: [
                      Icon(Icons.copy_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text('Copy', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

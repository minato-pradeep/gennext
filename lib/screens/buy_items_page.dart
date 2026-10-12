import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/buy_sell_service.dart';
import '../models/buy_sell_item.dart';
import '../theme/app_theme.dart';
import '../services/haptic_service.dart';
import '../widgets/listing_image.dart';

class BuyItemsPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final Map<String, String> userProfile;

  const BuyItemsPage({
    super.key,
    required this.userRole,
    required this.userName,
    required this.userProfile,
  });

  @override
  State<BuyItemsPage> createState() => _BuyItemsPageState();
}

class _BuyItemsPageState extends State<BuyItemsPage> with TickerProviderStateMixin {
  final _service = BuySellService();
  List<BuySellItem> _items = [];
  bool _loading = false;
  String _selectedCategory = 'All';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = ['All', 'Electronics', 'Furniture', 'Clothing', 'Books', 'Vehicles', 'Other'];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadItems();
    _service.addListener(_onItemsUpdate);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _service.removeListener(_onItemsUpdate);
    _fadeController.dispose();
    super.dispose();
  }

  void _onItemsUpdate() {
    if (mounted) _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      final items = await _service.getAllItems(category: _selectedCategory);
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _contactSeller(String phoneNumber, String itemName) async {
    final message = "Hi! I'm interested in your item '$itemName' listed on BlueBug Community App. Is it still available?";
    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = "https://wa.me/$phoneNumber?text=$encodedMessage";
    try {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please install WhatsApp to contact seller'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text('Buy Items', style: AppTheme.titleLarge.copyWith(color: Colors.white)),
        backgroundColor: AppTheme.brand(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
          children: [
            // ── Simple search/info bar ──────────────────
            Container(
              color: AppTheme.brand(context),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(children: [
                const Icon(Icons.shopping_cart_outlined,
                    color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text('Find great deals from your neighbors',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8))),
              ]),
            ),

            // ── Category filter ─────────────────────────
            Container(
              color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = category);
                        _loadItems();
                        HapticService.selection();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.brand(context)
                              : (isDark ? AppTheme.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark
                                    ? AppTheme.darkDivider
                                    : AppTheme.lightDivider),
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.white70
                                      : Colors.black54)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // thin divider
            Divider(
                height: 1,
                color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),

            // ── Items list ──────────────────────────────
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.brand(context)))
                  : _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined,
                                  size: 72,
                                  color: isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade400),
                              const SizedBox(height: 14),
                              Text('No items found',
                                  style: AppTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text('Try another category',
                                  style: AppTheme.bodySmall),
                            ],
                          ),
                        )
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: RefreshIndicator(
                            color: AppTheme.brand(context),
                            onRefresh: _loadItems,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              itemCount: _items.length,
                              itemBuilder: (_, i) =>
                                  _buildItemCard(_items[i], isDark),
                            ),
                          ),
                        ),
            ),
          ],
        ),
    );
  }

  Widget _buildItemCard(BuySellItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: GestureDetector(
                  onTap: () => showListingImagePreview(context, item.imageUrl),
                  child: ListingImage(
                    imageData: item.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Category Badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(fontFamily: 'Arial Narrow', 
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Price Badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.brand(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₹${item.price}',
                    style: const TextStyle(fontFamily: 'Arial Narrow', 
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Name and Price Type
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.itemName,
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.priceType == 'fixed'
                            ? AppTheme.success.withOpacity(0.1)
                            : AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.priceType == 'fixed' ? 'Fixed Price' : 'Negotiable',
                        style: TextStyle(fontFamily: 'Arial Narrow', 
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: item.priceType == 'fixed' ? AppTheme.success : AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  item.description,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textColor(context).withOpacity(0.54),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Divider
                Divider(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                const SizedBox(height: 8),
                
                // Seller Info and Actions
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.brand(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person_outline, size: 20, color: AppTheme.brand(context)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.sellerName,
                            style: AppTheme.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Apartment: ${item.sellerApartment}',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.textColor(context).withOpacity(0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _contactSeller(item.sellerPhone, item.itemName),
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('Contact'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
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
    );
  }
}
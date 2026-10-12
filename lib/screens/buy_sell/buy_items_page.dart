import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/buy_sell_service.dart';
import '../../models/buy_sell_item.dart';
import '../../theme/app_theme.dart';
import '../../services/haptic_service.dart';
import '../../widgets/listing_image.dart';

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
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String? _error;

  final List<String> _categories = ['All', 'Electronics', 'Furniture', 'Clothing', 'Books', 'Vehicles', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadItems();
    _service.addListener(_loadItems);
  }

  @override
  void dispose() {
    _service.removeListener(_loadItems);
    super.dispose();
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final items = await _service.getAllItems(category: _selectedCategory);
      if (mounted) setState(() { _items = items; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _contactSeller(String phoneNumber, String itemName) async {
    final message = "Hi! I'm interested in your item '$itemName' listed on BlueBug Community App. Is it still available?";
    final whatsappUrl = "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}";
    try {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please install WhatsApp to contact seller'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: Text('Buy Items', style: AppTheme.titleLarge.copyWith(color: Colors.white)),
        backgroundColor: AppTheme.brand(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
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
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.brandLight(context), AppTheme.brand(context)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppTheme.brandLight(context).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shopping_cart, color: Colors.white, size: 32),
                      SizedBox(height: 12),
                      Text('Browse Items', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                      SizedBox(height: 4),
                      Text('Find great deals from your neighbors', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),

                // Category Filter
                SizedBox(
                  height: 45,
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
                          HapticService.selection();
                          _loadItems();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            gradient: isSelected ? LinearGradient(colors: [AppTheme.brandLight(context), AppTheme.brand(context)]) : null,
                            color: isSelected ? null : (isDark ? AppTheme.darkCard : Colors.white),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: isSelected ? Colors.transparent : (isDark ? AppTheme.darkDivider : Colors.grey.shade300)),
                            boxShadow: isSelected ? [BoxShadow(color: AppTheme.brandLight(context).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
                          ),
                          child: Center(
                            child: Text(category, style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54))),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Items List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 60, color: AppTheme.error),
                                const SizedBox(height: 12),
                                Text('Failed to load items', style: AppTheme.titleMedium),
                                const SizedBox(height: 8),
                                ElevatedButton(onPressed: _loadItems, child: const Text('Retry')),
                              ],
                            ))
                          : _items.isEmpty
                              ? Center(child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_cart_outlined, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    Text('No items found', style: AppTheme.titleMedium),
                                    const SizedBox(height: 8),
                                    Text('Try another category', style: AppTheme.bodySmall),
                                  ],
                                ))
                              : RefreshIndicator(
                                  onRefresh: _loadItems,
                                  color: AppTheme.brand(context),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _items.length,
                                    itemBuilder: (context, index) => _buildItemCard(_items[index], isDark),
                                  ),
                                ),
                ),
              ],
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
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
              Positioned(
                top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(15)),
                  child: Text(item.category, style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              Positioned(
                top: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFF57C00)]), borderRadius: BorderRadius.circular(20)),
                  child: Text('₹${item.price}', style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(item.itemName, style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.priceType == 'fixed' ? AppTheme.success.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.priceType == 'fixed' ? 'Fixed Price' : 'Negotiable',
                        style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 10, fontWeight: FontWeight.w600, color: item.priceType == 'fixed' ? AppTheme.success : AppTheme.warning),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item.description, style: AppTheme.bodySmall.copyWith(color: isDark ? Colors.white70 : Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Divider(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: AppTheme.brand(context).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.person_outline, size: 20, color: AppTheme.brand(context)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.sellerName, style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                          Text('Apartment: ${item.sellerApartment}', style: AppTheme.caption.copyWith(color: isDark ? Colors.white54 : Colors.black45)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
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

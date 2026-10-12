import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/buy_sell_service.dart';
import '../models/buy_sell_item.dart';
import '../theme/app_theme.dart';
import '../widgets/listing_image.dart';

class SellItemPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final Map<String, String> userProfile;

  const SellItemPage({
    super.key,
    required this.userRole,
    required this.userName,
    required this.userProfile,
  });

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage>
    with SingleTickerProviderStateMixin {
  // ── Form ──────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _itemNameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _priceType = 'fixed';
  String _category = 'Other';
  File? _selectedImage;
  bool _isSubmitting = false;

  // ── My Listings ───────────────────────────────────────
  List<BuySellItem> _myItems = [];
  bool _loadingMyItems = false;
  late TabController _tabController;

  final _service = BuySellService();
  final _picker = ImagePicker();
  final List<String> _categories = [
    'Electronics', 'Furniture', 'Clothing', 'Books', 'Vehicles', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Refresh listings whenever user switches to My Listings tab
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        _loadMyItems();
      }
    });
    _service.addListener(_loadMyItems);
    _loadMyItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemNameCtrl.dispose();
    _priceCtrl.dispose();
    _descriptionCtrl.dispose();
    _service.removeListener(_loadMyItems);
    super.dispose();
  }

  // ── Load seller's own items ───────────────────────────
  Future<void> _loadMyItems() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    if (userId.isEmpty) return;

    setState(() => _loadingMyItems = true);
    try {
      final items = await _service.getMyItems(userId);
      if (mounted) setState(() { _myItems = items; _loadingMyItems = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingMyItems = false);
    }
  }

  // ── Pick image ────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.brand(context)),
              title: const Text('Choose from Gallery'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
          ListTile(
              leading: Icon(Icons.camera_alt, color: AppTheme.brand(context)),
              title: const Text('Take a Photo'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
        ]),
      ),
    );
  }

  // ── Submit new listing ────────────────────────────────
  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final phone = prefs.getString('user_phone') ?? widget.userProfile['phone'] ?? '';
      final apartment = prefs.getString('user_apartment') ?? widget.userProfile['unitNumber'] ?? '';

      String imageData = '';
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        imageData = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      final item = BuySellItem(
        id: '',
        itemName: _itemNameCtrl.text.trim(),
        price: _priceCtrl.text.trim(),
        priceType: _priceType,
        description: _descriptionCtrl.text.trim(),
        imageUrl: imageData,
        sellerId: userId,
        sellerName: widget.userName,
        sellerPhone: phone,
        sellerApartment: apartment,
        category: _category,
        status: 'active',
        dateTime: DateTime.now().toString(),
      );

      await _service.addItem(item);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _selectedImage = null;
        _itemNameCtrl.clear();
        _priceCtrl.clear();
        _descriptionCtrl.clear();
      });
      _loadMyItems();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(children: [
            Icon(Icons.check_circle, color: Color(0xFF12B76A), size: 60),
            SizedBox(height: 10),
            Text('Item Posted!', style: TextStyle(fontFamily: 'Arial Narrow', fontWeight: FontWeight.w700)),
          ]),
          content: const Text(
              'Your item is now listed. Buyers can see it in Buy Items.',
              style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 13),
              textAlign: TextAlign.center),
          actions: [
            ElevatedButton(
              onPressed: () { Navigator.pop(context); },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brand(context),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // ── Mark as Sold ──────────────────────────────────────
  void _markAsSold(BuySellItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mark as Sold',
            style: TextStyle(fontFamily: 'Arial Narrow', fontWeight: FontWeight.w700)),
        content: Text(
            'Mark "${item.itemName}" as sold?\n\nOnce marked as sold you will be able to delete it.',
            style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.markAsSold(item.id);
                await _loadMyItems();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Marked as sold'),
                      backgroundColor: Color(0xFF12B76A)));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brand(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Mark Sold', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Delete (only allowed when sold) ──────────────────
  void _deleteItem(BuySellItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Item',
            style: TextStyle(fontFamily: 'Arial Narrow', fontWeight: FontWeight.w700)),
        content: Text(
            'Delete "${item.itemName}" permanently?',
            style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.deleteItem(item.id);
                await _loadMyItems();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Item deleted'),
                      backgroundColor: Color(0xFF12B76A)));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Buy & Sell',
            style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 18,
                fontWeight: FontWeight.w600,
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
              fontFamily: 'Arial Narrow', fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Sell Item'),
            Tab(text: 'My Listings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSellForm(isDark),
          _buildMyListings(isDark),
        ],
      ),
    );
  }

  // ── Tab 1: Sell form ──────────────────────────────────
  Widget _buildSellForm(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seller info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
              child: Row(children: [
                Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                        color: AppTheme.brand(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.store, color: AppTheme.brand(context), size: 28)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.userName,
                      style: TextStyle(
                          fontFamily: 'Arial Narrow', fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor(context))),
                  Text('Seller',
                      style: TextStyle(
                          fontFamily: 'Arial Narrow', fontSize: 12,
                          color: AppTheme.textColor(context).withOpacity(0.45))),
                ]),
              ]),
            ),

            const SizedBox(height: 20),

            // Image picker
            _label('Item Image', isDark),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 160, width: double.infinity,
                decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_selectedImage!,
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate,
                            size: 48,
                            color: AppTheme.textColor(context).withOpacity(0.38)),
                        const SizedBox(height: 8),
                        Text('Tap to add image (optional)',
                            style: TextStyle(
                                fontFamily: 'Arial Narrow', fontSize: 12,
                                color: AppTheme.textColor(context).withOpacity(0.38))),
                      ]),
              ),
            ),

            const SizedBox(height: 20),

            _label('Item Name', isDark),
            const SizedBox(height: 8),
            _textField(_itemNameCtrl, 'e.g. Samsung TV, Wooden Table', isDark,
                validator: (v) => v!.isEmpty ? 'Required' : null),

            const SizedBox(height: 16),

            _label('Price (₹)', isDark),
            const SizedBox(height: 8),
            _textField(_priceCtrl, 'e.g. 5000', isDark,
                type: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null),

            const SizedBox(height: 16),

            _label('Price Type', isDark),
            const SizedBox(height: 8),
            Row(
              children: ['fixed', 'negotiable'].map((t) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _priceType = t),
                  child: Container(
                    margin: EdgeInsets.only(right: t == 'fixed' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _priceType == t
                          ? AppTheme.brand(context)
                          : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _priceType == t
                              ? Colors.transparent
                              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                    ),
                    child: Center(
                      child: Text(
                        t == 'fixed' ? 'Fixed Price' : 'Negotiable',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow', fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _priceType == t
                                ? Colors.white
                                : (AppTheme.textColor(context).withOpacity(0.54))),
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),

            const SizedBox(height: 16),

            _label('Category', isDark),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category, isExpanded: true,
                  dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  items: _categories
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c,
                              style: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  color: AppTheme.textColor(context)))))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),
            ),

            const SizedBox(height: 16),

            _label('Description', isDark),
            const SizedBox(height: 8),
            _textField(_descriptionCtrl, 'Describe condition, brand, features...', isDark,
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Required' : null),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitItem,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brand(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Post Item for Sale',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow', fontSize: 16,
                            fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: My Listings ────────────────────────────────
  Widget _buildMyListings(bool isDark) {
    if (_loadingMyItems) {
      return Center(child: CircularProgressIndicator(color: AppTheme.brand(context)));
    }
    if (_myItems.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.storefront_outlined, size: 64,
              color: AppTheme.textColor(context).withOpacity(0.26)),
          const SizedBox(height: 16),
          Text("You haven't listed anything yet",
              style: TextStyle(
                  fontFamily: 'Arial Narrow', fontSize: 15,
                  color: AppTheme.textColor(context).withOpacity(0.45))),
        ]),
      );
    }

    // Info banner
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: AppTheme.brand(context).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.brand(context).withOpacity(0.2))),
          child: Row(children: [
            Icon(Icons.info_outline, size: 16, color: AppTheme.brand(context)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You can only delete an item after marking it as Sold.',
                style: TextStyle(
                    fontFamily: 'Arial Narrow', fontSize: 12,
                    color: AppTheme.brand(context)),
              ),
            ),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.brand(context),
            onRefresh: _loadMyItems,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _myItems.length,
              itemBuilder: (_, i) => _buildMyItemCard(_myItems[i], isDark),
            ),
          ),
        ),
      ],
    );
  }

  // ── My item card ──────────────────────────────────────
  Widget _buildMyItemCard(BuySellItem item, bool isDark) {
    final isSold = item.status == 'sold';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSold
                  ? Colors.grey.shade300
                  : AppTheme.brand(context).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => showListingImagePreview(context, item.imageUrl),
            child: ListingImage(
              imageData: item.imageUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.itemName,
                            style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 15, fontWeight: FontWeight.w700,
                                color: AppTheme.textColor(context)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: isSold
                                ? Colors.grey.withOpacity(0.15)
                                : const Color(0xFF12B76A).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          isSold ? 'Sold' : 'Active',
                          style: TextStyle(
                              fontFamily: 'Arial Narrow', fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSold ? Colors.grey : const Color(0xFF12B76A)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('₹${item.price}  •  ${item.category}',
                      style: TextStyle(
                          fontFamily: 'Arial Narrow', fontSize: 12,
                          color: AppTheme.textColor(context).withOpacity(0.45))),
                  const SizedBox(height: 10),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isSold) ...[
                        // Active: only Mark as Sold — no delete yet
                        OutlinedButton.icon(
                          onPressed: () => _markAsSold(item),
                          icon: const Icon(Icons.sell_outlined, size: 14),
                          label: const Text('Mark as Sold'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.brand(context),
                              side: BorderSide(color: AppTheme.brand(context)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              textStyle: const TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                        ),
                      ] else ...[
                        // Sold: show Delete button
                        ElevatedButton.icon(
                          onPressed: () => _deleteItem(item),
                          icon: const Icon(Icons.delete_outline, size: 14),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              textStyle: const TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────
  Widget _label(String text, bool isDark) => Text(text,
      style: TextStyle(
          fontFamily: 'Arial Narrow', fontSize: 14, fontWeight: FontWeight.w600,
          color: AppTheme.textColor(context)));

  Widget _textField(
    TextEditingController ctrl, String hint, bool isDark, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl, keyboardType: type, maxLines: maxLines, validator: validator,
      style: TextStyle(
          fontFamily: 'Arial Narrow', fontSize: 14,
          color: AppTheme.textColor(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: 'Arial Narrow',
            color: AppTheme.textColor(context).withOpacity(0.38)),
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

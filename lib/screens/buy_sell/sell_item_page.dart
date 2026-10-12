import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/buy_sell_service.dart';
import '../../models/buy_sell_item.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_button.dart';
import '../../services/haptic_service.dart';
import '../../widgets/listing_image.dart';

class SellItemPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final Map<String, String> userProfile;
  final BuySellItem? editItem;

  const SellItemPage({
    super.key,
    required this.userRole,
    required this.userName,
    required this.userProfile,
    this.editItem,
  });

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _itemNameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String _priceType = 'fixed';
  String _selectedCategory = 'Electronics';
  File? _selectedImage;
  bool _isSubmitting = false;
  bool _isEditing = false;

  final _picker = ImagePicker();
  final _service = BuySellService();
  List<BuySellItem> _myItems = [];
  bool _loadingMyItems = false;

  final List<String> _categories = ['Electronics', 'Furniture', 'Clothing', 'Books', 'Vehicles', 'Other'];

  String get _sellerId => widget.userProfile['id'] ?? widget.userProfile['userId'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadMyItems();
    _service.addListener(_loadMyItems);

    if (widget.editItem != null) {
      _isEditing = true;
      _itemNameCtrl.text = widget.editItem!.itemName;
      _priceCtrl.text = widget.editItem!.price;
      _descriptionCtrl.text = widget.editItem!.description;
      _priceType = widget.editItem!.priceType;
      _selectedCategory = widget.editItem!.category;
    }
  }

  @override
  void dispose() {
    _service.removeListener(_loadMyItems);
    _itemNameCtrl.dispose();
    _priceCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMyItems() async {
    if (!mounted || _sellerId.isEmpty) return;
    setState(() => _loadingMyItems = true);
    try {
      final items = await _service.getMyItems(_sellerId);
      if (mounted) setState(() { _myItems = items; _loadingMyItems = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingMyItems = false);
    }
  }

  Future<void> _pickImage() async {
    final f = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (f != null) setState(() => _selectedImage = File(f.path));
  }

  Future<void> _takePhoto() async {
    final f = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (f != null) setState(() => _selectedImage = File(f.path));
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: Icon(Icons.photo_library, color: AppTheme.brand(context)), title: const Text('Choose from Gallery'), onTap: () { Navigator.pop(context); _pickImage(); }),
            ListTile(leading: Icon(Icons.camera_alt, color: AppTheme.brand(context)), title: const Text('Take a Photo'), onTap: () { Navigator.pop(context); _takePhoto(); }),
          ],
        ),
      ),
    );
  }

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null && !_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add an image of your item'), backgroundColor: AppTheme.error));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String imageData = widget.editItem?.imageUrl ?? '';
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        imageData = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      if (_isEditing && widget.editItem != null) {
        await _service.updateItem(widget.editItem!.id, {
          'itemName': _itemNameCtrl.text.trim(),
          'price': _priceCtrl.text.trim(),
          'priceType': _priceType,
          'description': _descriptionCtrl.text.trim(),
          'imageUrl': imageData,
          'category': _selectedCategory,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item updated successfully!'), backgroundColor: AppTheme.success));
          Navigator.pop(context);
        }
      } else {
        final newItem = BuySellItem(
          id: '',
          itemName: _itemNameCtrl.text.trim(),
          price: _priceCtrl.text.trim(),
          priceType: _priceType,
          description: _descriptionCtrl.text.trim(),
          imageUrl: imageData,
          sellerName: widget.userProfile['name'] ?? widget.userName,
          sellerPhone: widget.userProfile['phone'] ?? '',
          sellerApartment: widget.userProfile['apartment'] ?? widget.userProfile['unitNumber'] ?? '',
          dateTime: DateTime.now().toString(),
          status: 'active',
          category: _selectedCategory,
          sellerId: _sellerId,
        );
        await _service.addItem(newItem);
        _itemNameCtrl.clear();
        _priceCtrl.clear();
        _descriptionCtrl.clear();
        if (mounted) {
          setState(() { _selectedImage = null; _priceType = 'fixed'; _selectedCategory = 'Electronics'; });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item posted successfully!'), backgroundColor: AppTheme.success));
        }
      }
      await HapticService.success();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _editItem(BuySellItem item) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SellItemPage(userRole: widget.userRole, userName: widget.userName, userProfile: widget.userProfile, editItem: item),
    ));
  }

  void _deleteItem(BuySellItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusL),
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.itemName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.deleteItem(item.id);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item deleted'), backgroundColor: AppTheme.success));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _markAsSold(BuySellItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusL),
        title: const Text('Mark as Sold'),
        content: Text('Mark "${item.itemName}" as sold?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.markAsSold(item.id);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item marked as sold'), backgroundColor: AppTheme.success));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brand(context)),
            child: const Text('Mark as Sold'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF0F7FF),
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Item' : 'Sell Item', style: AppTheme.titleLarge.copyWith(color: Colors.white)),
          backgroundColor: AppTheme.secondaryGreen,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
          bottom: const TabBar(
            tabs: [Tab(text: 'Sell / Edit'), Tab(text: 'My Items')],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)] : [const Color(0xFFE8F4FD), const Color(0xFFD6EEFC), const Color(0xFFC5E8FB)],
                ),
              ),
            ),
            SafeArea(
              child: TabBarView(
                children: [
                  // Tab 1: Sell/Edit Form
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF66BB6A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: const Color(0xFF43A047).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.storefront, color: Colors.white, size: 32),
                                const SizedBox(height: 12),
                                Text(_isEditing ? 'Edit Item' : 'Sell an Item', style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(_isEditing ? 'Update your item details' : 'Post your item for sale in the community', style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 12, color: Colors.white70)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Image
                          Text('Item Image', style: AppTheme.titleSmall),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                                borderRadius: AppTheme.radiusM,
                                border: Border.all(color: isDark ? AppTheme.darkDivider : Colors.grey.shade300),
                              ),
                              child: _selectedImage != null || (_isEditing && (widget.editItem?.imageUrl.isNotEmpty ?? false))
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: AppTheme.radiusM,
                                          child: _selectedImage != null
                                              ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                              : ListingImage(
                                                  imageData: widget.editItem!.imageUrl,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        Positioned(
                                          top: 8, right: 8,
                                          child: GestureDetector(
                                            onTap: () => setState(() => _selectedImage = null),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: AppTheme.radiusS),
                                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate, size: 50, color: isDark ? Colors.white54 : Colors.black45),
                                        const SizedBox(height: 8),
                                        Text('Tap to add item image', style: AppTheme.bodySmall.copyWith(color: isDark ? Colors.white54 : Colors.black45)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Item Name
                          Text('Item Name', style: AppTheme.titleSmall),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _itemNameCtrl,
                            validator: (v) => v == null || v.isEmpty ? 'Please enter item name' : null,
                            style: AppTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'e.g., Samsung TV, Wooden Table',
                              prefixIcon: const Icon(Icons.title, color: AppTheme.secondaryGreen),
                              border: OutlineInputBorder(borderRadius: AppTheme.radiusM),
                              filled: true,
                              fillColor: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Price
                          Text('Price', style: AppTheme.titleSmall),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.isEmpty ? 'Please enter price' : null,
                            style: AppTheme.bodyMedium,
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              hintText: 'e.g., 5000',
                              border: OutlineInputBorder(borderRadius: AppTheme.radiusM),
                              filled: true,
                              fillColor: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Price Type
                          Text('Price Type', style: AppTheme.titleSmall),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _priceTypeCard('Fixed', 'fixed', Icons.check_circle, isDark)),
                              const SizedBox(width: 12),
                              Expanded(child: _priceTypeCard('Negotiable', 'negotiable', Icons.chat, isDark)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Category
                          Text('Category', style: AppTheme.titleSmall),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.grey.shade50, borderRadius: AppTheme.radiusM),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white : Colors.black54),
                                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTheme.bodyMedium))).toList(),
                                onChanged: (v) => setState(() => _selectedCategory = v!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text('Description', style: AppTheme.titleSmall),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descriptionCtrl,
                            maxLines: 4,
                            validator: (v) => v == null || v.isEmpty ? 'Please describe your item' : null,
                            style: AppTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Describe your item condition, brand, features...',
                              prefixIcon: const Icon(Icons.description, color: AppTheme.secondaryGreen),
                              border: OutlineInputBorder(borderRadius: AppTheme.radiusM),
                              filled: true,
                              fillColor: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 30),

                          AnimatedButton(
                            text: _isEditing ? 'Update Item' : 'Post Item for Sale',
                            onPressed: _submitItem,
                            isLoading: _isSubmitting,
                            icon: Icons.send,
                            backgroundColor: AppTheme.secondaryGreen,
                            isFullWidth: true,
                            height: 52,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Tab 2: My Items
                  _loadingMyItems
                      ? const Center(child: CircularProgressIndicator())
                      : _myItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.storefront, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text('No items listed yet', style: AppTheme.titleMedium),
                                  const SizedBox(height: 8),
                                  Text('Sell your first item using the form', style: AppTheme.bodySmall),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadMyItems,
                              color: AppTheme.secondaryGreen,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _myItems.length,
                                itemBuilder: (_, i) => _buildMyItemCard(_myItems[i], isDark),
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

  Widget _priceTypeCard(String title, String value, IconData icon, bool isDark) {
    final isSelected = _priceType == value;
    return GestureDetector(
      onTap: () => setState(() => _priceType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryGreen.withOpacity(0.1) : (isDark ? AppTheme.darkSurface : Colors.grey.shade50),
          borderRadius: AppTheme.radiusM,
          border: Border.all(color: isSelected ? AppTheme.secondaryGreen : (isDark ? AppTheme.darkDivider : Colors.grey.shade300), width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppTheme.secondaryGreen : (isDark ? Colors.white70 : Colors.black54), size: 18),
            const SizedBox(width: 8),
            Text(title, style: AppTheme.titleSmall.copyWith(color: isSelected ? AppTheme.secondaryGreen : (isDark ? Colors.white70 : Colors.black54))),
          ],
        ),
      ),
    );
  }

  Widget _buildMyItemCard(BuySellItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            child: GestureDetector(
              onTap: () => showListingImagePreview(context, item.imageUrl),
              child: ListingImage(
                imageData: item.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.secondaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('₹${item.price}', style: AppTheme.titleSmall.copyWith(color: AppTheme.secondaryGreen, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.category, size: 14, color: isDark ? Colors.white54 : Colors.black45),
                    const SizedBox(width: 4),
                    Text(item.category, style: AppTheme.caption),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.status == 'sold' ? Colors.grey.withOpacity(0.1) : (item.priceType == 'fixed' ? AppTheme.brand(context).withOpacity(0.1) : AppTheme.warning.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.status == 'sold' ? 'Sold' : (item.priceType == 'fixed' ? 'Fixed Price' : 'Negotiable'),
                        style: AppTheme.caption.copyWith(
                          color: item.status == 'sold' ? Colors.grey : (item.priceType == 'fixed' ? AppTheme.brand(context) : AppTheme.warning),
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item.description, style: AppTheme.bodySmall.copyWith(color: isDark ? Colors.white70 : Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (item.status == 'active') ...[
                      OutlinedButton.icon(
                        onPressed: () => _markAsSold(item),
                        icon: const Icon(Icons.sell, size: 16),
                        label: const Text('Mark Sold'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.brand(context), side: BorderSide(color: AppTheme.brand(context)), shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusM), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _editItem(item),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.brand(context), side: BorderSide(color: AppTheme.brand(context)), shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusM), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => _deleteItem(item),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusM), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
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

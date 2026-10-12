import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/complaint_service.dart';
import '../theme/app_theme.dart';
import '../utils/animations.dart';
import 'explore_page.dart';
import 'payments/payment_dashboard.dart';
import 'visitor_form_page.dart';

class RaiseComplaintPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final Map<String, String> userProfile;

  const RaiseComplaintPage({
    super.key,
    required this.userRole,
    required this.userName,
    required this.userProfile,
  });

  @override
  State<RaiseComplaintPage> createState() => _RaiseComplaintPageState();
}

class _RaiseComplaintPageState extends State<RaiseComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _complaintTextCtrl = TextEditingController();
  String? _selectedIssueType;
  File? _selectedImage;
  bool _isSubmitting = false;
  int _navIndex = -1; // no tab highlighted

  final List<String> _issueTypes = [
    'Maintenance', 'Security', 'Water Supply', 'Electricity',
    'Noise Complaint', 'Parking Issue', 'Garbage Disposal',
    'Pest Control', 'Elevator Issue', 'Neighbor Dispute',
    'Common Area Damage', 'Other',
  ];

  @override
  void dispose() {
    _complaintTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f != null) setState(() => _selectedImage = File(f.path));
  }

  Future<void> _takePhoto() async {
    final f = await ImagePicker().pickImage(source: ImageSource.camera);
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

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIssueType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an issue type'), backgroundColor: Color(0xFFF04438)));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ComplaintService().addComplaint({
        'user_id': widget.userProfile['id'],
        'user_name': widget.userProfile['name'] ?? widget.userName,
        'user_role': widget.userRole,
        'user_apartment': widget.userProfile['apartment'] ?? widget.userProfile['unitNumber'] ?? '',
        'issue_type': _selectedIssueType,
        'complaint_text': _complaintTextCtrl.text.trim(),
        'image_url': _selectedImage?.path ?? '',
      });
      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFF04438)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF12B76A), size: 60),
            SizedBox(height: 10),
            Text('Complaint Submitted!', style: TextStyle(fontFamily: 'Arial Narrow', fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text('Your complaint has been submitted successfully. Security will review it shortly.', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 13), textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brand(context), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Raise Complaint', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: AppTheme.brand(context),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: AppTheme.brand(context).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.person, color: AppTheme.brand(context), size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.userProfile['name'] ?? widget.userName, style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF212121))),
                          Text('Apartment: ${widget.userProfile['apartment'] ?? widget.userProfile['unitNumber'] ?? ''}', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Issue Type
              Text('Issue Type', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF212121))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedIssueType,
                    hint: Text('Select issue type', style: TextStyle(fontFamily: 'Arial Narrow', color: isDark ? Colors.white54 : Colors.black45)),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white : Colors.black54),
                    dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    items: _issueTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(fontFamily: 'Arial Narrow', color: isDark ? Colors.white : const Color(0xFF212121))))).toList(),
                    onChanged: (v) => setState(() => _selectedIssueType = v),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Complaint Text
              Text('Complaint Details', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF212121))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _complaintTextCtrl,
                maxLines: 5,
                validator: (v) => v == null || v.isEmpty ? 'Please describe your complaint' : null,
                style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 14, color: isDark ? Colors.white : const Color(0xFF212121)),
                decoration: InputDecoration(
                  hintText: 'Describe your issue in detail...',
                  hintStyle: TextStyle(fontFamily: 'Arial Narrow', color: isDark ? Colors.white54 : Colors.black45),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.brand(context), width: 2)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F8FA),
                ),
              ),

              const SizedBox(height: 20),

              // Image (Optional)
              Text('Attach Image (Optional)', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF212121))),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 120, width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, fit: BoxFit.cover)),
                            Positioned(
                              top: 8, right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedImage = null),
                                child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.close, color: Colors.white, size: 18)),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 40, color: isDark ? Colors.white54 : Colors.black45),
                            const SizedBox(height: 8),
                            Text('Tap to add image', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brand(context), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Submit Complaint', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
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

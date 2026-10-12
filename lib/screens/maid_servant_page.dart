import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/maid_servant.dart';
import '../providers/theme_provider.dart';
import '../services/maid_servant_service.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — shown from explore_page bottom sheet
// Two buttons: Add Maid Servant  |  Maid Details
// ─────────────────────────────────────────────────────────────────────────────
class MaidServantPage extends StatelessWidget {
  final String userName;
  final String userRole;

  const MaidServantPage({
    super.key,
    required this.userName,
    required this.userRole,
  });

  static const _teal = Color(0xFF00897B);
  static const _tealLight = Color(0xFF4DB6AC);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Servant Maid',
            style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        backgroundColor: _teal,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OptionCard(
              icon: Icons.cleaning_services_rounded,
              title: 'Maid Details',
              subtitle: 'View all registered maids & manage status',
              gradient: const [Color(0xFF00695C), Color(0xFF00897B)],
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MaidDetailsPage(
                          userName: userName, userRole: userRole))),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: gradient.first.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 5))
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8))),
          ])),
          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Maid Servant Form
// ─────────────────────────────────────────────────────────────────────────────
class AddMaidServantPage extends StatefulWidget {
  final String userName;
  final String userRole;

  const AddMaidServantPage(
      {super.key, required this.userName, required this.userRole});

  @override
  State<AddMaidServantPage> createState() => _AddMaidServantPageState();
}

class _AddMaidServantPageState extends State<AddMaidServantPage> {
  static const _teal = Color(0xFF00897B);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _flat1Ctrl = TextEditingController();
  final _flat2Ctrl = TextEditingController();

  int _flatCount = 1; // 1 or 2 flats
  XFile? _pickedImage;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _idCtrl.dispose();
    _addressCtrl.dispose();
    _flat1Ctrl.dispose();
    _flat2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70, maxWidth: 600);
    if (img != null) setState(() => _pickedImage = img);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final flats = [_flat1Ctrl.text.trim()];
    if (_flatCount == 2 && _flat2Ctrl.text.trim().isNotEmpty) {
      flats.add(_flat2Ctrl.text.trim());
    }

    // Image upload is handled server-side by sending the file path or base64.
    // For now we send imageUrl as empty string; real upload needs multipart.
    final body = {
      'name': _nameCtrl.text.trim(),
      'age': int.parse(_ageCtrl.text.trim()),
      'id_number': _idCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'flats_served': flats,
      'image_url': '',
      'is_active': true,
    };

    try {
      await MaidServantService().addMaid(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Servant maid added successfully'),
            backgroundColor: _teal));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Add Servant Maid',
            style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        backgroundColor: _teal,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            // ── Photo picker ──────────────────────────────────────────
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: _teal, width: 2),
                ),
                child: _pickedImage != null
                    ? ClipOval(
                        child: Image.file(File(_pickedImage!.path),
                            fit: BoxFit.cover, width: 110, height: 110))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_rounded,
                              color: _teal, size: 32),
                          const SizedBox(height: 6),
                          Text('Add Photo',
                              style: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  fontSize: 11,
                                  color: _teal.withOpacity(0.8))),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Details card ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: cardColor, borderRadius: BorderRadius.circular(18)),
              child: Column(children: [
                _field(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  textColor: textColor,
                  isDark: isDark,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _ageCtrl,
                  label: 'Age',
                  icon: Icons.cake_outlined,
                  textColor: textColor,
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Age is required';
                    final age = int.tryParse(v.trim());
                    if (age == null || age < 18 || age > 80) {
                      return 'Enter a valid age (18–80)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _idCtrl,
                  label: 'ID Number (Aadhar / PAN)',
                  icon: Icons.badge_outlined,
                  textColor: textColor,
                  isDark: isDark,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'ID number is required' : null,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _addressCtrl,
                  label: 'Address',
                  icon: Icons.home_outlined,
                  textColor: textColor,
                  isDark: isDark,
                  maxLines: 2,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Address is required' : null,
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Flat assignment card ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: cardColor, borderRadius: BorderRadius.circular(18)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Flat Service',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                    const SizedBox(height: 4),
                    Text('Select how many flats this maid serves',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 12,
                            color: textColor.withOpacity(0.5))),
                    const SizedBox(height: 16),

                    // Toggle: 1 flat / 2 flats
                    Row(children: [
                      _flatToggle(1, textColor, isDark),
                      const SizedBox(width: 12),
                      _flatToggle(2, textColor, isDark),
                    ]),
                    const SizedBox(height: 16),

                    _field(
                      controller: _flat1Ctrl,
                      label: 'Flat 1 Number',
                      icon: Icons.apartment_outlined,
                      textColor: textColor,
                      isDark: isDark,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Flat 1 number is required'
                          : null,
                    ),
                    if (_flatCount == 2) ...[
                      const SizedBox(height: 16),
                      _field(
                        controller: _flat2Ctrl,
                        label: 'Flat 2 Number',
                        icon: Icons.apartment_outlined,
                        textColor: textColor,
                        isDark: isDark,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Flat 2 number is required'
                            : null,
                      ),
                    ],
                  ]),
            ),
            const SizedBox(height: 28),

            // ── Submit button ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Submit',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _flatToggle(int count, Color textColor, bool isDark) {
    final selected = _flatCount == count;
    return GestureDetector(
      onTap: () => setState(() => _flatCount = count),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _teal : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? _teal : Colors.transparent, width: 1.5),
        ),
        child: Text('$count Flat${count == 2 ? 's' : ''}',
            style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : textColor.withOpacity(0.6))),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color textColor,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
          fontFamily: 'Arial Narrow', fontSize: 14, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            fontFamily: 'Arial Narrow',
            fontSize: 13,
            color: textColor.withOpacity(0.55)),
        prefixIcon: Icon(icon, color: _teal, size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF7F8FA),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _teal, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Maid Details — list view with active/inactive toggle
// ─────────────────────────────────────────────────────────────────────────────
class MaidDetailsPage extends StatefulWidget {
  final String userName;
  final String userRole;

  const MaidDetailsPage(
      {super.key, required this.userName, required this.userRole});

  @override
  State<MaidDetailsPage> createState() => _MaidDetailsPageState();
}

class _MaidDetailsPageState extends State<MaidDetailsPage> {
  static const _teal = Color(0xFF00897B);

  List<MaidServant> _maids = [];
  bool _loading = false;
  String? _error;
  String _filter = 'all'; // all | active | inactive

  @override
  void initState() {
    super.initState();
    _load();
    MaidServantService().addListener(_onUpdate);
  }

  @override
  void dispose() {
    MaidServantService().removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final maids = await MaidServantService().getMaids();
      if (mounted) setState(() => _maids = maids);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MaidServant> get _filtered {
    if (_filter == 'active') return _maids.where((m) => m.isActive).toList();
    if (_filter == 'inactive') return _maids.where((m) => !m.isActive).toList();
    return _maids;
  }

  Future<void> _toggleStatus(MaidServant maid) async {
    try {
      await MaidServantService().toggleStatus(maid.id, !maid.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${maid.name} marked as ${maid.isActive ? 'inactive' : 'active'}'),
            backgroundColor: _teal));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red));
      }
    }
  }

  void _showDetail(BuildContext context, MaidServant maid, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // drag handle
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),

          // Avatar
          CircleAvatar(
            radius: 44,
            backgroundColor: _teal.withOpacity(0.15),
            backgroundImage: maid.imageUrl.isNotEmpty
                ? NetworkImage(maid.imageUrl)
                : null,
            child: maid.imageUrl.isEmpty
                ? Text(maid.name.isNotEmpty ? maid.name[0].toUpperCase() : 'M',
                    style: const TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: _teal))
                : null,
          ),
          const SizedBox(height: 12),

          Text(maid.name,
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF172033))),
          const SizedBox(height: 4),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: maid.isActive
                  ? Colors.green.withOpacity(0.12)
                  : Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(maid.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: maid.isActive ? Colors.green : Colors.red)),
          ),
          const SizedBox(height: 24),

          // Info rows
          _detailRow(Icons.cake_outlined, 'Age', '${maid.age} years', isDark),
          _detailRow(Icons.badge_outlined, 'ID Number', maid.idNumber, isDark),
          _detailRow(Icons.home_outlined, 'Address', maid.address, isDark),
          _detailRow(
              Icons.apartment_outlined,
              'Serves Flat(s)',
              maid.flatsServed.join(', '),
              isDark),

          const SizedBox(height: 24),

          // Toggle active button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _toggleStatus(maid);
              },
              icon: Icon(
                  maid.isActive ? Icons.block_rounded : Icons.check_circle_outline,
                  size: 18),
              label: Text(
                  maid.isActive ? 'Mark as Inactive' : 'Mark as Active',
                  style: const TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: maid.isActive ? Colors.red : _teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: _teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _teal, size: 18),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 11,
                  color: isDark ? Colors.white54 : const Color(0xFF667085))),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF172033))),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Maid Details',
            style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        backgroundColor: _teal,
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
      body: Column(children: [
        // ── Summary banner ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF4DB6AC)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              _statChip('Total', _maids.length.toString()),
              Container(width: 1, height: 35, color: Colors.white24),
              _statChip('Active',
                  _maids.where((m) => m.isActive).length.toString()),
              Container(width: 1, height: 35, color: Colors.white24),
              _statChip('Inactive',
                  _maids.where((m) => !m.isActive).length.toString()),
            ]),
          ),
        ),

        // ── Filter chips ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
              children: ['all', 'active', 'inactive'].map((f) {
            final selected = _filter == f;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  margin: EdgeInsets.only(
                      right: f != 'inactive' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? _teal
                        : (isDark
                            ? const Color(0xFF1E1E1E)
                            : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : (isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300)),
                  ),
                  child: Center(
                      child: Text(
                          f[0].toUpperCase() + f.substring(1),
                          style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.white70
                                      : Colors.black54)))),
                ),
              ),
            );
          }).toList()),
        ),
        const SizedBox(height: 12),

        // ── List ───────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          const Icon(Icons.error_outline,
                              size: 56, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(_error!,
                              style: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black45)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                              onPressed: _load,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _teal),
                              child: const Text('Retry')),
                        ]))
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            Icon(Icons.cleaning_services_rounded,
                                size: 64,
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('No servant maids found',
                                style: TextStyle(
                                    fontFamily: 'Arial Narrow',
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45)),
                          ]))
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: _teal,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) =>
                                _maidCard(_filtered[i], isDark),
                          ),
                        ),
        ),
      ]),

      // ── FAB: add new maid ──────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddMaidServantPage(
                    userName: widget.userName,
                    userRole: widget.userRole))),
        backgroundColor: _teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Maid',
            style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
    );
  }

  Widget _statChip(String label, String value) => Expanded(
        child: Column(children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 11,
                  color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ]),
      );

  Widget _maidCard(MaidServant maid, bool isDark) {
    return GestureDetector(
      onTap: () => _showDetail(context, maid, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: _teal.withOpacity(0.15),
            backgroundImage: maid.imageUrl.isNotEmpty
                ? NetworkImage(maid.imageUrl)
                : null,
            child: maid.imageUrl.isEmpty
                ? Text(
                    maid.name.isNotEmpty ? maid.name[0].toUpperCase() : 'M',
                    style: const TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _teal))
                : null,
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(maid.name,
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF172033))),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.apartment_outlined,
                      size: 13,
                      color: isDark ? Colors.white54 : Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                      maid.flatsServed.isNotEmpty
                          ? maid.flatsServed.join(', ')
                          : '—',
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey)),
                  const SizedBox(width: 10),
                  Icon(Icons.cake_outlined,
                      size: 13,
                      color: isDark ? Colors.white54 : Colors.grey),
                  const SizedBox(width: 4),
                  Text('${maid.age} yrs',
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey)),
                ]),
              ])),

          // Status badge + toggle
          Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: maid.isActive
                    ? Colors.green.withOpacity(0.12)
                    : Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(maid.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: maid.isActive ? Colors.green : Colors.red)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _toggleStatus(maid),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: maid.isActive
                      ? Colors.red.withOpacity(0.08)
                      : _teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                    maid.isActive ? 'Deactivate' : 'Activate',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: maid.isActive ? Colors.red : _teal)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

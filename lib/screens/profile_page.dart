import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _api = ApiService();
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  String? _userId;
  String _role = '';
  String? _imageBase64;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _apartmentCtrl = TextEditingController();
  final _flatCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    _role = prefs.getString('user_role') ?? '';
    if (_userId == null) return;
    try {
      final info = await _api.getUserInfo(_userId!);
      setState(() {
        _loading = false;
        if (info != null) {
          _nameCtrl.text = info['name'] ?? '';
          _phoneCtrl.text = info['phone'] ?? '';
          _apartmentCtrl.text = info['apartment'] ?? '';
          _flatCtrl.text = info['flat_number'] ?? '';
          _addressCtrl.text = info['address'] ?? '';
          _aadharCtrl.text = info['aadhar'] ?? '';
          _panCtrl.text = info['pan'] ?? '';
          _vehicleCtrl.text = info['vehicle_number'] ?? '';
          _imageBase64 = info['profile_image'];
        }
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 400);
    if (picked == null) return;
    final bytes = await File(picked.path).readAsBytes();
    setState(() => _imageBase64 = base64Encode(bytes));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.updateUserInfo(_userId!, {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'apartment': _apartmentCtrl.text.trim(),
        'flat_number': _flatCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'aadhar': _aadharCtrl.text.trim(),
        'pan': _panCtrl.text.trim(),
        'vehicle_number': _vehicleCtrl.text.trim(),
        'profile_image': _imageBase64,
      });
      await _load();
      setState(() { _editing = false; _saving = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Profile updated'), backgroundColor: Colors.green));
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _apartmentCtrl, _flatCtrl, _addressCtrl, _aadharCtrl, _panCtrl, _vehicleCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, size: 18, color: isDark ? Colors.white : Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text('My Profile', style: TextStyle(fontFamily: 'Arial Narrow', fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _editing ? (_saving ? null : _save) : () => setState(() => _editing = true),
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_editing ? 'Save' : 'Edit', style: TextStyle(fontFamily: 'Arial Narrow', color: AppTheme.brand(context), fontWeight: FontWeight.w600)),
            ),
          if (_editing) TextButton(onPressed: () => setState(() => _editing = false), child: const Text('Cancel', style: TextStyle(fontFamily: 'Arial Narrow', color: Colors.grey))),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // Avatar with camera button
                GestureDetector(
                  onTap: _editing ? _pickImage : null,
                  child: Stack(alignment: Alignment.bottomRight, children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(gradient: AppTheme.brandGradient(context), shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.brand(context), width: 2)),
                      child: _imageBase64 != null
                          ? ClipOval(child: Image.memory(base64Decode(_imageBase64!), fit: BoxFit.cover))
                          : const Icon(Icons.person, color: Colors.white, size: 48),
                    ),
                    if (_editing)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppTheme.brand(context), shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      ),
                  ]),
                ),
                const SizedBox(height: 10),
                Text(_nameCtrl.text.isEmpty ? 'Your Name' : _nameCtrl.text,
                  style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF172033))),
                Text(_role.toUpperCase(), style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 12, color: AppTheme.brand(context), fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),
                _section('Basic Info', isDark, [
                  _field('Full Name', Icons.person, _nameCtrl, isDark),
                  _field('Phone', Icons.phone, _phoneCtrl, isDark, type: TextInputType.phone),
                  _field('Apartment', Icons.apartment, _apartmentCtrl, isDark),
                  _field('Flat Number', Icons.door_front_door, _flatCtrl, isDark),
                  _field('Address', Icons.home, _addressCtrl, isDark, maxLines: 2),
                ]),
                const SizedBox(height: 16),
                _section('Documents', isDark, [
                  _field('Aadhar Number', Icons.credit_card, _aadharCtrl, isDark, type: TextInputType.number),
                  _field('PAN Number', Icons.badge, _panCtrl, isDark),
                  _field('Vehicle Number', Icons.directions_car, _vehicleCtrl, isDark),
                ]),
              ]),
            ),
    );
  }

  Widget _section(String title, bool isDark, List<Widget> children) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.brand(context))),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _field(String label, IconData icon, TextEditingController ctrl, bool isDark, {TextInputType type = TextInputType.text, int maxLines = 1}) {
    if (!_editing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(gradient: AppTheme.brandGradient(context), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 16, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF667085))),
            Text(ctrl.text.isEmpty ? '—' : ctrl.text, style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white : const Color(0xFF172033))),
          ])),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl, keyboardType: type, maxLines: maxLines,
        style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 13, color: isDark ? Colors.white : const Color(0xFF172033)),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: AppTheme.brand(context)),
          labelStyle: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 12),
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF7F8FA),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

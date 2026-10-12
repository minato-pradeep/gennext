import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class EmergencyNumbersPage extends StatefulWidget {
  const EmergencyNumbersPage({super.key});

  @override
  State<EmergencyNumbersPage> createState() => _EmergencyNumbersPageState();
}

class _EmergencyNumbersPageState extends State<EmergencyNumbersPage> {
  static String get _base => '${AppConstants.baseUrl}/api/emergency-numbers';

  List<Map<String, dynamic>> _numbers = [];
  bool _loading = true;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res =
          await http.get(Uri.parse(_base)).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _numbers = List<Map<String, dynamic>>.from(data['numbers']);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) return;
    try {
      final res = await http.post(
        Uri.parse(_base),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'phone': phone, 'category': 'custom'}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _nameCtrl.clear();
        _phoneCtrl.clear();
        _load();
      }
    } catch (_) {}
  }

  Future<void> _delete(int id) async {
    try {
      await http.delete(Uri.parse('$_base/$id'));
      _load();
    } catch (_) {}
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  IconData _icon(String category) {
    switch (category) {
      case 'police':
        return Icons.local_police;
      case 'ambulance':
        return Icons.local_hospital;
      case 'fire':
        return Icons.local_fire_department;
      case 'helpline':
        return Icons.support_agent;
      case 'disaster':
        return Icons.warning_rounded;
      default:
        return Icons.phone;
    }
  }

  Color _color(String category) {
    switch (category) {
      case 'police':
        return AppTheme.brand(context);     // Primary blue
      case 'ambulance':
        return const Color(0xFFF04438);     // Error red
      case 'fire':
        return const Color(0xFFF04438);     // Error red
      case 'helpline':
        return const Color(0xFF7F56D9);     // Accent purple
      case 'disaster':
        return const Color(0xFFF79009);     // Warning amber
      default:
        return const Color(0xFF12B76A);     // Success green
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF7F8FA);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);

    final defaults = _numbers.where((n) => n['is_default'] == true).toList();
    final customs = _numbers.where((n) => n['is_default'] != true).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.brand(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Emergency Numbers',
            style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.brand(context)))
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Default numbers
                    Text('Emergency Services',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                    const SizedBox(height: 12),
                    ...defaults.map((n) => _numberTile(
                        n, cardBg, textColor, isDark,
                        canDelete: false)),

                    const SizedBox(height: 24),

                    // Custom numbers
                    Text('Custom Numbers',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                    const SizedBox(height: 12),

                    if (customs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14)),
                        child: Text('No custom numbers added yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 13,
                                color:
                                    isDark ? Colors.white38 : Colors.black38)),
                      )
                    else
                      ...customs.map((n) => _numberTile(
                          n, cardBg, textColor, isDark,
                          canDelete: true)),

                    const SizedBox(height: 24),

                    // Add custom number
                    Text('Add Custom Number',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _field(_nameCtrl, 'Name (e.g. Security Guard)',
                              Icons.person_outline, isDark),
                          const SizedBox(height: 10),
                          _field(_phoneCtrl, 'Phone Number',
                              Icons.phone_outlined, isDark,
                              type: TextInputType.phone),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: _add,
                              icon: const Icon(Icons.add,
                                  color: Colors.white, size: 18),
                              label: const Text('Add Number',
                                  style: TextStyle(
                                      fontFamily: 'Arial Narrow',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brand(context),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _numberTile(
      Map<String, dynamic> n, Color cardBg, Color textColor, bool isDark,
      {required bool canDelete}) {
    final category = n['category'] ?? 'custom';
    final color = _color(category);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
          ]),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(_icon(category), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n['name'] ?? '',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
                Text(n['phone'] ?? '',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 13,
                        color: isDark ? Colors.white54 : const Color(0xFF667085))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _call(n['phone']),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFF12B76A).withOpacity(0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.call, color: Color(0xFF12B76A), size: 20),
            ),
          ),
          if (canDelete) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _delete(n['id']),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFFF04438).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline,
                    color: Color(0xFFF04438), size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(
      TextEditingController ctrl, String hint, IconData icon, bool isDark,
      {TextInputType type = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: TextStyle(
            fontFamily: 'Arial Narrow',
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              fontFamily: 'Arial Narrow',
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black38),
          prefixIcon: Icon(icon, color: AppTheme.brand(context), size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        ),
      ),
    );
  }
}

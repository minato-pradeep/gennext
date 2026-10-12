import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/sos_service.dart';
import '../theme/app_theme.dart';

class SosSetupScreen extends StatefulWidget {
  const SosSetupScreen({super.key});

  @override
  State<SosSetupScreen> createState() => _SosSetupScreenState();
}

class _SosSetupScreenState extends State<SosSetupScreen> {
  String _ownerPhone = '';
  List<Map<String, dynamic>> _contacts = [];
  String _partnerPhone = '';
  bool _loading = true;
  bool _loadingPartner = false;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _partnerCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _ownerPhone =
        prefs.getString('user_phone') ?? prefs.getString('user_id') ?? '';
    await Future.wait([_loadContacts(), _loadPartner()]);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _partnerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPartner() async {
    if (_ownerPhone.isEmpty) return;
    setState(() => _loadingPartner = true);
    final partner = await SosService.getPartnerInfo(_ownerPhone);
    if (mounted) {
      setState(() {
        _partnerPhone = partner?['partner_phone']?.toString() ?? '';
        _partnerCtrl.text = _partnerPhone;
        _loadingPartner = false;
      });
    }
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    final contacts = await SosService.getSosContacts(_ownerPhone);
    if (mounted) {
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    }
  }

  Future<void> _addContact() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      _snack('Enter both name and phone', isError: true);
      return;
    }
    if (phone.length < 10) {
      _snack('Enter valid 10-digit number', isError: true);
      return;
    }
    if (_contacts.length >= 5) {
      _snack('Maximum 5 contacts allowed', isError: true);
      return;
    }

    final success = await SosService.saveContact(
        ownerPhone: _ownerPhone, contactName: name, contactPhone: phone);
    if (success) {
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _snack('✅ Contact saved!');
      await _loadContacts();
    } else {
      _snack('❌ Server unreachable. Check WiFi & backend.', isError: true);
    }
  }

  Future<void> _deleteContact(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove $name?',
            style: const TextStyle(fontFamily: 'Arial Narrow', fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF04438)),
              child:
                  const Text('Remove', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm == true) {
      await SosService.deleteContact(id);
      await _loadContacts();
    }
  }

  Future<void> _savePartner() async {
    final phone = _partnerCtrl.text.trim();
    if (phone.isEmpty) {
      _snack('Enter partner phone number', isError: true);
      return;
    }
    if (phone.length < 10) {
      _snack('Enter valid 10-digit number', isError: true);
      return;
    }

    // Save to backend
    final backendSuccess = await SosService.savePartner(
        ownerPhone: _ownerPhone, partnerPhone: phone);

    // Save to native preferences for call interception
    final nativeSuccess = await SosService.setNativePartnerNumber(phone);

    if (backendSuccess && nativeSuccess) {
      _snack('✅ Partner saved!');
      await _loadPartner();
    } else if (backendSuccess) {
      _snack(
          '⚠️ Partner saved to server, but native call detection may not work.',
          isError: true);
      await _loadPartner();
    } else {
      _snack('❌ Could not save partner. Check the server.', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 13)),
      backgroundColor: isError ? const Color(0xFFF04438) : const Color(0xFF12B76A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF7F8FA);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF172033);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.brand(context),
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context)),
        title: const Text('SOS Contacts',
            style: TextStyle(fontFamily: 'Arial Narrow', 
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.brand(context)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: const Color(0xFF12B76A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF12B76A).withOpacity(0.3))),
                      child: Row(children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFF12B76A), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                'When you trigger SOS, all contacts below will automatically receive your live location on WhatsApp.',
                                style: TextStyle(fontFamily: 'Arial Narrow', 
                                    fontSize: 12,
                                    color: Color(0xFF0E9558),
                                    height: 1.4))),
                      ]),
                    ),

                    const SizedBox(height: 20),

                    Text('SOS Partner',
                        style: TextStyle(fontFamily: 'Arial Narrow', 
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8)
                          ]),
                      child: Column(children: [
                        _field(_partnerCtrl, 'Partner Phone Number',
                            Icons.person_search, isDark,
                            type: TextInputType.phone),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _savePartner,
                            icon: const Icon(Icons.save,
                                color: Colors.white, size: 18),
                            label: const Text('Save Partner',
                                style: TextStyle(fontFamily: 'Arial Narrow', 
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brand(context),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_partnerPhone.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.link,
                                color: Color(0xFF12B76A), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text('Partner set: $_partnerPhone',
                                    style: const TextStyle(fontFamily: 'Arial Narrow', 
                                        fontSize: 13, color: Colors.white70))),
                          ])
                        else
                          Row(children: [
                            const Icon(Icons.info_outline,
                                color: Color(0xFFF79009), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    _loadingPartner
                                        ? 'Loading partner...'
                                        : 'No partner configured yet',
                                    style: const TextStyle(fontFamily: 'Arial Narrow', 
                                        fontSize: 13, color: Colors.white70))),
                          ]),
                      ]),
                    ),

                    const SizedBox(height: 20),

                    Text('Add SOS Contact',
                        style: TextStyle(fontFamily: 'Arial Narrow', 
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8)
                          ]),
                      child: Column(children: [
                        _field(_nameCtrl, 'Contact Name', Icons.person_outline,
                            isDark),
                        const SizedBox(height: 12),
                        _field(_phoneCtrl, 'Phone Number (with country code)',
                            Icons.phone_outlined, isDark,
                            type: TextInputType.phone),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _addContact,
                            icon: const Icon(Icons.add,
                                color: Colors.white, size: 18),
                            label: const Text('Save to DB',
                                style: TextStyle(fontFamily: 'Arial Narrow', 
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brand(context),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0),
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 24),

                    Row(children: [
                      Text('Saved Contacts (${_contacts.length}/5)',
                          style: TextStyle(fontFamily: 'Arial Narrow', 
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor)),
                      const Spacer(),
                      IconButton(
                          icon: Icon(Icons.refresh,
                              size: 20, color: AppTheme.brand(context)),
                          onPressed: _loadContacts),
                    ]),
                    const SizedBox(height: 8),

                    if (_contacts.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(children: [
                          Icon(Icons.contacts_outlined,
                              size: 48,
                              color: isDark ? Colors.white24 : Colors.black26),
                          const SizedBox(height: 8),
                          Text('No contacts saved yet',
                              style: TextStyle(fontFamily: 'Arial Narrow', 
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38)),
                        ]),
                      )
                    else
                      ...List.generate(_contacts.length, (i) {
                        final c = _contacts[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6)
                              ]),
                          child: Row(children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: AppTheme.brand(context).withOpacity(0.1),
                                  shape: BoxShape.circle),
                              child: Center(
                                  child: Text('${i + 1}',
                                      style: TextStyle(fontFamily: 'Arial Narrow', 
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.brand(context)))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(c['contact_name'] ?? '',
                                      style: TextStyle(fontFamily: 'Arial Narrow', 
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textColor)),
                                  Text(c['contact_phone'] ?? '',
                                      style: TextStyle(fontFamily: 'Arial Narrow', 
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white54
                                              : const Color(0xFF667085))),
                                ])),
                            IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Color(0xFFF04438), size: 20),
                                onPressed: () =>
                                    _deleteContact(c['id'], c['contact_name'])),
                          ]),
                        );
                      }),
                  ]),
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
          border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200)),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: TextStyle(fontFamily: 'Arial Narrow', 
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontFamily: 'Arial Narrow', 
              fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
          prefixIcon: Icon(icon, color: AppTheme.brand(context), size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        ),
      ),
    );
  }
}

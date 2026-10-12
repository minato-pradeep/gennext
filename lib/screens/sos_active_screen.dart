import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/sos_service.dart';

class SosActiveScreen extends StatefulWidget {
  const SosActiveScreen({super.key});

  @override
  State<SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends State<SosActiveScreen>
    with SingleTickerProviderStateMixin {
  bool _sosStopped = false;
  bool _loadingLocation = true;
  bool _sosTriggered = false;
  String? _mapsLink;
  Position? _position;
  List<Map<String, dynamic>> _contacts = [];
  String _ownerPhone = '';
  String _ownerName = '';
  String _ownerApartment = '';
  String _partnerPhone = '';
  bool _partnerCalled = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadAndTrigger();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    SosService.stopSiren();
    super.dispose();
  }

  Future<void> _loadAndTrigger() async {
    if (_sosTriggered) return;
    _sosTriggered = true;

    final prefs = await SharedPreferences.getInstance();
    _ownerPhone = prefs.getString('user_phone') ?? '';
    _ownerName = prefs.getString('user_name') ?? 'User';
    _ownerApartment = prefs.getString('user_apartment') ?? '';

    // 1. Start siren immediately
    await SosService.startSiren();

    // 2. Load contacts from DB
    _contacts = await SosService.getSosContacts(
      prefs.getString('user_phone') ?? prefs.getString('user_id') ?? '',
    );

    // 2.1. Load partner mapping if available
    final partnerInfo = await SosService.getPartnerInfo(_ownerPhone);
    if (partnerInfo != null) {
      _partnerPhone = partnerInfo['partner_phone']?.toString() ?? '';
    }

    // 3. Get GPS location
    final pos = await SosService.getCurrentLocation();
    if (!mounted) return;

    final link = pos != null ? SosService.buildMapsLink(pos) : null;
    setState(() {
      _position = pos;
      _mapsLink = link;
      _loadingLocation = false;
    });

    // 4. Save to DB
    await SosService.saveSosToDb(
      fullName: _ownerName,
      phoneNumber: _ownerPhone,
      apartment: _ownerApartment,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      mapsLink: link,
    );

    // 5. Send WhatsApp to ALL contacts simultaneously (no waiting between)
    if (_contacts.isNotEmpty && link != null) {
      _sendWhatsAppToAll(_contacts, link);
    }

    // 6. Dial SOS partner if configured
    if (_partnerPhone.isNotEmpty && !_partnerCalled) {
      _partnerCalled = true;
      await SosService.dialPhone(_partnerPhone);
    }
  }

  // Send WhatsApp to all contacts simultaneously without waiting
  void _sendWhatsAppToAll(
      List<Map<String, dynamic>> contacts, String mapsLink) {
    final msg = Uri.encodeComponent(
        '🚨 EMERGENCY ALERT!\n\n$_ownerName needs help urgently!\n\n📍 Live Location:\n$mapsLink\n\n📞 Call them: $_ownerPhone\n\nPlease respond immediately!');
    for (final contact in contacts) {
      final phone = contact['contact_phone'].toString();
      final waNumber =
          phone.startsWith('+') ? phone.replaceAll('+', '') : '91$phone';
      launchUrl(Uri.parse('https://wa.me/$waNumber?text=$msg'),
          mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _stopSos() async {
    await SosService.stopSiren();
    await SosService.stopSosInDb();
    _pulseCtrl.stop();
    if (mounted) setState(() => _sosStopped = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _sosStopped ? const Color(0xFF0D1B2A) : const Color(0xFF1A0000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(children: [
            // Header
            Row(children: [
              GestureDetector(
                onTap: () async {
                  await SosService.stopSiren();
                  if (mounted) Navigator.pop(context);
                },
                child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 16)),
              ),
              const SizedBox(width: 12),
              const Text('Emergency SOS',
                  style: TextStyle(fontFamily: 'Arial Narrow', 
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const Spacer(),
              if (!_sosStopped)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF79009).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF79009).withOpacity(0.5))),
                  child: const Text('LIVE',
                      style: TextStyle(fontFamily: 'Arial Narrow', 
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF79009))),
                ),
            ]),

            const Spacer(),

            // Pulse circle
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _sosStopped ? 1.0 : _pulseAnim.value,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _sosStopped
                        ? const Color(0xFF0E9558)
                        : const Color(0xFFF04438),
                    boxShadow: [
                      BoxShadow(
                          color: (_sosStopped ? const Color(0xFF12B76A) : const Color(0xFFF04438))
                              .withOpacity(0.55),
                          blurRadius: 50,
                          spreadRadius: 12)
                    ],
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            _sosStopped
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 48),
                        const SizedBox(height: 6),
                        Text(_sosStopped ? 'SOS\nStopped' : 'SOS\nActive',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'Arial Narrow', 
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1)),
                      ]),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Status
            Text(
              _sosStopped
                  ? 'Emergency stopped. Stay safe.'
                  : (_loadingLocation
                      ? 'Getting location...'
                      : 'WhatsApp sent to ${_contacts.length} contact(s) ✅'),
              style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 13, color: Colors.white60),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Location chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _mapsLink != null
                        ? Colors.greenAccent.withOpacity(0.4)
                        : Colors.white12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                    _loadingLocation
                        ? Icons.location_searching
                        : Icons.location_on,
                    color:
                        _loadingLocation ? const Color(0xFFF79009) : const Color(0xFF12B76A),
                    size: 15),
                const SizedBox(width: 8),
                Flexible(
                    child: Text(
                        _loadingLocation
                            ? 'Fetching GPS...'
                            : _position != null
                                ? '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}'
                                : 'Location unavailable',
                        style: const TextStyle(fontFamily: 'Arial Narrow', 
                            fontSize: 12, color: Colors.white70))),
              ]),
            ),

            const SizedBox(height: 12),

            if (_partnerPhone.isNotEmpty)
              GestureDetector(
                onTap: () async {
                  await SosService.dialPhone(_partnerPhone);
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.call,
                            color: Color(0xFF12B76A), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text('Partner alerted: $_partnerPhone',
                                style: const TextStyle(fontFamily: 'Arial Narrow', 
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                                overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        const Icon(Icons.phone_forwarded,
                            color: Colors.white54, size: 14),
                      ]),
                ),
              ),

            // MY PHONE NUMBER — for others to call back
            if (_ownerPhone.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _ownerPhone));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Phone number copied!'),
                      backgroundColor: Colors.green));
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone,
                            color: Color(0xFF12B76A), size: 18),
                        const SizedBox(width: 8),
                        Text('My Number: $_ownerPhone',
                            style: const TextStyle(fontFamily: 'Arial Narrow', 
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy, color: Colors.white54, size: 14),
                      ]),
                ),
              ),

            const Spacer(),

            // Action buttons
            if (!_sosStopped) ...[
              // Call contacts
              if (_contacts.isNotEmpty)
                ...List.generate(
                    _contacts.length > 3 ? 3 : _contacts.length,
                    (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _btn(
                              Icons.call,
                              'Call ${_contacts[i]['contact_name']} (${_contacts[i]['contact_phone']})',
                              const Color(0xFF12B76A),
                              () => _callPhone(_contacts[i]['contact_phone'])),
                        )),

              // Resend WhatsApp
              if (_mapsLink != null && _contacts.isNotEmpty)
                _btn(
                    Icons.send,
                    'Resend WhatsApp to All',
                    const Color(0xFF25D366),
                    () => _sendWhatsAppToAll(_contacts, _mapsLink!)),

              const SizedBox(height: 8),

              // Open maps
              if (_mapsLink != null)
                _btn(
                    Icons.map_outlined,
                    'View My Location',
                    const Color(0xFFF79009),
                    () => SosService.openMapsLink(_mapsLink!)),

              const SizedBox(height: 16),
            ],

            // Stop / Close
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed:
                    _sosStopped ? () => Navigator.pop(context) : _stopSos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sosStopped ? Colors.white12 : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(_sosStopped ? 'Close' : '■  STOP SOS',
                    style: TextStyle(fontFamily: 'Arial Narrow', 
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _sosStopped
                            ? Colors.white54
                            : const Color(0xFFF04438))),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _btn(IconData icon, String label, Color color, VoidCallback? onTap) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Flexible(
                child: Text(label,
                    style: TextStyle(fontFamily: 'Arial Narrow', 
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color),
                    overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
    );
  }
}

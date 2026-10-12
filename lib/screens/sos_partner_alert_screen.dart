import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sos_service.dart';

class SosPartnerAlertScreen extends StatefulWidget {
  final Map<String, dynamic> alert;

  const SosPartnerAlertScreen({super.key, required this.alert});

  @override
  State<SosPartnerAlertScreen> createState() => _SosPartnerAlertScreenState();
}

class _SosPartnerAlertScreenState extends State<SosPartnerAlertScreen>
    with SingleTickerProviderStateMixin {
  bool _acknowledged = false;
  bool _sendingResponse = false;
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
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _stopAlert() async {
    // For native triggers, just acknowledge locally
    if (widget.alert['is_native_trigger'] == true) {
      if (mounted) {
        setState(() => _acknowledged = true);
        Navigator.pop(context);
      }
      return;
    }

    // For regular alerts, stop on server
    if (widget.alert['id'] == null) return;
    await SosService.stopPartnerAlert(widget.alert['id'] as int);
    if (mounted) {
      setState(() => _acknowledged = true);
      Navigator.pop(context);
    }
  }

  Future<void> _triggerSosBack() async {
    if (_sendingResponse) return;
    setState(() => _sendingResponse = true);

    final prefs = await SharedPreferences.getInstance();
    final ownerPhone =
        prefs.getString('user_phone') ?? prefs.getString('user_id') ?? '';
    final ownerName = prefs.getString('user_name') ?? 'You';
    final ownerApartment = prefs.getString('user_apartment') ?? '';

    final pos = await SosService.getCurrentLocation();
    final link = pos != null
        ? SosService.buildMapsLink(pos)
        : widget.alert['maps_link']?.toString() ?? '';

    await SosService.saveSosToDb(
      fullName: ownerName,
      phoneNumber: ownerPhone,
      apartment: ownerApartment,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      mapsLink: link,
    );
    await _stopAlert();
  }

  @override
  Widget build(BuildContext context) {
    final isNativeTrigger = widget.alert['is_native_trigger'] == true;
    final senderName = isNativeTrigger
        ? 'Emergency Partner Call'
        : (widget.alert['sender_name']?.toString() ?? 'Your emergency partner');
    final senderPhone = widget.alert['partner_phone']?.toString() ?? '';
    final mapsLink = widget.alert['maps_link']?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Incoming SOS Alert',
                  style: TextStyle(fontFamily: 'Arial Narrow', 
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 12),
              Text(
                  isNativeTrigger
                      ? 'Emergency call detected from your partner: $senderPhone'
                      : 'Your partner triggered emergency alert.',
                  style:
                      const TextStyle(fontFamily: 'Arial Narrow', fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 24),
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF04438),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFFF04438).withOpacity(0.45),
                              blurRadius: 50,
                              spreadRadius: 12)
                        ],
                      ),
                      child: const Center(
                          child: Icon(Icons.dangerous,
                              color: Colors.white, size: 60)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _infoRow('From', senderName),
              const SizedBox(height: 10),
              _infoRow('Phone', senderPhone),
              const SizedBox(height: 10),
              _infoRow(
                  'Location',
                  mapsLink != null && mapsLink.isNotEmpty
                      ? 'Shared'
                      : 'Not available'),
              const Spacer(),
              _actionButton(
                label: _sendingResponse ? 'Sending SOS...' : 'Trigger SOS Back',
                color: const Color(0xFFF04438),
                onTap: _triggerSosBack,
                disabled: _sendingResponse,
              ),
              const SizedBox(height: 12),
              _actionButton(
                  label: 'Acknowledge Alert',
                  color: Colors.white24,
                  onTap: _stopAlert),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 12, color: Colors.white54)),
        const SizedBox(height: 6),
        Text(value.isEmpty ? 'Unknown' : value,
            style: const TextStyle(fontFamily: 'Arial Narrow', 
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ],
    );
  }

  Widget _actionButton(
      {required String label,
      required Color color,
      required VoidCallback onTap,
      bool disabled = false}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(label,
            style: const TextStyle(fontFamily: 'Arial Narrow', 
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
    );
  }
}

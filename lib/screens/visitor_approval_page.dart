import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class VisitorApprovalPage extends StatefulWidget {
  final String userRole;
  final String userName;
  const VisitorApprovalPage(
      {super.key, required this.userRole, required this.userName});

  @override
  State<VisitorApprovalPage> createState() => _VisitorApprovalPageState();
}

class _VisitorApprovalPageState extends State<VisitorApprovalPage>
    with WidgetsBindingObserver {
  static String get _base => '${AppConstants.baseUrl}/api/visitors';

  List<Map<String, dynamic>> _visitors = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res =
          await http.get(Uri.parse(_base)).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _visitors = List<Map<String, dynamic>>.from(data['visitors']);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      await http
          .put(
            Uri.parse('$_base/$id/status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 10));
      _load();
      _snack(status == 'approved' ? '✅ Visitor approved' : '❌ Visitor rejected',
          status == 'approved' ? const Color(0xFF12B76A) : const Color(0xFFF04438));
    } catch (e) {
      _snack('Error: $e', Colors.red);
    }
  }

  Future<void> _checkIn(int id) async {
    try {
      await http
          .put(Uri.parse('$_base/$id/checkin'))
          .timeout(const Duration(seconds: 10));
      _load();
      _snack('✅ Check-in time recorded', const Color(0xFF12B76A));
    } catch (e) {
      _snack('Error: $e', Colors.red);
    }
  }

  Future<void> _checkOut(int id) async {
    try {
      await http
          .put(Uri.parse('$_base/$id/checkout'))
          .timeout(const Duration(seconds: 10));
      _load();
      _snack('✅ Check-out time recorded', const Color(0xFF667085));
    } catch (e) {
      _snack('Error: $e', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _fmt(String? dt) {
    if (dt == null || dt.isEmpty) return '';
    try {
      final d = DateTime.parse(dt).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dt;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return const Color(0xFFF79009);   // Amber — Pending / Attention
      case 'approved':
        return AppTheme.brand(context);   // Primary Blue — Active
      case 'checked_in':
        return const Color(0xFF12B76A);   // Green — Completed / In
      case 'checked_out':
        return const Color(0xFF667085);   // Secondary text grey
      case 'rejected':
        return const Color(0xFFF04438);   // Red — Rejected
      default:
        return const Color(0xFF667085);
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'checked_in':
        return 'Checked In';
      case 'checked_out':
        return 'Checked Out';
      case 'rejected':
        return 'Rejected';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final pending = _visitors.where((v) => v['status'] == 'pending').length;
    final checkedIn =
        _visitors.where((v) => v['status'] == 'checked_in').length;
    final approved = _visitors.where((v) => v['status'] == 'approved').length;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Visitor Approval',
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
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load)
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(children: [
                // Stats
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    _stat('Pending', pending.toString(), const Color(0xFFF79009), isDark),
                    const SizedBox(width: 10),
                    _stat('Approved', approved.toString(), AppTheme.brand(context), isDark),
                    const SizedBox(width: 10),
                    _stat('Inside', checkedIn.toString(), const Color(0xFF12B76A), isDark),
                  ]),
                ),
                Expanded(
                  child: _visitors.isEmpty
                      ? Center(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                              Icon(Icons.people_outline,
                                  size: 64,
                                  color: isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('No visitor requests',
                                  style: TextStyle(
                                      fontFamily: 'Arial Narrow',
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black45)),
                            ]))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _visitors.length,
                          itemBuilder: (_, i) => _card(_visitors[i], isDark),
                        ),
                ),
              ]),
            ),
    );
  }

  Widget _stat(String label, String count, Color color, bool isDark) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
              ]),
          child: Column(children: [
            Text(count,
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color)),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 11,
                    color: AppTheme.textColor(context).withOpacity(0.45))),
          ]),
        ),
      );

  Widget _card(Map<String, dynamic> v, bool isDark) {
    final id = v['id'] as int;
    final status = v['status'] as String;
    final checkIn = v['check_in']?.toString();
    final checkOut = v['check_out']?.toString();
    final vehicleNumber = v['vehicle_number']?.toString() ?? '';
    final visitorImage = v['visitor_image']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Top row: photo + name/phone + status badge ──
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Visitor photo or default avatar
          GestureDetector(
            onTap: visitorImage.isNotEmpty
                ? () => _showImageDialog(context, visitorImage, isDark)
                : null,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppTheme.brand(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: visitorImage.isNotEmpty
                  ? Image.memory(
                      base64Decode(visitorImage.contains(',')
                          ? visitorImage.split(',').last
                          : visitorImage),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                          Icons.person, color: AppTheme.brand(context), size: 30),
                    )
                  : Icon(Icons.person,
                      color: AppTheme.brand(context), size: 30),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(v['visitor_name'] ?? '',
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context))),
              const SizedBox(height: 2),
              Text(v['visitor_phone'] ?? '',
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 12,
                      color: AppTheme.textColor(context).withOpacity(0.45))),
              if (vehicleNumber.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.directions_car_outlined,
                      size: 13, color: AppTheme.brand(context)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.brand(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color:
                              AppTheme.brand(context).withOpacity(0.3)),
                    ),
                    child: Text(vehicleNumber,
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.brand(context),
                            letterSpacing: 1.0)),
                  ),
                ]),
              ],
            ]),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(_statusLabel(status),
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(status))),
          ),
        ]),

        const SizedBox(height: 10),

        // Host info
        if (v['host_name'] != null)
          Row(children: [
            Icon(Icons.home,
                size: 13,
                color: AppTheme.textColor(context).withOpacity(0.38)),
            const SizedBox(width: 4),
            Text('Host: ${v['host_name']} • ${v['apartment'] ?? ''}',
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 11,
                    color: AppTheme.textColor(context).withOpacity(0.38))),
          ]),

        if (v['purpose'] != null &&
            v['purpose'].toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.info_outline,
                size: 13,
                color: AppTheme.textColor(context).withOpacity(0.38)),
            const SizedBox(width: 4),
            Expanded(
              child: Text('Purpose: ${v['purpose']}',
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 11,
                      color: AppTheme.textColor(context).withOpacity(0.38))),
            ),
          ]),
        ],

        // Check-in / Check-out times
        if (checkIn != null && checkIn.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.login, size: 13, color: Color(0xFF12B76A)),
            const SizedBox(width: 4),
            Text('In: ${_fmt(checkIn)}',
                style: const TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 11,
                    color: Color(0xFF12B76A))),
            if (checkOut != null && checkOut.isNotEmpty) ...[
              const SizedBox(width: 12),
              const Icon(Icons.logout, size: 13, color: Color(0xFF667085)),
              const SizedBox(width: 4),
              Text('Out: ${_fmt(checkOut)}',
                  style: const TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 11,
                      color: Color(0xFF667085))),
            ],
          ]),
        ],

        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),

        // Action buttons
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (status == 'pending') ...[
            _btn('Approve', const Color(0xFF12B76A), Icons.check_circle,
                () => _updateStatus(id, 'approved')),
            _btn('Reject', const Color(0xFFF04438), Icons.cancel,
                () => _updateStatus(id, 'rejected')),
          ],
          if (status == 'approved' && (checkIn == null || checkIn.isEmpty))
            _btn('Check In', const Color(0xFF12B76A), Icons.login, () => _checkIn(id)),
          if (status == 'checked_in' &&
              (checkOut == null || checkOut.isEmpty))
            _btn('Check Out', const Color(0xFF667085), Icons.logout,
                () => _checkOut(id)),
          if (status == 'checked_out')
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFF667085).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Completed',
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 11,
                      color: Color(0xFF667085))),
            ),
          if (status == 'rejected')
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Rejected',
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 11,
                      color: Colors.red)),
            ),
        ]),
      ]),
    );
  }

  void _showImageDialog(
      BuildContext context, String imageData, bool isDark) {
    final bytes = base64Decode(
        imageData.contains(',') ? imageData.split(',').last : imageData);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(alignment: Alignment.topRight, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _btn(String label, Color color, IconData icon, VoidCallback onTap) =>
      ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: Colors.white),
        label: Text(label,
            style: const TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
      );
}

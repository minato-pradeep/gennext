import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hall_booking.dart';
import '../services/hall_booking_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

// ── Hall metadata ────────────────────────────────────────────────────────────
class _HallInfo {
  final String name;
  final String subtitle;
  final String image;
  const _HallInfo(this.name, this.subtitle, this.image);
}

const _halls = [
  _HallInfo('Hall A', 'Party & Celebration', 'assets/images/hall_a.jpg'),
  _HallInfo('Hall B', 'Banquet & Dining',    'assets/images/hall_b.jpg'),
  _HallInfo('Hall C', 'Meeting & Conference','assets/images/hall_c.jpg'),
  _HallInfo('Hall D', 'Community & Events',  'assets/images/hall_d.jpg'),
];

class HallBookingPage extends StatefulWidget {
  final String userName;
  const HallBookingPage({super.key, required this.userName});

  @override
  State<HallBookingPage> createState() => _HallBookingPageState();
}

class _HallBookingPageState extends State<HallBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _title       = TextEditingController();
  final _description = TextEditingController();
  final _amount      = TextEditingController();
  final _service     = HallBookingService();

  String _hall = 'Hall A';
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;

  List<HallBooking>          _bookings = [];
  List<Map<String, dynamic>> _users    = [];
  final Set<int>             _selectedUsers = {};
  bool?  _inviteEveryone;
  bool   _loading = true;
  bool   _saving  = false;
  int    _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date  = DateTime(now.year, now.month, now.day);
    _start = TimeOfDay(hour: now.hour, minute: now.minute);
    final end = now.add(const Duration(hours: 2));
    _end   = TimeOfDay(hour: end.hour, minute: end.minute);
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _load() async {
    final prefs  = await SharedPreferences.getInstance();
    final userId = int.tryParse(prefs.getString('user_id') ?? '') ?? 0;
    try {
      final responses = await Future.wait([
        _service.fetchBookings(),
        http.get(Uri.parse('${AppConstants.baseUrl}/api/users')),
      ]);
      final userData = jsonDecode((responses[1] as http.Response).body);
      if (mounted) {
        setState(() {
          _currentUserId = userId;
          _bookings = responses[0] as List<HallBooking>;
          _users = (userData['users'] as List? ?? [])
              .map((u) => Map<String, dynamic>.from(u))
              .where((u) => u['is_active'] != false)
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<int> get _inviteIds => _inviteEveryone == true
      ? _users
          .map((u) => int.tryParse(u['id'].toString()))
          .whereType<int>()
          .toList()
      : _selectedUsers.toList();

  // ── Pickers ───────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked != null) {
      setState(() => isStart ? _start = picked : _end = picked);
    }
  }

  // ── Booking submit ────────────────────────────────────────────────────────

  Future<void> _book() async {
    if (!_formKey.currentState!.validate()) return;
    if (_inviteEveryone == null) {
      _msg('Choose whether to invite everyone or selected residents.');
      return;
    }
    if (_inviteEveryone == false && _selectedUsers.isEmpty) {
      _msg('Select at least one resident to invite.');
      return;
    }
    final prefs  = await SharedPreferences.getInstance();
    final userId = int.tryParse(prefs.getString('user_id') ?? '');
    if (userId == null) { _msg('Please sign in again before booking a hall.'); return; }

    final parsedAmount = double.tryParse(_amount.text.trim()) ?? 0;
    if (parsedAmount <= 0) { _msg('Enter a valid hall payment amount.'); return; }

    final now           = DateTime.now();
    final currentMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final start = DateTime(_date.year, _date.month, _date.day, _start.hour, _start.minute);
    final end   = DateTime(_date.year, _date.month, _date.day, _end.hour,   _end.minute);
    final isToday = _date.year == now.year && _date.month == now.month && _date.day == now.day;
    if ((isToday && start.isBefore(currentMinute)) || !end.isAfter(start)) {
      _msg('Choose a future time and make sure the end is after the start.');
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.bookHall(
        hallName:      _hall,
        bookedByName:  widget.userName,
        bookedBy:      userId,
        date:          _date,
        start:         TimeOfDayValue(_start.hour, _start.minute),
        end:           TimeOfDayValue(_end.hour,   _end.minute),
        eventTitle:    _title.text.trim(),
        description:   _description.text.trim(),
        amount:        parsedAmount,
        paymentStatus: 'pending',
        invitedUserIds: _inviteIds,
      );
      if (mounted) {
        _msg('Hall booked and invitations sent.');
        Navigator.pop(context, true);
      }
    } catch (error) {
      _msg(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Cancel booking ────────────────────────────────────────────────────────

  Future<void> _cancelBooking(HallBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Booking'),
        content: Text('Cancel the booking for "${booking.eventTitle}" at ${booking.hallName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.cancelBooking(booking.id);
      if (mounted) { _msg('Booking cancelled.'); _load(); }
    } catch (e) {
      if (mounted) _msg(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Resident selector ─────────────────────────────────────────────────────

  Future<void> _selectResidents() async {
    final selected = Set<int>.from(_selectedUsers);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select residents'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: _users.map((user) {
              final id = int.tryParse(user['id'].toString());
              if (id == null) return const SizedBox.shrink();
              return StatefulBuilder(
                builder: (context, setDialogState) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title:    Text('${user['name'] ?? user['username']}'),
                  subtitle: Text('${user['apartment'] ?? ''}'),
                  value: selected.contains(id),
                  onChanged: (checked) => setDialogState(() {
                    if (checked == true) selected.add(id); else selected.remove(id);
                  }),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _selectedUsers..clear()..addAll(selected));
              Navigator.pop(ctx);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String _fmt(TimeOfDay t) => t.format(context);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Book a Hall',
          style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppTheme.brand(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  // ── Hall selector ──────────────────────────────────────
                  _label('Choose a Hall'),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    children: _halls.map((info) {
                      final selected = _hall == info.name;
                      return GestureDetector(
                        onTap: () => setState(() => _hall = info.name),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // photo
                              Image.asset(info.image, fit: BoxFit.cover),
                              // dark scrim — lighter when not selected, darker when selected
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: selected
                                        ? [Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.72)]
                                        : [Colors.black.withOpacity(0.08), Colors.black.withOpacity(0.52)],
                                  ),
                                ),
                              ),
                              // selection ring
                              if (selected)
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.brand(context), width: 3),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              // text
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      info.name,
                                      style: const TextStyle(
                                        fontFamily: 'Arial Narrow',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                                      ),
                                    ),
                                    Text(
                                      info.subtitle,
                                      style: const TextStyle(
                                        fontFamily: 'Arial Narrow',
                                        fontSize: 10,
                                        color: Colors.white70,
                                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // tick badge
                              if (selected)
                                Positioned(
                                  top: 8, right: 8,
                                  child: Container(
                                    width: 22, height: 22,
                                    decoration: BoxDecoration(
                                      color: AppTheme.brand(context),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // ── Date & Time row ────────────────────────────────────
                  const SizedBox(height: 20),
                  _label('Date & Time'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE4E7EC)),
                    ),
                    child: Row(
                      children: [
                        // Date
                        Expanded(
                          flex: 5,
                          child: _pickerCell(
                            icon: Icons.calendar_today_outlined,
                            topLabel: 'Date',
                            value: '${_date.day} ${_monthAbbr(_date.month)} ${_date.year}',
                            onTap: _pickDate,
                            isDark: isDark,
                          ),
                        ),
                        _divider(isDark),
                        // Start
                        Expanded(
                          flex: 4,
                          child: _pickerCell(
                            icon: Icons.access_time_outlined,
                            topLabel: 'From',
                            value: _fmt(_start),
                            onTap: () => _pickTime(true),
                            isDark: isDark,
                          ),
                        ),
                        _divider(isDark),
                        // End
                        Expanded(
                          flex: 4,
                          child: _pickerCell(
                            icon: Icons.access_time_filled_outlined,
                            topLabel: 'To',
                            value: _fmt(_end),
                            onTap: () => _pickTime(false),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Event details ──────────────────────────────────────
                  const SizedBox(height: 20),
                  _label('Event Details'),
                  const SizedBox(height: 10),
                  _field(_title, 'Event title'),
                  _field(_description, 'Description', maxLines: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter valid amount' : null,
                      decoration: const InputDecoration(
                        labelText: 'Hall payment amount (₹)',
                        prefixText: '₹ ',
                      ),
                    ),
                  ),

                  // ── Invite ─────────────────────────────────────────────
                  const SizedBox(height: 4),
                  _label('Invite Residents'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Invite all apartment residents'),
                    value: _inviteEveryone == true,
                    onChanged: (v) => setState(() => _inviteEveryone = v ? true : null),
                  ),
                  RadioListTile<bool>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Invite selected residents'),
                    value: false,
                    groupValue: _inviteEveryone,
                    onChanged: (v) => setState(() => _inviteEveryone = v),
                  ),
                  if (_inviteEveryone == false)
                    OutlinedButton.icon(
                      onPressed: _selectResidents,
                      icon: const Icon(Icons.people_outline),
                      label: Text(_selectedUsers.isEmpty
                          ? 'Select residents'
                          : '${_selectedUsers.length} residents selected'),
                    ),

                  // ── Submit ─────────────────────────────────────────────
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _book,
                      icon: const Icon(Icons.event_available),
                      label: Text(_saving ? 'Booking…' : 'Book Hall'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brand(context),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  // ── Upcoming bookings ──────────────────────────────────
                  const SizedBox(height: 28),
                  if (_bookings.isNotEmpty) ...[
                    ..._bookings.map((b) => _bookingCard(b, isDark)),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Arial Narrow',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.textColor(context),
        ),
      );

  Widget _divider(bool isDark) => Container(
        width: 1,
        height: 44,
        color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE4E7EC),
      );

  Widget _pickerCell({
    required IconData icon,
    required String topLabel,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 12, color: AppTheme.brand(context)),
              const SizedBox(width: 4),
              Text(topLabel,
                  style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brand(context),
                  )),
            ]),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF172033),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator ??
            (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _bookingCard(HallBooking booking, bool isDark) {
    final isOwner = _currentUserId != 0 && booking.bookedBy == _currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF3D3D3D) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // hall icon
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppTheme.brand(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.meeting_room_outlined,
                color: AppTheme.brand(context), size: 18),
          ),
          const SizedBox(width: 10),
          // info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking.hallName}  ·  ${booking.eventTitle}',
                  style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF172033),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                // date + time in one line
                Row(children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 10, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text(
                    '${_fmtBookingDate(booking.bookingDate)}  ·  ${booking.startTime} – ${booking.endTime}',
                    style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // amount
          Text(
            '₹${booking.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: 'Arial Narrow',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF172033),
            ),
          ),
          // cancel button — only owner
          if (isOwner) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _cancelBooking(booking),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text('Cancel',
                    style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    )),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _monthAbbr(int m) =>
      const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  String _fmtBookingDate(String raw) {
    // raw is "YYYY-MM-DD" or similar from backend
    try {
      final d = DateTime.parse(raw);
      return '${d.day} ${_monthAbbr(d.month)} ${d.year}';
    } catch (_) {
      return raw;
    }
  }
}

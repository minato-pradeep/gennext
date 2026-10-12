import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../utils/animations.dart';
import 'explore_page.dart';
import 'payments/payment_dashboard.dart';
import 'visitor_form_page.dart';

class EventsListPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final bool isAdmin;

  const EventsListPage({
    super.key,
    required this.userRole,
    required this.userName,
    this.isAdmin = false,
  });

  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage>
    with WidgetsBindingObserver {
  List<Event> _events = [];
  bool _loading = false;
  int _navIndex = -1;
  Timer? _refreshTimer;
  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
    _loadEvents();
    _refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) _loadEvents();
    });
    EventService().addListener(_onEventsUpdated);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    EventService().removeListener(_onEventsUpdated);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadEvents();
  }

  void _onEventsUpdated() {
    if (mounted) _loadEvents();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = int.tryParse(prefs.getString('user_id') ?? '') ?? 0;
    if (mounted) setState(() => _currentUserId = id);
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      final events = await EventService().fetchEvents();
      if (mounted) {
        setState(() {
          _events = events;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Always returns all events, sorted newest-first.
  List<Event> get _allEvents {
    return [..._events]..sort((a, b) => EventService()
        .parseEventDateTime(b.dateTime)
        .compareTo(EventService().parseEventDateTime(a.dateTime)));
  }

  bool _canManageEvent(Event event) {
    if (widget.isAdmin) return true;
    if (event.postedBy == widget.userName) return true;
    if (event.isHallBooking &&
        _currentUserId != 0 &&
        event.bookedBy == _currentUserId) return true;
    return false;
  }

  void _deleteEvent(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(event.isHallBooking ? 'Cancel Booking' : 'Delete Event'),
        content: Text(
          event.isHallBooking
              ? 'Cancel the hall booking for "${event.title}"? This cannot be undone.'
              : 'Are you sure you want to delete "${event.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await EventService().deleteEvent(event);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(event.isHallBooking
                          ? 'Booking cancelled'
                          : 'Event deleted'),
                      backgroundColor: const Color(0xFF12B76A),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(event.isHallBooking ? 'Yes, Cancel' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(Event event) {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // drag handle
            Center(
              child: Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // title row
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.brand(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.event,
                      color: AppTheme.brand(context), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                ),
                IconButton(
                  icon:
                      Icon(Icons.close, color: AppTheme.textColor(context)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // date/time row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.brand(context).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: AppTheme.brand(context)),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(event.dateTime),
                    style: const TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time,
                      size: 16, color: AppTheme.brand(context)),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(event.dateTime),
                    style: const TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Description',
              style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                event.description,
                style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 13,
                  height: 1.5,
                  color: AppTheme.textColor(context).withOpacity(0.87),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Posted by ${event.postedBy}',
                  style: const TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 11,
                      color: Colors.grey),
                ),
              ],
            ),
            // hall booking details panel
            if (event.isHallBooking) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hall: ${event.hallName}',
                      style: const TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Payment: ₹${event.amount.toStringAsFixed(0)} • ${event.paymentStatus.toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            // cancel / delete button — only for owner or admin
            if (_canManageEvent(event))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteEvent(event);
                  },
                  icon: Icon(
                      event.isHallBooking
                          ? Icons.cancel_outlined
                          : Icons.delete,
                      size: 18),
                  label: Text(event.isHallBooking
                      ? 'Cancel Hall Booking'
                      : 'Delete Event'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateTimeStr) {
    try {
      final date = EventService().parseEventDateTime(dateTimeStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateTimeStr.split(' ').first;
    }
  }

  String _formatTime(String dateTimeStr) {
    try {
      final date = EventService().parseEventDateTime(dateTimeStr);
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final suffix = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $suffix';
    } catch (e) {
      return dateTimeStr.split(' ').last;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final events = _allEvents;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Events',
          style: TextStyle(
            fontFamily: 'Arial Narrow',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.brand(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadEvents),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── All Events header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'All Events',
              style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor(context),
              ),
            ),
          ),

          // ── Events list ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy,
                                size: 64,
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No events found',
                              style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 14,
                                color: AppTheme.textColor(context)
                                    .withOpacity(0.45),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: events.length,
                        itemBuilder: (context, index) =>
                            _buildEventCard(events[index], isDark),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _buildFooter(isDark),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────

  Widget _buildFooter(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color:
                isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE4E7EC),
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
                  fontWeight:
                      selected ? FontWeight.w800 : FontWeight.w600,
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
              apartment: '',
              phone: '')));
      if (mounted) setState(() => _navIndex = -1);
    } else if (index == 3) {
      await Navigator.push(
          context,
          PageAnimations.slideRight(VisitorFormPage(
              userRole: widget.userRole,
              userName: widget.userName,
              userProfile: {
                'name': widget.userName,
                'role': widget.userRole
              })));
      if (mounted) setState(() => _navIndex = -1);
    }
  }

  // ── Event card ────────────────────────────────────────────────────────────

  Widget _buildEventCard(Event event, bool isDark) {
    final isPast = _isPastEvent(event);

    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // date box
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isPast
                    ? Colors.grey.shade400
                    : AppTheme.brand(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDay(event.dateTime),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _getMonth(event.dateTime),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description.length > 50
                        ? '${event.description.substring(0, 50)}...'
                        : event.description,
                    style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 11,
                      color:
                          AppTheme.textColor(context).withOpacity(0.45),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 10,
                          color: AppTheme.textColor(context)
                              .withOpacity(0.45)),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(event.dateTime),
                        style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 10,
                          color: AppTheme.textColor(context)
                              .withOpacity(0.45),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (event.isHallBooking) ...[
                        Icon(Icons.meeting_room,
                            size: 10,
                            color: AppTheme.textColor(context)
                                .withOpacity(0.45)),
                        const SizedBox(width: 4),
                        Text(
                          event.hallName,
                          style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 10,
                            color: AppTheme.textColor(context)
                                .withOpacity(0.45),
                          ),
                        ),
                      ] else ...[
                        Icon(Icons.person,
                            size: 10,
                            color: AppTheme.textColor(context)
                                .withOpacity(0.45)),
                        const SizedBox(width: 4),
                        Text(
                          'By ${event.postedBy}',
                          style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 10,
                            color: AppTheme.textColor(context)
                                .withOpacity(0.45),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isPast)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Past',
                  style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
              )
            else
              Icon(Icons.chevron_right,
                  size: 20,
                  color: AppTheme.textColor(context).withOpacity(0.45)),
          ],
        ),
      ),
    );
  }

  bool _isPastEvent(Event event) {
    try {
      return EventService()
          .parseEventDateTime(event.dateTime)
          .isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String _getDay(String dateTimeStr) {
    try {
      return EventService()
          .parseEventDateTime(dateTimeStr)
          .day
          .toString();
    } catch (_) {
      return '--';
    }
  }

  String _getMonth(String dateTimeStr) {
    try {
      final date = EventService().parseEventDateTime(dateTimeStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return months[date.month - 1];
    } catch (_) {
      return '---';
    }
  }
}

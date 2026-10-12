import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/event.dart';
import '../models/complaint.dart';
import '../widgets/event_card.dart';
import '../widgets/complaint_card.dart';
import '../widgets/loading_shimmer.dart';
import '../theme/app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  final _api = ApiService();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<Event> _events = [];
  List<Complaint> _complaints = [];
  bool _loadingEvents = true;
  bool _loadingComplaints = true;
  bool _postingEvent = false;

  late AnimationController _postBtnCtrl;
  late Animation<double> _postBtnScale;
  late ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _postBtnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _postBtnScale = Tween<double>(begin: 1, end: 0.95)
        .animate(CurvedAnimation(parent: _postBtnCtrl, curve: Curves.easeInOut));
    _scrollCtrl = ScrollController();
    _fetchAll();
  }

  @override
  void dispose() {
    _postBtnCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    _fetchEvents();
    _fetchComplaints();
  }

  Future<void> _fetchEvents() async {
    setState(() => _loadingEvents = true);
    try {
      final events = await _api.getEvents();
      setState(() => _events = events.reversed.toList());
    } catch (e) {
      _showSnack('Failed to load events: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loadingEvents = false);
    }
  }

  Future<void> _fetchComplaints() async {
    setState(() => _loadingComplaints = true);
    try {
      final complaints = await _api.getComplaints();
      setState(() => _complaints = complaints.reversed.toList());
    } catch (e) {
      _showSnack('Failed to load complaints: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loadingComplaints = false);
    }
  }

  Future<void> _postEvent() async {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      _showSnack('Please fill in both title and description', isError: true);
      return;
    }
    setState(() => _postingEvent = true);
    try {
      await _api.createEvent(_titleCtrl.text.trim(), _descCtrl.text.trim());
      _titleCtrl.clear();
      _descCtrl.clear();
      _showSnack('Event posted successfully!');
      await _fetchEvents();
    } catch (e) {
      _showSnack('Failed to post event: $e', isError: true);
    } finally {
      if (mounted) setState(() => _postingEvent = false);
    }
  }

  Future<void> _deleteEvent(int id) async {
    final confirmed = await _showDeleteDialog();
    if (!confirmed) return;
    try {
      await _api.deleteEvent(id);
      _showSnack('Event deleted');
      await _fetchEvents();
    } catch (e) {
      _showSnack('Failed to delete event: $e', isError: true);
    }
  }

  Future<bool> _showDeleteDialog() async {
    return await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Delete',
          transitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (_, __, ___) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Event?',
                style: TextStyle(fontFamily: 'Arial Narrow', fontWeight: FontWeight.w700)),
            content: const Text('This action cannot be undone.',
                style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 13, color: Colors.black54)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel',
                    style: TextStyle(fontFamily: 'Arial Narrow', color: Colors.black54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF04438),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete',
                    style: TextStyle(fontFamily: 'Arial Narrow', color: Colors.white)),
              ),
            ],
          ),
          transitionBuilder: (_, anim, __, child) => ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOut),
            ),
            child: child,
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Arial Narrow', color: Colors.white)),
      backgroundColor: isError ? const Color(0xFFF04438) : const Color(0xFF12B76A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

Future<void> _logout() async {
  await _api.clearSession();
  if (mounted) {
    // Go to login, not splash
    Navigator.of(context).pushReplacementNamed('/login');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: const Text(
                'BlueBug Admin',
                style: TextStyle(fontFamily: 'Arial Narrow', 
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.brand(context), AppTheme.brandLight(context)],
                  ),
                ),
              ),
            ),
            backgroundColor: AppTheme.brand(context),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: _fetchAll,
              ),
              GestureDetector(
                onTap: _logout,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Logout',
                      style: TextStyle(fontFamily: 'Arial Narrow', 
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
        body: RefreshIndicator(
          onRefresh: _fetchAll,
          color: AppTheme.brand(context),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Post Event Card ──────────────────────────────────────────
                _sectionTitle('Post New Event', Icons.add_circle_outline,
                    AppTheme.brand(context)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildField(
                          controller: _titleCtrl,
                          label: 'Event Title',
                          icon: Icons.title),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _descCtrl,
                        label: 'Description',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTapDown: (_) => _postBtnCtrl.forward(),
                        onTapUp: (_) async {
                          await _postBtnCtrl.reverse();
                          _postEvent();
                        },
                        onTapCancel: () => _postBtnCtrl.reverse(),
                        child: ScaleTransition(
                          scale: _postBtnScale,
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.brand(context), AppTheme.brandLight(context)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.brand(context).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _postingEvent
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5))
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.send,
                                            color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Text('Post Event',
                                            style: TextStyle(fontFamily: 'Arial Narrow', 
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white)),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Events List ───────────────────────────────────────────────
                _sectionTitle('Events', Icons.event, AppTheme.brand(context)),
                const SizedBox(height: 10),
                _loadingEvents
                    ? const SizedBox(
                        height: 300,
                        child: LoadingShimmer(itemCount: 3))
                    : _events.isEmpty
                        ? _emptyState('No events posted yet')
                        : Column(
                            children: _events
                                .asMap()
                                .entries
                                .map((e) => EventCard(
                                      event: e.value,
                                      index: e.key,
                                      showDelete: true,
                                      onDelete: () => _deleteEvent(e.value.id),
                                    ))
                                .toList(),
                          ),
                const SizedBox(height: 28),

                // ── Complaints List ───────────────────────────────────────────
                _sectionTitle(
                    'All Complaints', Icons.report_outlined, const Color(0xFFF79009)),
                const SizedBox(height: 10),
                _loadingComplaints
                    ? const SizedBox(
                        height: 300,
                        child: LoadingShimmer(itemCount: 3))
                    : _complaints.isEmpty
                        ? _emptyState('No complaints yet')
                        : Column(
                            children: _complaints
                                .asMap()
                                .entries
                                .map((e) => ComplaintCard(
                                      complaint: e.value,
                                      index: e.key,
                                    ))
                                .toList(),
                          ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontFamily: 'Arial Narrow', 
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF172033),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 42, color: Colors.black26),
          const SizedBox(height: 8),
          Text(msg,
              style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 13, color: Colors.black38)),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 13, color: Color(0xFF172033)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 13, color: Color(0xFF667085)),
        prefixIcon: Icon(icon, color: AppTheme.brand(context), size: 19),
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: const Color(0xFFE4E7EC), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppTheme.brand(context), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
    );
  }
}

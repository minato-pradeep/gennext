import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';

class NoticeBoardPage extends StatefulWidget {
  final String userRole;
  final String userName;
  const NoticeBoardPage(
      {super.key, required this.userRole, required this.userName});

  @override
  State<NoticeBoardPage> createState() => _NoticeBoardPageState();
}

class _NoticeBoardPageState extends State<NoticeBoardPage>
    with WidgetsBindingObserver {
  static String get _base => '${AppConstants.baseUrl}/api/notices';

  List<Map<String, dynamic>> _notices = [];
  bool _loading = true;
  String _filter = 'all';
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
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final res = await http
          .get(Uri.parse(_base).replace(queryParameters: {
            if (userId != null && userId.isNotEmpty) 'user_id': userId,
          }))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _notices = List<Map<String, dynamic>>.from(data['notices']);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _notices;
    return _notices
        .where((n) => (n['priority'] ?? 'normal') == _filter)
        .toList();
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'urgent':
        return Colors.red;
      case 'important':
        return Colors.orange;
      case 'event':
        return Colors.green;
      default:
        return AppTheme.brand(context);
    }
  }

  IconData _priorityIcon(String p) {
    switch (p) {
      case 'urgent':
        return Icons.warning;
      case 'important':
        return Icons.priority_high;
      case 'event':
        return Icons.event;
      default:
        return Icons.info_outline;
    }
  }

  String _fmtDate(String? dt) {
    if (dt == null) return '';
    try {
      final d = DateTime.parse(dt).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return dt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: const Text('Notice Board',
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
          : Column(children: [
              // Filter chips
              Container(
                height: 50,
                margin: const EdgeInsets.all(12),
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  _chip('All', 'all', isDark),
                  const SizedBox(width: 8),
                  _chip('Important', 'important', isDark),
                  const SizedBox(width: 8),
                  _chip('Urgent', 'urgent', isDark),
                  const SizedBox(width: 8),
                  _chip('Event', 'event', isDark),
                  const SizedBox(width: 8),
                  _chip('Normal', 'normal', isDark),
                ]),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                              Icon(Icons.notifications_none,
                                  size: 64,
                                  color: isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('No notices found',
                                  style: TextStyle(
                                      fontFamily: 'Arial Narrow',
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black45)),
                            ]))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _card(filtered[i], isDark),
                        ),
                ),
              ),
            ]),
    );
  }

  Widget _chip(String label, String value, bool isDark) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brand(context)
              : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (AppTheme.textColor(context).withOpacity(0.54)))),
      ),
    );
  }

  Widget _card(Map<String, dynamic> n, bool isDark) {
    final priority = n['priority'] as String? ?? 'normal';
    final color = _priorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Priority color bar
        Container(
            height: 5,
            decoration: BoxDecoration(
                color: color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)))),
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(_priorityIcon(priority), color: color, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(n['title'] ?? '',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(children: [
                      Icon(Icons.person_outline,
                          size: 11,
                          color: AppTheme.textColor(context).withOpacity(0.45)),
                      const SizedBox(width: 3),
                      Text('${n['created_by'] ?? ''}',
                          style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              fontSize: 10,
                              color: AppTheme.textColor(context)
                                  .withOpacity(0.45))),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today,
                          size: 11,
                          color: AppTheme.textColor(context).withOpacity(0.45)),
                      const SizedBox(width: 3),
                      Text(_fmtDate(n['created_at']?.toString()),
                          style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              fontSize: 10,
                              color: AppTheme.textColor(context)
                                  .withOpacity(0.45))),
                    ]),
                  ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(priority.toUpperCase(),
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(n['description'] ?? '',
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 13,
                    color: AppTheme.textColor(context).withOpacity(0.54),
                    height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            if (n['expiry_date'] != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.timer, size: 12, color: Colors.orange),
                const SizedBox(width: 4),
                Text('Expires: ${_fmtDate(n['expiry_date']?.toString())}',
                    style: const TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 10,
                        color: Colors.orange)),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/complaint.dart';
import '../services/complaint_service.dart';
import '../theme/app_theme.dart';

class CheckComplaintPage extends StatefulWidget {
  final String userRole;
  final String userName;

  const CheckComplaintPage(
      {super.key, required this.userRole, required this.userName});

  @override
  State<CheckComplaintPage> createState() => _CheckComplaintPageState();
}

class _CheckComplaintPageState extends State<CheckComplaintPage>
    with WidgetsBindingObserver {
  List<Complaint> _complaints = [];
  String _selectedFilter = 'all';
  bool _isLoading = false;
  Timer? _refreshTimer;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) _load(reset: true);
    });
    ComplaintService().addListener(_onUpdate);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    ComplaintService().removeListener(_onUpdate);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(reset: true);
    }
  }

  void _onUpdate() {
    if (mounted) _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) _page = 1;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ComplaintService()
          .getComplaints(page: _page, status: _selectedFilter);
      if (mounted) {
        setState(() {
          _complaints = result['complaints'];
          _total = result['total'];
          _totalPages = result['totalPages'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onFilterChange(String filter) {
    setState(() {
      _selectedFilter = filter;
      _page = 1;
    });
    _load();
  }

  void _showUpdateDialog(Complaint c) {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final remarksCtrl = TextEditingController(text: c.remarks);
    String selectedStatus = c.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Update Complaint Status',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor(context))),
                Text('Complaint #${c.id} - ${c.issueType}',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 12,
                        color: AppTheme.textColor(context).withOpacity(0.55))),
                const SizedBox(height: 20),
                Text('Status',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            AppTheme.textColor(context))),
                const SizedBox(height: 8),
                Row(children: [
                  _statusOption('Pending', 'pending', selectedStatus,
                      (v) => setSheet(() => selectedStatus = v), isDark),
                  const SizedBox(width: 8),
                  _statusOption('In Progress', 'in_progress', selectedStatus,
                      (v) => setSheet(() => selectedStatus = v), isDark),
                  const SizedBox(width: 8),
                  _statusOption('Resolved', 'resolved', selectedStatus,
                      (v) => setSheet(() => selectedStatus = v), isDark),
                ]),
                const SizedBox(height: 20),
                Text('Remarks (Optional)',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            AppTheme.textColor(context))),
                const SizedBox(height: 8),
                TextField(
                  controller: remarksCtrl,
                  maxLines: 3,
                  style:
                      TextStyle(color: AppTheme.textColor(context)),
                  decoration: InputDecoration(
                    hintText: 'Add remarks about the action taken...',
                    hintStyle: TextStyle(
                        color: AppTheme.textColor(context).withOpacity(0.45)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppTheme.brand(context), width: 2)),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F8FA),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                        foregroundColor:
                            AppTheme.textColor(context).withOpacity(0.54),
                        side: BorderSide(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Cancel'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await ComplaintService().updateStatus(
                            c.id, selectedStatus,
                            remarks: remarksCtrl.text.isNotEmpty
                                ? remarksCtrl.text
                                : null);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Complaint #${c.id} updated to ${_statusText(selectedStatus)}'),
                            backgroundColor: _statusColor(selectedStatus),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ));
                          _load(reset: true);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brand(context),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Update Status',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  )),
                ]),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(Complaint c) {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(children: [
                  Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          color: _statusColor(c.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(_statusIcon(c.status),
                          color: _statusColor(c.status), size: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(c.issueType,
                            style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF212121))),
                        const SizedBox(height: 4),
                        _statusBadge(c.status),
                      ])),
                  IconButton(
                      icon: Icon(Icons.close,
                          color: AppTheme.textColor(context)),
                      onPressed: () => Navigator.pop(context)),
                ]),
                const SizedBox(height: 20),
                _row(Icons.confirmation_number, 'Complaint ID', '#${c.id}',
                    isDark),
                _row(Icons.person, 'Raised By', c.userName, isDark),
                _row(Icons.apartment, 'Apartment', c.userApartment, isDark),
                _row(Icons.category, 'Issue Type', c.issueType, isDark),
                _row(Icons.description, 'Complaint', c.complaintText, isDark),
                _row(
                    Icons.calendar_today, 'Date', _fmtDate(c.dateTime), isDark),
                if (c.remarks != null && c.remarks!.isNotEmpty)
                  _row(Icons.comment, 'Remarks', c.remarks!, isDark),
                if (c.resolvedDate != null)
                  _row(Icons.done_all, 'Resolved Date',
                      _fmtDate(c.resolvedDate!), isDark),
                const SizedBox(height: 20),
                if (c.status != 'resolved')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showUpdateDialog(c);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brand(context),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text('Update Status',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFF12B76A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Row(children: [
                      Icon(Icons.check_circle,
                          color: Color(0xFF12B76A), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text('This complaint is resolved.',
                              style: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  fontSize: 12,
                                  color: Color(0xFF12B76A)))),
                    ]),
                  ),
                const SizedBox(height: 10),
              ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final pending = _complaints.where((c) => c.status == 'pending').length;
    final inProgress =
        _complaints.where((c) => c.status == 'in_progress').length;
    final resolved = _complaints.where((c) => c.status == 'resolved').length;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Check Complaints',
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
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20)),
            child: const Row(children: [
              Icon(Icons.security, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text('Security Mode',
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 10,
                      color: Colors.white))
            ]),
          ),
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _load(reset: true)),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppTheme.brand(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.brand(context).withOpacity(0.3))),
            child: Row(children: [
              Icon(Icons.info_outline, color: AppTheme.brand(context)),
              SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Tap a complaint to update its status. Residents see updates in "All Complaints".',
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 11,
                          color: AppTheme.brand(context)))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _statCard('Pending', pending.toString(), const Color(0xFFF79009), isDark),
              const SizedBox(width: 12),
              _statCard('In Progress', inProgress.toString(), AppTheme.brand(context), isDark),
              const SizedBox(width: 12),
              _statCard('Resolved', resolved.toString(), const Color(0xFF12B76A), isDark),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('All', 'all', isDark),
                const SizedBox(width: 8),
                _chip('Pending', 'pending', isDark),
                const SizedBox(width: 8),
                _chip('In Progress', 'in_progress', isDark),
                const SizedBox(width: 8),
                _chip('Resolved', 'resolved', isDark),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: $_total complaints',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 12,
                            color: AppTheme.textColor(context).withOpacity(0.45))),
                    Text('Page $_page of $_totalPages',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 12,
                            color: AppTheme.textColor(context).withOpacity(0.45))),
                  ]),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            const Icon(Icons.error_outline,
                                size: 60, color: Colors.red),
                            const SizedBox(height: 12),
                            const Text('Failed to load',
                                style: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                )),
                            const SizedBox(height: 8),
                            ElevatedButton(
                                onPressed: () => _load(reset: true),
                                child: const Text('Retry')),
                          ]))
                    : _complaints.isEmpty
                        ? Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                Icon(Icons.report_off_outlined,
                                    size: 64,
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text('No complaints found',
                                    style: TextStyle(
                                        fontFamily: 'Arial Narrow',
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45)),
                              ]))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _complaints.length,
                            itemBuilder: (_, i) =>
                                _card(_complaints[i], isDark),
                          ),
          ),
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(12),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _page > 1
                        ? () {
                            setState(() => _page--);
                            _load();
                          }
                        : null),
                Text('$_page / $_totalPages',
                    style: const TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontWeight: FontWeight.w600)),
                IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _page < _totalPages
                        ? () {
                            setState(() => _page++);
                            _load();
                          }
                        : null),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _card(Complaint c, bool isDark) {
    return GestureDetector(
      onTap: () => _showDetails(c),
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
                offset: const Offset(0, 2))
          ],
          border: c.status == 'pending'
              ? Border.all(color: const Color(0xFFF79009).withOpacity(0.3))
              : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                    color: _statusColor(c.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(_statusIcon(c.status),
                    color: _statusColor(c.status), size: 24)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(c.issueType,
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              AppTheme.textColor(context))),
                  const SizedBox(height: 4),
                  Text(
                      c.complaintText.length > 60
                          ? '${c.complaintText.substring(0, 60)}...'
                          : c.complaintText,
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 11,
                          color: AppTheme.textColor(context).withOpacity(0.45))),
                ])),
            _statusBadge(c.status),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.person,
                size: 12, color: AppTheme.textColor(context).withOpacity(0.45)),
            const SizedBox(width: 4),
            Text(c.userName,
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 10,
                    color: AppTheme.textColor(context).withOpacity(0.45))),
            const SizedBox(width: 12),
            Icon(Icons.apartment,
                size: 12, color: AppTheme.textColor(context).withOpacity(0.45)),
            const SizedBox(width: 4),
            Text(c.userApartment,
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 10,
                    color: AppTheme.textColor(context).withOpacity(0.45))),
            const Spacer(),
            if (c.status != 'resolved')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppTheme.brand(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.edit, size: 10, color: AppTheme.brand(context)),
                  SizedBox(width: 2),
                  Text('Update',
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 9,
                          color: AppTheme.brand(context)))
                ]),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                size: 16, color: AppTheme.textColor(context).withOpacity(0.45)),
          ]),
        ]),
      ),
    );
  }

  Widget _statusOption(String label, String value, String selected,
      Function(String) onTap, bool isDark) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? _statusColor(value).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isSelected
                    ? _statusColor(value)
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                width: isSelected ? 2 : 1),
          ),
          child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? _statusColor(value)
                          : (isDark ? Colors.white70 : Colors.grey)))),
        ),
      ),
    );
  }

  Widget _statCard(String title, String count, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
        child: Column(children: [
          Text(count,
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(title,
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 11,
                  color: AppTheme.textColor(context).withOpacity(0.45))),
        ]),
      ),
    );
  }

  Widget _chip(String label, String value, bool isDark) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label,
          style: TextStyle(
              fontFamily: 'Arial Narrow',
              fontSize: 12,
              color: isSelected
                  ? Colors.white
                  : (AppTheme.textColor(context).withOpacity(0.54)))),
      selected: isSelected,
      onSelected: (_) => _onFilterChange(value),
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
      selectedColor: _statusColor(value == 'all' ? 'pending' : value),
      shape: StadiumBorder(
          side: BorderSide(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: _statusColor(status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Text(_statusText(status),
          style: TextStyle(
              fontFamily: 'Arial Narrow',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _statusColor(status))),
    );
  }

  Widget _row(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: AppTheme.brand(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: AppTheme.brand(context))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 11,
                  color: AppTheme.textColor(context).withOpacity(0.45))),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor(context))),
        ])),
      ]),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return const Color(0xFFF79009);
      case 'in_progress':
        return AppTheme.brand(context);
      case 'resolved':
        return const Color(0xFF12B76A);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'pending':
        return Icons.pending_actions;
      case 'in_progress':
        return Icons.engineering;
      case 'resolved':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  String _statusText(String s) {
    switch (s) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return s;
    }
  }

  String _fmtDate(String dt) {
    try {
      final d = DateTime.parse(dt);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dt;
    }
  }
}

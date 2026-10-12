import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

class CreateNoticePage extends StatefulWidget {
  final String userName;
  final String userRole;
  const CreateNoticePage(
      {super.key, required this.userName, required this.userRole});

  @override
  State<CreateNoticePage> createState() => _CreateNoticePageState();
}

class _CreateNoticePageState extends State<CreateNoticePage>
    with SingleTickerProviderStateMixin {
  static String get _base => '${AppConstants.baseUrl}/api/notices';

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'normal';
  DateTime? _expiryDate;
  bool _submitting = false;

  List<Map<String, dynamic>> _notices = [];
  bool _loading = true;

  // For editing
  Map<String, dynamic>? _editingNotice;

  late TabController _tabCtrl;

  List<Map<String, dynamic>> get _priorities => [
    {'value': 'normal', 'label': 'Normal', 'color': AppTheme.brand(context)},
    {'value': 'important', 'label': 'Important', 'color': Colors.orange},
    {'value': 'urgent', 'label': 'Urgent', 'color': Colors.red},
    {'value': 'event', 'label': 'Event', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tabCtrl.dispose();
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
          _notices = List<Map<String, dynamic>>.from(data['notices']);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      http.Response res;
      if (_editingNotice != null) {
        res = await http
            .put(
              Uri.parse('$_base/${_editingNotice!['id']}'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'title': _titleCtrl.text.trim(),
                'description': _descCtrl.text.trim(),
                'priority': _priority,
                'expiry_date': _expiryDate?.toIso8601String().substring(0, 10)
              }),
            )
            .timeout(const Duration(seconds: 10));
      } else {
        res = await http
            .post(
              Uri.parse(_base),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'title': _titleCtrl.text.trim(),
                'description': _descCtrl.text.trim(),
                'created_by': widget.userName,
                'priority': _priority,
                'expiry_date': _expiryDate?.toIso8601String().substring(0, 10)
              }),
            )
            .timeout(const Duration(seconds: 10));
      }
      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data['success'] == true) {
        _titleCtrl.clear();
        _descCtrl.clear();
        setState(() {
          _priority = 'normal';
          _expiryDate = null;
          _editingNotice = null;
          _submitting = false;
        });
        _load();
        _snack(
            _editingNotice != null
                ? '✅ Notice updated!'
                : '✅ Notice posted to all users!',
            Colors.green);
        _tabCtrl.animateTo(1);
      } else {
        _snack(data['message'] ?? 'Failed', Colors.red);
      }
    } catch (e) {
      if (mounted) _snack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> notice) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Delete Notice?',
                  style: TextStyle(
                      fontFamily: 'Arial Narrow', fontWeight: FontWeight.w700)),
              content: const Text('This cannot be undone.',
                  style: TextStyle(
                    fontFamily: 'Arial Narrow',
                  )),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.white))),
              ],
            ));
    if (confirm == true) {
      await http.delete(Uri.parse('$_base/${notice['id']}'));
      _load();
      _snack('Notice deleted', Colors.red);
    }
  }

  void _startEdit(Map<String, dynamic> notice) {
    setState(() {
      _editingNotice = notice;
      _titleCtrl.text = notice['title'] ?? '';
      _descCtrl.text = notice['description'] ?? '';
      _priority = notice['priority'] ?? 'normal';
      _expiryDate = notice['expiry_date'] != null
          ? DateTime.tryParse(notice['expiry_date'].toString())
          : null;
    });
    _tabCtrl.animateTo(0);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg,
            style: const TextStyle(
              fontFamily: 'Arial Narrow',
            )),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
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

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: Text(_editingNotice != null ? 'Edit Notice' : 'Create Notice',
            style: const TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        backgroundColor: AppTheme.brand(context),
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
            controller: _tabCtrl,
            tabs: const [Tab(text: 'Create / Edit'), Tab(text: 'All Notices')],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70),
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        // Tab 1: Create/Edit
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_editingNotice != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.3))),
                        child: Row(children: [
                          const Icon(Icons.edit,
                              color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  'Editing: ${_editingNotice!['title']}',
                                  style: const TextStyle(
                                      fontFamily: 'Arial Narrow',
                                      fontSize: 12,
                                      color: Colors.orange))),
                          GestureDetector(
                              onTap: () => setState(() {
                                    _editingNotice = null;
                                    _titleCtrl.clear();
                                    _descCtrl.clear();
                                  }),
                              child: const Icon(Icons.close,
                                  color: Colors.orange, size: 16)),
                        ]),
                      ),
                    _field(_titleCtrl, 'Notice Title', Icons.title, isDark,
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 14),
                    _field(_descCtrl, 'Description', Icons.description, isDark,
                        maxLines: 5,
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 14),
                    Text('Priority',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor(context))),
                    const SizedBox(height: 8),
                    Wrap(
                        spacing: 8,
                        children: _priorities.map((p) {
                          final isSelected = _priority == p['value'];
                          final color = p['color'] as Color;
                          return GestureDetector(
                            onTap: () => setState(
                                () => _priority = p['value'] as String),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withOpacity(0.15)
                                      : (isDark
                                          ? const Color(0xFF2A2A2A)
                                          : Colors.white),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: isSelected
                                          ? color
                                          : (isDark
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade300),
                                      width: isSelected ? 2 : 1)),
                              child: Text(p['label'] as String,
                                  style: TextStyle(
                                      fontFamily: 'Arial Narrow',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? color
                                          : (isDark
                                              ? Colors.white70
                                              : Colors.black54))),
                            ),
                          );
                        }).toList()),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                            context: context,
                            initialDate: _expiryDate ??
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)));
                        if (picked != null) {
                          setState(() => _expiryDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300)),
                        child: Row(children: [
                          Icon(Icons.calendar_today,
                              size: 18, color: AppTheme.brand(context)),
                          const SizedBox(width: 12),
                          Text(
                              _expiryDate != null
                                  ? 'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                                  : 'Set Expiry Date (optional)',
                              style: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  fontSize: 13,
                                  color: _expiryDate != null
                                      ? (AppTheme.textColor(context))
                                      : (isDark
                                          ? Colors.white38
                                          : Colors.black38))),
                          const Spacer(),
                          if (_expiryDate != null)
                            GestureDetector(
                                onTap: () => setState(() => _expiryDate = null),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.red)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send, color: Colors.white),
                        label: Text(
                            _editingNotice != null
                                ? 'Update Notice'
                                : 'Post Notice',
                            style: const TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brand(context),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16))),
                      ),
                    ),
                  ])),
        ),

        // Tab 2: All notices with edit/delete
        _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: _notices.isEmpty
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
                            Text('No notices yet',
                                style: TextStyle(
                                    fontFamily: 'Arial Narrow',
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45)),
                          ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notices.length,
                        itemBuilder: (_, i) {
                          final n = _notices[i];
                          final color =
                              _priorityColor(n['priority'] ?? 'normal');
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8)
                                ]),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                          color: color,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(16)))),
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Expanded(
                                                child: Text(n['title'] ?? '',
                                                    style: TextStyle(
                                                        fontFamily:
                                                            'Arial Narrow',
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: isDark
                                                            ? Colors.white
                                                            : Colors.black87),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis)),
                                            Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                    color:
                                                        color.withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                child: Text(
                                                    (n['priority'] ?? 'normal')
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                        fontFamily:
                                                            'Arial Narrow',
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: color))),
                                          ]),
                                          const SizedBox(height: 6),
                                          Text(n['description'] ?? '',
                                              style: TextStyle(
                                                  fontFamily: 'Arial Narrow',
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.black45),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 8),
                                          Row(children: [
                                            Text(
                                                _fmtDate(n['created_at']
                                                    ?.toString()),
                                                style: TextStyle(
                                                    fontFamily: 'Arial Narrow',
                                                    fontSize: 10,
                                                    color: isDark
                                                        ? Colors.white38
                                                        : Colors.black38)),
                                            const Spacer(),
                                            GestureDetector(
                                                onTap: () => _startEdit(n),
                                                child: Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 10,
                                                            vertical: 5),
                                                    decoration:
                                                        BoxDecoration(
                                                            color: AppTheme.brand(context)
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8)),
                                                    child: Row(children: [
                                                      Icon(Icons.edit,
                                                          size: 12,
                                                          color: AppTheme.brand(context)),
                                                      const SizedBox(width: 4),
                                                      Text('Edit',
                                                          style: TextStyle(
                                                              fontFamily:
                                                                  'Arial Narrow',
                                                              fontSize: 11,
                                                              color:
                                                                  AppTheme.brand(context)))
                                                    ]))),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                                onTap: () => _delete(n),
                                                child: Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 10,
                                                            vertical: 5),
                                                    decoration: BoxDecoration(
                                                        color: Colors.red
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8)),
                                                    child: const Row(children: [
                                                      Icon(Icons.delete,
                                                          size: 12,
                                                          color: Colors.red),
                                                      SizedBox(width: 4),
                                                      Text('Delete',
                                                          style: TextStyle(
                                                              fontFamily:
                                                                  'Arial Narrow',
                                                              fontSize: 11,
                                                              color:
                                                                  Colors.red))
                                                    ]))),
                                          ]),
                                        ]),
                                  ),
                                ]),
                          );
                        },
                      ),
              ),
      ]),
    );
  }

  Widget _field(
      TextEditingController ctrl, String label, IconData icon, bool isDark,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
          fontFamily: 'Arial Narrow',
          fontSize: 14,
          color: AppTheme.textColor(context)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.brand(context)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppTheme.brand(context), width: 2)),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
      ),
    );
  }
}

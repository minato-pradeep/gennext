import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../models/user_permissions.dart';
import '../../theme/app_theme.dart';

class AssignPermissionsPage extends StatefulWidget {
  final String userId;
  final String userName;
  final String userRole;
  final UserPermissions initialPermissions;

  const AssignPermissionsPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.initialPermissions,
  });

  @override
  State<AssignPermissionsPage> createState() => _AssignPermissionsPageState();
}

class _AssignPermissionsPageState extends State<AssignPermissionsPage> {
  static String get _base => '${AppConstants.baseUrl}/api/users';

  late UserPermissions _permissions;
  bool _saving = false;

  List<Map<String, dynamic>> get _items => [
    {
      'id': 'emergency',
      'title': 'Emergency',
      'icon': Icons.emergency,
      'color': const Color(0xFFE53935)
    },
    {
      'id': 'buySell',
      'title': 'Buy & Sell',
      'icon': Icons.storefront,
      'color': const Color(0xFF43A047)
    },
    {
      'id': 'raiseComplaint',
      'title': 'Raise Complaint',
      'icon': Icons.report_problem,
      'color': const Color(0xFFFF9800)
    },
    {
      'id': 'allComplaints',
      'title': 'All Complaints',
      'icon': Icons.list_alt,
      'color': const Color(0xFF9C27B0)
    },
    {
      'id': 'events',
      'title': 'Events',
      'icon': Icons.event,
      'color': AppTheme.brandLight(context)
    },
    {
      'id': 'facilities',
      'title': 'Facilities',
      'icon': Icons.fitness_center,
      'color': const Color(0xFF00BCD4)
    },
    {
      'id': 'payments',
      'title': 'Payments',
      'icon': Icons.payments,
      'color': const Color(0xFF607D8B)
    },
    {
      'id': 'visitors',
      'title': 'Visitors',
      'icon': Icons.people,
      'color': const Color(0xFF4CAF50)
    },
    {
      'id': 'visitorApproval',
      'title': 'Visitor Approval',
      'icon': Icons.security,
      'color': const Color(0xFFE53935)
    },
    {
      'id': 'polls',
      'title': 'Polls',
      'icon': Icons.poll,
      'color': const Color(0xFF009688)
    },
    {
      'id': 'documents',
      'title': 'Documents',
      'icon': Icons.folder,
      'color': const Color(0xFF795548)
    },
    {
      'id': 'maintenance',
      'title': 'Create Notice',
      'icon': Icons.announcement,
      'color': AppTheme.brandLight(context)
    },
    {
      'id': 'noticeBoard',
      'title': 'Notice Board',
      'icon': Icons.notifications,
      'color': AppTheme.brand(context)
    },
    {
      'id': 'checkComplaint',
      'title': 'Check Complaint',
      'icon': Icons.assignment_turned_in,
      'color': AppTheme.brandLight(context)
    },
  ];

  @override
  void initState() {
    super.initState();
    _permissions = widget.initialPermissions;
  }

  bool _get(String id) {
    switch (id) {
      case 'emergency':
        return _permissions.emergency;
      case 'buySell':
        return _permissions.buySell;
      case 'raiseComplaint':
        return _permissions.raiseComplaint;
      case 'allComplaints':
        return _permissions.allComplaints;
      case 'events':
        return _permissions.events;
      case 'facilities':
        return _permissions.facilities;
      case 'payments':
        return _permissions.payments;
      case 'visitors':
        return _permissions.visitors;
      case 'visitorApproval':
        return _permissions.visitorApproval;
      case 'polls':
        return _permissions.polls;
      case 'documents':
        return _permissions.documents;
      case 'maintenance':
        return _permissions.maintenance;
      case 'noticeBoard':
        return _permissions.noticeBoard;
      case 'checkComplaint':
        return _permissions.checkComplaint;
      default:
        return false;
    }
  }

  void _toggle(String id, bool value) {
    setState(() {
      switch (id) {
        case 'emergency':
          _permissions = _permissions.copyWith(emergency: value);
          break;
        case 'buySell':
          _permissions = _permissions.copyWith(buySell: value);
          break;
        case 'raiseComplaint':
          _permissions = _permissions.copyWith(raiseComplaint: value);
          break;
        case 'allComplaints':
          _permissions = _permissions.copyWith(allComplaints: value);
          break;
        case 'events':
          _permissions = _permissions.copyWith(events: value);
          break;
        case 'facilities':
          _permissions = _permissions.copyWith(facilities: value);
          break;
        case 'payments':
          _permissions = _permissions.copyWith(payments: value);
          break;
        case 'visitors':
          _permissions = _permissions.copyWith(visitors: value);
          break;
        case 'visitorApproval':
          _permissions = _permissions.copyWith(visitorApproval: value);
          break;
        case 'polls':
          _permissions = _permissions.copyWith(polls: value);
          break;
        case 'documents':
          _permissions = _permissions.copyWith(documents: value);
          break;
        case 'maintenance':
          _permissions = _permissions.copyWith(maintenance: value);
          break;
        case 'noticeBoard':
          _permissions = _permissions.copyWith(noticeBoard: value);
          break;
        case 'checkComplaint':
          _permissions = _permissions.copyWith(checkComplaint: value);
          break;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final res = await http
          .put(
            Uri.parse('$_base/${widget.userId}/permissions'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'permissions': _permissions.toMap()}),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Permissions saved to DB!'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data['message'] ?? 'Failed'),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final roleColor = widget.userRole == 'owner'
        ? Colors.orange
        : widget.userRole == 'security'
            ? Colors.red
            : Colors.green;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Permissions: ${widget.userName}',
            style: const TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        backgroundColor: const Color(0xFF9C27B0),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
          ),
        ],
      ),
      body: Column(children: [
        // User info
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
              ]),
          child: Row(children: [
            Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.person,
                    color: Color(0xFF9C27B0), size: 28)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.userName,
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87)),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(widget.userRole.toUpperCase(),
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: roleColor))),
            ]),
          ]),
        ),
        // Enable/Disable all
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(
                child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _permissions.enableAll();
              }),
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Enable All'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            )),
            const SizedBox(width: 12),
            Expanded(
                child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _permissions = UserPermissions(profile: true);
              }),
              icon: const Icon(Icons.cancel, size: 18),
              label: const Text('Disable All'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            )),
          ]),
        ),
        const SizedBox(height: 12),
        // Permissions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final item = _items[i];
              final enabled = _get(item['id'] as String);
              final color = item['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: enabled
                          ? color.withOpacity(0.5)
                          : (isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200),
                      width: enabled ? 1.5 : 1),
                ),
                child: CheckboxListTile(
                  value: enabled,
                  onChanged: (v) => _toggle(item['id'] as String, v ?? false),
                  activeColor: color,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(item['title'] as String,
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87)),
                  secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(item['icon'] as IconData,
                          color: color, size: 22)),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

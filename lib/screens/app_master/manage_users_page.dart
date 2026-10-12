import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../models/user_permissions.dart';
import 'assign_permissions_page.dart';
import '../../theme/app_theme.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  static String get _base => '${AppConstants.baseUrl}/api/users';

  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _search = '';
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res =
          await http.get(Uri.parse(_base)).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        final users = List<Map<String, dynamic>>.from(data['users']);
        setState(() {
          _users = users.where((u) => u['role'] != 'master').toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    if (user['username'] == 'macs') {
      _snack('Cannot modify default user macs', Colors.orange);
      return;
    }
    try {
      await http.put(
        Uri.parse('$_base/${user['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': user['name'],
          'apartment': user['apartment'],
          'phone': user['phone'],
          'role': user['role'],
          'is_active': !(user['is_active'] as bool)
        }),
      );
      _load();
    } catch (e) {
      _snack('Error: $e', Colors.red);
    }
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    if (user['username'] == 'macs') {
      _snack('Cannot modify default user macs', Colors.orange);
      return;
    }
    try {
      await http.put(
        Uri.parse('$_base/${user['id']}/password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': '123456'}),
      );
      _snack('Password reset to "123456" for ${user['name']}', AppTheme.brand(context));
    } catch (e) {
      _snack('Error: $e', Colors.red);
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    if (user['username'] == 'macs') {
      _snack('Cannot delete default user macs', Colors.orange);
      return;
    }
    final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('Delete ${user['name']}?',
                  style: const TextStyle(
                      fontFamily: 'Arial Narrow', fontWeight: FontWeight.w700)),
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
      await http.delete(Uri.parse('$_base/${user['id']}'));
      _load();
      _snack('User deleted', Colors.red);
    }
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

  List<Map<String, dynamic>> get _filtered => _users.where((u) {
        if (_roleFilter != 'all' && u['role'] != _roleFilter) return false;
        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          return (u['name'] ?? '').toLowerCase().contains(q) ||
              (u['username'] ?? '').toLowerCase().contains(q) ||
              (u['apartment'] ?? '').toLowerCase().contains(q);
        }
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Manage Users',
            style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        backgroundColor: const Color(0xFF9C27B0),
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load)
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    hintStyle: TextStyle(
                        fontFamily: 'Arial Narrow',
                        color: isDark ? Colors.white54 : Colors.black45),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF9C27B0)),
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
                        borderSide: const BorderSide(
                            color: Color(0xFF9C27B0), width: 2)),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                  ),
                ),
              ),
              Container(
                height: 45,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  _chip('All', 'all', isDark),
                  const SizedBox(width: 8),
                  _chip('Owner', 'owner', isDark),
                  const SizedBox(width: 8),
                  _chip('Security', 'security', isDark),
                  const SizedBox(width: 8),
                  _chip('Visitor', 'visitor', isDark),
                ]),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text('No users found',
                            style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                color:
                                    isDark ? Colors.white54 : Colors.black45)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _card(filtered[i], isDark),
                      ),
              ),
            ]),
    );
  }

  Widget _chip(String label, String value, bool isDark) {
    final isSelected = _roleFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _roleFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF9C27B0)
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
                    : (isDark ? Colors.white70 : Colors.black54))),
      ),
    );
  }

  Widget _card(Map<String, dynamic> user, bool isDark) {
    final isActive = user['is_active'] as bool? ?? true;
    final role = user['role'] as String? ?? '';
    final isMacs = user['username'] == 'macs';
    final roleColor = role == 'owner'
        ? Colors.orange
        : role == 'security'
            ? Colors.red
            : Colors.green;

    // Parse permissions from DB
    final rawPerms = user['permissions'];
    UserPermissions perms;
    if (rawPerms != null && rawPerms is Map) {
      perms = UserPermissions.fromMap(Map<String, dynamic>.from(rawPerms));
    } else {
      perms = UserPermissions();
    }

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
      child: Column(children: [
        Row(children: [
          Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(
                  role == 'owner'
                      ? Icons.home
                      : role == 'security'
                          ? Icons.security
                          : Icons.people_outline,
                  color: roleColor,
                  size: 26)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(user['name'] ?? '',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
                Text('@${user['username']} • ${user['apartment'] ?? ''}',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black45)),
                const SizedBox(height: 4),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(role.toUpperCase(),
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: roleColor))),
              ])),
          Switch(
              value: isActive,
              onChanged: isMacs ? null : (_) => _toggleActive(user),
              activeColor: Colors.green),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child:
                  _btn('Permissions', Icons.lock_open, const Color(0xFF9C27B0),
                      () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AssignPermissionsPage(
                        userId: user['id'].toString(),
                        userName: user['name'] ?? '',
                        userRole: role,
                        initialPermissions: perms)));
            _load();
          }, isDark)),
          const SizedBox(width: 8),
          Expanded(
              child: _btn('Reset PW', Icons.refresh, AppTheme.brandLight(context),
                  () => _resetPassword(user), isDark)),
          const SizedBox(width: 8),
          Expanded(
              child: _btn('Delete', Icons.delete, Colors.red,
                  () => _deleteUser(user), isDark)),
        ]),
      ]),
    );
  }

  Widget _btn(String title, IconData icon, Color color, VoidCallback onTap,
      bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(title,
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      ),
    );
  }
}

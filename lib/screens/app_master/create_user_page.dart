import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  static String get _base => '${ApiService.baseUrl}/api/auth/register';
  static String get _usersBase => '${ApiService.baseUrl}/api/users';

  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _apartmentCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _flatCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();

  String _selectedRole = 'owner';
  bool _loading = false;
  bool _showPassword = false;

  final List<String> _roles = ['owner', 'security', 'visitor'];

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _apartmentCtrl.dispose();
    _phoneCtrl.dispose();
    _flatCtrl.dispose();
    _addressCtrl.dispose();
    _aadharCtrl.dispose();
    _panCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  Map<String, bool> _defaultPermissions(String role) {
    final base = {
      'emergency': true,
      'buySell': true,
      'raiseComplaint': true,
      'allComplaints': true,
      'events': true,
      'facilities': true,
      'payments': true,
      'visitors': true,
      'visitorApproval': false,
      'polls': true,
      'documents': true,
      'maintenance': true,
      'noticeBoard': true,
      'checkComplaint': false,
      'profile': true,
    };
    if (role == 'security') {
      base['visitorApproval'] = true;
      base['checkComplaint'] = true;
    }
    return base;
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await http
          .post(
            Uri.parse(_base),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': _usernameCtrl.text.trim(),
              'password': _passwordCtrl.text,
              'name': _nameCtrl.text.trim(),
              'role': _selectedRole,
              'apartment': _apartmentCtrl.text.trim(),
              'phone': _phoneCtrl.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (data['success'] == true) {
        // Save default permissions based on role
        final userId = data['user']['id'];
        final defaultPerms = _defaultPermissions(_selectedRole);
        await http.put(
          Uri.parse('$_usersBase/$userId/permissions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'permissions': defaultPerms}),
        );
        // Save extra profile fields
        await http.put(
          Uri.parse('$_usersBase/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': _nameCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'apartment': _apartmentCtrl.text.trim(),
            'flat_number': _flatCtrl.text.trim(),
            'address': _addressCtrl.text.trim(),
            'aadhar': _aadharCtrl.text.trim(),
            'pan': _panCtrl.text.trim(),
            'vehicle_number': _vehicleCtrl.text.trim(),
            'role': _selectedRole,
            'is_active': true,
          }),
        );
        _usernameCtrl.clear();
        _passwordCtrl.clear();
        _nameCtrl.clear();
        _apartmentCtrl.clear();
        _phoneCtrl.clear();
        _flatCtrl.clear();
        _addressCtrl.clear();
        _aadharCtrl.clear();
        _panCtrl.clear();
        _vehicleCtrl.clear();
        setState(() {
          _selectedRole = 'owner';
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✅ User "${data['user']['username']}" created!'),
              backgroundColor: Colors.green),
        );
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['message'] ?? 'Failed to create user'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Create User',
            style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        backgroundColor: const Color(0xFF9C27B0),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.person_add, color: Colors.white, size: 40),
                      SizedBox(height: 10),
                      Text('Add New User',
                          style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(
                          'User will be saved to database and can login immediately',
                          style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              fontSize: 12,
                              color: Colors.white70)),
                    ]),
              ),

              const SizedBox(height: 24),

              _field(_usernameCtrl, 'Username', Icons.person_outline, isDark,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 14),
              _field(_nameCtrl, 'Full Name', Icons.badge_outlined, isDark,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 14),

              // Role
              Text('Role',
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    dropdownColor:
                        isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    items: _roles
                        .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.toUpperCase(),
                                style: TextStyle(
                                    fontFamily: 'Arial Narrow',
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87))))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedRole = v!),
                  ),
                ),
              ),

              const SizedBox(height: 14),
              _field(_apartmentCtrl, 'Apartment (e.g. A-101)', Icons.apartment,
                  isDark),
              const SizedBox(height: 14),
              _field(_flatCtrl, 'Flat Number', Icons.door_front_door, isDark),
              const SizedBox(height: 14),
              _field(_phoneCtrl, 'Phone Number', Icons.phone_outlined, isDark,
                  type: TextInputType.phone),
              const SizedBox(height: 14),
              _field(_addressCtrl, 'Address', Icons.home_outlined, isDark),
              const SizedBox(height: 14),
              _field(_aadharCtrl, 'Aadhar Number', Icons.credit_card, isDark,
                  type: TextInputType.number),
              const SizedBox(height: 14),
              _field(_panCtrl, 'PAN Number', Icons.badge_outlined, isDark),
              const SizedBox(height: 14),
              _field(
                  _vehicleCtrl, 'Vehicle Number', Icons.directions_car, isDark),
              const SizedBox(height: 14),

              // Password
              TextFormField(
                controller: _passwordCtrl,
                obscureText: !_showPassword,
                validator: (v) => v!.length < 4 ? 'Min 4 characters' : null,
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: Color(0xFF9C27B0)),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
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
                      borderSide:
                          const BorderSide(color: Color(0xFF9C27B0), width: 2)),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _createUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Create User',
                          style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController ctrl, String label, IconData icon, bool isDark,
      {TextInputType type = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: validator,
      style: TextStyle(
          fontFamily: 'Arial Narrow',
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF9C27B0)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2)),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';

class CreatePaymentPage extends StatefulWidget {
  final String userName;
  final String userRole;
  const CreatePaymentPage(
      {super.key, required this.userName, required this.userRole});

  @override
  State<CreatePaymentPage> createState() => _CreatePaymentPageState();
}

class _CreatePaymentPageState extends State<CreatePaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  String _billType = 'maintenance';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  String _shareOption = 'all';
  List<Map<String, dynamic>> _allUsers = [];
  final List<String> _selectedIds = [];
  bool _loading = false;
  bool _loadingUsers = true;

  final List<Map<String, dynamic>> _billTypes = [
    {'value': 'maintenance', 'label': 'Maintenance Fee', 'icon': Icons.build},
    {'value': 'community', 'label': 'Community Fund', 'icon': Icons.people},
    {'value': 'water', 'label': 'Water Bill', 'icon': Icons.water_drop},
    {
      'value': 'electricity',
      'label': 'Electricity Bill',
      'icon': Icons.flash_on
    },
    {'value': 'parking', 'label': 'Parking Fee', 'icon': Icons.local_parking},
    {'value': 'other', 'label': 'Other', 'icon': Icons.receipt},
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await PaymentService().getOwnerUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _loadingUsers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ids = _shareOption == 'all'
        ? _allUsers.map((u) => u['id'].toString()).toList()
        : _selectedIds;
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No users selected'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _loading = true);
    try {
      await PaymentService().createBill(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text),
        dueDate:
            '${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}',
        billType: _billType,
        createdBy: widget.userName,
        userIds: ids,
      );
      if (!mounted) return;
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: const Column(children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 60),
                  SizedBox(height: 10),
                  Text('Bill Created!',
                      style: TextStyle(
                          fontFamily: 'Segoe UI', fontWeight: FontWeight.w700)),
                ]),
                content: Text(
                    'Bill shared with ${ids.length} user(s). They can see it in Payments.',
                    style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 13),
                    textAlign: TextAlign.center),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brand(context),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Done',
                        style: TextStyle(color: Colors.white)),
                  )
                ],
              ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: Text('Create Bill',
            style: AppTheme.titleLarge.copyWith(color: Colors.white)),
        backgroundColor: AppTheme.brand(context),
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
            key: _formKey,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20)),
                child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.payments, color: Colors.white, size: 32),
                      SizedBox(height: 10),
                      Text('Create New Bill',
                          style: TextStyle(
                              fontFamily: 'Segoe UI',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(
                          'Bill will be saved to DB and visible to assigned users',
                          style: TextStyle(
                              fontFamily: 'Segoe UI',
                              fontSize: 12,
                              color: Colors.white70)),
                    ]),
              ),
              const SizedBox(height: 20),

              _field(_titleCtrl, 'Bill Title', Icons.title, isDark,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 14),
              _field(_descCtrl, 'Description', Icons.description, isDark,
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 14),

              // Bill type
              Text('Bill Type',
                  style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300)),
                child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                  value: _billType,
                  isExpanded: true,
                  dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                  items: _billTypes
                      .map((t) => DropdownMenuItem(
                          value: t['value'] as String,
                          child: Row(children: [
                            Icon(t['icon'] as IconData,
                                size: 18, color: AppTheme.brand(context)),
                            const SizedBox(width: 10),
                            Text(t['label'] as String,
                                style: TextStyle(
                                    fontFamily: 'Segoe UI',
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87)),
                          ])))
                      .toList(),
                  onChanged: (v) => setState(() => _billType = v!),
                )),
              ),
              const SizedBox(height: 14),

              Row(children: [
                Expanded(
                    child: _field(
                        _amountCtrl, 'Amount (₹)', Icons.currency_rupee, isDark,
                        type: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null)),
                const SizedBox(width: 12),
                Expanded(
                    child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                        color:
                            isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300)),
                    child: Row(children: [
                      Icon(Icons.calendar_today,
                          size: 18, color: AppTheme.brand(context)),
                      const SizedBox(width: 8),
                      Text('${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                          style:
                              const TextStyle(fontFamily: 'Segoe UI', fontSize: 13)),
                    ]),
                  ),
                )),
              ]),
              const SizedBox(height: 20),

              // Share with
              Text('Share With',
                  style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child:
                        _shareCard('All Owners', 'all', Icons.people, isDark)),
                const SizedBox(width: 12),
                Expanded(
                    child: _shareCard(
                        'Select Users', 'specific', Icons.person_add, isDark)),
              ]),

              if (_shareOption == 'specific') ...[
                const SizedBox(height: 16),
                _loadingUsers
                    ? const Center(child: CircularProgressIndicator())
                    : _allUsers.isEmpty
                        ? const Text('No owner users found',
                            style: TextStyle(
                                fontFamily: 'Segoe UI', color: Colors.red))
                        : Container(
                            height: 200,
                            decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkSurface
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300)),
                            child: ListView.builder(
                              itemCount: _allUsers.length,
                              itemBuilder: (_, i) {
                                final u = _allUsers[i];
                                final id = u['id'].toString();
                                return CheckboxListTile(
                                  value: _selectedIds.contains(id),
                                  onChanged: (_) => setState(() =>
                                      _selectedIds.contains(id)
                                          ? _selectedIds.remove(id)
                                          : _selectedIds.add(id)),
                                  title: Text(u['name'] ?? '',
                                      style: const TextStyle(
                                          fontFamily: 'Segoe UI',
                                          fontSize: 13)),
                                  subtitle: Text(
                                      '${u['apartment'] ?? ''} • ${u['phone'] ?? ''}',
                                      style: const TextStyle(
                                          fontFamily: 'Segoe UI',
                                          fontSize: 11)),
                                  dense: true,
                                );
                              },
                            ),
                          ),
              ],

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Create Bill',
                          style: TextStyle(
                              fontFamily: 'Segoe UI',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ])),
      ),
    );
  }

  Widget _shareCard(String title, String value, IconData icon, bool isDark) {
    final isSelected = _shareOption == value;
    return GestureDetector(
      onTap: () => setState(() => _shareOption = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brand(context).withOpacity(0.1)
              : (isDark ? AppTheme.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected
                  ? AppTheme.brand(context)
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              width: isSelected ? 2 : 1),
        ),
        child: Column(children: [
          Icon(icon,
              color: isSelected ? AppTheme.brand(context) : Colors.grey, size: 28),
          const SizedBox(height: 6),
          Text(title,
              style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppTheme.brand(context)
                      : (isDark ? Colors.white70 : Colors.black54)),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _field(
      TextEditingController ctrl, String label, IconData icon, bool isDark,
      {TextInputType type = TextInputType.text,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87),
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
        fillColor: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
      ),
    );
  }
}

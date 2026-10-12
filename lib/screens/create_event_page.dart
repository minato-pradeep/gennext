import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';

class CreateEventPage extends StatefulWidget {
  final String userRole;
  final String userName;

  const CreateEventPage(
      {super.key, required this.userRole, required this.userName});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final selectedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final dateTimeStr =
          '${selectedDateTime.year.toString().padLeft(4, '0')}-${selectedDateTime.month.toString().padLeft(2, '0')}-${selectedDateTime.day.toString().padLeft(2, '0')} '
          '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}:00';

      await EventService().createEvent(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        dateTime: dateTimeStr,
        postedBy: widget.userName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Event created!'),
            backgroundColor: Color(0xFF12B76A)),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Create Event',
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
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: const Text('POST',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _card(
                  isDark,
                  TextFormField(
                    controller: _titleCtrl,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Event Title',
                      hintText: 'Enter event title',
                      prefixIcon:
                          Icon(Icons.title, color: AppTheme.brand(context)),
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
                          isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    ),
                  )),
              const SizedBox(height: 16),
              _card(
                  isDark,
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 5,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter event description',
                      prefixIcon: Icon(Icons.description,
                          color: AppTheme.brand(context)),
                      alignLabelWithHint: true,
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
                          isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    ),
                  )),
              const SizedBox(height: 16),
              // Date picker
              _pickerTile(
                  isDark,
                  Icons.calendar_today,
                  'Event Date',
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  _pickDate),
              const SizedBox(height: 16),
              // Time picker
              _pickerTile(
                  isDark,
                  Icons.access_time,
                  'Event Time',
                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                  _pickTime),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brand(context),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('CREATE EVENT',
                          style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(bool isDark, Widget child) => Container(
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12)),
        child: child,
      );

  Widget _pickerTile(bool isDark, IconData icon, String label, String value,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        child: Row(children: [
          Icon(icon, color: AppTheme.brand(context)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87)),
              ])),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ]),
      ),
    );
  }
}

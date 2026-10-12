import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class AddPollPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final Map<String, String> userProfile;

  const AddPollPage(
      {super.key,
      required this.userRole,
      required this.userName,
      required this.userProfile});

  @override
  State<AddPollPage> createState() => _AddPollPageState();
}

class _AddPollPageState extends State<AddPollPage> {
  static String get _base => '${AppConstants.baseUrl}/api/polls';

  final _formKey = GlobalKey<FormState>();
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _addOption();
    _addOption();
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() => _optionCtrls.add(TextEditingController()));
  }

  void _removeOption(int i) {
    if (_optionCtrls.length <= 2) {
      _snack('Minimum 2 options required', const Color(0xFFF79009));
      return;
    }
    _optionCtrls[i].dispose();
    setState(() => _optionCtrls.removeAt(i));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final options = _optionCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (options.length < 2) {
      _snack('At least 2 options required', const Color(0xFFF79009));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final apartment = prefs.getString('user_apartment') ??
          widget.userProfile['unitNumber'] ??
          '';

      final res = await http
          .post(
            Uri.parse(_base),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'question': _questionCtrl.text.trim(),
              'options': options,
              'created_by': widget.userName,
              'created_by_apartment': apartment,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (data['success'] == true) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Column(children: [
                    Icon(Icons.check_circle,
                        color: AppTheme.brand(context), size: 60),
                    SizedBox(height: 10),
                    Text('Poll Created!',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontWeight: FontWeight.w700)),
                  ]),
                  content: const Text(
                      'Your poll is live. Community members can now vote.',
                      style:
                          TextStyle(fontFamily: 'Arial Narrow', fontSize: 13),
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
      } else {
        _snack(data['message'] ?? 'Failed', Colors.red);
      }
    } catch (e) {
      if (mounted) _snack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Create Poll',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
            key: _formKey,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Question
              Text('Poll Question',
                  style: TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _questionCtrl,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'e.g., What time should the meeting start?',
                  hintStyle: TextStyle(
                      fontFamily: 'Arial Narrow',
                      color: isDark ? Colors.white54 : Colors.black45),
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
                          BorderSide(color: AppTheme.brand(context), width: 2)),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 20),

              // Options
              Row(children: [
                Text('Options',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
                const Spacer(),
                TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppTheme.brand(context))),
              ]),
              const SizedBox(height: 8),

              ...List.generate(
                  _optionCtrls.length,
                  (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Expanded(
                              child: TextFormField(
                            controller: _optionCtrls[i],
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                            style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Option ${i + 1}',
                              hintStyle: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  color:
                                      isDark ? Colors.white54 : Colors.black45),
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
                              fillColor: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.grey.shade50,
                            ),
                          )),
                          const SizedBox(width: 8),
                          IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.red),
                              onPressed: () => _removeOption(i)),
                        ]),
                      )),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brand(context),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Create Poll',
                          style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                ),
              ),
            ])),
      ),
    );
  }
}

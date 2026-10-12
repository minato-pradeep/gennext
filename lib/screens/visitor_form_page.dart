import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class VisitorFormPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final Map<String, String> userProfile;

  const VisitorFormPage(
      {super.key,
      required this.userRole,
      required this.userName,
      required this.userProfile});

  @override
  State<VisitorFormPage> createState() => _VisitorFormPageState();
}

class _VisitorFormPageState extends State<VisitorFormPage> {
  static String get _base => '${AppConstants.baseUrl}/api/visitors';

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();

  File? _pickedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _purposeCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 60,
        maxWidth: 800,
      );
      if (picked != null && mounted) {
        setState(() => _pickedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not pick image: $e'),
                backgroundColor: Colors.red));
      }
    }
  }

  void _showImageSourceSheet() {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('Select Image Source',
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: _sourceOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                color: AppTheme.brand(context),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _sourceOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                color: AppTheme.brand(context),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _sourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Arial Narrow',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      ),
    );
  }

  Future<String?> _imageToBase64() async {
    if (_pickedImage == null) return null;
    final bytes = await _pickedImage!.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final imageBase64 = await _imageToBase64();

      final res = await http
          .post(
            Uri.parse(_base),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'host_user_id': userId != null ? int.tryParse(userId) : null,
              'visitor_name': _nameCtrl.text.trim(),
              'visitor_phone': _phoneCtrl.text.trim(),
              'purpose': _purposeCtrl.text.trim(),
              'vehicle_number': _vehicleCtrl.text.trim().isNotEmpty
                  ? _vehicleCtrl.text.trim().toUpperCase()
                  : null,
              'visitor_image': imageBase64,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (data['success'] == true) {
        _sendWhatsApp(_phoneCtrl.text.trim(), _nameCtrl.text.trim());
        _showSuccess();
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _sendWhatsApp(String phone, String visitorName) {
    final ownerName = widget.userProfile['name'] ?? widget.userName;
    final apt = widget.userProfile['unitNumber'] ?? '';
    final msg = Uri.encodeComponent(
        '🏠 *VISITOR PASS*\n\n👤 Visitor: $visitorName\n🏢 Host: $ownerName\n🏠 Apartment: $apt\n📅 Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}\n\n⚠️ Show this at security gate.');
    final num = phone.startsWith('+') ? phone.replaceAll('+', '') : '91$phone';
    launchUrl(Uri.parse('https://wa.me/$num?text=$msg'),
        mode: LaunchMode.externalApplication);
  }

  void _showSuccess() {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Column(children: [
                const Icon(Icons.check_circle,
                    color: Color(0xFF12B76A), size: 60),
                const SizedBox(height: 10),
                Text('Visitor Registered!',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87)),
              ]),
              content: const Text(
                  'Visitor saved. WhatsApp sent. Security will approve on arrival.',
                  style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 13),
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final profile = widget.userProfile;

    final cardBg = isDark ? const Color(0xFF1E2A3A) : const Color(0xFFBDD9F2);
    final cardBorder = isDark ? Colors.white12 : const Color(0xFF90C4E8);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Register Visitor',
          style: TextStyle(
            fontFamily: 'Arial Narrow',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.brand(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Card — text left, image right, no overlap ──
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: cardBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brand(context).withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 0, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ── LEFT: all text content ──
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar + name
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark
                                            ? Colors.white12
                                            : Colors.white
                                                .withValues(alpha: 0.7),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white24
                                              : Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        size: 20,
                                        color: isDark
                                            ? Colors.white70
                                            : const Color(0xFF3A7BD5),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profile['name'] ?? widget.userName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Arial Narrow',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF1A1A2E),
                                            ),
                                          ),
                                          Text(
                                            (profile['unitNumber'] != null &&
                                                    profile['unitNumber']!
                                                        .isNotEmpty)
                                                ? profile['unitNumber']!
                                                : widget.userRole,
                                            style: TextStyle(
                                              fontFamily: 'Arial Narrow',
                                              fontSize: 11,
                                              color: isDark
                                                  ? Colors.white60
                                                  : const Color(0xFF3A7BD5),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Visitor Pass',
                                  style: TextStyle(
                                    fontFamily: 'Arial Narrow',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF3A7BD5),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Fill details below',
                                  style: TextStyle(
                                    fontFamily: 'Arial Narrow',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1A1A2E),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── RIGHT: visiter.png ──
                          SizedBox(
                            width: 90,
                            height: 110,
                            child: Image.asset(
                              'assets/icons/visiter.png',
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomRight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Visitor form only
                _section('Visitor Details', AppTheme.brand(context), isDark, [
                  // --- Visitor Photo (optional) ---
                  _imagePickerTile(isDark),
                  const SizedBox(height: 14),

                  _field(_nameCtrl, 'Visitor Name', Icons.person_outline, isDark,
                      validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 14),
                  _field(_phoneCtrl, 'Visitor Phone', Icons.phone_outlined, isDark,
                      type: TextInputType.phone,
                      validator: (v) =>
                          v!.length < 10 ? 'Enter valid number' : null),
                  const SizedBox(height: 14),
                  _field(_purposeCtrl, 'Purpose of Visit',
                      Icons.info_outline, isDark),
                  const SizedBox(height: 14),

                  // --- Vehicle Number (optional) ---
                  _field(
                    _vehicleCtrl,
                    'Vehicle Number (optional)',
                    Icons.directions_car_outlined,
                    isDark,
                    type: TextInputType.text,
                  ),
                ]),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send, color: Colors.white),
                    label: const Text('Register & Notify Visitor',
                        style: TextStyle(
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Image picker tile
  Widget _imagePickerTile(bool isDark) {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        child: _pickedImage == null
            ? Column(children: [
                Icon(Icons.add_a_photo_outlined,
                    size: 36,
                    color: isDark
                        ? Colors.white38
                        : Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('Add Visitor Photo  (optional)',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 13,
                        color: isDark
                            ? Colors.white38
                            : Colors.grey.shade500)),
              ])
            : Stack(alignment: Alignment.topRight, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_pickedImage!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => setState(() => _pickedImage = null),
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: _showImageSourceSheet,
                    child: Container(
                      decoration: BoxDecoration(
                          color: AppTheme.brand(context),
                          shape: BoxShape.circle),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.edit,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ]),
      ),
    );
  }

  Widget _section(
      String title, Color color, bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 12)
          ]),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20))),
          child: Row(children: [
            const Icon(Icons.info, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color))
          ]),
        ),
        Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children)),
      ]),
    );
  }

  Widget _infoTile(
      IconData icon, String label, String value, bool isDark) {
    return Row(children: [
      Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: AppTheme.brand(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppTheme.brand(context))),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black45)),
        Text(value,
            style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87)),
      ]),
    ]);
  }

  Widget _field(
      TextEditingController ctrl, String label, IconData icon, bool isDark,
      {TextInputType type = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: validator,
      textCapitalization: type == TextInputType.text
          ? TextCapitalization.characters
          : TextCapitalization.none,
      style: TextStyle(
          fontFamily: 'Arial Narrow',
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.brand(context)),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }
}


import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/permission_service.dart';
import '../services/haptic_service.dart';
import '../models/user_permissions.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _serverIpCtrl = TextEditingController();
  final _apiService = ApiService();
  final _permissionService = PermissionService();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  bool _obscure = true;
  bool _keyboardOpen = false;
  String? _error;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _elevateController;
  late Animation<double> _elevateAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _elevateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _elevateAnimation =
        CurvedAnimation(parent: _elevateController, curve: Curves.easeInOut);

    _usernameFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);

    // Load stored IP and show it in the field
    AppConstants.getStoredServerIp().then((ip) {
      final resolved = ip.isNotEmpty ? ip : AppConstants.serverIp;
      if (mounted) _serverIpCtrl.text = resolved;
      AppConstants.setServerIp(resolved);
    });
  }

  void _onFocusChange() {
    final focused = _usernameFocus.hasFocus || _passwordFocus.hasFocus;
    if (focused != _keyboardOpen) {
      setState(() => _keyboardOpen = focused);
      if (focused) {
        _elevateController.forward();
      } else {
        _elevateController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _serverIpCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _fadeController.dispose();
    _elevateController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    // Save and apply the IP from the field before login
    final typedIp = _serverIpCtrl.text.trim();
    if (typedIp.isNotEmpty) {
      await AppConstants.setServerIp(typedIp);
    }
    final storedIp = await AppConstants.getStoredServerIp();

    try {
      final user = await _apiService.login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
        serverIp: storedIp.isNotEmpty ? storedIp : null,
      );
      if (!mounted) return;
      await HapticService.success();
      final role = user['role'] as String;
      final name = user['name'] as String;
      final permsData = user['permissions'];
      UserPermissions perms;
      if (permsData != null && permsData is Map && permsData.isNotEmpty) {
        perms = UserPermissions.fromMap(Map<String, dynamic>.from(permsData));
      } else {
        perms = UserPermissions(
          emergency: true,
          buySell: true,
          raiseComplaint: true,
          allComplaints: true,
          events: true,
          facilities: true,
          payments: true,
          visitors: true,
          visitorApproval: true,
          polls: true,
          documents: true,
          maintenance: true,
          noticeBoard: true,
          checkComplaint: true,
          profile: true,
        );
      }
      _permissionService.setCurrentUserPermissions(perms);
      if (role == 'master') {
        Navigator.of(context)
            .pushReplacementNamed('/app_master', arguments: {'name': name});
      } else {
        Navigator.of(context).pushReplacementNamed('/community',
            arguments: {'role': role, 'name': name});
      }
    } catch (e) {
      setState(() {
        if (e is TimeoutException) {
          _error =
              '⏳ Connection timed out. Please check your WiFi or network connection and try again.';
        } else {
          _error = e.toString().contains('Server is down')
              ? '🔴 Server is down. Please try again later.'
              : e.toString().replaceFirst('Exception: ', '');
        }
        _loading = false;
      });
      await HapticService.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: const Color(0xFFF7F8FA),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: AnimatedBuilder(
              animation: _elevateAnimation,
              builder: (context, child) {
                final t = _elevateAnimation.value;

                return Stack(
                  children: [
                    // Image — position & height unchanged, only visual width reduced to 50%
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      top: screenHeight * (0.02 + 0.55 * t),
                      left: 0,
                      right: 0,
                      height: screenHeight * (0.32 - 0.08 * t),
                      child: Center(
                        child: SizedBox(
                          width: screenWidth * 0.60,
                          child: Image.asset(
                            'assets/icons/nexgen.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // Login card — completely unchanged
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      top: screenHeight * (0.36 - 0.20 * t),
                      left: 24,
                      right: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFE4E7EC)),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.brand(context).withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF172033),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Sign in to your account',
                              style: TextStyle(
                                fontFamily: 'Arial Narrow',
                                fontSize: 12,
                                color: Color(0xFF667085),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Username
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _usernameCtrl,
                                focusNode: _usernameFocus,
                                style: const TextStyle(
                                    fontFamily: 'Arial Narrow',
                                    fontSize: 14,
                                    color: Color(0xFF172033)),
                                decoration: InputDecoration(
                                  hintText: 'Username',
                                  hintStyle: TextStyle(
                                      fontFamily: 'Arial Narrow',
                                      fontSize: 13,
                                      color: Color(0xFF667085)),
                                  prefixIcon: Icon(Icons.person_outline,
                                      color: AppTheme.brand(context), size: 20),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 13),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Password
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _passwordCtrl,
                                focusNode: _passwordFocus,
                                obscureText: _obscure,
                                style: const TextStyle(
                                    fontFamily: 'Arial Narrow',
                                    fontSize: 14,
                                    color: Color(0xFF172033)),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: const TextStyle(
                                      fontFamily: 'Arial Narrow',
                                      fontSize: 13,
                                      color: Color(0xFF667085)),
                                  prefixIcon: Icon(Icons.lock_outline,
                                      color: AppTheme.brand(context), size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.grey[400],
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 13),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      title: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                            fontFamily: 'Arial Narrow',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18,
                                            color: Color(0xFF172033)),
                                      ),
                                      content: const Text(
                                        'Please contact your society admin or manager to reset your password.',
                                        style: TextStyle(
                                            fontFamily: 'Arial Narrow',
                                            fontSize: 13,
                                            color: Color(0xFF667085)),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text(
                                            'OK',
                                            style: TextStyle(
                                                fontFamily: 'Arial Narrow',
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.brand(context)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontFamily: 'Arial Narrow',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.brand(context),
                                  ),
                                ),
                              ),
                            ),

                            // Server IP (hidden — managed in background)
                            Offstage(
                              child: TextField(
                                controller: _serverIpCtrl,
                                keyboardType: TextInputType.url,
                              ),
                            ),

                            if (_error != null) ...[                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.red.shade400, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                            fontFamily: 'Arial Narrow',
                                            fontSize: 11,
                                            color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            // Sign In Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    color: AppTheme.brand(context),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: _loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5),
                                          )
                                        : const Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontFamily: 'Arial Narrow',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            const Center(
                              child: Text(
                                'Secure Login • Powered by GenNext',
                                style: TextStyle(
                                  fontFamily: 'Arial Narrow',
                                  fontSize: 10,
                                  color: Color(0xFF667085),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

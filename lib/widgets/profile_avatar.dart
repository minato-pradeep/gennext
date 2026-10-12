import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProfileAvatar extends StatefulWidget {
  final double size;
  final double borderRadius;

  const ProfileAvatar({super.key, this.size = 40, this.borderRadius = 12});

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return;
    try {
      final info = await ApiService().getUserInfo(userId);
      if (mounted && info != null && info['profile_image'] != null) {
        setState(() => _imageBase64 = info['profile_image']);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size, height: widget.size,
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient(context),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: _imageBase64 != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Image.memory(base64Decode(_imageBase64!), fit: BoxFit.cover))
          : const Icon(Icons.person, color: Colors.white, size: 20),
    );
  }
}

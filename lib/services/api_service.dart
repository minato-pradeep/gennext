import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static Future<String> get baseUrl => AppConstants.resolveBaseUrlAsync();

  Future<Map<String, dynamic>> login(String username, String password,
      {String? serverIp}) async {
    try {
      final baseUrl = serverIp != null && serverIp.trim().isNotEmpty
          ? await AppConstants.resolveBaseUrlAsync(serverIp: serverIp)
          : await ApiService.baseUrl;
      // Debug: print resolved baseUrl to help diagnose emulator/network issues
      // Remove this when the issue is resolved.
      // ignore: avoid_print
      print('DEBUG ApiService.baseUrl -> $baseUrl');
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', data['user']['id'].toString());
        await prefs.setString('user_role', data['user']['role']);
        await prefs.setString('user_name', data['user']['name']);
        return data['user'];
      } else {
        throw Exception(data['message'] ?? 'Invalid credentials');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final baseUrl = await ApiService.baseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/users/$userId'),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['user'];
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserInfo(
      String userId, Map<String, dynamic> updateData) async {
    try {
      final baseUrl = await ApiService.baseUrl;
      final response = await http
          .put(
            Uri.parse('$baseUrl/api/users/$userId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updateData),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to update user info');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
  }
}

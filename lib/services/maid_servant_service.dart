import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/maid_servant.dart';
import '../utils/constants.dart';

class MaidServantService {
  static final MaidServantService _instance = MaidServantService._internal();
  factory MaidServantService() => _instance;
  MaidServantService._internal();

  static String get _base => '${AppConstants.baseUrl}/api/maid-servants';

  final List<void Function()> _listeners = [];
  void addListener(void Function() l) => _listeners.add(l);
  void removeListener(void Function() l) => _listeners.remove(l);
  void _notify() {
    for (var l in _listeners) {
      l();
    }
  }

  /// Fetch all maid servants (optionally filter by isActive)
  Future<List<MaidServant>> getMaids({bool? activeOnly}) async {
    final uri = activeOnly != null
        ? Uri.parse('$_base?active=$activeOnly')
        : Uri.parse(_base);
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return (data['maids'] as List)
          .map((e) => MaidServant.fromJson(e))
          .toList();
    }
    throw Exception(data['message'] ?? 'Failed to load maid servants');
  }

  /// Add a new maid servant (image upload handled separately via imageUrl)
  Future<MaidServant> addMaid(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse(_base),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      _notify();
      return MaidServant.fromJson(data['maid']);
    }
    throw Exception(data['message'] ?? 'Failed to add maid servant');
  }

  /// Toggle active / inactive status
  Future<MaidServant> toggleStatus(int id, bool isActive) async {
    final res = await http.put(
      Uri.parse('$_base/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'is_active': isActive}),
    ).timeout(const Duration(seconds: 15));
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      _notify();
      return MaidServant.fromJson(data['maid']);
    }
    throw Exception(data['message'] ?? 'Failed to update status');
  }

  /// Delete a maid servant record
  Future<void> deleteMaid(int id) async {
    final res = await http.delete(
      Uri.parse('$_base/$id'),
    ).timeout(const Duration(seconds: 15));
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      _notify();
      return;
    }
    throw Exception(data['message'] ?? 'Failed to delete maid servant');
  }
}

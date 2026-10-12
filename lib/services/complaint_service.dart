import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/complaint.dart';
import '../utils/constants.dart';

class ComplaintService {
  static final ComplaintService _instance = ComplaintService._internal();
  factory ComplaintService() => _instance;
  ComplaintService._internal();

  static String get _base => '${AppConstants.baseUrl}/api/complaints';

  final List<void Function()> _listeners = [];
  void addListener(void Function() l) => _listeners.add(l);
  void removeListener(void Function() l) => _listeners.remove(l);
  void _notify() {
    for (var l in _listeners) {
      l();
    }
  }

  Future<Map<String, dynamic>> getComplaints(
      {int page = 1, String status = 'all'}) async {
    final uri = Uri.parse('$_base?page=$page&status=$status');
    final res = await http.get(uri);
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      final complaints = (data['complaints'] as List)
          .map((e) => Complaint.fromJson(e))
          .toList();
      return {
        'complaints': complaints,
        'total': data['total'],
        'page': data['page'],
        'totalPages': data['totalPages'],
      };
    }
    throw Exception(data['message'] ?? 'Failed to load complaints');
  }

  Future<Complaint> addComplaint(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse(_base),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      _notify();
      return Complaint.fromJson(data['complaint']);
    }
    throw Exception(data['message'] ?? 'Failed to submit complaint');
  }

  Future<Complaint> updateStatus(int id, String status,
      {String? remarks}) async {
    final res = await http.put(
      Uri.parse('$_base/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status, 'remarks': remarks}),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      _notify();
      return Complaint.fromJson(data['complaint']);
    }
    throw Exception(data['message'] ?? 'Failed to update status');
  }
}

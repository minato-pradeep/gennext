import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  static String get _base => '${AppConstants.baseUrl}/api/bills';
  static String get _customerBase =>
      '${AppConstants.baseUrl}/api/layout-customers';
  static String get _companyPaymentBase =>
      '${AppConstants.baseUrl}/api/company-payments';

  final List<void Function()> _listeners = [];
  void addListener(void Function() l) => _listeners.add(l);
  void removeListener(void Function() l) => _listeners.remove(l);
  void _notify() {
    for (var l in _listeners) {
      l();
    }
  }

  // Get customer payment records from layout_customers
  Future<List<Map<String, dynamic>>> getCompanyPayments(
      {String? plotId,
      String? plotName,
      String? companyId,
      String? companyName,
      String? paymentType}) async {
    final query = <String>[];
    if (plotId != null && plotId.isNotEmpty) {
      query.add('plot_id=${Uri.encodeQueryComponent(plotId)}');
    }
    if (plotName != null && plotName.isNotEmpty) {
      query.add('plot_name=${Uri.encodeQueryComponent(plotName)}');
    }
    if (companyId != null && companyId.isNotEmpty) {
      query.add('company_id=${Uri.encodeQueryComponent(companyId)}');
    }
    if (companyName != null && companyName.isNotEmpty) {
      query.add('company_name=${Uri.encodeQueryComponent(companyName)}');
    }
    if (paymentType != null && paymentType.isNotEmpty) {
      query.add('payment_type=${Uri.encodeQueryComponent(paymentType)}');
    }
    final uri = Uri.parse(
        '$_companyPaymentBase${query.isNotEmpty ? '?${query.join('&')}' : ''}');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['payments']);
    }
    throw Exception(data['message'] ?? 'Failed to load company payments');
  }

  Future<Map<String, dynamic>> payCompanyPayment(
      String paymentId, String paymentMethod,
      {String? transactionId}) async {
    final res = await http
        .put(
          Uri.parse('$_companyPaymentBase/$paymentId/pay'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'payment_method': paymentMethod,
            'transaction_id':
                transactionId ?? 'TXN${DateTime.now().millisecondsSinceEpoch}',
          }),
        )
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to mark payment paid');
    }
    _notify();
    return Map<String, dynamic>.from(data['payment']);
  }

  // Get bills for a specific user
  Future<List<Map<String, dynamic>>> getUserBills(String userId) async {
    final res = await http
        .get(Uri.parse('$_base?user_id=$userId'))
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['bills']);
    }
    throw Exception(data['message'] ?? 'Failed to load bills');
  }

  // Create bill and assign to users
  Future<void> createBill({
    required String title,
    required String description,
    required double amount,
    required String dueDate,
    required String billType,
    required String createdBy,
    required List<String> userIds,
  }) async {
    final res = await http
        .post(
          Uri.parse(_base),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': title,
            'description': description,
            'amount': amount,
            'bill_type': billType,
            'due_date': dueDate,
            'created_by': createdBy,
            'user_ids': userIds.map((id) => int.parse(id)).toList(),
          }),
        )
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to create bill');
    }
    _notify();
  }

  // Mark bill as paid
  Future<Map<String, dynamic>> payBill(
      String billId, String userId, String transactionId, String paymentMethod,
      {int months = 1}) async {
    final res = await http
        .put(
          Uri.parse('$_base/$billId/pay'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': int.parse(userId),
            'transaction_id': transactionId,
            'payment_method': paymentMethod,
            'months': months
          }),
        )
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to pay bill');
    }

    // Notify listeners about updated payments
    _notify();
    if (data.containsKey('invoice')) {
      return Map<String, dynamic>.from(data['invoice']);
    }
    // Some responses may include multiple invoices; return the first invoice for display
    if (data.containsKey('invoices') && (data['invoices'] as List).isNotEmpty) {
      return Map<String, dynamic>.from(data['invoices'][0]);
    }
    return {};
  }

  // Get all users payment data (admin)
  Future<List<Map<String, dynamic>>> getAllUsersPayments() async {
    final res = await http
        .get(Uri.parse('$_base/all-users'))
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to load payment data');
  }

  // Get all users from DB
  Future<List<Map<String, dynamic>>> getOwnerUsers() async {
    final res = await http
        .get(Uri.parse('${AppConstants.baseUrl}/api/users'))
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      final users = List<Map<String, dynamic>>.from(data['users']);
      return users
          .where((u) => u['role'] == 'owner' && u['is_active'] == true)
          .toList();
    }
    return [];
  }

  // Get invoice for a given bill and user
  Future<Map<String, dynamic>> getInvoiceForBill(
      String billId, String userId) async {
    final uri = Uri.parse(
        '${AppConstants.baseUrl}/api/invoices/by-bill/$billId/$userId');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      final snippet =
          res.body.length > 200 ? res.body.substring(0, 200) : res.body;
      throw Exception('HTTP ${res.statusCode}: $snippet');
    }

    final contentType = res.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      final snippet =
          res.body.length > 200 ? res.body.substring(0, 200) : res.body;
      throw Exception(
          'Expected JSON but got ${contentType.isNotEmpty ? contentType : 'unknown content type'}: $snippet');
    }

    try {
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return Map<String, dynamic>.from(data['invoice']);
      }
      throw Exception(data['message'] ?? 'Invoice not found');
    } catch (e) {
      final snippet =
          res.body.length > 200 ? res.body.substring(0, 200) : res.body;
      throw Exception(
          'Invalid JSON response: ${e.toString()} — body: $snippet');
    }
  }
}

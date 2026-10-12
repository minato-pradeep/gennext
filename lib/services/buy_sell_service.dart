import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/buy_sell_item.dart';
import '../utils/constants.dart';

class BuySellService {
  static final BuySellService _instance = BuySellService._internal();
  factory BuySellService() => _instance;
  BuySellService._internal();

  static String get _base => '${AppConstants.baseUrl}/api/buy-sell';

  final List<void Function()> _listeners = [];

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);
  void _notifyListeners() {
    for (var l in _listeners) {
      l();
    }
  }

  Future<List<BuySellItem>> getAllItems({String category = 'All'}) async {
    final uri = category == 'All'
        ? Uri.parse(_base)
        : Uri.parse('$_base?category=${Uri.encodeComponent(category)}');
    final res = await http.get(uri);
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return (data['items'] as List)
          .map((e) => BuySellItem.fromJson(e))
          .toList();
    }
    throw Exception(data['message'] ?? 'Failed to load items');
  }

  Future<List<BuySellItem>> getMyItems(String sellerId) async {
    final res = await http.get(Uri.parse('$_base/my-items/$sellerId'));
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return (data['items'] as List)
          .map((e) => BuySellItem.fromJson(e))
          .toList();
    }
    throw Exception(data['message'] ?? 'Failed to load items');
  }

  Future<BuySellItem> addItem(BuySellItem item) async {
    final res = await http.post(
      Uri.parse(_base),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    ).timeout(const Duration(seconds: 60));
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      _notifyListeners();
      return BuySellItem.fromJson(data['item']);
    }
    throw Exception(data['message'] ?? 'Failed to post item');
  }

  Future<void> updateItem(String id, Map<String, dynamic> fields) async {
    final res = await http.put(
      Uri.parse('$_base/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(fields),
    );
    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update');
    }
    _notifyListeners();
  }

  Future<void> markAsSold(String id) async {
    final res = await http.patch(Uri.parse('$_base/$id/sold'));
    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to mark as sold');
    }
    _notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    final res = await http.delete(Uri.parse('$_base/$id'));
    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete');
    }
    _notifyListeners();
  }
}

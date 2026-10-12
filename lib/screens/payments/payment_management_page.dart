import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';

class PaymentManagementPage extends StatefulWidget {
  final String userRole;
  final String userName;
  const PaymentManagementPage({super.key, required this.userRole, required this.userName});

  @override
  State<PaymentManagementPage> createState() => _PaymentManagementPageState();
}

class _PaymentManagementPageState extends State<PaymentManagementPage> {
  List<Map<String, dynamic>> _rawData = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
    PaymentService().addListener(_load);
  }

  @override
  void dispose() {
    PaymentService().removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await PaymentService().getAllUsersPayments();
      if (mounted) setState(() { _rawData = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Group by user
  Map<String, Map<String, dynamic>> get _byUser {
    final Map<String, Map<String, dynamic>> result = {};
    for (final row in _rawData) {
      final uid = row['user_id'].toString();
      if (!result.containsKey(uid)) {
        result[uid] = {
          'name': row['name'], 'apartment': row['apartment'], 'phone': row['phone'],
          'bills': [], 'total': 0.0, 'paid': 0.0, 'pending': 0.0,
        };
      }
      final amount = double.parse(row['amount'].toString());
      final isPaid = row['pay_status'] == 'paid';
      result[uid]!['bills'].add(row);
      result[uid]!['total'] = (result[uid]!['total'] as double) + amount;
      if (isPaid) {
        result[uid]!['paid'] = (result[uid]!['paid'] as double) + amount;
      } else {
        result[uid]!['pending'] = (result[uid]!['pending'] as double) + amount;
      }
    }
    return result;
  }

  List<Map<String, dynamic>> get _filtered {
    final users = _byUser.values.toList();
    if (_filter == 'paid') return users.where((u) => (u['pending'] as double) == 0).toList();
    if (_filter == 'unpaid') return users.where((u) => (u['pending'] as double) > 0).toList();
    return users;
  }

  double get _totalCollected => _byUser.values.fold(0.0, (s, u) => s + (u['paid'] as double));
  double get _totalPending => _byUser.values.fold(0.0, (s, u) => s + (u['pending'] as double));

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text('Payment Management', style: AppTheme.titleLarge.copyWith(color: Colors.white)),
        backgroundColor: AppTheme.accentPurple, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(children: [
                // Summary
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)]), borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Expanded(child: Column(children: [
                        const Text('Members', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 11, color: Colors.white70)),
                        Text('${_byUser.length}', style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                      ])),
                      Container(width: 1, height: 35, color: Colors.white24),
                      Expanded(child: Column(children: [
                        const Text('Collected', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 11, color: Colors.white70)),
                        Text('₹${_totalCollected.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.greenAccent)),
                      ])),
                      Container(width: 1, height: 35, color: Colors.white24),
                      Expanded(child: Column(children: [
                        const Text('Pending', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 11, color: Colors.white70)),
                        Text('₹${_totalPending.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.orange)),
                      ])),
                    ]),
                  ),
                ),

                // Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: ['all', 'paid', 'unpaid'].map((f) => Expanded(child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      margin: EdgeInsets.only(right: f != 'unpaid' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _filter == f ? AppTheme.accentPurple : (isDark ? AppTheme.darkCard : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _filter == f ? Colors.transparent : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                      ),
                      child: Center(child: Text(f[0].toUpperCase() + f.substring(1), style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 13, fontWeight: FontWeight.w600, color: _filter == f ? Colors.white : (isDark ? Colors.white70 : Colors.black54)))),
                    ),
                  ))).toList()),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Text('No data found', style: TextStyle(fontFamily: 'Arial Narrow', color: isDark ? Colors.white54 : Colors.black45)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _userCard(filtered[i], isDark),
                        ),
                ),
              ]),
            ),
    );
  }

  Widget _userCard(Map<String, dynamic> user, bool isDark) {
    final isPaid = (user['pending'] as double) == 0;
    final bills = user['bills'] as List;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPaid ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: isPaid ? Colors.green : Colors.red, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(user['name'] ?? '', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: (isPaid ? Colors.green : Colors.red).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(isPaid ? 'PAID' : 'PENDING', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 11, fontWeight: FontWeight.w700, color: isPaid ? Colors.green : Colors.red)),
          ),
        ]),
        const SizedBox(height: 8),
        Text('${user['apartment']} • ${user['phone']}', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
        const SizedBox(height: 10),
        Row(children: [
          _chip('Total: ₹${(user['total'] as double).toStringAsFixed(0)}', AppTheme.accentPurple),
          const SizedBox(width: 8),
          _chip('Paid: ₹${(user['paid'] as double).toStringAsFixed(0)}', Colors.green),
          const SizedBox(width: 8),
          _chip('Due: ₹${(user['pending'] as double).toStringAsFixed(0)}', Colors.orange),
        ]),
        if (!isPaid) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (user['total'] as double) > 0 ? (user['paid'] as double) / (user['total'] as double) : 0,
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              color: Colors.green, minHeight: 4,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text('${bills.length} bill(s)', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
      ]),
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
    child: Text(text, style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}

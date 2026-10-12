import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/payment_service.dart';
import '../../models/payment.dart';
import '../../theme/app_theme.dart';

class PaymentHistoryPage extends StatefulWidget {
  final String userId;
  final String userName;
  final bool isAdmin;

  const PaymentHistoryPage({
    super.key,
    required this.userId,
    required this.userName,
    this.isAdmin = false,
  });

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  late PaymentService _paymentService;
  List<Payment> _payments = [];
  String _filter = 'all'; // 'all', 'paid', 'pending'

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _loadData();
    _paymentService.addListener(_onPaymentUpdate);
  }

  @override
  void dispose() {
    _paymentService.removeListener(_onPaymentUpdate);
    super.dispose();
  }

  void _onPaymentUpdate() {
    if (mounted) {
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      if (widget.isAdmin) {
        _payments = _paymentService.getPayments();
      } else {
        _payments = _paymentService.getUserPayments(widget.userId);
      }
    });
  }

  List<Payment> get _filteredPayments {
    if (_filter == 'paid') {
      return _payments.where((p) => p.status == 'paid').toList();
    } else if (_filter == 'pending') {
      return _payments.where((p) => p.status == 'pending' || p.status == 'overdue').toList();
    }
    return _payments;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final filteredPayments = _filteredPayments;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.isAdmin ? 'All Payments' : 'Payment History',
          style: const TextStyle(fontFamily: 'Arial Narrow', 
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.brandLight(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 45,
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                _filterChip('All', 'all', isDark),
                const SizedBox(width: 12),
                _filterChip('Paid', 'paid', isDark),
                const SizedBox(width: 12),
                _filterChip('Pending', 'pending', isDark),
              ],
            ),
          ),
          
          // Stats Summary
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Total Paid',
                        style: TextStyle(fontFamily: 'Arial Narrow', 
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      Text(
                        '₹${_payments.where((p) => p.status == 'paid').fold(0.0, (s, p) => s + p.amount).toStringAsFixed(0)}',
                        style: const TextStyle(fontFamily: 'Arial Narrow', 
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Total Pending',
                        style: TextStyle(fontFamily: 'Arial Narrow', 
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      Text(
                        '₹${_payments.where((p) => p.status != 'paid').fold(0.0, (s, p) => s + p.amount).toStringAsFixed(0)}',
                        style: const TextStyle(fontFamily: 'Arial Narrow', 
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Payment List
          Expanded(
            child: filteredPayments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No payment records found',
                          style: TextStyle(fontFamily: 'Arial Narrow', 
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredPayments.length,
                    itemBuilder: (context, index) {
                      final payment = filteredPayments[index];
                      return _buildHistoryCard(payment, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String filterValue, bool isDark) {
    final isSelected = _filter == filterValue;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filter = filterValue;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.brandLight(context)
                : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Arial Narrow', 
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Payment payment, bool isDark) {
    final isPaid = payment.status == 'paid';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (isPaid ? const Color(0xFF4CAF50) : const Color(0xFFFF9800)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              payment.getBillTypeIcon(),
              color: isPaid ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.getBillTypeDisplay(),
                  style: TextStyle(fontFamily: 'Arial Narrow', 
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF212121),
                  ),
                ),
                if (widget.isAdmin)
                  Text(
                    '${payment.userName} • ${payment.apartment}',
                    style: TextStyle(fontFamily: 'Arial Narrow', 
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                Text(
                  isPaid ? 'Paid on ${payment.paidDate?.substring(0, 10)}' : 'Due: ${payment.dueDate}',
                  style: TextStyle(fontFamily: 'Arial Narrow', 
                    fontSize: 10,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                if (payment.transactionId != null)
                  Text(
                    'Txn: ${payment.transactionId}',
                    style: TextStyle(fontFamily: 'Arial Narrow', 
                      fontSize: 9,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${payment.amount.toStringAsFixed(0)}',
                style: TextStyle(fontFamily: 'Arial Narrow', 
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isPaid ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: payment.getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  payment.status == 'paid' ? 'Paid' : (payment.status == 'overdue' ? 'Overdue' : 'Pending'),
                  style: TextStyle(fontFamily: 'Arial Narrow', 
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: payment.getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
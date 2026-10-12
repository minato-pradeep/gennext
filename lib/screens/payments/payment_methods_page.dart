import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/payment_service.dart';
import '../../models/payment.dart';
import 'invoice_page.dart';
import '../../theme/app_theme.dart';

class PaymentMethodsPage extends StatefulWidget {
  final String userId;
  final Bill bill;
  final String userName;

  const PaymentMethodsPage({
    super.key,
    required this.userId,
    required this.bill,
    required this.userName,
  });

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  bool _isProcessing = false;
  String? _selectedMethod;

  final List<PaymentMethodItem> _paymentMethods = [
    PaymentMethodItem(
      id: 'gpay',
      name: 'Google Pay',
      icon: Icons.abc,
      color: const Color(0xFF4285F4),
      upiId: 'bluebug@okhdfcbank',
    ),
    PaymentMethodItem(
      id: 'phonepe',
      name: 'PhonePe',
      icon: Icons.phone_android,
      color: const Color(0xFF5F259F),
      upiId: 'bluebug@ybl',
    ),
    PaymentMethodItem(
      id: 'paytm',
      name: 'Paytm',
      icon: Icons.currency_rupee,
      color: const Color(0xFF00BAF2),
      upiId: 'bluebug@paytm',
    ),
    PaymentMethodItem(
      id: 'card',
      name: 'Credit/Debit Card',
      icon: Icons.credit_card,
      color: AppTheme.brandLight(context),
      upiId: null,
    ),
    PaymentMethodItem(
      id: 'upi',
      name: 'Other UPI',
      icon: Icons.qr_code_scanner,
      color: const Color(0xFF43A047),
      upiId: null,
    ),
  ];

  void _processPayment(String methodId) async {
    setState(() {
      _selectedMethod = methodId;
      _isProcessing = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';

    _processPaymentAPI(methodId, transactionId);
  }

  void _processPaymentAPI(String methodId, String transactionId) {
    // Update payment status and fetch invoice info
    PaymentService()
        .payBill(
            widget.bill.id.toString(), widget.userId, transactionId, methodId)
        .then((invoice) async {
      setState(() {
        _isProcessing = false;
      });
      // Navigate to invoice page if invoice returned
      if (invoice.isNotEmpty) {
        if (mounted) {
          Navigator.pop(context); // Close payment page
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => InvoicePage(invoice: invoice)));
        }
      } else {
        _showSuccessDialog(transactionId);
      }
    }).catchError((e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    });
  }

  void _showSuccessDialog(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 60),
            SizedBox(height: 10),
            Text(
              'Payment Successful!',
              style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF212121),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your payment of ₹${widget.bill.amount.toStringAsFixed(0)} has been processed successfully.',
              style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    'Transaction ID',
                    style: TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 11,
                        color: Colors.black45),
                  ),
                  Text(
                    transactionId,
                    style: const TextStyle(
                      fontFamily: 'Arial Narrow',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close payment page
              Navigator.pop(context); // Go back to bill details
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandLight(context),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Pay with',
          style: TextStyle(
            fontFamily: 'Arial Narrow',
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
          // Bill Details Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.brandLight(context), AppTheme.brand(context)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.bill.getIcon(),
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.bill.title,
                        style: const TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Bill for ${widget.userName}',
                        style: const TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${widget.bill.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontFamily: 'Arial Narrow',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Payment Methods
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final method = _paymentMethods[index];
                return _buildPaymentMethodCard(method, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethodItem method, bool isDark) {
    final isSelected = _selectedMethod == method.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: InkWell(
          onTap: _isProcessing ? null : () => _processPayment(method.id),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: method.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(method.icon, color: method.color, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.name,
                        style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF212121),
                        ),
                      ),
                      if (method.upiId != null)
                        Text(
                          method.upiId!,
                          style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isProcessing && isSelected)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.brandLight(context),
                    ),
                  )
                else
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.brandLight(context), AppTheme.brand(context)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentMethodItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String? upiId;

  PaymentMethodItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.upiId,
  });
}

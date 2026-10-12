import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';

class MemberPaymentStatusPage extends StatefulWidget {
  const MemberPaymentStatusPage({super.key});

  @override
  State<MemberPaymentStatusPage> createState() => _MemberPaymentStatusPageState();
}

class _MemberPaymentStatusPageState extends State<MemberPaymentStatusPage> {
  late PaymentService _paymentService;
  List<PaymentStatusSummary> _members = [];
  String _searchQuery = '';
  String _filter = 'all'; // 'all', 'paid', 'unpaid'

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    if (_paymentService.getPayments().isEmpty) {
      _paymentService.initMockData();
    }
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
      _members = _paymentService.getAllMembersPaymentStatus();
    });
  }

  List<PaymentStatusSummary> get _filteredMembers {
    var members = _members;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      members = members.where((m) =>
        m.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        m.apartment.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Apply payment status filter
    if (_filter == 'paid') {
      members = members.where((m) => m.isFullyPaid).toList();
    } else if (_filter == 'unpaid') {
      members = members.where((m) => !m.isFullyPaid).toList();
    }
    
    return members;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final filteredMembers = _filteredMembers;
    
    final paidCount = _members.where((m) => m.isFullyPaid).length;
    final unpaidCount = _members.where((m) => !m.isFullyPaid).length;
    final totalAmount = _members.fold(0.0, (sum, m) => sum + m.totalAmount);
    final pendingAmount = _members.fold(0.0, (sum, m) => sum + m.pendingAmount);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Member Payment Status',
          style: TextStyle(fontFamily: 'Arial Narrow', 
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
          // Stats Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _statCard('Total Members', _members.length.toString(), Icons.people, AppTheme.brandLight(context), isDark),
                const SizedBox(width: 12),
                _statCard('Fully Paid', paidCount.toString(), Icons.check_circle, const Color(0xFF4CAF50), isDark),
                const SizedBox(width: 12),
                _statCard('Pending', unpaidCount.toString(), Icons.pending, const Color(0xFFFF9800), isDark),
              ],
            ),
          ),
          
          // Amount Summary
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
                        'Total Amount',
                        style: TextStyle(fontFamily: 'Arial Narrow', 
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      Text(
                        '₹${totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(fontFamily: 'Arial Narrow', 
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.brandLight(context),
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
                        'Collected',
                        style: TextStyle(fontFamily: 'Arial Narrow', 
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      Text(
                        '₹${(totalAmount - pendingAmount).toStringAsFixed(0)}',
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
                        'Pending',
                        style: TextStyle(fontFamily: 'Arial Narrow', 
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      Text(
                        '₹${pendingAmount.toStringAsFixed(0)}',
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
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 14, color: isDark ? Colors.white : const Color(0xFF212121)),
              decoration: InputDecoration(
                hintText: 'Search by name or apartment...',
                hintStyle: TextStyle(fontFamily: 'Arial Narrow', color: isDark ? Colors.white54 : Colors.black45),
                prefixIcon: Icon(Icons.search, color: AppTheme.brandLight(context)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.brandLight(context), width: 2),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filter Chips
          Container(
            height: 45,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip('All', 'all', isDark),
                const SizedBox(width: 12),
                _filterChip('Paid', 'paid', isDark),
                const SizedBox(width: 12),
                _filterChip('Unpaid', 'unpaid', isDark),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Members List
          Expanded(
            child: filteredMembers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No members found',
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
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = filteredMembers[index];
                      return _buildMemberCard(member, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontFamily: 'Arial Narrow', 
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF212121),
              ),
            ),
            Text(
              title,
              style: TextStyle(fontFamily: 'Arial Narrow', 
                fontSize: 9,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
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

  Widget _buildMemberCard(PaymentStatusSummary member, bool isDark) {
    final isPaid = member.isFullyPaid;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid 
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : const Color(0xFFE53935).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: isPaid 
                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                  : const Color(0xFFE53935).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isPaid ? Icons.check_circle : Icons.pending,
              color: isPaid ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.userName,
                  style: TextStyle(fontFamily: 'Arial Narrow', 
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF212121),
                  ),
                ),
                Text(
                  member.apartment,
                  style: TextStyle(fontFamily: 'Arial Narrow', 
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Total: ₹${member.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(fontFamily: 'Arial Narrow', 
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.brandLight(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Paid: ₹${member.paidAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontFamily: 'Arial Narrow', 
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPaid 
                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                  : const Color(0xFFE53935).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPaid ? 'PAID' : 'UNPAID',
              style: TextStyle(fontFamily: 'Arial Narrow', 
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isPaid ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
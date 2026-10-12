const fs = require('fs');
let c = fs.readFileSync('../lib/screens/community_dashboard.dart', 'utf8');

// Add imports
c = c.replace(
  "import '../services/api_service.dart';",
  "import 'dart:convert';\nimport 'package:http/http.dart' as http;\nimport 'package:shared_preferences/shared_preferences.dart';\nimport '../services/api_service.dart';"
);

// Add _bills and _loadingBills state variables
c = c.replace(
  '  bool _loadingEvent = false;',
  `  bool _loadingEvent = false;
  List<Map<String, dynamic>> _pendingBills = [];
  bool _loadingBills = false;
  String _userId = '';`
);

// Add _loadBills call in initState
c = c.replace(
  '    _loadEvents();\n    EventService().addListener(_loadEvents);',
  `    _loadEvents();
    _loadBills();
    EventService().addListener(_loadEvents);`
);

// Add _loadBills method after _loadEvents
c = c.replace(
  '  Future<void> _logout()',
  `  Future<void> _loadBills() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? '';
    if (_userId.isEmpty) return;
    setState(() => _loadingBills = true);
    try {
      final res = await http.get(Uri.parse('${ApiService.baseUrl}/api/bills?user_id=$_userId')).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        final all = List<Map<String, dynamic>>.from(data['bills']);
        setState(() {
          _pendingBills = all.where((b) => b['pay_status'] != 'paid').toList();
          _loadingBills = false;
        });
      } else {
        if (mounted) setState(() => _loadingBills = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBills = false);
    }
  }

  Future<void> _logout()`
);

// Replace dummy bills section with real data
const oldBills = `              // â"€â"€ PENDING BILLS â"€â"€
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pending Bills', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                                  Text('Total: â‚¹2,090', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ..._bills.map((bill) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(bill['icon'] as IconData, color: bill['color'] as Color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(bill['name']!, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                                    Text(bill['due']!, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60)),
                                  ],
                                ),
                              ),
                              Text(bill['amount']!, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => Navigator.push(context, PageAnimations.slideRight(
                                  ExplorePage(userRole: widget.userRole, userName: widget.userName))),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('Pay Now', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0D47A1))),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ),`;

const newBills = `              // ── PENDING BILLS (from DB) ──
              if (_loadingBills)
                const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Center(child: CircularProgressIndicator()))
              else if (_pendingBills.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.3))),
                            child: const Icon(Icons.receipt_long, color: Colors.white, size: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Pending Bills', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text('\${_pendingBills.length} bill(s) pending', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                          ])),
                        ]),
                        const SizedBox(height: 18),
                        ..._pendingBills.take(3).map((bill) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(children: [
                            Container(width: 36, height: 36,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.receipt, color: Colors.orange, size: 18)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(bill['title'] ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('Due: \${bill['due_date']?.toString().substring(0, 10) ?? ''}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60)),
                            ])),
                            Text('₹\${bill['amount']}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => Navigator.push(context, PageAnimations.slideRight(ExplorePage(userRole: widget.userRole, userName: widget.userName))),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                child: Text('Pay Now', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0D47A1))),
                              ),
                            ),
                          ]),
                        )),
                      ]),
                    ),
                  ),
                ),`;

c = c.replace(oldBills, newBills);

// Remove the dummy _bills list
c = c.replace(
  `  // Pending bills mock
  final List<Map<String, dynamic>> _bills = [
    {'name': 'Electricity', 'amount': 'â‚¹1,240', 'due': 'Due: 5 Jan', 'icon': Icons.bolt, 'color': const Color(0xFFFFB300)},
    {'name': 'Maintenance', 'amount': 'â‚¹850', 'due': 'Due: 10 Jan', 'icon': Icons.build, 'color': const Color(0xFF42A5F5)},
  ];`, ''
);

fs.writeFileSync('../lib/screens/community_dashboard.dart', c, 'utf8');
console.log('done');

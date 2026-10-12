const fs = require('fs');
let c = fs.readFileSync('../lib/screens/community_dashboard.dart', 'utf8');
const lines = c.split('\n');

// Remove lines 440-517 (0-indexed: 439-516) - the old pending bills container
// Find the start: line with "// â"€â"€ PENDING BILLS â"€â"€" or the container start
let startLine = -1, endLine = -1;
for (let i = 0; i < lines.length; i++) {
  if (lines[i].includes('PENDING BILLS') && startLine === -1) startLine = i - 1; // include the SizedBox before
  if (startLine > -1 && lines[i].trim() === '),' && i > startLine + 10) {
    // Check if next non-empty line is SizedBox(height: 16)
    let j = i + 1;
    while (j < lines.length && lines[j].trim() === '') j++;
    if (lines[j] && lines[j].includes('SizedBox(height: 16)')) {
      endLine = i;
      break;
    }
  }
}

console.log('startLine:', startLine, 'endLine:', endLine);
if (startLine > -1 && endLine > -1) {
  const newSection = `              // ── PENDING BILLS (from DB) ──
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
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
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
                              Text(bill['title']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
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
  const newLines = [...lines.slice(0, startLine), newSection, ...lines.slice(endLine + 1)];
  fs.writeFileSync('../lib/screens/community_dashboard.dart', newLines.join('\n'), 'utf8');
  console.log('replaced successfully');
} else {
  console.log('section not found');
}

const fs = require('fs');
const path = require('path');

const files = [
  '../lib/screens/all_complaints_page.dart',
  '../lib/screens/check_complaint_page.dart',
  '../lib/screens/events_list_page.dart',
  '../lib/screens/polls_page.dart',
  '../lib/screens/buy_items_page.dart',
  '../lib/screens/visitor_approval_page.dart',
  '../lib/screens/emergency_numbers_page.dart',
  '../lib/screens/notices/notice_board_page.dart',
  '../lib/screens/notices/create_notice_page.dart',
  '../lib/screens/payments/payment_dashboard.dart',
  '../lib/screens/payments/payment_management_page.dart',
];

const friendlyError = `'🔴 Server is down. Please try again later.'`;

files.forEach(f => {
  try {
    let c = fs.readFileSync(f, 'utf8');
    // Replace catch blocks that set error with technical messages
    c = c.replace(/catch \(_\) \{\s*if \(mounted\) setState\(\(\) => _loading = false\);\s*\}/g, 
      `catch (_) {\n      if (mounted) setState(() { _loading = false; _error = 'Server is down. Please try again later.'; });\n    }`);
    fs.writeFileSync(f, c, 'utf8');
    console.log('updated:', path.basename(f));
  } catch(e) {
    console.log('skip:', path.basename(f), e.message);
  }
});
console.log('done');

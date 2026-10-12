const fs = require('fs');

const files = [
  '../lib/screens/notices/notice_board_page.dart',
  '../lib/screens/visitor_approval_page.dart',
  '../lib/screens/polls_page.dart',
  '../lib/screens/events_list_page.dart',
  '../lib/screens/payments/payment_dashboard.dart',
  '../lib/screens/payments/payment_management_page.dart',
  '../lib/screens/notices/create_notice_page.dart',
  '../lib/screens/buy_items_page.dart',
  '../lib/screens/emergency_numbers_page.dart',
];

files.forEach(f => {
  let c = fs.readFileSync(f, 'utf8');
  c = c.replace(
    /if \(mounted\) setState\(\(\) \{ _loading = false; _error = 'Server is down\. Please try again later\.'; \}\);/g,
    `if (mounted) setState(() => _loading = false);`
  );
  fs.writeFileSync(f, c, 'utf8');
  console.log('fixed:', f.split('/').pop());
});

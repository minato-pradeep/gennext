const fs = require('fs');

// Fix all_complaints_page
let c = fs.readFileSync('../lib/screens/all_complaints_page.dart', 'utf8');
c = c.replace(
  "import '../widgets/server_down_widget.dart';",
  "import '../services/complaint_service.dart';\nimport '../widgets/server_down_widget.dart';"
);
fs.writeFileSync('../lib/screens/all_complaints_page.dart', c, 'utf8');

// Fix check_complaint_page
let c2 = fs.readFileSync('../lib/screens/check_complaint_page.dart', 'utf8');
if (!c2.includes('server_down_widget')) {
  c2 = c2.replace(
    "import '../services/complaint_service.dart';",
    "import '../services/complaint_service.dart';\nimport '../widgets/server_down_widget.dart';"
  );
  fs.writeFileSync('../lib/screens/check_complaint_page.dart', c2, 'utf8');
}

console.log('done');

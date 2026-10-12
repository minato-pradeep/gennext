const fs = require('fs');
let c = fs.readFileSync('../lib/screens/explore_page.dart', 'utf8');
c = c.replace(
  "import 'package:flutter/material.dart';",
  `import 'package:flutter/material.dart';
import 'package:flutter/services.dart';`
);
c = c.replace(
  "import 'sos_setup_screen.dart';",
  `import 'sos_setup_screen.dart';
import 'sos_active_screen.dart';
import 'buy_items_page.dart';`
);
c = c.replace(
  "import 'emergency_numbers_page.dart';",
  `import 'emergency_numbers_page.dart';
import '../widgets/animated_button.dart';
import '../widgets/glass_card.dart';`
);
fs.writeFileSync('../lib/screens/explore_page.dart', c, 'utf8');
console.log('done');

const fs = require('fs');
let c = fs.readFileSync('../lib/screens/explore_page.dart', 'utf8');

c = c.replace(
  '    return allOptions;\n  }',
  `    allOptions.add(ExploreOption(
      id: 99, title: 'App Master', icon: Icons.admin_panel_settings,
      imagePath: 'assets/icons/nextgen_icon.png', iconColor: const Color(0xFF9C27B0),
      gradientColors: [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)],
      description: 'Manage users and permissions'));
    return allOptions;
  }`
);

fs.writeFileSync('../lib/screens/explore_page.dart', c, 'utf8');
console.log('done');

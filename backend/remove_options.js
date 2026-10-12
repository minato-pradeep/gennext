const fs = require('fs');
let c = fs.readFileSync('../lib/screens/explore_page.dart', 'utf8');

// Remove Facilities option block (id: 6)
c = c.replace(/\s*if \(permissionService\.hasPermission\('facilities'\)\) \{[\s\S]*?id: 6[\s\S]*?\}\);[\s\n]*\}/m, '');

// Remove Documents option block (id: 11)
c = c.replace(/\s*if \(permissionService\.hasPermission\('documents'\)\) \{[\s\S]*?id: 11[\s\S]*?\}\);[\s\n]*\}/m, '');

// Remove Facilities action builder
c = c.replace(/\s*if \(option\.id == 6\).*?isFullWidth: true\),/g, '');

fs.writeFileSync('../lib/screens/explore_page.dart', c, 'utf8');
console.log('done');

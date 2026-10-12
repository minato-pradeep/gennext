const fs = require('fs');
let c = fs.readFileSync('../lib/screens/community_dashboard.dart', 'utf8');
const lines = c.split('\n');
// Remove lines 230-277 (0-indexed: 229-276)
const newLines = [...lines.slice(0, 229), ...lines.slice(277)];
fs.writeFileSync('../lib/screens/community_dashboard.dart', newLines.join('\n'), 'utf8');
console.log('done, removed lines 230-277');

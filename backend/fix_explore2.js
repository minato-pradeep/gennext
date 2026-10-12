const fs = require('fs');
let c = fs.readFileSync('../lib/screens/explore_page.dart', 'utf8');
const lines = c.split('\n');
const newLines = [];
let skip = false;
let braceCount = 0;

for (let i = 0; i < lines.length; i++) {
  const line = lines[i];
  
  // Detect start of facilities or documents block
  if (!skip && (
    (line.includes("hasPermission('facilities')") || line.includes("hasPermission('documents')"))
  )) {
    skip = true;
    braceCount = 0;
  }
  
  if (skip) {
    // Count braces to find end of block
    for (const ch of line) {
      if (ch === '{') braceCount++;
      if (ch === '}') braceCount--;
    }
    // End of block when braces balance and we hit closing }
    if (braceCount <= 0 && line.trim() === '}') {
      skip = false;
    }
    continue; // skip this line
  }
  
  newLines.push(line);
}

// Also fix the broken else block from events
let result = newLines.join('\n');

// Fix the broken else that got left from facilities removal
result = result.replace(
  `    } else {\n                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid credentials'), backgroundColor: Colors.red));\n                  }\n                },\n                child: const Text('Login', style: TextStyle(color: Colors.white)),\n              ),\n            ],\n\n          ),\n        );\n      },\n      icon: const Icon(Icons.admin_panel_settings, color: Colors.white),\n      label: Text('Open App Master', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),\n      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C27B0), minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),\n    );\n  }`,
  `    }`
);

fs.writeFileSync('../lib/screens/explore_page.dart', result, 'utf8');
console.log('done, lines:', newLines.length);

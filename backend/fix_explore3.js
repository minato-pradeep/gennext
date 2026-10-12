const fs = require('fs');
let c = fs.readFileSync('../lib/screens/explore_page.dart', 'utf8');
const lines = c.split('\n');

// Add import 'dart:async'; if not present
if (!c.includes("import 'dart:ui';")) {
  c = c.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'dart:ui';\nimport 'dart:async';\nimport 'package:flutter/services.dart';");
}

// Find and fix: replace lines 122-136 (0-indexed: 121-135)
// Line 122 has "} else {" which is wrong - should just be "}"
// Lines 123-136 are the _appMasterLoginBtn code that got injected

const brokenSection = lines.slice(121, 136).join('\n');
console.log('broken section:', brokenSection.substring(0, 100));

// Replace the broken else block with just closing brace
// and restore _appMasterLoginBtn after _exploreOptions closes
const fixed = lines.slice(0, 121).join('\n') + '\n    }\n' + lines.slice(136).join('\n');

// Now find where _exploreOptions ends (return allOptions;) and add _appMasterLoginBtn after
const appMasterBtn = `
  Widget _appMasterLoginBtn(BuildContext context) {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('App Master Login', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.w700)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: userCtrl, decoration: InputDecoration(labelText: 'Username', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 12),
              TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C27B0)),
                onPressed: () async {
                  final username = userCtrl.text.trim().toLowerCase();
                  final password = passCtrl.text.trim();

                  // Local Hardcoded Defaults (Bypass API)
                  if ((username == 'macs' && password == 'macs') || (username == 'master' && password == 'master')) {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/app_master', arguments: {'name': username == 'macs' ? 'Macs Admin' : 'Master User'});
                    return;
                  }

                  try {
                    final res = await http.post(
                      Uri.parse('\${ApiService.baseUrl}/api/auth/login'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({'username': username, 'password': password}),
                    ).timeout(const Duration(seconds: 30)); // Increased timeout to 30 seconds
                    final data = jsonDecode(res.body);
                    if (data['success'] == true && data['user'] != null && data['user']['role'] == 'master') {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/app_master', arguments: {'name': data['user']['name']});
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Invalid master credentials'), backgroundColor: Colors.red));
                    }
                  } catch (e) {
                    if (e is TimeoutException) { // Specific handling for TimeoutException
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login timed out. Please check your network and try again.'), backgroundColor: Colors.red));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔴 Server is down or an unexpected error occurred. Please try again later.'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text('Login', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
      label: Text('Open App Master', style: TextStyle(fontFamily: 'Segoe UI', color: Colors.white, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C27B0), minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
`;

// Insert _appMasterLoginBtn before @override Widget build
const result = fixed.replace('  @override\n  Widget build(BuildContext context) {', appMasterBtn + '\n  @override\n  Widget build(BuildContext context) {');

fs.writeFileSync('../lib/screens/explore_page.dart', result, 'utf8');
console.log('done');

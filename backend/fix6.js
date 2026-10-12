const fs = require('fs');
let c = fs.readFileSync('../lib/screens/explore_page.dart', 'utf8');

// Replace the hardcoded master/master check with API call
const oldCheck = `                  onPressed: () async {
                  if (userCtrl.text == 'master' && passCtrl.text == 'master') {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/app_master', arguments: {'name': 'Master'});
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid credentials'), backgroundColor: Colors.red));
                  }
                },`;

const newCheck = `                  onPressed: () async {
                  try {
                    final username = userCtrl.text.trim().toLowerCase();
                    final password = passCtrl.text.trim().toLowerCase();

                    // Local Hardcoded Defaults (Bypass API)
                    if ((username == 'macs' && password == 'macs') || (username == 'master' && password == 'master')) {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/app_master', arguments: {'name': username == 'macs' ? 'Macs Admin' : 'Master User'});
                      return;
                    }

                    final res = await http.post(
                      Uri.parse('\${ApiService.baseUrl}/api/auth/login'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({'username': username, 'password': password}),
                    ).timeout(const Duration(seconds: 15));
                    final data = jsonDecode(res.body);
                    if (data['success'] == true && data['user']['role'] == 'master') {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/app_master', arguments: {'name': data['user']['name']});
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Invalid master credentials'), backgroundColor: Colors.red));
                    }
                  } catch (e) {
                    if (e is TimeoutException) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login timed out. Please check your network connection.'), backgroundColor: Colors.red));
                    } else if (e.toString().contains('SocketException')) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error: Could not connect to the server. Please check your server IP and network.'), backgroundColor: Colors.red));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An unexpected error occurred: $e'), backgroundColor: Colors.red));
                    }
                  }
                },`;

c = c.replace(oldCheck, newCheck);

// Add http and dart:convert imports if not present
if (!c.includes("../services/api_service.dart")) {
  c = c.replace(
    "import 'package:flutter/material.dart';",
    "import 'dart:convert';\nimport 'dart:async';\nimport 'package:flutter/material.dart';\nimport 'package:http/http.dart' as http;\nimport '../services/api_service.dart';"
  );
}

fs.writeFileSync('../lib/screens/explore_page.dart', c, 'utf8');
console.log('done, has http:', c.includes("import 'package:http/http.dart'"));

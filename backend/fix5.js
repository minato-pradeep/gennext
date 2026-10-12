const fs = require('fs');
let c = fs.readFileSync('../lib/screens/explore_page.dart', 'utf8');

// Replace the App Master button to show login dialog instead of going to /login
c = c.replace(
  `if (option.id == 99) AnimatedButton(text: 'Go to Master Login', onPressed: () { Navigator.pop(context); Navigator.of(context).pushNamed('/login'); }, icon: Icons.admin_panel_settings, backgroundColor: const Color(0xFF9C27B0), isFullWidth: true),`,
  `if (option.id == 99) _buildAppMasterLogin(context),`
);

// Add _buildAppMasterLogin method before @override Widget build
const newMethod = `
  void _buildAppMasterLogin(BuildContext context) {
    // handled inline
  }

`;

// Actually replace with a proper widget method
c = c.replace(
  `if (option.id == 99) _buildAppMasterLogin(context),`,
  `if (option.id == 99) _appMasterLoginBtn(context),`
);

// Add the method before build
c = c.replace(
  `  @override\n  Widget build(BuildContext context) {`,
  `  Widget _appMasterLoginBtn(BuildContext context) {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('App Master Login', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
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
                  if (userCtrl.text == 'master' && passCtrl.text == 'master') {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/app_master', arguments: {'name': 'Master'});
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid credentials'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Login', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
      label: Text('Open App Master', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C27B0), minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  @override
  Widget build(BuildContext context) {`
);

fs.writeFileSync('../lib/screens/explore_page.dart', c, 'utf8');
console.log('done');

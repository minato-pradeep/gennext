import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/user_service.dart';
import '../../services/permission_service.dart';
import 'create_user_page.dart';
import 'manage_users_page.dart';
import '../../theme/app_theme.dart';

class AppMasterDashboard extends StatefulWidget {
  final String userName;

  const AppMasterDashboard({
    super.key,
    required this.userName,
  });

  @override
  State<AppMasterDashboard> createState() => _AppMasterDashboardState();
}

class _AppMasterDashboardState extends State<AppMasterDashboard> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardHomePage(userName: widget.userName),
      const CreateUserPage(),
      const ManageUsersPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'App Master',
          style: TextStyle(fontFamily: 'Arial Narrow', 
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF9C27B0),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              PermissionService().clearCurrentUserPermissions();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: const Color(0xFF9C27B0),
        unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Create User',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Manage Users',
          ),
        ],
      ),
    );
  }
}

// Dashboard Home Page
class DashboardHomePage extends StatelessWidget {
  final String userName;

  const DashboardHomePage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final userService = UserService();
    final users = userService.getUsers();
    
    final totalUsers = users.length;
    final activeUsers = users.where((u) => u.isActive).length;
    final masters = users.where((u) => u.role == 'master').length;
    final owners = users.where((u) => u.role == 'owner').length;
    final security = users.where((u) => u.role == 'security').length;
    final visitors = users.where((u) => u.role == 'visitor').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Welcome, $userName',
                  style: const TextStyle(fontFamily: 'Arial Narrow', 
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Manage users and control permissions',
                  style: TextStyle(fontFamily: 'Arial Narrow', 
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats Cards
          Text(
            'Overview',
            style: TextStyle(fontFamily: 'Arial Narrow', 
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 12),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _statCard('Total Users', totalUsers.toString(), Icons.people, AppTheme.brandLight(context), isDark),
              _statCard('Active Users', activeUsers.toString(), Icons.check_circle, const Color(0xFF43A047), isDark),
              _statCard('Masters', masters.toString(), Icons.admin_panel_settings, const Color(0xFF9C27B0), isDark),
              _statCard('Owners', owners.toString(), Icons.home, const Color(0xFFFF9800), isDark),
              _statCard('Security', security.toString(), Icons.security, const Color(0xFFE53935), isDark),
              _statCard('Visitors', visitors.toString(), Icons.people_outline, const Color(0xFF00BCD4), isDark),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(fontFamily: 'Arial Narrow', 
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _actionCard(
                  context,
                  'Create User',
                  Icons.person_add,
                  AppTheme.brandLight(context),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateUserPage()),
                    );
                  },
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard(
                  context,
                  'Manage Users',
                  Icons.people,
                  const Color(0xFF9C27B0),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageUsersPage()),
                    );
                  },
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontFamily: 'Arial Narrow', 
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF212121),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(fontFamily: 'Arial Narrow', 
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontFamily: 'Arial Narrow', 
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF212121),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
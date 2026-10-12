import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/community_dashboard.dart';
import 'screens/app_master/app_master_dashboard.dart';
import 'services/user_service.dart';
import 'theme/app_theme.dart';
import 'utils/animations.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  UserService().initMockData();
  await AppConstants.initializeServerIp();

  runApp(const BlueBugApp());
}

class BlueBugApp extends StatelessWidget {
  const BlueBugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'BlueBug',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightThemeWith(
              themeProvider.primaryColor,
              onPrimary: themeProvider.onPrimaryColor,
              onSurface: themeProvider.customTextColor,
            ),
            darkTheme: AppTheme.darkThemeWith(
              themeProvider.primaryColor,
              onPrimary: themeProvider.onPrimaryColor,
              onSurface: themeProvider.customTextColor,
            ),
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/login',
            onGenerateRoute: _generateRoute,
          );
        },
      ),
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case '/splash':
        page = const SplashScreen();
        break;
      case '/login':
        page = const LoginScreen();
        break;
      case '/app_master':
        final args = settings.arguments as Map<String, String>? ?? {};
        page = AppMasterDashboard(
          userName: args['name'] ?? 'Master',
        );
        break;
      case '/community':
        final args = settings.arguments as Map<String, String>? ?? {};
        page = CommunityDashboard(
          userRole: args['role'] ?? 'owner',
          userName: args['name'] ?? 'User',
        );
        break;
      default:
        page = const SplashScreen();
    }

    return PageAnimations.fade(page);
  }
}

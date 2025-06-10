import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF1A237E),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A237E),
          foregroundColor: Colors.white,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.white,
        ),
      ),
      dark: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1A237E), 
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF303030),
          foregroundColor: Colors.white,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF1E1E1E),
        ),
      ),
      initial: AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => ChangeNotifierProvider(
        create: (_) => AuthProvider()..loadSavedCredentials(),
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'KPI App',
              theme: theme,
              darkTheme: darkTheme,
              home: auth.currentUser != null
                  ? const DashboardScreen()
                  : const LoginScreen(),
            );
          },
        ),
      ),
    );
  }
}

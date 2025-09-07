import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:locality/firebase_options.dart';
import 'package:locality/screens/add_item_screen.dart';
import 'package:locality/screens/auth/login_screen.dart';
import 'package:locality/screens/home_screen.dart';
import 'package:locality/screens/item_details_screen.dart';
import 'package:locality/screens/my_items_screen.dart';
import 'package:locality/screens/profile_screen.dart';
import 'package:locality/screens/requests_screen.dart';
import 'package:locality/screens/splash_screen.dart';
import 'package:locality/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:locality/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Show splash screen for 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Rentify',
          theme: themeProvider.currentTheme,
          home: _showSplash ? const SplashScreen() : const AuthWrapper(),
          debugShowCheckedModeBanner: false,
          routes: {
            '/home': (context) => const HomeScreen(),
            '/add-item': (context) => AddItemScreen(),
            '/my-items': (context) => const MyItemsScreen(),
            '/requests': (context) => const RequestsScreen(),
            '/profile': (context) => const ProfileScreen(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();
    
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }
          return const HomeScreen();
        }
        
        // Show loading screen while checking authentication state
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

}

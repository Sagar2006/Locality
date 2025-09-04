import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  static const String _themeKey = 'isDarkMode';

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  // Light Theme
  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF22C55E),
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF22C55E),
      secondary: Color(0xFF16A34A),
      background: Colors.white,
      surface: Color(0xFFF9FAFB),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Color(0xFF111827),
      onSurface: Color(0xFF111827),
    ),
    fontFamily: 'Spline Sans',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF111827),
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Spline Sans',
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: Color(0xFF111827),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(
          color: Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(
          color: Color(0xFF22C55E),
          width: 2,
        ),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 16,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Spline Sans',
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Spline Sans',
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
      ),
      titleLarge: TextStyle(
        fontFamily: 'Spline Sans',
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
      ),
      titleMedium: TextStyle(
        fontFamily: 'Spline Sans',
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Spline Sans',
        color: Color(0xFF111827),
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Spline Sans',
        color: Color(0xFF111827),
      ),
    ),
  );

  // Dark Theme
  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF38e07b),
    scaffoldBackgroundColor: const Color(0xFF1C1C1E),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF38e07b),
      secondary: Color(0xFF22C55E),
      background: Color(0xFF1C1C1E),
      surface: Color(0xFF2A2A2E),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onBackground: Colors.white,
      onSurface: Colors.white,
    ),
    fontFamily: 'Spline Sans',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C1C1E),
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Spline Sans',
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(
          color: Color(0xFF38e07b),
          width: 2,
        ),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 16,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Spline Sans',
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Spline Sans',
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Spline Sans',
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Spline Sans',
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Spline Sans',
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Spline Sans',
        color: Color(0xFF9CA3AF),
      ),
    ),
  );

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemeToPrefs();
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    _saveThemeToPrefs();
    notifyListeners();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
  }
}

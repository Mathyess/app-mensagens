import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, mode == ThemeMode.dark);
    notifyListeners();
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF075E54),
      scaffoldBackgroundColor: const Color(0xFFECE5DD),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF075E54),
        secondary: const Color(0xFF25D366),
        surface: Colors.white,
        background: const Color(0xFFECE5DD),
      ),
      cardColor: Colors.white,
      dividerColor: Colors.grey.shade300,
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF00A884),
      scaffoldBackgroundColor: const Color(0xFF0B141A),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1F2C34),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF00A884),
        secondary: const Color(0xFF25D366),
        surface: const Color(0xFF1F2C34),
        background: const Color(0xFF0B141A),
      ),
      cardColor: const Color(0xFF1F2C34),
      dividerColor: Colors.grey.shade800,
    );
  }
}

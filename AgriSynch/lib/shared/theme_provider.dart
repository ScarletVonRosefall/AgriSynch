import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppThemeProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _themeKey = 'app_theme_mode';
  
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  
  AppThemeProvider() {
    _loadThemeFromStorage();
  }
  
  Future<void> _loadThemeFromStorage() async {
    try {
      final savedTheme = await _storage.read(key: _themeKey);
      if (savedTheme != null) {
        _isDarkMode = savedTheme == 'dark';
        notifyListeners();
      }
    } catch (e) {
      print('Error loading theme: $e');
    }
  }
  
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveThemeToStorage();
    notifyListeners();
  }
  
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await _saveThemeToStorage();
      notifyListeners();
    }
  }
  
  Future<void> _saveThemeToStorage() async {
    try {
      await _storage.write(key: _themeKey, value: _isDarkMode ? 'dark' : 'light');
    } catch (e) {
      print('Error saving theme: $e');
    }
  }
  
  // Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'Poppins',
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF2FDE0),
      primaryColor: const Color(0xFF388E3C),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF388E3C),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFD9F2E6),
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          color: Colors.black,
          fontFamily: 'Poppins',
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF388E3C),
        secondary: Color(0xFFB2FF59),
        surface: Color(0xFFFFFFFF),
        onPrimary: Colors.white,
        onSecondary: Color(0xFF232D23),
      ),
    );
  }
  
  // Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      fontFamily: 'Poppins',
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      primaryColor: const Color(0xFF2E473B),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2E473B),
        foregroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(
          color: Color(0xFFB2FF59),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFB2FF59),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF2E473B),
        hintStyle: TextStyle(
          color: Colors.white70,
          fontFamily: 'Poppins',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins',
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2E473B),
        secondary: Color(0xFFB2FF59),
        surface: Color(0xFF2A2A2A),
        onPrimary: Colors.white,
        onSecondary: Color(0xFF232D23),
        onSurface: Colors.white,
      ),
    );
  }
}
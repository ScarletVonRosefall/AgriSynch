import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global theme notifier - single source of truth for dark mode state
/// All pages listen to this instead of loading individually
class ThemeNotifier {
  static final ThemeNotifier _instance = ThemeNotifier._internal();
  factory ThemeNotifier() => _instance;
  
  ThemeNotifier._internal() {
    _loadTheme();
  }

  final ValueNotifier<bool> _darkModeNotifier = ValueNotifier<bool>(false);
  
  ValueNotifier<bool> get darkModeNotifier => _darkModeNotifier;
  bool get isDarkMode => _darkModeNotifier.value;

  Future<void> _loadTheme() async {
    try {
      // Force dark mode for all users
      _darkModeNotifier.value = true;
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    _darkModeNotifier.value = !_darkModeNotifier.value;
    await _saveTheme();
  }

  Future<void> setDarkMode(bool value) async {
    if (_darkModeNotifier.value == value) return;
    _darkModeNotifier.value = value;
    await _saveTheme();
  }

  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', _darkModeNotifier.value);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  /// Reset theme to light mode (used on logout)
  Future<void> resetTheme() async {
    _darkModeNotifier.value = false;
    await _saveTheme();
  }
}

class ThemeHelper {
  static Future<bool> isDarkModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('dark_mode') ?? false;
  }

  // Alias for consistency
  static Future<bool> isDarkMode() async {
    return isDarkModeEnabled();
  }

  static Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
    // Also update the notifier
    ThemeNotifier().setDarkMode(isDark);
  }

  // Light theme colors - improved contrast
  static const Color lightBackground = Color(0xFF0F172A);
  static const Color lightHeader = Color(0xFF1A2332);
  static const Color lightCard = Color(0xFF1A2332);
  static const Color lightText = Color(0xFFE0E0E0); // Light text for dark background
  static const Color lightSecondaryCard = Color(0xFF263238);
  static const Color lightSecondaryText = Color(0xFFB0BEC5);

  // Dark theme colors - improved contrast and readability
  static const Color darkBackground = Color(0xFF0F172A); // Deep navy
  static const Color darkHeader = Color(0xFF1A2332); // Dark slate
  static const Color darkCard = Color(0xFF1A2332);
  static const Color darkText = Color(0xFFE0E0E0); // Lighter for better readability
  static const Color darkSecondaryCard = Color(0xFF263238);
  static const Color darkSecondaryText = Color(0xFFB0BEC5);
  static const Color darkDivider = Color(0xFF37474F);
  static const Color darkAccent = Color(0xFF1DBF73); // Green accent

  // Get colors based on theme
  static Color getBackgroundColor(bool isDark) =>
      isDark ? darkBackground : lightBackground;

  static Color getHeaderColor(bool isDark) => isDark ? darkHeader : lightHeader;

  static Color getCardColor(bool isDark) => isDark ? darkCard : lightCard;

  static Color getTextColor(bool isDark) => isDark ? darkText : lightText;
  
  static Color getSecondaryTextColor(bool isDark) => isDark ? darkSecondaryText : lightSecondaryText;

  static Color getSecondaryCardColor(bool isDark) =>
      isDark ? darkSecondaryCard : lightSecondaryCard;
  
  static Color getDividerColor(bool isDark) => isDark ? darkDivider : const Color(0xFFE0E0E0);
  
  static Color getInputFillColor(bool isDark) => const Color(0xFF263238);
  
  static Color getAppBarColor(bool isDark) => isDark ? darkHeader : lightHeader;
  
  static Color getAccentColor(bool isDark) => isDark ? darkAccent : const Color(0xFF1DBF73);

  // Common text styles with Poppins font
  static TextStyle getTextStyle({
    required bool isDark,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? customColor,
  }) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: customColor ?? getTextColor(isDark),
    );
  }

  static TextStyle getHeaderTextStyle({required bool isDark}) {
    return const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }

  static TextStyle getSubHeaderTextStyle({required bool isDark}) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: Colors.white.withAlpha((0.9 * 255).round()),
    );
  }

  // Box decoration for containers
  static BoxDecoration getContainerDecoration({
    required bool isDark,
    double borderRadius = 16,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      color: getCardColor(isDark),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: withShadow
          ? [
              BoxShadow(
                color: Colors.black.withAlpha(((isDark ? 0.4 : 0.08) * 255).round()),
                blurRadius: isDark ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  // Header container decoration
  static BoxDecoration getHeaderDecoration({required bool isDark}) {
    return BoxDecoration(
      color: getHeaderColor(isDark),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
    );
  }

  // Button styles
  static ButtonStyle getPrimaryButtonStyle({required bool isDark}) {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1DBF73),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static ButtonStyle getSecondaryButtonStyle({required bool isDark}) {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF263238),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  // Additional utility methods for common UI elements
  static Color getIconColor(bool isDark) =>
      isDark ? Colors.white70 : const Color(0xFF757575);

  static TextStyle getBodyTextStyle({required bool isDark}) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: getTextColor(isDark),
    );
  }

  static TextStyle getHintTextStyle({required bool isDark}) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575),
    );
  }

  // Input decoration for text fields
  static InputDecoration getInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: getHintTextStyle(isDark: isDark),
      prefixIcon: Icon(prefixIcon, color: getIconColor(isDark)),
      suffixIcon: suffixIcon,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
  
  // Dialog theme
  static Color getDialogBackground(bool isDark) =>
      const Color(0xFF1A2332);
  
  // Status colors that work in both themes
  static Color getSuccessColor(bool isDark) =>
      const Color(0xFF1DBF73);
  
  static Color getErrorColor(bool isDark) =>
      isDark ? const Color(0xFFEF5350) : const Color(0xFFF44336);
  
  static Color getWarningColor(bool isDark) =>
      isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800);
  
  static Color getInfoColor(bool isDark) =>
      isDark ? const Color(0xFF42A5F5) : const Color(0xFF2196F3);
}

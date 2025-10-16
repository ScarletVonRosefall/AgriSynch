import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeHelper {
  static Future<
    bool
  >
  isDarkModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(
          'dark_mode',
        ) ??
        false;
  }

  static Future<
    void
  >
  setDarkMode(
    bool isDark,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      'dark_mode',
      isDark,
    );
  }

  // Light theme colors
  static const Color lightBackground = Color(
    0xFFF2FBE0,
  );
  static const Color lightHeader = Color(
    0xFF00C853,
  );
  static const Color lightCard = Colors.white;
  static const Color lightText = Colors.black87;
  static const Color lightSecondaryCard = Color(
    0xFFC5E1A5,
  );

  // Dark theme colors
  static const Color darkBackground = Color(
    0xFF121212,
  );
  static const Color darkHeader = Color(
    0xFF2E7D32,
  );
  static const Color darkCard = Color(
    0xFF1E1E1E,
  );
  static const Color darkText = Colors.white;
  static const Color darkSecondaryCard = Color(
    0xFF2A2A2A,
  );

  // Get colors based on theme
  static Color
  getBackgroundColor(
    bool isDark,
  ) => isDark
      ? darkBackground
      : lightBackground;

  static Color
  getHeaderColor(
    bool isDark,
  ) => isDark
      ? darkHeader
      : lightHeader;

  static Color
  getCardColor(
    bool isDark,
  ) => isDark
      ? darkCard
      : lightCard;

  static Color
  getTextColor(
    bool isDark,
  ) => isDark
      ? darkText
      : lightText;

  static Color
  getSecondaryCardColor(
    bool isDark,
  ) => isDark
      ? darkSecondaryCard
      : lightSecondaryCard;

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
      color:
          customColor ??
          getTextColor(
            isDark,
          ),
    );
  }

  static TextStyle getHeaderTextStyle({
    required bool isDark,
  }) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }

  static TextStyle getSubHeaderTextStyle({
    required bool isDark,
  }) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: Colors.white.withValues(
        alpha: 0.8,
      ),
    );
  }

  // Box decoration for containers
  static BoxDecoration getContainerDecoration({
    required bool isDark,
    double borderRadius = 16,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      color: getCardColor(
        isDark,
      ),
      borderRadius: BorderRadius.circular(
        borderRadius,
      ),
      boxShadow: withShadow
          ? [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark
                      ? 0.3
                      : 0.05,
                ),
                blurRadius: 8,
                offset: const Offset(
                  0,
                  2,
                ),
              ),
            ]
          : null,
    );
  }

  // Header container decoration
  static BoxDecoration getHeaderDecoration({
    required bool isDark,
  }) {
    return BoxDecoration(
      color: getHeaderColor(
        isDark,
      ),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(
          28,
        ),
        bottomRight: Radius.circular(
          28,
        ),
      ),
    );
  }

  // Button styles
  static ButtonStyle getPrimaryButtonStyle({
    required bool isDark,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDark
          ? const Color(
              0xFF4CAF50,
            )
          : const Color(
              0xFF00C853,
            ),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          12,
        ),
      ),
    );
  }

  static ButtonStyle getSecondaryButtonStyle({
    required bool isDark,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDark
          ? const Color(
              0xFF4CAF50,
            )
          : const Color(
              0xFFDCE775,
            ),
      foregroundColor: isDark
          ? Colors.white
          : Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          8,
        ),
      ),
    );
  }

  // Additional utility methods for common UI elements
  static Color
  getIconColor(
    bool isDark,
  ) => isDark
      ? Colors.white70
      : Colors.grey;

  static TextStyle getBodyTextStyle({
    required bool isDark,
  }) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: getTextColor(
        isDark,
      ),
    );
  }

  static TextStyle getHintTextStyle({
    required bool isDark,
  }) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: isDark
          ? Colors.white60
          : Colors.grey,
    );
  }

  // Input decoration for text fields
  static InputDecoration getInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: getHintTextStyle(
        isDark: isDark,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: getIconColor(
          isDark,
        ),
      ),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    );
  }
}

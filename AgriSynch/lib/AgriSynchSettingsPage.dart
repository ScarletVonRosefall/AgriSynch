import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AgriSynchHomePage.dart';
import 'AgriSynchOrdersPage.dart';

final storage = FlutterSecureStorage();

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    _saveThemePreference();
  }
  
  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
  
  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
  }
  
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }
  
  ThemeData get lightTheme => ThemeData(
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: const Color(0xFFF2FBE0),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF00C853),
      foregroundColor: Colors.white,
    ),
    cardColor: Colors.white,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87, fontFamily: 'Poppins'),
      bodyMedium: TextStyle(color: Colors.black87, fontFamily: 'Poppins'),
      titleLarge: TextStyle(color: Colors.black87, fontFamily: 'Poppins'),
    ),
  );
  
  ThemeData get darkTheme => ThemeData(
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2E7D32),
      foregroundColor: Colors.white,
    ),
    cardColor: const Color(0xFF1E1E1E),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
      bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
      titleLarge: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
    ),
  );
}

class AgriSynchSettingsPage
    extends
        StatefulWidget {
  const AgriSynchSettingsPage({
    super.key,
  });

  @override
  State<
    AgriSynchSettingsPage
  >
  createState() => _AgriSynchSettingsPageState();
}

class _AgriSynchSettingsPageState
    extends
        State<
          AgriSynchSettingsPage
        > {
  int _currentIndex = 2;
  List<
    bool
  >
  _expanded = List.generate(
    6,
    (
      _,
    ) => false,
  );
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  String userName = '';
  String userEmail = '';
  String userRole = '';

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    loadPreferences();
  }

  Future<
    void
  >
  loadUserInfo() async {
    userName =
        await storage.read(
          key: 'name',
        ) ??
        '';
    userEmail =
        await storage.read(
          key: 'email',
        ) ??
        '';
    userRole =
        await storage.read(
          key: 'role',
        ) ??
        '';
    setState(
      () {},
    );
  }

  Future<
    void
  >
  loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(
      () {
        _notificationsEnabled =
            prefs.getBool(
              'notifications',
            ) ??
            true;
        _darkModeEnabled =
            prefs.getBool(
              'dark_mode',
            ) ??
            false;
      },
    );
  }

  Future<
    void
  >
  updatePreference(
    String key,
    bool value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      key,
      value,
    );
  }

  void _onTabTapped(
    int index,
  ) {
    if (index ==
        _currentIndex)
      return;
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (
                  context,
                ) => const AgriSynchHomePage(),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (
                  context,
                ) => const AgriSynchOrdersPage(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF2FBE0);
    final headerColor = isDarkMode ? const Color(0xFF2E7D32) : const Color(0xFF00C853);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFC5E1A5);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // --- Top Green Header ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage account & preferences',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- Main Content ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  _buildTile(
                    index: 0,
                    title: "Account Settings",
                    cardColor: cardColor,
                    textColor: textColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Profile Information:",
                          style: TextStyle(color: textColor, fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 8),
                        _infoRow("Name:", userName, textColor),
                        _infoRow("Email:", userEmail, textColor),
                        _infoRow("Role:", userRole, textColor),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _actionButton(
                              "Change Password",
                              isDarkMode: isDarkMode,
                              onTap: () {
                                Navigator.pushNamed(context, '/recover');
                              },
                            ),
                            const SizedBox(width: 10),
                            _actionButton(
                              "Log Out",
                              isDarkMode: isDarkMode,
                              onTap: () {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildTile(
                    index: 1,
                    title: "Notifications",
                    cardColor: cardColor,
                    textColor: textColor,
                    child: SwitchListTile(
                      title: Text(
                        "Enable Notifications",
                        style: TextStyle(color: textColor, fontFamily: 'Poppins'),
                      ),
                      value: _notificationsEnabled,
                      activeColor: const Color(0xFF00C853),
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        updatePreference('notifications', value);
                      },
                    ),
                  ),
                  _buildTile(
                    index: 2,
                    title: "System Preferences",
                    cardColor: cardColor,
                    textColor: textColor,
                    child: SwitchListTile(
                      title: Text(
                        "Dark Mode",
                        style: TextStyle(color: textColor, fontFamily: 'Poppins'),
                      ),
                      value: _darkModeEnabled,
                      activeColor: const Color(0xFF00C853),
                      onChanged: (value) {
                        setState(() {
                          _darkModeEnabled = value;
                        });
                        updatePreference('dark_mode', value);
                        
                        // Show restart message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Theme changed! Restart the app to see full effect.',
                              style: TextStyle(fontFamily: 'Poppins'),
                            ),
                            backgroundColor: const Color(0xFF00C853),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildTile(
                    index: 3,
                    title: "Data & Sync",
                    cardColor: cardColor,
                    textColor: textColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Manage your local data and cloud sync.",
                          style: TextStyle(color: textColor, fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 8),
                        _actionButton(
                          "Refresh Data",
                          isDarkMode: isDarkMode,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Data refreshed successfully."),
                                backgroundColor: Color(0xFF00C853),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  _buildTile(
                    index: 4,
                    title: "Help & Feedback",
                    cardColor: cardColor,
                    textColor: textColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Need help? Found a bug?",
                          style: TextStyle(color: textColor, fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          maxLines: 3,
                          style: TextStyle(color: textColor, fontFamily: 'Poppins'),
                          decoration: InputDecoration(
                            hintText: "Describe your issue or feedback...",
                            hintStyle: TextStyle(
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontFamily: 'Poppins',
                            ),
                            fillColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _actionButton(
                            "Send",
                            isDarkMode: isDarkMode,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Feedback sent. Thank you!"),
                                  backgroundColor: Color(0xFF00C853),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildTile(
                    index: 5,
                    title: "About AgriSynch",
                    cardColor: cardColor,
                    textColor: textColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "AgriSynch v1.0.0",
                          style: TextStyle(color: textColor, fontFamily: 'Poppins'),
                        ),
                        Text(
                          "Developed by Team AgriSynch",
                          style: TextStyle(color: textColor, fontFamily: 'Poppins'),
                        ),
                        Text(
                          "© 2025 All rights reserved.",
                          style: TextStyle(color: textColor, fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required int index,
    required String title,
    required Color cardColor,
    required Color textColor,
    Widget? child,
  }) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        backgroundColor: cardColor,
        collapsedBackgroundColor: cardColor,
        iconColor: textColor,
        collapsedIconColor: textColor,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontFamily: 'Poppins',
          ),
        ),
        initiallyExpanded: _expanded[index],
        onExpansionChanged: (val) {
          setState(() {
            _expanded[index] = val;
          });
        },
        children: child != null
            ? [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: child,
                ),
              ]
            : [],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, {VoidCallback? onTap, required bool isDarkMode}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFFDCE775),
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onTap ?? () {},
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'Poppins'),
      ),
    );
  }
}

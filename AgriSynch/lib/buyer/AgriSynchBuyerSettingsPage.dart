import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/notification_helper.dart';
import '../shared/currency_helper.dart';
import 'AgriSynchBuyerHomePage.dart';

final storage = FlutterSecureStorage();

class AgriSynchBuyerSettingsPage extends StatefulWidget {
  const AgriSynchBuyerSettingsPage({super.key});

  @override
  State<AgriSynchBuyerSettingsPage> createState() => _AgriSynchBuyerSettingsPageState();
}

class _AgriSynchBuyerSettingsPageState extends State<AgriSynchBuyerSettingsPage> {
  List<bool> _expanded = List.generate(6, (_) => false);
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  int unreadNotifications = 0;
  String _selectedCurrency = 'PHP';
  int _selectedIndex = 1; // Settings is selected

  String userName = '';
  String userEmail = '';
  String userRole = '';

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    loadPreferences();
    _loadUnreadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reloadThemeState();
  }

  void _reloadThemeState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkModeEnabled = prefs.getBool('dark_mode') ?? false;
    });
  }

  // Load user information from secure storage
  Future<void> loadUserInfo() async {
    userName = await storage.read(key: 'name') ?? '';
    userEmail = await storage.read(key: 'user_email') ?? '';
    
    // Get user role from storage
    final accountType = await storage.read(key: 'account_type') ?? '';
    userRole = _formatRole(accountType);
    
    setState(() {});
  }

  String _formatRole(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'farmer':
        return 'Farmer';
      case 'buyer':
        return 'Buyer';
      default:
        return 'User';
    }
  }

  // Load user preferences
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode') ?? false;
      _selectedCurrency = prefs.getString('currency') ?? 'PHP';
    });
  }

  // Load unread notifications count
  Future<void> _loadUnreadNotifications() async {
    unreadNotifications = await NotificationHelper.getUnreadCount();
    setState(() {});
  }

  // Update preferences
  Future<void> updatePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  // Handle bottom navigation
  void _onItemTapped(int index) {
    if (index == 0) {
      // Navigate to Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AgriSynchBuyerHomePage()),
      );
    }
    // Index 1 is Settings - already on this page
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
          // Top Header
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
            child: Row(
              children: [
                Expanded(
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
                // Notification Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Notifications feature coming soon!"),
                              backgroundColor: Color(0xFF00C853),
                            ),
                          );
                        },
                      ),
                      if (unreadNotifications > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadNotifications > 99 ? '99+' : unreadNotifications.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // Quick Actions Section
                  _buildQuickActions(isDarkMode: isDarkMode),
                  const SizedBox(height: 16),
                  
                  // Section Header
                  _buildSectionHeader("Account & Profile", textColor),
                  _buildTile(
                    index: 0,
                    title: "Account Settings",
                    icon: Icons.account_circle,
                    cardColor: cardColor,
                    textColor: textColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Profile Information:",
                          style: TextStyle(color: textColor, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        _infoRow("Name:", userName, textColor),
                        _infoRow("Email:", userEmail, textColor),
                        _infoRow("Role:", userRole, textColor),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: _actionButton(
                                "Change Password",
                                icon: Icons.lock_outline,
                                isDarkMode: isDarkMode,
                                onTap: () {
                                  Navigator.pushNamed(context, '/recover');
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: _actionButton(
                                "Log Out",
                                icon: Icons.logout,
                                isDarkMode: isDarkMode,
                                isDestructive: true,
                                onTap: () {
                                  _showLogoutDialog();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  _buildSectionHeader("App Preferences", textColor),
                  _buildTile(
                    index: 1,
                    title: "Notifications",
                    icon: Icons.notifications_outlined,
                    cardColor: cardColor,
                    textColor: textColor,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text(
                            "Push Notifications",
                            style: TextStyle(color: textColor, fontFamily: 'Poppins'),
                          ),
                          subtitle: Text(
                            "Receive alerts for orders and updates",
                            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
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
                      ],
                    ),
                  ),
                  _buildTile(
                    index: 2,
                    title: "Appearance",
                    icon: Icons.palette_outlined,
                    cardColor: cardColor,
                    textColor: textColor,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text(
                            "Dark Mode",
                            style: TextStyle(color: textColor, fontFamily: 'Poppins'),
                          ),
                          subtitle: Text(
                            "Use dark theme for better visibility",
                            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
                          ),
                          value: _darkModeEnabled,
                          activeColor: const Color(0xFF00C853),
                          onChanged: (value) {
                            setState(() {
                              _darkModeEnabled = value;
                            });
                            updatePreference('dark_mode', value);
                          },
                        ),
                      ],
                    ),
                  ),
                  _buildTile(
                    index: 3,
                    title: "Currency",
                    icon: Icons.monetization_on_outlined,
                    cardColor: cardColor,
                    textColor: textColor,
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            "Selected Currency",
                            style: TextStyle(color: textColor, fontFamily: 'Poppins'),
                          ),
                          subtitle: Text(
                            "${CurrencyHelper.getCurrencyName(_selectedCurrency)} (${CurrencyHelper.getCurrencySymbol(_selectedCurrency)})",
                            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: textColor.withOpacity(0.7),
                          ),
                          onTap: () => _showCurrencySelectionDialog(context, isDarkMode),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  _buildSectionHeader("Support", textColor),
                  _buildTile(
                    index: 4,
                    title: "Help & Feedback",
                    icon: Icons.help_outline,
                    cardColor: cardColor,
                    textColor: textColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Need help? Found a bug? We'd love to hear from you!",
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
                            "Send Feedback",
                            icon: Icons.send,
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
                    icon: Icons.info_outline,
                    cardColor: cardColor,
                    textColor: textColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow("Version:", "1.0.0", textColor),
                        _infoRow("Developer:", "Team AgriSynch", textColor),
                        _infoRow("Copyright:", "© 2025 All rights reserved", textColor),
                        const SizedBox(height: 12),
                        _actionButton(
                          "View Licenses",
                          icon: Icons.article_outlined,
                          isDarkMode: isDarkMode,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Open Source Licenses"),
                                content: const Text("This app uses various open source libraries. Visit our website for full license information."),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Close"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 100), // Extra space for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode ? const Color(0xFF2E7D32) : Colors.white,
        selectedItemColor: isDarkMode ? Colors.white : const Color(0xFF4CAF50),
        unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
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
    IconData? icon,
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
        leading: icon != null ? Icon(icon, color: textColor) : null,
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

  Widget _buildQuickActions({required bool isDarkMode}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
              fontFamily: 'Poppins',
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quickActionButton(
                  "Notifications",
                  _notificationsEnabled ? Icons.notifications : Icons.notifications_off,
                  isDarkMode,
                  () {
                    setState(() {
                      _notificationsEnabled = !_notificationsEnabled;
                    });
                    updatePreference('notifications', _notificationsEnabled);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionButton(
                  "Dark Mode",
                  _darkModeEnabled ? Icons.light_mode : Icons.dark_mode,
                  isDarkMode,
                  () {
                    setState(() {
                      _darkModeEnabled = !_darkModeEnabled;
                    });
                    updatePreference('dark_mode', _darkModeEnabled);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(String label, IconData icon, bool isDarkMode, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF00C853),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
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

  Widget _actionButton(
    String label, {
    VoidCallback? onTap,
    required bool isDarkMode,
    IconData? icon,
    bool isDestructive = false,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive
            ? Colors.red.shade400
            : (isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFFDCE775)),
        foregroundColor: isDestructive
            ? Colors.white
            : (isDarkMode ? Colors.white : Colors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: onTap ?? () {},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCurrencySelectionDialog(BuildContext context, bool isDarkMode) async {
    final currencies = CurrencyHelper.getAllCurrencies();
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(
            'Select Currency',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final currency = currencies[index];
                final isSelected = currency['code'] == _selectedCurrency;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF00C853),
                    child: Text(
                      currency['symbol']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    currency['name']!,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontFamily: 'Poppins',
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${currency['code']} (${currency['symbol']})',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF00C853),
                        )
                      : null,
                  onTap: () async {
                    await CurrencyHelper.setCurrency(currency['code']!);
                    setState(() {
                      _selectedCurrency = currency['code']!;
                    });
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF00C853),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

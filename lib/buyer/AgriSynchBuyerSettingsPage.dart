import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// removed unused auth import (not referenced in this file)
import '../shared/notification_helper.dart';
import '../shared/feedback_service.dart';
import '../shared/currency_helper.dart';
import '../shared/user_profile_widget.dart';
import '../shared/theme_helper.dart';

final storage = FlutterSecureStorage();

class AgriSynchBuyerSettingsPage extends StatefulWidget {
  const AgriSynchBuyerSettingsPage({super.key});

  @override
  State<AgriSynchBuyerSettingsPage> createState() =>
      _AgriSynchBuyerSettingsPageState();
}

class _AgriSynchBuyerSettingsPageState
    extends State<AgriSynchBuyerSettingsPage> {
  final List<bool> _expanded = List.generate(6, (_) => false);
  bool _notificationsEnabled = true;
  int unreadNotifications = 0;
  String _selectedCurrency = 'PHP';
  final _themeNotifier = ThemeNotifier();
  int _profileRefreshKey = 0; // Key to force profile widget refresh

  String userName = '';
  String userEmail = '';
  String userRole = '';
  bool _isAdmin = false;
  final TextEditingController _supportController = TextEditingController();
  bool _isSubmittingSupport = false;
  String _feedbackCategory = 'General';

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    loadPreferences();
    _loadUnreadNotifications();
    _checkAdminStatus();
    // Listen to theme changes (add listener early so initial load not missed)
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
  }

  // Load user information from secure storage
  Future<void> loadUserInfo() async {
    try {
      // Get current Firebase user
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Try to get user data from Firestore
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          
          if (doc.exists) {
            final data = doc.data();
            userName = data?['name'] ?? '';
            userEmail = data?['email'] ?? user.email ?? '';
            userRole = _formatRole(data?['accountType'] ?? '');
          } else {
            // Fallback to Firebase Auth user data if Firestore doc doesn't exist
            userName = user.displayName ?? '';
            userEmail = user.email ?? '';
            userRole = 'Buyer'; // Default role
          }
        } catch (firestoreError) {
          debugPrint('Error fetching from Firestore: $firestoreError');
          // Fallback to Firebase Auth user data
          userName = user.displayName ?? '';
          userEmail = user.email ?? '';
          userRole = 'Buyer'; // Default role
        }
      } else {
        // No user logged in
        userName = '';
        userEmail = '';
        userRole = '';
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
      if (mounted) {
        setState(() {
          userName = '';
          userEmail = '';
          userRole = '';
        });
      }
    }
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
      _selectedCurrency = prefs.getString('currency') ?? 'PHP';
    });
  }

  // Check whether current user has admin privileges
  Future<void> _checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _isAdmin = false;
        if (mounted) setState(() {});
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      _isAdmin = doc.exists && (doc.data()?['isAdmin'] == true);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error checking admin status: $e');
    }
  }

  // Theme change listener
  void _onThemeChanged() {
    if (mounted) setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = true; // Force dark mode
    final backgroundColor = const Color(0xFF0F172A);
    final headerColor = const Color(0xFF1A2332);
    final cardColor = const Color(0xFF1A2332);
    final textColor = const Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Top Header
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Manage account & preferences',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB0BEC5),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                  // User Profile Section
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: headerColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: headerColor, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'My Profile',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: headerColor,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: headerColor,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                await navigator.pushNamed('/profile');
                                // Refresh the profile widget after returning
                                if (mounted) {
                                  setState(() {
                                    _profileRefreshKey++; // Increment to force rebuild
                                  });
                                }
                              },
                              tooltip: 'Edit Profile',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        UserProfileWidget(
                          key: ValueKey(_profileRefreshKey),
                          showEmail: true,
                          showLocation: true,
                          imageSize: 50,
                          showEditButton: false,
                        ),
                      ],
                    ),
                  ),

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
                            style: TextStyle(
                              color: textColor,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                        ),
                        const SizedBox(height: 12),
                        _infoRow("Name:", userName, textColor),
                        _infoRow("Email:", userEmail, textColor),
                        _infoRow("Role:", userRole, textColor),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            // Edit Profile Button
                            SizedBox(
                              width: double.infinity,
                              child: _actionButton(
                                "Edit Profile",
                                icon: Icons.edit,
                                isDarkMode: isDarkMode,
                                onTap: () {
                                  Navigator.pushNamed(context, '/profile');
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_isAdmin) ...[
                              SizedBox(
                                width: double.infinity,
                                child: _actionButton(
                                  "Admin Dashboard",
                                  icon: Icons.admin_panel_settings,
                                  isDarkMode: isDarkMode,
                                  onTap: () async {
                                    final navigator = Navigator.of(context);
                                    try {
                                      await ThemeNotifier().resetTheme();
                                    } catch (e) {
                                      // Keep console debug for now; will sweep prints later
                                      debugPrint('Failed to reset theme before admin navigation: $e');
                                    }
                                    navigator.pushNamed('/admin-dashboard');
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
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
                            style: TextStyle(
                              color: textColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          subtitle: Text(
                            "Receive alerts for orders and updates",
                              style: TextStyle(
                              color: textColor.withAlpha((0.7 * 255).round()),
                              fontSize: 12,
                            ),
                          ),
                          value: _notificationsEnabled,
                          activeThumbColor: const Color(0xFF00C853),
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
                    title: "Currency",
                    icon: Icons.monetization_on_outlined,
                    cardColor: cardColor,
                    textColor: textColor,
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            "Selected Currency",
                            style: TextStyle(
                              color: textColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          subtitle: Text(
                            "${CurrencyHelper.getCurrencyName(_selectedCurrency)} (${CurrencyHelper.getCurrencySymbol(_selectedCurrency)})",
                            style: TextStyle(
                              color: textColor.withAlpha((0.7 * 255).round()),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: textColor.withAlpha((0.7 * 255).round()),
                          ),
                          onTap: () =>
                              _showCurrencySelectionDialog(context, isDarkMode),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  _buildSectionHeader("Support", textColor),
                  _buildTile(
                    index: 3,
                    title: "Help & Feedback",
                    icon: Icons.help_outline,
                    cardColor: cardColor,
                    textColor: textColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Need help? Found a bug? We'd love to hear from you!",
                          style: TextStyle(
                            color: textColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Category selection for quick feedback
                        Text(
                          "Category:",
                          style: TextStyle(
                            color: textColor,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF263238),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF37474F),
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: _feedbackCategory,
                            isExpanded: true,
                            underline: const SizedBox(),
                            dropdownColor: const Color(0xFF263238),
                            style: const TextStyle(color: Color(0xFFE0E0E0), fontFamily: 'Poppins'),
                            items: const [
                              DropdownMenuItem(value: 'General', child: Text('General Question/Comment')),
                              DropdownMenuItem(value: 'Bug Report', child: Text('Bug Report')),
                              DropdownMenuItem(value: 'Feature Request', child: Text('Feature Request')),
                              DropdownMenuItem(value: 'Technical Support', child: Text('Technical Support')),
                              DropdownMenuItem(value: 'Account Issues', child: Text('Account Issues')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _feedbackCategory = value ?? 'General';
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _supportController,
                          maxLines: 3,
                          maxLength: 500,
                          style: TextStyle(
                            color: textColor,
                            fontFamily: 'Poppins',
                          ),
                          decoration: InputDecoration(
                            hintText: "Describe your issue or feedback...",
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontFamily: 'Poppins',
                            ),
                            fillColor: const Color(0xFF263238),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _isSubmittingSupport
                              ? const SizedBox(
                                  width: 120,
                                  height: 40,
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : _actionButton(
                                  "Send Feedback",
                                  icon: Icons.send,
                                  isDarkMode: isDarkMode,
                                  onTap: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final message = _supportController.text.trim();
                                    if (message.isEmpty) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text("Please enter your feedback before submitting."),
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      _isSubmittingSupport = true;
                                    });

                                    final ok = await FeedbackService.submitFeedback(
                                      feedback: message,
                                      category: _feedbackCategory,
                                    );

                                    setState(() {
                                      _isSubmittingSupport = false;
                                    });

                                    if (ok) {
                                      _supportController.clear();
                                      setState(() {
                                        _feedbackCategory = 'General';
                                      });
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text("Feedback sent. Thank you!"),
                                          backgroundColor: Color(0xFF00C853),
                                        ),
                                      );
                                    } else {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text("Failed to send feedback. Please try again."),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  _buildTile(
                    index: 4,
                    title: "About AgriSynch",
                    icon: Icons.info_outline,
                    cardColor: cardColor,
                    textColor: textColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow("Version:", "1.0", textColor),
                        _infoRow("Developer:", "Team AgriSynch", textColor),
                        _infoRow(
                          "Copyright:",
                          "©2025 All rights reserved",
                          textColor,
                        ),
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
                                content: const Text(
                                  "Final requirements BSIT SM 3307, 2024-2025. All rights reserved to @BatangasStateUniversity",
                                ),
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

                  const SizedBox(height: 24),
                ],
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
    IconData? icon,
    Widget? child,
  }) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            ? [Padding(padding: const EdgeInsets.all(12), child: child)]
            : [],
      ),
    );
  }

  Widget _buildQuickActions({required bool isDarkMode}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF37474F),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Actions",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _quickActionButton(
            "Notifications",
            _notificationsEnabled
                ? Icons.notifications_active
                : Icons.notifications_off_outlined,
            isDarkMode,
            () {
              setState(() {
                _notificationsEnabled = !_notificationsEnabled;
              });
              updatePreference('notifications', _notificationsEnabled);
            },
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(
    String label,
    IconData icon,
    bool isDarkMode,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF263238),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _notificationsEnabled ? const Color(0xFF1DBF73) : const Color(0xFF37474F),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _notificationsEnabled 
                      ? const Color(0xFF1DBF73).withAlpha((0.2 * 255).round())
                      : const Color(0xFF37474F).withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: _notificationsEnabled 
                      ? const Color(0xFF1DBF73)
                      : const Color(0xFF78909C),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _notificationsEnabled 
                      ? const Color(0xFF1DBF73)
                      : const Color(0xFF37474F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _notificationsEnabled ? 'ON' : 'OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop(); // Close dialog

              try {
                // Clear all local data
                final storage = const FlutterSecureStorage();
                await storage.deleteAll();

                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                // Reset theme to light mode
                await ThemeNotifier().resetTheme();

                // Sign out from Firebase
                await FirebaseAuth.instance.signOut();

                // Navigate to root (AuthWrapper) and clear all navigation history
                navigator.pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              } catch (e) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Error logging out. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
              style: TextStyle(color: textColor, fontFamily: 'Poppins'),
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
            : const Color(0xFF1DBF73),
        foregroundColor: isDestructive
            ? Colors.white
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: onTap ?? () {},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  Future<void> _showCurrencySelectionDialog(
    BuildContext context,
    bool isDarkMode,
  ) async {
    final currencies = CurrencyHelper.getAllCurrencies();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF263238),
          title: Text(
            'Select Currency',
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
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
                    backgroundColor: isDarkMode
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF00C853),
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
                      color: const Color(0xFFE0E0E0),
                      fontFamily: 'Poppins',
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${currency['code']} (${currency['symbol']})',
                    style: const TextStyle(
                      color: Color(0xFFB0BEC5),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: isDarkMode
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF00C853),
                        )
                      : null,
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    await CurrencyHelper.setCurrency(currency['code']!);
                    setState(() {
                      _selectedCurrency = currency['code']!;
                    });
                    if (!mounted) return;
                    navigator.pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

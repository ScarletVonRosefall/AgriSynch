import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/notification_helper.dart';
import '../shared/currency_helper.dart';
import '../shared/user_profile_widget.dart';
import '../shared/theme_helper.dart';
import '../shared/feedback_service.dart';
import '../services/review_service.dart';
import '../shared/farmer_reviews_page.dart';
import '../auth/auth_service.dart';

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
      bodyLarge: TextStyle(color: Color(0xFFE0E0E0), fontFamily: 'Poppins'),
      bodyMedium: TextStyle(color: Color(0xFFE0E0E0), fontFamily: 'Poppins'),
      titleLarge: TextStyle(color: Color(0xFFE0E0E0), fontFamily: 'Poppins'),
    ),
  );
}

class AgriSynchSettingsPage extends StatefulWidget {
  const AgriSynchSettingsPage({super.key});

  @override
  State<AgriSynchSettingsPage> createState() => _AgriSynchSettingsPageState();
}

class _AgriSynchSettingsPageState extends State<AgriSynchSettingsPage> {
  final List<bool> _expanded = List.generate(6, (_) => false);
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  int unreadNotifications = 0;
  String _selectedCurrency = 'PHP';
  final _themeNotifier = ThemeNotifier();
  int _profileRefreshKey = 0; // Key to force profile widget refresh

  String userName = '';
  String userEmail = '';
  String userRole = '';

  bool _isLoading = true;
  bool _isAdmin = false;
  
  // Feedback form controllers
  final TextEditingController _feedbackController = TextEditingController();
  String _feedbackCategory = 'General';
  bool _isSubmittingFeedback = false;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
    // Listen to theme changes
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload currency when returning to settings page
    _reloadCurrency();
  }

  Future<void> _reloadCurrency() async {
    try {
      final currentCurrency = await CurrencyHelper.getCurrentCurrency();
      if (mounted) {
        setState(() {
          _selectedCurrency = currentCurrency;
        });
      }
    } catch (e) {
      print('Error reloading currency: $e');
    }
  }

  Future<void> _initializeSettings() async {
    try {
      // Load user info first
      await loadUserInfo();
      
      // Check if user is admin
      _isAdmin = await AuthService.isCurrentUserAdmin();
      
      // Then load preferences and notifications in parallel
      await Future.wait<void>([
        loadPreferences(),
        Future.microtask(() => _loadUnreadNotifications()),
      ]);
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    _feedbackController.dispose();
    super.dispose();
  }

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
            userRole = data?['accountType'] ?? '';
          } else {
            // Fallback to Firebase Auth user data if Firestore doc doesn't exist
            userName = user.displayName ?? '';
            userEmail = user.email ?? '';
            userRole = 'Farmer'; // Default role
          }
        } catch (firestoreError) {
          print('Error fetching from Firestore: $firestoreError');
          // Fallback to Firebase Auth user data
          userName = user.displayName ?? '';
          userEmail = user.email ?? '';
          userRole = 'Farmer'; // Default role
        }
        
        // Also try to get name from local storage as backup
        if (userName.isEmpty) {
          String localName = await storage.read(key: 'user_name') ?? '';
          if (localName.isEmpty) {
            localName = await storage.read(key: 'name') ?? '';
          }
          userName = localName;
        }
        
        // Get role from local storage if not found in Firestore
        if (userRole.isEmpty) {
          userRole = await storage.read(key: 'account_type') ?? 'Farmer';
        }
      } else {
        // No user logged in, try local storage only
        String name = await storage.read(key: 'user_name') ?? '';
        if (name.isEmpty) {
          name = await storage.read(key: 'name') ?? '';
        }
        
        userName = name;
        userEmail = await storage.read(key: 'user_email') ?? '';
        userRole = await storage.read(key: 'account_type') ?? '';
      }
    } catch (e) {
      print('Error loading user info: $e');
      // Fallback to empty strings if everything fails
      userName = '';
      userEmail = '';
      userRole = '';
    }
    
    setState(() {});
  }

  Future<void> loadPreferences() async {
    try {
      final results = await Future.wait([
        SharedPreferences.getInstance(),
        CurrencyHelper.getCurrentCurrency(),
      ]);
      
      final prefs = results[0] as SharedPreferences;
      final currentCurrency = results[1] as String;
      
      if (mounted) {
        setState(() {
          _notificationsEnabled = prefs.getBool('notifications') ?? true;
          _darkModeEnabled = _themeNotifier.isDarkMode; // Use ThemeNotifier instead
          _selectedCurrency = currentCurrency;
        });
      }
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final count = await NotificationHelper.getUnreadCount();
      if (mounted) {
        setState(() {
          unreadNotifications = count;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> updatePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      print('Error updating preference: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update setting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Debounce expansion changes to prevent rapid state updates
  DateTime _lastExpansionChange = DateTime.now();
  static const _expansionThrottle = Duration(milliseconds: 200);

  void _handleExpansionChanged(int index, bool isExpanded) {
    final now = DateTime.now();
    if (now.difference(_lastExpansionChange) < _expansionThrottle) {
      return;
    }
    _lastExpansionChange = now;
    
    if (mounted) {
      setState(() {
        _expanded[index] = isExpanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    final backgroundColor = ThemeHelper.getBackgroundColor(isDarkMode);
    final cardColor = ThemeHelper.getCardColor(isDarkMode);
    final textColor = ThemeHelper.getTextColor(isDarkMode);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00C853),
              ),
            )
          : Column(
        children: [
          // --- Top Green Header ---
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            width: double.infinity,
            decoration: ThemeHelper.getHeaderDecoration(isDark: isDarkMode),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: ThemeHelper.getHeaderTextStyle(isDark: isDarkMode),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage account & preferences',
                            style: ThemeHelper.getSubHeaderTextStyle(isDark: isDarkMode),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 42,
                  decoration: ThemeHelper.getContainerDecoration(isDark: isDarkMode),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: ThemeHelper.getIconColor(isDarkMode)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search settings...',
                            border: InputBorder.none,
                            hintStyle: ThemeHelper.getHintTextStyle(isDark: isDarkMode),
                          ),
                          style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Main Content ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                  // User Profile Section
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: ThemeHelper.getContainerDecoration(isDark: isDarkMode),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: ThemeHelper.getHeaderColor(isDarkMode), size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'My Profile',
                              style: ThemeHelper.getTextStyle(
                                isDark: isDarkMode,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                customColor: ThemeHelper.getHeaderColor(isDarkMode),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: ThemeHelper.getHeaderColor(isDarkMode),
                                size: 20,
                              ),
                              onPressed: () async {
                                await Navigator.pushNamed(context, '/profile');
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
                        const SizedBox(height: 12),
                        UserProfileWidget(
                          key: ValueKey(_profileRefreshKey),
                          showEmail: true,
                          showLocation: true,
                          imageSize: 60,
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
                        const SizedBox(height: 12),
                        // Farmer Rating Display - Real-time from reviews
                        StreamBuilder(
                          stream: ReviewService.getFarmerReviewsStream(
                            FirebaseAuth.instance.currentUser?.uid ?? ''
                          ),
                          builder: (context, snapshot) {
                            // Calculate rating from reviews in real-time
                            double rating = 0.0;
                            int reviewCount = 0;
                            
                            if (snapshot.hasData && snapshot.data != null) {
                              final reviews = snapshot.data!;
                              reviewCount = reviews.length;
                              
                              if (reviews.isNotEmpty) {
                                double totalRating = 0;
                                for (var review in reviews) {
                                  totalRating += review.rating;
                                }
                                rating = totalRating / reviews.length;
                              }
                            }
                            
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your Rating',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 20),
                                          const SizedBox(width: 4),
                                          Text(
                                            rating > 0 ? rating.toStringAsFixed(1) : 'No ratings yet',
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (rating > 0) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              '($reviewCount ${reviewCount == 1 ? 'review' : 'reviews'})',
                                              style: TextStyle(
                                                color: textColor.withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FarmerReviewsPage(
                                            farmerId: FirebaseAuth.instance.currentUser?.uid ?? '',
                                            farmerName: userName,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'View Reviews',
                                      style: TextStyle(
                                        color: Color(0xFF4CAF50),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            // Admin Dashboard Button (only visible to admins)
                            if (_isAdmin) ...[
                              SizedBox(
                                width: double.infinity,
                                child: _actionButton(
                                  "Admin Dashboard",
                                  icon: Icons.admin_panel_settings,
                                  isDarkMode: isDarkMode,
                                  onTap: () {
                                    Navigator.pushNamed(context, '/admin-dashboard');
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
                                "Request Account Deletion",
                                icon: Icons.delete_forever,
                                isDarkMode: isDarkMode,
                                isDestructive: true,
                                onTap: () {
                                  _showDeletionRequestDialog();
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
                            "Receive alerts for tasks and orders",
                            style: TextStyle(
                              color: textColor.withOpacity(0.7),
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
                    title: "Appearance",
                    icon: Icons.palette_outlined,
                    cardColor: cardColor,
                    textColor: textColor,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text(
                            "Dark Mode",
                            style: TextStyle(
                              color: textColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          subtitle: Text(
                            "Use dark theme for better visibility",
                            style: TextStyle(
                              color: textColor.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          value: _darkModeEnabled,
                          activeThumbColor: const Color(0xFF00C853),
                          onChanged: (value) async {
                            setState(() {
                              _darkModeEnabled = value;
                            });
                            await _themeNotifier.setDarkMode(value);
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
                            style: TextStyle(
                              color: textColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          subtitle: Text(
                            "${CurrencyHelper.getCurrencyName(_selectedCurrency)} (${CurrencyHelper.getCurrencySymbol(_selectedCurrency)})",
                            style: TextStyle(
                              color: textColor.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: textColor.withOpacity(0.7),
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
                          style: TextStyle(
                            color: textColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Category Selection
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                              ),
                              child: DropdownButton<String>(
                                value: _feedbackCategory,
                                isExpanded: true,
                                underline: const SizedBox(),
                                dropdownColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                                style: TextStyle(color: textColor, fontFamily: 'Poppins'),
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
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Feedback Text Field
                        TextFormField(
                          controller: _feedbackController,
                          maxLines: 4,
                          maxLength: 500,
                          style: TextStyle(
                            color: textColor,
                            fontFamily: 'Poppins',
                          ),
                          decoration: InputDecoration(
                            hintText: "Describe your issue or feedback in detail...",
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              fontFamily: 'Poppins',
                            ),
                            fillColor: isDarkMode
                                ? const Color(0xFF2A2A2A)
                                : Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF4CAF50),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // Submit Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: _isSubmittingFeedback
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isDarkMode ? Colors.white : Colors.black,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Sending...",
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _actionButton(
                                  "Send Feedback",
                                  icon: Icons.send,
                                  isDarkMode: isDarkMode,
                                  onTap: _submitFeedback,
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
                        _infoRow(
                          "Copyright:",
                          "© 2025 All rights reserved",
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
        onExpansionChanged: (val) => _handleExpansionChanged(index, val),
        children: child != null
            ? [Padding(padding: const EdgeInsets.all(12), child: child)]
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
                  _notificationsEnabled
                      ? Icons.notifications
                      : Icons.notifications_off,
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
                  () async {
                    setState(() {
                      _darkModeEnabled = !_darkModeEnabled;
                    });
                    await _themeNotifier.setDarkMode(_darkModeEnabled);
                  },
                ),
              ),
            ],
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
              color: isDarkMode
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF00C853),
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

  Future<void> _showDeletionRequestDialog() async {
    final TextEditingController reasonController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Request Account Deletion",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Please provide a reason for deletion:",
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "e.g., No longer need the app, Privacy concerns, etc.",
                hintStyle: const TextStyle(fontFamily: 'Poppins'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Note: Your request will be reviewed by an admin. You will be notified of the decision.",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              reasonController.dispose();
              Navigator.pop(context, false);
            },
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Submit Request',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      reasonController.dispose();
      return;
    }

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for deletion'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    setState(() => _isLoading = true);

    try {
      final success = await AuthService.submitDeletionRequest(reason);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deletion request submitted successfully. An admin will review it shortly.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit deletion request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      setState(() => _isLoading = true);

      // Clear all stored data
      await Future.wait([
        storage.deleteAll(),
        SharedPreferences.getInstance().then((prefs) => prefs.clear()),
        FirebaseAuth.instance.signOut(),
      ]);

      if (!mounted) return;

      // Navigate to root (AuthWrapper) which will show login page
      await Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error logging out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
            : (isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFFDCE775)),
        foregroundColor: isDestructive
            ? Colors.white
            : (isDarkMode ? Colors.white : Colors.black),
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
          backgroundColor: isDarkMode ? const Color(0xFF263238) : Colors.white,
          title: Text(
            'Select Currency',
            style: TextStyle(
              color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
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
                      color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                      fontFamily: 'Poppins',
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${currency['code']} (${currency['symbol']})',
                    style: TextStyle(
                      color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.black54,
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
                  color: isDarkMode
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF00C853),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter your feedback before submitting."),
          backgroundColor: Colors.orange.shade600,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingFeedback = true;
    });

    try {
      final success = await FeedbackService.submitFeedback(
        feedback: _feedbackController.text.trim(),
        category: _feedbackCategory,
        // No priority parameter - will use default "Medium"
      );

      if (success) {
        // Clear the form
        _feedbackController.clear();
        setState(() {
          _feedbackCategory = 'General';
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Feedback sent successfully! Thank you for helping us improve AgriSynch."),
            backgroundColor: Color(0xFF00C853),
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to send feedback. Please try again later."),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      print('Error submitting feedback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("An error occurred while sending feedback. Please check your connection and try again."),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingFeedback = false;
        });
      }
    }
  }
}

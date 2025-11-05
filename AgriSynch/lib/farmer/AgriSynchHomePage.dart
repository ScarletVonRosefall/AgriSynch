import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AgriSynchCalendarPage.dart';
import 'AgriFinances.dart';
import 'AgriCustomersPage.dart';
import '../shared/AgriWeatherPage.dart';
import 'AgriSynchProductionLogPage.dart';
import '../shared/weather_helper.dart';
import '../shared/theme_helper.dart';
import '../shared/notification_helper.dart';
import '../shared/AgriNotificationPage.dart';
import '../auth/auth_service.dart';
import 'dart:convert';
import 'dart:async';

class AgriSynchHomePage extends StatefulWidget {
  const AgriSynchHomePage({super.key});

  @override
  State<AgriSynchHomePage> createState() => _AgriSynchHomePageState();
}

class _AgriSynchHomePageState extends State<AgriSynchHomePage> {
  final storage = FlutterSecureStorage();
  final _themeNotifier = ThemeNotifier();

  // Data for summary
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> orders = [];
  int unreadNotifications = 0;
  WeatherData? currentWeather;

  bool _isLoading = true;
  bool _needsReload = false;
  Timer? _debounceTimer;
  Timer? _refreshTimer;
  Timer? _reloadTimer;

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    _initializeData();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _refreshTimer?.cancel();
    _reloadTimer?.cancel();
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Load most essential data first with timeout
      await Future.wait([
        loadTheme(),
      ]).timeout(const Duration(seconds: 3));

      if (!mounted) return;

      // Load primary data with timeout
      await Future.wait([
        loadTasksAndOrders(),
        loadUnreadNotifications(),
      ]).timeout(const Duration(seconds: 5));

      if (!mounted) return;

      // Set up periodic refresh for notifications and tasks
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _refreshData(),
      );

      // Load non-critical data last
      _loadNonCriticalData();
    } catch (e) {
      // Handle initialization errors gracefully
      if (!mounted) return;
      _handleLoadError();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleLoadError() {
    setState(() {
      tasks = [];
      orders = [];
      // Theme is now handled by ThemeNotifier
    });
  }

  Future<void> _refreshData() async {
    if (!mounted || _isLoading) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        await Future.wait([
          loadTasksAndOrders(),
          loadUnreadNotifications(),
        ]).timeout(const Duration(seconds: 5));
      } catch (e) {
        // Handle refresh errors silently
      }
    });
  }

  Future<void> _loadNonCriticalData() async {
    if (!mounted) return;

    try {
      await Future.wait([
        loadWeather(),
        checkAndCreateSampleNotifications(),
      ]).timeout(const Duration(seconds: 10));
    } catch (e) {
      // Handle non-critical data load errors silently
    }
  }

  // Load the current theme setting (dark/light mode)
  Future<void> loadTheme() async {
    if (!mounted) return;
    // Theme is now handled by ThemeNotifier, no need to load manually
  }

  // Load tasks and orders data for dashboard statistics
  Future<void> loadTasksAndOrders() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load tasks
      final savedTasks = prefs.getString('tasks');
      final newTasks = savedTasks != null
          ? List<Map<String, dynamic>>.from(json.decode(savedTasks))
          : <Map<String, dynamic>>[];

      // Load orders
      final savedOrders = prefs.getString('orders');
      final newOrders = savedOrders != null
          ? List<Map<String, dynamic>>.from(json.decode(savedOrders))
          : <Map<String, dynamic>>[];

      // Only update state if data has changed
      if (!mounted) return;
      
      if (!_areListsEqual(tasks, newTasks) || !_areListsEqual(orders, newOrders)) {
        setState(() {
          tasks = newTasks;
          orders = newOrders;
        });
      }
    } catch (e) {
      // Handle load errors silently but ensure we have valid lists
      if (mounted) {
        setState(() {
          tasks = [];
          orders = [];
        });
      }
    }
  }

  bool _areListsEqual(List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (!_areMapContentsEqual(list1[i], list2[i])) return false;
    }
    return true;
  }

  bool _areMapContentsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    return json.encode(map1) == json.encode(map2);
  }

  // Update data when user returns to homepage
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_needsReload && !_isLoading) {
      _needsReload = false;
      // Schedule reload for next frame to avoid immediate heavy loading
      _reloadTimer?.cancel();
      _reloadTimer = Timer(const Duration(milliseconds: 100), () {
        if (mounted) {
          _refreshData();
        }
      });
    }
  }

  // Load count of unread notifications
  Future<void> loadUnreadNotifications() async {
    unreadNotifications = await NotificationHelper.getUnreadCount();
    setState(() {});
  }

  // Fetch current weather data for the dashboard
  Future<void> loadWeather() async {
    if (!mounted) return;

    try {
      final weather = await WeatherHelper.getCurrentWeather().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Weather data load timeout'),
      );
      
      if (!mounted) return;
      
      setState(() {
        currentWeather = weather;
      });
    } catch (e) {
      // Silently fail - weather is optional
      if (mounted) {
        setState(() {
          currentWeather = null;
        });
      }
    }
  }

  // Build the weather card widget for homepage
  Widget _buildWeatherCard() {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AgriWeatherPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF263238) : Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [const Color(0xFF37474F), const Color(0xFF263238)]
                : [Colors.blue[100]!, Colors.blue[50]!],
          ),
        ),
        child: Row(
          children: [
            // Weather Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1976D2) : Colors.blue[600],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                currentWeather != null
                    ? _getWeatherIconData(currentWeather!.description)
                    : Icons.wb_sunny,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),

            // Weather Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weather',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (currentWeather != null) ...[
                    Text(
                      '${currentWeather!.temperature}°C',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? const Color(0xFF64B5F6) : Colors.blue[700],
                      ),
                    ),
                    Text(
                      currentWeather!.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.grey[600],
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Check task deadlines and create welcome notifications
  Future<void> checkAndCreateSampleNotifications() async {
    // Check for task deadlines
    await NotificationHelper.checkTaskDeadlines();

    // Create a welcome notification if it's the first time
    final prefs = await SharedPreferences.getInstance();
    final hasWelcomeNotification =
        prefs.getBool('welcome_notification_sent') ?? false;

    if (!hasWelcomeNotification) {
      await NotificationHelper.addNotification(
        title: 'Welcome to AgriSynch! 🌱',
        message:
            'Start managing your agricultural tasks and orders efficiently.',
        type: NotificationHelper.systemNotification,
      );
      await prefs.setBool('welcome_notification_sent', true);
    }

    loadUnreadNotifications();
  }

  // Get time-appropriate greeting message
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  // Build quick stat cards for dashboard
  Widget _buildQuickStat(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Build the homepage UI with fixed header and scrollable content
  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      body: Column(
        children: [
          // --- Fixed Top Green Header ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            width: double.infinity,
            decoration: ThemeHelper.getHeaderDecoration(isDark: isDarkMode),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildProfileAvatar(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGreetingText(),
                          Text(
                            "Let's Get Tasks Done!",
                            style: ThemeHelper.getSubHeaderTextStyle(
                              isDark: isDarkMode,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AgriNotificationPage(),
                                ),
                              );
                              // Reload notification count when returning
                              loadUnreadNotifications();
                            },
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        if (unreadNotifications > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unreadNotifications > 9
                                    ? '9+'
                                    : unreadNotifications.toString(),
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
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Today is ${DateFormat.yMMMMd().format(DateTime.now())}",
                  style: ThemeHelper.getSubHeaderTextStyle(isDark: isDarkMode),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),

          // --- Scrollable Content ---
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // --- Quick Stats Row ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildQuickStat(
                          "Total Tasks",
                          "${tasks.length}",
                          Icons.assignment,
                          Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildQuickStat(
                          "Completed",
                          "${tasks.where((t) => t['done'] == true).length}",
                          Icons.check_circle,
                          Colors.green,
                        ),
                        const SizedBox(width: 12),
                        _buildQuickStat(
                          "Orders",
                          "${orders.length}",
                          Icons.shopping_cart,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Summary Card ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF00E676),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode 
                                ? Colors.black.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Today's Summary",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "• ${tasks.length} Total Tasks",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  "• ${tasks.where((t) => t['done'] == true).length} Completed",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  "• ${tasks.where((t) => t['done'] != true).length} Pending",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  "• ${orders.length} Active Orders",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.eco,
                                color: Colors.orange,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- Weather Card ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildWeatherCard(),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "Jump Into Our Work!",
                      style: ThemeHelper.getTextStyle(
                        isDark: isDarkMode,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // --- Tile List ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _homeTile(
                          icon: Icons.calendar_month,
                          title: "Calendar",
                          onTap: () async {
                            try {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AgriSynchCalendarPage(),
                                ),
                              );
                              if (mounted) {
                                _needsReload = true;
                              }
                            } catch (e) {
                              // Handle navigation error silently
                            }
                          },
                        ),
                        _homeTile(
                          icon: Icons.attach_money,
                          title: "Finances",
                          onTap: () async {
                            try {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AgriFinances(),
                                ),
                              );
                              if (mounted) {
                                _needsReload = true;
                              }
                            } catch (e) {
                              // Handle navigation error silently
                            }
                          },
                        ),
                        _homeTile(
                          icon: Icons.engineering,
                          title: "Production Log",
                          onTap: () async {
                            try {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AgriSynchProductionLog(),
                                ),
                              );
                              if (mounted) {
                                _needsReload = true;
                              }
                            } catch (e) {
                              // Handle navigation error silently
                            }
                          },
                        ),
                        _homeTile(
                          icon: Icons.people_alt,
                          title: "Customers",
                          onTap: () async {
                            try {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AgriCustomersPage(),
                                ),
                              );
                              if (mounted) {
                                _needsReload = true;
                              }
                            } catch (e) {
                              // Handle navigation error silently
                            }
                          },
                        ),
                        const SizedBox(height: 20),
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

  Widget _homeTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: isDarkMode ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.white,
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _getWeatherIconData(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('sunny') || desc.contains('clear')) {
      return Icons.wb_sunny;
    } else if (desc.contains('cloud')) {
      return Icons.cloud;
    } else if (desc.contains('rain')) {
      return Icons.grain;
    } else if (desc.contains('storm')) {
      return Icons.flash_on;
    } else if (desc.contains('snow')) {
      return Icons.ac_unit;
    } else if (desc.contains('wind')) {
      return Icons.air;
    } else {
      return Icons.wb_sunny;
    }
  }

  Widget _buildProfileAvatar() {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return FutureBuilder<Map<String, String?>>(
      future: _loadUserProfileData(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final profileImageBase64 = snapshot.data!['profileImage'];
          if (profileImageBase64 != null && profileImageBase64.isNotEmpty) {
            return Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: Image.memory(
                  base64Decode(profileImageBase64),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            );
          }
        }
        
        // Default avatar
        return CircleAvatar(
          backgroundColor: ThemeHelper.getHeaderColor(isDarkMode),
          radius: 20,
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 24,
          ),
        );
      },
    );
  }

  Widget _buildGreetingText() {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return FutureBuilder<Map<String, String?>>(
      future: _loadUserProfileData(),
      builder: (context, snapshot) {
        String displayName = '';
        if (snapshot.hasData) {
          final data = snapshot.data!;
          displayName = data['name'] ?? data['nickname'] ?? '';
        }
        
        return Text(
          "${_getGreeting()}${displayName.isNotEmpty ? ' $displayName' : ''}!",
          style: ThemeHelper.getHeaderTextStyle(
            isDark: isDarkMode,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      },
    );
  }

  Future<Map<String, String?>> _loadUserProfileData() async {
    try {
      // Import auth service here to load from Firebase
      final userData = await AuthService.getUserData();

      if (userData != null && userData.exists) {
        final data = userData.data() as Map<String, dynamic>;
        return {
          'name': data['name'] ?? '',
          'nickname': data['nickname'] ?? '',
          'profileImage': data['profileImage'] ?? '',
        };
      } else {
        // Fallback to local storage
        final name = await storage.read(key: 'user_name') ?? 
                     await storage.read(key: 'name') ?? '';
        final nickname = await storage.read(key: 'user_nickname') ?? '';
        final profileImage = await storage.read(key: 'profile_image') ?? '';
        
        return {
          'name': name,
          'nickname': nickname,
          'profileImage': profileImage,
        };
      }
    } catch (e) {
      return {
        'name': '',
        'nickname': '',
        'profileImage': '',
      };
    }
  }
}

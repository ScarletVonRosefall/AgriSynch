import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AgriSynchCalendarPage.dart';
import 'AgriFinances.dart';
import 'AgriCustomersPage.dart';
import 'AgriWeatherPage.dart';
import 'AgriSynchProductionLogPage.dart';
import 'weather_helper.dart';
import 'theme_helper.dart';
import 'notification_helper.dart';
import 'AgriNotificationPage.dart';
import 'dart:convert';

class AgriSynchHomePage
    extends
        StatefulWidget {
  const AgriSynchHomePage({
    super.key,
  });

  @override
  State<
    AgriSynchHomePage
  >
  createState() => _AgriSynchHomePageState();
}

class _AgriSynchHomePageState
    extends
        State<
          AgriSynchHomePage
        > {
  final storage = FlutterSecureStorage();
  String userName = '';
  bool isDarkMode = false;

  // Data for summary
  List<
    Map<
      String,
      dynamic
    >
  >
  tasks = [];
  List<
    Map<
      String,
      dynamic
    >
  >
  orders = [];
  int unreadNotifications = 0;
  WeatherData? currentWeather;

  // Initialize the homepage when widget is first created
  @override
  void initState() {
    super.initState();
    loadUserName();
    loadTheme();
    loadTasksAndOrders();
    loadUnreadNotifications();
    loadWeather();
    checkAndCreateSampleNotifications();
  }

  // Load user's name from secure storage
  Future<
    void
  >
  loadUserName() async {
    userName =
        await storage.read(
          key: 'name',
        ) ??
        '';
    setState(
      () {},
    );
  }

  // Load the current theme setting (dark/light mode)
  Future<
    void
  >
  loadTheme() async {
    isDarkMode = await ThemeHelper.isDarkModeEnabled();
    setState(
      () {},
    );
  }

  // Load tasks and orders data for dashboard statistics
  Future<
    void
  >
  loadTasksAndOrders() async {
    final prefs = await SharedPreferences.getInstance();

    // Load tasks
    final savedTasks = prefs.getString(
      'tasks',
    );
    if (savedTasks !=
        null) {
      tasks =
          List<
            Map<
              String,
              dynamic
            >
          >.from(
            json.decode(
              savedTasks,
            ),
          );
    }

    // Load orders
    final savedOrders = prefs.getString(
      'orders',
    );
    if (savedOrders !=
        null) {
      orders =
          List<
            Map<
              String,
              dynamic
            >
          >.from(
            json.decode(
              savedOrders,
            ),
          );
    }

    setState(
      () {},
    );
  }

  // Update data when user returns to homepage
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data and theme when returning to this page
    loadTheme();
    loadTasksAndOrders();
    loadUnreadNotifications();
  }

  // Load count of unread notifications
  Future<
    void
  >
  loadUnreadNotifications() async {
    unreadNotifications = await NotificationHelper.getUnreadCount();
    setState(
      () {},
    );
  }

  // Fetch current weather data for the dashboard
  Future<void> loadWeather() async {
    try {
      final weather = await WeatherHelper.getCurrentWeather();
      setState(() {
        currentWeather = weather;
      });
    } catch (e) {
      // Silently fail - weather is optional
      setState(() {
        currentWeather = null;
      });
    }
  }

  // Build the weather card widget for homepage
  Widget _buildWeatherCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AgriWeatherPage(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.grey[850]!, Colors.grey[800]!]
                : [Colors.blue[100]!, Colors.blue[50]!],
          ),
        ),
        child: Row(
          children: [
            // Weather Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.blue[700] : Colors.blue[600],
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
                      color: isDarkMode ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (currentWeather != null) ...[
                    Text(
                      '${currentWeather!.temperature}°C',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                      ),
                    ),
                    Text(
                      currentWeather!.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
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
        prefs.getBool(
          'welcome_notification_sent',
        ) ??
        false;

    if (!hasWelcomeNotification) {
      await NotificationHelper.addNotification(
        title: 'Welcome to AgriSynch! 🌱',
        message: 'Start managing your agricultural tasks and orders efficiently.',
        type: NotificationHelper.systemNotification,
      );
      await prefs.setBool(
        'welcome_notification_sent',
        true,
      );
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
  Widget _buildQuickStat(String title, String value, IconData icon, Color color) {
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
            Icon(
              icon,
              color: color,
              size: 24,
            ),
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
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(
        isDarkMode,
      ),
      body: Column(
        children: [
          // --- Fixed Top Green Header ---
          Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              40,
              20,
              20,
            ),
            width: double.infinity,
            decoration: ThemeHelper.getHeaderDecoration(
              isDark: isDarkMode,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage(
                        'assets/user_avatar.png',
                      ),
                      radius: 20,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${_getGreeting()}${userName.isNotEmpty ? ' $userName' : ''}!",
                          style: ThemeHelper.getHeaderTextStyle(
                            isDark: isDarkMode,
                          ),
                        ),
                        Text(
                          "Let's Get Tasks Done!",
                          style: ThemeHelper.getSubHeaderTextStyle(
                            isDark: isDarkMode,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              0.2,
                            ),
                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (
                                        _,
                                      ) => const AgriNotificationPage(),
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
                        if (unreadNotifications >
                            0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(
                                2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(
                                  10,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unreadNotifications >
                                        9
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
                const SizedBox(
                  height: 10,
                ),
                Text(
                  "Today is ${DateFormat.yMMMMd().format(DateTime.now())}",
                  style: ThemeHelper.getSubHeaderTextStyle(
                    isDark: isDarkMode,
                  ),
                ),
              ],
            ),
          ),

          // --- Scrollable Content ---
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),

                  // --- Quick Stats Row ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildQuickStat(
                          "Total Tasks", 
                          "${tasks.length}", 
                          Icons.assignment, 
                          Colors.blue
                        ),
                        const SizedBox(width: 12),
                        _buildQuickStat(
                          "Completed", 
                          "${tasks.where((t) => t['done'] == true).length}", 
                          Icons.check_circle, 
                          Colors.green
                        ),
                        const SizedBox(width: 12),
                        _buildQuickStat(
                          "Orders", 
                          "${orders.length}", 
                          Icons.shopping_cart, 
                          Colors.orange
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // --- Summary Card ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(
                        16,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(
                                0xFF4CAF50,
                              )
                            : const Color(
                                0xFF00E676,
                              ),
                        borderRadius: BorderRadius.circular(
                          18,
                        ),
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
                                const SizedBox(
                                  height: 6,
                                ),
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

                  const SizedBox(
                    height: 20,
                  ),

                  // --- Weather Card ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: _buildWeatherCard(),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                    ),
                    child: Text(
                      "Jump Into Our Work!",
                      style: ThemeHelper.getTextStyle(
                        isDark: isDarkMode,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // --- Tile List ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                    ),
                    child: Column(
                      children: [
                        _homeTile(
                          icon: Icons.calendar_month,
                          title: "Calendar",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (
                                      _,
                                    ) => const AgriSynchCalendarPage(),
                              ),
                            );
                          },
                        ),
                        _homeTile(
                          icon: Icons.attach_money,
                          title: "Finances",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (
                                      _,
                                    ) => const AgriFinances(),
                              ),
                            );
                          },
                        ),
                        _homeTile(
                          icon: Icons.engineering,
                          title: "Production Log",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AgriSynchProductionLog(),
                              ),
                            );
                          },
                        ),
                        _homeTile(
                          icon: Icons.people_alt,
                          title: "Customers",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (
                                      _,
                                    ) => const AgriCustomersPage(),
                              ),
                            );
                          },
                        ),
                        // Add some bottom padding
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
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          16,
        ),
      ),
      elevation: 2,
      color: isDarkMode
          ? const Color(
              0xFF2E7D32,
            )
          : const Color(
              0xFF4CAF50,
            ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
        ),
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
}



import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AgriSynchCalendarPage.dart';
import 'theme_helper.dart';
import 'notification_helper.dart';
import 'notifications_page.dart';
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

class _AgriSynchHomePageState extends State<AgriSynchHomePage> {
  final storage = FlutterSecureStorage();
  String userName = '';
  bool isDarkMode = false;
  
  // Data for summary
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> orders = [];
  int unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    loadUserName();
    loadTheme();
    loadTasksAndOrders();
    loadUnreadNotifications();
    checkAndCreateSampleNotifications();
  }

  Future<void> loadUserName() async {
    userName = await storage.read(key: 'name') ?? '';
    setState(() {});
  }

  Future<void> loadTheme() async {
    isDarkMode = await ThemeHelper.isDarkModeEnabled();
    setState(() {});
  }

  Future<void> loadTasksAndOrders() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load tasks
    final savedTasks = prefs.getString('tasks');
    if (savedTasks != null) {
      tasks = List<Map<String, dynamic>>.from(json.decode(savedTasks));
    }
    
    // Load orders
    final savedOrders = prefs.getString('orders');
    if (savedOrders != null) {
      orders = List<Map<String, dynamic>>.from(json.decode(savedOrders));
    }
    
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this page
    loadTasksAndOrders();
    loadUnreadNotifications();
  }

  Future<void> loadUnreadNotifications() async {
    unreadNotifications = await NotificationHelper.getUnreadCount();
    setState(() {});
  }

  Future<void> checkAndCreateSampleNotifications() async {
    // Check for task deadlines
    await NotificationHelper.checkTaskDeadlines();
    
    // Create a welcome notification if it's the first time
    final prefs = await SharedPreferences.getInstance();
    final hasWelcomeNotification = prefs.getBool('welcome_notification_sent') ?? false;
    
    if (!hasWelcomeNotification) {
      await NotificationHelper.addNotification(
        title: 'Welcome to AgriSynch! 🌱',
        message: 'Start managing your agricultural tasks and orders efficiently.',
        type: NotificationHelper.systemNotification,
      );
      await prefs.setBool('welcome_notification_sent', true);
    }
    
    loadUnreadNotifications();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      body: Column(
        children: [
          // --- Top Green Header ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            width: double.infinity,
            decoration: ThemeHelper.getHeaderDecoration(isDark: isDarkMode),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage('assets/user_avatar.png'),
                      radius: 20,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Good Morning${userName.isNotEmpty ? ' $userName' : ''}!",
                          style: ThemeHelper.getHeaderTextStyle(isDark: isDarkMode),
                        ),
                        Text(
                          "Let's Get Tasks Done!",
                          style: ThemeHelper.getSubHeaderTextStyle(isDark: isDarkMode),
                        ),
                      ],
                    ),
                    const Spacer(),
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
                                  builder: (_) => const NotificationsPage(),
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
                                unreadNotifications > 9 ? '9+' : unreadNotifications.toString(),
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
                ),
                const SizedBox(height: 12),
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // --- Summary Card ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF00E676),
                borderRadius: BorderRadius.circular(18),
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _homeTile(
                  icon: Icons.calendar_month,
                  title: "Calendar",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AgriSynchCalendarPage(),
                      ),
                    );
                  },
                ),
                _homeTile(
                  icon: Icons.attach_money,
                  title: "Finances",
                ),
                _homeTile(
                  icon: Icons.engineering,
                  title: "Production Log",
                ),
                _homeTile(
                  icon: Icons.people_alt,
                  title: "Customers",
                ),
              ],
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      color: isDarkMode ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50),
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
}

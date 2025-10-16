import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/AgriWeatherPage.dart';
import '../shared/weather_helper.dart';
import '../shared/theme_helper.dart';
import '../shared/notification_helper.dart';
import '../shared/AgriNotificationPage.dart';
import 'AgriSynchBuyerSettingsPage.dart';
import 'BrowseProductsPage.dart';
import 'ShoppingCartPage.dart';
import 'MyOrdersPage.dart';
import 'DeliveryTrackingPage.dart';
import 'dart:convert';

class AgriSynchBuyerHomePage extends StatefulWidget {
  const AgriSynchBuyerHomePage({super.key});

  @override
  State<AgriSynchBuyerHomePage> createState() => _AgriSynchBuyerHomePageState();
}

class _AgriSynchBuyerHomePageState extends State<AgriSynchBuyerHomePage> {
  final storage = FlutterSecureStorage();
  String userName = '';
  bool isDarkMode = false;
  final int _selectedIndex = 0;

  // Data for buyer dashboard
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> cart = [];
  int unreadNotifications = 0;
  WeatherData? currentWeather;

  @override
  void initState() {
    super.initState();
    loadUserName();
    loadTheme();
    loadBuyerData();
    loadUnreadNotifications();
    loadWeather();
    checkAndCreateWelcomeNotification();
  }

  // Load user's name from secure storage
  Future<void> loadUserName() async {
    userName = await storage.read(key: 'name') ?? '';
    setState(() {});
  }

  // Load the current theme setting
  Future<void> loadTheme() async {
    isDarkMode = await ThemeHelper.isDarkModeEnabled();
    setState(() {});
  }

  // Load buyer-specific data (orders, cart)
  Future<void> loadBuyerData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load orders
    final savedOrders = prefs.getString('buyer_orders');
    if (savedOrders != null) {
      orders = List<Map<String, dynamic>>.from(json.decode(savedOrders));
    }

    // Load cart
    final savedCart = prefs.getString('buyer_cart');
    if (savedCart != null) {
      cart = List<Map<String, dynamic>>.from(json.decode(savedCart));
    }

    setState(() {});
  }

  // Update data when user returns to homepage
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadTheme();
    loadBuyerData();
    loadUnreadNotifications();
  }

  // Load count of unread notifications
  Future<void> loadUnreadNotifications() async {
    unreadNotifications = await NotificationHelper.getUnreadCount();
    setState(() {});
  }

  // Fetch current weather data
  Future<void> loadWeather() async {
    try {
      final weather = await WeatherHelper.getCurrentWeather();
      setState(() {
        currentWeather = weather;
      });
    } catch (e) {
      setState(() {
        currentWeather = null;
      });
    }
  }

  // Create welcome notification for buyers
  Future<void> checkAndCreateWelcomeNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final hasWelcomeNotification = prefs.getBool('buyer_welcome_notification_sent') ?? false;

    if (!hasWelcomeNotification) {
      await NotificationHelper.addNotification(
        title: 'Welcome to AgriSynch Marketplace! 🛒',
        message: 'Discover fresh agricultural products from local farmers.',
        type: NotificationHelper.systemNotification,
      );
      await prefs.setBool('buyer_welcome_notification_sent', true);
    }

    loadUnreadNotifications();
  }

  // Get time-appropriate greeting
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

  // Build weather card
  Widget _buildWeatherCard() {
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weather Today',
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

  // Build quick stat cards for buyer dashboard
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

  // Handle bottom navigation tab selection
  void _onItemTapped(int index) {
    if (index == 1) {
      // Navigate to Settings
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AgriSynchBuyerSettingsPage()),
      ).then((_) {
        // Reload theme and data when returning from settings
        loadTheme();
        loadBuyerData();
        loadUnreadNotifications();
      });
    }
    // Index 0 is Home - already on this page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      body: Column(
        children: [
          // Fixed Top Header
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
                          "${_getGreeting()}${userName.isNotEmpty ? ' $userName' : ''}!",
                          style: ThemeHelper.getHeaderTextStyle(isDark: isDarkMode),
                        ),
                        Text(
                          "Welcome to AgriSynch Marketplace!",
                          style: ThemeHelper.getSubHeaderTextStyle(isDark: isDarkMode),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Notification Button (removed settings button since it's now in bottom nav)
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
                                MaterialPageRoute(builder: (_) => const AgriNotificationPage()),
                              );
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
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Quick Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildQuickStat(
                          "My Orders",
                          "${orders.length}",
                          Icons.shopping_bag,
                          Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildQuickStat(
                          "In Cart",
                          "${cart.length}",
                          Icons.shopping_cart,
                          Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        _buildQuickStat(
                          "Delivered",
                          "${orders.where((o) => o['status'] == 'delivered').length}",
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Summary Card
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
                                  "Shopping Summary",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "• ${orders.length} Total Orders",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  "• ${cart.length} Items in Cart",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  "• ${orders.where((o) => o['status'] == 'pending').length} Pending Orders",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  "• ${orders.where((o) => o['status'] == 'delivered').length} Completed",
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
                                Icons.shopping_basket,
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

                  // Weather Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildWeatherCard(),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "Explore Marketplace!",
                      style: ThemeHelper.getTextStyle(
                        isDark: isDarkMode,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Buyer Action Tiles
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buyerTile(
                          icon: Icons.storefront,
                          title: "Browse Products",
                          subtitle: "Discover fresh produce",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const BrowseProductsPage()),
                            );
                          },
                        ),
                        _buyerTile(
                          icon: Icons.receipt_long,
                          title: "My Orders",
                          subtitle: "Track your purchases",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MyOrdersPage()),
                            );
                          },
                        ),
                        _buyerTile(
                          icon: Icons.shopping_cart,
                          title: "Shopping Cart",
                          subtitle: "Review items to buy",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ShoppingCartPage()),
                            );
                          },
                        ),
                        _buyerTile(
                          icon: Icons.local_shipping,
                          title: "Delivery Tracking",
                          subtitle: "Track your deliveries",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DeliveryTrackingPage()),
                            );
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

  Widget _buyerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
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
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white70,
            fontSize: 12,
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

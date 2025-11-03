import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/AgriWeatherPage.dart';
import '../shared/weather_helper.dart';
import '../shared/theme_helper.dart';
import '../shared/notification_helper.dart';
import '../shared/AgriNotificationPage.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../models/product.dart';
import '../models/order.dart';
import 'AgriSynchBuyerSettingsPage.dart';
import 'BrowseProductsPage.dart';
import 'MyOrdersPage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'DeliveryTrackingPage.dart';
import 'dart:convert';

class AgriSynchBuyerHomePage extends StatefulWidget {
  const AgriSynchBuyerHomePage({super.key});

  @override
  State<AgriSynchBuyerHomePage> createState() => _AgriSynchBuyerHomePageState();
}

class _AgriSynchBuyerHomePageState extends State<AgriSynchBuyerHomePage> {
  final storage = FlutterSecureStorage();
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  
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
    final hasWelcomeNotification =
        prefs.getBool('buyer_welcome_notification_sent') ?? false;

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
  Widget _buildQuickStat(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
                      child: Icon(Icons.person, color: Colors.white),
                      backgroundColor: Colors.blue,
                      radius: 20,
                    ),
                    const SizedBox(width: 10),
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
                          "Welcome to AgriSynch Marketplace!",
                          style: ThemeHelper.getSubHeaderTextStyle(
                            isDark: isDarkMode,
                          ),
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
                                MaterialPageRoute(
                                  builder: (_) => const AgriNotificationPage(),
                                ),
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
                        color: isDarkMode
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF00E676),
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

                  // Featured Products Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "✨ Featured Products",
                          style: ThemeHelper.getTextStyle(
                            isDark: isDarkMode,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BrowseProductsPage(),
                              ),
                            );
                          },
                          child: Text(
                            "See All",
                            style: TextStyle(
                              color: ThemeHelper.getHeaderColor(isDarkMode),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Featured Products Horizontal List
                  StreamBuilder<List<Product>>(
                    stream: _productService.getAllProducts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Error loading products',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      List<Product> products = snapshot.data ?? [];
                      List<Product> featuredProducts =
                          products.take(5).toList();

                      if (featuredProducts.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 60, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No products available yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: featuredProducts.length,
                          itemBuilder: (context, index) {
                            final product = featuredProducts[index];
                            return _buildFeaturedProductCard(product);
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Product Categories
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "🏷️ Shop by Category",
                      style: ThemeHelper.getTextStyle(
                        isDark: isDarkMode,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Category Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                      children: [
                        _buildCategoryChip(
                            'Poultry', Icons.egg_outlined, Colors.orange),
                        _buildCategoryChip(
                            'Livestock', Icons.pets, Colors.red),
                        _buildCategoryChip(
                            'Crops', Icons.grass, Colors.green),
                        _buildCategoryChip(
                            'Vegetables', Icons.spa, Colors.lightGreen),
                        _buildCategoryChip(
                            'Fruits', Icons.apple, Colors.pink),
                        _buildCategoryChip(
                            'Dairy', Icons.water_drop, Colors.blue),
                        _buildCategoryChip(
                            'Other', Icons.shopping_basket, Colors.grey),
                        _buildCategoryChip(
                            'All', Icons.grid_view, Colors.purple),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Orders Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "📦 Recent Orders",
                          style: ThemeHelper.getTextStyle(
                            isDark: isDarkMode,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyOrdersPage(),
                              ),
                            );
                          },
                          child: Text(
                            "View All",
                            style: TextStyle(
                              color: ThemeHelper.getHeaderColor(isDarkMode),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Recent Orders List
                  StreamBuilder<List<AppOrder>>(
                    stream: _orderService.getMyBuyerOrders(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      List<AppOrder> recentOrders =
                          (snapshot.data ?? []).take(3).toList();

                      if (recentOrders.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.shopping_bag_outlined,
                                  size: 60, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No orders yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BrowseProductsPage(),
                                    ),
                                  );
                                },
                                child: const Text('Start Shopping'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: recentOrders
                              .map((order) => _buildRecentOrderCard(order))
                              .toList(),
                        ),
                      );
                    },
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

                  const SizedBox(height: 24),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
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

  // Build featured product card
  Widget _buildFeaturedProductCard(Product product) {
    Color categoryColor = _getCategoryColor(product.category);
    
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: ThemeHelper.getCardColor(isDarkMode),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BrowseProductsPage(
                  initialCategory: product.category,
                ),
              ),
            ).then((_) {
              // Reload data when returning from browse
              loadBuyerData();
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  image: product.images.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(product.images.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    if (product.images.isEmpty)
                      Center(
                        child: Icon(
                          _getCategoryIcon(product.category),
                          size: 50,
                          color: categoryColor,
                        ),
                      ),
                    if (product.stock < 10)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: product.stock > 0 ? Colors.orange : Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.stock > 0 ? 'Low Stock' : 'Out',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${product.price.toStringAsFixed(2)} ${product.unit}',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.location,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build category chip
  Widget _buildCategoryChip(String category, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BrowseProductsPage(
              initialCategory: category,
            ),
          ),
        ).then((_) {
          // Reload data when returning from browse
          loadBuyerData();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            category,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Build recent order card
  Widget _buildRecentOrderCard(AppOrder order) {
    Color statusColor = _getOrderStatusColor(order.status);
    bool isDelivering = order.status.toLowerCase() == 'delivering';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: ThemeHelper.getCardColor(isDarkMode),
      child: InkWell(
        onTap: () {
          // Navigate to delivery tracking if order is in delivery, otherwise go to orders page
          if (isDelivering) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DeliveryTrackingPage()),
            ).then((_) {
              loadBuyerData();
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyOrdersPage()),
            ).then((_) {
              loadBuyerData();
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'From: ${order.farmerName}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${order.items.length} item(s) • ₱${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 8),
              
              // Delivery status indicator
              if (isDelivering) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping, size: 16, color: Colors.teal),
                      const SizedBox(width: 8),
                      const Text(
                        'Out for delivery',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Track →',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // Order progress tracker for all orders
              _buildOrderProgressTracker(order.status),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isDelivering ? Icons.navigation : Icons.arrow_forward_ios, 
                    size: 14, 
                    color: isDelivering ? Colors.teal : Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build order progress tracker
  Widget _buildOrderProgressTracker(String status) {
    final steps = ['pending', 'confirmed', 'preparing', 'delivering', 'delivered'];
    int currentStep = steps.indexOf(status.toLowerCase());
    if (currentStep == -1) currentStep = 0; // Default to first step if status not found
    
    return Row(
      children: List.generate(steps.length, (index) {
        bool isCompleted = index <= currentStep;
        
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: isCompleted 
                      ? _getOrderStatusColor(steps[index])
                      : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < steps.length - 1) const SizedBox(width: 2),
            ],
          ),
        );
      }),
    );
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'delivering':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'poultry':
        return const Color(0xFFFFA726);
      case 'livestock':
        return const Color(0xFFEF5350);
      case 'crops':
        return const Color(0xFF66BB6A);
      case 'vegetables':
        return const Color(0xFF4CAF50);
      case 'fruits':
        return const Color(0xFFEC407A);
      case 'dairy':
        return const Color(0xFF42A5F5);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'poultry':
        return Icons.egg_outlined;
      case 'livestock':
        return Icons.pets;
      case 'crops':
        return Icons.grass;
      case 'vegetables':
        return Icons.spa;
      case 'fruits':
        return Icons.apple;
      case 'dairy':
        return Icons.water_drop;
      default:
        return Icons.shopping_basket;
    }
  }
}

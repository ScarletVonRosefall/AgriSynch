import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'AgriSynchCalendarPage.dart';
import 'AgriFinances.dart';
import 'AgriCustomersPage.dart';
import '../shared/weather_helper.dart';
import '../shared/theme_helper.dart';
import '../shared/notification_helper.dart';
import '../shared/AgriNotificationPage.dart';
import '../auth/auth_service.dart';
import '../services/task_service.dart';
import '../services/order_service.dart';
import 'dart:convert';

class AgriSynchHomePage extends StatefulWidget {
  const AgriSynchHomePage({super.key});

  @override
  State<AgriSynchHomePage> createState() => _AgriSynchHomePageState();
}

class _AgriSynchHomePageState extends State<AgriSynchHomePage> {
  final storage = FlutterSecureStorage();
  final _themeNotifier = ThemeNotifier();
  final _taskService = TaskService();
  final _orderService = OrderService();

  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> orders = [];
  int unreadNotifications = 0;
  WeatherData? currentWeather;

  bool _isLoading = true;
  bool _needsReload = false;
  Timer? _debounceTimer;
  Timer? _refreshTimer;
  Timer? _reloadTimer;
  
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _ordersSubscription;
  StreamSubscription? _banCheckSubscription;

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    _setupBanListener();
    _initializeData();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _setupBanListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _banCheckSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .timeout(const Duration(seconds: 10))
        .listen((snapshot) async {
      if (!snapshot.exists || !mounted) return;

      final data = snapshot.data();
      final isBanned = data?['banned'] == true;
      final suspendedUntil = data?['suspendedUntil'] as Timestamp?;
      final isSuspended = suspendedUntil != null && 
                         suspendedUntil.toDate().isAfter(DateTime.now());

      if (isBanned || isSuspended) {
        // User has been banned/suspended, sign them out
        await FirebaseAuth.instance.signOut();
        
        if (!mounted) return;
        
        // Show message and redirect to login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBanned 
                ? 'Your account has been banned. Reason: ${data?['banReason'] ?? 'Terms violation'}'
                : 'Your account has been suspended until ${suspendedUntil?.toDate().toString().split(' ')[0]}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );

        // Navigate to login
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }, onError: (error) {
      print('Ban check subscription error: $error');
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _refreshTimer?.cancel();
    _reloadTimer?.cancel();
    _tasksSubscription?.cancel();
    _ordersSubscription?.cancel();
    _banCheckSubscription?.cancel();
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await Future.wait([
        loadTheme(),
      ]).timeout(const Duration(seconds: 3));

      if (!mounted) return;

      await Future.wait([
        loadTasksAndOrders(),
        loadUnreadNotifications(),
      ]).timeout(const Duration(seconds: 5));

      if (!mounted) return;

      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _refreshData(),
      );

      _loadNonCriticalData();
    } catch (e) {
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
      }
    });
  }

  Future<void> _loadNonCriticalData() async {
    if (!mounted) return;

    // Load these independently without blocking each other
    loadWeather().catchError((e) => print('Weather load failed: $e'));
    checkAndCreateSampleNotifications().catchError((e) => print('Notifications check failed: $e'));
  }

  Future<void> loadTheme() async {
    if (!mounted) return;
  }

  Future<void> loadTasksAndOrders() async {
    if (!mounted) return;

    try {
      _tasksSubscription?.cancel();
      _ordersSubscription?.cancel();

      // Add timeout wrapper for task stream
      _tasksSubscription = _taskService.getTasks(limit: 100)
        .timeout(const Duration(seconds: 10))
        .listen((snapshot) {
          if (!mounted) return;
          
          final newTasks = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? '',
              'description': data['description'] ?? '',
              'completed': data['completed'] ?? false,
              'dueDate': data['dueDate'],
              'priority': data['priority'] ?? 'Medium',
              'category': data['category'] ?? '',
              'createdAt': data['createdAt'],
            };
          }).toList();
          
          if (mounted && !_areListsEqual(tasks, newTasks)) {
            setState(() {
              tasks = newTasks;
            });
          }
        }, onError: (error) {
          print('Error loading tasks: $error');
          if (mounted) {
            setState(() {
              tasks = [];
            });
          }
        });

      // Add timeout wrapper for orders stream
      _ordersSubscription = _orderService.getMyFarmerOrders()
        .timeout(const Duration(seconds: 10))
        .listen((ordersList) {
          if (!mounted) return;
          
          final newOrders = ordersList.map((order) {
            return {
              'id': order.id,
              'buyerName': order.buyerName,
              'status': order.status,
              'totalAmount': order.totalAmount,
              'createdAt': Timestamp.fromDate(order.orderDate),
              'items': order.items.map((item) => {
                'productId': item.productId,
                'name': item.name,
                'quantity': item.quantity,
                'price': item.price,
              }).toList(),
            };
          }).toList();
          
          if (mounted && !_areListsEqual(orders, newOrders)) {
            setState(() {
              orders = newOrders;
            });
          }
        }, onError: (error) {
          print('Error loading orders: $error');
          if (mounted) {
            setState(() {
              orders = [];
            });
          }
        });

    } catch (e) {
      print('Error setting up task/order streams: $e');
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

  Future<void> loadUnreadNotifications() async {
    unreadNotifications = await NotificationHelper.getUnreadCount();
    setState(() {});
  }

  Future<void> loadWeather() async {
    if (!mounted) return;

    try {
      // Don't block UI - fire and forget with callback
      WeatherHelper.getCurrentWeather().then((weather) {
        if (mounted) {
          setState(() {
            currentWeather = weather;
          });
        }
      }).catchError((e) {
        print('Weather load error: $e');
        if (mounted) {
          setState(() {
            currentWeather = null;
          });
        }
      });
    } catch (e) {
      // Silently fail - weather is optional
      print('Weather init error: $e');
    }
  }

  Future<void> checkAndCreateSampleNotifications() async {
    await NotificationHelper.checkTaskDeadlines();

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

  Widget _buildStatisticsSection() {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Stream.value(tasks),
      builder: (context, snapshot) {
        int totalTasks = tasks.length;
        int completedTasks = tasks.where((t) => t['completed'] == true).length;
        int totalOrders = orders.length;
        int pendingTasks = tasks.where((t) => t['completed'] != true).length;
        int pendingOrders = orders.where((o) => 
          o['status']?.toLowerCase() != 'delivered' && 
          o['status']?.toLowerCase() != 'cancelled'
        ).length;

        return Column(
          children: [
            // Quick Stats Row
            Row(
              children: [
                _buildQuickStat(
                  "Total Tasks",
                  "$totalTasks",
                  Icons.assignment,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildQuickStat(
                  "Completed",
                  "$completedTasks",
                  Icons.check_circle,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildQuickStat(
                  "Orders",
                  "$totalOrders",
                  Icons.shopping_cart,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF2E7D32)
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
                          "Today's Summary",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "• $totalTasks Total Tasks",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "• $pendingTasks Pending Tasks",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "• $totalOrders Total Orders",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "• $pendingOrders Pending Orders",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFFFAFAFA) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.eco,
                        color: isDarkMode ? const Color(0xFFFF6F00) : Colors.orange,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Compact Weather Card
            _buildCompactWeatherCard(),
          ],
        );
      },
    );
  }

  Widget _buildCompactWeatherCard() {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    if (currentWeather == null) {
      return GestureDetector(
        onTap: loadWeather,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF2E7D32)
                : const Color(0xFF00C853),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(
            child: Text(
              'Tap to load weather',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF2E7D32)
            : const Color(0xFF00C853),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // Weather icon and temperature
          Text(
            WeatherHelper.getWeatherIcon(currentWeather!.icon),
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentWeather!.temperatureString,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  currentWeather!.capitalizedDescription,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Location and time in vertical layout
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    currentWeather!.location,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.thermostat, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Feels ${currentWeather!.feelsLikeString}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm').format(DateTime.now()),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailsSection() {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    if (currentWeather == null) {
      return GestureDetector(
        onTap: loadWeather,
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 48,
                  color: isDarkMode ? Colors.white54 : Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap to load weather',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: isDarkMode ? Colors.white54 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather Details',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      Icons.water_drop,
                      size: 24,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${currentWeather!.humidity}%',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Humidity',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      Icons.air,
                      size: 24,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${currentWeather!.windSpeed.toStringAsFixed(1)} km/h',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Wind Speed',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      Icons.thermostat,
                      size: 24,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      currentWeather!.feelsLikeString,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Feels Like',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      Icons.update,
                      size: 24,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat('HH:mm').format(DateTime.now()),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Updated',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFarmingAdviceSection() {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    if (currentWeather == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xFF1B5E20).withAlpha((0.3 * 255).round())
              : const Color(0xFFE8F5E8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF81C784),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.agriculture,
                  color: isDarkMode ? Colors.white : const Color(0xFF2E7D32),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Farming Advice',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Check weather conditions regularly',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : const Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1B5E20).withAlpha((0.3 * 255).round())
            : const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF81C784),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.agriculture,
                color: isDarkMode ? Colors.white : const Color(0xFF2E7D32),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Farming Advice',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            WeatherHelper.getWeatherAdvice(
              currentWeather!.description,
              currentWeather!.temperature,
            ),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : const Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((0.2 * 255).round()),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

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
                          _buildGreetingText(),
                          const SizedBox(height: 8),
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
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.2 * 255).round()),
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
                const SizedBox(height: 16),
                // Search bar
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
                            hintText: 'Search...',
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

          // --- Scrollable Content ---
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWideScreen = constraints.maxWidth > 700;

                        if (isWideScreen) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    _buildStatisticsSection(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    _buildWeatherDetailsSection(),
                                    const SizedBox(height: 16),
                                    _buildFarmingAdviceSection(),
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildStatisticsSection(),
                              const SizedBox(height: 16),
                              _buildWeatherDetailsSection(),
                              const SizedBox(height: 16),
                              _buildFarmingAdviceSection(),
                            ],
                          );
                        }
                      },
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
                            } catch (e) {}
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
                            } catch (e) {}
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
                            } catch (e) {}
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

  

  Widget _buildGreetingText() {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return FutureBuilder<Map<String, String?>>(
      future: _loadUserProfileData(),
      builder: (context, snapshot) {
        String displayName = '';
        if (snapshot.hasData) {
          final data = snapshot.data!;
          final fullName = data['name'] ?? data['nickname'] ?? '';
          
          // Extract surname and first name only (first two parts)
          if (fullName.isNotEmpty) {
            final nameParts = fullName.split(',').map((e) => e.trim()).toList();
            if (nameParts.length >= 2) {
              // Format: "Surname, First Name"
              displayName = '${nameParts[0]}, ${nameParts[1].split(' ').first}';
            } else {
              // If no comma, just take first two words
              final words = fullName.split(' ').where((w) => w.isNotEmpty).toList();
              if (words.length >= 2) {
                displayName = '${words[0]} ${words[1]}';
              } else {
                displayName = fullName;
              }
            }
          }
        }
        
        return Text(
          "${_getGreeting()}${displayName.isNotEmpty ? ' $displayName' : ''}!",
          style: ThemeHelper.getHeaderTextStyle(isDark: isDarkMode),
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

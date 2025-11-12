import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'AgriSynchCalendarPage.dart';
import 'AgriFinances.dart';
import 'AgriCustomersPage.dart';
import '../shared/AgriWeatherPage.dart';
import '../shared/weather_helper.dart';
import '../shared/theme_helper.dart';
import '../shared/notification_helper.dart';
import '../shared/AgriNotificationPage.dart';
import '../shared/AgriCurrencyPage.dart';
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

  Widget _buildWeatherCard() {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return GestureDetector(
      onTap: () {
        if (currentWeather == null) {
          // Retry loading weather if it failed
          loadWeather();
        } else {
          // Navigate to weather page if already loaded
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgriWeatherPage()),
          );
        }
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
                    Row(
                      children: [
                        Text(
                          'Tap to load',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.refresh,
                          size: 14,
                          color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.grey[600],
                        ),
                      ],
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

  Widget _buildCurrencyCard() {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AgriCurrencyPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF263238) : Colors.green[50],
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
                ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]
                : [Colors.green[100]!, Colors.green[50]!],
          ),
        ),
        child: Row(
          children: [
            // Currency Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF4CAF50) : Colors.green[600],
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.currency_exchange,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),

            // Currency Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Currency Converter',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PHP • USD • EUR • More',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Real-time exchange rates',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? const Color(0xFF81C784) : Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                                  "• ${tasks.where((t) => t['completed'] != true).length} Pending Tasks",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  "• ${orders.length} Total Orders",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  "• ${orders.where((o) => o['status']?.toLowerCase() != 'delivered' && o['status']?.toLowerCase() != 'cancelled').length} Pending Orders",
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

                  const SizedBox(height: 16),

                  // --- Currency Converter Card ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildCurrencyCard(),
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

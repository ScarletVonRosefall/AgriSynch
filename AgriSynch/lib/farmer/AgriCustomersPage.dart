import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/theme_helper.dart';
import '../shared/notification_helper.dart';
import '../shared/AgriNotificationPage.dart';
import '../services/error_handler.dart';
import '../models/order.dart';

class AgriCustomersPage extends StatefulWidget {
  const AgriCustomersPage({super.key});

  @override
  State<AgriCustomersPage> createState() => _AgriCustomersPageState();
}

class _AgriCustomersPageState extends State<AgriCustomersPage> {
  final _themeNotifier = ThemeNotifier();
  int unreadNotifications = 0;
  String searchQuery = '';
  String sortBy = 'recent'; // recent, name, orders
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Pagination state
  final int _pageSize = 50; // Load more orders since we group by customer
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
  List<AppOrder> _allOrders = [];
  Map<String, List<AppOrder>> _customerOrders = {};

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    _loadUnreadNotifications();
    _loadInitialOrders();
    _scrollController.addListener(_onScroll);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreOrders();
      }
    }
  }

  Future<void> _loadInitialOrders() async {
    setState(() {
      _isInitialLoading = true;
      _allOrders = [];
      _customerOrders = {};
      _lastDocument = null;
      _hasMoreData = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _isInitialLoading = false;
          });
        }
        return;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('farmerId', isEqualTo: currentUser.uid)
          .orderBy('orderDate', descending: true)
          .limit(_pageSize)
          .get()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Failed to load customers. Please check your connection.');
            },
          );

      final orders = querySnapshot.docs
          .map((doc) {
            try {
              return AppOrder.fromFirestore(doc);
            } catch (e) {
              print('Error parsing order ${doc.id}: $e');
              return null;
            }
          })
          .whereType<AppOrder>()
          .toList();

      if (!mounted) return;
      
      setState(() {
        _allOrders = orders;
        _customerOrders = _groupOrdersByCustomer(orders);
        _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
        _hasMoreData = querySnapshot.docs.length >= _pageSize;
        _isInitialLoading = false;
      });
    } catch (e) {
      ErrorHandler.logError('AgriCustomersPage._loadInitialOrders', e);
      
      if (!mounted) return;
      
      setState(() {
        _isInitialLoading = false;
      });

      ErrorHandler.showErrorSnackBar(
        context,
        e,
        customMessage: ErrorHandler.isNetworkError(e)
            ? 'No internet connection. Cannot load customer data.'
            : null,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadInitialOrders,
        ),
      );
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_lastDocument == null || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
        return;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('farmerId', isEqualTo: currentUser.uid)
          .orderBy('orderDate', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Failed to load more customers. Please check your connection.');
            },
          );

      final newOrders = querySnapshot.docs
          .map((doc) {
            try {
              return AppOrder.fromFirestore(doc);
            } catch (e) {
              print('Error parsing order ${doc.id}: $e');
              return null;
            }
          })
          .whereType<AppOrder>()
          .toList();

      if (!mounted) return;
      
      setState(() {
        _allOrders.addAll(newOrders);
        _customerOrders = _groupOrdersByCustomer(_allOrders);
        _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
        _hasMoreData = querySnapshot.docs.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      ErrorHandler.logError('AgriCustomersPage._loadMoreOrders', e);
      
      if (!mounted) return;
      
      setState(() {
        _isLoadingMore = false;
      });

      if (ErrorHandler.shouldRetry(e)) {
        ErrorHandler.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to load more customers',
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _loadMoreOrders,
          ),
        );
      }
    }
  }

  Map<String, List<AppOrder>> _groupOrdersByCustomer(List<AppOrder> orders) {
    Map<String, List<AppOrder>> grouped = {};
    for (var order in orders) {
      if (!grouped.containsKey(order.buyerId)) {
        grouped[order.buyerId] = [];
      }
      grouped[order.buyerId]!.add(order);
    }
    return grouped;
  }

  void _loadUnreadNotifications() async {
    final count = await NotificationHelper.getUnreadCount();
    setState(() {
      unreadNotifications = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header as SliverAppBar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: isDarkMode ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50),
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                  decoration: ThemeHelper.getHeaderDecoration(isDark: isDarkMode),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            'My Customers',
                            style: ThemeHelper.getHeaderTextStyle(isDark: isDarkMode),
                          ),
                        ),
                        // Notification bell
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
                                  _loadUnreadNotifications();
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
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search customers...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          prefixIcon: const Icon(Icons.search, color: Colors.white),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),

          // Sort options
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort, 
                          size: 20,
                          color: isDarkMode ? const Color(0xFFE0E0E0) : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sort by:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? const Color(0xFFE0E0E0) : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildSortChip('Recent Orders', 'recent'),
                        const SizedBox(width: 8),
                        _buildSortChip('Name (A-Z)', 'name'),
                        const SizedBox(width: 8),
                        _buildSortChip('Most Orders', 'orders'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Customer list
          _buildCustomerList(),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    if (_isInitialLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
        ),
      );
    }

    if (_customerOrders.isEmpty) {
      final isDarkMode = _themeNotifier.isDarkMode;
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 80,
                color: isDarkMode ? const Color(0xFF757575) : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No customers yet',
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? const Color(0xFF9E9E9E) : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Customers will appear here after they place orders',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? const Color(0xFF757575) : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Convert to CustomerData list
    var customers = _customerOrders.entries.map((entry) {
      return CustomerData(
        id: entry.key,
        name: entry.value.first.buyerName,
        orders: entry.value,
      );
    }).toList();

    // Filter by search
    if (searchQuery.isNotEmpty) {
      customers = customers.where((customer) {
        return customer.name.toLowerCase().contains(searchQuery);
      }).toList();
    }

    // Sort customers
    _sortCustomers(customers);

    if (customers.isEmpty) {
      final isDarkMode = _themeNotifier.isDarkMode;
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: isDarkMode ? const Color(0xFF757575) : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No customers found',
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? const Color(0xFF9E9E9E) : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Add loading indicator at bottom
          if (index == customers.length) {
            if (_isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              index == 0 ? 0 : 0,
              16,
              index == customers.length - 1 ? 16 : 0,
            ),
            child: _buildCustomerCard(customers[index]),
          );
        },
        childCount: customers.length + (_isLoadingMore ? 1 : 0),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isDarkMode = _themeNotifier.isDarkMode;
    final isSelected = sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          sortBy = value;
        });
      },
      selectedColor: isDarkMode ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50),
      backgroundColor: isDarkMode ? const Color(0xFF263238) : null,
      labelStyle: TextStyle(
        color: isSelected 
            ? Colors.white 
            : (isDarkMode ? const Color(0xFFE0E0E0) : null),
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
      checkmarkColor: Colors.white,
    );
  }

  void _sortCustomers(List<CustomerData> customers) {
    switch (sortBy) {
      case 'name':
        customers.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'orders':
        customers.sort((a, b) => b.orders.length.compareTo(a.orders.length));
        break;
      case 'recent':
      default:
        customers.sort((a, b) {
          final aLatest = a.orders.map((o) => o.orderDate).reduce(
              (a, b) => a.isAfter(b) ? a : b);
          final bLatest = b.orders.map((o) => o.orderDate).reduce(
              (a, b) => a.isAfter(b) ? a : b);
          return bLatest.compareTo(aLatest);
        });
    }
  }

  Widget _buildCustomerCard(CustomerData customer) {
    final isDarkMode = _themeNotifier.isDarkMode;
    final totalOrders = customer.orders.length;
    final totalRevenue = customer.orders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );
    final lastOrderDate = customer.orders.map((o) => o.orderDate).reduce(
        (a, b) => a.isAfter(b) ? a : b);
    
    final deliveredCount = customer.orders
        .where((o) => o.status.toLowerCase() == 'delivered')
        .length;
    final pendingCount = customer.orders
        .where((o) => ['pending', 'confirmed', 'preparing'].contains(o.status.toLowerCase()))
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDarkMode ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCustomerDetails(customer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: (isDarkMode ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50)).withOpacity(0.2),
                    child: Text(
                      customer.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? const Color(0xFF81C784) : const Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Customer info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? const Color(0xFFE0E0E0) : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last order: ${_formatDate(lastOrderDate)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? const Color(0xFF9E9E9E) : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Stats badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isDarkMode ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50)).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_bag,
                          size: 16,
                          color: isDarkMode ? const Color(0xFF81C784) : const Color(0xFF4CAF50),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$totalOrders',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? const Color(0xFF81C784) : const Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: isDarkMode ? const Color(0xFF424242) : null,
              ),
              const SizedBox(height: 16),
              
              // Order statistics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.check_circle,
                    'Delivered',
                    '$deliveredCount',
                    Colors.green,
                  ),
                  _buildStatItem(
                    Icons.pending,
                    'Pending',
                    '$pendingCount',
                    Colors.orange,
                  ),
                  _buildStatItem(
                    Icons.attach_money,
                    'Revenue',
                    '₱${totalRevenue.toStringAsFixed(0)}',
                    Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    final isDarkMode = _themeNotifier.isDarkMode;
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? const Color(0xFF9E9E9E) : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showCustomerDetails(CustomerData customer) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: ThemeHelper.getBackgroundColor(isDarkMode),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF616161) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: (isDarkMode ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50)).withOpacity(0.2),
                        child: Text(
                          customer.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? const Color(0xFF81C784) : const Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? const Color(0xFFE0E0E0) : null,
                              ),
                            ),
                            Text(
                              '${customer.orders.length} orders',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? const Color(0xFF9E9E9E) : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode ? const Color(0xFFE0E0E0) : null,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: isDarkMode ? const Color(0xFF424242) : null,
                ),
                
                // Order history
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: customer.orders.length,
                    itemBuilder: (context, index) {
                      final order = customer.orders[index];
                      return _buildOrderItem(order);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderItem(AppOrder order) {
    final isDarkMode = _themeNotifier.isDarkMode;
    final statusColor = _getStatusColor(order.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDarkMode ? const Color(0xFF1E1E1E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDarkMode ? const Color(0xFFE0E0E0) : null,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.items.length} item(s) - ₱${order.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? const Color(0xFFBDBDBD) : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(order.orderDate),
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? const Color(0xFF9E9E9E) : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'preparing':
        return Colors.blue;
      case 'delivering':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Helper class to group customer data
class CustomerData {
  final String id;
  final String name;
  final List<AppOrder> orders;

  CustomerData({
    required this.id,
    required this.name,
    required this.orders,
  });
}

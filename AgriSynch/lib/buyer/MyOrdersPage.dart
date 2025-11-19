import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../services/order_service.dart';
import '../services/error_handler.dart';
import '../models/order.dart';
import '../shared/chat_screen.dart';
import '../shared/submit_review_dialog.dart';
import '../shared/theme_helper.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final OrderService _orderService = OrderService();
  final _themeNotifier = ThemeNotifier();
  List<Map<String, dynamic>> legacyOrders = []; // Legacy orders from SharedPreferences
  String selectedFilter = 'All';

  // Pagination
  final int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
  List<AppOrder> _firestoreOrders = [];
  final ScrollController _scrollController = ScrollController();

  final List<String> orderFilters = [
    'All',
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    _loadLegacyOrders();
    _loadInitialOrders();
    _scrollController.addListener(_onScroll);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      _firestoreOrders = [];
      _lastDocument = null;
      _hasMoreData = true;
    });

    try {
      // Don't pass filter to service - we'll filter in UI to support grouped statuses
      final result = await _orderService.getBuyerOrdersPaginated(
        limit: _pageSize,
        statusFilter: null, // Always fetch all orders
      );

      if (!mounted) return;

      setState(() {
        _firestoreOrders = result['orders'] as List<AppOrder>;
        _lastDocument = result['lastDocument'] as DocumentSnapshot?;
        _hasMoreData = result['hasMore'] as bool;
        _isInitialLoading = false;
      });
    } catch (e) {
      ErrorHandler.logError('MyOrdersPage._loadInitialOrders', e);
      
      if (!mounted) return;
      
      setState(() {
        _isInitialLoading = false;
      });

      ErrorHandler.showErrorSnackBar(
        context,
        e,
        customMessage: ErrorHandler.isNetworkError(e)
            ? 'No internet connection. Showing offline orders only.'
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
      // Don't pass filter to service - we'll filter in UI to support grouped statuses
      final result = await _orderService.getMoreBuyerOrders(
        lastDocument: _lastDocument!,
        limit: _pageSize,
        statusFilter: null, // Always fetch all orders
      );

      if (!mounted) return;

      setState(() {
        _firestoreOrders.addAll(result['orders'] as List<AppOrder>);
        _lastDocument = result['lastDocument'] as DocumentSnapshot?;
        _hasMoreData = result['hasMore'] as bool;
        _isLoadingMore = false;
      });
    } catch (e) {
      ErrorHandler.logError('MyOrdersPage._loadMoreOrders', e);
      
      if (!mounted) return;
      
      setState(() {
        _isLoadingMore = false;
      });

      if (ErrorHandler.shouldRetry(e)) {
        ErrorHandler.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to load more orders',
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _loadMoreOrders,
          ),
        );
      }
    }
  }

  Future<void> _loadLegacyOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersString = prefs.getString('buyer_orders');
    if (ordersString != null) {
      setState(() {
        legacyOrders = List<Map<String, dynamic>>.from(json.decode(ordersString));
      });
    }
  }

  List<Map<String, dynamic>> _buildCombinedOrderList(List<AppOrder> firestoreOrders) {
    // Convert Firestore orders to maps
    final firestoreOrderMaps = firestoreOrders.map((order) {
      return {
        'id': order.id,
        'buyerId': order.buyerId,
        'farmerId': order.farmerId,
        'items': order.items.map((item) => {
          'productId': item.productId,
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
          'category': item.category,
        }).toList(),
        'total': order.totalAmount,
        'status': order.status,
        'orderDate': order.orderDate.toIso8601String(),
        'estimatedDelivery': order.estimatedDelivery?.toIso8601String(),
        'isFirestore': true,
      };
    }).toList();

    // Combine Firestore and legacy orders
    final combined = [...firestoreOrderMaps, ...legacyOrders];
    
    // Sort by date (newest first)
    combined.sort((a, b) {
      final aDate = DateTime.parse(a['orderDate']);
      final bDate = DateTime.parse(b['orderDate']);
      return bDate.compareTo(aDate);
    });

    return combined;
  }

  Future<void> cancelOrder(String orderId, bool isFirestore) async {
    if (isFirestore) {
      // Cancel in Firestore
      await _orderService.updateOrderStatus(orderId, 'cancelled');
    } else {
      // Cancel in legacy SharedPreferences
      final orderIndex = legacyOrders.indexWhere((order) => order['id'] == orderId);
      if (orderIndex >= 0) {
        setState(() {
          legacyOrders[orderIndex]['status'] = 'cancelled';
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('buyer_orders', json.encode(legacyOrders));
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  List<Map<String, dynamic>> getFilteredOrders(List<Map<String, dynamic>> allOrders) {
    if (selectedFilter == 'All') return allOrders;
    
    // Map filter names to actual statuses
    return allOrders.where((order) {
      final status = order['status'].toLowerCase();
      
      switch (selectedFilter) {
        case 'Pending':
          return status == 'pending';
        case 'Processing':
          // "Processing" includes confirmed and preparing
          return status == 'confirmed' || status == 'preparing';
        case 'Shipped':
          // "Shipped" means delivering
          return status == 'delivering';
        case 'Delivered':
          return status == 'delivered';
        case 'Cancelled':
          return status == 'cancelled';
        default:
          return false;
      }
    }).toList();
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.amber;
      case 'delivering':
        return Colors.purple;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check;
      case 'preparing':
        return Icons.restaurant_menu;
      case 'delivering':
        return Icons.local_shipping;
      case 'processing':
        return Icons.autorenew;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }

  void showOrderDetails(Map<String, dynamic> order) {
    final isDarkMode = _themeNotifier.isDarkMode;
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order['id']}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(order['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order['status'].toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Order Date: ${formatDate(order['orderDate'])}',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: textColor.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            if (order['estimatedDelivery'] != null)
              Text(
                'Estimated Delivery: ${formatDate(order['estimatedDelivery'])}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),

            const SizedBox(height: 16),
            Text(
              'Items:',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),

            ...List.generate(order['items'].length, (index) {
              final item = order['items'][index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _getProductIcon(item['category']),
                      size: 20,
                      color: const Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item['name']} x${item['quantity']}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: textColor,
                        ),
                      ),
                    ),
                    Text(
                      '₱${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
                Text(
                  '₱${order['total'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            
            // Rate Farmer Button (for delivered orders)
            if (order['status'].toLowerCase() == 'delivered')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => SubmitReviewDialog(
                        farmerId: order['farmerId'] ?? '',
                        farmerName: order['farmerName'] ?? 'Farmer',
                        orderId: order['id'],
                      ),
                    );
                  },
                  icon: const Icon(Icons.star),
                  label: const Text('Rate Farmer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA726),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            
            if (order['status'].toLowerCase() == 'delivered')
              const SizedBox(height: 8),
            
            // Message Farmer Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUserId: order['farmerId'] ?? '',
                        otherUserName: order['farmerName'] ?? 'Farmer',
                        orderId: order['id'],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.message),
                label: const Text('Message Farmer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00C853),
                  side: const BorderSide(color: Color(0xFF00C853)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            if (order['status'].toLowerCase() == 'pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Cancel Order'),
                        content: const Text(
                          'Are you sure you want to cancel this order?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              cancelOrder(order['id'], order['isFirestore'] == true);
                            },
                            child: const Text(
                              'Yes',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel Order',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    final backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF2FBE0);
    final headerColor = isDarkMode
        ? const Color(0xFF2E7D32)
        : const Color(0xFF00C853);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _buildOrdersView(backgroundColor, headerColor, cardColor, textColor),
    );
  }

  Widget _buildOrdersView(Color backgroundColor, Color headerColor, Color cardColor, Color textColor) {
    if (_isInitialLoading) {
      return Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'My Orders',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
          ),
        ],
      );
    }

    // Combine Firestore and legacy orders
    final allOrders = _buildCombinedOrderList(_firestoreOrders);
    final filteredOrders = getFilteredOrders(allOrders);

    return Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'My Orders',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Filter Tabs
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: orderFilters.length,
                    itemBuilder: (context, index) {
                      final filter = orderFilters[index];
                      final isSelected = selectedFilter == filter;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedFilter = filter;
                              // No need to reload - filtering is done client-side
                            });
                          },
                          backgroundColor: cardColor,
                          selectedColor: const Color(0xFF4CAF50),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : textColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Orders List
              Expanded(
                child: filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 80,
                          color: textColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedFilter == 'All'
                              ? 'No orders yet'
                              : 'No ${selectedFilter.toLowerCase()} orders',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your orders will appear here',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: textColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Loading indicator at bottom
                      if (index == filteredOrders.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                            ),
                          ),
                        );
                      }

                      final order = filteredOrders[index];
                      final itemCount = order['items'].length;
                      final isFirestore = order['isFirestore'] == true;

                      return Card(
                        color: cardColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => showOrderDetails(order),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            'Order #${order['id']}',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (isFirestore) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4CAF50),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'MARKETPLACE',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(order['status']),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            getStatusIcon(order['status']),
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            order['status'].toUpperCase(),
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                Text(
                                  formatDate(order['orderDate']),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: textColor.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$itemCount item${itemCount > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: textColor.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '₱${order['total'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4CAF50),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Tap for details',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: const Color(0xFF4CAF50),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ),
            ],
          );
  }

  IconData _getProductIcon(String category) {
    switch (category) {
      case 'Vegetables':
        return Icons.eco;
      case 'Fruits':
        return Icons.apple;
      case 'Grains':
        return Icons.grain;
      case 'Dairy':
        return Icons.local_drink;
      case 'Poultry':
        return Icons.egg;
      default:
        return Icons.shopping_basket;
    }
  }
}

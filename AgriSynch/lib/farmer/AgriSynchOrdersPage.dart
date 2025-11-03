import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/theme_helper.dart';
import '../shared/notification_helper.dart';
import '../shared/AgriNotificationPage.dart';
import '../services/finance_service.dart';
import '../services/order_service.dart';
import '../services/error_handler.dart';
import '../models/order.dart';

class AgriSynchOrdersPage extends StatefulWidget {
  const AgriSynchOrdersPage({super.key});

  @override
  State<AgriSynchOrdersPage> createState() => _AgriSynchOrdersPageState();
}

class _AgriSynchOrdersPageState extends State<AgriSynchOrdersPage> {
  final OrderService _orderService = OrderService();
  List<Map<String, dynamic>> _orders = [];
  final TextEditingController _searchController = TextEditingController();
  bool isDarkMode = false;
  int unreadNotifications = 0;

  final List<String> _statuses = ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];
  String _selectedStatusFilter = 'All'; // Filter for viewing orders by status
  String _searchTerm = '';
  String _sortOption = 'Date (Newest First)';

  // Pagination state
  final int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
  List<AppOrder> _firestoreOrders = [];
  final ScrollController _scrollController = ScrollController();

  // Initialize the orders page when widget is first created
  @override
  void initState() {
    super.initState();
    _loadOrders();
    _loadTheme();
    _loadUnreadNotifications();
    _loadInitialOrders();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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
      final result = await _orderService.getFarmerOrdersPaginated(
        limit: _pageSize,
        statusFilter: _selectedStatusFilter == 'All' ? null : _selectedStatusFilter,
      );

      if (!mounted) return;

      setState(() {
        _firestoreOrders = result['orders'] as List<AppOrder>;
        _lastDocument = result['lastDocument'] as DocumentSnapshot?;
        _hasMoreData = result['hasMore'] as bool;
        _isInitialLoading = false;
      });
    } catch (e) {
      ErrorHandler.logError('AgriSynchOrdersPage._loadInitialOrders', e);
      
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
      final result = await _orderService.getMoreFarmerOrders(
        lastDocument: _lastDocument!,
        limit: _pageSize,
        statusFilter: _selectedStatusFilter == 'All' ? null : _selectedStatusFilter,
      );

      if (!mounted) return;

      setState(() {
        _firestoreOrders.addAll(result['orders'] as List<AppOrder>);
        _lastDocument = result['lastDocument'] as DocumentSnapshot?;
        _hasMoreData = result['hasMore'] as bool;
        _isLoadingMore = false;
      });
    } catch (e) {
      ErrorHandler.logError('AgriSynchOrdersPage._loadMoreOrders', e);
      
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

  // Load count of unread notifications
  Future<void> _loadUnreadNotifications() async {
    unreadNotifications = await NotificationHelper.getUnreadCount();
    setState(() {});
  }

  // Load the current theme setting
  Future<void> _loadTheme() async {
    isDarkMode = await ThemeHelper.isDarkModeEnabled();
    setState(() {});
  }

  // Load saved orders from device storage
  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('orders');
    if (data != null) {
      setState(() {
        _orders = List<Map<String, dynamic>>.from(json.decode(data));
        
        // Migration: Ensure all orders have orderId field
        for (var order in _orders) {
          if (!order.containsKey('orderId') && order.containsKey('id')) {
            order['orderId'] = order['id'];
          }
        }
      });
      
      // Save migrated data
      await _saveOrders();
    }
  }

  // Save orders to device storage
  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('orders', json.encode(_orders));
  }

  int _getStatusPriority(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'processing':
        return 1;
      case 'shipped':
        return 2;
      case 'delivered':
        return 3;
      case 'cancelled':
        return 4;
      default:
        return 5;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _deleteOrder(String orderId) {
    final index = _orders.indexWhere((order) => order['orderId'] == orderId);
    if (index == -1) return; // Order not found
    
    setState(() {
      _orders.removeAt(index);
    });
    _saveOrders();

    // Show delete confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order Deleted!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _deleteAllDelivered() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Delivered Orders'),
        content: const Text(
          'Are you sure you want to delete all delivered orders? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _orders.removeWhere((order) => (order['status'] as String?) == 'Delivered');
              });
              _saveOrders();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredOrders {
    List<Map<String, dynamic>> filtered = _orders;

    // Filter by status
    if (_selectedStatusFilter != 'All') {
      filtered = filtered
          .where((order) => order['status'] == _selectedStatusFilter)
          .toList();
    }

    // Filter by search term
    if (_searchTerm.isNotEmpty) {
      filtered = filtered.where((order) {
        final productName = order['product'].toString().toLowerCase();
        final quantity = order['quantity'].toString().toLowerCase();
        final orderId = order['id'].toString().toLowerCase();
        final searchLower = _searchTerm.toLowerCase();
        return productName.contains(searchLower) ||
            quantity.contains(searchLower) ||
            orderId.contains(searchLower);
      }).toList();
    }

    // Sort the filtered list
    switch (_sortOption) {
      case 'Date (Newest First)':
        filtered.sort(
          (a, b) =>
              DateTime.parse(b['orderDate']).compareTo(DateTime.parse(a['orderDate'])),
        );
        break;
      case 'Date (Oldest First)':
        filtered.sort(
          (a, b) =>
              DateTime.parse(a['orderDate']).compareTo(DateTime.parse(b['orderDate'])),
        );
        break;
      case 'Product Name (A-Z)':
        filtered.sort(
          (a, b) => a['product'].toString().compareTo(b['product'].toString()),
        );
        break;
      case 'Product Name (Z-A)':
        filtered.sort(
          (a, b) => b['product'].toString().compareTo(a['product'].toString()),
        );
        break;
      case 'Quantity (High to Low)':
        filtered.sort(
          (a, b) => int.parse(
            b['quantity'].toString(),
          ).compareTo(int.parse(a['quantity'].toString())),
        );
        break;
      case 'Quantity (Low to High)':
        filtered.sort(
          (a, b) => int.parse(
            a['quantity'].toString(),
          ).compareTo(int.parse(b['quantity'].toString())),
        );
        break;
      case 'Price (High to Low)':
        filtered.sort(
          (a, b) => (b['total'] as num).compareTo(a['total'] as num),
        );
        break;
      case 'Price (Low to High)':
        filtered.sort(
          (a, b) => (a['total'] as num).compareTo(b['total'] as num),
        );
        break;
      case 'Status':
        filtered.sort((a, b) {
          final statusA = a['status']?.toString().toLowerCase() ?? '';
          final statusB = b['status']?.toString().toLowerCase() ?? '';
          if (statusA == statusB) {
            return DateTime.parse(b['orderDate'])
                .compareTo(DateTime.parse(a['orderDate']));
          }
          return _getStatusPriority(statusA).compareTo(_getStatusPriority(statusB));
        });
        break;
    }

    return filtered;
  }

  Widget _buildPaginatedOrderList() {
    if (_isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
        ),
      );
    }

    // Use the paginated Firestore orders instead of stream
    return _buildCombinedOrderList(_firestoreOrders);
  }

  // Build combined order list from Firestore and legacy SharedPreferences
  Widget _buildCombinedOrderList(List<AppOrder> firestoreOrders) {
    // Convert Firestore orders to map format for unified display
    List<Map<String, dynamic>> combinedOrders = [];
    
    // Add Firestore orders (these are the new marketplace orders)
    for (var order in firestoreOrders) {
      combinedOrders.add({
        'id': order.id.substring(0, 8),
        'orderId': order.id,
        'product': order.items.map((item) => item.name).join(', '),
        'quantity': order.items.fold<int>(0, (sum, item) => sum + item.quantity),
        'price': order.totalAmount / order.items.fold<int>(0, (sum, item) => sum + item.quantity),
        'total': order.totalAmount,
        'status': _capitalizeFirst(order.status),
        'orderDate': order.orderDate.toIso8601String(),
        'buyer': order.buyerName,
        'isFirestore': true, // Mark as Firestore order
      });
    }
    
    // Add legacy SharedPreferences orders
    for (var order in _orders) {
      combinedOrders.add({
        ...order,
        'isFirestore': false, // Mark as legacy order
      });
    }
    
    // Apply filters
    List<Map<String, dynamic>> filtered = combinedOrders;
    
    // Filter by status
    if (_selectedStatusFilter != 'All') {
      filtered = filtered
          .where((order) => order['status'] == _selectedStatusFilter)
          .toList();
    }
    
    // Filter by search term
    if (_searchTerm.isNotEmpty) {
      filtered = filtered.where((order) {
        final productName = order['product'].toString().toLowerCase();
        final quantity = order['quantity'].toString().toLowerCase();
        final orderId = order['id'].toString().toLowerCase();
        final searchLower = _searchTerm.toLowerCase();
        return productName.contains(searchLower) ||
            quantity.contains(searchLower) ||
            orderId.contains(searchLower);
      }).toList();
    }
    
    // Sort the filtered list
    switch (_sortOption) {
      case 'Date (Newest First)':
        filtered.sort(
          (a, b) =>
              DateTime.parse(b['orderDate']).compareTo(DateTime.parse(a['orderDate'])),
        );
        break;
      case 'Date (Oldest First)':
        filtered.sort(
          (a, b) =>
              DateTime.parse(a['orderDate']).compareTo(DateTime.parse(b['orderDate'])),
        );
        break;
      case 'Price (High to Low)':
        filtered.sort(
          (a, b) => (b['total'] as num).compareTo(a['total'] as num),
        );
        break;
      case 'Price (Low to High)':
        filtered.sort(
          (a, b) => (a['total'] as num).compareTo(b['total'] as num),
        );
        break;
    }
    
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No orders yet",
              style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Orders from buyers will appear here",
              style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode).copyWith(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
      padding: const EdgeInsets.only(bottom: 20),
      itemBuilder: (context, index) {
        // Loading indicator at bottom
        if (index == filtered.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
          );
        }

        final order = filtered[index];
        final date = DateTime.parse(order['orderDate'] ?? order['date']);
        final isFirestoreOrder = order['isFirestore'] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: ThemeHelper.getContainerDecoration(isDark: isDarkMode),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            onLongPress: isFirestoreOrder ? null : () => _editOrder(order['orderId']),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getStatusColor(order['status'] ?? 'Pending').withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getStatusIcon(order['status'] ?? 'Pending'),
                color: _getStatusColor(order['status'] ?? 'Pending'),
                size: 24,
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${order['product']} - Qty: ${order['quantity']}",
                        style: ThemeHelper.getBodyTextStyle(
                          isDark: isDarkMode,
                        ).copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      if (isFirestoreOrder && order['buyer'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              order['buyer'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  "₱${order['total']?.toStringAsFixed(2) ?? '0.00'}",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Order #${order['id'] ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: isDarkMode ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    Text(
                      "Ordered ${date.day}/${date.month}/${date.year}",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: isDarkMode ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (isFirestoreOrder) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                        child: const Text(
                          'MARKETPLACE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: isFirestoreOrder
                ? PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'update_status',
                        child: Row(
                          children: [
                            Icon(Icons.update, size: 20),
                            SizedBox(width: 8),
                            Text('Update Status'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'update_status') {
                        _showUpdateStatusDialog(order['orderId']);
                      }
                    },
                  )
                : PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editOrder(order['orderId']);
                      } else if (value == 'delete') {
                        _deleteOrder(order['orderId']);
                      }
                    },
                  ),
          ),
        );
      },
    );
  }

  String _capitalizeFirst(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  // Show dialog to update Firestore order status
  void _showUpdateStatusDialog(String orderId) async {
    final statusOptions = ['pending', 'confirmed', 'preparing', 'delivering', 'delivered', 'cancelled'];
    String selectedStatus = 'confirmed';

    // Fetch the order to get details for finance transaction
    final order = await _orderService.getOrderById(orderId);
    if (order == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Order not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Order Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select new status for this order:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: statusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(_capitalizeFirst(status)),
                          size: 20,
                          color: _getStatusColor(_capitalizeFirst(status)),
                        ),
                        const SizedBox(width: 8),
                        Text(_capitalizeFirst(status)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedStatus = value;
                    });
                  }
                },
              ),
              if (selectedStatus == 'delivered') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4CAF50)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Color(0xFF4CAF50), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Will add ₱${order.totalAmount.toStringAsFixed(2)} to finances',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Update order status in Firestore
                  await _orderService.updateOrderStatus(orderId, selectedStatus);
                  
                  // If delivered, add finance transaction
                  if (selectedStatus == 'delivered') {
                    final productNames = order.items.map((item) => item.name).join(', ');
                    final totalQuantity = order.items.fold<int>(0, (sum, item) => sum + item.quantity);
                    
                    await FinanceService.addTransactionFromOrder(
                      orderId: orderId,
                      productName: productNames,
                      amount: order.totalAmount,
                      quantity: totalQuantity,
                    );
                  }
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ErrorHandler.showSuccessSnackBar(
                      context,
                      selectedStatus == 'delivered'
                          ? 'Order delivered! ₱${order.totalAmount.toStringAsFixed(2)} added to finances'
                          : 'Order status updated to ${_capitalizeFirst(selectedStatus)}',
                      duration: const Duration(seconds: 3),
                    );
                  }
                } catch (e) {
                  ErrorHandler.logError('updateOrderStatus', e);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ErrorHandler.showErrorSnackBar(
                      context,
                      e,
                      customMessage: 'Failed to update order status',
                      action: SnackBarAction(
                        label: 'Retry',
                        textColor: Colors.white,
                        onPressed: () => _showUpdateStatusDialog(orderId),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // Build the orders page UI with fixed header and scrollable content
  @override
  Widget build(BuildContext context) {
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Orders Management',
                            style: ThemeHelper.getHeaderTextStyle(
                              isDark: isDarkMode,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your agricultural orders',
                            style: ThemeHelper.getSubHeaderTextStyle(
                              isDark: isDarkMode,
                            ),
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
                _buildSearchSection(),
              ],
            ),
          ),

          // --- Scrollable Content ---
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildFilterAndSortSection(),
                    const SizedBox(height: 12),
                    _buildOrdersHeader(),
                    const SizedBox(height: 8),
                    // Orders List - Using pagination for performance
                    SizedBox(
                      height: 400, // Fixed height for orders list
                      child: _buildPaginatedOrderList(),
                    ),
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      height: 42,
      decoration: ThemeHelper.getContainerDecoration(isDark: isDarkMode),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.search, color: ThemeHelper.getIconColor(isDarkMode)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search orders...',
                border: InputBorder.none,
                hintStyle: ThemeHelper.getHintTextStyle(isDark: isDarkMode),
              ),
              style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode),
            ),
          ),
          if (_searchTerm.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: ThemeHelper.getIconColor(isDarkMode),
              ),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchTerm = '';
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSortSection() {
    final deliveredCount = _orders
        .where((order) => (order['status'] as String?) == 'Delivered')
        .length;
    final sortOptions = [
      'Date (Newest First)',
      'Date (Oldest First)',
      'Product Name (A-Z)',
      'Product Name (Z-A)',
      'Quantity (High to Low)',
      'Quantity (Low to High)',
      'Price (High to Low)',
      'Price (Low to High)',
      'Status',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ThemeHelper.getContainerDecoration(isDark: isDarkMode),
      child: Column(
        children: [
          // Filter Row
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: ThemeHelper.getHeaderColor(isDarkMode),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Filter:',
                style: ThemeHelper.getBodyTextStyle(
                  isDark: isDarkMode,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              // Status Filter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedStatusFilter,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: Text('Status', style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode)),
                    style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode),
                    dropdownColor: ThemeHelper.getCardColor(isDarkMode),
                    items: ['All', ..._statuses]
                        .map(
                          (status) =>
                              DropdownMenuItem(
                                value: status, 
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: _getStatusColor(status),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(status),
                                  ],
                                ),
                              ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatusFilter = value!;
                      });
                      _loadInitialOrders(); // Reload with new filter
                    },
                  ),
                ),
              ),
              if (deliveredCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton.icon(
                    onPressed: _deleteAllDelivered,
                    icon: const Icon(
                      Icons.delete_sweep,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: Text(
                      'Clear ($deliveredCount)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Sort Row
          Row(
            children: [
              Icon(
                Icons.sort,
                color: ThemeHelper.getHeaderColor(isDarkMode),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Sort:',
                style: ThemeHelper.getBodyTextStyle(
                  isDark: isDarkMode,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _sortOption,
                    isExpanded: true,
                    underline: const SizedBox(),
                    style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode),
                    dropdownColor: ThemeHelper.getCardColor(isDarkMode),
                    items: sortOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(
                              option,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _sortOption = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersHeader() {
    final deliveredCount = _filteredOrders.where((order) => (order['status'] as String?) == 'Delivered').length;
    final processingCount = _filteredOrders.where((order) => (order['status'] as String?) == 'Processing').length;
    final shippedCount = _filteredOrders.where((order) => (order['status'] as String?) == 'Shipped').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ThemeHelper.getHeaderColor(isDarkMode),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                "Total Orders: ${_filteredOrders.length}",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (_filteredOrders.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusCount('Delivered', deliveredCount, Icons.check_circle),
                _buildStatusCount('Processing', processingCount, Icons.autorenew),
                _buildStatusCount('Shipped', shippedCount, Icons.local_shipping),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCount(String status, int count, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 12),
        const SizedBox(width: 4),
        Text(
          "$count $status",
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _editOrder(String orderId) async {
    final index = _orders.indexWhere((order) => order['orderId'] == orderId);
    if (index == -1) return; // Order not found
    
    final order = _orders[index];
    String editedProduct = order['product'];
    String editedQuantity = order['quantity'];

    // Build a list of all unique products from existing orders
    final allProducts = <String>{};
    for (var o in _orders) {
      final productName = o['product'] as String?;
      if (productName != null && productName.isNotEmpty) {
        allProducts.add(productName);
      }
    }
    final productList = allProducts.toList()..sort();

    await showDialog(
      context: context,
      builder: (context) {
        TextEditingController quantityController = TextEditingController(
          text: editedQuantity,
        );

        return AlertDialog(
          title: const Text('Edit Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: editedProduct,
                items: productList
                    .map(
                      (product) => DropdownMenuItem(
                        value: product,
                        child: Text(product),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) editedProduct = value;
                },
                decoration: const InputDecoration(labelText: 'Product'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _orders[index]['product'] = editedProduct;
                  _orders[index]['quantity'] = quantityController.text;
                });
                _saveOrders();
                Navigator.pop(context);

                // Show edit confirmation snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order Updated!'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Color(0xFF00C853),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

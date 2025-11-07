import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/theme_helper.dart';
import '../shared/notification_helper.dart';
import '../shared/AgriNotificationPage.dart';
import '../shared/currency_helper.dart';
import '../services/finance_service.dart';
import '../services/order_service.dart';
import '../services/error_handler.dart';
import '../models/order.dart';
import '../shared/chat_screen.dart';

class AgriSynchOrdersPage extends StatefulWidget {
  const AgriSynchOrdersPage({super.key});

  @override
  State<AgriSynchOrdersPage> createState() => _AgriSynchOrdersPageState();
}

class _AgriSynchOrdersPageState extends State<AgriSynchOrdersPage> {
  final OrderService _orderService = OrderService();
  final TextEditingController _searchController = TextEditingController();
  final _themeNotifier = ThemeNotifier();
  int unreadNotifications = 0;
  String _currencySymbol = '₱'; // Will be loaded from settings

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
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    _loadUnreadNotifications();
    _loadCurrencySymbol();
    _loadInitialOrders();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload currency when returning to this page
    _loadCurrencySymbol();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCurrencySymbol() async {
    final symbol = await CurrencyHelper.getCurrentCurrencySymbol();
    if (mounted) {
      setState(() {
        _currencySymbol = symbol;
      });
    }
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
      print('DEBUG: Order loading error: $e');
      ErrorHandler.logError('AgriSynchOrdersPage._loadInitialOrders', e);
      
      if (!mounted) return;
      
      setState(() {
        _isInitialLoading = false;
      });

      // Show specific error messages based on error type
      String errorMessage;
      if (e.toString().contains('permission-denied') || 
          e.toString().contains('PERMISSION_DENIED')) {
        errorMessage = 'Permission denied. Please ensure you are logged in.';
      } else if (ErrorHandler.isNetworkError(e)) {
        errorMessage = 'No internet connection. Please check your connection.';
      } else {
        errorMessage = 'Unable to load orders. ${e.toString()}';
      }

      ErrorHandler.showErrorSnackBar(
        context,
        e,
        customMessage: errorMessage,
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

  // Load saved orders from device storage
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
    final isDarkMode = _themeNotifier.isDarkMode;
    
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
    
    // Legacy SharedPreferences orders are no longer loaded automatically
    // Users should rely on Firestore orders from the marketplace
    
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
            // All orders are now from Firestore - no long press edit for legacy orders
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
                  "$_currencySymbol${order['total']?.toStringAsFixed(2) ?? '0.00'}",
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
            trailing: PopupMenuButton(
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
                          'Will add $_currencySymbol${order.totalAmount.toStringAsFixed(2)} to finances',
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
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      otherUserId: order.buyerId,
                      otherUserName: order.buyerName,
                      orderId: orderId,
                    ),
                  ),
                );
              },
              child: const Text('Message Buyer'),
            ),
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
                          ? 'Order delivered! $_currencySymbol${order.totalAmount.toStringAsFixed(2)} added to finances'
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
    final isDarkMode = _themeNotifier.isDarkMode;
    
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
    final isDarkMode = _themeNotifier.isDarkMode;
    
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
    final isDarkMode = _themeNotifier.isDarkMode;
    
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
              // Removed "Delete All Delivered" button - Firestore orders managed through status updates
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
    final isDarkMode = _themeNotifier.isDarkMode;
    
    final deliveredCount = _firestoreOrders.where((order) => order.status.toLowerCase() == 'delivered').length;
    final processingCount = _firestoreOrders.where((order) => order.status.toLowerCase() == 'processing' || order.status.toLowerCase() == 'preparing').length;
    final shippedCount = _firestoreOrders.where((order) => order.status.toLowerCase() == 'delivering' || order.status.toLowerCase() == 'shipped').length;

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
                "Total Orders: ${_firestoreOrders.length}",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (_firestoreOrders.isNotEmpty) ...[
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
}

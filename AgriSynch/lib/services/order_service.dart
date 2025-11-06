import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart' show AppOrder;
import 'notification_service.dart';
import '../shared/notification_helper.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new order (buyer creates order)
  Future<void> createOrder(AppOrder order) async {
    // Use a batch to ensure atomic updates
    final batch = _firestore.batch();
    
    // Add the order
    final orderRef = _firestore.collection('orders').doc(order.id);
    batch.set(orderRef, order.toFirestore());
    
    // Decrement stock for each product in the order
    for (final item in order.items) {
      final productRef = _firestore.collection('products').doc(item.productId);
      batch.update(productRef, {
        'stock': FieldValue.increment(-item.quantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    // Commit all changes atomically
    await batch.commit();
    
    // Notify farmer about new order
    try {
      // Get first product name from order items
      final productName = order.items.isNotEmpty ? order.items.first.name : 'Product(s)';
      
      // Show local notification on current device (works on Spark Plan)
      await _notificationService.showLocalNotificationDirect(
        title: '🔔 New Order Received!',
        body: '${order.buyerName} ordered $productName (₱${order.totalAmount.toStringAsFixed(2)})',
        payload: 'order:${order.id}',
      );
      
      // Also save to NotificationHelper for persistence
      await NotificationHelper.addOrderNotification(
        title: '🔔 New Order Received!',
        message: '${order.buyerName} ordered $productName (₱${order.totalAmount.toStringAsFixed(2)})',
        orderId: order.id,
      );
      
      // Queue for Cloud Functions (if deployed)
      await _notificationService.notifyFarmerNewOrder(
        farmerId: order.farmerId,
        orderId: order.id,
        productName: productName,
        buyerName: order.buyerName,
        totalAmount: order.totalAmount,
      );
    } catch (e) {
      // Don't fail order creation if notification fails
      print('Failed to send new order notification: $e');
    }
  }

  // Get orders for the current buyer
  Stream<List<AppOrder>> getMyBuyerOrders() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          var orders = snapshot.docs.map((doc) => AppOrder.fromFirestore(doc)).toList();
          // Sort by date in memory to avoid index requirements
          orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
          return orders;
        });
  }

  // Get orders for the current farmer
  Stream<List<AppOrder>> getMyFarmerOrders() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('orders')
        .where('farmerId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          var orders = snapshot.docs.map((doc) => AppOrder.fromFirestore(doc)).toList();
          // Sort by date in memory to avoid index requirements
          orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
          return orders;
        });
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Send notification to buyer about status change
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final orderData = orderDoc.data()!;
        final buyerId = orderData['buyerId'] as String;
        final items = (orderData['items'] as List<dynamic>?) ?? [];
        final productName = items.isNotEmpty 
            ? (items.first as Map<String, dynamic>)['name'] ?? 'Product(s)'
            : 'Product(s)';
        
        // Generate status-specific message
        String title = '';
        String body = '';
        switch (status.toLowerCase()) {
          case 'confirmed':
            title = '✅ Order Confirmed';
            body = 'Your order for $productName has been confirmed!';
            break;
          case 'preparing':
            title = '📦 Order Preparing';
            body = 'The farmer is preparing your order for $productName.';
            break;
          case 'ready':
            title = '✨ Order Ready';
            body = 'Your order for $productName is ready for pickup/delivery!';
            break;
          case 'in transit':
            title = '🚚 Order In Transit';
            body = 'Your order for $productName is on its way!';
            break;
          case 'delivered':
            title = '🎉 Order Delivered';
            body = 'Your order for $productName has been delivered!';
            break;
          case 'cancelled':
            title = '❌ Order Cancelled';
            body = 'Your order for $productName has been cancelled.';
            break;
          default:
            title = '📬 Order Update';
            body = 'Status changed to: $status';
        }
        
        // Show local notification on current device (works on Spark Plan)
        await _notificationService.showLocalNotificationDirect(
          title: title,
          body: body,
          payload: 'order:$orderId',
        );
        
        // Also save to NotificationHelper for persistence
        await NotificationHelper.addOrderNotification(
          title: title,
          message: body,
          orderId: orderId,
        );
        
        // Queue for Cloud Functions (if deployed)
        await _notificationService.notifyBuyerOrderStatusChange(
          buyerId: buyerId,
          orderId: orderId,
          productName: productName,
          newStatus: status,
        );
      }
    } catch (e) {
      // Don't fail status update if notification fails
      print('Failed to send status update notification: $e');
    }
  }

  // Update delivery date
  Future<void> updateDeliveryDate(String orderId, DateTime date) async {
    await _firestore.collection('orders').doc(orderId).update({
      'estimatedDelivery': Timestamp.fromDate(date),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete order (only for pending orders)
  Future<void> deleteOrder(String orderId) async {
    await _firestore.collection('orders').doc(orderId).delete();
  }

  // Get single order by ID
  Future<AppOrder?> getOrderById(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (!doc.exists) return null;
    return AppOrder.fromFirestore(doc);
  }

  // Update order with custom fields
  Future<void> updateOrder(String orderId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('orders').doc(orderId).update(updates);
  }

  // PAGINATION METHODS FOR ORDERS

  /// Get paginated buyer orders (initial load)
  Future<Map<String, dynamic>> getBuyerOrdersPaginated({
    int limit = 20,
    String? statusFilter,
  }) async {
    try {
      if (currentUserId == null) {
        return {
          'orders': <AppOrder>[],
          'lastDocument': null,
          'hasMore': false,
        };
      }

      Query<Map<String, dynamic>> query = _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: currentUserId)
          .orderBy('orderDate', descending: true)
          .limit(limit);

      if (statusFilter != null && statusFilter != 'All') {
        query = query.where('status', isEqualTo: statusFilter.toLowerCase());
      }

      final snapshot = await query.get().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Failed to load orders. Please check your connection.');
        },
      );
      
      final orders = snapshot.docs
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

      return {
        'orders': orders,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length == limit,
      };
    } catch (e) {
      print('Error in getBuyerOrdersPaginated: $e');
      rethrow;
    }
  }

  /// Get next page of buyer orders
  Future<Map<String, dynamic>> getMoreBuyerOrders({
    required DocumentSnapshot lastDocument,
    int limit = 20,
    String? statusFilter,
  }) async {
    try {
      if (currentUserId == null) {
        return {
          'orders': <AppOrder>[],
          'lastDocument': null,
          'hasMore': false,
        };
      }

      Query<Map<String, dynamic>> query = _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: currentUserId)
          .orderBy('orderDate', descending: true)
          .startAfterDocument(lastDocument)
          .limit(limit);

      if (statusFilter != null && statusFilter != 'All') {
        query = query.where('status', isEqualTo: statusFilter.toLowerCase());
      }

      final snapshot = await query.get().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Failed to load more orders. Please check your connection.');
        },
      );
      
      final orders = snapshot.docs
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

      return {
        'orders': orders,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length == limit,
      };
    } catch (e) {
      print('Error in getMoreBuyerOrders: $e');
      rethrow;
    }
  }

  /// Get paginated farmer orders (initial load)
  Future<Map<String, dynamic>> getFarmerOrdersPaginated({
    int limit = 20,
    String? statusFilter,
  }) async {
    try {
      if (currentUserId == null) {
        return {
          'orders': <AppOrder>[],
          'lastDocument': null,
          'hasMore': false,
        };
      }

      // Build query - ONLY filter by farmerId to avoid composite index requirement
      // We'll sort and filter in-memory
      Query<Map<String, dynamic>> query = _firestore
          .collection('orders')
          .where('farmerId', isEqualTo: currentUserId)
          .limit(100); // Get more documents since we'll filter/sort in-memory

      final snapshot = await query.get().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Failed to load orders. Please check your connection.');
        },
      );
      
      var orders = snapshot.docs
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

      // Filter by status in-memory if needed
      if (statusFilter != null && statusFilter != 'All') {
        orders = orders.where((order) => 
          order.status.toLowerCase() == statusFilter.toLowerCase()
        ).toList();
      }

      // Sort by date in-memory (newest first)
      orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

      // Take only the limit we need after filtering and sorting
      final limitedOrders = orders.take(limit).toList();

      return {
        'orders': limitedOrders,
        'lastDocument': null, // Disable pagination for now since we're loading all
        'hasMore': false,
      };
    } catch (e) {
      print('Error in getFarmerOrdersPaginated: $e');
      rethrow;
    }
  }

  /// Get next page of farmer orders
  Future<Map<String, dynamic>> getMoreFarmerOrders({
    required DocumentSnapshot lastDocument,
    int limit = 20,
    String? statusFilter,
  }) async {
    // Pagination disabled for now - return empty result
    // Since we load all orders in getFarmerOrdersPaginated
    return {
      'orders': <AppOrder>[],
      'lastDocument': null,
      'hasMore': false,
    };
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart' show AppOrder;
import 'notification_service.dart';
import '../shared/notification_helper.dart';
import 'rate_limit_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> createOrder(AppOrder order) async {
    try {
      // Check rate limit
      final canCreate = await RateLimitService.checkRateLimit(
        'order_create',
        userId: order.buyerId,
      );
      if (!canCreate) {
        final errorMessage = RateLimitService.getRateLimitMessage('order_create');
        debugPrint('🚫 OrderService: $errorMessage');
        throw Exception(errorMessage);
      }

      debugPrint('📝 Creating order: ${order.id}');
      
      final orderRef = _firestore.collection('orders').doc(order.id);
      await orderRef.set(order.toFirestore());
      debugPrint('✅ Order document created');
      
      // Update stock individually using transactions for proper security rule validation
      for (final item in order.items) {
        debugPrint('📦 Decrementing stock for product: ${item.productId}, quantity: ${item.quantity}');
        await _decrementProductStock(item.productId, item.quantity);
        debugPrint('✅ Stock decremented for: ${item.productId}');
      }
      
      debugPrint('✅ All stocks updated successfully');
      
      await _sendOrderNotifications(order);
      debugPrint('✅ Notifications sent');
    } catch (e) {
      debugPrint('❌ ERROR in createOrder: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }
  
  Future<void> _decrementProductStock(String productId, int quantity) async {
    final productRef = _firestore.collection('products').doc(productId);
    
    try {
      return _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(productRef);
        
        if (!snapshot.exists) {
          throw Exception('Product not found');
        }
        
        final data = snapshot.data();
        if (data == null) {
          throw Exception('Product data is invalid');
        }
        final currentStock = data['stock'] as int? ?? 0;
        final newStock = currentStock - quantity;
        
        debugPrint('  📊 Current stock: $currentStock, Order quantity: $quantity, New stock: $newStock');
        debugPrint('  📊 Current data keys: ${data.keys.toList()}');
        
        if (newStock < 0) {
          throw Exception('Insufficient stock for product $productId');
        }
        
        final updateData = Map<String, dynamic>.from(data);
        updateData['stock'] = newStock;
        updateData['isAvailable'] = newStock > 0;
        updateData['updatedAt'] = Timestamp.now();
        
        debugPrint('  📝 Updating with keys: ${updateData.keys.toList()}');
        
        transaction.set(productRef, updateData, SetOptions(merge: true));
      });
      } catch (e) {
      debugPrint('  ❌ ERROR in _decrementProductStock for $productId: $e');
      if (e.toString().contains('permission-denied')) {
        debugPrint('  ⚠️  PERMISSION DENIED - Check Firestore security rules!');
      }
      rethrow;
    }
  }
  
  Future<void> _sendOrderNotifications(AppOrder order) async {
    try {
      final productName = order.items.isNotEmpty ? order.items.first.name : 'Product(s)';
      
      await _notificationService.showLocalNotificationDirect(
        title: '🔔 New Order Received!',
        body: '${order.buyerName} ordered $productName (₱${order.totalAmount.toStringAsFixed(2)})',
        payload: 'order:${order.id}',
      );
      
      await NotificationHelper.addOrderNotification(
        title: '🔔 New Order Received!',
        message: '${order.buyerName} ordered $productName (₱${order.totalAmount.toStringAsFixed(2)})',
        orderId: order.id,
      );
      
      await _notificationService.notifyFarmerNewOrder(
        farmerId: order.farmerId,
        orderId: order.id,
        productName: productName,
        buyerName: order.buyerName,
        totalAmount: order.totalAmount,
      );
    } catch (e) {
      debugPrint('Failed to send new order notification: $e');
    }
  }

  Stream<List<AppOrder>> getMyBuyerOrders() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          var orders = snapshot.docs.map((doc) => AppOrder.fromFirestore(doc)).toList();
          orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
          return orders;
        });
  }

  Stream<List<AppOrder>> getMyFarmerOrders() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('orders')
        .where('farmerId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          var orders = snapshot.docs.map((doc) => AppOrder.fromFirestore(doc)).toList();
          orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
          return orders;
        });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // If order is cancelled, create automatic reversal transaction
    if (status.toLowerCase() == 'cancelled') {
      await _createReversalTransaction(orderId);
    }
    
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
        if (orderDoc.exists) {
        final orderData = orderDoc.data();
        if (orderData == null) {
          debugPrint('Warning: Order $orderId has no data');
          return;
        }
        final buyerId = orderData['buyerId'] as String?;
        if (buyerId == null) {
          debugPrint('Warning: Order $orderId missing buyerId');
          return;
        }
        final items = (orderData['items'] as List<dynamic>?) ?? [];
        String productName = 'Product(s)';
        if (items.isNotEmpty && items.first is Map<String, dynamic>) {
          productName = (items.first as Map<String, dynamic>)['name'] as String? ?? 'Product(s)';
        }
        
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
            body = 'Your order for $productName has been cancelled. Financial reversal has been recorded.';
            break;
          default:
            title = '📬 Order Update';
            body = 'Status changed to: $status';
        }
        
        await _notificationService.showLocalNotificationDirect(
          title: title,
          body: body,
          payload: 'order:$orderId',
        );
        
        await NotificationHelper.addOrderNotification(
          title: title,
          message: body,
          orderId: orderId,
        );
        
        await _notificationService.notifyBuyerOrderStatusChange(
          buyerId: buyerId,
          orderId: orderId,
          productName: productName,
          newStatus: status,
        );
      }
    } catch (e) {
      debugPrint('Failed to send status update notification: $e');
    }
  }

  /// Create automatic reversal transaction when order is cancelled
  Future<void> _createReversalTransaction(String orderId) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) {
        debugPrint('⚠️ Cannot create reversal: Order $orderId not found');
        return;
      }

      // Create reversal transaction in farmer's transaction history
      await _firestore
          .collection('users')
          .doc(order.farmerId)
          .collection('transactions')
          .add({
            'type': 'reversal',
            'category': 'Order Cancellation',
            'amount': -order.totalAmount, // Negative amount reverses the sale
            'description': 'Cancellation reversal - Order #${orderId.substring(0, 8)}...',
            'linkedOrderId': orderId,
            'linkedOrderStatus': 'cancelled',
            'isReversal': true,
            'date': DateTime.now().toIso8601String(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      debugPrint('✅ Reversal transaction created for cancelled order $orderId');
    } catch (e) {
      debugPrint('❌ Error creating reversal transaction: $e');
    }
  }

  Future<void> updateDeliveryDate(String orderId, DateTime date) async {
    await _firestore.collection('orders').doc(orderId).update({
      'estimatedDelivery': Timestamp.fromDate(date),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteOrder(String orderId) async {
    await _firestore.collection('orders').doc(orderId).delete();
  }

  Future<AppOrder?> getOrderById(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (!doc.exists) return null;
    return AppOrder.fromFirestore(doc);
  }

  Future<void> updateOrder(String orderId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('orders').doc(orderId).update(updates);
  }

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
              debugPrint('Error parsing order ${doc.id}: $e');
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
      debugPrint('Error in getBuyerOrdersPaginated: $e');
      rethrow;
    }
  }

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
              debugPrint('Error parsing order ${doc.id}: $e');
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
      debugPrint('Error in getMoreBuyerOrders: $e');
      rethrow;
    }
  }

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

      // Only filter by farmerId to avoid composite index requirement - sort and filter in memory
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
              debugPrint('Error parsing order ${doc.id}: $e');
              return null;
            }
          })
          .whereType<AppOrder>()
          .toList();

      if (statusFilter != null && statusFilter != 'All') {
        orders = orders.where((order) => 
          order.status.toLowerCase() == statusFilter.toLowerCase()
        ).toList();
      }

      orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      final limitedOrders = orders.take(limit).toList();

      return {
        'orders': limitedOrders,
        'lastDocument': null,
        'hasMore': false,
      };
    } catch (e) {
      debugPrint('Error in getFarmerOrdersPaginated: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMoreFarmerOrders({
    required DocumentSnapshot lastDocument,
    int limit = 20,
    String? statusFilter,
  }) async {
    return {
      'orders': <AppOrder>[],
      'lastDocument': null,
      'hasMore': false,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart' show AppOrder;

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new order (buyer creates order)
  Future<void> createOrder(AppOrder order) async {
    await _firestore.collection('orders').doc(order.id).set(order.toFirestore());
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
}

import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final String unit;
  final int quantity;
  final String category;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.unit,
    required this.quantity,
    required this.category,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      quantity: map['quantity'] ?? 1,
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'unit': unit,
      'quantity': quantity,
      'category': category,
    };
  }
}

class AppOrder {
  final String id;
  final String buyerId;
  final String buyerName;
  final String farmerId;
  final String farmerName;
  final List<OrderItem> items;
  final double totalAmount;
  final String status; // pending, confirmed, preparing, delivering, delivered, cancelled
  final DateTime orderDate;
  final DateTime? estimatedDelivery;
  final String? deliveryAddress;
  final String? notes;
  final DateTime? updatedAt;

  AppOrder({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.farmerId,
    required this.farmerName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.estimatedDelivery,
    this.deliveryAddress,
    this.notes,
    this.updatedAt,
  });

  factory AppOrder.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppOrder(
      id: doc.id,
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      farmerId: data['farmerId'] ?? '',
      farmerName: data['farmerName'] ?? '',
      items: (data['items'] as List?)
              ?.map((item) => OrderItem.fromMap(item))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      orderDate: (data['orderDate'] as Timestamp).toDate(),
      estimatedDelivery: data['estimatedDelivery'] != null
          ? (data['estimatedDelivery'] as Timestamp).toDate()
          : null,
      deliveryAddress: data['deliveryAddress'],
      notes: data['notes'],
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'orderDate': Timestamp.fromDate(orderDate),
      'estimatedDelivery': estimatedDelivery != null
          ? Timestamp.fromDate(estimatedDelivery!)
          : null,
      'deliveryAddress': deliveryAddress,
      'notes': notes,
      'createdAt': Timestamp.now(), // Add createdAt timestamp
      // Don't include updatedAt on creation - only on updates
    };
  }

  AppOrder copyWith({
    String? id,
    String? buyerId,
    String? buyerName,
    String? farmerId,
    String? farmerName,
    List<OrderItem>? items,
    double? totalAmount,
    String? status,
    DateTime? orderDate,
    DateTime? estimatedDelivery,
    String? deliveryAddress,
    String? notes,
    DateTime? updatedAt,
  }) {
    return AppOrder(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

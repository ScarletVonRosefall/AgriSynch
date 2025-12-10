import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String farmerId;
  final String farmerName;
  final String buyerId;
  final String buyerName;
  final double rating; // 1.0 to 5.0
  final String? comment;
  final String? orderId; // Optional: link to specific order
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.buyerId,
    required this.buyerName,
    required this.rating,
    this.comment,
    this.orderId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      farmerId: data['farmerId'] ?? '',
      farmerName: data['farmerName'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'],
      orderId: data['orderId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'farmerId': farmerId,
      'farmerName': farmerName,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'rating': rating,
      'comment': comment,
      'orderId': orderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Review copyWith({
    String? id,
    String? farmerId,
    String? farmerName,
    String? buyerId,
    String? buyerName,
    double? rating,
    String? comment,
    String? orderId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      orderId: orderId ?? this.orderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

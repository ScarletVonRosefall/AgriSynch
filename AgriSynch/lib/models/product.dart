import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String unit; // e.g., 'per kg', 'per dozen', 'per head'
  final String category; // e.g., 'Poultry', 'Livestock', 'Crops', 'Vegetables'
  final String farmerId;
  final String farmerName;
  final String location;
  final int stock; // Available quantity
  final List<String> images; // URLs to product images
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAvailable;
  final double? rating; // Average rating from buyers
  final int? reviewCount;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.category,
    required this.farmerId,
    required this.farmerName,
    required this.location,
    required this.stock,
    this.images = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isAvailable = true,
    this.rating,
    this.reviewCount,
  });

  // Convert Firestore document to Product
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] ?? 'per unit',
      category: data['category'] ?? 'Other',
      farmerId: data['farmerId'] ?? '',
      farmerName: data['farmerName'] ?? '',
      location: data['location'] ?? '',
      stock: data['stock'] ?? 0,
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAvailable: data['isAvailable'] ?? true,
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: data['reviewCount'],
    );
  }

  // Convert Product to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'category': category,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'location': location,
      'stock': stock,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isAvailable': isAvailable,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  // Create a copy with updated fields
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? unit,
    String? category,
    String? farmerId,
    String? farmerName,
    String? location,
    int? stock,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAvailable,
    double? rating,
    int? reviewCount,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      location: location ?? this.location,
      stock: stock ?? this.stock,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}

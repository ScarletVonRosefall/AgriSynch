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
  final bool isAdminOnly; // If true, only visible to admin users

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
    this.isAdminOnly = false,
  });

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Product document ${doc.id} has no data');
    }
    
    List<String> imagesList = [];
    if (data['images'] != null) {
      if (data['images'] is List) {
        imagesList = List<String>.from(data['images']);
      } else {
        print('Warning: Product ${doc.id} has invalid images field type: ${data['images'].runtimeType}');
      }
    }
    
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
      images: imagesList,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAvailable: data['isAvailable'] ?? true,
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: data['reviewCount'],
      isAdminOnly: data['isAdminOnly'] ?? false,
    );
  }

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
      'isAdminOnly': isAdminOnly,
    };
  }

  /// Validate product data to prevent Firestore size limit issues
  /// Returns a list of validation errors (empty if valid)
  List<String> validate() {
    final errors = <String>[];

    // Name validation
    if (name.isEmpty) {
      errors.add('Product name cannot be empty');
    }
    if (name.length > 200) {
      errors.add('Product name must be 200 characters or less (${name.length})');
    }

    // Description validation (prevent bloat)
    if (description.length > 5000) {
      errors.add('Product description must be 5000 characters or less (${description.length})');
    }

    // Price validation
    if (price < 0) {
      errors.add('Price cannot be negative');
    }
    if (price > 999999) {
      errors.add('Price exceeds maximum allowed value');
    }

    // Stock validation
    if (stock < 0) {
      errors.add('Stock cannot be negative');
    }
    if (stock > 999999) {
      errors.add('Stock exceeds maximum allowed value');
    }

    // Images validation (prevent storing massive base64 data)
    if (images.length > 10) {
      errors.add('Maximum 10 images allowed (${images.length} provided)');
    }
    for (int i = 0; i < images.length; i++) {
      final imageUrl = images[i];
      // Check if image is base64 (starts with 'data:image')
      if (imageUrl.startsWith('data:image')) {
        errors.add('Image $i: Base64 images not allowed in Firestore. Use URLs only.');
        continue;
      }
      // Check URL length (URLs should be reasonable, not massive)
      if (imageUrl.length > 2000) {
        errors.add('Image $i URL exceeds maximum length (${imageUrl.length} characters)');
      }
    }

    // Unit validation
    if (unit.isEmpty) {
      errors.add('Unit cannot be empty');
    }
    if (unit.length > 50) {
      errors.add('Unit must be 50 characters or less');
    }

    // Category validation
    if (category.isEmpty) {
      errors.add('Category cannot be empty');
    }

    // Location validation
    if (location.isEmpty) {
      errors.add('Location cannot be empty');
    }
    if (location.length > 200) {
      errors.add('Location must be 200 characters or less');
    }

    // FarmerId validation
    if (farmerId.isEmpty) {
      errors.add('Farmer ID cannot be empty');
    }

    // FarmerName validation
    if (farmerName.isEmpty) {
      errors.add('Farmer name cannot be empty');
    }
    if (farmerName.length > 200) {
      errors.add('Farmer name must be 200 characters or less');
    }

    return errors;
  }

  /// Check if this product would exceed Firestore document size when stored
  /// Firestore has a 1MB limit per document
  bool exceedsFirestoreLimit() {
    // Rough estimate: convert to JSON and check byte size
    final json = toFirestore();
    final jsonString = json.toString();
    final bytes = jsonString.codeUnitAt(0) * jsonString.length; // Rough estimate
    
    // Flag if over 500KB to be safe (leaves room for other data)
    return bytes > 500000;
  }

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
    bool? isAdminOnly,
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
      isAdminOnly: isAdminOnly ?? this.isAdminOnly,
    );
  }
}

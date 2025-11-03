import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserName => _auth.currentUser?.displayName;

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  /// Get all available products (for buyers)
  Stream<List<Product>> getAllProducts() {
    return _productsCollection
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          var products = snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .where((product) => product.stock > 0)
              .toList();
          // Sort by date in memory
          products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return products;
        });
  }

  /// Get products by category
  Stream<List<Product>> getProductsByCategory(String category) {
    return _productsCollection
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
          var products = snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .where((product) => product.isAvailable && product.stock > 0)
              .toList();
          // Sort by date in memory
          products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return products;
        });
  }

  /// Get products by farmer ID (for farmer's own product management)
  Stream<List<Product>> getFarmerProducts(String farmerId) {
    return _productsCollection
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) {
          var products = snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
          // Sort by date in memory
          products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return products;
        });
  }

  /// Get current farmer's products
  Stream<List<Product>> getMyProducts() {
    if (currentUserId == null) throw Exception('User not authenticated');
    return getFarmerProducts(currentUserId!);
  }

  /// Search products by name or description
  Stream<List<Product>> searchProducts(String query) {
    // Note: Firestore doesn't support full-text search natively
    // This is a basic implementation - for production, consider Algolia or ElasticSearch
    final queryLower = query.toLowerCase();
    
    return _productsCollection
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .where((product) =>
                product.name.toLowerCase().contains(queryLower) ||
                product.description.toLowerCase().contains(queryLower) ||
                product.category.toLowerCase().contains(queryLower))
            .toList());
  }

  /// Add a new product
  Future<String> addProduct(Product product) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final docRef = await _productsCollection.add(product.toFirestore());
    print('✅ Product added: ${docRef.id}');
    return docRef.id;
  }

  /// Update an existing product
  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Add updatedAt timestamp
    updates['updatedAt'] = Timestamp.fromDate(DateTime.now());

    await _productsCollection.doc(productId).update(updates);
    print('✅ Product updated: $productId');
  }

  /// Delete a product
  Future<void> deleteProduct(String productId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _productsCollection.doc(productId).delete();
    print('✅ Product deleted: $productId');
  }

  /// Update product stock
  Future<void> updateStock(String productId, int newStock) async {
    await updateProduct(productId, {
      'stock': newStock,
      'isAvailable': newStock > 0,
    });
  }

  /// Decrease stock when order is placed
  Future<void> decreaseStock(String productId, int quantity) async {
    final docRef = _productsCollection.doc(productId);
    
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      
      if (!snapshot.exists) {
        throw Exception('Product not found');
      }

      final currentStock = snapshot.data()!['stock'] as int;
      final newStock = currentStock - quantity;

      if (newStock < 0) {
        throw Exception('Insufficient stock');
      }

      transaction.update(docRef, {
        'stock': newStock,
        'isAvailable': newStock > 0,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  /// Increase stock (for cancellations or returns)
  Future<void> increaseStock(String productId, int quantity) async {
    final docRef = _productsCollection.doc(productId);
    
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      
      if (!snapshot.exists) {
        throw Exception('Product not found');
      }

      final currentStock = snapshot.data()!['stock'] as int;
      final newStock = currentStock + quantity;

      transaction.update(docRef, {
        'stock': newStock,
        'isAvailable': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  /// Get a single product by ID
  Future<Product> getProduct(String productId) async {
    final doc = await _productsCollection.doc(productId).get();
    if (!doc.exists) throw Exception('Product not found');
    return Product.fromFirestore(doc);
  }

  /// Toggle product availability
  Future<void> toggleAvailability(String productId, bool isAvailable) async {
    await updateProduct(productId, {'isAvailable': isAvailable});
  }

  // PAGINATION METHODS

  /// Get paginated products (initial load)
  Future<Map<String, dynamic>> getProductsPaginated({
    int limit = 20,
    String? category,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _productsCollection
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (category != null && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Failed to load products. Please check your connection.');
        },
      );
      
      final products = snapshot.docs
          .map((doc) {
            try {
              return Product.fromFirestore(doc);
            } catch (e) {
              print('Error parsing product ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Product>()
          .where((product) => product.stock > 0)
          .toList();

      return {
        'products': products,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length == limit,
      };
    } catch (e) {
      print('Error in getProductsPaginated: $e');
      rethrow;
    }
  }

  /// Get next page of products
  Future<Map<String, dynamic>> getMoreProducts({
    required DocumentSnapshot lastDocument,
    int limit = 20,
    String? category,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _productsCollection
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(lastDocument)
          .limit(limit);

      if (category != null && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Failed to load more products. Please check your connection.');
        },
      );
      
      final products = snapshot.docs
          .map((doc) {
            try {
              return Product.fromFirestore(doc);
            } catch (e) {
              print('Error parsing product ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Product>()
          .where((product) => product.stock > 0)
          .toList();

      return {
        'products': products,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length == limit,
      };
    } catch (e) {
      print('Error in getMoreProducts: $e');
      rethrow;
    }
  }
}

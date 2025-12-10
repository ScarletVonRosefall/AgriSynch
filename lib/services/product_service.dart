import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'rate_limit_service.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserName => _auth.currentUser?.displayName;

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  Future<bool> _isCurrentUserAdmin() async {
    if (currentUserId == null) return false;
    
    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final accountType = userDoc.data()?['accountType'] ?? '';
      return accountType.toLowerCase() == 'admin';
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Public wrapper to check if current user is admin.
  Future<bool> isCurrentUserAdmin() async {
    return _isCurrentUserAdmin();
  }

  Stream<List<Product>> getAllProducts() async* {
    final isAdmin = await _isCurrentUserAdmin();
    
    yield* _productsCollection
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          var products = snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .where((product) => product.stock > 0)
              .toList();
          
          // Filter out admin-only products for non-admin users
          if (!isAdmin) {
            products = products.where((product) => !product.isAdminOnly).toList();
          }
          
          products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return products;
        });
  }

  Stream<List<Product>> getProductsByCategory(String category) async* {
    final isAdmin = await _isCurrentUserAdmin();
    
    yield* _productsCollection
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
          var products = snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .where((product) => product.isAvailable && product.stock > 0)
              .toList();
          
          // Filter out admin-only products for non-admin users
          if (!isAdmin) {
            products = products.where((product) => !product.isAdminOnly).toList();
          }
          
          products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return products;
        });
  }

  Stream<List<Product>> getFarmerProducts(String farmerId) {
    return _productsCollection
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) {
          var products = snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
          products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return products;
        });
  }

  Stream<List<Product>> getMyProducts() {
    if (currentUserId == null) throw Exception('User not authenticated');
    return getFarmerProducts(currentUserId!);
  }

  // For production apps, consider using dedicated search solutions like Algolia
  Stream<List<Product>> searchProducts(String query) async* {
    final queryLower = query.toLowerCase();
    final isAdmin = await _isCurrentUserAdmin();
    
    yield* _productsCollection
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          var products = snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .where((product) =>
                  product.name.toLowerCase().contains(queryLower) ||
                  product.description.toLowerCase().contains(queryLower) ||
                  product.category.toLowerCase().contains(queryLower))
              .toList();
          
          // Filter out admin-only products for non-admin users
          if (!isAdmin) {
            products = products.where((product) => !product.isAdminOnly).toList();
          }
          
          return products;
        });
  }

  Future<String> addProduct(Product product) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Check rate limit
    final canCreate = await RateLimitService.checkRateLimit(
      'product_create',
      userId: currentUserId,
    );
    if (!canCreate) {
      final errorMessage = RateLimitService.getRateLimitMessage('product_create');
      debugPrint('🚫 ProductService: $errorMessage');
      throw Exception(errorMessage);
    }

    final docRef = await _productsCollection.add(product.toFirestore());
    debugPrint('✅ Product added: ${docRef.id}');
    return docRef.id;
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Check rate limit
    final canUpdate = await RateLimitService.checkRateLimit(
      'product_update',
      userId: currentUserId,
    );
    if (!canUpdate) {
      final errorMessage = RateLimitService.getRateLimitMessage('product_update');
      debugPrint('🚫 ProductService: $errorMessage');
      throw Exception(errorMessage);
    }

    updates['updatedAt'] = Timestamp.fromDate(DateTime.now());

    await _productsCollection.doc(productId).update(updates);
    debugPrint('✅ Product updated: $productId');
  }

  Future<void> deleteProduct(String productId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _productsCollection.doc(productId).delete();
    debugPrint('✅ Product deleted: $productId');
  }

  Future<void> updateStock(String productId, int newStock) async {
    await updateProduct(productId, {
      'stock': newStock,
      'isAvailable': newStock > 0,
    });
  }

  Future<void> decreaseStock(String productId, int quantity) async {
    final docRef = _productsCollection.doc(productId);
    
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      
      if (!snapshot.exists) {
        throw Exception('Product not found');
      }

      final data = snapshot.data();
      if (data == null) {
        throw Exception('Product data is invalid');
      }
      final currentStock = data['stock'] as int? ?? 0;
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

  Future<void> increaseStock(String productId, int quantity) async {
    final docRef = _productsCollection.doc(productId);
    
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      
      if (!snapshot.exists) {
        throw Exception('Product not found');
      }

      final data = snapshot.data();
      if (data == null) {
        throw Exception('Product data is invalid');
      }
      final currentStock = data['stock'] as int? ?? 0;
      final newStock = currentStock + quantity;

      transaction.update(docRef, {
        'stock': newStock,
        'isAvailable': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  Future<Product> getProduct(String productId) async {
    final doc = await _productsCollection.doc(productId).get();
    if (!doc.exists) throw Exception('Product not found');
    return Product.fromFirestore(doc);
  }

  Future<void> toggleAvailability(String productId, bool isAvailable) async {
    await updateProduct(productId, {'isAvailable': isAvailable});
  }

  Future<Map<String, dynamic>> getProductsPaginated({
    int limit = 20,
    String? category,
  }) async {
    try {
      // Check if current user is admin
      final isAdmin = await _isCurrentUserAdmin();
      
      // Only filter by isAvailable to avoid composite index requirement - sort and filter in memory
      Query<Map<String, dynamic>> query = _productsCollection
          .where('isAvailable', isEqualTo: true)
          .limit(100); // Get more documents since we'll filter/sort in-memory

      final snapshot = await query.get().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Failed to load products. Please check your connection.');
        },
      );
      
      var products = snapshot.docs
          .map((doc) {
            try {
              return Product.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing product ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Product>()
          .where((product) => product.stock > 0)
          .toList();

      // Filter out admin-only products for non-admin users
      if (!isAdmin) {
        products = products.where((product) => !product.isAdminOnly).toList();
      }

      if (category != null && category != 'All') {
        products = products.where((product) => 
          product.category.toLowerCase() == category.toLowerCase()
        ).toList();
      }

      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final limitedProducts = products.take(limit).toList();

      return {
        'products': limitedProducts,
        'lastDocument': null,
        'hasMore': false,
      };
    } catch (e) {
      debugPrint('Error in getProductsPaginated: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMoreProducts({
    required DocumentSnapshot lastDocument,
    int limit = 20,
    String? category,
  }) async {
    return {
      'products': <Product>[],
      'lastDocument': null,
      'hasMore': false,
    };
  }
}

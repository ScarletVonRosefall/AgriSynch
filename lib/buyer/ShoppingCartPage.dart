import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../models/order.dart';
import '../shared/theme_helper.dart';

class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({super.key});

  @override
  State<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  final OrderService _orderService = OrderService();
  final _themeNotifier = ThemeNotifier();
  List<Map<String, dynamic>> cart = [];
  List<Map<String, dynamic>> orders = [];
  bool _cartChanged = false;

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    loadCart();
    loadOrders();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> loadCart() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      // Try to load from Firestore first
      try {
        debugPrint('🛒 ShoppingCartPage.loadCart: Loading from Firestore for user ${currentUser.uid}');
        final cartDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('cart')
            .doc('items')
            .get();
        
        if (cartDoc.exists && cartDoc.data() != null) {
          final cartDocData = cartDoc.data();
          if (cartDocData != null) {
            final cartData = cartDocData['items'] as List<dynamic>?;
            if (cartData != null) {
              debugPrint('🛒 ShoppingCartPage.loadCart: Found ${cartData.length} items in Firestore');
              for (var i = 0; i < cartData.length; i++) {
                final item = cartData[i];
                debugPrint('  Item $i: id=${item['id']}, name=${item['name']}, qty=${item['quantity']}');
              }
              final loadedCart = List<Map<String, dynamic>>.from(
                cartData.map((item) => Map<String, dynamic>.from(item))
              );
            
            // Fetch product images for items that don't have imageUrl
            for (var item in loadedCart) {
              if (item['imageUrl'] == null || item['imageUrl'].toString().isEmpty) {
                try {
                  final productDoc = await FirebaseFirestore.instance
                      .collection('products')
                      .doc(item['id'])
                      .get();
                  
                  if (productDoc.exists) {
                    final productData = productDoc.data();
                    if (productData != null && productData['images'] != null) {
                      final images = productData['images'] as List<dynamic>;
                      if (images.isNotEmpty) {
                        item['imageUrl'] = images[0];
                      }
                    }
                  }
                } catch (e) {
                  print('Error fetching image for product ${item['id']}: $e');
                }
              }
            }
            
            setState(() {
              cart = loadedCart;
            });
            // Also save to local storage as backup
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('buyer_cart', json.encode(cart));
            return;
            }
          }
        }
      } catch (e) {
        debugPrint('🛒 ShoppingCartPage.loadCart: Error loading from Firestore: $e');
      }
    }
    
    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString('buyer_cart');
    debugPrint('🛒 ShoppingCartPage.loadCart: Checking SharedPreferences for buyer_cart key');
    if (cartString != null) {
      debugPrint('🛒 ShoppingCartPage.loadCart: Found cart in SharedPreferences');
      final loadedCart = List<Map<String, dynamic>>.from(json.decode(cartString));
      debugPrint('🛒 ShoppingCartPage.loadCart: Loaded ${loadedCart.length} items from SharedPreferences');
      for (var i = 0; i < loadedCart.length; i++) {
        final item = loadedCart[i];
        debugPrint('  Item $i: id=${item['id']}, name=${item['name']}, qty=${item['quantity']}');
      }
      
      // Fetch product images for items that don't have imageUrl
      for (var item in loadedCart) {
        if (item['imageUrl'] == null || item['imageUrl'].toString().isEmpty) {
          try {
            final productDoc = await FirebaseFirestore.instance
                .collection('products')
                .doc(item['id'])
                .get();
            
            if (productDoc.exists) {
              final productData = productDoc.data();
              if (productData != null && productData['images'] != null) {
                final images = productData['images'] as List<dynamic>;
                if (images.isNotEmpty) {
                  item['imageUrl'] = images[0];
                }
              }
            }
          } catch (e) {
            print('Error fetching image for product ${item['id']}: $e');
          }
        }
      }
      
      setState(() {
        cart = loadedCart;
      });
      // Save updated cart with images
      await prefs.setString('buyer_cart', json.encode(cart));
    }
  }

  Future<void> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersString = prefs.getString('buyer_orders');
    if (ordersString != null) {
      setState(() {
        orders = List<Map<String, dynamic>>.from(json.decode(ordersString));
      });
    }
  }

  // Strip cart items to essential fields only (prevent Firestore size limit issues)
  List<Map<String, dynamic>> _getCleanCartForFirestore(List<Map<String, dynamic>> cartItems) {
    return cartItems.map((item) {
      // Ensure we never persist base64 image data into Firestore cart documents
      var imageUrl = item['imageUrl'];
      if (imageUrl is String && imageUrl.startsWith('data:image')) {
        imageUrl = ''; // strip base64 images from cart storage
      }

      return {
        'id': item['id'],
        'name': item['name'],
        'price': item['price'],
        'unit': item['unit'],
        'category': item['category'],
        'farmer': item['farmer'],
        'farmerId': item['farmerId'],
        'location': item['location'],
        'imageUrl': imageUrl ?? '',
        'quantity': item['quantity'],
        'dateAdded': item['dateAdded'] ?? DateTime.now().toIso8601String(),
      };
    }).toList();
  }

  Future<void> updateCart() async {
    // Save to SharedPreferences (can store everything)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('buyer_cart', json.encode(cart));
    _cartChanged = true;
    
    // Save to Firestore (strip unnecessary fields to avoid size limit)
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final cleanCart = _getCleanCartForFirestore(cart);
        debugPrint('🛒 updateCart: Saving ${cleanCart.length} items to Firestore');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('cart')
            .doc('items')
            .set({
              'items': cleanCart,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        debugPrint('🛒 Error saving cart to Firestore: $e');
        // Continue anyway - local storage is saved
      }
    }
  }

  Future<void> updateQuantity(int index, int newQuantity) async {
    if (newQuantity <= 0) {
      removeItem(index);
      return;
    }

    final oldQuantity = cart[index]['quantity'] as int? ?? 0;

    // If increasing quantity, validate against product stock
    if (newQuantity > oldQuantity) {
      try {
        final productId = cart[index]['id'] as String? ?? '';
        final productService = ProductService();
        final product = await productService.getProduct(productId);
        final availableStock = product.stock;

        if (newQuantity > availableStock) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Only $availableStock item(s) available'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('Error checking stock for product when updating quantity: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to verify product stock. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      cart[index]['quantity'] = newQuantity;
    });
    await updateCart();
  }

  Future<void> removeItem(int index) async {
    setState(() {
      cart.removeAt(index);
    });
    await updateCart();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item removed from cart'),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> clearCart() async {
    setState(() {
      cart.clear();
    });
    await updateCart();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cart cleared'),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> checkout() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get current user from Firebase Auth
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User authentication error'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get user details from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    
    final String userName = userDoc.data()?['name'] ?? 'Unknown User';
    final String userId = currentUser.uid;

    // Group cart items by farmer
    Map<String, List<Map<String, dynamic>>> ordersByFarmer = {};
    for (var item in cart) {
      String farmerId = item['farmerId'] ?? '';
      if (ordersByFarmer.containsKey(farmerId)) {
        ordersByFarmer[farmerId]!.add(item);
      } else {
        ordersByFarmer[farmerId] = [item];
      }
    }

    try {
      // Create separate orders for each farmer
      for (var entry in ordersByFarmer.entries) {
        String farmerId = entry.key;
        List<Map<String, dynamic>> farmerItems = entry.value;
        
        // Get farmer name from first item
        String farmerName = farmerItems.first['farmer'] ?? 'Unknown Farmer';
        
        // Calculate total for this farmer's products
        double totalAmount = farmerItems.fold(
          0.0,
          (sum, item) => sum + (item['price'] * item['quantity']),
        );

        // Create order items
        List<OrderItem> orderItems = farmerItems.map((item) {
          return OrderItem(
            productId: item['id'] ?? '',
            name: item['name'] ?? '',
            price: (item['price'] ?? 0).toDouble(),
            unit: item['unit'] ?? '',
            quantity: item['quantity'] ?? 1,
            category: item['category'] ?? '',
          );
        }).toList();

        // Create order
        final orderId = DateTime.now().millisecondsSinceEpoch.toString();
        final order = AppOrder(
          id: orderId,
          buyerId: userId,
          buyerName: userName,
          farmerId: farmerId,
          farmerName: farmerName,
          items: orderItems,
          totalAmount: totalAmount,
          status: 'pending',
          orderDate: DateTime.now(),
          estimatedDelivery: DateTime.now().add(const Duration(days: 3)),
        );

        // Save to Firestore
        await _orderService.createOrder(order);
        
        // Note: Stock is already decremented in createOrder() method
      }

      // Clear cart
      await clearCart();

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 32),
                SizedBox(width: 12),
                Text('Order Placed!'),
              ],
            ),
            content: Text(
              '${ordersByFarmer.length} order(s) have been placed successfully.\nEstimated delivery: 3 days',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, _cartChanged); // Go back to home and notify previous route
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double getTotalPrice() {
    return cart.fold(0.0, (total, item) {
      return total + (item['price'] * item['quantity']);
    });
  }

  int getTotalItems() {
    return cart.fold(0, (total, item) {
      return total + (item['quantity'] as int);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _cartChanged);
        return false; // Prevent the default pop since we're handling it
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2332),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context, _cartChanged);
                      } else {
                        Navigator.pushReplacementNamed(context, '/buyer-home');
                      }
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    iconSize: 22,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                const Expanded(
                  child: Text(
                    'Shopping Cart',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (cart.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear Cart'),
                          content: const Text(
                            'Are you sure you want to remove all items?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                clearCart();
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.clear_all, color: Colors.white),
                    iconSize: 22,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),

          // Cart Items
          if (cart.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.white.withAlpha((0.4 * 255).round()),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some products to get started!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.white.withAlpha((0.6 * 255).round()),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Cart Items List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2332),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withAlpha((0.1 * 255).round()),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Product Image
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha((0.1 * 255).round()),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty
                                        ? _buildProductImage(item['imageUrl'], item['category'])
                                        : Icon(
                                            _getProductIcon(item['category']),
                                            color: const Color(0xFF1DBF73),
                                            size: 40,
                                          ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Product Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        'by ${item['farmer']}',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Colors.white.withAlpha((0.6 * 255).round()),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'P${item['price'].toStringAsFixed(2)} ${item['unit']}',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Color(0xFF1DBF73),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Quantity Controls & Delete
                                Column(
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () => updateQuantity(
                                            index,
                                            item['quantity'] - 1,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withAlpha((0.1 * 255).round()),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.remove,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: Text(
                                            '${item['quantity']}',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => updateQuantity(
                                            index,
                                            item['quantity'] + 1,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withAlpha((0.1 * 255).round()),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () => removeItem(index),
                                      child: Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Checkout Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2332),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withAlpha((0.1 * 255).round()),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${getTotalItems()} items',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Colors.white.withAlpha((0.6 * 255).round()),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'P${getTotalPrice().toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: checkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1DBF73),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Checkout',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl, String category) {
    try {
      if (imageUrl.startsWith('data:image')) {
        // Base64 image
        final base64String = imageUrl.split(',')[1];
        return Image.memory(
          base64Decode(base64String),
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              _getProductIcon(category),
              color: const Color(0xFF1DBF73),
              size: 40,
            );
          },
        );
      } else {
        // Network URL image
        return Image.network(
          imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              _getProductIcon(category),
              color: const Color(0xFF1DBF73),
              size: 40,
            );
          },
        );
      }
    } catch (e) {
      return Icon(
        _getProductIcon(category),
        color: const Color(0xFF1DBF73),
        size: 40,
      );
    }
  }

  IconData _getProductIcon(String category) {
    switch (category) {
      case 'Vegetables':
        return Icons.eco;
      case 'Fruits':
        return Icons.apple;
      case 'Grains':
        return Icons.grain;
      case 'Dairy':
        return Icons.local_drink;
      case 'Poultry':
        return Icons.egg;
      default:
        return Icons.shopping_basket;
    }
  }
}

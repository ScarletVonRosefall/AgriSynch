import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../services/order_service.dart';
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
        final cartDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('cart')
            .doc('items')
            .get();
        
        if (cartDoc.exists && cartDoc.data() != null) {
          final cartData = cartDoc.data()!['items'] as List<dynamic>?;
          if (cartData != null) {
            setState(() {
              cart = List<Map<String, dynamic>>.from(
                cartData.map((item) => Map<String, dynamic>.from(item))
              );
            });
            // Also save to local storage as backup
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('buyer_cart', json.encode(cart));
            return;
          }
        }
      } catch (e) {
        print('Error loading cart from Firestore: $e');
      }
    }
    
    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString('buyer_cart');
    if (cartString != null) {
      setState(() {
        cart = List<Map<String, dynamic>>.from(json.decode(cartString));
      });
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

  Future<void> updateCart() async {
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('buyer_cart', json.encode(cart));
    
    // Save to Firestore
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('cart')
            .doc('items')
            .set({
              'items': cart,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        print('Error saving cart to Firestore: $e');
        // Continue anyway - local storage is saved
      }
    }
  }

  Future<void> updateQuantity(int index, int newQuantity) async {
    if (newQuantity <= 0) {
      removeItem(index);
      return;
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
                  Navigator.pop(context); // Go back to home
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
    final isDarkMode = _themeNotifier.isDarkMode;
    final backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF2FBE0);
    final headerColor = isDarkMode
        ? const Color(0xFF2E7D32)
        : const Color(0xFF00C853);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    'Shopping Cart',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 24,
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
                      color: textColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some products to get started!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: textColor.withOpacity(0.5),
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
                  // Cart Summary
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${getTotalItems()} items',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Total: P${getTotalPrice().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Checkout',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cart Items List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index];

                        return Card(
                          color: cardColor,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Product Icon
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getProductIcon(item['category']),
                                    color: const Color(0xFF4CAF50),
                                    size: 30,
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
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'by ${item['farmer']}',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: textColor.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'P${item['price'].toStringAsFixed(2)} ${item['unit']}',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: const Color(0xFF4CAF50),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Quantity Controls
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
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.remove,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            '${item['quantity']}',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => updateQuantity(
                                            index,
                                            item['quantity'] + 1,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF4CAF50),
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
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => removeItem(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: Colors.red,
                                        ),
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
                ],
              ),
            ),
        ],
      ),
    );
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

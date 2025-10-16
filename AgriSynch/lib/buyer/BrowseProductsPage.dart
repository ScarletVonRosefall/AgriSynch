import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BrowseProductsPage extends StatefulWidget {
  const BrowseProductsPage({super.key});

  @override
  State<BrowseProductsPage> createState() => _BrowseProductsPageState();
}

class _BrowseProductsPageState extends State<BrowseProductsPage> {
  bool isDarkMode = false;
  String searchQuery = '';
  List<String> favoriteProducts = [];
  List<Map<String, dynamic>> cart = [];

  // Actual farm products data
  List<Map<String, dynamic>> products = [
    {
      'id': '1',
      'name': 'Fresh Quail Eggs',
      'price': 220.0,
      'unit': 'per dozen',
      'category': 'Poultry',
      'farmer': 'Juan Dela Cruz',
      'location': 'Bataan',
      'rating': 4.9,
      'image': 'assets/quail_eggs.jpg',
      'description': 'Premium fresh quail eggs, rich in protein and nutrients.',
      'stock': 45,
    },
    {
      'id': '2',
      'name': 'Farm Fresh Chicken Eggs',
      'price': 180.0,
      'unit': 'per dozen',
      'category': 'Poultry',
      'farmer': 'Maria Santos',
      'location': 'Nueva Ecija',
      'rating': 4.8,
      'image': 'assets/chicken_eggs.jpg',
      'description': 'Large brown eggs from free-range chickens.',
      'stock': 80,
    },
    {
      'id': '3',
      'name': 'Live Pigs (Lechon Ready)',
      'price': 12500.0,
      'unit': 'per head',
      'category': 'Livestock',
      'farmer': 'Pedro Reyes',
      'location': 'Laguna',
      'rating': 4.7,
      'image': 'assets/pigs.jpg',
      'description': 'Healthy pigs ready for lechon, weight 40-50kg.',
      'stock': 8,
    },
  ];

  @override
  void initState() {
    super.initState();
    loadTheme();
    loadFavorites();
    loadCart();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesString = prefs.getString('favorite_products');
    if (favoritesString != null) {
      setState(() {
        favoriteProducts = List<String>.from(json.decode(favoritesString));
      });
    }
  }

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString('buyer_cart');
    if (cartString != null) {
      setState(() {
        cart = List<Map<String, dynamic>>.from(json.decode(cartString));
      });
    }
  }

  Future<void> toggleFavorite(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (favoriteProducts.contains(productId)) {
        favoriteProducts.remove(productId);
      } else {
        favoriteProducts.add(productId);
      }
    });
    await prefs.setString('favorite_products', json.encode(favoriteProducts));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          favoriteProducts.contains(productId) 
            ? 'Added to favorites!' 
            : 'Removed from favorites!',
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 1),
      ),
    );
    }
  }

  Future<void> addToCart(Map<String, dynamic> product) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if product already in cart
    final existingIndex = cart.indexWhere((item) => item['id'] == product['id']);
    
    setState(() {
      if (existingIndex >= 0) {
        // Increase quantity
        cart[existingIndex]['quantity'] = (cart[existingIndex]['quantity'] ?? 1) + 1;
      } else {
        // Add new item
        cart.add({
          ...product,
          'quantity': 1,
          'dateAdded': DateTime.now().toIso8601String(),
        });
      }
    });
    
    await prefs.setString('buyer_cart', json.encode(cart));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to cart!'),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 1),
      ),
    );
    }
  }

  List<Map<String, dynamic>> getFilteredProducts() {
    return products.where((product) {
      final matchesSearch = product['name'].toLowerCase().contains(searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF2FBE0);
    final headerColor = isDarkMode ? const Color(0xFF2E7D32) : const Color(0xFF00C853);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Browse Products',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Products Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: getFilteredProducts().length,
              itemBuilder: (context, index) {
                final product = getFilteredProducts()[index];
                final isFavorite = favoriteProducts.contains(product['id']);
                
                return Card(
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              child: Icon(
                                _getProductIcon(product['category']),
                                size: 60,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                            // Favorite Button
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => toggleFavorite(product['id']),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : Colors.grey,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Product Info
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'],
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'by ${product['farmer']}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '₱${product['price'].toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF4CAF50),
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          product['unit'],
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: textColor.withOpacity(0.7),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => addToCart(product),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
      case 'Livestock':
        return Icons.pets;
      default:
        return Icons.shopping_basket;
    }
  }
}

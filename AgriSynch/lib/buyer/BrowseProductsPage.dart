import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product.dart';
import '../services/product_service.dart';
import '../shared/theme_helper.dart';

class BrowseProductsPage extends StatefulWidget {
  final String? initialCategory;
  
  const BrowseProductsPage({super.key, this.initialCategory});

  @override
  State<BrowseProductsPage> createState() => _BrowseProductsPageState();
}

class _BrowseProductsPageState extends State<BrowseProductsPage> {
  final ProductService _productService = ProductService();
  bool isDarkMode = false;
  String searchQuery = '';
  late String selectedCategory;
  List<String> favoriteProducts = [];
  List<Map<String, dynamic>> cart = [];

  final List<String> categories = [
    'All',
    'Poultry',
    'Livestock',
    'Crops',
    'Vegetables',
    'Fruits',
    'Dairy',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory ?? 'All';
    loadTheme();
    loadFavorites();
    loadCart();
  }

  Future<void> loadTheme() async {
    isDarkMode = await ThemeHelper.isDarkModeEnabled();
    setState(() {});
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

  Future<void> addToCart(Product product) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if product already in cart
    final existingIndex = cart.indexWhere(
      (item) => item['id'] == product.id,
    );

    setState(() {
      if (existingIndex >= 0) {
        // Increase quantity
        cart[existingIndex]['quantity'] =
            (cart[existingIndex]['quantity'] ?? 1) + 1;
      } else {
        // Add new item
        cart.add({
          'id': product.id,
          'name': product.name,
          'price': product.price,
          'unit': product.unit,
          'category': product.category,
          'farmer': product.farmerName,
          'farmerId': product.farmerId,
          'location': product.location,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            width: double.infinity,
            decoration: ThemeHelper.getHeaderDecoration(isDark: isDarkMode),
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
                      ),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart, color: Colors.white),
                          onPressed: () {
                            // Navigate to cart
                          },
                        ),
                        if (cart.isNotEmpty)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${cart.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
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
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Category Filter
                SizedBox(
                  height: 50,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => selectedCategory = category);
                            },
                            backgroundColor: Colors.white.withOpacity(0.85),
                            selectedColor: Colors.white,
                            labelStyle: TextStyle(
                              color: const Color(0xFF2E7D32),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                            ),
                            checkmarkColor: const Color(0xFF2E7D32),
                            side: isSelected 
                              ? const BorderSide(color: Color(0xFF2E7D32), width: 2)
                              : BorderSide.none,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Products Grid - StreamBuilder for real-time data
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: selectedCategory == 'All'
                  ? _productService.getAllProducts()
                  : _productService.getProductsByCategory(selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading products: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                List<Product> products = snapshot.data ?? [];

                // Apply search filter
                if (searchQuery.isNotEmpty) {
                  products = products.where((product) =>
                    product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                    product.description.toLowerCase().contains(searchQuery.toLowerCase())
                  ).toList();
                }

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'No products found for "$searchQuery"'
                              : 'No products available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for new products',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isFavorite = favoriteProducts.contains(product.id);

                    return Card(
                      elevation: 2,
                      color: ThemeHelper.getCardColor(isDarkMode),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image/Icon
                          Stack(
                            children: [
                              Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(product.category).withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  image: product.images.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(product.images.first),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: product.images.isEmpty
                                    ? Icon(
                                        _getCategoryIcon(product.category),
                                        size: 60,
                                        color: _getCategoryColor(product.category),
                                      )
                                    : null,
                              ),
                              // Favorite Button
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : Colors.white,
                                    shadows: const [Shadow(blurRadius: 2)],
                                  ),
                                  onPressed: () => toggleFavorite(product.id),
                                ),
                              ),
                              // Stock badge
                              if (product.stock < 10)
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: product.stock > 0 ? Colors.orange : Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      product.stock > 0 ? 'Low Stock' : 'Out of Stock',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          // Product Details
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode).copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₱${product.price.toStringAsFixed(2)} ${product.unit}',
                                    style: const TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          product.farmerName,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          product.location,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: product.stock > 0 
                                          ? () => addToCart(product)
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: ThemeHelper.getHeaderColor(isDarkMode),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      child: const Text('Add to Cart', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'poultry':
        return const Color(0xFFFFA726);
      case 'livestock':
        return const Color(0xFFEF5350);
      case 'crops':
        return const Color(0xFF66BB6A);
      case 'vegetables':
        return const Color(0xFF4CAF50);
      case 'fruits':
        return const Color(0xFFEC407A);
      case 'dairy':
        return const Color(0xFF42A5F5);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'poultry':
        return Icons.egg_outlined;
      case 'livestock':
        return Icons.pets;
      case 'crops':
        return Icons.grass;
      case 'vegetables':
        return Icons.spa;
      case 'fruits':
        return Icons.apple;
      case 'dairy':
        return Icons.water_drop;
      default:
        return Icons.shopping_basket;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/error_handler.dart';
import '../shared/theme_helper.dart';
import '../shared/currency_helper.dart';
import 'ShoppingCartPage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../shared/chat_screen.dart';
import '../shared/farmer_reviews_page.dart';
import '../services/review_service.dart';

class BrowseProductsPage extends StatefulWidget {
  final String? initialCategory;
  
  const BrowseProductsPage({super.key, this.initialCategory});

  @override
  State<BrowseProductsPage> createState() => _BrowseProductsPageState();
}

class _BrowseProductsPageState extends State<BrowseProductsPage> {
  final ProductService _productService = ProductService();
  final _themeNotifier = ThemeNotifier();
  String searchQuery = '';
  late String selectedCategory;
  List<String> favoriteProducts = [];
  List<Map<String, dynamic>> cart = [];
  String _currencySymbol = 'P'; // Will be loaded from settings
  
  // Pagination
  final int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
  List<Product> _allProducts = [];
  final ScrollController _scrollController = ScrollController();
  
  // New filter states
  String selectedLocation = 'All';
  double minPrice = 0;
  double maxPrice = 10000;
  String sortBy = 'newest'; // newest, price_low, price_high

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
  
  final List<String> sortOptions = [
    'Newest First',
    'Price: Low to High',
    'Price: High to Low',
  ];

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory ?? 'All';
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    _loadCurrencySymbol();
    loadFavorites();
    loadCart();
    _loadInitialProducts();
    _scrollController.addListener(_onScroll);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCurrencySymbol() async {
    final symbol = await CurrencyHelper.getCurrentCurrencySymbol();
    if (mounted) {
      setState(() {
        _currencySymbol = symbol;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _loadInitialProducts() async {
    setState(() {
      _isInitialLoading = true;
      _allProducts = [];
      _lastDocument = null;
      _hasMoreData = true;
    });

    try {
      final result = await _productService.getProductsPaginated(
        limit: _pageSize,
        category: selectedCategory == 'All' ? null : selectedCategory,
      );

      if (!mounted) return;

      setState(() {
        _allProducts = result['products'] as List<Product>;
        _lastDocument = result['lastDocument'] as DocumentSnapshot?;
        _hasMoreData = result['hasMore'] as bool;
        _isInitialLoading = false;
      });
    } catch (e) {
      ErrorHandler.logError('BrowseProductsPage._loadInitialProducts', e);
      
      if (!mounted) return;
      
      setState(() {
        _isInitialLoading = false;
      });

      ErrorHandler.showErrorSnackBar(
        context,
        e,
        customMessage: ErrorHandler.isNetworkError(e)
            ? 'No internet connection. Please check your network.'
            : null,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadInitialProducts,
        ),
      );
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_lastDocument == null || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _productService.getMoreProducts(
        lastDocument: _lastDocument!,
        limit: _pageSize,
        category: selectedCategory == 'All' ? null : selectedCategory,
      );

      if (!mounted) return;

      setState(() {
        _allProducts.addAll(result['products'] as List<Product>);
        _lastDocument = result['lastDocument'] as DocumentSnapshot?;
        _hasMoreData = result['hasMore'] as bool;
        _isLoadingMore = false;
      });
    } catch (e) {
      ErrorHandler.logError('BrowseProductsPage._loadMoreProducts', e);
      
      if (!mounted) return;
      
      setState(() {
        _isLoadingMore = false;
      });

      if (ErrorHandler.shouldRetry(e)) {
        ErrorHandler.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to load more products',
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _loadMoreProducts,
          ),
        );
      } else {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
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
    try {
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

      // Save to SharedPreferences
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
              }).timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  print('Firestore cart sync timed out - local cart saved');
                },
              );
        } catch (e) {
          ErrorHandler.logError('addToCart - Firestore sync', e);
          // Continue anyway - local storage is saved
        }
      }

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Added to cart!',
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      ErrorHandler.logError('addToCart', e);
      
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to add item to cart',
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => addToCart(product),
          ),
        );
      }
    }
  }

  // Filter and sort products
  List<Product> filterAndSortProducts(List<Product> products) {
    var filtered = products;

    // Apply search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((p) =>
        p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        p.farmerName.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

    // Apply location filter
    if (selectedLocation != 'All') {
      filtered = filtered.where((p) =>
        p.location.toLowerCase().contains(selectedLocation.toLowerCase())
      ).toList();
    }

    // Apply price range filter
    filtered = filtered.where((p) =>
      p.price >= minPrice && p.price <= maxPrice
    ).toList();

    // Apply sorting
    switch (sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
      default:
        // Newest first (default Firestore order)
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            width: double.infinity,
            decoration: ThemeHelper.getHeaderDecoration(isDark: isDarkMode),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 16),
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
                          onPressed: () async {
                            // Navigate to cart page
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ShoppingCartPage(),
                              ),
                            );
                            
                            // Reload cart after returning from cart page
                            if (result == true) {
                              loadCart();
                            }
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
                              setState(() {
                                selectedCategory = category;
                              });
                              _loadInitialProducts(); // Reload products when category changes
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
                const SizedBox(height: 12),
                // Filter and Sort Row
                Row(
                  children: [
                    // Filter Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showFilterDialog(),
                        icon: const Icon(Icons.filter_list, size: 18),
                        label: const Text('Filters'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showSortDialog(),
                        icon: const Icon(Icons.sort, size: 18),
                        label: Text(_getSortLabel()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Products Grid - Paginated data
          Expanded(
            child: _isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    // Apply all filters and sorting
    List<Product> filteredProducts = filterAndSortProducts(_allProducts);

    if (filteredProducts.isEmpty) {
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
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredProducts.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at the end
        if (index == filteredProducts.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final product = filteredProducts[index];

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
                                          image: _getImageProvider(product.images.first),
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
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode).copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$_currencySymbol${product.price.toStringAsFixed(2)} ${product.unit}',
                                    style: const TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FarmerReviewsPage(
                                                  farmerId: product.farmerId,
                                                  farmerName: product.farmerName,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Row(
                                            children: [
                                              Text(
                                                product.farmerName,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.w500,
                                                  decoration: TextDecoration.underline,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(width: 4),
                                              // Farmer Rating
                                              FutureBuilder<Map<String, dynamic>>(
                                                future: ReviewService.getFarmerRatingStats(product.farmerId),
                                                builder: (context, snapshot) {
                                                  if (!snapshot.hasData) return const SizedBox.shrink();
                                                  final rating = snapshot.data?['averageRating'] ?? 0.0;
                                                  if (rating == 0.0) return const SizedBox.shrink();
                                                  return Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.star, size: 12, color: Colors.amber),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        rating.toStringAsFixed(1),
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.grey,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
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
                                          product.location.isEmpty ? 'No location' : product.location,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDarkMode ? const Color(0xFF9E9E9E) : Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Contact Farmer Button
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ChatScreen(
                                                  otherUserId: product.farmerId,
                                                  otherUserName: product.farmerName,
                                                  productId: product.id,
                                                  productName: product.name,
                                                ),
                                              ),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: ThemeHelper.getHeaderColor(isDarkMode),
                                            side: BorderSide(color: ThemeHelper.getHeaderColor(isDarkMode)),
                                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                            minimumSize: const Size(0, 36),
                                          ),
                                          child: const Icon(Icons.message, size: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // Add to Cart Button
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton(
                                          onPressed: product.stock > 0 
                                              ? () => addToCart(product)
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: ThemeHelper.getHeaderColor(isDarkMode),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                            minimumSize: const Size(0, 36),
                                          ),
                                          child: const Text('Add to Cart', style: TextStyle(fontSize: 10)),
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

  String _getSortLabel() {
    switch (sortBy) {
      case 'price_low':
        return 'Price: Low-High';
      case 'price_high':
        return 'Price: High-Low';
      case 'newest':
      default:
        return 'Newest First';
    }
  }

  void _showFilterDialog() {
    final isDarkMode = _themeNotifier.isDarkMode;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: ThemeHelper.getCardColor(isDarkMode),
            title: Text('Filter Products', style: TextStyle(
              color: ThemeHelper.getTextColor(isDarkMode),
            )),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Filter
                  Text('Location', style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ThemeHelper.getTextColor(isDarkMode),
                  )),
                  const SizedBox(height: 8),
                  TextField(
                    style: TextStyle(color: ThemeHelper.getTextColor(isDarkMode)),
                    decoration: InputDecoration(
                      hintText: 'Enter location...',
                      hintStyle: TextStyle(color: ThemeHelper.getSecondaryTextColor(isDarkMode)),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on, color: ThemeHelper.getTextColor(isDarkMode)),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedLocation = value.isEmpty ? 'All' : value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Price Range
                  Text('Price Range', style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ThemeHelper.getTextColor(isDarkMode),
                  )),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: TextStyle(color: ThemeHelper.getTextColor(isDarkMode)),
                          decoration: InputDecoration(
                            labelText: 'Min Price',
                            labelStyle: TextStyle(color: ThemeHelper.getSecondaryTextColor(isDarkMode)),
                            border: const OutlineInputBorder(),
                            prefixText: _currencySymbol,
                            prefixStyle: TextStyle(color: ThemeHelper.getTextColor(isDarkMode)),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setDialogState(() {
                              minPrice = double.tryParse(value) ?? 0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          style: TextStyle(color: ThemeHelper.getTextColor(isDarkMode)),
                          decoration: InputDecoration(
                            labelText: 'Max Price',
                            labelStyle: TextStyle(color: ThemeHelper.getSecondaryTextColor(isDarkMode)),
                            border: const OutlineInputBorder(),
                            prefixText: _currencySymbol,
                            prefixStyle: TextStyle(color: ThemeHelper.getTextColor(isDarkMode)),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setDialogState(() {
                              maxPrice = double.tryParse(value) ?? 10000;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_currencySymbol${minPrice.toStringAsFixed(0)} - $_currencySymbol${maxPrice.toStringAsFixed(0)}',
                    style: TextStyle(color: ThemeHelper.getSecondaryTextColor(isDarkMode), fontSize: 12),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    selectedLocation = 'All';
                    minPrice = 0;
                    maxPrice = 10000;
                  });
                },
                child: const Text('Reset'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {}); // Refresh main UI
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Newest First'),
              value: 'newest',
              groupValue: sortBy,
              onChanged: (value) {
                setState(() => sortBy = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Price: Low to High'),
              value: 'price_low',
              groupValue: sortBy,
              onChanged: (value) {
                setState(() => sortBy = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Price: High to Low'),
              value: 'price_high',
              groupValue: sortBy,
              onChanged: (value) {
                setState(() => sortBy = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get ImageProvider for both base64 and URL images
  ImageProvider _getImageProvider(String imageData) {
    if (imageData.startsWith('data:image')) {
      // Base64 image
      return MemoryImage(base64Decode(imageData.split(',')[1]));
    } else {
      // URL image - use CachedNetworkImageProvider
      return CachedNetworkImageProvider(imageData);
    }
  }
}

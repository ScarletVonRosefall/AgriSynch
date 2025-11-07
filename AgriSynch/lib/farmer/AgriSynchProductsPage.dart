import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/image_upload_service.dart';
import '../services/validation_service.dart';
import '../shared/theme_helper.dart';
import '../shared/notification_helper.dart';
import '../shared/AgriNotificationPage.dart';
import '../shared/input_validator.dart';
import '../shared/currency_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AgriSynchProductsPage extends StatefulWidget {
  const AgriSynchProductsPage({super.key});

  @override
  State<AgriSynchProductsPage> createState() => _AgriSynchProductsPageState();
}

class _AgriSynchProductsPageState extends State<AgriSynchProductsPage> {
  final ProductService _productService = ProductService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final _themeNotifier = ThemeNotifier();
  int unreadNotifications = 0;
  String _searchQuery = '';
  String _categoryFilter = 'All';
  String _currencySymbol = '₱'; // Will be loaded from settings

  final List<String> _categories = [
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
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    _loadUnreadNotifications();
    _loadCurrencySymbol();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload currency when returning to this page
    _loadCurrencySymbol();
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
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> _loadUnreadNotifications() async {
    unreadNotifications = await NotificationHelper.getUnreadCount();
    setState(() {});
  }

  void _showAddProductDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final locationController = TextEditingController();
    String selectedCategory = 'Poultry';
    String selectedUnit = 'per kg';

    final units = ['per kg', 'per dozen', 'per head', 'per piece', 'per bundle', 'per sack'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Product'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name*',
                      hintText: 'e.g., Fresh Chicken Eggs',
                    ),
                    validator: ValidationService.validateProductName,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description*',
                      hintText: 'Describe your product...',
                    ),
                    validator: ValidationService.validateDescription,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Price ($_currencySymbol)*',
                            hintText: '0.00',
                          ),
                          validator: ValidationService.validatePrice,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: units.map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        )).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedUnit = value!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.where((c) => c != 'All').map((category) =>
                    DropdownMenuItem(value: category, child: Text(category)),
                  ).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedCategory = value!);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity*',
                    hintText: '0',
                  ),
                  validator: ValidationService.validateStock,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'e.g., Bataan, Philippines',
                  ),
                  validator: ValidationService.validateOptionalDescription,
                ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate form
                if (!formKey.currentState!.validate()) {
                  return;
                }

                // Comprehensive input sanitization
                final sanitizedName = InputValidator.sanitizeText(nameController.text);
                final sanitizedDescription = InputValidator.sanitizeDescription(descriptionController.text);
                final sanitizedLocation = InputValidator.sanitizeAddress(locationController.text);
                
                // Validate sanitized inputs
                final nameError = InputValidator.validateText(
                  sanitizedName,
                  fieldName: 'Product name',
                  minLength: 2,
                  maxLength: 100,
                );
                
                if (nameError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(nameError), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                // Check for dangerous content
                if (InputValidator.containsDangerousContent(nameController.text) ||
                    InputValidator.containsDangerousContent(descriptionController.text) ||
                    InputValidator.containsDangerousContent(locationController.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid characters detected. Please use only standard characters.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final product = Product(
                    id: '',
                    name: sanitizedName,
                    description: sanitizedDescription,
                    price: double.parse(priceController.text),
                    unit: selectedUnit,
                    category: selectedCategory,
                    farmerId: _productService.currentUserId!,
                    farmerName: _productService.currentUserName ?? 'Farmer',
                    location: sanitizedLocation,
                    stock: int.parse(stockController.text.isNotEmpty ? stockController.text : '0'),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  await _productService.addProduct(product);

                  if (!mounted) return;
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  await NotificationHelper.addNotification(
                    title: 'Product Listed',
                    message: '${product.name} is now available for buyers',
                    type: 'system',
                  );
                  _loadUnreadNotifications();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding product: $e')),
                  );
                }
              },
              child: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product.name);
    final descriptionController = TextEditingController(text: product.description);
    final priceController = TextEditingController(text: product.price.toString());
    final stockController = TextEditingController(text: product.stock.toString());
    final locationController = TextEditingController(text: product.location);
    String selectedCategory = product.category;
    String selectedUnit = product.unit;
    bool isAvailable = product.isAvailable;

    final units = ['per kg', 'per dozen', 'per head', 'per piece', 'per bundle', 'per sack'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Product Name*'),
                    validator: ValidationService.validateProductName,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description*'),
                    validator: ValidationService.validateDescription,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: 'Price ($_currencySymbol)*'),
                          validator: ValidationService.validatePrice,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: units.map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        )).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedUnit = value!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.where((c) => c != 'All').map((category) =>
                    DropdownMenuItem(value: category, child: Text(category)),
                  ).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedCategory = value!);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Stock Quantity*'),
                  validator: ValidationService.validateStock,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: ValidationService.validateOptionalDescription,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Available for Sale'),
                  value: isAvailable,
                  onChanged: (value) {
                    setDialogState(() => isAvailable = value);
                  },
                ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate form
                if (!formKey.currentState!.validate()) {
                  return;
                }

                // Comprehensive input sanitization
                final sanitizedName = InputValidator.sanitizeText(nameController.text);
                final sanitizedDescription = InputValidator.sanitizeDescription(descriptionController.text);
                final sanitizedLocation = InputValidator.sanitizeAddress(locationController.text);
                
                // Check for dangerous content
                if (InputValidator.containsDangerousContent(nameController.text) ||
                    InputValidator.containsDangerousContent(descriptionController.text) ||
                    InputValidator.containsDangerousContent(locationController.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid characters detected in input'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _productService.updateProduct(product.id, {
                    'name': sanitizedName,
                    'description': sanitizedDescription,
                    'price': double.parse(priceController.text),
                    'unit': selectedUnit,
                    'category': selectedCategory,
                    'stock': int.parse(stockController.text),
                    'location': sanitizedLocation,
                    'isAvailable': isAvailable,
                  });

                  if (!mounted) return;
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating product: $e')),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _productService.deleteProduct(product.id);
                
                if (!mounted) return;
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting product: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddPhotosDialog(Product product) {
    final isDarkMode = _themeNotifier.isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeHelper.getCardColor(isDarkMode),
        title: Text('Add Product Photos', style: TextStyle(
          color: ThemeHelper.getTextColor(isDarkMode),
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add photos for "${product.name}"', style: TextStyle(
              color: ThemeHelper.getTextColor(isDarkMode),
            )),
            const SizedBox(height: 16),
            if (product.images.isNotEmpty) ...[
              Text('Current photos:', style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ThemeHelper.getTextColor(isDarkMode),
              )),
              const SizedBox(height: 8),
              Container(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: product.images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: product.images[index],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 20),
                              onPressed: () async {
                                await _deleteProductImage(product, index);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _pickAndUploadImage(product);
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _pickAndUploadFromGallery(product);
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(Product product) async {
    try {
      final XFile? image = await _imageUploadService.pickImageFromCamera();
      if (image == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image selected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      
      // Show uploading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading photo...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        // Upload to Firebase Storage
        final String? downloadUrl = await _imageUploadService.uploadProductImage(image, product.id);
        
        if (!mounted) return;
        Navigator.pop(context); // Close uploading dialog

        if (downloadUrl != null) {
          // Update product with new image URL
          final updatedImages = [...product.images, downloadUrl];
          await _productService.updateProduct(product.id, {'images': updatedImages});

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo uploaded successfully!'),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload photo - please try again'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (uploadError) {
        if (!mounted) return;
        Navigator.pop(context); // Close uploading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: ${uploadError.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadFromGallery(Product product) async {
    try {
      final XFile? image = await _imageUploadService.pickImageFromGallery();
      if (image == null) return;

      if (!mounted) return;
      
      // Show uploading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading photo...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Upload to Firebase Storage
      final String? downloadUrl = await _imageUploadService.uploadProductImage(image, product.id);
      
      if (!mounted) return;
      Navigator.pop(context); // Close uploading dialog

      if (downloadUrl != null) {
        // Update product with new image URL
        final updatedImages = [...product.images, downloadUrl];
        await _productService.updateProduct(product.id, {'images': updatedImages});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload photo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close uploading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteProductImage(Product product, int index) async {
    try {
      final imageUrl = product.images[index];
      
      // Delete from Storage
      await _imageUploadService.deleteProductImage(imageUrl);
      
      // Update product
      final updatedImages = List<String>.from(product.images)..removeAt(index);
      await _productService.updateProduct(product.id, {'images': updatedImages});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting photo: $e')),
        );
      }
    }
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Products',
                            style: ThemeHelper.getHeaderTextStyle(isDark: isDarkMode),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your product listings',
                            style: ThemeHelper.getSubHeaderTextStyle(isDark: isDarkMode),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AgriNotificationPage(),
                                ),
                              );
                              _loadUnreadNotifications();
                            },
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        if (unreadNotifications > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unreadNotifications > 9 ? '9+' : unreadNotifications.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search and Filter
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: ThemeHelper.getContainerDecoration(isDark: isDarkMode),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: ThemeHelper.getIconColor(isDarkMode)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (value) => setState(() => _searchQuery = value),
                                decoration: InputDecoration(
                                  hintText: 'Search products...',
                                  border: InputBorder.none,
                                  hintStyle: ThemeHelper.getHintTextStyle(isDark: isDarkMode),
                                ),
                                style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: ThemeHelper.getContainerDecoration(isDark: isDarkMode),
                      child: DropdownButton<String>(
                        value: _categoryFilter,
                        underline: const SizedBox(),
                        style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode),
                        dropdownColor: ThemeHelper.getCardColor(isDarkMode),
                        items: _categories.map((category) =>
                          DropdownMenuItem(value: category, child: Text(category)),
                        ).toList(),
                        onChanged: (value) => setState(() => _categoryFilter = value!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productService.getMyProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                List<Product> products = snapshot.data ?? [];

                // Apply filters
                if (_searchQuery.isNotEmpty) {
                  products = products.where((p) =>
                    p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    p.description.toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();
                }

                if (_categoryFilter != 'All') {
                  products = products.where((p) => p.category == _categoryFilter).toList();
                }

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first product to start selling',
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: ThemeHelper.getCardColor(isDarkMode),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(product.category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
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
                                  color: _getCategoryColor(product.category),
                                  size: 32,
                                )
                              : null,
                        ),
                        title: Text(
                          product.name,
                          style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '$_currencySymbol${product.price.toStringAsFixed(2)} ${product.unit}',
                              style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  size: 14,
                                  color: product.stock > 0 ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Stock: ${product.stock}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: product.stock > 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  'Available:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 8),
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: product.isAvailable,
                                    onChanged: (value) async {
                                      await _productService.toggleAvailability(
                                        product.id,
                                        value,
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              value
                                                  ? '${product.name} is now available'
                                                  : '${product.name} marked as unavailable',
                                            ),
                                            backgroundColor: const Color(0xFF4CAF50),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    activeColor: const Color(0xFF4CAF50),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: product.isAvailable ? Colors.green : Colors.grey,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product.isAvailable ? 'Available' : 'Unavailable',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'photos',
                              child: Row(
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 20, color: Color(0xFF4CAF50)),
                                  SizedBox(width: 8),
                                  Text('Add Photos', style: TextStyle(color: Color(0xFF4CAF50))),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'photos') {
                              _showAddPhotosDialog(product);
                            } else if (value == 'edit') {
                              _showEditProductDialog(product);
                            } else if (value == 'delete') {
                              _deleteProduct(product);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        backgroundColor: ThemeHelper.getHeaderColor(isDarkMode),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
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

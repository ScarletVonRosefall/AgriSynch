import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/validation_service.dart';
import '../shared/theme_helper.dart';
import '../shared/notification_helper.dart';
import '../shared/AgriNotificationPage.dart';
import '../shared/input_validator.dart';
import '../shared/currency_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Custom formatter for decimal numbers - more efficient than regex
class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;
  final int maxDigits;

  DecimalTextInputFormatter({
    this.decimalRange = 2,
    this.maxDigits = 10, // Max 10 digits before decimal (9,999,999,999.99)
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;

    // Allow empty string
    if (newText.isEmpty) {
      return newValue;
    }

    // Quick validation - only allow digits and one decimal point
    if (!RegExp(r'^[\d.]*$').hasMatch(newText)) {
      return oldValue;
    }

    // Check for multiple decimal points
    if (newText.indexOf('.') != newText.lastIndexOf('.')) {
      return oldValue;
    }

    // Check decimal places
    if (newText.contains('.')) {
      final parts = newText.split('.');
      if (parts[1].length > decimalRange) {
        return oldValue;
      }
      // Check digits before decimal
      if (parts[0].length > maxDigits) {
        return oldValue;
      }
    } else {
      // Check total digits
      if (newText.length > maxDigits) {
        return oldValue;
      }
    }

    return newValue;
  }
}

class AgriSynchProductsPage extends StatefulWidget {
  const AgriSynchProductsPage({super.key});

  @override
  State<AgriSynchProductsPage> createState() => _AgriSynchProductsPageState();
}

class _AgriSynchProductsPageState extends State<AgriSynchProductsPage> {
  final ProductService _productService = ProductService();
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
                            DecimalTextInputFormatter(
                              decimalRange: 2,
                              maxDigits: 8, // Max 99,999,999.99 (99 million)
                            ),
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
        title: Text('Manage Product Photos', style: TextStyle(
          color: ThemeHelper.getTextColor(isDarkMode),
        )),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Photos for "${product.name}"', style: TextStyle(
                  color: ThemeHelper.getTextColor(isDarkMode),
                )),
                const SizedBox(height: 16),
                if (product.images.isNotEmpty) ...[
                Text('Current photos (tap X to delete):', style: TextStyle(
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
                      final imageData = product.images[index];
                      final isBase64 = imageData.startsWith('data:image');
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: isBase64
                                    ? Image.memory(
                                        base64Decode(imageData.split(',')[1]),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.broken_image, color: Colors.grey),
                                        ),
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: imageData,
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
                              ),
                            ),
                            Positioned(
                              top: -5,
                              right: -5,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  onPressed: () async {
                                    await _deleteProductImage(product, index);
                                    Navigator.pop(context);
                                    // Reopen dialog to show updated list
                                    _showAddPhotosDialog(product);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete All Photos'),
                        content: const Text('Are you sure you want to delete all photos for this product?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmed == true) {
                      await _deleteAllProductImages(product);
                      if (mounted) {
                        Navigator.pop(context);
                        _showAddPhotosDialog(product);
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Delete All Photos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              ElevatedButton.icon(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await _pickAndUploadImage(product);
                  if (mounted && nav.canPop()) {
                    nav.pop();
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: Text(product.images.isEmpty ? 'Take Photo' : 'Add Photo (Camera)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await _pickAndUploadFromGallery(product);
                  if (mounted && nav.canPop()) {
                    nav.pop();
                  }
                },
                icon: const Icon(Icons.photo_library),
                label: Text(product.images.isEmpty ? 'Choose from Gallery' : 'Add Photo (Gallery)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
            ],
          ),
        ),
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
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 100,
      );
      
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
      
      // Show processing dialog
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
                  Text('Processing photo...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        // Convert to base64
        final bytes = await image.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        
        if (!mounted) return;
        Navigator.pop(context); // Close processing dialog

        // Update product with new base64 image
        final updatedImages = [...product.images, base64String];
        await _productService.updateProduct(product.id, {'images': updatedImages});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo added successfully!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      } catch (uploadError) {
        if (!mounted) return;
        Navigator.pop(context); // Close processing dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: ${uploadError.toString()}'),
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
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 100,
      );
      
      if (image == null) return;

      if (!mounted) return;
      
      // Show processing dialog
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
                  Text('Processing photo...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Convert to base64
      final bytes = await image.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      
      if (!mounted) return;
      Navigator.pop(context); // Close processing dialog

      // Update product with new base64 image
      final updatedImages = [...product.images, base64String];
      await _productService.updateProduct(product.id, {'images': updatedImages});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo added successfully!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close processing dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteProductImage(Product product, int index) async {
    try {
      // No need to delete from Storage for base64 images
      // Just remove from the list
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

  Future<void> _deleteAllProductImages(Product product) async {
    try {
      // Clear all images
      await _productService.updateProduct(product.id, {'images': []});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All photos deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting photos: $e')),
        );
      }
    }
  }

  Future<void> _showReplacePhotoDialog(Product product) async {
    final isDarkMode = _themeNotifier.isDarkMode;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeHelper.getCardColor(isDarkMode),
        title: Text('Replace Photo', style: TextStyle(
          color: ThemeHelper.getTextColor(isDarkMode),
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose a new photo. Old photos will be replaced.',
              style: TextStyle(color: ThemeHelper.getTextColor(isDarkMode)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _replaceWithCamera(product);
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take New Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _replaceWithGallery(product);
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
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _replaceWithCamera(Product product) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 100,
      );
      
      if (image == null) return;

      if (!mounted) return;
      
      // Show processing dialog
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
                  Text('Replacing photo...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Convert to base64
      final bytes = await image.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      
      if (!mounted) return;
      
      // Replace all images with just this new one
      await _productService.updateProduct(product.id, {'images': [base64String]});
      
      Navigator.pop(context); // Close processing dialog

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo replaced successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close processing dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _replaceWithGallery(Product product) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 100,
      );
      
      if (image == null) return;

      if (!mounted) return;
      
      // Show processing dialog
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
                  Text('Replacing photo...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Convert to base64
      final bytes = await image.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      
      if (!mounted) return;
      
      // Replace all images with just this new one
      await _productService.updateProduct(product.id, {'images': [base64String]});
      
      Navigator.pop(context); // Close processing dialog

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo replaced successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close processing dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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

                // Calculate responsive columns based on screen width
                final screenWidth = MediaQuery.of(context).size.width;
                final crossAxisCount = screenWidth > 1200 ? 4 : (screenWidth > 800 ? 3 : 2);
                
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
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
                              // Menu Button
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: PopupMenuButton(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'photos',
                                        child: Row(
                                          children: [
                                            Icon(
                                              product.images.isEmpty ? Icons.add_photo_alternate : Icons.refresh,
                                              size: 20,
                                              color: product.images.isEmpty ? Color(0xFF4CAF50) : Colors.orange,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              product.images.isEmpty ? 'Add Photos' : 'Replace Photo',
                                              style: TextStyle(
                                                color: product.images.isEmpty ? Color(0xFF4CAF50) : Colors.orange,
                                              ),
                                            ),
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
                                    onSelected: (value) async {
                                      if (value == 'photos') {
                                        if (product.images.isNotEmpty) {
                                          await _showReplacePhotoDialog(product);
                                        } else {
                                          _showAddPhotosDialog(product);
                                        }
                                      } else if (value == 'edit') {
                                        _showEditProductDialog(product);
                                      } else if (value == 'delete') {
                                        _deleteProduct(product);
                                      }
                                    },
                                  ),
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
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: ThemeHelper.getBodyTextStyle(isDark: isDarkMode).copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
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
                                      Icon(
                                        Icons.inventory_2,
                                        size: 12,
                                        color: product.stock > 0 ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Stock: ${product.stock}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: product.stock > 0 ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Description in the white space
                                  if (product.description.isNotEmpty)
                                    Expanded(
                                      child: Text(
                                        product.description,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isDarkMode ? Colors.white60 : Colors.grey[600],
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 8),
                                  const SizedBox(height: 6),
                                  // Availability Toggle
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Transform.scale(
                                        scale: 0.7,
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
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: product.isAvailable ? Colors.green : Colors.grey,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            product.isAvailable ? 'Available' : 'Unavailable',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
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

  // Helper method to get ImageProvider for both base64 and URL images
  ImageProvider _getImageProvider(String imageData) {
    if (imageData.startsWith('data:image')) {
      // Base64 image
      return MemoryImage(base64Decode(imageData.split(',')[1]));
    } else {
      // URL image
      return NetworkImage(imageData);
    }
  }
}

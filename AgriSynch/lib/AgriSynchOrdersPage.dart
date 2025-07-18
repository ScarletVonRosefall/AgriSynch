import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AgriSynchOrdersPage extends StatefulWidget {
  const AgriSynchOrdersPage({super.key});

  @override
  State<AgriSynchOrdersPage> createState() => _AgriSynchOrdersPageState();
}

class _AgriSynchOrdersPageState extends State<AgriSynchOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final List<String> _products = ['Quail Eggs', 'Chicken Egg', 'Pigs'];
  String? _selectedProduct;
  String _selectedCategory = 'All';
  String _searchTerm = '';
  String _sortOption = 'Date (Newest First)';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('orders');
    if (data != null) {
      setState(() {
        _orders = List<Map<String, dynamic>>.from(json.decode(data));
      });
    }
  }

  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('orders', json.encode(_orders));
  }

  void _addOrder() {
    final quantity = _quantityController.text.trim();
    
    // Form validation
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (quantity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a quantity'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (int.tryParse(quantity) == null || int.parse(quantity) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity must be greater than 0'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newOrder = {
      'product': _selectedProduct,
      'quantity': quantity,
      'date': DateTime.now().toIso8601String(),
      'delivered': false,
    };

    setState(() {
      _orders.add(newOrder);
    });

    setState(() {
      _selectedProduct = null;
    });
    _quantityController.clear();
    _saveOrders();

    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order Added'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF00C853),
      ),
    );
  }

  void _toggleDelivery(int index) {
    final wasDelivered = _orders[index]['delivered'];
    setState(() {
      _orders[index]['delivered'] = !_orders[index]['delivered'];
    });
    _saveOrders();
    
    // Show delivery toggle snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasDelivered ? 'Marked as Undelivered!' : 'Marked as Delivered!'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF00C853),
      ),
    );
  }

  void _deleteOrder(int index) {
    setState(() {
      _orders.removeAt(index);
    });
    _saveOrders();
    
    // Show delete confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order Deleted!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _deleteAllDelivered() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Delivered Orders'),
        content: const Text('Are you sure you want to delete all delivered orders? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _orders.removeWhere((order) => order['delivered'] == true);
              });
              _saveOrders();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredOrders {
    List<Map<String, dynamic>> filtered = _orders;
    
    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((order) => order['product'] == _selectedCategory).toList();
    }
    
    // Filter by search term
    if (_searchTerm.isNotEmpty) {
      filtered = filtered.where((order) {
        final productName = order['product'].toString().toLowerCase();
        final quantity = order['quantity'].toString().toLowerCase();
        final searchLower = _searchTerm.toLowerCase();
        return productName.contains(searchLower) || quantity.contains(searchLower);
      }).toList();
    }
    
    // Sort the filtered list
    switch (_sortOption) {
      case 'Date (Newest First)':
        filtered.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
        break;
      case 'Date (Oldest First)':
        filtered.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
        break;
      case 'Product Name (A-Z)':
        filtered.sort((a, b) => a['product'].toString().compareTo(b['product'].toString()));
        break;
      case 'Product Name (Z-A)':
        filtered.sort((a, b) => b['product'].toString().compareTo(a['product'].toString()));
        break;
      case 'Quantity (High to Low)':
        filtered.sort((a, b) => int.parse(b['quantity'].toString()).compareTo(int.parse(a['quantity'].toString())));
        break;
      case 'Quantity (Low to High)':
        filtered.sort((a, b) => int.parse(a['quantity'].toString()).compareTo(int.parse(b['quantity'].toString())));
        break;
      case 'Delivery Status':
        filtered.sort((a, b) {
          // Delivered orders first (true comes before false)
          if (a['delivered'] == b['delivered']) {
            // If same delivery status, sort by date (newest first)
            return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
          }
          return b['delivered'] == true ? 1 : -1;
        });
        break;
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FBE0),
      body: Column(
        children: [
          // --- Top Green Header ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF00C853),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
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
                          const Text(
                            'Orders Management',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your agricultural orders',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No new notifications'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF00C853),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSearchSection(),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // --- Content Area ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildInputSection(),
                  const SizedBox(height: 16),
                  _buildFilterAndSortSection(),
                  const SizedBox(height: 12),
                  _buildOrdersHeader(),
                  const SizedBox(height: 8),
                  Expanded(child: _buildOrderList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add New Order",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF00C853),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedProduct,
                    decoration: const InputDecoration(
                      labelText: 'Product',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: const TextStyle(fontFamily: 'Poppins', color: Colors.black87),
                    items: _products
                        .map((product) => DropdownMenuItem(
                              value: product,
                              child: Text(product),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProduct = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontFamily: 'Poppins'),
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      labelStyle: TextStyle(fontFamily: 'Poppins'),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _addOrder,
                  icon: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search orders...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontFamily: 'Poppins'),
              ),
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          if (_searchTerm.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchTerm = '';
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final deliveredCount = _orders.where((order) => order['delivered'] == true).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: _selectedCategory,
                items: ['All', ..._products]
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text("Category: $cat"),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
            ),
            if (deliveredCount > 0) ...[
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _deleteAllDelivered,
                icon: const Icon(Icons.delete_sweep, color: Colors.white, size: 16),
                label: Text('Clear ($deliveredCount)', style: const TextStyle(color: Colors.white, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFilterAndSortSection() {
    final deliveredCount = _orders.where((order) => order['delivered'] == true).length;
    final sortOptions = [
      'Date (Newest First)',
      'Date (Oldest First)',
      'Product Name (A-Z)',
      'Product Name (Z-A)',
      'Quantity (High to Low)',
      'Quantity (Low to High)',
      'Delivery Status',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Filter Row
          Row(
            children: [
              const Icon(Icons.filter_list, color: Color(0xFF00C853), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Filter:',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    underline: const SizedBox(),
                    style: const TextStyle(fontFamily: 'Poppins', color: Colors.black87),
                    items: ['All', ..._products]
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ),
              ),
              if (deliveredCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton.icon(
                    onPressed: _deleteAllDelivered,
                    icon: const Icon(Icons.delete_sweep, color: Colors.white, size: 16),
                    label: Text(
                      'Clear ($deliveredCount)',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Poppins'),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Sort Row
          Row(
            children: [
              const Icon(Icons.sort, color: Color(0xFF00C853), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Sort:',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _sortOption,
                    isExpanded: true,
                    underline: const SizedBox(),
                    style: const TextStyle(fontFamily: 'Poppins', color: Colors.black87),
                    items: sortOptions.map((option) => DropdownMenuItem(
                      value: option,
                      child: Text(option, style: const TextStyle(fontSize: 13)),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _sortOption = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF00E676),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            "Total Orders: ${_filteredOrders.length}",
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          if (_filteredOrders.isNotEmpty)
            Text(
              "${_filteredOrders.where((order) => order['delivered']).length} delivered",
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {

  void _editOrder(int index) async {
    final order = _orders[index];
    String editedProduct = order['product'];
    String editedQuantity = order['quantity'];

    await showDialog(
      context: context,
      builder: (context) {
        TextEditingController productController = TextEditingController(text: editedProduct);
        TextEditingController quantityController = TextEditingController(text: editedQuantity);

        return AlertDialog(
          title: const Text('Edit Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: editedProduct,
                items: _products.map((product) => DropdownMenuItem(
                      value: product,
                      child: Text(product),
                    )).toList(),
                onChanged: (value) {
                  if (value != null) editedProduct = value;
                },
                decoration: const InputDecoration(labelText: 'Product'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _orders[index]['product'] = editedProduct;
                  _orders[index]['quantity'] = quantityController.text;
                });
                _saveOrders();
                Navigator.pop(context);
                
                // Show edit confirmation snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order Updated!'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Color(0xFF00C853),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
    if (_filteredOrders.isEmpty) {
      return const Center(
        child: Text("No orders yet."),
      );
    }

    return ListView.builder(
      itemCount: _filteredOrders.length,
      padding: const EdgeInsets.only(bottom: 20),
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        final date = DateTime.parse(order['date']);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            onLongPress: () => _editOrder(_orders.indexOf(order)),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: order['delivered']
                    ? const Color(0xFF00C853).withOpacity(0.1)
                    : const Color(0xFF00E676).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                order['delivered'] ? Icons.check_circle : Icons.pending,
                color: order['delivered'] 
                    ? const Color(0xFF00C853) 
                    : const Color(0xFF00E676),
                size: 24,
              ),
            ),
            title: Text(
              "${order['product']} - Qty: ${order['quantity']}",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "Ordered on ${date.day}/${date.month}/${date.year}",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: order['delivered']
                        ? const Color(0xFF00C853).withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order['delivered'] ? 'Delivered' : 'Pending',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: order['delivered'] 
                          ? const Color(0xFF00C853) 
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: order['delivered']
                        ? const Color(0xFF00C853).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      order['delivered'] ? Icons.check_box : Icons.check_box_outline_blank,
                      color: order['delivered'] 
                          ? const Color(0xFF00C853) 
                          : Colors.grey[600],
                      size: 20,
                    ),
                    onPressed: () => _toggleDelivery(_orders.indexOf(order)),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _deleteOrder(_orders.indexOf(order)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

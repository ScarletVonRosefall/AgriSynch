import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AgriSynchOrdersPage
    extends
        StatefulWidget {
  const AgriSynchOrdersPage({
    super.key,
  });

  @override
  State<
    AgriSynchOrdersPage
  >
  createState() => _AgriSynchOrdersPageState();
}

class _AgriSynchOrdersPageState
    extends
        State<
          AgriSynchOrdersPage
        > {
  List<
    Map<
      String,
      dynamic
    >
  >
  _orders = [];

  final TextEditingController _productController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<
    void
  >
  _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(
      'orders',
    );
    if (data !=
        null) {
      setState(
        () {
          _orders =
              List<
                Map<
                  String,
                  dynamic
                >
              >.from(
                json.decode(
                  data,
                ),
              );
        },
      );
    }
  }

  Future<
    void
  >
  _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'orders',
      json.encode(
        _orders,
      ),
    );
  }

  void _addOrder() {
    final product = _productController.text.trim();
    final quantity = _quantityController.text.trim();
    if (product.isEmpty ||
        quantity.isEmpty)
      return;

    final newOrder = {
      'product': product,
      'quantity': quantity,
      'date': DateTime.now().toIso8601String(),
      'delivered': false,
    };

    setState(
      () {
        _orders.add(
          newOrder,
        );
      },
    );

    _productController.clear();
    _quantityController.clear();
    _saveOrders();
  }

  void _toggleDelivery(
    int index,
  ) {
    setState(
      () {
        _orders[index]['delivered'] = !_orders[index]['delivered'];
      },
    );
    _saveOrders();
  }

  void _deleteOrder(
    int index,
  ) {
    setState(
      () {
        _orders.removeAt(
          index,
        );
      },
    );
    _saveOrders();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF2FBE0,
      ),
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF00C853,
        ),
        title: const Text(
          'Orders',
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputSection(),
            const SizedBox(
              height: 20,
            ),
            Expanded(
              child: _buildOrderList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Add New Order",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _productController,
                decoration: const InputDecoration(
                  labelText: 'Product',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              onPressed: _addOrder,
              icon: const Icon(
                Icons.add_circle,
                color: Color(
                  0xFF00C853,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderList() {
    if (_orders.isEmpty) {
      return const Center(
        child: Text(
          "No orders yet.",
        ),
      );
    }

    return ListView.builder(
      itemCount: _orders.length,
      itemBuilder:
          (
            context,
            index,
          ) {
            final order = _orders[index];
            final date = DateTime.parse(
              order['date'],
            );

            return Card(
              color: order['delivered']
                  ? const Color(
                      0xFFA5D6A7,
                    )
                  : const Color(
                      0xFFC5E1A5,
                    ),
              child: ListTile(
                title: Text(
                  "${order['product']} - Qty: ${order['quantity']}",
                ),
                subtitle: Text(
                  "Ordered on ${date.day}/${date.month}/${date.year}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        order['delivered']
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: Colors.green[900],
                      ),
                      onPressed: () => _toggleDelivery(
                        index,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () => _deleteOrder(
                        index,
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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class DeliveryTrackingPage extends StatefulWidget {
  final String? orderId;
  
  const DeliveryTrackingPage({super.key, this.orderId});

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage> {
  bool isDarkMode = false;
  List<Map<String, dynamic>> deliveries = [];
  Map<String, dynamic>? currentOrder;
  
  final List<Map<String, dynamic>> trackingSteps = [
    {'step': 'Order Placed', 'icon': Icons.receipt, 'description': 'Your order has been placed'},
    {'step': 'Processing', 'icon': Icons.autorenew, 'description': 'Farmer is preparing your order'},
    {'step': 'Ready for Pickup', 'icon': Icons.local_shipping, 'description': 'Order is ready for delivery'},
    {'step': 'Out for Delivery', 'icon': Icons.delivery_dining, 'description': 'On the way to your location'},
    {'step': 'Delivered', 'icon': Icons.check_circle, 'description': 'Order has been delivered'},
  ];

  @override
  void initState() {
    super.initState();
    loadTheme();
    loadDeliveries();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> loadDeliveries() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersString = prefs.getString('buyer_orders');
    
    if (ordersString != null) {
      final orders = List<Map<String, dynamic>>.from(json.decode(ordersString));
      
      setState(() {
        // Filter orders that are shipped or processing
        deliveries = orders.where((order) => 
          ['processing', 'shipped', 'delivered'].contains(order['status'].toLowerCase())
        ).toList();
        
        // Sort by date (newest first)
        deliveries.sort((a, b) => DateTime.parse(b['orderDate']).compareTo(DateTime.parse(a['orderDate'])));
        
        // If orderId is provided, find and set current order
        if (widget.orderId != null) {
          currentOrder = orders.firstWhere(
            (order) => order['id'] == widget.orderId,
            orElse: () => deliveries.isNotEmpty ? deliveries.first : {},
          );
        } else if (deliveries.isNotEmpty) {
          currentOrder = deliveries.first;
        }
      });
    }
  }

  int getCurrentStepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'processing':
        return 1;
      case 'shipped':
        return 3; // Out for delivery
      case 'delivered':
        return 4;
      default:
        return 0;
    }
  }

  String getEstimatedTime(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return '24-48 hours';
      case 'shipped':
        return '2-4 hours';
      case 'delivered':
        return 'Completed';
      default:
        return 'TBD';
    }
  }

  String formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }

  Widget buildTrackingTimeline() {
    if (currentOrder == null) return const SizedBox();
    
    final currentStep = getCurrentStepIndex(currentOrder!['status']);
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Card(
      color: backgroundColor,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${currentOrder!['id']}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Estimated delivery: ${getEstimatedTime(currentOrder!['status'])}',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: const Color(0xFF4CAF50),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            
            ...List.generate(trackingSteps.length, (index) {
              final step = trackingSteps[index];
              final isCompleted = index <= currentStep;
              final isCurrent = index == currentStep;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    // Timeline indicator
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted 
                                ? const Color(0xFF4CAF50) 
                                : textColor.withOpacity(0.2),
                            border: isCurrent 
                                ? Border.all(color: const Color(0xFF4CAF50), width: 3)
                                : null,
                          ),
                          child: Icon(
                            step['icon'] as IconData,
                            color: isCompleted ? Colors.white : textColor.withOpacity(0.5),
                            size: 20,
                          ),
                        ),
                        if (index < trackingSteps.length - 1)
                          Container(
                            width: 2,
                            height: 40,
                            color: index < currentStep 
                                ? const Color(0xFF4CAF50) 
                                : textColor.withOpacity(0.2),
                          ),
                      ],
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Step info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['step'] as String,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? textColor : textColor.withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            step['description'] as String,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: isCompleted ? textColor.withOpacity(0.7) : textColor.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                          if (isCurrent)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Current Status',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: const Color(0xFF4CAF50),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Timestamp (for completed steps)
                    if (isCompleted && index <= currentStep)
                      Text(
                        _getStepTime(index),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: textColor.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getStepTime(int stepIndex) {
    if (currentOrder == null) return '';
    
    final orderDate = DateTime.parse(currentOrder!['orderDate']);
    final currentStepIndex = getCurrentStepIndex(currentOrder!['status']);
    
    if (stepIndex > currentStepIndex) return '';
    
    // Simulate realistic timestamps
    switch (stepIndex) {
      case 0: // Order placed
        return DateFormat('MMM dd, hh:mm a').format(orderDate);
      case 1: // Processing
        return DateFormat('MMM dd, hh:mm a').format(orderDate.add(const Duration(hours: 2)));
      case 2: // Ready for pickup
        return DateFormat('MMM dd, hh:mm a').format(orderDate.add(const Duration(hours: 24)));
      case 3: // Out for delivery
        return DateFormat('MMM dd, hh:mm a').format(orderDate.add(const Duration(hours: 26)));
      case 4: // Delivered
        return DateFormat('MMM dd, hh:mm a').format(orderDate.add(const Duration(hours: 28)));
      default:
        return '';
    }
  }

  Widget buildDeliveryInfo() {
    if (currentOrder == null) return const SizedBox();
    
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Card(
      color: backgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Information',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(Icons.person, 'Delivery Person', 'Juan Dela Cruz', textColor),
            _buildInfoRow(Icons.phone, 'Contact', '+63 912 345 6789', textColor),
            _buildInfoRow(Icons.local_shipping, 'Vehicle', 'Motorcycle - ABC 123', textColor),
            _buildInfoRow(Icons.location_on, 'Delivery Address', 'Your saved address', textColor),
            
            if (currentOrder!['status'].toLowerCase() == 'shipped')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Calling delivery person...'),
                          backgroundColor: Color(0xFF4CAF50),
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text(
                      'Call Delivery Person',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4CAF50)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: textColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    'Delivery Tracking',
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
          ),

          // Dropdown to select delivery
          if (deliveries.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                underline: const SizedBox(),
                value: currentOrder?['id'],
                hint: Text(
                  'Select an order to track',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                items: deliveries.map((delivery) => DropdownMenuItem<String>(
                  value: delivery['id'],
                  child: Text(
                    'Order #${delivery['id']} - ${delivery['status']}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: textColor,
                    ),
                  ),
                )).toList(),
                onChanged: (orderId) {
                  setState(() {
                    currentOrder = deliveries.firstWhere((d) => d['id'] == orderId);
                  });
                },
              ),
            ),

          // Content
          Expanded(
            child: deliveries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping,
                          size: 80,
                          color: textColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No deliveries to track',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your active deliveries will appear here',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: textColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : currentOrder == null
                    ? Center(
                        child: Text(
                          'Select an order to view tracking details',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            buildTrackingTimeline(),
                            const SizedBox(height: 16),
                            buildDeliveryInfo(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

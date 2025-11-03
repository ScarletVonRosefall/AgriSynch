import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/notification_helper.dart';
import '../shared/currency_helper.dart';

class FinanceService {
  /// Add a transaction from a delivered order
  static Future<void> addTransactionFromOrder({
    required String orderId,
    required String productName,
    required double amount,
    required int quantity,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedTransactions = prefs.getString('financial_transactions');
    
    List<Map<String, dynamic>> transactions = [];
    if (savedTransactions != null) {
      transactions = List<Map<String, dynamic>>.from(json.decode(savedTransactions));
    }

    // Check if transaction already exists for this order
    final existingTransaction = transactions.any((t) => t['orderId'] == orderId);
    if (existingTransaction) {
      print('Transaction already exists for order $orderId');
      return; // Don't create duplicate
    }

    // Add the new transaction
    transactions.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': 'income',
      'category': 'Sales',
      'amount': amount,
      'description': 'Order #$orderId: $productName (Qty: $quantity)',
      'date': DateTime.now().toIso8601String(),
      'orderId': orderId, // Link to the order
    });

    await prefs.setString('financial_transactions', json.encode(transactions));
    
    // Add notification
    final currencySymbol = await CurrencyHelper.getCurrentCurrencySymbol();
    await NotificationHelper.addNotification(
      title: 'Sale Recorded 💰',
      message: 'Income of $currencySymbol${amount.toStringAsFixed(2)} from $productName has been added to finances.',
      type: 'system',
    );
    
    print('✅ Transaction added for order $orderId: $currencySymbol${amount.toStringAsFixed(2)}');
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
    // Get current user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('No user logged in, cannot add transaction');
      return;
    }

    final userId = currentUser.uid;
    
    // Check if transaction already exists in Firestore
    final existingTransaction = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('orderId', isEqualTo: orderId)
        .get();
    
    if (existingTransaction.docs.isNotEmpty) {
      debugPrint('Transaction already exists for order $orderId');
      return; // Don't create duplicate
    }

    // Create the new transaction in Firestore
    final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
    final transactionData = {
      'id': transactionId,
      'type': 'income',
      'category': 'Sales',
      'amount': amount,
      'description': 'Order #$orderId: $productName (Qty: $quantity)',
      'date': DateTime.now().toIso8601String(),
      'orderId': orderId, // Link to the order
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .set(transactionData);

    // Also save to local storage for backwards compatibility
    final prefs = await SharedPreferences.getInstance();
    final savedTransactions = prefs.getString('financial_transactions');
    
    List<Map<String, dynamic>> transactions = [];
    if (savedTransactions != null) {
      transactions = List<Map<String, dynamic>>.from(json.decode(savedTransactions));
    }

    // Add to local storage if not exists (without FieldValue)
    final existingLocal = transactions.any((t) => t['orderId'] == orderId);
    if (!existingLocal) {
      transactions.add({
        'id': transactionId,
        'type': 'income',
        'category': 'Sales',
        'amount': amount,
        'description': 'Order #$orderId: $productName (Qty: $quantity)',
        'date': DateTime.now().toIso8601String(),
        'orderId': orderId,
        // Don't include 'createdAt' with FieldValue in JSON
      });
      await prefs.setString('financial_transactions', json.encode(transactions));
    }
    
    // Add notification
    final currencySymbol = await CurrencyHelper.getCurrentCurrencySymbol();
    await NotificationHelper.addNotification(
      title: 'Sale Recorded 💰',
      message: 'Income of $currencySymbol${amount.toStringAsFixed(2)} from $productName has been added to finances.',
      type: 'system',
    );
    
    debugPrint('✅ Transaction added to Firestore for order $orderId: $currencySymbol${amount.toStringAsFixed(2)}');
  }
}

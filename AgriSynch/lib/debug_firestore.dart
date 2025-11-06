import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  print('🔍 Starting Firestore Debug Scan...\n');
  
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    print('❌ No user logged in!');
    print('Please run the app and log in first.\n');
    return;
  }
  
  print('👤 Current User:');
  print('   UID: ${currentUser.uid}');
  print('   Email: ${currentUser.email}');
  print('   Display Name: ${currentUser.displayName}\n');
  
  // Check users collection
  print('📂 Scanning USERS collection...');
  try {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();
    
    print('   Total users: ${usersSnapshot.docs.length}');
    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      print('\n   User ID: ${doc.id}');
      print('   Name: ${data['name'] ?? 'N/A'}');
      print('   Email: ${data['email'] ?? 'N/A'}');
      print('   Role: ${data['role'] ?? 'N/A'}');
      print('   Is Current User: ${doc.id == currentUser.uid ? '✅ YES' : '❌ NO'}');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
  
  // Check products collection
  print('\n📂 Scanning PRODUCTS collection...');
  try {
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .get();
    
    print('   Total products: ${productsSnapshot.docs.length}');
    for (var doc in productsSnapshot.docs) {
      final data = doc.data();
      print('\n   Product ID: ${doc.id}');
      print('   Name: ${data['name'] ?? 'N/A'}');
      print('   Farmer ID: ${data['farmerId'] ?? 'N/A'}');
      print('   Farmer Name: ${data['farmerName'] ?? 'N/A'}');
      print('   Price: ₱${data['price'] ?? 0}');
      print('   Stock: ${data['stock'] ?? 0}');
      print('   Owned by current user: ${data['farmerId'] == currentUser.uid ? '✅ YES' : '❌ NO'}');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
  
  // Check orders collection
  print('\n📂 Scanning ORDERS collection...');
  try {
    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .get();
    
    print('   Total orders: ${ordersSnapshot.docs.length}');
    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      print('\n   Order ID: ${doc.id}');
      print('   Buyer ID: ${data['buyerId'] ?? 'N/A'}');
      print('   Buyer Name: ${data['buyerName'] ?? 'N/A'}');
      print('   Farmer ID: ${data['farmerId'] ?? 'N/A'}');
      print('   Farmer Name: ${data['farmerName'] ?? 'N/A'}');
      print('   Status: ${data['status'] ?? 'N/A'}');
      print('   Total: ₱${data['totalAmount'] ?? 0}');
      print('   Current user is buyer: ${data['buyerId'] == currentUser.uid ? '✅ YES' : '❌ NO'}');
      print('   Current user is farmer: ${data['farmerId'] == currentUser.uid ? '✅ YES' : '❌ NO'}');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
  
  print('\n✅ Scan complete!\n');
  print('💡 Summary:');
  print('   - If you see orders where "Current user is farmer: ✅ YES", they should appear in My Customers');
  print('   - If all orders show "Current user is buyer: ✅ YES", you need to order from your own products');
  print('   - To test properly: Create product → Switch to buyer view → Order your own product\n');
}

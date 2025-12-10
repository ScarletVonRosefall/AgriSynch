/// Script to fix products with incorrect 'images' field type in Firestore
/// Run this once to clean up database
/// 
/// This fixes products where images field is set to 'true' (boolean)
/// instead of an array/list of URLs
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

Future<void> fixProductImages() async {
  print('🔧 Starting product images cleanup...');
  
  try {
    // Initialize Firebase if not already initialized
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      print('Firebase already initialized');
    }

    final firestore = FirebaseFirestore.instance;
    final productsRef = firestore.collection('products');
    
    // Get all products
    final snapshot = await productsRef.get();
    print('📦 Found ${snapshot.docs.length} products to check');
    
    int fixedCount = 0;
    int errorCount = 0;
    
    for (var doc in snapshot.docs) {
      try {
        final data = doc.data();
        final imagesField = data['images'];
        
        // Check if images field is not a list (could be bool, string, etc.)
        if (imagesField != null && imagesField is! List) {
          print('⚠️  Product ${doc.id} has invalid images type: ${imagesField.runtimeType}');
          print('   Current value: $imagesField');
          
          // Fix by setting to empty array
          await productsRef.doc(doc.id).update({
            'images': [], // Set to empty array
          });
          
          print('✅ Fixed product ${doc.id} - set images to []');
          fixedCount++;
        } else if (imagesField == null) {
          // If images field is missing, add it
          await productsRef.doc(doc.id).update({
            'images': [],
          });
          print('✅ Added missing images field to product ${doc.id}');
          fixedCount++;
        } else if (imagesField is List) {
          print('✓  Product ${doc.id} images field is correct (${imagesField.length} images)');
        }
        
      } catch (e) {
        print('❌ Error fixing product ${doc.id}: $e');
        errorCount++;
      }
    }
    
    print('\n${'=' * 50}');
    print('🎉 Cleanup Complete!');
    print('=' * 50);
    print('Total products checked: ${snapshot.docs.length}');
    print('Products fixed: $fixedCount');
    print('Errors: $errorCount');
    print('=' * 50);
    
  } catch (e) {
    print('❌ Fatal error: $e');
  }
}

void main() async {
  await fixProductImages();
}

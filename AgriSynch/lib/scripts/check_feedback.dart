import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Quick script to check feedback collection
Future<void> checkFeedback() async {
  try {
    print('🔍 Checking feedback collection...');
    
    final snapshot = await FirebaseFirestore.instance
        .collection('feedback')
        .get();
    
    print('📊 Total feedback documents: ${snapshot.docs.length}');
    
    if (snapshot.docs.isEmpty) {
      print('⚠️ No feedback found in Firestore!');
      print('💡 Try submitting feedback from the app first.');
    } else {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('\n📝 Feedback ID: ${doc.id}');
        print('   Status: ${data['status']}');
        print('   Category: ${data['category']}');
        print('   User: ${data['userName']} (${data['userEmail']})');
        print('   Message: ${data['feedback']}');
        print('   Timestamp: ${data['timestamp']}');
      }
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}

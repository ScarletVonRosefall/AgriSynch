import 'package:cloud_firestore/cloud_firestore.dart';

class SimpleFeedbackTest {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> testSubmit(String feedback) async {
    try {
      print('🧪 Testing simple feedback submission...');
      
      final testData = {
        'feedback': feedback,
        'category': 'Test',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'test',
      };

      print('📤 Submitting test data: $testData');
      
      final docRef = await _firestore.collection('feedback').add(testData);
      print('✅ Test successful! Document ID: ${docRef.id}');
      
      return true;
    } catch (e) {
      print('❌ Test failed: $e');
      return false;
    }
  }
}
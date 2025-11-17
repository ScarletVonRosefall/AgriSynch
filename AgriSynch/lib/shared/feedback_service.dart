import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FeedbackService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Submit feedback to Firebase Firestore
  static Future<bool> submitFeedback({
    required String feedback,
    String? category,
  }) async {
    try {
      print('🔄 Starting feedback submission...');
      
      // Get current user info
      final user = _auth.currentUser;
      print('🔍 Current user: ${user?.email ?? 'No user logged in'}');
      
      // Get user info with fallback for storage errors
      String userEmail = 'Unknown';
      String userName = 'Anonymous';
      String accountType = 'Unknown';
      
      try {
        userEmail = user?.email ?? await _storage.read(key: 'user_email') ?? 'Unknown';
        userName = await _storage.read(key: 'user_name') ?? 
                   await _storage.read(key: 'name') ?? 'Anonymous';
        accountType = await _storage.read(key: 'account_type') ?? 'Unknown';
      } catch (storageError) {
        print('⚠️ Storage error, using fallbacks: $storageError');
        userEmail = user?.email ?? 'Unknown';
        userName = user?.displayName ?? 'Anonymous';
      }

      print('📝 User info - Email: $userEmail, Name: $userName, Type: $accountType');

      // Auto-determine priority based on category
      String priority = 'Medium'; // Default
      if (category == 'Bug Report') {
        priority = 'High';
      } else if (category == 'Technical Support' || category == 'Account Issues') {
        priority = 'High';
      } else if (category == 'Feature Request') {
        priority = 'Low';
      }

      // Create feedback document
      final feedbackData = {
        'feedback': feedback.trim(),
        'category': category ?? 'General',
        'priority': priority, // Auto-determined based on category
        'userEmail': userEmail,
        'userName': userName,
        'accountType': accountType,
        'userId': user?.uid ?? 'unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'submitted', // submitted, in-progress, resolved
        'deviceInfo': await _getDeviceInfo(),
        'appVersion': '1.0.0',
      };

      print('📤 Submitting feedback data: $feedbackData');

      // Add to Firestore
      final docRef = await _firestore.collection('feedback').add(feedbackData);
      print('✅ Feedback submitted successfully! Document ID: ${docRef.id}');
      
      return true;
    } catch (e) {
      print('❌ Error submitting feedback: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('❌ Firebase error code: ${e.code}');
        print('❌ Firebase error message: ${e.message}');
      }
      return false;
    }
  }

  /// Get device and app information for better support
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': 'Flutter Web',
      'timestamp': DateTime.now().toIso8601String(),
      'userAgent': 'Web Browser',
    };
  }

  /// Get all feedback for admin dashboard (requires admin privileges)
  static Future<List<Map<String, dynamic>>> getAllFeedback() async {
    try {
      final querySnapshot = await _firestore
          .collection('feedback')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print('Error getting feedback: $e');
      return [];
    }
  }

  /// Update feedback status (for admin use)
  static Future<bool> updateFeedbackStatus(String feedbackId, String status) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).update({
        'status': status,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating feedback status: $e');
      return false;
    }
  }

  /// Add admin response to feedback
  static Future<bool> addAdminResponse(String feedbackId, String response) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).update({
        'adminResponse': response,
        'responseDate': FieldValue.serverTimestamp(),
        'status': 'resolved',
      });
      return true;
    } catch (e) {
      print('Error adding admin response: $e');
      return false;
    }
  }

  /// Get feedback statistics for admin dashboard
  static Future<Map<String, dynamic>> getFeedbackStats() async {
    try {
      final snapshot = await _firestore.collection('feedback').get();
      final feedbacks = snapshot.docs;

      int total = feedbacks.length;
      int submitted = feedbacks.where((doc) => doc.data()['status'] == 'submitted').length;
      int inProgress = feedbacks.where((doc) => doc.data()['status'] == 'in-progress').length;
      int resolved = feedbacks.where((doc) => doc.data()['status'] == 'resolved').length;

      // Category breakdown
      Map<String, int> categories = {};
      for (var doc in feedbacks) {
        String category = doc.data()['category'] ?? 'General';
        categories[category] = (categories[category] ?? 0) + 1;
      }

      return {
        'total': total,
        'submitted': submitted,
        'inProgress': inProgress,
        'resolved': resolved,
        'categories': categories,
        'lastWeekCount': await _getLastWeekFeedbackCount(),
      };
    } catch (e) {
      print('Error getting feedback stats: $e');
      return {
        'total': 0,
        'submitted': 0,
        'inProgress': 0,
        'resolved': 0,
        'categories': {},
        'lastWeekCount': 0,
      };
    }
  }

  /// Get feedback count from last week
  static Future<int> _getLastWeekFeedbackCount() async {
    try {
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _firestore
          .collection('feedback')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(oneWeekAgo))
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Search feedback by keyword
  static Future<List<Map<String, dynamic>>> searchFeedback(String keyword) async {
    try {
      final querySnapshot = await _firestore
          .collection('feedback')
          .orderBy('timestamp', descending: true)
          .get();

      final allFeedback = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      // Filter by keyword (case-insensitive search)
      return allFeedback.where((feedback) {
        final feedbackText = (feedback['feedback'] ?? '').toString().toLowerCase();
        final userName = (feedback['userName'] ?? '').toString().toLowerCase();
        final userEmail = (feedback['userEmail'] ?? '').toString().toLowerCase();
        final category = (feedback['category'] ?? '').toString().toLowerCase();
        
        return feedbackText.contains(keyword.toLowerCase()) ||
               userName.contains(keyword.toLowerCase()) ||
               userEmail.contains(keyword.toLowerCase()) ||
               category.contains(keyword.toLowerCase());
      }).toList();
    } catch (e) {
      print('Error searching feedback: $e');
      return [];
    }
  }
}
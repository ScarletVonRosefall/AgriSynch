import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to handle rate limiting for various operations
/// Prevents abuse and controls costs by limiting operations per user
class RateLimitService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Rate limit configurations (operations per time window)
  static const Map<String, RateLimitConfig> rateLimits = {
    'message_send': RateLimitConfig(maxOperations: 50, windowMinutes: 1), // 50 messages per minute
    'message_conversation': RateLimitConfig(maxOperations: 100, windowMinutes: 5), // 100 messages per 5 min per conversation
    'order_create': RateLimitConfig(maxOperations: 10, windowMinutes: 60), // 10 orders per hour
    'product_create': RateLimitConfig(maxOperations: 20, windowMinutes: 60), // 20 products per hour
    'product_update': RateLimitConfig(maxOperations: 50, windowMinutes: 60), // 50 updates per hour
    'image_upload': RateLimitConfig(maxOperations: 30, windowMinutes: 60), // 30 images per hour
    'search_query': RateLimitConfig(maxOperations: 100, windowMinutes: 1), // 100 searches per minute
    'api_call': RateLimitConfig(maxOperations: 200, windowMinutes: 1), // 200 API calls per minute
    'notification_create': RateLimitConfig(maxOperations: 20, windowMinutes: 60), // 20 notifications per hour
    'deletion_request': RateLimitConfig(maxOperations: 1, windowMinutes: 1440), // 1 per day (24 hours)
    'password_reset': RateLimitConfig(maxOperations: 3, windowMinutes: 60), // 3 per hour
    'login_attempt': RateLimitConfig(maxOperations: 5, windowMinutes: 15), // 5 failed logins per 15 min
  };

  /// Check if the user can perform an operation
  /// Returns true if allowed, false if rate limit exceeded
  static Future<bool> checkRateLimit(String operationType, {String? userId, String? identifier}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final effectiveUserId = userId ?? user?.uid;
      
      if (effectiveUserId == null && identifier == null) {
        // If no user and no identifier, allow (shouldn't happen in normal flow)
        return true;
      }

      final config = rateLimits[operationType];
      if (config == null) {
        // No rate limit configured for this operation
        return true;
      }

      // Create a unique key for this rate limit check
      final key = identifier ?? '${effectiveUserId}_$operationType';
      final now = DateTime.now();
      final windowStart = now.subtract(Duration(minutes: config.windowMinutes));

      // Query recent operations
      final rateLimitDoc = await _firestore
          .collection('rateLimits')
          .doc(key)
          .get();

      if (!rateLimitDoc.exists) {
        // First operation, create the document
        await _firestore.collection('rateLimits').doc(key).set({
          'operations': [now.toIso8601String()],
          'lastUpdated': FieldValue.serverTimestamp(),
          'operationType': operationType,
          'userId': effectiveUserId,
        });
        return true;
      }

      final data = rateLimitDoc.data() as Map<String, dynamic>;
      final operations = (data['operations'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .where((timestamp) => timestamp.isAfter(windowStart))
          .toList() ?? [];

      // Check if within limit
      if (operations.length >= config.maxOperations) {
        debugPrint('Rate limit exceeded for $operationType: ${operations.length}/${config.maxOperations} in ${config.windowMinutes} minutes');
        return false;
      }

      // Add current operation and clean old ones
      operations.add(now);
      await _firestore.collection('rateLimits').doc(key).update({
        'operations': operations.map((e) => e.toIso8601String()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error checking rate limit: $e');
      // On error, allow the operation (fail open to not block users on technical issues)
      return true;
    }
  }

  /// Get remaining operations for a user
  static Future<int> getRemainingOperations(String operationType, {String? userId, String? identifier}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final effectiveUserId = userId ?? user?.uid;
      
      if (effectiveUserId == null && identifier == null) {
        return 999; // Unlimited if no user
      }

      final config = rateLimits[operationType];
      if (config == null) {
        return 999; // Unlimited if no config
      }

      final key = identifier ?? '${effectiveUserId}_$operationType';
      final now = DateTime.now();
      final windowStart = now.subtract(Duration(minutes: config.windowMinutes));

      final rateLimitDoc = await _firestore
          .collection('rateLimits')
          .doc(key)
          .get();

      if (!rateLimitDoc.exists) {
        return config.maxOperations;
      }

      final data = rateLimitDoc.data() as Map<String, dynamic>;
      final operations = (data['operations'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .where((timestamp) => timestamp.isAfter(windowStart))
          .length ?? 0;

      return (config.maxOperations - operations).clamp(0, config.maxOperations);
    } catch (e) {
      debugPrint('Error getting remaining operations: $e');
      return 999;
    }
  }

  /// Reset rate limit for a user (admin function)
  static Future<void> resetRateLimit(String operationType, String userId) async {
    try {
      final key = '${userId}_$operationType';
      await _firestore.collection('rateLimits').doc(key).delete();
    } catch (e) {
      debugPrint('Error resetting rate limit: $e');
    }
  }

  /// Get user-friendly error message
  static String getRateLimitMessage(String operationType) {
    final config = rateLimits[operationType];
    if (config == null) return 'Rate limit exceeded. Please try again later.';

    switch (operationType) {
      case 'message_send':
        return 'You\'re sending messages too quickly. Please wait a moment.';
      case 'order_create':
        return 'You\'ve created too many orders recently. Please try again in ${config.windowMinutes} minutes.';
      case 'product_create':
        return 'You\'ve created too many products recently. Please try again in ${config.windowMinutes} minutes.';
      case 'image_upload':
        return 'You\'ve uploaded too many images. Please try again in ${config.windowMinutes} minutes.';
      case 'search_query':
        return 'Too many searches. Please slow down.';
      case 'deletion_request':
        return 'You can only request account deletion once per day.';
      case 'password_reset':
        return 'Too many password reset attempts. Please try again in ${config.windowMinutes} minutes.';
      case 'login_attempt':
        return 'Too many failed login attempts. Please try again in ${config.windowMinutes} minutes.';
      default:
        return 'Rate limit exceeded for $operationType. Please try again in ${config.windowMinutes} minutes.';
    }
  }

  /// Cleanup old rate limit records (should be run periodically)
  static Future<void> cleanupOldRecords() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      
      final oldRecords = await _firestore
          .collection('rateLimits')
          .where('lastUpdated', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (var doc in oldRecords.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      debugPrint('Cleaned up ${oldRecords.docs.length} old rate limit records');
    } catch (e) {
      debugPrint('Error cleaning up rate limit records: $e');
    }
  }

  /// Check multiple operations at once (for bulk operations)
  static Future<bool> checkBulkRateLimit(
    String operationType,
    int count, {
    String? userId,
    String? identifier,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final effectiveUserId = userId ?? user?.uid;
      
      if (effectiveUserId == null && identifier == null) {
        return true;
      }

      final config = rateLimits[operationType];
      if (config == null) {
        return true;
      }

      final key = identifier ?? '${effectiveUserId}_$operationType';
      final now = DateTime.now();
      final windowStart = now.subtract(Duration(minutes: config.windowMinutes));

      final rateLimitDoc = await _firestore
          .collection('rateLimits')
          .doc(key)
          .get();

      if (!rateLimitDoc.exists) {
        // First operations, check if count exceeds limit
        if (count > config.maxOperations) {
          return false;
        }
        
        await _firestore.collection('rateLimits').doc(key).set({
          'operations': List.generate(count, (_) => now.toIso8601String()),
          'lastUpdated': FieldValue.serverTimestamp(),
          'operationType': operationType,
          'userId': effectiveUserId,
        });
        return true;
      }

      final data = rateLimitDoc.data() as Map<String, dynamic>;
      final operations = (data['operations'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .where((timestamp) => timestamp.isAfter(windowStart))
          .toList() ?? [];

      // Check if adding count would exceed limit
      if (operations.length + count > config.maxOperations) {
        return false;
      }

      // Add all operations
      operations.addAll(List.generate(count, (_) => now));
      await _firestore.collection('rateLimits').doc(key).update({
        'operations': operations.map((e) => e.toIso8601String()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error checking bulk rate limit: $e');
      return true;
    }
  }
}

/// Configuration for a rate limit
class RateLimitConfig {
  final int maxOperations;
  final int windowMinutes;

  const RateLimitConfig({
    required this.maxOperations,
    required this.windowMinutes,
  });
}

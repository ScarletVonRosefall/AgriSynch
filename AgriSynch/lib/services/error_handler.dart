import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Centralized error handling service for the AgriSynch app
class ErrorHandler {
  static bool _crashlyticsEnabled = false;

  /// Initialize Crashlytics (call this in main.dart)
  static Future<void> initializeCrashlytics() async {
    try {
      // Pass all uncaught errors to Crashlytics
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };

      _crashlyticsEnabled = true;
      debugPrint('✅ Firebase Crashlytics initialized');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize Crashlytics: $e');
      _crashlyticsEnabled = false;
    }
  }

  /// Set user identifier for crash reports
  static Future<void> setUserIdentifier(String userId, {String? email}) async {
    if (!_crashlyticsEnabled) return;
    
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      if (email != null) {
        await FirebaseCrashlytics.instance.setCustomKey('email', email);
      }
    } catch (e) {
      debugPrint('Error setting user identifier: $e');
    }
  }

  /// Set custom key-value pairs for crash reports
  static Future<void> setCustomKey(String key, dynamic value) async {
    if (!_crashlyticsEnabled) return;
    
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
      debugPrint('Error setting custom key: $e');
    }
  }

  /// Get user-friendly error message from exception
  static String getErrorMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred';

    // Firebase Auth Errors
    if (error is FirebaseAuthException) {
      return _getAuthErrorMessage(error);
    }

    // Firestore Errors
    if (error is FirebaseException) {
      return _getFirestoreErrorMessage(error);
    }

    // Network/Timeout Errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    // Format error
    if (error.toString().contains('FormatException')) {
      return 'Invalid data format received. Please try again.';
    }

    // Generic error with details
    return 'An error occurred: ${error.toString()}';
  }

  /// Get Firebase Auth specific error messages
  static String _getAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again to perform this action.';
      default:
        return 'Authentication error: ${error.message ?? error.code}';
    }
  }

  /// Get Firestore specific error messages
  static String _getFirestoreErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You don\'t have permission to access this data.';
      case 'not-found':
        return 'The requested data was not found.';
      case 'already-exists':
        return 'This data already exists.';
      case 'cancelled':
        return 'Operation was cancelled.';
      case 'unknown':
        return 'An unknown error occurred. Please try again.';
      case 'invalid-argument':
        return 'Invalid data provided. Please check your input.';
      case 'deadline-exceeded':
        return 'Request timed out. Please try again.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again later.';
      case 'unauthenticated':
        return 'You must be signed in to perform this action.';
      case 'resource-exhausted':
        return 'Too many requests. Please try again later.';
      case 'failed-precondition':
        return 'Operation failed. Please try again.';
      case 'aborted':
        return 'Operation was aborted. Please try again.';
      case 'out-of-range':
        return 'Invalid data range provided.';
      case 'unimplemented':
        return 'This feature is not yet available.';
      case 'internal':
        return 'Internal error occurred. Please try again.';
      case 'data-loss':
        return 'Data loss detected. Please contact support.';
      default:
        return 'Database error: ${error.message ?? error.code}';
    }
  }

  /// Show error dialog to user
  static void showErrorDialog(BuildContext context, String title, dynamic error) {
    final message = getErrorMessage(error);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar to user
  static void showErrorSnackBar(BuildContext context, dynamic error, {
    String? customMessage,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final message = customMessage ?? getErrorMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show success snackbar to user
  static void showSuccessSnackBar(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Log error for debugging and send to Crashlytics
  /// Supports both legacy format (context as first param) and new format (error, stackTrace, context)
  static void logError(dynamic errorOrContext, [dynamic errorOrStackTrace, dynamic optionalParam3, dynamic optionalParam4, dynamic optionalParam5]) {
    // Support both calling conventions
    String? context;
    dynamic error;
    StackTrace? stack;
    bool isFatal = false;
    Map<String, dynamic>? extraData;
    
    // New format: logError(error, stackTrace, context: 'Context')
    // Since Dart doesn't support method overloading, we check parameter types
    if (errorOrContext is! String) {
      error = errorOrContext;
      stack = errorOrStackTrace as StackTrace?;
      // Context would be passed via named parameter (which we can't use in positional-only)
      // So we'll just use the new signature without named params
    } 
    // Legacy format: logError('Context', error, stackTrace, fatal, additionalData)
    else {
      context = errorOrContext;
      error = errorOrStackTrace;
      stack = optionalParam3 as StackTrace?;
      if (optionalParam4 is bool) {
        isFatal = optionalParam4;
      }
      if (optionalParam5 is Map<String, dynamic>) {
        extraData = optionalParam5;
      }
    }
    
    // Console logging
    debugPrint('═══════════════════════════════════════');
    if (context != null) {
      debugPrint('ERROR in $context');
    } else {
      debugPrint('ERROR');
    }
    debugPrint('Message: ${getErrorMessage(error)}');
    debugPrint('Details: $error');
    if (stack != null) {
      debugPrint('Stack Trace:\n$stack');
    }
    if (extraData != null) {
      debugPrint('Additional Data: $extraData');
    }
    debugPrint('═══════════════════════════════════════');
    
    // Send to Firebase Crashlytics
    if (_crashlyticsEnabled) {
      try {
        // Set custom keys for context
        if (context != null) {
          FirebaseCrashlytics.instance.setCustomKey('error_context', context);
        }
        FirebaseCrashlytics.instance.setCustomKey('error_message', getErrorMessage(error));
        
        // Add additional data as custom keys
        if (extraData != null) {
          extraData.forEach((key, value) {
            FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
          });
        }

        // Record the error
        FirebaseCrashlytics.instance.recordError(
          error,
          stack ?? StackTrace.current,
          reason: context,
          fatal: isFatal,
        );
      } catch (e) {
        debugPrint('Failed to log to Crashlytics: $e');
      }
    }
  }

  /// Log a custom message to Crashlytics
  static void logMessage(String message) {
    debugPrint('📝 Log: $message');
    
    if (_crashlyticsEnabled) {
      try {
        FirebaseCrashlytics.instance.log(message);
      } catch (e) {
        debugPrint('Failed to log message to Crashlytics: $e');
      }
    }
  }

  /// Execute an async operation with error handling
  static Future<T?> tryAsync<T>({
    required Future<T> Function() operation,
    required BuildContext context,
    String? errorTitle,
    String? customErrorMessage,
    bool showDialog = false,
    bool showSnackBar = true,
    VoidCallback? onError,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      logError(errorTitle ?? 'Async Operation', error, stackTrace);
      
      if (context.mounted) {
        if (showDialog) {
          ErrorHandler.showErrorDialog(context, errorTitle ?? 'Error', error);
        } else if (showSnackBar) {
          ErrorHandler.showErrorSnackBar(context, error, customMessage: customErrorMessage);
        }
      }
      
      onError?.call();
      return null;
    }
  }

  /// Execute a sync operation with error handling
  static T? trySync<T>({
    required T Function() operation,
    required BuildContext context,
    String? errorTitle,
    String? customErrorMessage,
    bool showDialog = false,
    bool showSnackBar = true,
    VoidCallback? onError,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      logError(errorTitle ?? 'Sync Operation', error, stackTrace);
      
      if (context.mounted) {
        if (showDialog) {
          ErrorHandler.showErrorDialog(context, errorTitle ?? 'Error', error);
        } else if (showSnackBar) {
          ErrorHandler.showErrorSnackBar(context, error, customMessage: customErrorMessage);
        }
      }
      
      onError?.call();
      return null;
    }
  }

  /// Retry operation with exponential backoff
  static Future<T?> retryOperation<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    String? operationName,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxAttempts) {
      try {
        attempt++;
        return await operation();
      } catch (error) {
        if (attempt >= maxAttempts) {
          logError(
            operationName ?? 'Retry Operation',
            'Failed after $maxAttempts attempts: $error',
          );
          rethrow;
        }

        debugPrint('Attempt $attempt failed. Retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * backoffMultiplier).round());
      }
    }

    return null;
  }

  /// Check if error is network-related
  static bool isNetworkError(dynamic error) {
    if (error == null) return false;
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
           errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('failed host lookup') ||
           (error is FirebaseException && error.code == 'unavailable');
  }

  /// Check if error is permission-related
  static bool isPermissionError(dynamic error) {
    if (error == null) return false;
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('permission') ||
           (error is FirebaseException && error.code == 'permission-denied');
  }

  /// Check if error is authentication-related
  static bool isAuthError(dynamic error) {
    if (error == null) return false;
    
    if (error is FirebaseAuthException) return true;
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('firebase_auth') ||
           errorString.contains('authentication') ||
           errorString.contains('unauthenticated');
  }

  /// Get user-friendly message for error code
  static String getUserFriendlyMessage(String errorCode) {
    // Firebase Auth error codes
    if (errorCode.contains('user-not-found')) {
      return 'No account found with this email address.';
    }
    if (errorCode.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    }
    if (errorCode.contains('email-already-in-use')) {
      return 'This email is already registered.';
    }
    if (errorCode.contains('permission-denied')) {
      return 'You don\'t have permission to perform this action.';
    }
    if (errorCode.contains('not-found')) {
      return 'The requested data was not found.';
    }
    
    return 'An error occurred. Please try again.';
  }

  /// Sanitize error message to remove sensitive information
  static String sanitizeError(String errorMessage) {
    String sanitized = errorMessage;
    
    // Remove email addresses
    sanitized = sanitized.replaceAll(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      '[EMAIL]',
    );
    
    // Remove API keys
    sanitized = sanitized.replaceAll(
      RegExp(r'AIza[0-9A-Za-z-_]{35}'),
      '[API_KEY]',
    );
    
    // Remove auth tokens
    sanitized = sanitized.replaceAll(
      RegExp(r'Bearer [A-Za-z0-9-._~+/]+=*'),
      'Bearer [TOKEN]',
    );
    
    // Remove phone numbers
    sanitized = sanitized.replaceAll(
      RegExp(r'\+?[0-9]{10,13}'),
      '[PHONE]',
    );
    
    return sanitized;
  }

  /// Check if error is retryable
  static bool isRetryable(dynamic error) {
    if (error == null) return false;
    
    // Network errors are retryable
    if (isNetworkError(error)) return true;
    
    // Some Firebase errors are retryable
    if (error is FirebaseException) {
      return error.code == 'unavailable' ||
             error.code == 'deadline-exceeded' ||
             error.code == 'resource-exhausted' ||
             error.code == 'aborted';
    }
    
    // Permission and auth errors are not retryable
    if (isPermissionError(error) || isAuthError(error)) return false;
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
           errorString.contains('failed to connect');
  }

  /// Check if user should retry operation
  static bool shouldRetry(dynamic error) {
    if (error is FirebaseException) {
      // Retry on network issues or temporary failures
      return error.code == 'unavailable' ||
             error.code == 'deadline-exceeded' ||
             error.code == 'resource-exhausted';
    }
    
    return isNetworkError(error);
  }
}

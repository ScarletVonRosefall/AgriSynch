import 'package:flutter_test/flutter_test.dart';
import 'package:test001/services/error_handler.dart';

void main() {
  group('ErrorHandler - Error Message Extraction', () {
    test('Should extract Firebase Auth error messages', () {
      expect(
        ErrorHandler.getErrorMessage(Exception('[firebase_auth/user-not-found] No user found')),
        contains('No user found'),
      );
      expect(
        ErrorHandler.getErrorMessage(Exception('[firebase_auth/wrong-password] Invalid password')),
        contains('Invalid password'),
      );
      expect(
        ErrorHandler.getErrorMessage(Exception('[firebase_auth/email-already-in-use] Email exists')),
        contains('Email exists'),
      );
    });

    test('Should extract Firestore error messages', () {
      expect(
        ErrorHandler.getErrorMessage(Exception('[cloud_firestore/permission-denied] Access denied')),
        contains('Access denied'),
      );
      expect(
        ErrorHandler.getErrorMessage(Exception('[cloud_firestore/not-found] Document not found')),
        contains('Document not found'),
      );
    });

    test('Should handle generic exceptions', () {
      expect(
        ErrorHandler.getErrorMessage(Exception('Something went wrong')),
        contains('Something went wrong'),
      );
      expect(
        ErrorHandler.getErrorMessage(Exception('Network error')),
        contains('Network error'),
      );
    });

    test('Should handle null and empty errors gracefully', () {
      expect(
        ErrorHandler.getErrorMessage(Exception('')),
        isNotNull,
      );
      expect(
        ErrorHandler.getErrorMessage(Exception('   ')),
        isNotNull,
      );
    });
  });

  group('ErrorHandler - User-Friendly Messages', () {
    test('Should provide user-friendly Firebase Auth messages', () {
      final message = ErrorHandler.getUserFriendlyMessage('[firebase_auth/user-not-found]');
      expect(message, isNotNull);
      expect(message.length, greaterThan(0));
    });

    test('Should provide user-friendly Firestore messages', () {
      final message = ErrorHandler.getUserFriendlyMessage('[cloud_firestore/permission-denied]');
      expect(message, isNotNull);
      expect(message.length, greaterThan(0));
    });

    test('Should provide generic message for unknown errors', () {
      final message = ErrorHandler.getUserFriendlyMessage('unknown-error-code');
      expect(message, isNotNull);
      expect(message.length, greaterThan(0));
    });
  });

  group('ErrorHandler - Error Classification', () {
    test('Should identify network errors', () {
      expect(
        ErrorHandler.isNetworkError(Exception('network error')),
        isTrue,
      );
      expect(
        ErrorHandler.isNetworkError(Exception('Failed host lookup')),
        isTrue,
      );
      expect(
        ErrorHandler.isNetworkError(Exception('SocketException')),
        isTrue,
      );
    });

    test('Should identify permission errors', () {
      expect(
        ErrorHandler.isPermissionError(Exception('[cloud_firestore/permission-denied]')),
        isTrue,
      );
      expect(
        ErrorHandler.isPermissionError(Exception('permission denied')),
        isTrue,
      );
    });

    test('Should identify authentication errors', () {
      expect(
        ErrorHandler.isAuthError(Exception('[firebase_auth/user-not-found]')),
        isTrue,
      );
      expect(
        ErrorHandler.isAuthError(Exception('[firebase_auth/wrong-password]')),
        isTrue,
      );
    });

    test('Should return false for non-matching errors', () {
      expect(
        ErrorHandler.isNetworkError(Exception('Some other error')),
        isFalse,
      );
      expect(
        ErrorHandler.isPermissionError(Exception('Normal error')),
        isFalse,
      );
      expect(
        ErrorHandler.isAuthError(Exception('Generic error')),
        isFalse,
      );
    });
  });

  group('ErrorHandler - Error Logging', () {
    test('Should log errors without throwing', () {
      expect(
        () => ErrorHandler.logError(Exception('Test error'), StackTrace.current),
        returnsNormally,
      );
    });

    test('Should handle null stack traces', () {
      expect(
        () => ErrorHandler.logError(Exception('Test error'), null),
        returnsNormally,
      );
    });

    test('Should log errors with context', () {
      expect(
        () => ErrorHandler.logError(
          'Unit Test',
          Exception('Test error'),
          StackTrace.current,
        ),
        returnsNormally,
      );
    });
  });

  group('ErrorHandler - Error Sanitization', () {
    test('Should remove sensitive information from error messages', () {
      final sanitized = ErrorHandler.sanitizeError(
        'Error: user@example.com failed to authenticate',
      );
      expect(sanitized, isNot(contains('user@example.com')));
    });

    test('Should remove API keys from error messages', () {
      final sanitized = ErrorHandler.sanitizeError(
        'API Key: AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz123456789012345 failed',
      );
      // Note: ErrorHandler replaces API keys with [API_KEY] (regex expects AIza prefix + 35 chars)
      expect(sanitized, contains('[API_KEY]'));
    });

    test('Should preserve error structure', () {
      final original = '[firebase_auth/user-not-found] User not found';
      final sanitized = ErrorHandler.sanitizeError(original);
      expect(sanitized, contains('[firebase_auth/user-not-found]'));
    });
  });

  group('ErrorHandler - Retry Logic', () {
    test('Should identify retryable errors', () {
      expect(
        ErrorHandler.isRetryable(Exception('network timeout')),
        isTrue,
      );
      expect(
        ErrorHandler.isRetryable(Exception('Failed to connect')),
        isTrue,
      );
    });

    test('Should identify non-retryable errors', () {
      expect(
        ErrorHandler.isRetryable(Exception('[firebase_auth/user-not-found]')),
        isFalse,
      );
      expect(
        ErrorHandler.isRetryable(Exception('[cloud_firestore/permission-denied]')),
        isFalse,
      );
    });
  });
}

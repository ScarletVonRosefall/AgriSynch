import 'package:flutter/material.dart';
import '../services/rate_limit_service.dart';

class RateLimitHelper {
  /// Show rate limit error dialog with remaining operations
  static void showRateLimitDialog(
    BuildContext context,
    String operationType, {
    String? customTitle,
    String? customMessage,
  }) async {
    final remaining = await RateLimitService.getRemainingOperations(operationType);
    final message = customMessage ?? RateLimitService.getRateLimitMessage(operationType);
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.timer_off, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                customTitle ?? 'Rate Limit Reached',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Operations remaining: $remaining',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show rate limit snackbar (less intrusive)
  static void showRateLimitSnackBar(
    BuildContext context,
    String operationType, {
    String? customMessage,
  }) async {
    final remaining = await RateLimitService.getRemainingOperations(operationType);
    final message = customMessage ?? RateLimitService.getRateLimitMessage(operationType);
    
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.timer_off, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remaining: $remaining',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Get rate limit info widget to display on a page
  static Widget buildRateLimitInfo(String operationType) {
    return FutureBuilder<int>(
      future: RateLimitService.getRemainingOperations(operationType),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final remaining = snapshot.data!;
        final config = RateLimitService.rateLimits[operationType];
        
        if (config == null) return const SizedBox.shrink();

        final percentage = (remaining / config.maxOperations) * 100;
        final isLow = percentage < 25;
        final color = isLow ? Colors.orange : Colors.green;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLow ? Icons.warning_amber : Icons.check_circle_outline,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '$remaining/${config.maxOperations} operations remaining',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Handle rate limit exception with appropriate UI feedback
  static void handleRateLimitException(
    BuildContext context,
    Exception exception,
    String operationType, {
    bool useDialog = false,
  }) {
    final message = exception.toString().replaceAll('Exception: ', '');
    
    if (useDialog) {
      showRateLimitDialog(context, operationType, customMessage: message);
    } else {
      showRateLimitSnackBar(context, operationType, customMessage: message);
    }
  }
}

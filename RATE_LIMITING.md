# Rate Limiting Implementation Guide

## Overview
Comprehensive rate limiting system has been implemented to prevent abuse, control costs, and ensure fair usage of AgriSynch resources.

## Components

### 1. RateLimitService (`lib/services/rate_limit_service.dart`)

Core service that handles all rate limiting logic using Firestore for tracking.

**Features:**
- 12 pre-configured operation types with appropriate limits
- Firestore-based tracking for persistence across sessions
- Automatic cleanup of old records
- Fail-open design (allows operations if service errors occur)
- Bulk operation support for batch processing

**Rate Limits:**
```dart
'message_send': 50 per minute
'message_conversation': 100 per 5 minutes per conversation
'order_create': 10 per hour
'product_create': 20 per hour
'product_update': 50 per hour
'image_upload': 30 per hour
'search_query': 100 per minute
'api_call': 200 per minute
'notification_create': 20 per hour
'deletion_request': 1 per day
'password_reset': 3 per hour
'login_attempt': 5 per 15 minutes
```

**Key Methods:**
- `checkRateLimit(operationType, {userId, identifier})` - Check if operation is allowed
- `getRemainingOperations(operationType, {userId, identifier})` - Get remaining operations count
- `getRateLimitMessage(operationType)` - Get user-friendly error message
- `resetRateLimit(operationType, userId)` - Admin function to reset limits
- `cleanupOldRecords()` - Remove old rate limit records (7+ days)
- `checkBulkRateLimit(operationType, count, {userId, identifier})` - Validate bulk operations

### 2. RateLimitHelper (`lib/shared/rate_limit_helper.dart`)

UI helper widget for displaying rate limit information and errors to users.

**Features:**
- Dialog display for rate limit errors
- SnackBar notifications for less intrusive feedback
- Visual indicators showing remaining operations
- Color-coded warnings (orange for low, green for healthy)
- Exception handling utilities

**Key Methods:**
- `showRateLimitDialog(context, operationType)` - Show detailed dialog
- `showRateLimitSnackBar(context, operationType)` - Show quick notification
- `buildRateLimitInfo(operationType)` - Widget showing remaining operations
- `handleRateLimitException(context, exception, operationType)` - Automatic error handling

### 3. Firestore Security Rules

Server-side validation added to `firestore.rules` as backup layer:

```javascript
// Rate Limits Collection
match /rateLimits/{rateLimitId} {
  // Users can read/write their own rate limit records
  allow read, create, update: if isSignedIn() 
    && rateLimitId.matches(request.auth.uid + '_.*');
  
  // Admins can read all and delete (for reset)
  allow read, delete: if isAdmin();
}
```

**Helper Function Added:**
```javascript
function withinRateLimit(operationType, maxOps, windowMinutes) {
  // Validates rate limits at database level
}
```

## Integration Points

### 1. Chat Service (`lib/services/chat_service.dart`)
- **Operation**: `message_send`
- **Limit**: 50 per minute
- **Location**: Before message creation in `sendMessage()`
- **Error Handling**: Throws exception with user-friendly message

### 2. Order Service (`lib/services/order_service.dart`)
- **Operation**: `order_create`
- **Limit**: 10 per hour
- **Location**: Beginning of `createOrder()`
- **Error Handling**: Throws exception to prevent order creation

### 3. Product Service (`lib/services/product_service.dart`)
- **Operations**: 
  - `product_create` (20 per hour)
  - `product_update` (50 per hour)
- **Locations**: 
  - `addProduct()` - before Firestore add
  - `updateProduct()` - before Firestore update
- **Error Handling**: Throws exception with appropriate message

### 4. Image Upload Service (`lib/services/image_upload_service.dart`)
- **Operation**: `image_upload`
- **Limit**: 30 per hour
- **Location**: Beginning of `uploadProductImage()`
- **Error Handling**: Throws exception before Firebase Storage upload

### 5. Auth Service (`lib/auth/auth_service.dart`)
- **Operation**: `deletion_request`
- **Limit**: 1 per day
- **Location**: Beginning of `submitDeletionRequest()`
- **Error Handling**: Throws exception to prevent duplicate requests

## Usage Examples

### Checking Rate Limit
```dart
final canSend = await RateLimitService.checkRateLimit('message_send');
if (!canSend) {
  final message = RateLimitService.getRateLimitMessage('message_send');
  throw Exception(message);
}
// Proceed with operation
```

### Displaying Rate Limit Info
```dart
// Show as widget in UI
RateLimitHelper.buildRateLimitInfo('message_send')

// Show dialog on error
try {
  await someRateLimitedOperation();
} catch (e) {
  RateLimitHelper.handleRateLimitException(
    context, 
    e as Exception, 
    'message_send'
  );
}
```

### Admin Reset
```dart
// Reset rate limit for a user
await RateLimitService.resetRateLimit('message_send', userId);
```

## Database Structure

### rateLimits Collection
```
rateLimits/{userId}_{operationType}
  - operations: [timestamp1, timestamp2, ...]  // ISO 8601 strings
  - lastUpdated: Timestamp
  - operationType: String
  - userId: String
```

**Example Document:**
```json
{
  "operations": [
    "2024-01-15T10:30:00.000Z",
    "2024-01-15T10:31:00.000Z",
    "2024-01-15T10:32:00.000Z"
  ],
  "lastUpdated": Timestamp(2024-01-15 10:32:00),
  "operationType": "message_send",
  "userId": "abc123xyz"
}
```

## Testing Checklist

- [ ] Test message sending rate limit (50/min)
- [ ] Test order creation rate limit (10/hr)
- [ ] Test product creation rate limit (20/hr)
- [ ] Test product update rate limit (50/hr)
- [ ] Test image upload rate limit (30/hr)
- [ ] Test deletion request rate limit (1/day)
- [ ] Verify error messages are user-friendly
- [ ] Verify UI shows remaining operations
- [ ] Test admin reset functionality
- [ ] Verify Firestore rules block unauthorized access
- [ ] Test fail-open behavior on service errors
- [ ] Test cleanup of old records

## Maintenance

### Periodic Cleanup
Run cleanup to remove old rate limit records:
```dart
await RateLimitService.cleanupOldRecords();
```

Recommended: Schedule this to run daily via Cloud Functions or admin panel.

### Adjusting Limits
To modify rate limits, update the `rateLimits` map in `rate_limit_service.dart`:
```dart
static const Map<String, RateLimitConfig> rateLimits = {
  'message_send': RateLimitConfig(maxOperations: 50, windowMinutes: 1),
  // Add or modify limits here
};
```

### Monitoring
Monitor rate limit hits in Firebase Console:
1. Check `rateLimits` collection size
2. Look for documents with high operation counts
3. Review timestamps for patterns of abuse

## Security Considerations

1. **Client-Side Validation**: Primary rate limit checks happen in app
2. **Server-Side Backup**: Firestore rules provide secondary validation
3. **Fail-Open Design**: Service errors don't block legitimate users
4. **User Isolation**: Each user has separate rate limit tracking
5. **Admin Override**: Admins can reset limits for support cases

## Future Enhancements

Potential improvements:
- [ ] Add IP-based rate limiting for login attempts
- [ ] Implement tiered limits (premium users get higher limits)
- [ ] Add real-time monitoring dashboard for admins
- [ ] Email alerts for users approaching limits
- [ ] Automatic temporary bans for repeated violations
- [ ] Analytics on rate limit usage patterns
- [ ] Dynamic rate limits based on system load

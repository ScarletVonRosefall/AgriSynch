# AgriSynch Cloud Functions

Firebase Cloud Functions for handling push notifications in the AgriSynch app.

## Functions

### 1. `sendOrderNotification`
- **Trigger**: New document in `notifications` collection
- **Purpose**: Sends push notifications via FCM
- **Features**: 
  - Validates FCM token
  - Sends notification to device
  - Updates sent status
  - Error handling and logging

### 2. `notifyFarmerOnNewOrder`
- **Trigger**: New document in `orders` collection
- **Purpose**: Notifies farmers when they receive a new order
- **Message**: "🔔 New Order Received! [Buyer] ordered [Product] (₱[Amount])"

### 3. `notifyBuyerOnOrderStatusChange`
- **Trigger**: Update to `orders` collection (status field)
- **Purpose**: Notifies buyers when their order status changes
- **Statuses**: Confirmed, Preparing, Ready, In Transit, Delivered, Cancelled

### 4. `cleanupOldNotifications`
- **Trigger**: Scheduled (every 24 hours)
- **Purpose**: Deletes notifications older than 30 days
- **Keeps**: Database clean and performant

### 5. `updateNotificationBadge`
- **Trigger**: Any change to `notifications` collection
- **Purpose**: Updates user's unread notification count
- **Updates**: `users/{userId}/unreadNotificationCount`

## Setup

### Prerequisites
- Node.js 18 or higher
- Firebase CLI installed (`npm install -g firebase-tools`)
- Firebase project with Blaze (Pay as you go) plan

### Installation

1. Navigate to functions directory:
   ```bash
   cd functions
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

### Local Testing

1. Start the Firebase emulator:
   ```bash
   npm run serve
   ```

2. The functions will be available at:
   - http://localhost:5001/agrisynch-a9350/us-central1/sendOrderNotification
   - http://localhost:5001/agrisynch-a9350/us-central1/notifyFarmerOnNewOrder
   - etc.

### Deployment

1. Make sure you're logged in:
   ```bash
   firebase login
   ```

2. Deploy all functions:
   ```bash
   npm run deploy
   ```

   Or deploy specific function:
   ```bash
   firebase deploy --only functions:sendOrderNotification
   ```

### View Logs

```bash
npm run logs
```

Or for specific function:
```bash
firebase functions:log --only sendOrderNotification
```

## Testing

### Test Notification Flow

1. **Create a test notification document** in Firestore:
   ```javascript
   {
     userId: "test-user-id",
     fcmToken: "user-fcm-token-here",
     title: "Test Notification",
     body: "This is a test message",
     data: {
       type: "test",
       action: "view"
     },
     createdAt: Timestamp.now(),
     sent: false
   }
   ```

2. **Watch the logs**:
   ```bash
   npm run logs
   ```

3. **Check the notification is sent** (document updated with `sent: true`)

### Test Order Notifications

1. Create an order in Firestore (via app or console)
2. Check farmer receives notification
3. Update order status
4. Check buyer receives notification

## Cost Estimation

Based on Firebase Cloud Functions pricing:

- **Free Tier**: 
  - 2 million invocations/month
  - 400,000 GB-seconds/month
  - 200,000 CPU-seconds/month

- **Estimated Usage** (Small App):
  - ~1000 orders/month
  - ~2000 status updates/month
  - ~30 cleanup runs/month
  - **Total**: ~3030 invocations/month
  - **Cost**: $0.00 (within free tier)

## Troubleshooting

### Function not triggering?
- Check Firestore indexes are configured
- Verify function is deployed: `firebase functions:list`
- Check logs: `npm run logs`

### Notifications not being sent?
- Verify FCM token is valid
- Check user has notification permissions
- Review error logs in notification document

### High costs?
- Check for infinite loops in triggers
- Review cleanup function schedule
- Optimize query limits

## Security Notes

- Functions run with admin privileges
- Validate all input data
- Don't expose sensitive information in logs
- Use security rules for Firestore access

## Support

For issues or questions:
- Check Firebase Console logs
- Review function execution history
- Test with Firebase emulator locally

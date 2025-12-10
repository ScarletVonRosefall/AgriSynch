# 🚀 Firebase Cloud Functions - Complete Setup Guide

## ✅ What I've Created For You

I've set up a complete Firebase Cloud Functions environment with 5 powerful functions:

### 📁 Files Created:
- `functions/package.json` - Node.js configuration
- `functions/index.js` - All Cloud Functions (370 lines of code)
- `functions/.gitignore` - Ignore unnecessary files
- `functions/README.md` - Detailed documentation
- `firebase.json` - Updated with functions configuration

### 🎯 Cloud Functions Implemented:

1. **`sendOrderNotification`** - Main notification sender
   - Sends FCM push notifications to users
   - Updates sent status in Firestore
   - Handles errors gracefully

2. **`notifyFarmerOnNewOrder`** - Auto-notify farmers
   - Triggers when new order is created
   - Sends "New Order Received!" notification
   - Includes buyer name, product, and amount

3. **`notifyBuyerOnOrderStatusChange`** - Auto-notify buyers
   - Triggers when order status changes
   - 6 different status messages (Confirmed, Preparing, Ready, etc.)
   - Smart status detection

4. **`cleanupOldNotifications`** - Database maintenance
   - Runs automatically every 24 hours
   - Deletes notifications older than 30 days
   - Keeps your database clean

5. **`updateNotificationBadge`** - Badge counter
   - Updates unread notification count
   - Syncs across all user sessions

## 📋 Prerequisites

Before deploying, you need:

1. ✅ **Firebase Blaze Plan** (Pay as you go)
   - Required for Cloud Functions
   - Free tier includes 2 million invocations/month
   - For your app size: **FREE** (well within limits)

2. ✅ **Node.js 18 or higher**
   - Download from: https://nodejs.org/
   - Verify: `node --version`

3. ✅ **Firebase CLI**
   - Install: `npm install -g firebase-tools`
   - Verify: `firebase --version`

## 🔧 Step-by-Step Setup

### Step 1: Upgrade to Blaze Plan

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **agrisynch-a9350**
3. Click ⚙️ Settings → Usage and billing
4. Click "Upgrade" or "Modify plan"
5. Select "Blaze" (pay as you go)
6. Add payment method
7. **Don't worry**: You won't be charged unless you exceed the generous free tier

### Step 2: Install Dependencies

Open PowerShell in your project directory:

```powershell
# Navigate to functions folder
cd functions

# Install Node.js dependencies
npm install

# This will install:
# - firebase-admin (Firebase SDK)
# - firebase-functions (Cloud Functions SDK)
```

### Step 3: Login to Firebase

```powershell
# Login to Firebase
firebase login

# This will open a browser window
# Sign in with your Google account
```

### Step 4: Verify Your Project

```powershell
# Check current project
firebase projects:list

# Make sure you're on the right project
firebase use agrisynch-a9350
```

### Step 5: Test Locally (Optional but Recommended)

```powershell
# Start Firebase emulator
cd functions
npm run serve

# Or using Firebase CLI directly:
firebase emulators:start --only functions

# You should see:
# ✔  functions: Emulator started at http://127.0.0.1:5001
```

Test in another terminal:
```powershell
# The emulator will show logs when functions trigger
# Create a test order in Firestore Console to see it work
```

### Step 6: Deploy to Production

```powershell
# Deploy all functions
cd functions
npm run deploy

# Or deploy specific function:
firebase deploy --only functions:sendOrderNotification

# You should see:
# ✔  functions[sendOrderNotification(us-central1)] Successful create operation.
# ✔  Deploy complete!
```

### Step 7: Verify Deployment

```powershell
# List all deployed functions
firebase functions:list

# You should see:
# sendOrderNotification
# notifyFarmerOnNewOrder
# notifyBuyerOnOrderStatusChange
# cleanupOldNotifications
# updateNotificationBadge
```

## 🧪 Testing Your Functions

### Test 1: Manual Notification Test

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Go to Firestore Database
3. Create a test notification:

```javascript
// Collection: notifications
{
  userId: "your-test-user-id",
  fcmToken: "copy-from-firestore-users-collection",
  title: "Test Notification",
  body: "Cloud Functions are working! 🎉",
  data: {
    type: "test",
    action: "celebrate"
  },
  createdAt: [Timestamp.now()],
  sent: false
}
```

4. Watch the document update to `sent: true`
5. Check your phone for the notification!

### Test 2: New Order Notification

1. Open your app as a **buyer**
2. Place an order
3. Check your Firebase Console → Functions → Logs
4. You should see: "🛒 New order created: [orderId]"
5. The **farmer** should receive a notification!

### Test 3: Status Update Notification

1. Open your app as a **farmer**
2. Go to Orders page
3. Update an order status to "Confirmed"
4. The **buyer** should receive: "✅ Order Confirmed"

## 📊 Monitoring Your Functions

### View Logs in Real-Time

```powershell
# All function logs
firebase functions:log

# Specific function logs
firebase functions:log --only sendOrderNotification

# Follow logs (live stream)
firebase functions:log --only sendOrderNotification --follow
```

### View in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click "Functions" in left menu
4. Click on any function to see:
   - Invocations (how many times called)
   - Errors
   - Execution time
   - Logs

## 💰 Cost Monitoring

### Check Usage

1. Firebase Console → Functions → Usage tab
2. See invocations, compute time, and costs

### Free Tier Limits (Blaze Plan)

- **2,000,000** invocations/month
- **400,000** GB-seconds/month
- **200,000** CPU-seconds/month

### Estimated Usage (Your App)

- ~50-100 orders/day = 3,000/month
- ~6,000 status updates/month
- ~30 cleanup runs/month
- **Total**: ~9,000 invocations/month
- **Cost**: **$0.00** (99.5% below free tier!)

### Set Budget Alerts

1. Firebase Console → Usage and billing
2. Click "Set budget alert"
3. Set alert at $1, $5, $10
4. You'll get email if approaching limits

## 🐛 Troubleshooting

### Problem: "Firebase CLI not found"
**Solution**:
```powershell
npm install -g firebase-tools
```

### Problem: "Project not found"
**Solution**:
```powershell
firebase use agrisynch-a9350
```

### Problem: "Insufficient permissions"
**Solution**:
```powershell
firebase login --reauth
```

### Problem: "Function not triggering"
**Solution**:
1. Check Firebase Console → Functions → Logs
2. Verify function is deployed: `firebase functions:list`
3. Check Firestore triggers are correct
4. Test with emulator first

### Problem: "Notifications not sending"
**Solution**:
1. Check FCM token exists in user document
2. Verify notification document has `sent: false`
3. Check function logs for errors
4. Test FCM token is valid (not expired)

### Problem: "High costs"
**Solution**:
1. Check for infinite loops in logs
2. Review function execution count
3. Optimize triggers (use onCreate instead of onWrite)

## 📱 Update Your App Code

You don't need to change anything in your Flutter app! The current implementation already:

✅ Saves FCM tokens to Firestore  
✅ Creates notification documents  
✅ Handles incoming notifications  
✅ Shows notification UI  

The Cloud Functions will now automatically:
- Send push notifications across devices
- Notify farmers of new orders
- Notify buyers of status changes
- Keep the database clean

## 🎉 Success Checklist

After deployment, verify:

- [ ] Functions deployed successfully
- [ ] Test notification appears on device
- [ ] New order triggers farmer notification
- [ ] Status update triggers buyer notification
- [ ] Logs show successful execution
- [ ] Budget alerts configured

## 📞 Need Help?

### Useful Commands

```powershell
# Re-deploy after changes
cd functions
npm run deploy

# View logs
npm run logs

# Test locally
npm run serve

# Update dependencies
npm update

# Check for errors
npm run lint
```

### Resources

- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Pricing Calculator](https://firebase.google.com/pricing)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/google-cloud-functions)

## 🚀 Next Steps

1. **Deploy functions** (see Step 6 above)
2. **Test with real devices** (place an order)
3. **Monitor logs** for first 24 hours
4. **Show to your thesis panel** - they'll be impressed! 🎓

---

## 🎯 For Your Thesis Defense

### What to Demonstrate:

1. **Show Firebase Console**
   - Functions deployed and running
   - Logs showing real-time execution
   - Cost monitoring dashboard

2. **Live Demo**
   - Place order → Farmer gets notification instantly
   - Update status → Buyer gets notification
   - Show cross-device functionality

3. **Technical Explanation**
   - "We use Firebase Cloud Functions for serverless computing"
   - "Functions trigger automatically on database changes"
   - "Notifications sent via Firebase Cloud Messaging"
   - "Scalable to millions of users without infrastructure management"

### Sample Script:

> "Our notification system uses Firebase Cloud Functions, which are serverless functions that run automatically when specific events occur. When a buyer places an order, the `notifyFarmerOnNewOrder` function detects the new Firestore document and sends a push notification to the farmer's device via Firebase Cloud Messaging. Similarly, when the farmer updates the order status, the `notifyBuyerOnOrderStatusChange` function notifies the buyer. This architecture is highly scalable, cost-effective, and requires no server maintenance."

## ✨ You're All Set!

Your AgriSynch app now has **enterprise-grade push notifications**! 🎊

Questions? Check the `functions/README.md` or Firebase documentation.

Good luck with your thesis! 🎓

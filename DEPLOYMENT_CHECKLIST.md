# ✅ Cloud Functions Deployment Checklist

Use this checklist to track your Cloud Functions setup progress.

## 📋 Pre-Deployment Checklist

### Prerequisites
- [ ] Node.js 18+ installed
  - Check: `node --version`
  - Download: https://nodejs.org/
  
- [ ] Firebase CLI installed
  - Check: `firebase --version`
  - Install: `npm install -g firebase-tools`
  
- [ ] Firebase Blaze Plan enabled
  - Go to: https://console.firebase.google.com/
  - Project Settings → Usage and billing → Upgrade

### Account Setup
- [ ] Logged into Firebase CLI
  - Run: `firebase login`
  
- [ ] Correct project selected
  - Run: `firebase use agrisynch-a9350`
  - Verify: `firebase projects:list`

## 🚀 Deployment Steps

### Local Testing (Optional but Recommended)
- [ ] Navigate to functions folder: `cd functions`
- [ ] Install dependencies: `npm install`
- [ ] Start emulator: `npm run serve`
- [ ] Test functions locally
- [ ] Verify no errors in console

### Production Deployment
- [ ] Review function code in `functions/index.js`
- [ ] Run deployment script: `.\deploy-functions.ps1`
  - Or manually: `cd functions` → `npm run deploy`
- [ ] Wait for deployment to complete (2-5 minutes)
- [ ] Verify all 5 functions deployed successfully

### Verification
- [ ] List deployed functions
  - Run: `firebase functions:list`
  - Should see:
    - sendOrderNotification
    - notifyFarmerOnNewOrder
    - notifyBuyerOnOrderStatusChange
    - cleanupOldNotifications
    - updateNotificationBadge

- [ ] Check Firebase Console
  - Go to: https://console.firebase.google.com/
  - Functions → See all 5 functions listed
  - No deployment errors

## 🧪 Testing

### Test 1: Manual Notification
- [ ] Create test notification in Firestore:
  ```
  Collection: notifications
  Document: auto-ID
  Fields:
    - userId: [your test user ID]
    - fcmToken: [from users collection]
    - title: "Test Notification"
    - body: "Testing Cloud Functions!"
    - sent: false
    - createdAt: [timestamp]
  ```
- [ ] Wait 2-3 seconds
- [ ] Document updates to `sent: true`
- [ ] Notification received on device

### Test 2: New Order Notification
- [ ] Login as buyer in app
- [ ] Place a new order
- [ ] Check Firebase Console → Functions → Logs
- [ ] See "🛒 New order created" log entry
- [ ] Farmer receives notification on device

### Test 3: Status Update Notification
- [ ] Login as farmer in app
- [ ] Update order status to "Confirmed"
- [ ] Check Firebase Console → Functions → Logs
- [ ] See "📦 Order status changed" log entry
- [ ] Buyer receives notification on device

## 📊 Monitoring Setup

### Logging
- [ ] View function logs: `firebase functions:log`
- [ ] Check Firebase Console → Functions → each function → Logs tab
- [ ] No error logs present
- [ ] Successful execution logs visible

### Cost Monitoring
- [ ] Set budget alert
  - Firebase Console → Usage and billing
  - Click "Set budget alert"
  - Set alerts at $1, $5, $10
  
- [ ] Review current usage
  - Functions → Usage tab
  - Check invocations count
  - Verify within free tier

### Health Check
- [ ] All functions show "Healthy" status
- [ ] No failed invocations
- [ ] Average execution time < 5 seconds
- [ ] Error rate < 1%

## 📱 App Integration Verification

### Farmer Flow
- [ ] Receives notification for new orders
- [ ] Notification shows buyer name
- [ ] Notification shows product name
- [ ] Notification shows order amount
- [ ] Tapping notification opens order details

### Buyer Flow
- [ ] Receives notification on status change
- [ ] Correct status message shown:
  - [ ] Confirmed: "✅ Order Confirmed"
  - [ ] Preparing: "📦 Order Preparing"
  - [ ] Ready: "✨ Order Ready"
  - [ ] In Transit: "🚚 Order In Transit"
  - [ ] Delivered: "🎉 Order Delivered"
  - [ ] Cancelled: "❌ Order Cancelled"
- [ ] Tapping notification opens order details

## 🎓 Thesis Demo Preparation

### Documentation
- [ ] Read CLOUD_FUNCTIONS_SETUP.md
- [ ] Read functions/README.md
- [ ] Understand function flow
- [ ] Prepare explanation for panel

### Demo Script
- [ ] Practice live demo
- [ ] Test on two devices simultaneously
- [ ] Prepare backup screenshots/video
- [ ] Have Firebase Console ready to show

### Talking Points
- [ ] Explain serverless architecture
- [ ] Discuss scalability benefits
- [ ] Show cost effectiveness (free tier)
- [ ] Demonstrate real-time notifications
- [ ] Highlight security (server-side logic)

## 🐛 Troubleshooting

If something doesn't work:

### Functions Not Deploying
- [ ] Check Node.js version: `node --version` (should be 18+)
- [ ] Verify project: `firebase use agrisynch-a9350`
- [ ] Check billing enabled in Firebase Console
- [ ] Review deployment errors in console

### Notifications Not Sending
- [ ] Verify FCM token exists in user document
- [ ] Check function logs for errors: `firebase functions:log`
- [ ] Test with manual notification first
- [ ] Verify notification document has `sent: false`

### High Error Rate
- [ ] Check function logs: `firebase functions:log`
- [ ] Review error messages
- [ ] Test with emulator locally
- [ ] Verify Firestore data structure matches expected format

## ✅ Final Checklist

Before thesis defense:
- [ ] All 5 functions deployed and working
- [ ] Test notifications working on real devices
- [ ] Logs showing successful executions
- [ ] Budget alerts configured
- [ ] Demo prepared and tested
- [ ] Documentation reviewed
- [ ] Backup plan ready (screenshots/video)

## 🎉 Success!

When all boxes are checked, your Cloud Functions are production-ready!

---

**Need help?** Check:
- `CLOUD_FUNCTIONS_SETUP.md` - Detailed setup guide
- `functions/README.md` - Function documentation
- Firebase Console → Functions → Logs

**Questions?** Review the troubleshooting section above.

**Ready to deploy?** Run: `.\deploy-functions.ps1`

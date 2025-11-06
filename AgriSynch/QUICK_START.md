# 🚀 Quick Start - Cloud Functions

## One-Command Deployment

```powershell
.\deploy-functions.ps1
```

This script will:
1. ✅ Check Node.js installation
2. ✅ Install/verify Firebase CLI
3. ✅ Login to Firebase
4. ✅ Set correct project
5. ✅ Install dependencies
6. ✅ Deploy all functions

## Manual Deployment

If you prefer manual steps:

```powershell
# 1. Install Firebase CLI (if not installed)
npm install -g firebase-tools

# 2. Login
firebase login

# 3. Set project
firebase use agrisynch-a9350

# 4. Install dependencies
cd functions
npm install

# 5. Deploy
npm run deploy
```

## Test Locally First

```powershell
.\test-functions-local.ps1
```

Or manually:
```powershell
cd functions
npm run serve
```

## Common Commands

```powershell
# View logs
firebase functions:log

# List deployed functions
firebase functions:list

# Deploy specific function
firebase deploy --only functions:sendOrderNotification

# Test locally
firebase emulators:start --only functions
```

## What Happens After Deployment?

✅ **Automatic Notifications**:
- Buyer places order → Farmer gets notified
- Farmer updates status → Buyer gets notified
- Works across all devices instantly!

✅ **5 Functions Running**:
1. `sendOrderNotification` - Sends push notifications
2. `notifyFarmerOnNewOrder` - New order alerts
3. `notifyBuyerOnOrderStatusChange` - Status update alerts
4. `cleanupOldNotifications` - Daily cleanup
5. `updateNotificationBadge` - Badge counter

## Quick Test

After deployment:

1. **Open your app as a buyer**
2. **Place an order**
3. **Check if farmer receives notification** ✅

If it works, you're done! 🎉

## Need Help?

- Full guide: `CLOUD_FUNCTIONS_SETUP.md`
- Checklist: `DEPLOYMENT_CHECKLIST.md`
- Function docs: `functions/README.md`

## Troubleshooting

**Error: "Firebase CLI not found"**
```powershell
npm install -g firebase-tools
```

**Error: "Not logged in"**
```powershell
firebase login
```

**Error: "Billing required"**
- Enable Blaze plan in Firebase Console
- It's free for your usage level!

**Functions not triggering?**
```powershell
# Check logs
firebase functions:log

# Verify deployment
firebase functions:list
```

## Cost

**Your app usage**: FREE ✅
- Free tier: 2,000,000 invocations/month
- Your estimated usage: ~9,000/month
- Cost: $0.00

## Files Created

```
functions/
  ├── index.js          # All 5 Cloud Functions
  ├── package.json      # Node.js config
  ├── .gitignore        # Git ignore rules
  └── README.md         # Detailed docs

Root/
  ├── firebase.json               # Updated with functions
  ├── deploy-functions.ps1        # Deployment script
  ├── test-functions-local.ps1    # Local testing script
  ├── CLOUD_FUNCTIONS_SETUP.md    # Full setup guide
  ├── DEPLOYMENT_CHECKLIST.md     # Step-by-step checklist
  └── QUICK_START.md              # This file
```

## Ready?

Run this command to deploy:

```powershell
.\deploy-functions.ps1
```

Then test by placing an order in your app!

---

**That's it!** Your Cloud Functions are ready to deploy. 🚀

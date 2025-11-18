# Connecting Your Squarespace Domain to AgriSynch

This guide will help you connect your Squarespace domain to your Flutter web app deployed on Firebase Hosting.

## Prerequisites

- ✅ Squarespace account with a registered domain
- ✅ Firebase project set up (agrisynch-a9350)
- ✅ Flutter web app built and ready to deploy

---

## Step 1: Build Your Flutter Web App

First, build your Flutter app for web deployment:

```powershell
# Navigate to your project directory
cd c:\Users\Reddi\AgriSynch\AgriSynch

# Build the web version
flutter build web --release

# This creates optimized files in the build/web directory
```

**Build Options** (optional):
```powershell
# Build with custom base href (if needed)
flutter build web --base-href /

# Build with web renderer (auto, canvaskit, or html)
flutter build web --web-renderer canvaskit
```

---

## Step 2: Set Up Firebase Hosting

### 2.1 Install Firebase CLI (if not already installed)

```powershell
# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login

# Verify you're logged in
firebase projects:list
```

### 2.2 Initialize Firebase Hosting

```powershell
# In your project directory
cd c:\Users\Reddi\AgriSynch\AgriSynch

# Initialize Firebase Hosting
firebase init hosting
```

**During initialization, select:**
- ✅ Use existing project: `agrisynch-a9350`
- ✅ Public directory: `build/web`
- ✅ Configure as single-page app: **Yes**
- ✅ Set up automatic builds: **No** (for now)
- ✅ Overwrite index.html: **No**

### 2.3 Update firebase.json

Add hosting configuration to your `firebase.json`:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=7200"
          }
        ]
      },
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=3600"
          }
        ]
      }
    ]
  },
  "flutter": {
    "platforms": {
      "android": {
        "default": {
          "projectId": "agrisynch-a9350",
          "appId": "1:823257894813:android:1f51c971c825b1ab17e974",
          "fileOutput": "android/app/google-services.json"
        }
      },
      "dart": {
        "lib/firebase_options.dart": {
          "projectId": "agrisynch-a9350",
          "configurations": {
            "android": "1:823257894813:android:1f51c971c825b1ab17e974",
            "web": "1:823257894813:web:b4d29b0b17428d7417e974"
          }
        }
      }
    }
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log"
      ],
      "predeploy": [
        "npm --prefix \"$RESOURCE_DIR\" run lint"
      ]
    }
  ]
}
```

### 2.4 Deploy to Firebase Hosting

```powershell
# Build and deploy in one command
flutter build web --release
firebase deploy --only hosting

# Or deploy everything
firebase deploy
```

After deployment, Firebase will give you a URL like:
- `https://agrisynch-a9350.web.app`
- `https://agrisynch-a9350.firebaseapp.com`

**Test this URL first** to make sure your app works!

---

## Step 3: Connect Your Squarespace Domain

### 3.1 Add Custom Domain in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `agrisynch-a9350`
3. Navigate to **Hosting** in the left sidebar
4. Click **Add custom domain**
5. Enter your Squarespace domain (e.g., `yourdomain.com`)
6. Click **Continue**

Firebase will show you DNS records to add. **Keep this page open!**

### 3.2 Configure DNS in Squarespace

#### Option A: Connect Root Domain (e.g., yourdomain.com)

1. Log in to your [Squarespace account](https://account.squarespace.com/)
2. Go to **Settings** → **Domains**
3. Click on your domain
4. Navigate to **DNS Settings**
5. Add the following records (provided by Firebase):

**A Records** (Firebase will give you these IPs):
```
Type: A
Host: @
Value: 151.101.1.195
TTL: 3600

Type: A
Host: @
Value: 151.101.65.195
TTL: 3600
```

**Note**: Firebase might give you different IPs. **Use the ones Firebase provides!**

#### Option B: Connect Subdomain (e.g., app.yourdomain.com)

If you want to use a subdomain like `app.yourdomain.com`:

1. In Firebase Hosting, add custom domain: `app.yourdomain.com`
2. In Squarespace DNS Settings, add:

```
Type: CNAME
Host: app
Value: agrisynch-a9350.web.app
TTL: 3600
```

### 3.3 Verify Domain Ownership

Firebase requires domain verification:

1. Firebase will provide a **TXT record** for verification
2. In Squarespace DNS Settings, add:

```
Type: TXT
Host: @  (or _firebase-hosting-challenge)
Value: [value provided by Firebase]
TTL: 3600
```

3. Click **Verify** in Firebase Console
4. Wait a few minutes for DNS to propagate

### 3.4 Complete SSL Setup

1. After verification, Firebase will automatically provision an SSL certificate
2. This can take up to 24 hours (usually much faster)
3. Your site will be accessible via HTTPS automatically

---

## Step 4: Update Squarespace Settings

### 4.1 Disable Squarespace Website (if needed)

If you want your domain to ONLY point to Firebase:

1. In Squarespace, go to **Settings** → **Domains**
2. Click your domain
3. Go to **Domain Settings**
4. Turn OFF "Use Squarespace nameservers" if you want full DNS control

**OR** keep Squarespace for email and just point a subdomain to Firebase.

### 4.2 Set Up Email Forwarding (Optional)

If you want to keep email@yourdomain.com working:

1. Keep Squarespace nameservers active
2. Use the CNAME method (subdomain) instead
3. Or use Google Workspace / another email provider

---

## Step 5: Configure CORS for Firebase (if needed)

If you're using Firebase Storage, configure CORS:

Create `cors.json`:
```json
[
  {
    "origin": ["https://yourdomain.com", "https://www.yourdomain.com"],
    "method": ["GET", "POST", "PUT", "DELETE"],
    "maxAgeSeconds": 3600
  }
]
```

Apply CORS settings:
```powershell
gsutil cors set cors.json gs://agrisynch-a9350.appspot.com
```

---

## Step 6: Test Your Setup

### 6.1 Check DNS Propagation

Use online tools to check if DNS is propagated:
- https://dnschecker.org
- https://www.whatsmydns.net

Enter your domain and check the records worldwide.

### 6.2 Test Your Domain

```powershell
# Test with curl
curl -I https://yourdomain.com

# Or open in browser
# https://yourdomain.com
```

### 6.3 Verify SSL Certificate

- Check for the padlock icon in browser
- Use https://www.ssllabs.com/ssltest/ to verify SSL setup
- Certificate should be issued by Google Trust Services

---

## Common DNS Configurations

### Configuration 1: Root Domain → Firebase
```
Type: A, Host: @, Value: [Firebase IP 1]
Type: A, Host: @, Value: [Firebase IP 2]
Type: TXT, Host: @, Value: [Firebase verification]
```

### Configuration 2: WWW → Firebase
```
Type: CNAME, Host: www, Value: agrisynch-a9350.web.app
Type: TXT, Host: @, Value: [Firebase verification]
```

### Configuration 3: Subdomain → Firebase
```
Type: CNAME, Host: app, Value: agrisynch-a9350.web.app
```

### Configuration 4: Both Root and WWW → Firebase
```
Type: A, Host: @, Value: [Firebase IP 1]
Type: A, Host: @, Value: [Firebase IP 2]
Type: CNAME, Host: www, Value: yourdomain.com
```

---

## Deployment Workflow

### Manual Deployment

```powershell
# 1. Build Flutter web app
flutter build web --release

# 2. Deploy to Firebase
firebase deploy --only hosting

# 3. Verify deployment
# Visit your domain in browser
```

### Automated Deployment Script

Create `deploy.ps1`:
```powershell
# Build and Deploy Script
Write-Host "Building Flutter Web App..." -ForegroundColor Green
flutter build web --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build successful! Deploying to Firebase..." -ForegroundColor Green
    firebase deploy --only hosting
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deployment successful!" -ForegroundColor Green
        Write-Host "Visit: https://yourdomain.com" -ForegroundColor Cyan
    } else {
        Write-Host "Deployment failed!" -ForegroundColor Red
    }
} else {
    Write-Host "Build failed!" -ForegroundColor Red
}
```

Run: `.\deploy.ps1`

---

## Troubleshooting

### Issue 1: Domain Not Resolving
**Problem**: Domain doesn't load after DNS setup

**Solutions**:
- ✅ Wait 24-48 hours for full DNS propagation
- ✅ Clear browser cache (Ctrl+Shift+Delete)
- ✅ Try incognito/private mode
- ✅ Flush DNS: `ipconfig /flushdns` (Windows)
- ✅ Check DNS with `nslookup yourdomain.com`
- ✅ Verify DNS records in Squarespace are correct

### Issue 2: SSL Certificate Not Working
**Problem**: Browser shows "Not Secure" warning

**Solutions**:
- ✅ Wait up to 24 hours for SSL provisioning
- ✅ Verify domain is connected in Firebase Console
- ✅ Check that you're using `https://` not `http://`
- ✅ Clear browser cache
- ✅ Force SSL renewal in Firebase Console

### Issue 3: 404 Errors on Refresh
**Problem**: Page not found when refreshing or direct URLs

**Solutions**:
- ✅ Ensure `firebase.json` has rewrite rules (see Step 2.3)
- ✅ Rebuild and redeploy: `flutter build web && firebase deploy`
- ✅ Check that single-page app is configured correctly

### Issue 4: Firebase Build Fails
**Problem**: `firebase deploy` errors

**Solutions**:
- ✅ Run `flutter clean` then `flutter build web --release`
- ✅ Verify `build/web` directory exists
- ✅ Check Firebase CLI is logged in: `firebase login`
- ✅ Verify project: `firebase use agrisynch-a9350`

### Issue 5: Images/Assets Not Loading
**Problem**: Resources show 404 errors

**Solutions**:
- ✅ Check assets are included in `pubspec.yaml`
- ✅ Use relative paths in code
- ✅ Rebuild: `flutter build web --release`
- ✅ Check browser console for errors
- ✅ Verify CORS settings if using Firebase Storage

### Issue 6: Slow Initial Load
**Problem**: App takes long to load first time

**Solutions**:
- ✅ Enable caching in `firebase.json` (see Step 2.3)
- ✅ Use `--web-renderer canvaskit` for better performance
- ✅ Optimize images and assets
- ✅ Enable PWA caching
- ✅ Use CDN for static assets

---

## Advanced Configuration

### Enable Redirects (www to non-www or vice versa)

In `firebase.json`:
```json
{
  "hosting": {
    "redirects": [
      {
        "source": "www.yourdomain.com",
        "destination": "https://yourdomain.com",
        "type": 301
      }
    ]
  }
}
```

### Add Security Headers

In `firebase.json`:
```json
{
  "hosting": {
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "X-Content-Type-Options",
            "value": "nosniff"
          },
          {
            "key": "X-Frame-Options",
            "value": "DENY"
          },
          {
            "key": "X-XSS-Protection",
            "value": "1; mode=block"
          }
        ]
      }
    ]
  }
}
```

### Set Up Preview Channels (Beta/Staging)

```powershell
# Create a preview channel
firebase hosting:channel:create beta

# Deploy to preview channel
firebase hosting:channel:deploy beta
```

### Monitor Performance

- Use Firebase Hosting analytics
- Set up Google Analytics for web traffic
- Monitor in Firebase Console → Hosting

---

## Checklist

Before going live, verify:

- [ ] Flutter app builds successfully (`flutter build web --release`)
- [ ] Firebase deployment works (`firebase deploy --only hosting`)
- [ ] Test Firebase default URL works
- [ ] DNS records added in Squarespace
- [ ] Domain verified in Firebase Console
- [ ] SSL certificate provisioned (can take up to 24 hours)
- [ ] Domain accessible via HTTPS
- [ ] All pages/routes work correctly
- [ ] Images and assets load properly
- [ ] Forms and authentication work
- [ ] Mobile responsive design works
- [ ] Browser console shows no errors
- [ ] Performance is acceptable

---

## Domain Configuration Examples

### Example 1: Direct Domain (yourdomain.com)
**Squarespace DNS:**
```
A     @    151.101.1.195    3600
A     @    151.101.65.195   3600
TXT   @    firebase-verification-token
```

**Firebase:** Add `yourdomain.com` as custom domain

**Result:** https://yourdomain.com → Firebase app

---

### Example 2: Subdomain (app.yourdomain.com)
**Squarespace DNS:**
```
CNAME app  agrisynch-a9350.web.app  3600
```

**Firebase:** Add `app.yourdomain.com` as custom domain

**Result:** https://app.yourdomain.com → Firebase app

---

### Example 3: Both Root and WWW
**Squarespace DNS:**
```
A     @    151.101.1.195    3600
A     @    151.101.65.195   3600
CNAME www  yourdomain.com    3600
TXT   @    firebase-verification-token
```

**Firebase:** 
1. Add `yourdomain.com` as custom domain
2. Add `www.yourdomain.com` as custom domain

**Result:** 
- https://yourdomain.com → Firebase app
- https://www.yourdomain.com → Firebase app

---

## Alternative: Using Cloudflare (Advanced)

If you want more control and better performance:

1. Transfer domain DNS to Cloudflare (free)
2. Point Cloudflare to Firebase
3. Benefits: Better caching, DDoS protection, analytics
4. Keep domain registered in Squarespace

---

## Support Resources

- **Firebase Hosting Docs**: https://firebase.google.com/docs/hosting
- **Squarespace DNS Help**: https://support.squarespace.com/hc/en-us/articles/205812378
- **Flutter Web Deployment**: https://docs.flutter.dev/deployment/web
- **Firebase Console**: https://console.firebase.google.com/project/agrisynch-a9350

---

## Quick Reference Commands

```powershell
# Build web app
flutter build web --release

# Deploy to Firebase
firebase deploy --only hosting

# Check Firebase project
firebase projects:list

# Login to Firebase
firebase login

# Check hosting status
firebase hosting:sites:list

# View deployment history
firebase hosting:releases:list
```

---

## Notes

- DNS changes can take 24-48 hours to fully propagate globally
- SSL certificates are automatically renewed by Firebase
- Firebase Hosting includes free SSL and CDN
- Your app will be served from servers closest to your users
- Firebase Hosting is included in the free Spark plan (with limits)

---

**Your Firebase Project**: `agrisynch-a9350`
**Default URLs**:
- https://agrisynch-a9350.web.app
- https://agrisynch-a9350.firebaseapp.com

Once configured, your Squarespace domain will point to your Firebase-hosted Flutter web app! 🚀

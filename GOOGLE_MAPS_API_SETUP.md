# 🔑 Google Maps API Setup Guide

## Why Do We Need This?

The interactive map location picker requires Google Maps API credentials to display maps and geocode addresses.

---

## ✅ Step-by-Step Setup

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click **"Select a project"** → **"New Project"**
3. Enter name: `AgriSynch Maps`
4. Click **"Create"**
5. Wait for project to be created (1-2 minutes)

### Step 2: Enable Required APIs

1. In Cloud Console, go to **"APIs & Services"** → **"Library"**
2. Search for **"Maps SDK for Android"** → Click → **"Enable"**
3. Search for **"Maps SDK for iOS"** → Click → **"Enable"**
4. Search for **"Maps JavaScript API"** → Click → **"Enable"** (for web)
5. Search for **"Geocoding API"** → Click → **"Enable"** (for address lookup)

### Step 3: Create API Key

1. Go to **"APIs & Services"** → **"Credentials"**
2. Click **"Create Credentials"** → **"API Key"**
3. Copy the API key (save it safely)
4. Click **"Edit API key"**
5. Under **"API restrictions"**:
   - Select **"Restrict key"**
   - Check:
     - ✅ Maps SDK for Android
     - ✅ Maps SDK for iOS
     - ✅ Maps JavaScript API
     - ✅ Geocoding API
6. Under **"Application restrictions"**:
   - Select **"Android apps"** and add your Android app signature
   - Select **"iOS apps"** and add your iOS bundle ID
   - Select **"HTTP referrers"** and add your web domain
7. Click **"Save"**

---

## 📱 Android Setup

### 1. Get Your App's SHA-1 Fingerprint

```bash
cd C:\Users\Reddi\AgriSynch\AgriSynch

# For debug key:
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android

# Look for: SHA1: XX:XX:XX:...
```

### 2. Add to Android Manifest

Edit: `android/app/src/main/AndroidManifest.xml`

Add inside `<application>` tag:
```xml
<application
  android:label="@string/app_name"
  android:icon="@mipmap/ic_launcher">
  
  <!-- Add this -->
  <meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE" />
  
  <activity>
    ...
  </activity>
</application>
```

Replace `YOUR_API_KEY_HERE` with your actual API key.

### 3. Update Android Gradle (if needed)

Check `android/app/build.gradle` has:
```gradle
android {
    compileSdkVersion 35  // Or higher
    
    defaultConfig {
        minSdkVersion 21
        ...
    }
}
```

---

## 🍎 iOS Setup

### 1. Add to Info.plist

Edit: `ios/Runner/Info.plist`

Add these keys:
```xml
<dict>
  <!-- Existing keys... -->
  
  <!-- Add these -->
  <key>io.flutter.embedded_views_preview</key>
  <true/>
  
  <key>GoogleMapsApiKey</key>
  <string>YOUR_API_KEY_HERE</string>
  
  <!-- Existing keys... -->
</dict>
```

Replace `YOUR_API_KEY_HERE` with your API key.

### 2. Update Podfile (if needed)

Edit: `ios/Podfile`

Ensure this exists:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

### 3. Run Pod Update

```bash
cd ios
pod update
cd ..
```

---

## 🌐 Web Setup

### 1. Add Script to HTML

Edit: `web/index.html`

In the `<head>` section, add:
```html
<head>
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  
  <!-- Add this -->
  <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE"></script>
  
  <!-- Rest of head... -->
</head>
```

Replace `YOUR_API_KEY_HERE` with your API key.

### 2. Update CORS Settings

In Google Cloud Console:
1. Go to **"APIs & Services"** → **"Credentials"**
2. Click your API key
3. Under **"HTTP referrers"**, add:
   - `localhost:8080`
   - `localhost:*`
   - Your deployed web domain (e.g., `yourdomain.com`)

---

## 🔒 Security Best Practices

### ❌ DON'T
- ❌ Commit API keys to Git/GitHub
- ❌ Share API keys publicly
- ❌ Use same key for development and production
- ❌ Unrestricted API keys

### ✅ DO
- ✅ Use API key restrictions (Android app signature, iOS bundle ID, web domain)
- ✅ Rotate keys regularly
- ✅ Use different keys per environment
- ✅ Monitor usage in Cloud Console
- ✅ Set up billing alerts

### For Production
1. Create separate API key for production
2. Restrict to your production domains/apps
3. Set up billing alerts in Google Cloud
4. Monitor API usage regularly

---

## 🧪 Testing the Setup

### Android Test
```bash
flutter run

# On device/emulator:
# 1. Go to signup form
# 2. Click "Pick on Map"
# 3. Map should display
# 4. Tap on map
# 5. Confirm location
```

### iOS Test
```bash
flutter run -d ios

# Same as Android:
# 1. Go to signup form
# 2. Click "Pick on Map"
# 3. Map should display
# 4. Tap on map
# 5. Confirm location
```

### Web Test
```bash
flutter run -d chrome

# Go to:
# http://localhost:8080
# Sign up → Pick on Map → Test
```

---

## ❌ Troubleshooting

### Map Shows "Could not load tile"
**Problem:** Invalid or missing API key
**Solution:** 
- Check API key is correct
- Verify Maps API is enabled
- Verify platform-specific restrictions

### "Maps SDK for Android not recognized"
**Problem:** AndroidManifest.xml not updated
**Solution:**
- Check meta-data tag is inside `<application>`
- API key is string value
- Rebuild with `flutter clean && flutter run`

### "GoogleMapsApiKey not found" (iOS)
**Problem:** Info.plist not updated
**Solution:**
- Check `GoogleMapsApiKey` is in correct plist file
- Runner/Info.plist (not other files)
- Rebuild pods: `cd ios && pod update`

### Blank Map or Gray Tiles
**Problem:** API key not loaded for web
**Solution:**
- Check script tag in web/index.html
- Script must load before Flutter app
- Clear browser cache and reload

### Permission Denied Error
**Problem:** App not whitelisted for API key
**Solution:**
- Add app to API key restrictions
- Android: Add SHA-1 fingerprint
- iOS: Add bundle ID
- Web: Add domain/localhost
- Wait 5 minutes for changes to propagate

### Tiles Load Slowly
**Problem:** Network speed or rate limiting
**Solution:**
- Check internet connection
- Verify Maps API quota not exceeded
- Check Cloud Console for usage

---

## 📊 Monitor API Usage

### In Google Cloud Console
1. Go to **"APIs & Services"** → **"Library"**
2. Click on **"Maps SDK for Android"** → **"Metrics"**
3. View:
   - Requests per minute
   - Errors
   - Latency
   - Quota usage

### Set Up Billing Alert
1. Go to **"Billing"**
2. Select your project
3. Go to **"Budgets and alerts"**
4. Create budget (recommended: $100/month)
5. Enable email alerts

---

## 💰 Pricing

### Free Tier
- **28,000** Maps loads/month (free)
- **100,000** Geocoding requests/month (free)
- Good for development and small apps

### Paid (if exceeded)
- Maps: $7 per 1,000 loads
- Geocoding: $5 per 1,000 requests

**For AgriSynch (startup):**
- Low usage in early days
- Should stay within free tier
- Monitor and set alerts just in case

---

## ✅ Verification Checklist

After setup, verify:

- [ ] API key created in Google Cloud
- [ ] Maps SDK for Android enabled
- [ ] Maps SDK for iOS enabled
- [ ] Maps JavaScript API enabled (web)
- [ ] Geocoding API enabled
- [ ] API key added to Android manifest
- [ ] API key added to iOS Info.plist
- [ ] Script tag added to web/index.html
- [ ] API key restricted to your apps/domains
- [ ] Can run `flutter run` without errors
- [ ] Map displays when "Pick on Map" clicked
- [ ] Can tap on map to select location
- [ ] Address lookup works
- [ ] Confirm location returns to signup

---

## 🎯 Quick Copy-Paste Checklist

### Your API Key
```
YOUR_API_KEY_HERE: [YOUR_KEY_GOES_HERE]
```

Save this somewhere safe (not in code!)

### Android Manifest Meta-data
```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="YOUR_API_KEY_HERE" />
```

### iOS Info.plist Entries
```xml
<key>io.flutter.embedded_views_preview</key>
<true/>

<key>GoogleMapsApiKey</key>
<string>YOUR_API_KEY_HERE</string>
```

### Web Script Tag
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE"></script>
```

---

## 📞 Support

If you have issues:

1. **Check console errors** (logcat, Xcode, browser console)
2. **Verify API key** is correct
3. **Check Cloud Console** for API status
4. **Review restrictions** are correct
5. **Check Flutter doctor** for SDK issues

---

## 🎉 Once Complete

After setup:
- ✅ Users can see interactive map
- ✅ Users can pinpoint location like delivery apps
- ✅ Address auto-populates
- ✅ Coordinates stored for distance calculations
- ✅ Location-based features enabled

You're ready to deploy! 🚀

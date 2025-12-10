# Location Feature for Weather

## Overview
AgriSynch now uses your device's GPS location to provide accurate, personalized weather data for your exact location.

## How It Works

### 1. **Automatic Location Detection**
- When you open the Weather page, the app automatically requests your location
- Uses device GPS for high accuracy
- No need to manually enter your city or region

### 2. **Permission Request**
The app will ask for location permission:

**On Web (Chrome/Edge/Firefox):**
- Browser shows a popup asking "Allow AgriSynch to access your location?"
- Click "Allow" to enable location-based weather

**On Android:**
- System dialog asks for location permission
- Choose "While using the app" or "Only this time"
- Permission is required for accurate weather data

**On iOS:**
- System dialog asks for location permission
- Choose "Allow While Using App" for best experience

### 3. **Location Display**
- Shows your actual city, region, and country (e.g., "Quezon City, Metro Manila, Philippines")
- Uses Open-Meteo's reverse geocoding to convert GPS coordinates to readable location names
- Displays "Using your current location" indicator at bottom of weather card

### 4. **Fallback System**
If reverse geocoding fails, the app intelligently falls back to:
1. **Region-based location**: Matches coordinates to known Philippine regions
   - "Metro Manila Area, Philippines"
   - "Cebu Area, Philippines"
   - "Davao Area, Philippines"
   - etc.
2. **Coordinate display**: Shows exact GPS coordinates if region can't be determined

## Features

### ✅ **High Accuracy**
- Uses `LocationAccuracy.high` for precise GPS positioning
- Weather data matches your exact location, not a generic city

### ✅ **Privacy First**
- Location is only requested when you visit the Weather page
- No location tracking or storage
- Permission can be revoked anytime in device settings

### ✅ **Clear Error Messages**
If location access fails, you'll see:
- Clear explanation of the issue
- Retry button to request permission again
- Guide on how to enable location in settings

### ✅ **Automatic Refresh**
- Weather data refreshes every 15 minutes
- Uses your current location each time (great for farmers moving between fields!)

## Troubleshooting

### Location Permission Denied
1. Tap the "Retry" button
2. When browser/system asks, click "Allow"
3. Refresh the page if needed

### Location Permission Permanently Denied
1. Go to your device Settings
2. Find AgriSynch app (or browser on web)
3. Enable Location permission
4. Return to app and tap "Retry"

### Location Services Disabled
1. Enable GPS in device settings
2. Return to app and tap "Retry"

## Technical Details

### APIs Used
- **Open-Meteo Weather API**: No API key needed, unlimited calls
- **Open-Meteo Geocoding API**: Reverse geocoding (coordinates → location name)
- **Geolocator Package**: Cross-platform location services (Android, iOS, Web)

### Permissions (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### Location Accuracy
- Timeout: 10 seconds
- Accuracy: High precision GPS
- Mode: Current position only (no tracking)

## Benefits for Farmers

1. **Field-Specific Weather**: Get weather for your exact farm location, not the nearest city
2. **Multiple Locations**: Moving between fields? Weather updates to your current location
3. **Remote Areas**: Works even in rural areas without city names
4. **Offline Mode**: If location fails, shows last known weather data
5. **Mobile Friendly**: Perfect for farmers checking weather while on their land

## Privacy & Security

- ✅ Location requested only when needed
- ✅ No location history stored
- ✅ No location data sent to our servers
- ✅ All location processing done on-device
- ✅ Open-source APIs (Open-Meteo) with no tracking
- ✅ User can deny permission and still use other app features

---

**Last Updated**: November 8, 2025
**Version**: 1.0 with GPS Location Support

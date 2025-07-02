# 🗺️ Google Maps Blank Tiles Fix Guide

## Problem
Google Maps showing blank/gray tiles instead of map data in Flutter app.

## Root Cause
API key configuration issue - the key works for web APIs but not for mobile SDKs.

## 🔧 Step-by-Step Solution

### 1. Go to Google Cloud Console
Visit: https://console.cloud.google.com/

### 2. Enable Required APIs
Navigate to **APIs & Services > Library** and enable:
- ✅ **Maps SDK for Android** (Critical!)
- ✅ **Maps SDK for iOS** (Critical!)
- ✅ **Maps JavaScript API** 
- ✅ **Geocoding API** (already working)
- ✅ **Maps Static API** (already working)

### 3. Configure API Key Restrictions
Navigate to **APIs & Services > Credentials** and edit your API key:

#### Application Restrictions:
**For Android apps:**
- Package name: `com.wordnerd.artbeat`
- SHA-1 certificate fingerprint: `FB:22:5F:D1:2D:48:71:E6:EE:58:52:3C:BC:A9:1B:A3:36:1E:F1:4B`

**For iOS apps:**
- Bundle ID: `com.wordnerd.artbeat`

#### API Restrictions:
Select "Restrict key" and check:
- Maps SDK for Android
- Maps SDK for iOS
- Maps JavaScript API
- Geocoding API
- Maps Static API

### 4. Verify Configuration
Your API key: `AIzaSyBvmSCvenoo9u-eXNzKm_oDJJJjC0MbqHA`

Configuration files updated:
- ✅ `android/key.properties` - Created with API key
- ✅ `ios/Runner/Info.plist` - Updated with consistent API key
- ✅ `.env` - Contains API key for ConfigService
- ✅ Added debugging to GoogleMapsService

### 5. Test the Fix
1. Save your API key settings in Google Cloud Console
2. Wait 5-10 minutes for changes to propagate
3. Rebuild and run the app:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### 6. Debugging
Check the console for these messages:
- `🔑 Google Maps API key found: AIzaSyAclolfPruwSH4o...`
- `🗺️ GoogleMap controller created successfully`
- `🗺️ Map tiles loading properly`

If you see warnings about tiles not loading, the API key restrictions are still not configured correctly.

### 7. Common Issues
- **API not enabled**: Make sure "Maps SDK for Android" and "Maps SDK for iOS" are enabled
- **Wrong SHA-1**: Make sure you add the exact SHA-1 fingerprint listed above
- **Bundle ID mismatch**: Ensure bundle ID matches exactly: `com.wordnerd.artbeat`
- **Propagation delay**: Google API changes can take 5-10 minutes to take effect

### 8. Verification
After the fix, you should see:
- Map tiles loading instead of gray squares
- Normal map interaction (zoom, pan, etc.)
- Markers showing on the map
- Location services working

## 🚨 Most Critical Steps
1. **Enable "Maps SDK for Android"** in Google Cloud Console
2. **Add the SHA-1 fingerprint** to your API key restrictions
3. **Wait 5-10 minutes** after making changes

The API key itself is valid (tested ✅), the issue is just the mobile SDK configuration!
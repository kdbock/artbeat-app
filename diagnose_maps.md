# Google Maps Troubleshooting Guide

## Issue: Blank/Gray tiles in Flutter Google Maps

### Root Cause Analysis
The API key is working for web APIs (Static Maps, Geocoding) but not for mobile SDKs.

### Required Google Cloud APIs
For Flutter Google Maps to work, you need these APIs enabled:

1. **Maps SDK for Android** - Required for Android apps
2. **Maps SDK for iOS** - Required for iOS apps  
3. **Maps JavaScript API** - Sometimes required
4. **Geocoding API** - For address/coordinate conversion
5. **Places API** - If using places features

### Current Configuration
- **Package Name (Android)**: `com.wordnerd.artbeat`
- **Bundle ID (iOS)**: `com.wordnerd.artbeat`
- **API Key**: `AIzaSyAclolfPruwSH4oQ-keOXkfTPQJT86-dPU`

### Steps to Fix

#### 1. Enable Required APIs
Go to [Google Cloud Console](https://console.cloud.google.com/):
1. Select your project
2. Go to "APIs & Services" > "Library"
3. Search for and enable:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Maps JavaScript API (if not already enabled)

#### 2. Check API Key Restrictions
Go to [Google Cloud Console](https://console.cloud.google.com/):
1. Go to "APIs & Services" > "Credentials"
2. Click on your API key
3. Under "Application restrictions":
   - For Android: Add package name `com.wordnerd.artbeat` with SHA-1 fingerprint
   - For iOS: Add bundle ID `com.wordnerd.artbeat`
4. Under "API restrictions":
   - Select "Restrict key"
   - Check: Maps SDK for Android, Maps SDK for iOS, Geocoding API

#### 3. Android SHA-1 Fingerprint (Required for API Key)
**Debug SHA-1**: `FB:22:5F:D1:2D:48:71:E6:EE:58:52:3C:BC:A9:1B:A3:36:1E:F1:4B`

**IMPORTANT**: This SHA-1 fingerprint MUST be added to your Google Maps API key restrictions for Android to work.

#### 4. Test Configuration
After making changes, wait 5-10 minutes for propagation, then test the app.

### Common Issues
- API key restrictions are too strict
- Missing SHA-1 fingerprint for Android
- Bundle ID mismatch
- APIs not enabled in Google Cloud Console
- Billing not enabled for the project

### Verification
The API key should work for:
- ✅ Static Maps API (verified working)
- ✅ Geocoding API (verified working)
- ❌ Maps SDK for Android (needs verification)
- ❌ Maps SDK for iOS (needs verification)
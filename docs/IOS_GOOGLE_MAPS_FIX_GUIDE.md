# iOS Google Maps Fix Guide

## Issues Identified
1. **API Key Mismatch**: AppDelegate.swift was using a different API key than Info.plist
2. **Firebase AppCheck Registration**: iOS app not properly registered with Firebase AppCheck
3. **Missing Maps API Restrictions**: API key may not be configured for iOS bundle ID

## Fixes Applied

### 1. ✅ Fixed API Key Mismatch
- **Problem**: AppDelegate.swift used `AIzaSyAWORLK8SxG6IKkaA5CaY2s3J2OIJ_36TA`
- **Solution**: Updated to match Info.plist key `AIzaSyDzH_pJ_I2U_rkC4OBKVasjjJMus3LtSH0`
- **File**: `/ios/Runner/AppDelegate.swift`

### 2. ✅ Enhanced Firebase AppCheck Configuration
- **Problem**: iOS debug mode causing AppCheck registration failures
- **Solution**: Added better debug mode handling and logging
- **File**: `/packages/artbeat_core/lib/src/firebase/secure_firebase_config.dart`

### 3. ✅ Added Maps Diagnostic Service
- **Created**: `MapsDiagnosticService` for debugging Maps issues
- **Features**: 
  - Platform detection
  - API key validation
  - Network connectivity testing
  - Comprehensive logging
- **File**: `/packages/artbeat_core/lib/src/services/maps_diagnostic_service.dart`

## Manual Steps Required

### Step 1: Verify Google Cloud Console Configuration
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select project `wordnerd-artbeat`
3. Navigate to **APIs & Services** → **Credentials**
4. Find API key: `AIzaSyDzH_pJ_I2U_rkC4OBKVasjjJMus3LtSH0`
5. Click **Edit** and verify:
   - **Application restrictions**: Set to "iOS apps"
   - **Bundle IDs**: Include `com.wordnerd.artbeat`
   - **API restrictions**: Include:
     - Maps SDK for iOS
     - Geocoding API
     - Places API (if using places)

### Step 2: Firebase Console Configuration
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select project `wordnerd-artbeat`
3. Go to **Project Settings** → **General**
4. Verify iOS app with bundle ID `com.wordnerd.artbeat` is registered
5. If not, click **Add app** → **iOS** and follow setup

### Step 3: Set Firebase AppCheck Debug Token (Development Only)
For iOS development, you may need to set a debug token:

1. In Firebase Console, go to **Project Settings** → **App Check**
2. Click on your iOS app
3. Click **Debug tokens** → **Add debug token**
4. Generate a token and add it to your `.env` file:
   ```
   FIREBASE_APP_CHECK_DEBUG_TOKEN=your_debug_token_here
   ```

### Step 4: Test with Diagnostic Service
Add this to any screen where Maps should work:

```dart
import 'package:artbeat_core/artbeat_core.dart';

// Add to initState or onPressed
await MapsDiagnosticService.logDiagnostics();
```

## Expected Behavior After Fix
- ✅ Maps UI loads properly
- ✅ Map tiles (roads, water, terrain) render correctly
- ✅ No Firebase AppCheck errors in logs
- ✅ No "Invalid API key" errors

## Debugging Commands
If issues persist, run these in terminal:

```bash
# Clean and rebuild iOS
cd ios && rm -rf Pods Podfile.lock && cd ..
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run

# Check logs for specific errors
flutter logs | grep -i "maps\|firebase\|appcheck"
```

## Common Error Messages and Solutions

### "Firebase: App Check debug token detected" 
- **Status**: ✅ Normal in development
- **Action**: No action needed

### "Invalid API key for bundle identifier" 
- **Status**: ❌ Needs fix
- **Action**: Complete Step 1 above

### "App not registered with AppCheck"
- **Status**: ❌ Needs fix  
- **Action**: Complete Step 2 and Step 3 above

### Maps loads but no tiles/roads visible
- **Status**: ❌ Usually API key restriction issue
- **Action**: Complete Step 1, ensure "Maps SDK for iOS" is enabled

## Verification Checklist
- [ ] AppDelegate.swift uses correct API key
- [ ] Google Cloud Console API key has iOS restrictions
- [ ] Firebase iOS app is registered
- [ ] Maps diagnostic service shows no errors
- [ ] Map tiles render on real iOS device

## Contact Info
If issues persist after following this guide:
1. Run `MapsDiagnosticService.logDiagnostics()`
2. Share the diagnostic output
3. Check Firebase and Google Cloud Console settings match this guide

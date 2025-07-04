# Firebase App Check & iOS Simulator Issues - Troubleshooting Guide

## 🚨 Critical Issues and Solutions

### 1. **Firebase App Check Authentication Failure (HTTP 403)**

**Issue**: 
```
AppCheck failed: 'App attestation failed.' - HTTP status code: 403
```

**Root Cause**: Debug token not configured in Firebase Console

**Solution**:
1. Run the debug token setup script:
   ```bash
   ./scripts/setup_debug_token.sh
   ```

2. **Manual Configuration**:
   - Go to [Firebase Console](https://console.firebase.google.com/project/wordnerd-artbeat/settings/appcheck)
   - Find your iOS app: `1:665020451634:ios:2aa5cc17ac7d0dad78652b`
   - Click "Manage debug tokens"
   - Add debug token: `04F9166E-D163-4827-A0C4-5B540F2FF618`
   - Save configuration

**Status**: ✅ **CRITICAL - Must fix to resolve 403 errors**

---

### 2. **Core Telephony XPC Connection Errors**

**Issue**:
```
The connection to service named com.apple.commcenter.coretelephony.xpc was invalidated
```

**Root Cause**: iOS Simulator limitation - doesn't have cellular capabilities

**Solution**: These errors are **harmless** and expected in the simulator. They don't affect app functionality.

**Status**: ⚠️ **INFORMATIONAL - Safe to ignore**

---

### 3. **Google Maps SDK Version Warning**

**Issue**:
```
New version of Google Maps SDK for iOS available: 10.0.0.0
Current version: 9.4.0.0
```

**Solution**: Update Google Maps dependency
```bash
cd ios/
pod update GoogleMaps
```

**Status**: 📋 **RECOMMENDED - Non-critical upgrade**

---

### 4. **Network Connection Issues**

**Issue**:
```
nw_connection_get_connected_socket_block_invoke [C8] Client called nw_connection_get_connected_socket on unconnected nw_connection
```

**Root Cause**: Simulator network stack differences from real devices

**Solution**: Test on physical device for accurate network behavior

**Status**: ⚠️ **SIMULATOR LIMITATION - Test on device**

---

### 5. **CoreData Warnings**

**Issue**:
```
CoreData: warning: no NSValueTransformer with class name 'GMSCachePropertyValueTransformer'
```

**Root Cause**: Google Maps SDK internal caching mechanism

**Solution**: These warnings are **harmless** and don't affect functionality

**Status**: ⚠️ **INFORMATIONAL - Safe to ignore**

---

## 🔧 **Immediate Action Items**

### Priority 1: **Fix App Check (Critical)**
```bash
# Run the setup script
./scripts/setup_debug_token.sh

# Follow the instructions to configure the debug token in Firebase Console
```

### Priority 2: **Verify Fix**
```bash
# Clean and rebuild
flutter clean
flutter pub get
cd ios/ && pod install && cd ..

# Run the app and check for 403 errors
flutter run
```

### Priority 3: **Optional Updates**
```bash
# Update Google Maps (optional)
cd ios/ && pod update GoogleMaps && cd ..
```

---

## 📱 **Testing on Physical Device**

For production-like testing, always test on a physical device:

```bash
# Build for physical device
flutter build ios --debug
```

Many simulator-specific issues (network, telephony, etc.) don't occur on real devices.

---

## 🔍 **Verification Steps**

After fixing the App Check configuration:

1. **Look for these success messages**:
   ```
   ✅ App Check initialization complete
   ✅ Firebase initialization completed successfully
   ```

2. **No more 403 errors**:
   ```
   # Should NOT see:
   AppCheck failed: 'App attestation failed.' - HTTP status code: 403
   ```

3. **Normal operation**:
   ```
   ✅ CaptureService.getAllCaptures() found X captures
   ✅ UserSyncHelper: User document already exists
   ```

---

## 📞 **Need Help?**

- **Firebase Console**: https://console.firebase.google.com/project/wordnerd-artbeat
- **App Check Documentation**: https://firebase.google.com/docs/app-check
- **Debug Token Guide**: https://firebase.google.com/docs/app-check/ios/debug-provider
# ArtBeat App Crash Analysis & Emergency Fixes

## 🚨 CRITICAL ISSUE SUMMARY

**Current Status**: 100% crash rate (0% crash-free users/sessions)  
**Affected Version**: 2.3.1 (Build 61)  
**Affected Users**: 66+ users  
**Root Cause**: Third-party library initialization failures in payment and authentication flows

---

## 📊 CRASH BREAKDOWN

### 1. **Stripe Payment Crashes (66 users affected)**

- **AddressElementActivity**: `IllegalArgumentException - Required value was null`
- **CvcRecollectionActivity**: `IllegalStateException - Cannot start CVC Recollection flow without args`
- **PollingActivity**: `IllegalArgumentException - Required value was null`
- **BacsMandateConfirmationActivity**: `IllegalStateException - Cannot start Bacs mandate confirmation flow without arguments`

**Root Cause**: Stripe activities launched without required intent extras/arguments

### 2. **Google Play Billing Crash (66 users affected)**

- **ProxyBillingActivity.onCreate**: `NullPointerException - Attempt to invoke virtual method 'android.app.IntentSender' on a null 'PendingIntent'`

**Root Cause**: PendingIntent is null - likely missing extras or initialization issue

### 3. **Google Sign-In Crash (55 users affected)**

- **SignInHubActivity.onCreate**: `NullPointerException - Attempt to invoke virtual method 'java.lang.Class' on a null object reference`

**Root Cause**: Object reference is null during activity creation

---

## 🔧 IMMEDIATE FIXES

### Fix #1: Add Stripe Activity Intent Guard

**File**: Need to create a new wrapper for Stripe calls

The issue is that Stripe activities are being started without proper initialization. We need to:

1. Ensure Stripe is properly initialized before use
2. Validate payment intent data before launching payment activities
3. Add try-catch around all Stripe payment operations

### Fix #2: Fix Google Play Billing Initialization

**Files to Modify**:

- `android/app/build.gradle.kts` - Update billing client version
- `lib/in_app_purchase_setup.dart` - Add proper initialization guards
- `packages/artbeat_core/lib/src/services/in_app_purchase_service.dart` - Add error handling

### Fix #3: Fix Google Sign-In Initialization

**Files to Modify**:

- `lib/main.dart` - Initialize GoogleSignIn with proper error handling
- Check all Firebase auth initialization

---

## 🛠️ DETAILED FIXES

### Fix #1: Stripe Payment Protection Service

Create a wrapper that validates Stripe setup before attempting payment operations:

**Create**: `/Users/kristybock/artbeat/packages/artbeat_core/lib/src/services/stripe_safety_service.dart`

This service will:

- Check if Stripe is properly initialized
- Validate payment intent before launching activities
- Catch and handle null reference errors
- Provide fallback error handling

### Fix #2: Update Android Build Configuration

**File**: `android/app/build.gradle.kts`

Issues to fix:

1. `com.android.billingclient:billing` version 7.1.1 has known issues - should use 7.0.0 or add compatibility fixes
2. Add proper manifest placeholders for all third-party activities
3. Ensure all activities have proper Android Manifest declarations

### Fix #3: Add Initialization Safeguards in main.dart

The initialization sequence needs to ensure:

1. Firebase is initialized FIRST (before any auth/payment services)
2. Stripe publishable key is loaded and validated
3. Google Sign-In is initialized with proper error handling
4. In-app purchase service has fallback handlers

---

## 📋 STEP-BY-STEP RESOLUTION PLAN

### Phase 1: Immediate Hotfix (This Release)

1. ✅ Create Stripe Safety Service with intent validation
2. ✅ Add initialization guards in main.dart
3. ✅ Update AndroidManifest.xml with proper activity declarations
4. ✅ Add fallback payment handling

### Phase 2: Dependency Updates (Next Release)

1. Review and update billing client version
2. Update Stripe SDK if needed
3. Update Google Play Services version
4. Test all payment flows

### Phase 3: Long-term Stability

1. Add comprehensive crash reporting
2. Implement payment flow testing in CI/CD
3. Add pre-launch checks for critical services

---

## 🔍 ROOT CAUSE ANALYSIS

### Why These Crashes Are Happening:

1. **Stripe Crashes**:

   - Stripe Payment Sheet activities expect specific intent extras that aren't being provided
   - Likely caused by Stripe SDK update (^11.1.0 or ^11.2.0) that changed initialization requirements
   - Activities launched in wrong sequence or without proper context

2. **Billing Crashes**:

   - Google Play Billing version 7.1.1 has known compatibility issues with certain Android versions
   - PendingIntent being created with insufficient permissions
   - Missing QUERY_ALL_PACKAGES permission or similar

3. **Sign-In Crashes**:
   - GoogleSignIn not properly initialized before use
   - Possible race condition where activity tries to use null GoogleSignInAccount
   - Missing proper lifecycle management

### Why This Happens on Launch:

The app initializes these services in the background (line 79 in main.dart):

```dart
_initializeNonCriticalServices();
```

The issue: These services ARE critical, but they're initialized in a delayed background task. If the user tries to access payment/auth before they finish initializing, crashes occur.

---

## 🚀 SPECIFIC CODE CHANGES NEEDED

### 1. Move In-App Purchase Initialization to Critical Path

**File**: `/Users/kristybock/artbeat/lib/main.dart`

Change line 207-217 from background initialization to critical path, OR ensure it completes before allowing payment flows.

### 2. Add Stripe Validation Before Payment

Ensure any payment flow checks:

```dart
if (!StripePaymentService.isInitialized) {
  throw Exception("Payment service not ready. Please try again.");
}
```

### 3. Update Android Manifest

Ensure all third-party activities are declared:

```xml
<!-- Stripe Payment Activities -->
<!-- Google Play Billing Activities -->
<!-- Google Sign-In Activities -->
```

### 4. Add Error Recovery

Implement automatic retry logic for failed initializations with exponential backoff.

---

## 📱 TESTING CHECKLIST AFTER FIXES

- [ ] App launches without crashes on first install
- [ ] App launches without crashes on warm start
- [ ] Payment sheet opens and closes without crashes
- [ ] Google Sign-In works without crashes
- [ ] In-app purchases complete successfully
- [ ] Handle network disconnection gracefully
- [ ] Test on Android 7.0 (minSdk 24) through Android 14+
- [ ] Test with airplane mode enabled
- [ ] Test killing app mid-payment and recovering

---

## 🎯 PRIORITY ORDER FOR FIXES

1. **CRITICAL** - Create Stripe Safety Service (prevents 66 crashes)
2. **CRITICAL** - Move IAP initialization to critical path
3. **HIGH** - Update Android Manifest with proper activity declarations
4. **HIGH** - Add GoogleSignIn initialization guard
5. **MEDIUM** - Consider updating billing client version
6. **MEDIUM** - Add comprehensive logging for debugging

---

## 📞 NEXT STEPS

1. Review this analysis with team
2. Implement fixes in priority order
3. Build test version for internal testing
4. Test on physical devices across Android versions
5. Prepare rollout with gradual rollout to catch any new issues
6. Monitor crash reports closely after deployment

---

## 📚 REFERENCE DOCUMENTS

- Stripe Flutter Documentation: https://github.com/stripe-archive/stripe-sdk-android
- Google Play Billing Issues: https://issuetracker.google.com/issues?q=componentid:179261
- Firebase Auth Known Issues: https://firebase.google.com/support/troubleshooting/auth-issues

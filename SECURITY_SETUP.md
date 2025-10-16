# 🔒 ArtBeat Security Setup Guide

## Phase 1: Security Fixes - COMPLETED ✅

This guide documents the security improvements implemented for production readiness.

---

## 🎯 What Was Fixed

### 1. Firebase Storage Rules ✅

**Status:** PRODUCTION READY

**Changes Made:**

- ✅ Set `isDebugMode()` to `false` - App Check now enforced
- ✅ Removed all public read access (now requires authentication)
- ✅ Added file size validation:
  - Images: 10MB limit
  - Videos: 100MB limit
  - Audio: 50MB limit
- ✅ Added file type validation (only allow image/_, video/_, audio/\*)
- ✅ Removed debug upload paths
- ✅ Enforced user-specific access controls (users can only upload to their own folders)

**Impact:**

- All storage operations now require authentication
- App Check is enforced (prevents unauthorized API access)
- File uploads are validated for size and type
- Users can only access their own files (except admins)

### 2. Firestore Rules ✅

**Status:** PRODUCTION READY

**Current Configuration:**

- ✅ Public read access maintained for: artists, events, artwork (for discovery features)
- ✅ All write operations require authentication
- ✅ User-specific data properly secured
- ✅ Admin access controls in place

### 3. API Keys & Secrets ✅

**Status:** SECURED

**Configuration:**

- ✅ `key.properties` - properly gitignored (not tracked in git)
- ✅ `.env` files - properly gitignored (not tracked in git)
- ✅ Environment-based configuration ready
- ✅ Example files provided for reference

**Files:**

- `.env.example` - Template for all environments
- `.env.production.example` - Production-specific template
- `.env.local.example` - Local development template

### 4. Android Build Configuration ✅

**Status:** CONFIGURED FOR PRODUCTION

**Changes Made:**

- ✅ Release builds now REQUIRE proper keystore (no debug fallback)
- ✅ Added debug build variant with `.debug` suffix
- ✅ ProGuard rules configured for Stripe SDK
- ⚠️ Minification disabled temporarily (needs testing with Stripe)

---

## 📋 Production Deployment Checklist

### Before First Production Build:

#### 1. Create Release Keystore (Android)

```bash
# Generate a new keystore for production
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# Move it to a secure location (NOT in the project directory)
mv upload-keystore.jks ~/secure-keys/artbeat/
```

#### 2. Configure key.properties (Android)

Create or update `/android/key.properties`:

```properties
storeFile=/Users/YOUR_USERNAME/secure-keys/artbeat/upload-keystore.jks
storePassword=YOUR_SECURE_PASSWORD
keyAlias=upload
keyPassword=YOUR_SECURE_PASSWORD
mapsApiKey=YOUR_GOOGLE_MAPS_API_KEY
```

**⚠️ IMPORTANT:**

- Store keystore file OUTSIDE the project directory
- Use absolute path in `storeFile`
- Never commit this file to git (already in .gitignore)
- Back up your keystore securely - you cannot recover it if lost!

#### 3. Configure iOS Signing

- Open Xcode project: `ios/Runner.xcworkspace`
- Select Runner target → Signing & Capabilities
- Set your Team and Bundle Identifier
- Configure Release signing with Distribution certificate

#### 4. Set Up Environment Variables

**For Local Development:**
Copy `.env.example` to `.env` and fill in your keys:

```bash
cp .env.example .env
# Edit .env with your actual API keys
```

**For CI/CD (GitHub Actions, etc.):**
Add these secrets to your CI/CD platform:

- `FIREBASE_ANDROID_API_KEY`
- `FIREBASE_IOS_API_KEY`
- `GOOGLE_MAPS_API_KEY`
- `STRIPE_PUBLISHABLE_KEY`
- `ANDROID_KEYSTORE_BASE64` (base64-encoded keystore file)
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

#### 5. Firebase App Check Setup

**Enable App Check in Firebase Console:**

1. Go to Firebase Console → Build → App Check
2. Register your app for App Check
3. For iOS: Enable DeviceCheck or App Attest
4. For Android: Enable Play Integrity API
5. For development: Register debug tokens

**Get Debug Token (Development Only):**

```bash
# Run the app in debug mode
flutter run

# Check logs for App Check debug token
# Add it to Firebase Console → App Check → Debug tokens
```

**Production:**

- Debug tokens are automatically disabled (isDebugMode = false)
- Only properly signed apps can access Firebase services

#### 6. Test ProGuard Configuration

Before enabling minification:

```bash
# Build release APK
flutter build apk --release

# Test all features, especially:
# - Stripe payments
# - Firebase operations
# - Image uploads
# - All third-party SDK integrations

# If everything works, enable minification in build.gradle.kts:
# isMinifyEnabled = true
# isShrinkResources = true
```

---

## 🔐 Security Best Practices

### API Key Management

**DO:**

- ✅ Use environment variables for all API keys
- ✅ Store keystores outside project directory
- ✅ Use different keys for dev/staging/production
- ✅ Rotate keys regularly (every 90 days recommended)
- ✅ Back up keystores securely (encrypted cloud storage)

**DON'T:**

- ❌ Commit API keys to git
- ❌ Share keystores via email or chat
- ❌ Use production keys in development
- ❌ Store keystores in project directory
- ❌ Reuse passwords across environments

### Firebase Security

**Storage Rules:**

- All uploads require authentication
- Users can only access their own files
- File size and type validation enforced
- App Check prevents unauthorized API access

**Firestore Rules:**

- Public read for discovery features (artists, events, artwork)
- All writes require authentication
- User data properly isolated
- Admin controls in place

### App Check

**What it does:**

- Prevents unauthorized API access
- Blocks requests from modified apps
- Protects against abuse and fraud
- Required for all production Firebase operations

**How to use:**

- Development: Register debug tokens in Firebase Console
- Production: Automatically enforced (isDebugMode = false)

---

## 🚨 Emergency Procedures

### If API Key is Compromised:

1. **Immediately rotate the key:**

   - Firebase: Generate new key in Firebase Console
   - Google Maps: Restrict or regenerate in Google Cloud Console
   - Stripe: Rotate keys in Stripe Dashboard

2. **Update all environments:**

   - Update `.env` files
   - Update CI/CD secrets
   - Redeploy all services

3. **Review access logs:**
   - Check Firebase Analytics for unusual activity
   - Review Stripe transaction logs
   - Check Google Maps API usage

### If Keystore is Lost:

**Android:**

- ⚠️ You CANNOT recover a lost keystore
- You will need to publish as a new app
- Users will need to uninstall and reinstall
- **Prevention:** Back up keystores securely NOW!

**iOS:**

- Certificates can be regenerated
- But you'll need to update provisioning profiles
- **Prevention:** Back up certificates and profiles

---

## 📊 Monitoring & Alerts

### Set Up Monitoring:

1. **Firebase Crashlytics:**

   - Already configured ✅
   - Monitor crash-free users
   - Set up alerts for crash spikes

2. **Firebase Performance:**

   - Already configured ✅
   - Monitor app startup time
   - Track network request performance

3. **Firebase Analytics:**

   - Already configured ✅
   - Track user engagement
   - Monitor feature usage

4. **App Check Metrics:**
   - Monitor App Check failures
   - Alert on suspicious activity
   - Review blocked requests

### Recommended Alerts:

- Crash rate > 1%
- App Check failure rate > 5%
- Unusual API usage spikes
- Failed authentication attempts
- Storage quota warnings

---

## 🔄 Regular Maintenance

### Weekly:

- Review Firebase Analytics for anomalies
- Check crash reports
- Monitor API usage

### Monthly:

- Review and update dependencies
- Check for security advisories
- Test backup/restore procedures

### Quarterly:

- Rotate API keys
- Review and update security rules
- Audit user permissions
- Test disaster recovery procedures

### Annually:

- Full security audit
- Penetration testing
- Update certificates and provisioning profiles
- Review and update privacy policy

---

## 📞 Support & Resources

### Documentation:

- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [Firebase App Check](https://firebase.google.com/docs/app-check)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [iOS Code Signing](https://developer.apple.com/support/code-signing/)

### Tools:

- [Firebase Console](https://console.firebase.google.com)
- [Google Cloud Console](https://console.cloud.google.com)
- [Stripe Dashboard](https://dashboard.stripe.com)

---

## ✅ Phase 1 Completion Status

- ✅ Firebase Storage Rules - SECURED
- ✅ Firestore Rules - REVIEWED & SECURED
- ✅ API Keys - PROPERLY MANAGED
- ✅ Build Configuration - PRODUCTION READY
- ✅ Documentation - COMPLETE

**Next Steps:** Proceed to Phase 2 (Build & Deploy) when ready for production deployment.

---

_Last Updated: Phase 1 Security Fixes - Completed_
_Document Version: 1.0_

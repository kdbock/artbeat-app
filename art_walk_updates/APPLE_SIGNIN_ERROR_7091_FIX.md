# Apple Sign-In Error -7091 Troubleshooting Guide

## Error Description

Error code `-7091` from Apple's AuthenticationServices framework indicates a configuration mismatch between your app and Apple Developer Console settings.

## Root Cause

This error typically occurs when:

1. **Apple Service ID mismatch**: The Service ID configured in Firebase doesn't match Apple Developer Console
2. **Bundle ID mismatch**: App bundle ID doesn't match the bundle ID configured for Apple Sign-In
3. **Missing Apple Sign-In capability**: App ID doesn't have Apple Sign-In capability enabled
4. **Domain verification incomplete**: Required domain verification not completed

## Step-by-Step Fix

### 1. Verify Apple Developer Console Configuration

#### Check App ID Configuration:

1. Go to [Apple Developer Console](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles** > **Identifiers**
3. Find your App ID: `com.wordnerd.artbeat`
4. Ensure **Sign In with Apple** capability is **ENABLED** ✅

#### Check Services ID Configuration:

1. In Apple Developer Console, go to **Identifiers**
2. Filter by **Services IDs**
3. Find or create Service ID: `com.wordnerd.artbeat`
4. Enable **Sign In with Apple**
5. Click **Configure** next to Sign In with Apple
6. Set **Primary App ID**: `com.wordnerd.artbeat`
7. Add **Website URLs**:
   - **Domains**: `wordnerd-artbeat.firebaseapp.com`
   - **Return URLs**: `https://wordnerd-artbeat.firebaseapp.com/__/auth/handler`

### 2. Complete Domain Verification

This is the step most commonly missed:

1. In Service ID configuration, click **Add Domain**
2. Enter: `wordnerd-artbeat.firebaseapp.com`
3. Click **Download** to get verification file
4. **Important**: Since this is a Firebase domain, you need to:
   - Go to Firebase Console > Hosting
   - Upload the verification file to your hosting
   - OR contact Firebase support for domain verification assistance

### 3. Verify Firebase Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: `wordnerd-artbeat`
3. Navigate to **Authentication** > **Sign-in method**
4. Enable **Apple** provider
5. Enter configuration:
   - **Services ID**: `com.wordnerd.artbeat`
   - **Apple Team ID**: `H49R32NPY6`
   - **Key ID**: `5G5237Z826`
   - **Private Key**: Upload your .p8 file content

### 4. Verify App Bundle Configuration

Ensure your app's bundle ID matches everywhere:

**iOS Info.plist should show:**

```xml
<key>CFBundleIdentifier</key>
<string>com.wordnerd.artbeat</string>
```

**Xcode project settings:**

- Bundle Identifier: `com.wordnerd.artbeat`

### 5. Test Configuration

Run the debug script:

```bash
./debug_apple_signin.sh
```

Use the test screen in your app to validate configuration before attempting sign-in.

## Alternative Workaround

If domain verification is problematic with Firebase hosting, consider:

1. **Use App-Only Flow**: Remove web authentication options and use only native iOS flow
2. **Different Service ID**: Create a different Service ID specifically for native app use
3. **Custom Domain**: Use a custom domain you control for easier verification

## Update Implementation

If using app-only flow, update the sign-in code:

```dart
appleCredential = await SignInWithApple.getAppleIDCredential(
  scopes: [
    AppleIDAuthorizationScopes.email,
    AppleIDAuthorizationScopes.fullName,
  ],
  nonce: nonce,
  // Remove webAuthenticationOptions for app-only flow
);
```

## Verification Checklist

- [ ] App ID has Apple Sign-In capability enabled
- [ ] Service ID exists and is configured
- [ ] Service ID has correct bundle ID as Primary App ID
- [ ] Domain `wordnerd-artbeat.firebaseapp.com` is added and verified
- [ ] Return URL `https://wordnerd-artbeat.firebaseapp.com/__/auth/handler` is added
- [ ] Firebase has Apple provider enabled with correct credentials
- [ ] App bundle ID matches Apple Developer Console configuration
- [ ] Testing on physical iOS device (not simulator)
- [ ] Device is signed into iCloud

## Common Mistakes

1. **Forgetting domain verification** - Most common cause of -7091
2. **Using wrong Service ID** - Must match Firebase configuration exactly
3. **Missing return URL** - Firebase auth handler URL must be added
4. **Testing in simulator** - Apple Sign-In requires physical device
5. **Bundle ID mismatch** - All configurations must use same bundle ID

## Need Help?

If error persists after following this guide:

1. Double-check each step above
2. Wait 10-15 minutes after making Apple Developer Console changes
3. Try app-only flow as workaround
4. Contact Apple Developer Support for domain verification issues

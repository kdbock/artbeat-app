# Apple Sign-In Configuration Checklist

This document provides a step-by-step guide to properly configure Apple Sign-In for the ARTbeat app.

## Current Configuration Values

- **Apple Team ID**: `H49R32NPY6`
- **Apple Key ID**: `5G5237Z826`
- **Apple Services ID**: `com.wordnerd.artbeat`
- **Bundle ID**: `com.wordnerd.artbeat`
- **Firebase Project**: `wordnerd-artbeat`
- **OAuth Callback URL**: `https://wordnerd-artbeat.firebaseapp.com/__/auth/handler`

## Apple Developer Console Configuration

### 1. App ID Configuration

✅ **Status**: Configured in iOS entitlements

- [ ] Verify App ID `com.wordnerd.artbeat` exists in Apple Developer Console
- [ ] Ensure "Sign In with Apple" capability is enabled for the App ID
- [ ] Verify the Bundle ID matches exactly: `com.wordnerd.artbeat`

### 2. Services ID Configuration

❗ **Action Required**: Verify this configuration

- [ ] Create/verify Services ID: `com.wordnerd.artbeat`
- [ ] Enable "Sign In with Apple" for the Services ID
- [ ] Configure Web Authentication:
  - Primary App ID: `com.wordnerd.artbeat`
  - Website URLs: `https://wordnerd-artbeat.firebaseapp.com`
  - Return URLs: `https://wordnerd-artbeat.firebaseapp.com/__/auth/handler`

### 3. Key Configuration

❗ **Action Required**: Verify key is properly configured

- [ ] Verify Key ID `5G5237Z826` exists and is active
- [ ] Ensure the key has "Sign In with Apple" service enabled
- [ ] Verify the private key matches what's uploaded to Firebase

### 4. Domain Verification

❗ **Critical**: This step is often missed

- [ ] In Services ID configuration, click "Configure" next to "Sign In with Apple"
- [ ] Add domain: `wordnerd-artbeat.firebaseapp.com`
- [ ] Download the verification file and upload it to your domain
- [ ] Complete domain verification process

## Firebase Console Configuration

### 1. Authentication Provider Setup

❗ **Action Required**: Configure Apple provider in Firebase

- [ ] Go to Firebase Console > Authentication > Sign-in method
- [ ] Enable Apple provider
- [ ] Add the following configuration:
  - **Services ID**: `com.wordnerd.artbeat`
  - **Apple Team ID**: `H49R32NPY6`
  - **Key ID**: `5G5237Z826`
  - **Private key**: Upload the private key from Apple Developer Console

### 2. OAuth Redirect Domain

✅ **Status**: Should be automatically configured

- [ ] Verify `wordnerd-artbeat.firebaseapp.com` is in Authorized domains
- [ ] Ensure no extra domains are causing conflicts

## iOS App Configuration

### 1. Entitlements

✅ **Status**: Properly configured

- Entitlements file includes Apple Sign-In capability
- Bundle ID matches Apple configuration

### 2. Info.plist

✅ **Status**: Properly configured

- URL schemes configured for OAuth callback

## Web Configuration (for testing)

### 1. Firebase Hosting

- [ ] Ensure Firebase Hosting is enabled for your project
- [ ] Verify the domain `wordnerd-artbeat.firebaseapp.com` is accessible

## Debugging Steps

### 1. Test Apple Sign-In Availability

```dart
final isAvailable = await SignInWithApple.isAvailable();
print('Apple Sign-In available: $isAvailable');
```

### 2. Check Network Connectivity

- [ ] Ensure device has internet connection
- [ ] Try Apple Sign-In on different networks (WiFi vs cellular)

### 3. Verify Token Generation

- [ ] Check app logs for nonce generation
- [ ] Verify identity token is received from Apple
- [ ] Check token length and format

### 4. Firebase Authentication

- [ ] Monitor Firebase Authentication logs in console
- [ ] Check for any domain or configuration errors

## Common Issues and Solutions

### Issue: "Invalid OAuth response from apple.com"

**Likely Causes:**

1. Services ID not properly configured in Firebase
2. Domain verification not completed
3. Private key mismatch between Apple and Firebase
4. OAuth callback URL misconfiguration

**Solutions:**

1. Re-verify all configuration values match between Apple and Firebase
2. Complete domain verification in Apple Developer Console
3. Re-upload private key to Firebase
4. Ensure callback URL is exactly: `https://wordnerd-artbeat.firebaseapp.com/__/auth/handler`

### Issue: "Apple Sign-In not available"

**Likely Causes:**

1. Device doesn't support Apple Sign-In (iOS < 13)
2. Region restrictions
3. Missing entitlements

**Solutions:**

1. Test on iOS 13+ device
2. Verify entitlements are properly configured
3. Check device Apple ID settings

## Next Steps

1. **Immediate**: Verify Firebase Console Apple provider configuration
2. **Critical**: Complete Apple Developer Console domain verification
3. **Testing**: Test on physical iOS device (Apple Sign-In doesn't work in simulator)
4. **Monitoring**: Enable detailed logging to track authentication flow

## Support Resources

- [Firebase Apple Sign-In Documentation](https://firebase.google.com/docs/auth/ios/apple)
- [Apple Sign-In Developer Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Firebase Console](https://console.firebase.google.com/)
- [Apple Developer Console](https://developer.apple.com/account/)

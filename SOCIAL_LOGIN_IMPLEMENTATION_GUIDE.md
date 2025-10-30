# Social Login Implementation Guide

## Overview

This guide provides step-by-step instructions for implementing Google Sign-In and Apple Sign-In in the ArtBeat Flutter app.

## Current Status

- ✅ Firebase Auth integration ready
- ✅ GoogleService-Info.plist configured for iOS
- ✅ **Social login dependencies added** (`google_sign_in`, `sign_in_with_apple`, `crypto`)
- ✅ **AuthService social login methods implemented** (`signInWithGoogle()`, `signInWithApple()`)
- ✅ **UI buttons added to LoginScreen** (Google Sign-In + Apple Sign-In buttons)

## Integration Test Status

Created comprehensive readiness test suite in `test/social_login_readiness_test.dart`:

- **12 tests** covering infrastructure readiness, UI integration, and implementation validation
- **Current Status**: ✅ All 12 tests passing - social login UI and backend implemented
- **Purpose**: Validate complete social login implementation including dependencies, AuthService methods, and UI integration

---

## Step 1: Add Dependencies

Add the following dependencies to `pubspec.yaml`:

```yaml
dependencies:
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^6.1.2
```

Run: `flutter pub get`

---

## Step 2: Extend AuthService

Add social login methods to `packages/artbeat_auth/lib/src/services/auth_service.dart`:

```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  // ... existing code ...

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      AppLogger.info('🔄 Starting Google Sign-In process');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled by user');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      AppLogger.auth('✅ Google Sign-In successful: ${userCredential.user?.uid}');

      // Create user document if this is first sign-in
      await _createSocialUserDocument(userCredential.user!);

      return userCredential;
    } catch (e) {
      AppLogger.error('❌ Google Sign-In failed: $e');
      rethrow;
    }
  }

  /// Sign in with Apple
  Future<UserCredential> signInWithApple() async {
    try {
      AppLogger.info('🔄 Starting Apple Sign-In process');

      // Generate a random nonce
      final rawNonce = _generateNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create an OAuth credential from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Sign in to Firebase with the Apple credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      AppLogger.auth('✅ Apple Sign-In successful: ${userCredential.user?.uid}');

      // Create user document if this is first sign-in
      await _createSocialUserDocument(userCredential.user!, appleCredential: appleCredential);

      return userCredential;
    } catch (e) {
      AppLogger.error('❌ Apple Sign-In failed: $e');
      rethrow;
    }
  }

  /// Create user document for social sign-in users
  Future<void> _createSocialUserDocument(
    User user, {
    AuthorizationCredentialAppleID? appleCredential,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Extract display name
        String displayName = user.displayName ?? '';
        if (displayName.isEmpty && appleCredential != null) {
          final firstName = appleCredential.givenName ?? '';
          final lastName = appleCredential.familyName ?? '';
          displayName = '$firstName $lastName'.trim();
        }
        if (displayName.isEmpty) {
          displayName = 'User'; // Fallback
        }

        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'fullName': displayName,
          'email': user.email ?? '',
          'zipCode': '', // Will be collected later
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userType': 'regular',
          'posts': <String>[],
          'followers': <String>[],
          'following': <String>[],
          'captures': <String>[],
          'followersCount': 0,
          'followingCount': 0,
          'postsCount': 0,
          'capturesCount': 0,
          'isVerified': false,
        }, SetOptions(merge: true));

        AppLogger.info('✅ Social user document created for ${user.uid}');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to create social user document: $e');
      // Don't rethrow - continue with authentication even if Firestore fails
    }
  }

  /// Generate a cryptographically secure nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }
}
```

---

## Step 3: Update LoginScreen UI

Add social login buttons to `packages/artbeat_auth/lib/src/screens/login_screen.dart`:

Add this after the existing login form:

```dart
// Add these imports at the top
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;

// Add this method to _LoginScreenState class
Widget _buildSocialLoginButtons() {
  return Column(
    children: [
      const SizedBox(height: 24),

      // Divider with "OR" text
      const Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'OR',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider()),
        ],
      ),

      const SizedBox(height: 24),

      // Google Sign-In Button
      SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          key: const Key('google_sign_in_button'),
          onPressed: _handleGoogleSignIn,
          icon: Image.asset(
            'assets/icons/google_logo.png',
            height: 24,
            width: 24,
          ),
          label: const Text(
            'Continue with Google',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      const SizedBox(height: 16),

      // Apple Sign-In Button (iOS only)
      if (Platform.isIOS)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            key: const Key('apple_sign_in_button'),
            onPressed: _handleAppleSignIn,
            icon: const Icon(
              Icons.apple,
              color: Colors.black,
              size: 24,
            ),
            label: const Text(
              'Continue with Apple',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
    ],
  );
}

// Add these handler methods to _LoginScreenState class
Future<void> _handleGoogleSignIn() async {
  try {
    setState(() => _isLoading = true);

    final authService = widget.authService ?? AuthService();
    await authService.signInWithGoogle();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: ${e.toString()}')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

Future<void> _handleAppleSignIn() async {
  try {
    setState(() => _isLoading = true);

    final authService = widget.authService ?? AuthService();
    await authService.signInWithApple();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple Sign-In failed: ${e.toString()}')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

Then add `_buildSocialLoginButtons()` to your build method after the login form.

---

## Step 4: Platform Configuration

### iOS Configuration

1. **Add URL Scheme** to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

2. **Add Apple Sign-In capability** in Xcode:
   - Open `ios/Runner.xcworkspace`
   - Select Runner target
   - Go to Signing & Capabilities
   - Add "Sign In with Apple" capability

### Android Configuration

1. **Add SHA-1 fingerprints** to Firebase Console:

   - Get debug SHA-1: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
   - Get release SHA-1 from your release keystore
   - Add both to Firebase project settings

2. **Update `android/app/build.gradle`**:

```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21  // Required for Google Sign-In
    }
}
```

---

## Step 5: Add Assets

Add Google logo to `assets/icons/google_logo.png` and update `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/icons/
```

---

## Step 6: Run Integration Tests

Run the social login integration tests:

```bash
flutter test test/social_login_integration_test.dart
```

**Expected Results:**

- **Before implementation**: All tests will fail (dependencies missing, UI elements missing)
- **After implementation**: All 16 tests should pass

---

## Step 7: Test Implementation

1. **Test Google Sign-In**:

   - Tap "Continue with Google" button
   - Complete Google authentication flow
   - Verify user document created in Firestore
   - Verify navigation to dashboard

2. **Test Apple Sign-In** (iOS only):

   - Tap "Continue with Apple" button
   - Complete Apple authentication flow
   - Verify user document created in Firestore
   - Verify navigation to dashboard

3. **Test Error Handling**:
   - Cancel authentication flows
   - Test with network issues
   - Verify error messages displayed

---

## Verification Checklist

After implementation, verify:

- [ ] Dependencies added and `flutter pub get` completed
- [ ] AuthService has `signInWithGoogle()` method
- [ ] AuthService has `signInWithApple()` method
- [ ] LoginScreen has Google Sign-In button (Key: `google_sign_in_button`)
- [ ] LoginScreen has Apple Sign-In button (Key: `apple_sign_in_button`)
- [ ] iOS URL schemes configured
- [ ] Android SHA-1 fingerprints configured
- [ ] Google logo asset added
- [ ] All 16 integration tests pass
- [ ] Manual testing successful for both platforms

---

## Integration Test Coverage

The `test/social_login_integration_test.dart` file provides comprehensive coverage:

1. **Prerequisites Check** (4 tests):

   - Google/Apple Sign-In dependencies availability
   - AuthService method existence

2. **UI Integration Tests** (4 tests):

   - Social login buttons presence and functionality

3. **Authentication Flow Tests** (3 tests):

   - Success flows and error handling

4. **Platform Configuration Tests** (2 tests):

   - iOS and Android configuration verification

5. **User Data Integration Tests** (2 tests):
   - Firestore user document creation

**Total: 16 tests** ensuring complete social login functionality.

---

## Next Steps

1. **Implement Step 1**: Add dependencies
2. **Implement Step 2**: Extend AuthService
3. **Implement Step 3**: Update LoginScreen UI
4. **Implement Step 4**: Configure platforms
5. **Implement Step 5**: Add assets
6. **Run tests**: Verify all integration tests pass
7. **Manual testing**: Test on both iOS and Android devices

Once implementation is complete, you'll have achieved **16/16 authentication features** (100% complete) with comprehensive test coverage.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// A test service to verify Firebase Authentication is working correctly
class TestAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static bool _isTestAccount(User? user) {
    return user != null && user.email == 'test@artbeatapp.com';
  }

  /// Attempt to sign in with test credentials to verify Firebase Auth configuration
  static Future<bool> verifyFirebaseAuthConnection() async {
    try {
      debugPrint('🔍 Testing Firebase Auth connection...');

      // Use a predefined test account (you should create one specifically for testing)
      const email = 'test@artbeatapp.com';
      const password = 'Test1234!';

      // Try signing in
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        debugPrint('✅ Firebase Auth connection test successful');
        // Only sign out if this is the test account and no one else is signed in
        if (_isTestAccount(_auth.currentUser)) {
          await _auth.signOut();
        }
        return true;
      }

      return false;
    } catch (e) {
      // This is expected if test account doesn't exist
      debugPrint('❌ Firebase Auth test failed: $e');
      return false;
    }
  }

  /// Create a test account if one doesn't exist
  static Future<bool> createTestAccountIfNeeded() async {
    try {
      const email = 'test@artbeatapp.com';
      const password = 'Test1234!';

      // Check if user exists by trying to sign in
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (credential.user != null) {
          // Only sign out if this is the test account
          if (_isTestAccount(_auth.currentUser)) {
            await _auth.signOut();
          }
          return true;
        }
      } catch (e) {
        // User doesn't exist, create one
        if (e is FirebaseAuthException &&
            (e.code == 'user-not-found' || e.code == 'invalid-credential')) {
          try {
            final credential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );

            if (credential.user != null) {
              // Only sign out if this is the test account
              if (_isTestAccount(_auth.currentUser)) {
                await _auth.signOut();
              }
              debugPrint('✅ Created test account successfully');
              return true;
            }
          } catch (createError) {
            debugPrint('❌ Failed to create test account: $createError');
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error in test account verification: $e');
      return false;
    }
  }
}

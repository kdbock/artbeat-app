import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';

/// Authentication service for handling user authentication
class AuthService {
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  
  /// Initialize Google Sign-In with proper error handling
  /// Late-init to prevent null reference crashes during app startup
  late final GoogleSignIn _googleSignIn;

  /// Constructor with optional dependencies for testing
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore}) {
    _auth = auth ?? FirebaseAuth.instance;
    _firestore = firestore ?? FirebaseFirestore.instance;
    _initializeGoogleSignIn();
  }

  /// For dependency injection in tests (deprecated - use constructor)
  @deprecated
  void setDependenciesForTesting(
    FirebaseAuth auth,
    FirebaseFirestore firestore,
  ) {
    _auth = auth;
    _firestore = firestore;
  }

  /// Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Get the current authenticated user (async)
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Register with email, password, and name
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String fullName, {
    required String zipCode, // Required parameter
  }) async {
    try {
      AppLogger.info('📝 Starting registration for email: $email');

      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      AppLogger.auth('✅ Authentication account created with UID: $uid');

      // Set display name
      await userCredential.user?.updateDisplayName(fullName);
      AppLogger.info('✅ Display name set to: $fullName');

      try {
        // Create user document in Firestore with zipCode
        await _firestore.collection('users').doc(uid).set({
          'id': uid,
          'fullName': fullName,
          'email': email,
          'zipCode': zipCode,
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

        AppLogger.info('✅ User document created in Firestore');
      } catch (firestoreError) {
        debugPrint(
          '❌ Failed to create user document in Firestore: $firestoreError',
        );
        // Continue to return the userCredential even if Firestore fails
        // The RegisterScreen will attempt to create the document as a fallback
      }

      return userCredential;
    } catch (e) {
      AppLogger.error('❌ Error in registerWithEmailAndPassword: $e');
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Listen to auth state changes
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Send email verification to current user
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        AppLogger.info('✅ Email verification sent to ${user.email}');
      } else if (user?.emailVerified == true) {
        AppLogger.info('ℹ️ Email already verified');
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      AppLogger.error('❌ Error sending email verification: $e');
      rethrow;
    }
  }

  /// Check if current user's email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Reload current user to get updated verification status
  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
      AppLogger.info('✅ User data reloaded');
    } catch (e) {
      AppLogger.error('❌ Error reloading user: $e');
      rethrow;
    }
  }

  /// Constructor with dependencies - ensures Google Sign-In is properly initialized
  void _initializeGoogleSignIn() {
    try {
      // Initialize with email scope to prevent SignInHubActivity crashes
      _googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
        ],
      );
      AppLogger.info('✅ Google Sign-In initialized with email and profile scopes');
    } catch (e) {
      AppLogger.error('⚠️ Error initializing Google Sign-In: $e');
      // Fall back to default initialization
      _googleSignIn = GoogleSignIn();
    }
  }

  /// Sign in with Google
  /// This method includes comprehensive error handling to prevent native crashes
  /// in SignInHubActivity when configuration is missing
  Future<UserCredential> signInWithGoogle() async {
    try {
      AppLogger.info('🔄 Starting Google Sign-In process');

      // Pre-validate that we can proceed with Google Sign-In
      try {
        // Check if user is already signed in
        final isSignedIn = await _googleSignIn.isSignedIn();
        if (isSignedIn) {
          // Sign out first to get fresh credentials
          await _googleSignIn.signOut();
          AppLogger.info('ℹ️ Previous Google Sign-In session cleared');
        }
      } catch (e) {
        AppLogger.warning('Could not check Google Sign-In status: $e');
      }

      // Trigger the authentication flow with error handling
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } catch (e) {
        AppLogger.error('Google Sign-In flow failed (SignInHubActivity crash possible): $e');
        
        // Check if this looks like a null object reference crash
        if (e.toString().contains('null') || e.toString().contains('Null')) {
          throw Exception(
            'Google Sign-In configuration error. Please ensure Google Services are properly configured in your app.',
          );
        }
        rethrow;
      }

      if (googleUser == null) {
        AppLogger.info('ℹ️ Google Sign-In was cancelled by user');
        throw Exception('Google Sign-In was cancelled by user');
      }

      AppLogger.info('✅ Google Sign-In successful for: ${googleUser.email}');

      // Obtain the auth details from the request
      GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        AppLogger.error('Failed to obtain Google authentication: $e');
        throw Exception('Failed to obtain Google authentication credentials');
      }

      // Validate we have required tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        AppLogger.error('Google authentication tokens are null');
        throw Exception('Invalid Google authentication tokens received');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithCredential(credential);
      } catch (e) {
        AppLogger.error('Firebase sign-in with Google credential failed: $e');
        throw Exception('Failed to sign in to Firebase with Google account');
      }

      AppLogger.auth(
        '✅ Google Sign-In and Firebase authentication successful: ${userCredential.user?.uid}',
      );

      // Create user document if this is first sign-in
      await _createSocialUserDocument(userCredential.user!);

      return userCredential;
    } catch (e) {
      AppLogger.error('❌ Google Sign-In failed: $e', error: e);
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
      final oauthCredential = OAuthProvider(
        "apple.com",
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      // Sign in to Firebase with the Apple credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      AppLogger.auth('✅ Apple Sign-In successful: ${userCredential.user?.uid}');

      // Create user document if this is first sign-in
      await _createSocialUserDocument(
        userCredential.user!,
        appleCredential: appleCredential,
      );

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
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}

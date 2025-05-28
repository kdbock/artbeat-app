import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat/services/user_service.dart';

/// Service to ensure authenticated users have corresponding Firestore profiles
class AuthProfileService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final UserService _userService = UserService();

  /// Check if the current authenticated user has a Firestore profile
  /// If not, create one with basic information
  static Future<bool> ensureUserProfileExists() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('🚫 No authenticated user found');
        return false;
      }

      debugPrint('👤 Checking profile for user: ${user.uid}');

      // Check if user document exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        debugPrint('✅ User profile exists in Firestore');
        return true;
      }

      // User is authenticated but no Firestore profile exists
      debugPrint(
          '⚠️ User authenticated but no Firestore profile found. Creating...');

      // Extract names from display name or email
      String firstName = '';
      String lastName = '';

      if (user.displayName != null && user.displayName!.isNotEmpty) {
        final nameParts = user.displayName!.split(' ');
        firstName = nameParts.isNotEmpty ? nameParts[0] : '';
        lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      } else {
        // Fallback: use email prefix as first name
        firstName = user.email?.split('@')[0] ?? 'User';
      }

      // Create user profile with available information
      await _userService.createNewUser(
        user,
        firstName,
        lastName,
        user.email ?? '',
        '', // Default empty zipCode - user can update later
      );

      debugPrint('✅ Created Firestore profile for existing authenticated user');
      return true;
    } catch (e) {
      debugPrint('❌ Error ensuring user profile exists: $e');
      return false;
    }
  }

  /// Enhanced login flow that ensures profile creation
  static Future<UserCredential?> signInAndEnsureProfile(
      String email, String password) async {
    try {
      // Sign in the user
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        debugPrint('✅ User signed in: ${credential.user!.uid}');

        // Ensure the user has a Firestore profile
        await ensureUserProfileExists();
      }

      return credential;
    } catch (e) {
      debugPrint('❌ Error in enhanced sign in: $e');
      rethrow;
    }
  }

  /// Enhanced registration flow
  static Future<UserCredential?> registerAndCreateProfile({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String zipCode,
  }) async {
    try {
      // Create the user account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        final displayName = '$firstName $lastName'.trim();
        if (displayName.isNotEmpty) {
          await credential.user!.updateDisplayName(displayName);
        }

        // Create Firestore profile
        await _userService.createNewUser(
          credential.user!,
          firstName,
          lastName,
          email,
          zipCode,
        );

        debugPrint('✅ Registration complete with Firestore profile');
      }

      return credential;
    } catch (e) {
      debugPrint('❌ Error in enhanced registration: $e');
      rethrow;
    }
  }

  /// Check and fix any authenticated users missing Firestore profiles
  /// This can be called on app startup
  static Future<void> migrateExistingUsers() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      debugPrint('🔄 Checking for user profile migration...');
      await ensureUserProfileExists();
    } catch (e) {
      debugPrint('❌ Error in user migration: $e');
    }
  }

  /// Listen to auth state changes and ensure profiles exist
  static void setupAuthStateListener() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        debugPrint('👤 Auth state changed: User signed in');
        await ensureUserProfileExists();
      } else {
        debugPrint('👤 Auth state changed: User signed out');
      }
    });
  }
}

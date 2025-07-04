import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class UserSyncHelper {
  static final UserService _userService = UserService();
  static bool _isChecking = false;
  static String? _lastCheckedUserId;
  static DateTime? _lastCheckTime;

  /// Ensures the current authenticated user has a corresponding Firestore document
  static Future<bool> ensureUserDocumentExists() async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        debugPrint('❌ UserSyncHelper: No authenticated user');
        return false;
      }

      // Prevent multiple simultaneous checks for the same user
      if (_isChecking && _lastCheckedUserId == authUser.uid) {
        debugPrint(
          '⏳ UserSyncHelper: Already checking user document for ${authUser.uid}',
        );
        return false;
      }

      // Debounce rapid calls - only check once per 5 seconds for the same user
      final now = DateTime.now();
      if (_lastCheckedUserId == authUser.uid &&
          _lastCheckTime != null &&
          now.difference(_lastCheckTime!).inSeconds < 5) {
        debugPrint(
          '⏸️ UserSyncHelper: Skipping recent check for ${authUser.uid}',
        );
        return true; // Assume success since we checked recently
      }

      _isChecking = true;
      _lastCheckedUserId = authUser.uid;
      _lastCheckTime = now;

      debugPrint(
        '🔍 UserSyncHelper: Checking user document for ${authUser.uid}',
      );

      // Check if user document exists
      final existingUser = await _userService.getUserById(authUser.uid);
      if (existingUser != null) {
        debugPrint('✅ UserSyncHelper: User document already exists');
        return true;
      }

      debugPrint('⚠️ UserSyncHelper: User document missing, creating...');

      // Create user document
      try {
        await _userService.createNewUser(
          uid: authUser.uid,
          email: authUser.email ?? '',
          displayName: authUser.displayName ?? 'ARTbeat User',
        );
        debugPrint('✅ UserSyncHelper: createNewUser completed without error');
      } catch (createError) {
        debugPrint(
          '❌ UserSyncHelper: createNewUser failed with error: $createError',
        );
        debugPrint('❌ UserSyncHelper: Error type: ${createError.runtimeType}');
        rethrow;
      }

      // Verify creation
      final newUser = await _userService.getUserById(authUser.uid);
      if (newUser != null) {
        debugPrint('✅ UserSyncHelper: User document created successfully');
        return true;
      } else {
        debugPrint('❌ UserSyncHelper: Failed to create user document');
        return false;
      }
    } catch (e) {
      debugPrint('❌ UserSyncHelper: Error ensuring user document: $e');
      return false;
    } finally {
      _isChecking = false;
    }
  }

  /// Reset state for hot reload scenarios
  static void resetState() {
    _isChecking = false;
    _lastCheckedUserId = null;
    _lastCheckTime = null;
  }

  /// Call this when the app starts to ensure user sync
  static Future<void> initializeUserSync() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      await ensureUserDocumentExists();
    }
  }
}

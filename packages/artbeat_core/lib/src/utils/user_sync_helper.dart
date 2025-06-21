import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class UserSyncHelper {
  static final UserService _userService = UserService();

  /// Ensures the current authenticated user has a corresponding Firestore document
  static Future<bool> ensureUserDocumentExists() async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        debugPrint('❌ UserSyncHelper: No authenticated user');
        return false;
      }

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
    }
  }

  /// Call this when the app starts to ensure user sync
  static Future<void> initializeUserSync() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      await ensureUserDocumentExists();
    }
  }
}

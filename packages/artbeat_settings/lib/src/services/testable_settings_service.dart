import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../interfaces/test_interfaces.dart';
import '../interfaces/document_snapshot_adapter.dart';

/// Interface for user authentication
abstract class IAuthService {
  User? get currentUser;
  Stream<User?> get authStateChanges;
}

/// Default implementation of IAuthService using Firebase Auth
class FirebaseAuthService implements IAuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

/// Interface for firestore operations
abstract class IFirestoreService {
  Future<ITestDocumentSnapshot> getDocument(String collection, String docId);
  Future<void> setDocument(
      String collection, String docId, Map<String, dynamic> data,
      {bool merge});
  Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> data);
}

/// Default implementation of IFirestoreService using Cloud Firestore
class FirestoreService implements IFirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<ITestDocumentSnapshot> getDocument(
      String collection, String docId) async {
    final snapshot = await _firestore.collection(collection).doc(docId).get();
    return DocumentSnapshotAdapter(snapshot);
  }

  @override
  Future<void> setDocument(
      String collection, String docId, Map<String, dynamic> data,
      {bool merge = false}) async {
    await _firestore
        .collection(collection)
        .doc(docId)
        .set(data, merge ? SetOptions(merge: true) : null);
  }

  @override
  Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }
}

/// Testable version of SettingsService with dependency injection
class TestableSettingsService extends ChangeNotifier {
  final IAuthService _authService;
  final IFirestoreService _firestoreService;

  TestableSettingsService({
    required IAuthService authService,
    required IFirestoreService firestoreService,
  })  : _authService = authService,
        _firestoreService = firestoreService;

  /// Get settings for the current user
  Future<Map<String, dynamic>> getUserSettings() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestoreService.getDocument('userSettings', userId);

      if (!doc.exists) {
        // Create default settings if they don't exist
        final defaultSettings = {
          'darkMode': false,
          'notificationsEnabled': true,
          'emailNotifications': true,
          'pushNotifications': true,
          'privacySettings': {
            'profileVisibility': 'public',
            'allowMessages': true,
            'showLocation': false,
          },
          'securitySettings': {
            'twoFactorEnabled': false,
            'loginAlerts': true,
          },
        };

        await _firestoreService
            .setDocument('userSettings', userId, defaultSettings, merge: true);

        return defaultSettings;
      }

      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting user settings: $e');
      rethrow;
    }
  }

  /// Update a specific setting for the current user
  Future<void> updateSetting(String path, dynamic value) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Convert dot notation path to a proper update structure
      final Map<String, dynamic> updateData = {};
      updateData[path] = value;

      await _firestoreService.setDocument('userSettings', userId, updateData,
          merge: true);

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating setting: $e');
      rethrow;
    }
  }

  /// Update user notification preferences
  Future<void> updateNotificationSettings({
    bool? emailNotifications,
    bool? pushNotifications,
    bool? inAppNotifications,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (emailNotifications != null) {
        updates['emailNotifications'] = emailNotifications;
      }

      if (pushNotifications != null) {
        updates['pushNotifications'] = pushNotifications;
      }

      if (inAppNotifications != null) {
        updates['inAppNotifications'] = inAppNotifications;
      }

      if (updates.isNotEmpty) {
        final userId = _authService.currentUser?.uid;
        if (userId == null) {
          throw Exception('User not authenticated');
        }

        await _firestoreService.setDocument('userSettings', userId, updates,
            merge: true);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
      rethrow;
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings({
    String? profileVisibility,
    bool? allowMessages,
    bool? showLocation,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (profileVisibility != null) {
        updates['privacySettings.profileVisibility'] = profileVisibility;
      }

      if (allowMessages != null) {
        updates['privacySettings.allowMessages'] = allowMessages;
      }

      if (showLocation != null) {
        updates['privacySettings.showLocation'] = showLocation;
      }

      if (updates.isNotEmpty) {
        final userId = _authService.currentUser?.uid;
        if (userId == null) {
          throw Exception('User not authenticated');
        }

        await _firestoreService.setDocument('userSettings', userId, updates,
            merge: true);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating privacy settings: $e');
      rethrow;
    }
  }

  /// Get a list of blocked user IDs
  Future<List<String>> getBlockedUsers() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestoreService.getDocument('userSettings', userId);

      if (!doc.exists) {
        return [];
      }

      final data = doc.data();
      if (data == null || !data.containsKey('blockedUsers')) {
        return [];
      }

      final blockedUsers = data['blockedUsers'] as List<dynamic>;
      return blockedUsers.cast<String>();
    } catch (e) {
      debugPrint('Error getting blocked users: $e');
      return [];
    }
  }

  /// Block a user
  Future<void> blockUser(String targetUserId) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // First get the current blocked users
      final currentBlocked = await getBlockedUsers();
      if (!currentBlocked.contains(targetUserId)) {
        currentBlocked.add(targetUserId);
      }

      await _firestoreService.setDocument(
          'userSettings', userId, {'blockedUsers': currentBlocked},
          merge: true);

      notifyListeners();
    } catch (e) {
      debugPrint('Error blocking user: $e');
      rethrow;
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String targetUserId) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // First get the current blocked users
      final currentBlocked = await getBlockedUsers();
      currentBlocked.remove(targetUserId);

      await _firestoreService.setDocument(
          'userSettings', userId, {'blockedUsers': currentBlocked},
          merge: true);

      notifyListeners();
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      rethrow;
    }
  }
}

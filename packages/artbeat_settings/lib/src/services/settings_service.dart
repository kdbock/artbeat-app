import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Settings service for managing user settings and preferences
class SettingsService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SettingsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get settings for the current user
  Future<Map<String, dynamic>> getUserSettings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore.collection('userSettings').doc(userId).get();

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

        await _firestore
            .collection('userSettings')
            .doc(userId)
            .set(defaultSettings);

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
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Convert dot notation path to a proper update structure
      final Map<String, dynamic> updateData = {};
      updateData[path] = value;

      await _firestore
          .collection('userSettings')
          .doc(userId)
          .set(updateData, SetOptions(merge: true));

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
        final userId = _auth.currentUser?.uid;
        if (userId == null) {
          throw Exception('User not authenticated');
        }

        await _firestore
            .collection('userSettings')
            .doc(userId)
            .set(updates, SetOptions(merge: true));

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
        final userId = _auth.currentUser?.uid;
        if (userId == null) {
          throw Exception('User not authenticated');
        }

        await _firestore
            .collection('userSettings')
            .doc(userId)
            .set(updates, SetOptions(merge: true));

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
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore.collection('userSettings').doc(userId).get();

      if (!doc.exists || !doc.data()!.containsKey('blockedUsers')) {
        return [];
      }

      final blockedUsers = doc.data()!['blockedUsers'] as List<dynamic>;
      return blockedUsers.cast<String>();
    } catch (e) {
      debugPrint('Error getting blocked users: $e');
      return [];
    }
  }

  /// Block a user
  Future<void> blockUser(String targetUserId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('userSettings').doc(userId).set({
        'blockedUsers': FieldValue.arrayUnion([targetUserId])
      }, SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      debugPrint('Error blocking user: $e');
      rethrow;
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String targetUserId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('userSettings').doc(userId).set({
        'blockedUsers': FieldValue.arrayRemove([targetUserId])
      }, SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      rethrow;
    }
  }
}

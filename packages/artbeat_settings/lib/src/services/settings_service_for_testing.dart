import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_settings/src/services/testable_settings_service.dart';

/// Standalone version of a testable settings service
class SettingsServiceForTesting extends ChangeNotifier {
  final IAuthService _authService;
  final IFirestoreService _firestoreService;

  SettingsServiceForTesting({
    required IAuthService authService,
    required IFirestoreService firestoreService,
  })  : _authService = authService,
        _firestoreService = firestoreService;

  /// Get user account settings
  Future<Map<String, dynamic>> getUserAccountSettings() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestoreService.getDocument('users', userId);

      if (!doc.exists) {
        return {};
      }

      final data = doc.data();
      if (data == null) {
        return {};
      }

      // Extract relevant account settings
      final accountSettings = {
        'email': data['email'] ?? '',
        'fullName': data['fullName'] ?? '',
        'phoneNumber': data['phoneNumber'] ?? '',
      };

      return accountSettings;
    } catch (e) {
      debugPrint('Error getting user account settings: $e');
      return {};
    }
  }

  /// Update user account settings
  Future<void> updateUserAccountSettings(Map<String, dynamic> settings) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestoreService.updateDocument('users', userId, settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user account settings: $e');
      rethrow;
    }
  }

  /// Get user notification settings
  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestoreService.getDocument('users', userId);

      if (!doc.exists) {
        return {};
      }

      final data = doc.data();
      if (data == null || !data.containsKey('notificationPreferences')) {
        return {};
      }

      return data['notificationPreferences'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting notification settings: $e');
      return {};
    }
  }

  /// Update notification settings with a complete settings map
  Future<void> updateNotificationSettings(Map<String, dynamic> settings) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final updates = {
        'notificationPreferences': settings
      };

      await _firestoreService.updateDocument('users', userId, updates);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
      rethrow;
    }
  }

  /// Get user privacy settings
  Future<Map<String, dynamic>> getPrivacySettings() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestoreService.getDocument('users', userId);

      if (!doc.exists) {
        return {};
      }

      final data = doc.data();
      if (data == null || !data.containsKey('privacySettings')) {
        return {};
      }

      return data['privacySettings'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting privacy settings: $e');
      return {};
    }
  }

  /// Update privacy settings with a complete settings map
  Future<void> updatePrivacySettings(Map<String, dynamic> settings) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final updates = {
        'privacySettings': settings
      };

      await _firestoreService.updateDocument('users', userId, updates);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating privacy settings: $e');
      rethrow;
    }
  }

  /// Get device activity for the current user
  Future<List<Map<String, dynamic>>> getDeviceActivity() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestoreService.getDocument('users', userId);

      if (!doc.exists) {
        return [];
      }

      final data = doc.data();
      if (data == null || !data.containsKey('deviceActivity')) {
        return [];
      }

      final deviceActivity = data['deviceActivity'] as List<dynamic>;
      return deviceActivity.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting device activity: $e');
      return [];
    }
  }

  /// Revoke access for a specific device
  Future<void> revokeDeviceAccess(String deviceId) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get current device activity
      final currentDevices = await getDeviceActivity();
      
      // Remove the specific device
      final updatedDevices = currentDevices
          .where((device) => device['deviceId'] != deviceId)
          .toList();
      
      // Update the document
      await _firestoreService.updateDocument(
          'users', userId, {'deviceActivity': updatedDevices});
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error revoking device access: $e');
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

      final doc = await _firestoreService.getDocument('users', userId);

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

      await _firestoreService.updateDocument(
          'users', userId, {'blockedUsers': currentBlocked});

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

      await _firestoreService.updateDocument(
          'users', userId, {'blockedUsers': currentBlocked});

      notifyListeners();
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      rethrow;
    }
  }
}

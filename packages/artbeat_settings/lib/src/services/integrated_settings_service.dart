import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Production-ready integrated settings service with caching and performance optimization
/// Implementation Date: September 5, 2025
class IntegratedSettingsService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Cache management
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Stream subscriptions for real-time updates
  StreamSubscription<DocumentSnapshot>? _userSettingsSubscription;

  // Performance tracking
  int _cacheHits = 0;
  int _cacheMisses = 0;

  IntegratedSettingsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance {
    _initializeService();
  }

  /// Initialize the service with caching and listeners
  Future<void> _initializeService() async {
    _setupRealtimeListeners();
  }

  /// Set up real-time listeners for settings changes
  void _setupRealtimeListeners() {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      _userSettingsSubscription?.cancel();
      _userSettingsSubscription = _firestore
          .collection('userSettings')
          .doc(userId)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists) {
              _invalidateCache();
              notifyListeners();
            }
          });
    }
  }

  /// Performance metrics getter
  Map<String, dynamic> get performanceMetrics => {
    'cacheHits': _cacheHits,
    'cacheMisses': _cacheMisses,
    'hitRatio': _cacheHits / (_cacheHits + _cacheMisses),
    'cachedItems': _cache.length,
  };

  /// Generic cache management
  T? _getCached<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null &&
        DateTime.now().difference(timestamp) < _cacheExpiry) {
      _cacheHits++;
      return _cache[key] as T?;
    }
    _cacheMisses++;
    return null;
  }

  void _setCached(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  void _invalidateCache([String? specificKey]) {
    if (specificKey != null) {
      _cache.remove(specificKey);
      _cacheTimestamps.remove(specificKey);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }

  /// Get comprehensive user settings with caching
  Future<UserSettingsModel> getUserSettings() async {
    const cacheKey = 'userSettings';

    // Try cache first
    final cached = _getCached<UserSettingsModel>(cacheKey);
    if (cached != null) return cached;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore.collection('userSettings').doc(userId).get();

      UserSettingsModel settings;
      if (!doc.exists) {
        // Create default settings
        settings = UserSettingsModel.defaultSettings(userId);
        await _createDefaultUserSettings(settings);
      } else {
        settings = UserSettingsModel.fromMap(doc.data()!);
      }

      // Cache the result
      _setCached(cacheKey, settings);
      return settings;
    } catch (e) {
      AppLogger.error('Error getting user settings: $e');
      rethrow;
    }
  }

  /// Create default user settings in Firestore
  Future<void> _createDefaultUserSettings(UserSettingsModel settings) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('userSettings')
        .doc(userId)
        .set(settings.toMap());
  }

  /// Update user settings with optimistic updates and caching
  Future<void> updateUserSettings(UserSettingsModel settings) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Optimistic update - update cache immediately
      _setCached('userSettings', settings);
      notifyListeners();

      // Update Firestore
      await _firestore
          .collection('userSettings')
          .doc(userId)
          .set(settings.toMap(), SetOptions(merge: true));
    } catch (e) {
      // Revert optimistic update on error
      _invalidateCache('userSettings');
      AppLogger.error('Error updating user settings: $e');
      rethrow;
    }
  }

  /// Get notification settings with caching
  Future<NotificationSettingsModel> getNotificationSettings() async {
    const cacheKey = 'notificationSettings';

    final cached = _getCached<NotificationSettingsModel>(cacheKey);
    if (cached != null) return cached;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection('notificationSettings')
          .doc(userId)
          .get();

      NotificationSettingsModel settings;
      if (!doc.exists) {
        settings = NotificationSettingsModel.defaultSettings(userId);
        await _firestore
            .collection('notificationSettings')
            .doc(userId)
            .set(settings.toMap());
      } else {
        settings = NotificationSettingsModel.fromMap(doc.data()!);
      }

      _setCached(cacheKey, settings);
      return settings;
    } catch (e) {
      AppLogger.error('Error getting notification settings: $e');
      rethrow;
    }
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(
    NotificationSettingsModel settings,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Optimistic update
      _setCached('notificationSettings', settings);
      notifyListeners();

      await _firestore
          .collection('notificationSettings')
          .doc(userId)
          .set(settings.toMap(), SetOptions(merge: true));
    } catch (e) {
      _invalidateCache('notificationSettings');
      AppLogger.error('Error updating notification settings: $e');
      rethrow;
    }
  }

  /// Get privacy settings with caching
  Future<PrivacySettingsModel> getPrivacySettings() async {
    const cacheKey = 'privacySettings';

    final cached = _getCached<PrivacySettingsModel>(cacheKey);
    if (cached != null) return cached;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection('privacySettings')
          .doc(userId)
          .get();

      PrivacySettingsModel settings;
      if (!doc.exists) {
        settings = PrivacySettingsModel.defaultSettings(userId);
        await _firestore
            .collection('privacySettings')
            .doc(userId)
            .set(settings.toMap());
      } else {
        settings = PrivacySettingsModel.fromMap(doc.data()!);
      }

      _setCached(cacheKey, settings);
      return settings;
    } catch (e) {
      AppLogger.error('Error getting privacy settings: $e');
      rethrow;
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(PrivacySettingsModel settings) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Optimistic update
      _setCached('privacySettings', settings);
      notifyListeners();

      await _firestore
          .collection('privacySettings')
          .doc(userId)
          .set(settings.toMap(), SetOptions(merge: true));
    } catch (e) {
      _invalidateCache('privacySettings');
      AppLogger.error('Error updating privacy settings: $e');
      rethrow;
    }
  }

  /// Get security settings with caching
  Future<SecuritySettingsModel> getSecuritySettings() async {
    const cacheKey = 'securitySettings';

    final cached = _getCached<SecuritySettingsModel>(cacheKey);
    if (cached != null) return cached;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection('securitySettings')
          .doc(userId)
          .get();

      SecuritySettingsModel settings;
      if (!doc.exists) {
        settings = SecuritySettingsModel.defaultSettings(userId);
        await _firestore
            .collection('securitySettings')
            .doc(userId)
            .set(settings.toMap());
      } else {
        settings = SecuritySettingsModel.fromMap(doc.data()!);
      }

      _setCached(cacheKey, settings);
      return settings;
    } catch (e) {
      AppLogger.error('Error getting security settings: $e');
      rethrow;
    }
  }

  /// Update security settings
  Future<void> updateSecuritySettings(SecuritySettingsModel settings) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Optimistic update
      _setCached('securitySettings', settings);
      notifyListeners();

      await _firestore
          .collection('securitySettings')
          .doc(userId)
          .set(settings.toMap(), SetOptions(merge: true));
    } catch (e) {
      _invalidateCache('securitySettings');
      AppLogger.error('Error updating security settings: $e');
      rethrow;
    }
  }

  /// Get account settings with caching
  Future<AccountSettingsModel> getAccountSettings() async {
    const cacheKey = 'accountSettings';

    final cached = _getCached<AccountSettingsModel>(cacheKey);
    if (cached != null) return cached;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore.collection('users').doc(userId).get();

      AccountSettingsModel settings;
      if (!doc.exists) {
        final user = _auth.currentUser!;
        settings = AccountSettingsModel(
          userId: userId,
          email: user.email ?? '',
          username: '',
          displayName: user.displayName ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(userId)
            .set(settings.toMap(), SetOptions(merge: true));
      } else {
        settings = AccountSettingsModel.fromMap(doc.data()!);
      }

      _setCached(cacheKey, settings);
      return settings;
    } catch (e) {
      AppLogger.error('Error getting account settings: $e');
      rethrow;
    }
  }

  /// Update account settings
  Future<void> updateAccountSettings(AccountSettingsModel settings) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Optimistic update
      _setCached('accountSettings', settings);
      notifyListeners();

      await _firestore
          .collection('users')
          .doc(userId)
          .set(settings.toMap(), SetOptions(merge: true));
    } catch (e) {
      _invalidateCache('accountSettings');
      AppLogger.error('Error updating account settings: $e');
      rethrow;
    }
  }

  /// Get blocked users with caching
  Future<List<BlockedUserModel>> getBlockedUsers() async {
    const cacheKey = 'blockedUsers';

    final cached = _getCached<List<BlockedUserModel>>(cacheKey);
    if (cached != null) return cached;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('blockedUsers')
          .where('blockedBy', isEqualTo: userId)
          .orderBy('blockedAt', descending: true)
          .get();

      final blockedUsers = querySnapshot.docs
          .map((doc) => BlockedUserModel.fromMap(doc.data()))
          .toList();

      _setCached(cacheKey, blockedUsers);
      return blockedUsers;
    } catch (e) {
      AppLogger.error('Error getting blocked users: $e');
      return [];
    }
  }

  /// Block a user
  Future<void> blockUser(
    String targetUserId,
    String targetUserName,
    String reason,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final blockedUser = BlockedUserModel(
        blockedUserId: targetUserId,
        blockedUserName: targetUserName,
        reason: reason,
        blockedAt: DateTime.now(),
        blockedBy: userId,
      );

      final blockId = '${userId}_$targetUserId';
      await _firestore
          .collection('blockedUsers')
          .doc(blockId)
          .set(blockedUser.toMap());

      // Invalidate cache to force refresh
      _invalidateCache('blockedUsers');
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error blocking user: $e');
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

      final blockId = '${userId}_$targetUserId';
      await _firestore.collection('blockedUsers').doc(blockId).delete();

      // Invalidate cache to force refresh
      _invalidateCache('blockedUsers');
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error unblocking user: $e');
      rethrow;
    }
  }

  /// Get device activity with caching
  Future<List<DeviceActivityModel>> getDeviceActivity() async {
    const cacheKey = 'deviceActivity';

    final cached = _getCached<List<DeviceActivityModel>>(cacheKey);
    if (cached != null) return cached;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('deviceActivity')
          .where('userId', isEqualTo: userId)
          .orderBy('lastActive', descending: true)
          .limit(20)
          .get();

      final devices = querySnapshot.docs
          .map((doc) => DeviceActivityModel.fromMap(doc.data()))
          .toList();

      _setCached(cacheKey, devices);
      return devices;
    } catch (e) {
      AppLogger.error('Error getting device activity: $e');
      return [];
    }
  }

  /// Log device activity
  Future<void> logDeviceActivity(DeviceActivityModel activity) async {
    try {
      await _firestore
          .collection('deviceActivity')
          .doc(activity.deviceId)
          .set(activity.toMap(), SetOptions(merge: true));

      // Invalidate cache to force refresh
      _invalidateCache('deviceActivity');
    } catch (e) {
      AppLogger.error('Error logging device activity: $e');
    }
  }

  /// Request data download (GDPR compliance)
  Future<void> requestDataDownload() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('dataRequests').add({
        'userId': userId,
        'requestType': 'download',
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      AppLogger.error('Error requesting data download: $e');
      rethrow;
    }
  }

  /// Request data deletion (GDPR compliance)
  Future<void> requestDataDeletion() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('dataRequests').add({
        'userId': userId,
        'requestType': 'deletion',
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      AppLogger.error('Error requesting data deletion: $e');
      rethrow;
    }
  }

  /// Preload all settings for performance
  Future<void> preloadAllSettings() async {
    try {
      await Future.wait([
        getUserSettings(),
        getNotificationSettings(),
        getPrivacySettings(),
        getSecuritySettings(),
        getAccountSettings(),
        getBlockedUsers(),
        getDeviceActivity(),
      ]);
    } catch (e) {
      AppLogger.error('Error preloading settings: $e');
    }
  }

  /// Clear all cached data
  void clearCache() {
    _invalidateCache();
    notifyListeners();
  }

  @override
  void dispose() {
    _userSettingsSubscription?.cancel();
    super.dispose();
  }
}

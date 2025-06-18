import 'package:artbeat_settings/src/interfaces/i_auth_service.dart';
import 'package:artbeat_settings/src/interfaces/i_firestore_service.dart';

/// Enhanced settings service with dependency injection for better testability
class EnhancedSettingsService {
  final IAuthService _authService;
  final IFirestoreService _firestoreService;

  EnhancedSettingsService({
    required IAuthService authService,
    required IFirestoreService firestoreService,
  }) : _authService = authService,
       _firestoreService = firestoreService;

  /// Get current user account settings
  Future<Map<String, dynamic>> getUserAccountSettings() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) throw Exception('No authenticated user');

    final doc = await _firestoreService.getDocument('users', userId);
    if (!doc.exists) throw Exception('User settings not found');

    return doc.data() ?? {};
  }

  /// Get notification settings
  Future<Map<String, dynamic>> getNotificationSettings() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) throw Exception('No authenticated user');

    final doc = await _firestoreService.getDocument('users', userId);
    if (!doc.exists) throw Exception('User settings not found');

    final data = doc.data() ?? {};
    return (data['notificationPreferences'] as Map<String, dynamic>?) ?? {};
  }

  /// Get privacy settings
  Future<Map<String, dynamic>> getPrivacySettings() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) throw Exception('No authenticated user');

    final doc = await _firestoreService.getDocument('users', userId);
    if (!doc.exists) throw Exception('User settings not found');

    final data = doc.data() ?? {};
    return (data['privacySettings'] as Map<String, dynamic>?) ?? {};
  }

  /// Get blocked users list
  Future<List<String>> getBlockedUsers() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) throw Exception('No authenticated user');

    final doc = await _firestoreService.getDocument('users', userId);
    if (!doc.exists) throw Exception('User settings not found');

    final data = doc.data() ?? {};
    return (data['blockedUsers'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();
  }

  /// Get device activity
  Future<List<Map<String, dynamic>>> getDeviceActivity() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) throw Exception('No authenticated user');

    final doc = await _firestoreService.getDocument('users', userId);
    if (!doc.exists) throw Exception('User settings not found');

    final data = doc.data() ?? {};
    return (data['deviceActivity'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
}

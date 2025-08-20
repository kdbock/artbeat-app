import 'package:flutter/foundation.dart';
import '../services/presence_service.dart';

/// Provider for managing user presence across the app
class PresenceProvider extends ChangeNotifier {
  final PresenceService _presenceService;
  bool _isInitialized = false;

  PresenceProvider(this._presenceService) {
    debugPrint('PresenceProvider: Initializing');
    _initialize();
  }

  bool get isInitialized => _isInitialized;

  void _initialize() {
    // The PresenceService handles its own initialization
    _isInitialized = true;
    debugPrint('PresenceProvider: Initialized');
  }

  /// Update user activity (call when user interacts with the app)
  Future<void> updateActivity() async {
    await _presenceService.updateActivity();
  }

  /// Get online users stream
  Stream<List<Map<String, dynamic>>> getOnlineUsersStream() {
    return _presenceService.getOnlineUsersStream();
  }

  /// Check if a specific user is online
  Future<bool> isUserOnline(String userId) async {
    return _presenceService.isUserOnline(userId);
  }

  /// Get user's last seen time
  Future<DateTime?> getUserLastSeen(String userId) async {
    return _presenceService.getUserLastSeen(userId);
  }

  /// Force immediate presence update and debug check (for testing)
  Future<void> forcePresenceUpdate() async {
    await _presenceService.forcePresenceUpdate();
  }

  @override
  void dispose() {
    debugPrint('PresenceProvider: Disposing');
    _presenceService.dispose();
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/integrated_settings_service.dart';

/// Settings provider with optimized state management and caching
/// Implementation Date: September 5, 2025
class SettingsProvider extends ChangeNotifier {
  final IntegratedSettingsService _service;

  // Cached settings
  UserSettingsModel? _userSettings;
  NotificationSettingsModel? _notificationSettings;
  PrivacySettingsModel? _privacySettings;
  SecuritySettingsModel? _securitySettings;
  AccountSettingsModel? _accountSettings;
  List<BlockedUserModel> _blockedUsers = [];
  List<DeviceActivityModel> _deviceActivity = [];

  // Loading states
  bool _isLoadingUserSettings = false;
  bool _isLoadingNotificationSettings = false;
  bool _isLoadingPrivacySettings = false;
  bool _isLoadingSecuritySettings = false;
  bool _isLoadingAccountSettings = false;
  bool _isLoadingBlockedUsers = false;
  bool _isLoadingDeviceActivity = false;

  // Error states
  String? _errorMessage;

  SettingsProvider(this._service) {
    _service.addListener(_onServiceUpdate);
  }

  // Getters for settings
  UserSettingsModel? get userSettings => _userSettings;
  NotificationSettingsModel? get notificationSettings => _notificationSettings;
  PrivacySettingsModel? get privacySettings => _privacySettings;
  SecuritySettingsModel? get securitySettings => _securitySettings;
  AccountSettingsModel? get accountSettings => _accountSettings;
  List<BlockedUserModel> get blockedUsers => _blockedUsers;
  List<DeviceActivityModel> get deviceActivity => _deviceActivity;

  // Loading state getters
  bool get isLoadingUserSettings => _isLoadingUserSettings;
  bool get isLoadingNotificationSettings => _isLoadingNotificationSettings;
  bool get isLoadingPrivacySettings => _isLoadingPrivacySettings;
  bool get isLoadingSecuritySettings => _isLoadingSecuritySettings;
  bool get isLoadingAccountSettings => _isLoadingAccountSettings;
  bool get isLoadingBlockedUsers => _isLoadingBlockedUsers;
  bool get isLoadingDeviceActivity => _isLoadingDeviceActivity;

  bool get isLoadingAny =>
      _isLoadingUserSettings ||
      _isLoadingNotificationSettings ||
      _isLoadingPrivacySettings ||
      _isLoadingSecuritySettings ||
      _isLoadingAccountSettings ||
      _isLoadingBlockedUsers ||
      _isLoadingDeviceActivity;

  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Performance metrics
  Map<String, dynamic> get performanceMetrics => _service.performanceMetrics;

  void _onServiceUpdate() {
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Load user settings
  Future<void> loadUserSettings({bool forceRefresh = false}) async {
    if (!forceRefresh && _userSettings != null) return;

    _isLoadingUserSettings = true;
    _clearError();
    notifyListeners();

    try {
      _userSettings = await _service.getUserSettings();
    } catch (e) {
      _setError('Failed to load user settings: $e');
    } finally {
      _isLoadingUserSettings = false;
      notifyListeners();
    }
  }

  /// Update user settings
  Future<bool> updateUserSettings(UserSettingsModel settings) async {
    _clearError();

    try {
      await _service.updateUserSettings(settings);
      _userSettings = settings;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update user settings: $e');
      return false;
    }
  }

  /// Load notification settings
  Future<void> loadNotificationSettings({bool forceRefresh = false}) async {
    if (!forceRefresh && _notificationSettings != null) return;

    _isLoadingNotificationSettings = true;
    _clearError();
    notifyListeners();

    try {
      _notificationSettings = await _service.getNotificationSettings();
    } catch (e) {
      _setError('Failed to load notification settings: $e');
    } finally {
      _isLoadingNotificationSettings = false;
      notifyListeners();
    }
  }

  /// Update notification settings
  Future<bool> updateNotificationSettings(
    NotificationSettingsModel settings,
  ) async {
    _clearError();

    try {
      await _service.updateNotificationSettings(settings);
      _notificationSettings = settings;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update notification settings: $e');
      return false;
    }
  }

  /// Load privacy settings
  Future<void> loadPrivacySettings({bool forceRefresh = false}) async {
    if (!forceRefresh && _privacySettings != null) return;

    _isLoadingPrivacySettings = true;
    _clearError();
    notifyListeners();

    try {
      _privacySettings = await _service.getPrivacySettings();
    } catch (e) {
      _setError('Failed to load privacy settings: $e');
    } finally {
      _isLoadingPrivacySettings = false;
      notifyListeners();
    }
  }

  /// Update privacy settings
  Future<bool> updatePrivacySettings(PrivacySettingsModel settings) async {
    _clearError();

    try {
      await _service.updatePrivacySettings(settings);
      _privacySettings = settings;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update privacy settings: $e');
      return false;
    }
  }

  /// Load security settings
  Future<void> loadSecuritySettings({bool forceRefresh = false}) async {
    if (!forceRefresh && _securitySettings != null) return;

    _isLoadingSecuritySettings = true;
    _clearError();
    notifyListeners();

    try {
      _securitySettings = await _service.getSecuritySettings();
    } catch (e) {
      _setError('Failed to load security settings: $e');
    } finally {
      _isLoadingSecuritySettings = false;
      notifyListeners();
    }
  }

  /// Update security settings
  Future<bool> updateSecuritySettings(SecuritySettingsModel settings) async {
    _clearError();

    try {
      await _service.updateSecuritySettings(settings);
      _securitySettings = settings;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update security settings: $e');
      return false;
    }
  }

  /// Load account settings
  Future<void> loadAccountSettings({bool forceRefresh = false}) async {
    if (!forceRefresh && _accountSettings != null) return;

    _isLoadingAccountSettings = true;
    _clearError();
    notifyListeners();

    try {
      _accountSettings = await _service.getAccountSettings();
    } catch (e) {
      _setError('Failed to load account settings: $e');
    } finally {
      _isLoadingAccountSettings = false;
      notifyListeners();
    }
  }

  /// Update account settings
  Future<bool> updateAccountSettings(AccountSettingsModel settings) async {
    _clearError();

    try {
      await _service.updateAccountSettings(settings);
      _accountSettings = settings;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update account settings: $e');
      return false;
    }
  }

  /// Load blocked users
  Future<void> loadBlockedUsers({bool forceRefresh = false}) async {
    if (!forceRefresh && _blockedUsers.isNotEmpty) return;

    _isLoadingBlockedUsers = true;
    _clearError();
    notifyListeners();

    try {
      _blockedUsers = await _service.getBlockedUsers();
    } catch (e) {
      _setError('Failed to load blocked users: $e');
    } finally {
      _isLoadingBlockedUsers = false;
      notifyListeners();
    }
  }

  /// Block user
  Future<bool> blockUser(String userId, String userName, String reason) async {
    _clearError();

    try {
      await _service.blockUser(userId, userName, reason);
      // Refresh blocked users list
      await loadBlockedUsers(forceRefresh: true);
      return true;
    } catch (e) {
      _setError('Failed to block user: $e');
      return false;
    }
  }

  /// Unblock user
  Future<bool> unblockUser(String userId) async {
    _clearError();

    try {
      await _service.unblockUser(userId);
      // Remove from local list immediately for better UX
      _blockedUsers.removeWhere((user) => user.blockedUserId == userId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to unblock user: $e');
      // Refresh the list to ensure consistency
      await loadBlockedUsers(forceRefresh: true);
      return false;
    }
  }

  /// Load device activity
  Future<void> loadDeviceActivity({bool forceRefresh = false}) async {
    if (!forceRefresh && _deviceActivity.isNotEmpty) return;

    _isLoadingDeviceActivity = true;
    _clearError();
    notifyListeners();

    try {
      _deviceActivity = await _service.getDeviceActivity();
    } catch (e) {
      _setError('Failed to load device activity: $e');
    } finally {
      _isLoadingDeviceActivity = false;
      notifyListeners();
    }
  }

  /// Load all settings at once for performance
  Future<void> preloadAllSettings() async {
    _clearError();

    try {
      await _service.preloadAllSettings();

      // Load all settings in parallel
      await Future.wait([
        loadUserSettings(forceRefresh: true),
        loadNotificationSettings(forceRefresh: true),
        loadPrivacySettings(forceRefresh: true),
        loadSecuritySettings(forceRefresh: true),
        loadAccountSettings(forceRefresh: true),
        loadBlockedUsers(forceRefresh: true),
        loadDeviceActivity(forceRefresh: true),
      ]);
    } catch (e) {
      _setError('Failed to preload settings: $e');
    }
  }

  /// Clear all cached data
  void clearCache() {
    _service.clearCache();

    _userSettings = null;
    _notificationSettings = null;
    _privacySettings = null;
    _securitySettings = null;
    _accountSettings = null;
    _blockedUsers = [];
    _deviceActivity = [];

    _clearError();
    notifyListeners();
  }

  /// Request data download (GDPR)
  Future<bool> requestDataDownload() async {
    _clearError();

    try {
      await _service.requestDataDownload();
      return true;
    } catch (e) {
      _setError('Failed to request data download: $e');
      return false;
    }
  }

  /// Request data deletion (GDPR)
  Future<bool> requestDataDeletion() async {
    _clearError();

    try {
      await _service.requestDataDeletion();
      return true;
    } catch (e) {
      _setError('Failed to request data deletion: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _service.dispose();
    super.dispose();
  }
}

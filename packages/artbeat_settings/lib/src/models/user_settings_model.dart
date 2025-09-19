import 'package:flutter/foundation.dart';

/// Core user settings model that encompasses all user preferences
/// Implementation Date: September 5, 2025
class UserSettingsModel {
  final String userId;
  final bool darkMode;
  final bool notificationsEnabled;
  final String language;
  final String timezone;
  final String distanceUnit; // 'miles' or 'kilometers'
  final Map<String, dynamic> notificationPreferences;
  final Map<String, dynamic> privacySettings;
  final Map<String, dynamic> securitySettings;
  final List<String> blockedUsers;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserSettingsModel({
    required this.userId,
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.language = 'en',
    this.timezone = 'UTC',
    this.distanceUnit = 'miles', // Default to miles for US users
    this.notificationPreferences = const {},
    this.privacySettings = const {},
    this.securitySettings = const {},
    this.blockedUsers = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create UserSettings from Firestore document
  factory UserSettingsModel.fromMap(Map<String, dynamic> map) {
    return UserSettingsModel(
      userId: map['userId'] as String? ?? '',
      darkMode: map['darkMode'] as bool? ?? false,
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      language: map['language'] as String? ?? 'en',
      timezone: map['timezone'] as String? ?? 'UTC',
      distanceUnit: map['distanceUnit'] as String? ?? 'miles',
      notificationPreferences: Map<String, dynamic>.from(
        map['notificationPreferences'] as Map<String, dynamic>? ?? {},
      ),
      privacySettings: Map<String, dynamic>.from(
        map['privacySettings'] as Map<String, dynamic>? ?? {},
      ),
      securitySettings: Map<String, dynamic>.from(
        map['securitySettings'] as Map<String, dynamic>? ?? {},
      ),
      blockedUsers: List<String>.from(
        map['blockedUsers'] as List<dynamic>? ?? [],
      ),
      createdAt: DateTime.parse(
        map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'darkMode': darkMode,
      'notificationsEnabled': notificationsEnabled,
      'language': language,
      'timezone': timezone,
      'distanceUnit': distanceUnit,
      'notificationPreferences': notificationPreferences,
      'privacySettings': privacySettings,
      'securitySettings': securitySettings,
      'blockedUsers': blockedUsers,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create default settings for a new user
  factory UserSettingsModel.defaultSettings(String userId) {
    final now = DateTime.now();
    return UserSettingsModel(
      userId: userId,
      darkMode: false,
      notificationsEnabled: true,
      language: 'en',
      timezone: 'UTC',
      distanceUnit: 'miles', // Default to miles for US users
      notificationPreferences: _getDefaultNotificationPreferences(),
      privacySettings: _getDefaultPrivacySettings(),
      securitySettings: _getDefaultSecuritySettings(),
      blockedUsers: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Default notification preferences
  static Map<String, dynamic> _getDefaultNotificationPreferences() {
    return {
      'email': {
        'enabled': true,
        'frequency': 'immediate', // immediate, daily, weekly
        'types': {
          'account': true,
          'security': true,
          'marketing': false,
          'social': true,
          'artwork': true,
          'events': true,
        },
      },
      'push': {
        'enabled': true,
        'types': {
          'messages': true,
          'likes': true,
          'comments': true,
          'follows': true,
          'events': true,
          'artwork': true,
          'security': true,
        },
      },
      'inApp': {
        'enabled': true,
        'types': {
          'messages': true,
          'social': true,
          'artwork': true,
          'events': true,
        },
      },
      'quietHours': {
        'enabled': false,
        'startTime': '22:00',
        'endTime': '08:00',
        'timezone': 'UTC',
      },
    };
  }

  /// Default privacy settings
  static Map<String, dynamic> _getDefaultPrivacySettings() {
    return {
      'profile': {
        'visibility': 'public', // public, friends, private
        'showLastSeen': true,
        'showOnlineStatus': true,
      },
      'content': {
        'allowComments': true,
        'allowLikes': true,
        'allowSharing': true,
        'showInSearch': true,
      },
      'data': {
        'allowAnalytics': true,
        'allowPersonalization': true,
        'allowMarketing': false,
        'allowThirdPartySharing': false,
      },
      'location': {
        'shareLocation': false,
        'showLocationInProfile': false,
        'allowLocationBasedRecommendations': true,
      },
    };
  }

  /// Default security settings
  static Map<String, dynamic> _getDefaultSecuritySettings() {
    return {
      'twoFactor': {
        'enabled': false,
        'method': 'sms', // sms, authenticator, email
        'backupCodes': <String>[],
      },
      'login': {
        'requireEmailVerification': true,
        'allowLoginAlerts': true,
        'sessionTimeout': 30, // days
      },
      'password': {
        'requireComplexPassword': true,
        'requirePasswordChange': false,
        'lastChanged': null,
      },
      'devices': {'allowMultipleSessions': true, 'maxActiveSessions': 5},
    };
  }

  /// Copy with new values
  UserSettingsModel copyWith({
    String? userId,
    bool? darkMode,
    bool? notificationsEnabled,
    String? language,
    String? timezone,
    String? distanceUnit,
    Map<String, dynamic>? notificationPreferences,
    Map<String, dynamic>? privacySettings,
    Map<String, dynamic>? securitySettings,
    List<String>? blockedUsers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettingsModel(
      userId: userId ?? this.userId,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      privacySettings: privacySettings ?? this.privacySettings,
      securitySettings: securitySettings ?? this.securitySettings,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Validation method
  bool isValid() {
    return userId.isNotEmpty &&
        language.isNotEmpty &&
        timezone.isNotEmpty &&
        (distanceUnit == 'miles' || distanceUnit == 'kilometers');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSettingsModel &&
        other.userId == userId &&
        other.darkMode == darkMode &&
        other.notificationsEnabled == notificationsEnabled &&
        other.language == language &&
        other.timezone == timezone &&
        other.distanceUnit == distanceUnit &&
        mapEquals(other.notificationPreferences, notificationPreferences) &&
        mapEquals(other.privacySettings, privacySettings) &&
        mapEquals(other.securitySettings, securitySettings) &&
        listEquals(other.blockedUsers, blockedUsers);
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        darkMode.hashCode ^
        notificationsEnabled.hashCode ^
        language.hashCode ^
        timezone.hashCode ^
        distanceUnit.hashCode ^
        notificationPreferences.hashCode ^
        privacySettings.hashCode ^
        securitySettings.hashCode ^
        blockedUsers.hashCode;
  }

  @override
  String toString() {
    return 'UserSettingsModel(userId: $userId, darkMode: $darkMode, '
        'notificationsEnabled: $notificationsEnabled, language: $language, '
        'timezone: $timezone, distanceUnit: $distanceUnit, updatedAt: $updatedAt)';
  }
}

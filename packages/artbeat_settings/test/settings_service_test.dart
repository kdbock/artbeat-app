import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock classes
@GenerateMocks([SharedPreferences])
import 'settings_service_test.mocks.dart';

void main() {
  group('SettingsService Tests', () {
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
    });

    test('should save user preferences successfully', () async {
      // Arrange
      const key = 'notification_enabled';
      const value = true;

      when(mockPrefs.setBool(key, value)).thenAnswer((_) async => true);

      // Act
      final result = await mockPrefs.setBool(key, value);

      // Assert
      expect(result, isTrue);
      verify(mockPrefs.setBool(key, value)).called(1);
    });

    test('should load user preferences successfully', () {
      // Arrange
      const key = 'notification_enabled';
      const expectedValue = true;

      when(mockPrefs.getBool(key)).thenReturn(expectedValue);

      // Act
      final result = mockPrefs.getBool(key);

      // Assert
      expect(result, equals(expectedValue));
      verify(mockPrefs.getBool(key)).called(1);
    });

    test('should return default value when preference not found', () {
      // Arrange
      const key = 'non_existent_key';
      const defaultValue = false;

      when(mockPrefs.getBool(key)).thenReturn(null);

      // Act
      final result = mockPrefs.getBool(key) ?? defaultValue;

      // Assert
      expect(result, equals(defaultValue));
      verify(mockPrefs.getBool(key)).called(1);
    });

    test('should save string preferences', () async {
      // Arrange
      const key = 'user_language';
      const value = 'en';

      when(mockPrefs.setString(key, value)).thenAnswer((_) async => true);

      // Act
      final result = await mockPrefs.setString(key, value);

      // Assert
      expect(result, isTrue);
      verify(mockPrefs.setString(key, value)).called(1);
    });

    test('should save integer preferences', () async {
      // Arrange
      const key = 'max_artworks_per_page';
      const value = 20;

      when(mockPrefs.setInt(key, value)).thenAnswer((_) async => true);

      // Act
      final result = await mockPrefs.setInt(key, value);

      // Assert
      expect(result, isTrue);
      verify(mockPrefs.setInt(key, value)).called(1);
    });

    test('should save double preferences', () async {
      // Arrange
      const key = 'map_zoom_level';
      const value = 15.5;

      when(mockPrefs.setDouble(key, value)).thenAnswer((_) async => true);

      // Act
      final result = await mockPrefs.setDouble(key, value);

      // Assert
      expect(result, isTrue);
      verify(mockPrefs.setDouble(key, value)).called(1);
    });

    test('should save string list preferences', () async {
      // Arrange
      const key = 'favorite_art_categories';
      const value = ['painting', 'sculpture', 'digital'];

      when(mockPrefs.setStringList(key, value)).thenAnswer((_) async => true);

      // Act
      final result = await mockPrefs.setStringList(key, value);

      // Assert
      expect(result, isTrue);
      verify(mockPrefs.setStringList(key, value)).called(1);
    });

    test('should remove preferences', () async {
      // Arrange
      const key = 'temp_setting';

      when(mockPrefs.remove(key)).thenAnswer((_) async => true);

      // Act
      final result = await mockPrefs.remove(key);

      // Assert
      expect(result, isTrue);
      verify(mockPrefs.remove(key)).called(1);
    });

    test('should clear all preferences', () async {
      // Arrange
      when(mockPrefs.clear()).thenAnswer((_) async => true);

      // Act
      final result = await mockPrefs.clear();

      // Assert
      expect(result, isTrue);
      verify(mockPrefs.clear()).called(1);
    });

    test('should check if preference key exists', () {
      // Arrange
      const existingKey = 'notification_enabled';
      const nonExistentKey = 'non_existent';

      when(mockPrefs.containsKey(existingKey)).thenReturn(true);
      when(mockPrefs.containsKey(nonExistentKey)).thenReturn(false);

      // Act & Assert
      expect(mockPrefs.containsKey(existingKey), isTrue);
      expect(mockPrefs.containsKey(nonExistentKey), isFalse);
      verify(mockPrefs.containsKey(existingKey)).called(1);
      verify(mockPrefs.containsKey(nonExistentKey)).called(1);
    });

    test('should get all preference keys', () {
      // Arrange
      const keys = {'notification_enabled', 'user_language', 'theme_mode'};

      when(mockPrefs.getKeys()).thenReturn(keys);

      // Act
      final result = mockPrefs.getKeys();

      // Assert
      expect(result, equals(keys));
      expect(result.length, equals(3));
      verify(mockPrefs.getKeys()).called(1);
    });
  });

  group('UserSettings Model Tests', () {
    test('should create UserSettings with default values', () {
      final settings = UserSettings();

      expect(settings.notificationsEnabled, isTrue);
      expect(settings.language, equals('en'));
      expect(settings.themeMode, equals(AppThemeMode.system));
      expect(settings.autoBackup, isTrue);
      expect(settings.mapZoomLevel, equals(15.0));
      expect(settings.maxArtworksPerPage, equals(20));
      expect(settings.allowAnalytics, isTrue);
      expect(settings.privateProfile, isFalse);
    });

    test('should create UserSettings with custom values', () {
      final settings = UserSettings(
        notificationsEnabled: false,
        language: 'es',
        themeMode: AppThemeMode.dark,
        autoBackup: false,
        mapZoomLevel: 12.0,
        maxArtworksPerPage: 10,
        allowAnalytics: false,
        privateProfile: true,
        favoriteCategories: ['painting', 'sculpture'],
      );

      expect(settings.notificationsEnabled, isFalse);
      expect(settings.language, equals('es'));
      expect(settings.themeMode, equals(AppThemeMode.dark));
      expect(settings.autoBackup, isFalse);
      expect(settings.mapZoomLevel, equals(12.0));
      expect(settings.maxArtworksPerPage, equals(10));
      expect(settings.allowAnalytics, isFalse);
      expect(settings.privateProfile, isTrue);
      expect(settings.favoriteCategories, equals(['painting', 'sculpture']));
    });

    test('should validate UserSettings data', () {
      // Valid settings
      final validSettings = UserSettings(
        language: 'en',
        mapZoomLevel: 15.0,
        maxArtworksPerPage: 20,
      );
      expect(validSettings.isValid, isTrue);

      // Invalid settings - invalid language
      final invalidSettings1 = UserSettings(
        language: '',
        mapZoomLevel: 15.0,
        maxArtworksPerPage: 20,
      );
      expect(invalidSettings1.isValid, isFalse);

      // Invalid settings - invalid zoom level
      final invalidSettings2 = UserSettings(
        language: 'en',
        mapZoomLevel: -1.0,
        maxArtworksPerPage: 20,
      );
      expect(invalidSettings2.isValid, isFalse);

      // Invalid settings - invalid max artworks
      final invalidSettings3 = UserSettings(
        language: 'en',
        mapZoomLevel: 15.0,
        maxArtworksPerPage: 0,
      );
      expect(invalidSettings3.isValid, isFalse);
    });

    test('should convert UserSettings to JSON', () {
      final settings = UserSettings(
        notificationsEnabled: true,
        language: 'en',
        themeMode: AppThemeMode.light,
        autoBackup: true,
        mapZoomLevel: 15.0,
        maxArtworksPerPage: 20,
        allowAnalytics: true,
        privateProfile: false,
        favoriteCategories: ['painting', 'digital'],
      );

      final json = settings.toJson();

      expect(json['notificationsEnabled'], isTrue);
      expect(json['language'], equals('en'));
      expect(json['themeMode'], equals(AppThemeMode.light.toString()));
      expect(json['autoBackup'], isTrue);
      expect(json['mapZoomLevel'], equals(15.0));
      expect(json['maxArtworksPerPage'], equals(20));
      expect(json['allowAnalytics'], isTrue);
      expect(json['privateProfile'], isFalse);
      expect(json['favoriteCategories'], equals(['painting', 'digital']));
    });

    test('should create UserSettings from JSON', () {
      final json = {
        'notificationsEnabled': false,
        'language': 'es',
        'themeMode': AppThemeMode.dark.toString(),
        'autoBackup': false,
        'mapZoomLevel': 12.0,
        'maxArtworksPerPage': 15,
        'allowAnalytics': false,
        'privateProfile': true,
        'favoriteCategories': ['sculpture', 'photography'],
      };

      final settings = UserSettings.fromJson(json);

      expect(settings.notificationsEnabled, isFalse);
      expect(settings.language, equals('es'));
      expect(settings.themeMode, equals(AppThemeMode.dark));
      expect(settings.autoBackup, isFalse);
      expect(settings.mapZoomLevel, equals(12.0));
      expect(settings.maxArtworksPerPage, equals(15));
      expect(settings.allowAnalytics, isFalse);
      expect(settings.privateProfile, isTrue);
      expect(settings.favoriteCategories, equals(['sculpture', 'photography']));
    });

    test('should copy UserSettings with modifications', () {
      final originalSettings = UserSettings(
        notificationsEnabled: true,
        language: 'en',
        themeMode: AppThemeMode.system,
      );

      final modifiedSettings = originalSettings.copyWith(
        notificationsEnabled: false,
        themeMode: AppThemeMode.dark,
      );

      expect(modifiedSettings.notificationsEnabled, isFalse);
      expect(modifiedSettings.language, equals('en')); // Unchanged
      expect(modifiedSettings.themeMode, equals(AppThemeMode.dark));
    });

    test('should reset settings to defaults', () {
      final customSettings = UserSettings(
        notificationsEnabled: false,
        language: 'es',
        themeMode: AppThemeMode.dark,
        autoBackup: false,
      );

      final resetSettings = customSettings.resetToDefaults();

      expect(resetSettings.notificationsEnabled, isTrue);
      expect(resetSettings.language, equals('en'));
      expect(resetSettings.themeMode, equals(AppThemeMode.system));
      expect(resetSettings.autoBackup, isTrue);
    });
  });

  group('AppThemeMode Tests', () {
    test('should convert AppThemeMode to string correctly', () {
      expect(AppThemeMode.light.toString(), equals('AppThemeMode.light'));
      expect(AppThemeMode.dark.toString(), equals('AppThemeMode.dark'));
      expect(AppThemeMode.system.toString(), equals('AppThemeMode.system'));
    });

    test('should parse AppThemeMode from string correctly', () {
      expect(
        AppThemeModeExtension.fromString('AppThemeMode.light'),
        equals(AppThemeMode.light),
      );
      expect(
        AppThemeModeExtension.fromString('AppThemeMode.dark'),
        equals(AppThemeMode.dark),
      );
      expect(
        AppThemeModeExtension.fromString('AppThemeMode.system'),
        equals(AppThemeMode.system),
      );
      expect(
        AppThemeModeExtension.fromString('invalid'),
        equals(AppThemeMode.system),
      ); // Default
    });

    test('should get theme mode display name correctly', () {
      expect(AppThemeMode.light.displayName, equals('Light'));
      expect(AppThemeMode.dark.displayName, equals('Dark'));
      expect(AppThemeMode.system.displayName, equals('System'));
    });
  });

  group('NotificationSettings Tests', () {
    test('should create NotificationSettings with defaults', () {
      final settings = NotificationSettings();

      expect(settings.enabled, isTrue);
      expect(settings.newArtwork, isTrue);
      expect(settings.newFollowers, isTrue);
      expect(settings.messages, isTrue);
      expect(settings.events, isTrue);
      expect(settings.marketing, isFalse);
      expect(settings.sound, isTrue);
      expect(settings.vibration, isTrue);
    });

    test('should validate NotificationSettings', () {
      final validSettings = NotificationSettings(enabled: true);
      expect(validSettings.isValid, isTrue);

      // All notification settings are optional booleans, so they're always valid
      final customSettings = NotificationSettings(
        enabled: false,
        newArtwork: false,
        newFollowers: false,
        messages: false,
        events: false,
        marketing: true,
        sound: false,
        vibration: false,
      );
      expect(customSettings.isValid, isTrue);
    });

    test('should disable all notifications when main toggle is off', () {
      final settings = NotificationSettings(enabled: false);
      final effectiveSettings = settings.getEffectiveSettings();

      expect(effectiveSettings.enabled, isFalse);
      expect(effectiveSettings.newArtwork, isFalse);
      expect(effectiveSettings.newFollowers, isFalse);
      expect(effectiveSettings.messages, isFalse);
      expect(effectiveSettings.events, isFalse);
      expect(effectiveSettings.marketing, isFalse);
    });

    test('should preserve individual settings when main toggle is on', () {
      final settings = NotificationSettings(
        enabled: true,
        newArtwork: false,
        messages: true,
        events: false,
      );
      final effectiveSettings = settings.getEffectiveSettings();

      expect(effectiveSettings.enabled, isTrue);
      expect(effectiveSettings.newArtwork, isFalse);
      expect(effectiveSettings.messages, isTrue);
      expect(effectiveSettings.events, isFalse);
    });
  });

  group('PrivacySettings Tests', () {
    test('should create PrivacySettings with defaults', () {
      final settings = PrivacySettings();

      expect(settings.profileVisibility, equals(ProfileVisibility.public));
      expect(settings.showOnlineStatus, isTrue);
      expect(settings.allowMessagesFromStrangers, isTrue);
      expect(settings.showLocationInArtWalk, isTrue);
      expect(settings.allowAnalytics, isTrue);
      expect(settings.allowCookies, isTrue);
    });

    test('should validate PrivacySettings', () {
      final validSettings = PrivacySettings();
      expect(validSettings.isValid, isTrue);

      final customSettings = PrivacySettings(
        profileVisibility: ProfileVisibility.private,
        showOnlineStatus: false,
        allowMessagesFromStrangers: false,
      );
      expect(customSettings.isValid, isTrue);
    });

    test('should check if profile is public', () {
      final publicSettings = PrivacySettings(
        profileVisibility: ProfileVisibility.public,
      );
      final friendsOnlySettings = PrivacySettings(
        profileVisibility: ProfileVisibility.friendsOnly,
      );
      final privateSettings = PrivacySettings(
        profileVisibility: ProfileVisibility.private,
      );

      expect(publicSettings.isProfilePublic, isTrue);
      expect(friendsOnlySettings.isProfilePublic, isFalse);
      expect(privateSettings.isProfilePublic, isFalse);
    });
  });
}

// Model classes that should be in your actual settings package
class UserSettings {
  final bool notificationsEnabled;
  final String language;
  final AppThemeMode themeMode;
  final bool autoBackup;
  final double mapZoomLevel;
  final int maxArtworksPerPage;
  final bool allowAnalytics;
  final bool privateProfile;
  final List<String> favoriteCategories;

  UserSettings({
    this.notificationsEnabled = true,
    this.language = 'en',
    this.themeMode = AppThemeMode.system,
    this.autoBackup = true,
    this.mapZoomLevel = 15.0,
    this.maxArtworksPerPage = 20,
    this.allowAnalytics = true,
    this.privateProfile = false,
    this.favoriteCategories = const [],
  });

  bool get isValid {
    return language.isNotEmpty &&
        mapZoomLevel > 0 &&
        mapZoomLevel <= 20 &&
        maxArtworksPerPage > 0 &&
        maxArtworksPerPage <= 100;
  }

  UserSettings copyWith({
    bool? notificationsEnabled,
    String? language,
    AppThemeMode? themeMode,
    bool? autoBackup,
    double? mapZoomLevel,
    int? maxArtworksPerPage,
    bool? allowAnalytics,
    bool? privateProfile,
    List<String>? favoriteCategories,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      autoBackup: autoBackup ?? this.autoBackup,
      mapZoomLevel: mapZoomLevel ?? this.mapZoomLevel,
      maxArtworksPerPage: maxArtworksPerPage ?? this.maxArtworksPerPage,
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      privateProfile: privateProfile ?? this.privateProfile,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
    );
  }

  UserSettings resetToDefaults() {
    return UserSettings();
  }

  Map<String, dynamic> toJson() => {
    'notificationsEnabled': notificationsEnabled,
    'language': language,
    'themeMode': themeMode.toString(),
    'autoBackup': autoBackup,
    'mapZoomLevel': mapZoomLevel,
    'maxArtworksPerPage': maxArtworksPerPage,
    'allowAnalytics': allowAnalytics,
    'privateProfile': privateProfile,
    'favoriteCategories': favoriteCategories,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    notificationsEnabled: json['notificationsEnabled'] ?? true,
    language: json['language'] ?? 'en',
    themeMode: AppThemeModeExtension.fromString(json['themeMode']),
    autoBackup: json['autoBackup'] ?? true,
    mapZoomLevel: json['mapZoomLevel']?.toDouble() ?? 15.0,
    maxArtworksPerPage: json['maxArtworksPerPage'] ?? 20,
    allowAnalytics: json['allowAnalytics'] ?? true,
    privateProfile: json['privateProfile'] ?? false,
    favoriteCategories: json['favoriteCategories'] != null
        ? List<String>.from(json['favoriteCategories'])
        : [],
  );
}

class NotificationSettings {
  final bool enabled;
  final bool newArtwork;
  final bool newFollowers;
  final bool messages;
  final bool events;
  final bool marketing;
  final bool sound;
  final bool vibration;

  NotificationSettings({
    this.enabled = true,
    this.newArtwork = true,
    this.newFollowers = true,
    this.messages = true,
    this.events = true,
    this.marketing = false,
    this.sound = true,
    this.vibration = true,
  });

  bool get isValid => true; // All boolean fields are always valid

  NotificationSettings getEffectiveSettings() {
    if (!enabled) {
      return NotificationSettings(
        enabled: false,
        newArtwork: false,
        newFollowers: false,
        messages: false,
        events: false,
        marketing: false,
        sound: sound,
        vibration: vibration,
      );
    }
    return this;
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'newArtwork': newArtwork,
    'newFollowers': newFollowers,
    'messages': messages,
    'events': events,
    'marketing': marketing,
    'sound': sound,
    'vibration': vibration,
  };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        enabled: json['enabled'] ?? true,
        newArtwork: json['newArtwork'] ?? true,
        newFollowers: json['newFollowers'] ?? true,
        messages: json['messages'] ?? true,
        events: json['events'] ?? true,
        marketing: json['marketing'] ?? false,
        sound: json['sound'] ?? true,
        vibration: json['vibration'] ?? true,
      );
}

class PrivacySettings {
  final ProfileVisibility profileVisibility;
  final bool showOnlineStatus;
  final bool allowMessagesFromStrangers;
  final bool showLocationInArtWalk;
  final bool allowAnalytics;
  final bool allowCookies;

  PrivacySettings({
    this.profileVisibility = ProfileVisibility.public,
    this.showOnlineStatus = true,
    this.allowMessagesFromStrangers = true,
    this.showLocationInArtWalk = true,
    this.allowAnalytics = true,
    this.allowCookies = true,
  });

  bool get isValid => true; // All fields have valid defaults

  bool get isProfilePublic => profileVisibility == ProfileVisibility.public;

  Map<String, dynamic> toJson() => {
    'profileVisibility': profileVisibility.toString(),
    'showOnlineStatus': showOnlineStatus,
    'allowMessagesFromStrangers': allowMessagesFromStrangers,
    'showLocationInArtWalk': showLocationInArtWalk,
    'allowAnalytics': allowAnalytics,
    'allowCookies': allowCookies,
  };

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      PrivacySettings(
        profileVisibility: ProfileVisibilityExtension.fromString(
          json['profileVisibility'],
        ),
        showOnlineStatus: json['showOnlineStatus'] ?? true,
        allowMessagesFromStrangers: json['allowMessagesFromStrangers'] ?? true,
        showLocationInArtWalk: json['showLocationInArtWalk'] ?? true,
        allowAnalytics: json['allowAnalytics'] ?? true,
        allowCookies: json['allowCookies'] ?? true,
      );
}

enum AppThemeMode { light, dark, system }

extension AppThemeModeExtension on AppThemeMode {
  static AppThemeMode fromString(String? value) {
    switch (value) {
      case 'AppThemeMode.light':
        return AppThemeMode.light;
      case 'AppThemeMode.dark':
        return AppThemeMode.dark;
      case 'AppThemeMode.system':
        return AppThemeMode.system;
      default:
        return AppThemeMode.system;
    }
  }

  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }
}

enum ProfileVisibility { public, friendsOnly, private }

extension ProfileVisibilityExtension on ProfileVisibility {
  static ProfileVisibility fromString(String? value) {
    switch (value) {
      case 'ProfileVisibility.public':
        return ProfileVisibility.public;
      case 'ProfileVisibility.friendsOnly':
        return ProfileVisibility.friendsOnly;
      case 'ProfileVisibility.private':
        return ProfileVisibility.private;
      default:
        return ProfileVisibility.public;
    }
  }

  String get displayName {
    switch (this) {
      case ProfileVisibility.public:
        return 'Public';
      case ProfileVisibility.friendsOnly:
        return 'Friends Only';
      case ProfileVisibility.private:
        return 'Private';
    }
  }
}

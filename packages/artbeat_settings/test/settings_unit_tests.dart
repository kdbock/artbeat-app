import 'package:flutter_test/flutter_test.dart';

import '../lib/src/models/models.dart';
import '../lib/src/utils/performance_monitor.dart';
import '../lib/src/utils/settings_configuration.dart';

/// Unit tests for ARTbeat Settings components
/// Implementation Date: September 5, 2025
void main() {
  group('Settings Models Tests', () {
    group('UserSettingsModel', () {
      test('should create model with default values', () {
        final settings = UserSettingsModel.defaultSettings('user123');

        expect(settings.userId, equals('user123'));
        expect(settings.darkMode, isFalse);
        expect(settings.language, equals('en'));
        expect(settings.notificationsEnabled, isTrue);
        expect(settings.timezone, equals('UTC'));
      });

      test('should serialize to and from JSON', () {
        final original = UserSettingsModel.defaultSettings('user123');
        final json = original.toMap();
        final reconstructed = UserSettingsModel.fromMap(json);

        expect(reconstructed.userId, equals(original.userId));
        expect(reconstructed.darkMode, equals(original.darkMode));
        expect(reconstructed.language, equals(original.language));
      });

      test('should support copyWith modifications', () {
        final original = UserSettingsModel.defaultSettings('user123');
        final modified = original.copyWith(
          darkMode: true,
          notificationsEnabled: false,
        );

        expect(modified.darkMode, isTrue);
        expect(modified.notificationsEnabled, isFalse);
        // Other properties should remain unchanged
        expect(modified.userId, equals(original.userId));
        expect(modified.language, equals(original.language));
      });

      test('should validate model correctness', () {
        final valid = UserSettingsModel.defaultSettings('user123');
        expect(valid.isValid(), isTrue);

        final invalid = UserSettingsModel(
          userId: '', // Empty userId should make it invalid
          darkMode: false,
          notificationsEnabled: true,
          language: 'en',
          timezone: 'UTC',
          notificationPreferences: {},
          privacySettings: {},
          securitySettings: {},
          blockedUsers: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(invalid.isValid(), isFalse);
      });
    });

    group('NotificationSettingsModel', () {
      test('should create model with default values', () {
        final settings = NotificationSettingsModel.defaultSettings('user123');

        expect(settings.userId, equals('user123'));
        expect(settings.push.enabled, isTrue);
        expect(settings.email.enabled, isTrue);
        expect(settings.inApp.enabled, isTrue);
        expect(settings.push.types.likes, isTrue);
        expect(settings.push.types.comments, isTrue);
        expect(settings.push.types.follows, isTrue);
      });

      test('should serialize correctly', () {
        final original = NotificationSettingsModel.defaultSettings('user123');
        final json = original.toMap();
        final reconstructed = NotificationSettingsModel.fromMap(json);

        expect(reconstructed.userId, equals(original.userId));
        expect(reconstructed.push.enabled, equals(original.push.enabled));
        expect(reconstructed.email.enabled, equals(original.email.enabled));
      });

      test('should validate model', () {
        final valid = NotificationSettingsModel.defaultSettings('user123');
        expect(valid.isValid(), isTrue);

        final invalid = NotificationSettingsModel(
          userId: '', // Empty userId
          email: EmailNotificationSettings.defaultSettings(),
          push: PushNotificationSettings.defaultSettings(),
          inApp: InAppNotificationSettings.defaultSettings(),
          quietHours: QuietHoursSettings.defaultSettings(),
          updatedAt: DateTime.now(),
        );
        expect(invalid.isValid(), isFalse);
      });
    });

    group('BlockedUserModel', () {
      test('should create and serialize blocked user model', () {
        final blockedUser = BlockedUserModel(
          blockedUserId: 'blocked123',
          blockedUserName: 'Blocked User',
          blockedUserProfileImage: 'https://example.com/avatar.jpg',
          reason: 'Spam',
          blockedAt: DateTime.now(),
          blockedBy: 'user123',
        );

        expect(blockedUser.blockedUserId, equals('blocked123'));
        expect(blockedUser.blockedUserName, equals('Blocked User'));
        expect(blockedUser.reason, equals('Spam'));
        expect(blockedUser.blockedBy, equals('user123'));

        final json = blockedUser.toMap();
        final reconstructed = BlockedUserModel.fromMap(json);

        expect(reconstructed.blockedUserId, equals(blockedUser.blockedUserId));
        expect(
          reconstructed.blockedUserName,
          equals(blockedUser.blockedUserName),
        );
        expect(reconstructed.reason, equals(blockedUser.reason));
      });
    });
  });

  group('Performance Monitor Tests', () {
    late SettingsPerformanceMonitor monitor;

    setUp(() {
      monitor = SettingsPerformanceMonitor();
      monitor.reset(); // Ensure clean state
    });

    test('should track operation timing', () {
      monitor.startOperation('testOperation');
      // Simulate some work
      monitor.endOperation('testOperation');

      expect(monitor.getOperationCount('testOperation'), equals(1));
      expect(monitor.getAverageOperationTime('testOperation'), greaterThan(0));
    });

    test('should track cache hits and misses', () {
      monitor.recordCacheHit();
      monitor.recordCacheHit();
      monitor.recordCacheMiss();

      expect(monitor.getCacheHitRatio(), equals(2 / 3));
    });

    test('should provide performance metrics', () {
      monitor.recordCacheHit();
      monitor.recordCacheMiss();
      monitor.startOperation('op1');
      monitor.endOperation('op1');

      final metrics = monitor.getPerformanceMetrics();
      expect(metrics, isA<Map<String, dynamic>>());
      expect(metrics['totalCacheHits'], equals(1));
      expect(metrics['totalCacheMisses'], equals(1));
      expect(metrics['cacheHitRatio'], equals(0.5));
      expect(metrics['operationMetrics'], isA<Map<String, dynamic>>());
    });

    test('should provide performance recommendations', () {
      // Simulate poor cache performance
      for (int i = 0; i < 10; i++) {
        monitor.recordCacheMiss();
      }
      monitor.recordCacheHit();

      final recommendations = monitor.getPerformanceRecommendations();
      expect(recommendations, isNotEmpty);
      expect(recommendations.first, contains('cache'));
    });

    test('should reset metrics', () {
      monitor.recordCacheHit();
      monitor.startOperation('test');
      monitor.endOperation('test');

      var metrics = monitor.getPerformanceMetrics();
      expect(metrics['totalCacheHits'], greaterThan(0));

      monitor.reset();

      metrics = monitor.getPerformanceMetrics();
      expect(metrics['totalCacheHits'], equals(0));
      expect(metrics['totalCacheMisses'], equals(0));
    });
  });

  group('Settings Configuration Tests', () {
    late SettingsConfiguration config;

    setUp(() {
      config = SettingsConfiguration();
      config.resetToDefaults();
    });

    test('should have sensible default values', () {
      expect(config.cacheExpiryDuration, equals(const Duration(minutes: 5)));
      expect(config.maxCacheSize, equals(100));
      expect(config.enablePersistentCache, isTrue);
      expect(config.networkTimeout, equals(const Duration(seconds: 30)));
      expect(config.maxRetryAttempts, equals(3));
      expect(config.enableRealtimeUpdates, isTrue);
    });

    test('should allow configuration updates', () {
      config.configureCaching(
        expiryDuration: const Duration(minutes: 10),
        maxCacheSize: 200,
        enablePersistentCache: false,
      );

      expect(config.cacheExpiryDuration, equals(const Duration(minutes: 10)));
      expect(config.maxCacheSize, equals(200));
      expect(config.enablePersistentCache, isFalse);
    });

    test('should support environment-specific configurations', () {
      config.configureForProduction();

      expect(config.enablePerformanceTracking, isFalse);
      expect(config.enableAnalytics, isTrue);
      expect(config.enableEncryptionAtRest, isTrue);

      config.configureForDevelopment();

      expect(config.enablePerformanceTracking, isTrue);
      expect(config.enableAnalytics, isFalse);
      expect(config.enableEncryptionAtRest, isFalse);

      config.configureForTesting();

      expect(config.enableRealtimeUpdates, isFalse);
      expect(config.cacheExpiryDuration, equals(const Duration(seconds: 1)));
      expect(config.maxRetryAttempts, equals(1));
    });

    test('should serialize and deserialize configuration', () {
      config.configureCaching(expiryDuration: const Duration(minutes: 15));
      config.configurePerformance(enableTracking: true);

      final json = config.toMap();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['cache']['expiryDuration'], equals(15 * 60 * 1000));

      final newConfig = SettingsConfiguration();
      newConfig.fromMap(json);

      expect(
        newConfig.cacheExpiryDuration,
        equals(const Duration(minutes: 15)),
      );
      expect(newConfig.enablePerformanceTracking, isTrue);
    });
  });

  group('Performance Tracking Mixin Tests', () {
    test('should track async operation performance', () async {
      final monitor = SettingsPerformanceMonitor();
      monitor.reset();

      final tracker = _TestTracker();

      final result = await tracker.measureOperation('testAsync', () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 'result';
      });

      expect(result, equals('result'));
      expect(monitor.getOperationCount('testAsync'), equals(1));
      expect(monitor.getAverageOperationTime('testAsync'), greaterThan(0));
    });

    test('should track sync operation performance', () {
      final monitor = SettingsPerformanceMonitor();
      monitor.reset();

      final tracker = _TestTracker();

      final result = tracker.measureSync('testSync', () {
        return 42;
      });

      expect(result, equals(42));
      expect(monitor.getOperationCount('testSync'), equals(1));
    });
  });
}

/// Test class that uses the PerformanceTrackingMixin
class _TestTracker with PerformanceTrackingMixin {
  // Mixin methods are automatically available
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import '../lib/src/services/integrated_settings_service.dart';

/// Integration tests for IntegratedSettingsService using fake implementations
/// Implementation Date: September 5, 2025
void main() {
  group('IntegratedSettingsService Integration Tests', () {
    late IntegratedSettingsService service;
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      mockUser = MockUser(
        uid: 'test_user_id',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      service = IntegratedSettingsService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      // Wait for service initialization
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      service.dispose();
    });

    group('User Settings', () {
      test('should create default settings when none exist', () async {
        final settings = await service.getUserSettings();

        expect(settings.userId, equals('test_user_id'));
        expect(settings.darkMode, isFalse);
        expect(settings.language, equals('en'));
        expect(settings.notificationsEnabled, isTrue);
        expect(settings.timezone, equals('UTC'));
      });

      test('should update user settings', () async {
        final originalSettings = await service.getUserSettings();
        final updatedSettings = originalSettings.copyWith(darkMode: true);

        await service.updateUserSettings(updatedSettings);

        // Fetch settings again to verify update
        final fetchedSettings = await service.getUserSettings();
        expect(fetchedSettings.darkMode, isTrue);
      });

      test('should cache settings for better performance', () async {
        // First call
        final startTime1 = DateTime.now();
        await service.getUserSettings();
        final duration1 = DateTime.now().difference(startTime1);

        // Second call should be faster due to caching
        final startTime2 = DateTime.now();
        await service.getUserSettings();
        final duration2 = DateTime.now().difference(startTime2);

        expect(duration2.inMicroseconds, lessThan(duration1.inMicroseconds));

        final metrics = service.performanceMetrics;
        expect(metrics['cacheHits'], equals(1));
        expect(metrics['cacheMisses'], equals(1));
      });
    });

    group('Notification Settings', () {
      test('should create default notification settings', () async {
        final settings = await service.getNotificationSettings();

        expect(settings.userId, equals('test_user_id'));
        expect(settings.push.enabled, isTrue);
        expect(settings.email.enabled, isTrue);
        expect(settings.inApp.enabled, isTrue);
        expect(settings.push.types.likes, isTrue);
        expect(settings.push.types.comments, isTrue);
        expect(settings.push.types.follows, isTrue);
      });

      test('should update notification settings', () async {
        final originalSettings = await service.getNotificationSettings();
        final updatedSettings = originalSettings.copyWith(
          push: originalSettings.push.copyWith(enabled: false),
          email: originalSettings.email.copyWith(enabled: false),
        );

        await service.updateNotificationSettings(updatedSettings);

        final fetchedSettings = await service.getNotificationSettings();
        expect(fetchedSettings.push.enabled, isFalse);
        expect(fetchedSettings.email.enabled, isFalse);
      });
    });

    group('Privacy Settings', () {
      test('should create default privacy settings', () async {
        final settings = await service.getPrivacySettings();

        expect(settings.userId, equals('test_user_id'));
        expect(settings.profile.visibility, equals('public'));
        expect(settings.profile.showLastSeen, isTrue);
        expect(settings.profile.showOnlineStatus, isTrue);
        expect(settings.content.allowComments, isTrue);
      });

      test('should update privacy settings', () async {
        final originalSettings = await service.getPrivacySettings();
        final updatedSettings = originalSettings.copyWith(
          profile: originalSettings.profile.copyWith(
            visibility: 'private',
            showOnlineStatus: false,
          ),
        );

        await service.updatePrivacySettings(updatedSettings);

        final fetchedSettings = await service.getPrivacySettings();
        expect(fetchedSettings.profile.visibility, equals('private'));
        expect(fetchedSettings.profile.showOnlineStatus, isFalse);
      });
    });

    group('Security Settings', () {
      test('should create default security settings', () async {
        final settings = await service.getSecuritySettings();

        expect(settings.userId, equals('test_user_id'));
        expect(settings.twoFactor.enabled, isFalse);
        expect(settings.login.allowLoginAlerts, isTrue);
        expect(settings.login.sessionTimeout, equals(30));
        expect(settings.devices.allowMultipleSessions, isTrue);
      });

      test('should update security settings', () async {
        final originalSettings = await service.getSecuritySettings();
        final updatedSettings = originalSettings.copyWith(
          twoFactor: originalSettings.twoFactor.copyWith(enabled: true),
          login: originalSettings.login.copyWith(sessionTimeout: 60),
        );

        await service.updateSecuritySettings(updatedSettings);

        final fetchedSettings = await service.getSecuritySettings();
        expect(fetchedSettings.twoFactor.enabled, isTrue);
        expect(fetchedSettings.login.sessionTimeout, equals(60));
      });
    });

    group('Account Settings', () {
      test('should create account settings from auth user', () async {
        final settings = await service.getAccountSettings();

        expect(settings.userId, equals('test_user_id'));
        expect(settings.email, equals('test@example.com'));
        expect(settings.displayName, equals('Test User'));
        expect(settings.emailVerified, isFalse);
        expect(settings.phoneVerified, isFalse);
      });

      test('should update account settings', () async {
        final originalSettings = await service.getAccountSettings();
        final updatedSettings = originalSettings.copyWith(
          username: 'testuser123',
          bio: 'Test user bio',
          phoneNumber: '+1234567890',
        );

        await service.updateAccountSettings(updatedSettings);

        final fetchedSettings = await service.getAccountSettings();
        expect(fetchedSettings.username, equals('testuser123'));
        expect(fetchedSettings.bio, equals('Test user bio'));
        expect(fetchedSettings.phoneNumber, equals('+1234567890'));
      });
    });

    group('Blocked Users Management', () {
      test('should start with empty blocked users list', () async {
        final blockedUsers = await service.getBlockedUsers();
        expect(blockedUsers, isEmpty);
      });

      test('should block and unblock users', () async {
        // Block a user
        await service.blockUser('blocked_user_id', 'Blocked User', 'Spam');

        final blockedUsers = await service.getBlockedUsers();
        expect(blockedUsers.length, equals(1));
        expect(blockedUsers.first.blockedUserId, equals('blocked_user_id'));
        expect(blockedUsers.first.blockedUserName, equals('Blocked User'));
        expect(blockedUsers.first.reason, equals('Spam'));
        expect(blockedUsers.first.blockedBy, equals('test_user_id'));

        // Unblock the user
        await service.unblockUser('blocked_user_id');

        final updatedBlockedUsers = await service.getBlockedUsers();
        expect(updatedBlockedUsers, isEmpty);
      });
    });

    group('Performance Metrics', () {
      test('should track performance metrics', () async {
        // Perform multiple operations
        await service.getUserSettings();
        await service.getNotificationSettings();
        await service.getUserSettings(); // This should be cached

        final metrics = service.performanceMetrics;
        expect(metrics, isA<Map<String, dynamic>>());
        expect(metrics.containsKey('cacheHits'), isTrue);
        expect(metrics.containsKey('cacheMisses'), isTrue);
        expect(metrics.containsKey('hitRatio'), isTrue);
        expect(metrics.containsKey('cachedItems'), isTrue);

        expect(metrics['cacheHits'], greaterThan(0));
        expect(metrics['cacheMisses'], greaterThan(0));
      });
    });

    group('GDPR Compliance', () {
      test('should handle data download requests', () async {
        // This should not throw
        await expectLater(service.requestDataDownload(), completes);

        // Verify request was stored in Firestore
        final collection = fakeFirestore.collection('dataRequests');
        final docs = await collection.get();
        expect(docs.docs.length, equals(1));

        final request = docs.docs.first.data();
        expect(request['userId'], equals('test_user_id'));
        expect(request['requestType'], equals('download'));
        expect(request['status'], equals('pending'));
      });

      test('should handle data deletion requests', () async {
        // This should not throw
        await expectLater(service.requestDataDeletion(), completes);

        // Verify request was stored in Firestore
        final collection = fakeFirestore.collection('dataRequests');
        final docs = await collection.get();
        expect(docs.docs.length, equals(1));

        final request = docs.docs.first.data();
        expect(request['userId'], equals('test_user_id'));
        expect(request['requestType'], equals('deletion'));
        expect(request['status'], equals('pending'));
      });
    });

    group('Preloading', () {
      test('should preload all settings efficiently', () async {
        final startTime = DateTime.now();
        await service.preloadAllSettings();
        final duration = DateTime.now().difference(startTime);

        // Should complete within reasonable time
        expect(duration.inSeconds, lessThan(5));

        // All settings should now be cached
        final metrics = service.performanceMetrics;
        expect(metrics['cachedItems'], greaterThan(0));
      });
    });

    group('Cache Management', () {
      test('should clear cache when requested', () async {
        // Load some data to populate cache
        await service.getUserSettings();
        await service.getNotificationSettings();

        var metrics = service.performanceMetrics;
        expect(metrics['cachedItems'], greaterThan(0));

        // Clear cache
        service.clearCache();

        metrics = service.performanceMetrics;
        expect(metrics['cachedItems'], equals(0));
      });
    });

    group('Error Handling', () {
      test('should handle unauthenticated users', () async {
        // Create service with no authenticated user
        final unauthenticatedAuth = MockFirebaseAuth(signedIn: false);
        final unauthenticatedService = IntegratedSettingsService(
          firestore: fakeFirestore,
          auth: unauthenticatedAuth,
        );

        await expectLater(
          unauthenticatedService.getUserSettings(),
          throwsA(isA<Exception>()),
        );

        unauthenticatedService.dispose();
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import '../lib/src/services/integrated_settings_service.dart';
import '../lib/src/models/models.dart';

/// Comprehensive test suite for IntegratedSettingsService
/// Implementation Date: September 5, 2025
void main() {
  group('IntegratedSettingsService', () {
    late IntegratedSettingsService service;
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockUser = MockUser(
        uid: 'test_user_id',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      mockAuth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);

      service = IntegratedSettingsService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );
    });

    tearDown(() {
      service.dispose();
    });

    group('Cache Management', () {
      test(
        'should return cached data when available and not expired',
        () async {
          // Setup test data in fake Firestore
          await fakeFirestore
              .collection('userSettings')
              .doc('test_user_id')
              .set({
                'userId': 'test_user_id',
                'theme': 'light',
                'language': 'en',
                'fontSize': 16.0,
                'enableAnimations': true,
                'enableHaptics': true,
                'enableSounds': true,
                'autoSave': true,
                'syncSettings': true,
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              });

          // First call should fetch from Firestore
          final settings1 = await service.getUserSettings();

          // Second call should use cache
          final settings2 = await service.getUserSettings();

          expect(settings1.userId, equals(settings2.userId));
          expect(settings1.language, equals('en'));
          expect(service.performanceMetrics['cacheHits'], equals(1));
        },
      );

      test('should clear cache when invalidated', () async {
        // Setup test data
        await fakeFirestore.collection('userSettings').doc('test_user_id').set({
          'userId': 'test_user_id',
          'theme': 'light',
          'language': 'en',
          'fontSize': 16.0,
          'enableAnimations': true,
          'enableHaptics': true,
          'enableSounds': true,
          'autoSave': true,
          'syncSettings': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // First call to populate cache
        await service.getUserSettings();

        // Clear cache
        service.clearCache();

        // Next call should fetch from Firestore again
        await service.getUserSettings();

        // Verify cache was cleared and data was fetched again
        expect(service.performanceMetrics['cacheMisses'], equals(2));
      });
    });

    group('User Settings Management', () {
      test(
        'should create default settings when document does not exist',
        () async {
          final settings = await service.getUserSettings();

          expect(settings.userId, equals('test_user_id'));
          expect(settings.darkMode, isFalse); // Default value

          // Verify document was created in Firestore
          final doc = await fakeFirestore
              .collection('userSettings')
              .doc('test_user_id')
              .get();
          expect(doc.exists, isTrue);
        },
      );

      test('should update user settings with optimistic updates', () async {
        final settings = UserSettingsModel.defaultSettings('test_user_id');
        final updatedSettings = settings.copyWith(darkMode: true);

        await service.updateUserSettings(updatedSettings);

        // Verify update was applied
        final doc = await fakeFirestore
            .collection('userSettings')
            .doc('test_user_id')
            .get();
        expect(doc.exists, isTrue);
        expect(doc.data()?['darkMode'], isTrue);
      });
    });

    group('Notification Settings', () {
      test('should get notification settings with caching', () async {
        // Setup test data
        await fakeFirestore
            .collection('notificationSettings')
            .doc('test_user_id')
            .set({
              'userId': 'test_user_id',
              'pushNotifications': true,
              'emailNotifications': true,
              'smsNotifications': false,
              'inAppNotifications': true,
              'artworkLikes': true,
              'artworkComments': true,
              'newFollowers': true,
              'eventReminders': true,
              'systemUpdates': false,
              'marketingEmails': false,
              'weeklyDigest': true,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            });

        final settings = await service.getNotificationSettings();

        expect(settings.userId, equals('test_user_id'));
        expect(settings.push.enabled, isTrue);
      });
    });

    group('Blocked Users Management', () {
      test('should get blocked users list', () async {
        final blockedUsers = await service.getBlockedUsers();

        expect(blockedUsers, isEmpty);
      });

      test('should block a user', () async {
        await service.blockUser('blocked_user_id', 'Blocked User', 'Spam');

        // Verify user was blocked
        final querySnapshot = await fakeFirestore
            .collection('blockedUsers')
            .where('blockedBy', isEqualTo: 'test_user_id')
            .get();

        expect(querySnapshot.docs.length, equals(1));
        expect(
          querySnapshot.docs.first.data()['blockedUserId'],
          equals('blocked_user_id'),
        );
      });

      test('should unblock a user', () async {
        // First block a user
        await service.blockUser('blocked_user_id', 'Blocked User', 'Spam');

        // Then unblock them
        await service.unblockUser('blocked_user_id');

        // Verify user was unblocked
        final querySnapshot = await fakeFirestore
            .collection('blockedUsers')
            .where('blockedBy', isEqualTo: 'test_user_id')
            .get();

        expect(querySnapshot.docs.length, equals(0));
      });
    });

    group('Performance Metrics', () {
      test('should track cache hit ratio', () async {
        // Setup test data
        await fakeFirestore.collection('userSettings').doc('test_user_id').set({
          'userId': 'test_user_id',
          'theme': 'light',
          'language': 'en',
          'fontSize': 16.0,
          'enableAnimations': true,
          'enableHaptics': true,
          'enableSounds': true,
          'autoSave': true,
          'syncSettings': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // First call (cache miss)
        await service.getUserSettings();

        // Second call (cache hit)
        await service.getUserSettings();

        final metrics = service.performanceMetrics;
        expect(metrics['cacheHits'], equals(1));
        expect(metrics['cacheMisses'], equals(1));
        expect(metrics['hitRatio'], equals(0.5));
      });
    });

    group('Error Handling', () {
      test('should handle authentication errors', () async {
        // Create service with signed out user
        final signedOutAuth = MockFirebaseAuth(signedIn: false);
        final unauthenticatedService = IntegratedSettingsService(
          firestore: fakeFirestore,
          auth: signedOutAuth,
        );

        expect(
          () => unauthenticatedService.getUserSettings(),
          throwsA(isA<Exception>()),
        );

        unauthenticatedService.dispose();
      });
    });

    group('GDPR Compliance', () {
      test('should request data download', () async {
        await service.requestDataDownload();

        // Verify request was created
        final querySnapshot = await fakeFirestore
            .collection('dataRequests')
            .where('userId', isEqualTo: 'test_user_id')
            .where('requestType', isEqualTo: 'download')
            .get();

        expect(querySnapshot.docs.length, equals(1));
      });

      test('should request data deletion', () async {
        await service.requestDataDeletion();

        // Verify request was created
        final querySnapshot = await fakeFirestore
            .collection('dataRequests')
            .where('userId', isEqualTo: 'test_user_id')
            .where('requestType', isEqualTo: 'deletion')
            .get();

        expect(querySnapshot.docs.length, equals(1));
      });
    });

    group('Preloading', () {
      test('should preload all settings efficiently', () async {
        await service.preloadAllSettings();

        // Verify all default settings were created
        final userDoc = await fakeFirestore
            .collection('userSettings')
            .doc('test_user_id')
            .get();
        final notificationDoc = await fakeFirestore
            .collection('notificationSettings')
            .doc('test_user_id')
            .get();
        final privacyDoc = await fakeFirestore
            .collection('privacySettings')
            .doc('test_user_id')
            .get();
        final securityDoc = await fakeFirestore
            .collection('securitySettings')
            .doc('test_user_id')
            .get();
        final accountDoc = await fakeFirestore
            .collection('users')
            .doc('test_user_id')
            .get();

        expect(userDoc.exists, isTrue);
        expect(notificationDoc.exists, isTrue);
        expect(privacyDoc.exists, isTrue);
        expect(securityDoc.exists, isTrue);
        expect(accountDoc.exists, isTrue);
      });
    });
  });
}

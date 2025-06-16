import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_core/src/models/subscription_model.dart';

void main() {
  group('Core Module Tests', () {
    group('User Model', () {
      test('UserModel can be instantiated with required properties', () {
        final now = DateTime.now();
        final user = UserModel(
          id: 'test-id',
          email: 'test@example.com',
          fullName: 'Test User',
          createdAt: now,
        );

        expect(user.id, equals('test-id'));
        expect(user.email, equals('test@example.com'));
        expect(user.fullName, equals('Test User'));
        expect(user.createdAt, equals(now));
      });

      test('UserModel optional properties are correctly initialized', () {
        final user = UserModel(
          id: 'test-id',
          email: 'test@example.com',
          fullName: 'Test User',
          createdAt: DateTime.now(),
          username: 'testuser',
          bio: 'Test bio',
        );

        expect(user.username, equals('testuser'));
        expect(user.bio, equals('Test bio'));
        expect(user.posts, isEmpty);
        expect(user.followers, isEmpty);
        expect(user.following, isEmpty);
        expect(user.postsCount, equals(0));
        expect(user.followersCount, equals(0));
        expect(user.followingCount, equals(0));
      });
    });

    group('ConnectivityService', () {
      test('ConnectivityService initializes with default values', () {
        final service = ConnectivityService();

        expect(service.connectionStatus, equals(ConnectionStatus.wifi));
        expect(service.isConnected, isTrue);
      });

      test('ConnectivityService can simulate connection changes', () {
        final service = ConnectivityService();

        service.simulateConnectionChange(ConnectionStatus.mobile);
        expect(service.connectionStatus, equals(ConnectionStatus.mobile));
        expect(service.isConnected, isTrue);
        expect(service.getConnectionType(), equals('Mobile Data'));

        service.simulateConnectionChange(ConnectionStatus.none);
        expect(service.connectionStatus, equals(ConnectionStatus.none));
        expect(service.isConnected, isFalse);
        expect(service.getConnectionType(), equals('None'));
      });
    });

    group('SubscriptionModel', () {
      test('SubscriptionModel can be instantiated with required properties',
          () {
        final now = DateTime.now();
        final subscription = SubscriptionModel(
          id: 'sub-id',
          userId: 'user-id',
          tier: SubscriptionTier
              .values.first, // Use first enum value to avoid hardcoding
          startDate: now,
          isActive: true,
          autoRenew: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.id, equals('sub-id'));
        expect(subscription.userId, equals('user-id'));
        expect(subscription.startDate, equals(now));
        expect(subscription.isActive, isTrue);
        expect(subscription.autoRenew, isTrue);
      });
    });
  });
}

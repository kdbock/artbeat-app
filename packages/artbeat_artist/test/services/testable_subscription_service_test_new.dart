import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show SubscriptionTier;
import 'package:artbeat_artist/src/models/subscription_model.dart';
import 'package:artbeat_artist/src/services/testable_subscription_service.dart';

// Create mocks for dependencies
@GenerateMocks([FirebaseAuth, User])
import 'testable_subscription_service_test_new.mocks.dart';

// Create a mock implementation of the Stripe API service
class MockStripeApiService implements IStripeApiService {
  Map<String, String> subscriptions = {};
  bool throwException = false;

  @override
  Future<Map<String, dynamic>> createSubscription(
      String customerId, String priceId) async {
    if (throwException) {
      throw Exception('Stripe API Error');
    }

    final subscriptionId = 'sub_${DateTime.now().millisecondsSinceEpoch}';
    subscriptions[subscriptionId] = priceId;
    return {
      'id': subscriptionId,
      'customer': customerId,
      'status': 'active',
      'current_period_end':
          DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch ~/ 1000,
    };
  }

  @override
  Future<Map<String, dynamic>> cancelSubscription(String subscriptionId) async {
    if (throwException) {
      throw Exception('Stripe API Error');
    }

    if (!subscriptions.containsKey(subscriptionId)) {
      throw Exception('Subscription not found');
    }
    subscriptions.remove(subscriptionId);
    return {
      'id': subscriptionId,
      'status': 'canceled',
      'canceled_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  @override
  Future<Map<String, dynamic>> updateSubscription(
      String subscriptionId, String newPriceId) async {
    if (throwException) {
      throw Exception('Stripe API Error');
    }

    if (!subscriptions.containsKey(subscriptionId)) {
      throw Exception('Subscription not found');
    }
    subscriptions[subscriptionId] = newPriceId;
    return {
      'id': subscriptionId,
      'status': 'active',
      'current_period_end':
          DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch ~/ 1000,
    };
  }
}

void main() {
  const testUserId = 'test-user-id';

  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockStripeApiService mockStripeApiService;
  late TestableSubscriptionService subscriptionService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockStripeApiService = MockStripeApiService();

    // Set up user auth mock
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(testUserId);

    // Create service with mocked dependencies
    subscriptionService = TestableSubscriptionService(
      firestore: fakeFirestore,
      auth: mockAuth,
      stripeApiService: mockStripeApiService,
    );
  });

  group('TestableSubscriptionService Tests', () {
    test('getCurrentUserId should return the current user ID', () {
      // Act
      final userId = subscriptionService.getCurrentUserId();

      // Assert
      expect(userId, testUserId);
    });

    test('getUserSubscription should return null if no subscription exists',
        () async {
      // Act
      final subscription = await subscriptionService.getUserSubscription();

      // Assert
      expect(subscription, isNull);
    });

    test('getUserSubscription should return subscription if one exists',
        () async {
      // Arrange - Create a test subscription in Firestore
      final subscriptionRef =
          fakeFirestore.collection('subscriptions').doc('test-subscription');
      await subscriptionRef.set({
        'id': 'test-subscription',
        'userId': testUserId,
        'tier': 'standard',
        'startDate':
            Timestamp.fromDate(DateTime.now().subtract(Duration(days: 10))),
        'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 20))),
        'stripeSubscriptionId': 'stripe-sub-123',
        'stripePriceId': 'price-standard-monthly',
        'stripeCustomerId': 'cus-123',
        'autoRenew': true,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Act
      final subscription = await subscriptionService.getUserSubscription();

      // Assert
      expect(subscription, isNotNull);
      expect(subscription!.id, 'test-subscription');
      expect(subscription.userId, testUserId);
      expect(subscription.tier, SubscriptionTier.artistPro);
      expect(subscription.autoRenew, isTrue);
      expect(subscription.isActive, isTrue);
    });

    test('getCurrentTier should return basic tier if no subscription exists',
        () async {
      // Act
      final tier = await subscriptionService.getCurrentTier();

      // Assert
      expect(tier, SubscriptionTier.artistBasic);
    });

    test('getCurrentTier should return correct tier if subscription exists',
        () async {
      // Arrange - Create a test subscription in Firestore
      final subscriptionRef =
          fakeFirestore.collection('subscriptions').doc('test-subscription');
      await subscriptionRef.set({
        'id': 'test-subscription',
        'userId': testUserId,
        'tier': 'standard',
        'startDate':
            Timestamp.fromDate(DateTime.now().subtract(Duration(days: 10))),
        'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 20))),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Act
      final tier = await subscriptionService.getCurrentTier();

      // Assert
      expect(tier, SubscriptionTier.artistPro);
    });

    test(
        'createSubscription should create a subscription in Firestore and Stripe',
        () async {
      // Arrange
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: 30));
      const stripePriceId = 'price-standard-monthly';
      const stripeCustomerId = 'cus-123';

      // Act
      final subscriptionId = await subscriptionService.createSubscription(
        userId: testUserId,
        tier: SubscriptionTier.artistPro,
        stripePriceId: stripePriceId,
        stripeCustomerId: stripeCustomerId,
        autoRenew: true,
        startDate: startDate,
        endDate: endDate,
      );

      // Assert
      expect(subscriptionId, isNotEmpty);

      // Verify Firestore document
      final docSnapshot = await fakeFirestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();
      expect(docSnapshot.exists, isTrue);
      expect(docSnapshot.data()?['userId'], testUserId);
      expect(docSnapshot.data()?['tier'], 'standard');
      expect(docSnapshot.data()?['autoRenew'], isTrue);

      // Verify Stripe API was called
      expect(mockStripeApiService.subscriptions.length, 1);
      final stripeSubId = mockStripeApiService.subscriptions.keys.first;
      expect(docSnapshot.data()?['stripeSubscriptionId'], stripeSubId);
    });

    test('cancelSubscription should update Firestore and cancel in Stripe',
        () async {
      // Arrange - Create a test subscription
      const stripeSubId = 'sub-123';
      final subscriptionRef =
          fakeFirestore.collection('subscriptions').doc('test-subscription');
      await subscriptionRef.set({
        'id': 'test-subscription',
        'userId': testUserId,
        'tier': 'standard',
        'stripeSubscriptionId': stripeSubId,
        'stripePriceId': 'price-standard-monthly',
        'stripeCustomerId': 'cus-123',
        'startDate':
            Timestamp.fromDate(DateTime.now().subtract(Duration(days: 10))),
        'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 20))),
        'autoRenew': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add to mock stripe API
      mockStripeApiService.subscriptions[stripeSubId] =
          'price-standard-monthly';

      // Act
      await subscriptionService.cancelSubscription('test-subscription');

      // Assert
      // Verify Firestore document was updated
      final updatedDoc = await fakeFirestore
          .collection('subscriptions')
          .doc('test-subscription')
          .get();
      expect(updatedDoc.data()?['autoRenew'], isFalse);
      expect(updatedDoc.data()?['canceledAt'], isNotNull);

      // Verify Stripe API was called
      expect(
          mockStripeApiService.subscriptions.containsKey(stripeSubId), isFalse);
    });

    test('upgradeSubscription should update tier and Stripe subscription',
        () async {
      // Arrange - Create a test subscription and artist profile
      const stripeSubId = 'sub-123';
      final subscriptionRef =
          fakeFirestore.collection('subscriptions').doc('test-subscription');
      await subscriptionRef.set({
        'id': 'test-subscription',
        'userId': testUserId,
        'tier': 'basic',
        'stripeSubscriptionId': stripeSubId,
        'stripePriceId': 'price-basic-monthly',
        'stripeCustomerId': 'cus-123',
        'startDate':
            Timestamp.fromDate(DateTime.now().subtract(Duration(days: 10))),
        'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 20))),
        'autoRenew': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create artist profile
      final artistProfileRef =
          fakeFirestore.collection('artistProfiles').doc('test-profile');
      await artistProfileRef.set({
        'userId': testUserId,
        'displayName': 'Test Artist',
        'subscriptionTier': 'free', // Basic tier API name
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add to mock stripe API
      mockStripeApiService.subscriptions[stripeSubId] = 'price-basic-monthly';

      // Act
      await subscriptionService.upgradeSubscription(
        subscriptionId: 'test-subscription',
        newTier: SubscriptionTier.artistPro,
        newStripePriceId: 'price-standard-monthly',
      );

      // Assert
      // Verify Firestore subscription document was updated
      final updatedDoc = await fakeFirestore
          .collection('subscriptions')
          .doc('test-subscription')
          .get();
      expect(updatedDoc.data()?['tier'], 'standard');
      expect(updatedDoc.data()?['stripePriceId'], 'price-standard-monthly');

      // Verify artist profile was updated
      final updatedProfile = await fakeFirestore
          .collection('artistProfiles')
          .doc('test-profile')
          .get();
      expect(updatedProfile.data()?['subscriptionTier'], 'standard');

      // Verify Stripe API was called
      expect(mockStripeApiService.subscriptions[stripeSubId],
          'price-standard-monthly');
    });

    test('getSubscriptionById should return subscription if it exists',
        () async {
      // Arrange - Create a test subscription
      final subscriptionRef =
          fakeFirestore.collection('subscriptions').doc('test-subscription-id');
      await subscriptionRef.set({
        'id': 'test-subscription-id',
        'userId': testUserId,
        'tier': 'standard',
        'startDate':
            Timestamp.fromDate(DateTime.now().subtract(Duration(days: 10))),
        'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 20))),
        'stripeSubscriptionId': 'stripe-sub-123',
        'stripePriceId': 'price-standard-monthly',
        'stripeCustomerId': 'cus-123',
        'autoRenew': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Act
      final subscription =
          await subscriptionService.getSubscriptionById('test-subscription-id');

      // Assert
      expect(subscription, isNotNull);
      expect(subscription!.id, 'test-subscription-id');
      expect(subscription.userId, testUserId);
      expect(subscription.tier, SubscriptionTier.artistPro);
    });

    test(
        'getSubscriptionById should return null if subscription does not exist',
        () async {
      // Act
      final subscription = await subscriptionService
          .getSubscriptionById('non-existent-subscription');

      // Assert
      expect(subscription, isNull);
    });

    test('createSubscription should handle Stripe API errors gracefully',
        () async {
      // Arrange - Set up the mock to throw an exception
      mockStripeApiService.throwException = true;

      // Act & Assert
      expect(
        () => subscriptionService.createSubscription(
          userId: testUserId,
          tier: SubscriptionTier.artistPro,
          stripePriceId: 'price-standard-monthly',
          stripeCustomerId: 'cus-123',
          autoRenew: true,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(Duration(days: 30)),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('cancelSubscription should throw exception if not authenticated',
        () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act & Assert
      expect(
        () => subscriptionService.cancelSubscription('any-subscription-id'),
        throwsA(isA<Exception>()),
      );
    });

    test(
        'cancelSubscription should throw exception if subscription does not exist',
        () async {
      // Act & Assert
      expect(
        () =>
            subscriptionService.cancelSubscription('non-existent-subscription'),
        throwsA(isA<Exception>()),
      );
    });

    test(
        'cancelSubscription should throw exception if user does not own subscription',
        () async {
      // Arrange - Create a subscription owned by someone else
      final subscriptionRef = fakeFirestore
          .collection('subscriptions')
          .doc('other-user-subscription');
      await subscriptionRef.set({
        'id': 'other-user-subscription',
        'userId': 'other-user-id', // Different user ID
        'tier': 'standard',
        'startDate':
            Timestamp.fromDate(DateTime.now().subtract(Duration(days: 10))),
        'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 20))),
        'stripeSubscriptionId': 'stripe-sub-456',
        'autoRenew': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Act & Assert
      expect(
        () => subscriptionService.cancelSubscription('other-user-subscription'),
        throwsA(isA<Exception>()),
      );
    });

    test('upgradeSubscription should throw exception if not authenticated',
        () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act & Assert
      expect(
        () => subscriptionService.upgradeSubscription(
          subscriptionId: 'any-subscription-id',
          newTier: SubscriptionTier.artistPro,
          newStripePriceId: 'price-premium-monthly',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
        'upgradeSubscription should throw exception if subscription does not exist',
        () async {
      // Act & Assert
      expect(
        () => subscriptionService.upgradeSubscription(
          subscriptionId: 'non-existent-subscription',
          newTier: SubscriptionTier.artistPro,
          newStripePriceId: 'price-premium-monthly',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
        'upgradeSubscription should throw exception if user does not own subscription',
        () async {
      // Arrange - Create a subscription owned by someone else
      final subscriptionRef = fakeFirestore
          .collection('subscriptions')
          .doc('other-user-subscription');
      await subscriptionRef.set({
        'id': 'other-user-subscription',
        'userId': 'other-user-id', // Different user ID
        'tier': 'standard',
        'startDate':
            Timestamp.fromDate(DateTime.now().subtract(Duration(days: 10))),
        'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 20))),
        'stripeSubscriptionId': 'stripe-sub-456',
        'autoRenew': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Act & Assert
      expect(
        () => subscriptionService.upgradeSubscription(
          subscriptionId: 'other-user-subscription',
          newTier: SubscriptionTier.artistPro,
          newStripePriceId: 'price-premium-monthly',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('isActive property works correctly on subscription model', () async {
      // Arrange - Create an active subscription
      final activeSubscription = SubscriptionModel(
        id: 'active-sub',
        userId: testUserId,
        tier: SubscriptionTier.artistPro,
        startDate: DateTime.now().subtract(Duration(days: 10)),
        endDate: DateTime.now().add(Duration(days: 20)),
        stripeSubscriptionId: 'stripe-sub-123',
        autoRenew: true,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now().subtract(Duration(days: 10)),
      );

      // Create an inactive subscription (past end date)
      final inactiveSubscription = SubscriptionModel(
        id: 'inactive-sub',
        userId: testUserId,
        tier: SubscriptionTier.artistPro,
        startDate: DateTime.now().subtract(Duration(days: 60)),
        endDate: DateTime.now().subtract(Duration(days: 30)),
        stripeSubscriptionId: 'stripe-sub-456',
        autoRenew: false,
        createdAt: DateTime.now().subtract(Duration(days: 60)),
        updatedAt: DateTime.now().subtract(Duration(days: 30)),
      );

      // Create a canceled subscription in grace period
      final canceledSubscription = SubscriptionModel(
        id: 'canceled-sub',
        userId: testUserId,
        tier: SubscriptionTier.artistPro,
        startDate: DateTime.now().subtract(Duration(days: 20)),
        endDate: DateTime.now().add(Duration(days: 10)),
        stripeSubscriptionId: 'stripe-sub-789',
        autoRenew: false,
        canceledAt: DateTime.now().subtract(Duration(days: 5)),
        createdAt: DateTime.now().subtract(Duration(days: 20)),
        updatedAt: DateTime.now().subtract(Duration(days: 5)),
      );

      // Assert
      expect(activeSubscription.isActive, isTrue);
      expect(inactiveSubscription.isActive, isFalse);
      expect(canceledSubscription.isActive, isFalse);
      expect(canceledSubscription.isGracePeriod, isTrue);

      expect(activeSubscription.status, 'active');
      expect(inactiveSubscription.status, 'inactive');

      expect(activeSubscription.daysRemaining, greaterThan(0));
      expect(inactiveSubscription.daysRemaining, 0);
    });
  });
}

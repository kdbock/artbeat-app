import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/src/models/subscription_tier.dart';
import 'package:artbeat_core/src/models/subscription_model.dart';

void main() {
  group('SubscriptionModel Tests', () {
    test('SubscriptionModel can be instantiated with required properties', () {
      final now = DateTime.now();
      final subscription = SubscriptionModel(
        id: 'sub-id',
        userId: 'user-id',
        tier: SubscriptionTier.values.first,
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
}

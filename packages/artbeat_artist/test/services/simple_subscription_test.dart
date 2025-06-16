import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/artbeat_core.dart';

void main() {
  group('Artist Subscription Basic Tests', () {
    test('SubscriptionTier enum has correct values', () {
      // Verify core subscription tier enum values
      expect(SubscriptionTier.artistBasic.name, equals('basic'));
      expect(SubscriptionTier.artistPro.name, equals('standard'));
      expect(SubscriptionTier.artistPro.name, equals('premium'));
    });

    test('SubscriptionTier apiName property returns correct values', () {
      // Verify API name mapping for subscription tiers
      expect(SubscriptionTier.artistBasic.apiName, equals('free'));
      expect(SubscriptionTier.artistPro.apiName, equals('standard'));
      expect(SubscriptionTier.artistPro.apiName, equals('premium'));
    });

    test('SubscriptionTier displayName property returns correct values', () {
      // Verify display name mapping for subscription tiers
      expect(SubscriptionTier.artistBasic.displayName, equals('Artist Basic'));
      expect(SubscriptionTier.artistPro.displayName, equals('Artist Pro'));
      expect(SubscriptionTier.artistPro.displayName, equals('Gallery'));
    });
  });
}

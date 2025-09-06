import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Test to verify 2025 optimization implementation
void main() {
  group('2025 Optimization Implementation Tests', () {
    test('SubscriptionTier 2025 pricing structure', () {
      // Test new 2025 pricing tiers
      expect(SubscriptionTier.free.monthlyPrice, equals(0.0));
      expect(SubscriptionTier.starter.monthlyPrice, equals(4.99));
      expect(SubscriptionTier.creator.monthlyPrice, equals(12.99));
      expect(SubscriptionTier.business.monthlyPrice, equals(29.99));
      expect(SubscriptionTier.enterprise.monthlyPrice, equals(79.99));
    });

    test('Legacy tier name conversion', () {
      // Test migration from legacy names
      expect(
        SubscriptionTier.fromLegacyName('artist_basic'),
        equals(SubscriptionTier.starter),
      );
      expect(
        SubscriptionTier.fromLegacyName('artist_pro'),
        equals(SubscriptionTier.creator),
      );
      expect(
        SubscriptionTier.fromLegacyName('business'),
        equals(SubscriptionTier.business),
      );
    });

    test('FeatureLimits usage-based system', () {
      // Test usage limits for different tiers
      final freeLimits = FeatureLimits.forTier(SubscriptionTier.free);
      expect(freeLimits.artworks, equals(3));
      expect(freeLimits.storageGB, equals(0.5));
      expect(freeLimits.aiCredits, equals(5));

      final creatorLimits = FeatureLimits.forTier(SubscriptionTier.creator);
      expect(creatorLimits.artworks, equals(100));
      expect(creatorLimits.storageGB, equals(25));
      expect(creatorLimits.aiCredits, equals(200));
      expect(creatorLimits.hasAdvancedAnalytics, isTrue);

      final enterpriseLimits = FeatureLimits.forTier(
        SubscriptionTier.enterprise,
      );
      expect(enterpriseLimits.hasUnlimitedArtworks, isTrue);
      expect(enterpriseLimits.hasUnlimitedStorage, isTrue);
      expect(enterpriseLimits.hasUnlimitedAICredits, isTrue);
    });

    test('Overage pricing calculations', () {
      final freeLimits = FeatureLimits.forTier(SubscriptionTier.free);

      // Test overage cost calculation
      final overageCost = freeLimits.calculateOverageCost(
        additionalArtworks: 2, // $0.99 each = $1.98
        additionalStorageGB: 1, // $0.49 = $0.49
        additionalAICredits: 10, // $0.05 each = $0.50
      );

      expect(overageCost, closeTo(2.97, 0.01)); // $1.98 + $0.49 + $0.50
    });

    test('Usage percentage tracking', () {
      final limits = FeatureLimits.forTier(SubscriptionTier.starter);

      // Test usage percentage calculation
      expect(
        limits.getUsagePercentage('artworks', 20),
        equals(0.8),
      ); // 20/25 = 80%
      expect(
        limits.isApproachingLimit('artworks', 20),
        isTrue,
      ); // 80% is approaching limit
      expect(
        limits.getRemainingQuota('artworks', 20),
        equals(5),
      ); // 25-20 = 5 remaining
    });

    test('Display strings and pricing', () {
      // Test display formatting
      expect(SubscriptionTier.free.priceString, equals('Free'));
      expect(SubscriptionTier.starter.priceString, equals('\$4.99/month'));
      expect(SubscriptionTier.creator.priceString, equals('\$12.99/month'));
      expect(SubscriptionTier.business.priceString, equals('\$29.99/month'));
      expect(SubscriptionTier.enterprise.priceString, equals('\$79.99/month'));
    });

    test('Feature availability checks', () {
      final businessLimits = FeatureLimits.forTier(SubscriptionTier.business);

      expect(businessLimits.hasAdvancedAnalytics, isTrue);
      expect(businessLimits.hasFeaturedPlacement, isTrue);
      expect(businessLimits.hasCustomBranding, isTrue);
      expect(businessLimits.hasAPIAccess, isTrue);
      expect(businessLimits.teamMembers, equals(5));
    });
  });
}

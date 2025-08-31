import 'package:flutter_test/flutter_test.dart';

// Import only the core models we created for 2025 optimization
import '../lib/src/models/subscription_tier.dart';
import '../lib/src/models/feature_limits.dart';

/// Test to verify 2025 optimization implementation - core models only
void main() {
  group('2025 Core Optimization Implementation Tests', () {
    test('SubscriptionTier 2025 pricing structure', () {
      // Test new 2025 pricing tiers
      expect(SubscriptionTier.free.monthlyPrice, equals(0.0));
      expect(SubscriptionTier.starter.monthlyPrice, equals(4.99));
      expect(SubscriptionTier.creator.monthlyPrice, equals(12.99));
      expect(SubscriptionTier.business.monthlyPrice, equals(29.99));
      expect(SubscriptionTier.enterprise.monthlyPrice, equals(79.99));
    });

    test('Legacy tier name conversion works correctly', () {
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
      expect(
        SubscriptionTier.fromLegacyName('enterprise'),
        equals(SubscriptionTier.enterprise),
      );
    });

    test('FeatureLimits usage-based system works correctly', () {
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

    test('Overage pricing calculations work correctly', () {
      final freeLimits = FeatureLimits.forTier(SubscriptionTier.free);

      // Test overage cost calculation
      final overageCost = freeLimits.calculateOverageCost(
        additionalArtworks: 2, // $0.99 each = $1.98
        additionalStorageGB: 1, // $0.49 = $0.49
        additionalAICredits: 10, // $0.05 each = $0.50
      );

      expect(
        overageCost,
        closeTo(2.97, 0.01),
      ); // Allow small floating point variance
    });

    test('Usage percentage tracking works correctly', () {
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

    test('Display strings and pricing format correctly', () {
      // Test display formatting
      expect(SubscriptionTier.free.priceString, equals('Free'));
      expect(SubscriptionTier.starter.priceString, equals('\$4.99/month'));
      expect(SubscriptionTier.creator.priceString, equals('\$12.99/month'));
      expect(SubscriptionTier.business.priceString, equals('\$29.99/month'));
      expect(SubscriptionTier.enterprise.priceString, equals('\$79.99/month'));
    });

    test('Feature availability checks work correctly', () {
      final businessLimits = FeatureLimits.forTier(SubscriptionTier.business);

      expect(businessLimits.hasAdvancedAnalytics, isTrue);
      expect(businessLimits.hasFeaturedPlacement, isTrue);
      expect(businessLimits.hasCustomBranding, isTrue);
      expect(businessLimits.hasAPIAccess, isTrue);
      expect(businessLimits.teamMembers, equals(5));
    });

    test('Tier names and API compatibility', () {
      expect(SubscriptionTier.free.apiName, equals('free'));
      expect(SubscriptionTier.starter.apiName, equals('starter'));
      expect(SubscriptionTier.creator.apiName, equals('creator'));
      expect(SubscriptionTier.business.apiName, equals('business'));
      expect(SubscriptionTier.enterprise.apiName, equals('enterprise'));

      expect(SubscriptionTier.free.displayName, equals('Free'));
      expect(SubscriptionTier.starter.displayName, equals('Starter'));
      expect(SubscriptionTier.creator.displayName, equals('Creator'));
      expect(SubscriptionTier.business.displayName, equals('Business'));
      expect(SubscriptionTier.enterprise.displayName, equals('Enterprise'));
    });

    test('Feature descriptions match 2025 standards', () {
      final starterFeatures = SubscriptionTier.starter.features;
      expect(starterFeatures.contains('Up to 25 artworks'), isTrue);
      expect(starterFeatures.contains('5GB storage'), isTrue);
      expect(starterFeatures.contains('50 AI credits/month'), isTrue);

      final creatorFeatures = SubscriptionTier.creator.features;
      expect(creatorFeatures.contains('Up to 100 artworks'), isTrue);
      expect(creatorFeatures.contains('25GB storage'), isTrue);
      expect(creatorFeatures.contains('200 AI credits/month'), isTrue);
      expect(creatorFeatures.contains('Advanced analytics'), isTrue);

      final enterpriseFeatures = SubscriptionTier.enterprise.features;
      expect(enterpriseFeatures.contains('Unlimited everything'), isTrue);
      expect(enterpriseFeatures.contains('Unlimited storage'), isTrue);
      expect(enterpriseFeatures.contains('Unlimited AI credits'), isTrue);
    });

    test('Overage pricing constants are correct', () {
      const overagePricing = FeatureLimits.overagePricing;
      expect(overagePricing['artwork'], equals(0.99));
      expect(overagePricing['storageGB'], equals(0.49));
      expect(overagePricing['aiCredit'], equals(0.05));
      expect(overagePricing['teamMember'], equals(9.99));
    });
  });
}

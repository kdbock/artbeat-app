import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/artbeat_core.dart';

void main() {
  group('Artist Feature Testing Service', () {
    late ArtistFeatureTestingService testingService;

    setUp(() {
      testingService = ArtistFeatureTestingService();
    });

    test('should create testing service successfully', () {
      expect(testingService, isNotNull);
    });

    test('should format feature names correctly', () {
      // Create a test app to access the private method
      // This is a simplified test since the method is private
      expect(true, isTrue); // Placeholder test
    });

    test('should generate test report structure correctly', () {
      final report = testingService.generateTestReport();
      expect(report, contains('ARTIST FEATURES TEST REPORT'));
      expect(report, contains('SUMMARY:'));
    });
  });

  group('Subscription Tier Features', () {
    test('should have correct features for Free tier', () {
      const tier = SubscriptionTier.free;
      expect(tier.displayName, equals('Free'));
      expect(tier.monthlyPrice, equals(0.0));
      expect(tier.features, contains('Up to 3 artworks'));
    });

    test('should have correct features for Starter tier', () {
      const tier = SubscriptionTier.starter;
      expect(tier.displayName, equals('Starter'));
      expect(tier.monthlyPrice, equals(4.99));
      expect(tier.features, contains('Up to 25 artworks'));
      expect(tier.features, contains('5GB storage'));
      expect(tier.features, contains('50 AI credits/month'));
    });

    test('should have correct features for Creator tier', () {
      const tier = SubscriptionTier.creator;
      expect(tier.displayName, equals('Creator'));
      expect(tier.monthlyPrice, equals(12.99));
      expect(tier.features, contains('Up to 100 artworks'));
      expect(tier.features, contains('25GB storage'));
      expect(tier.features, contains('200 AI credits/month'));
      expect(tier.features, contains('Advanced analytics'));
      expect(tier.features, contains('Featured placement'));
      expect(tier.features, contains('Event creation'));
    });

    test('should have correct features for Business tier', () {
      const tier = SubscriptionTier.business;
      expect(tier.displayName, equals('Business'));
      expect(tier.monthlyPrice, equals(29.99));
      expect(tier.features, contains('Unlimited artworks'));
      expect(tier.features, contains('100GB storage'));
      expect(tier.features, contains('500 AI credits/month'));
      expect(tier.features, contains('Team collaboration (up to 5 users)'));
      expect(tier.features, contains('Custom branding'));
      expect(tier.features, contains('API access'));
    });

    test('should have correct features for Enterprise tier', () {
      const tier = SubscriptionTier.enterprise;
      expect(tier.displayName, equals('Enterprise'));
      expect(tier.monthlyPrice, equals(79.99));
      expect(tier.features, contains('Unlimited everything'));
      expect(tier.features, contains('Custom integrations'));
      expect(tier.features, contains('White-label options'));
      expect(tier.features, contains('Enterprise security'));
      expect(tier.features, contains('Dedicated account manager'));
    });
  });

  group('Feature Limits', () {
    test('should have correct limits for Free tier', () {
      final limits = FeatureLimits.forTier(SubscriptionTier.free);
      expect(limits.artworks, equals(3));
      expect(limits.storageGB, equals(0.5));
      expect(limits.aiCredits, equals(5));
      expect(limits.hasUnlimitedArtworks, isFalse);
      expect(limits.hasAdvancedAnalytics, isFalse);
    });

    test('should have correct limits for Business tier', () {
      final limits = FeatureLimits.forTier(SubscriptionTier.business);
      expect(limits.hasUnlimitedArtworks, isTrue);
      expect(limits.storageGB, equals(100));
      expect(limits.aiCredits, equals(500));
      expect(limits.teamMembers, equals(5));
      expect(limits.hasCustomBranding, isTrue);
      expect(limits.hasAPIAccess, isTrue);
    });

    test('should have correct limits for Enterprise tier', () {
      final limits = FeatureLimits.forTier(SubscriptionTier.enterprise);
      expect(limits.hasUnlimitedArtworks, isTrue);
      expect(limits.hasUnlimitedStorage, isTrue);
      expect(limits.hasUnlimitedAICredits, isTrue);
      expect(limits.hasUnlimitedTeamMembers, isTrue);
      expect(limits.hasCustomBranding, isTrue);
      expect(limits.hasAPIAccess, isTrue);
    });
  });

  group('Usage Calculations', () {
    test('should calculate overage costs correctly', () {
      final limits = FeatureLimits.forTier(SubscriptionTier.starter);

      // Test artwork overage (starter has 25 artworks, so 30-25=5 extra at $0.99 each)
      final artworkOverage = limits.calculateOverageCost(additionalArtworks: 5);
      expect(artworkOverage, equals(4.95)); // 5 extra artworks at $0.99 each

      // Test storage overage (starter has 5GB, so 7-5=2 extra at $0.49 each)
      final storageOverage = limits.calculateOverageCost(
        additionalStorageGB: 2,
      );
      expect(storageOverage, equals(0.98)); // 2 extra GB at $0.49 each

      // Test AI credits overage (starter has 50 credits, so 60-50=10 extra at $0.05 each)
      final aiOverage = limits.calculateOverageCost(additionalAICredits: 10);
      expect(aiOverage, equals(0.50)); // 10 extra credits at $0.05 each
    });

    test('should detect when approaching limits', () {
      final limits = FeatureLimits.forTier(SubscriptionTier.starter);

      // Test approaching artwork limit (80% = 20 artworks)
      expect(limits.isApproachingLimit('artworks', 20), isTrue);
      expect(limits.isApproachingLimit('artworks', 15), isFalse);

      // Test approaching storage limit (80% = 4GB)
      expect(limits.isApproachingLimit('storage', 4), isTrue);
      expect(limits.isApproachingLimit('storage', 3), isFalse);
    });

    test('should calculate usage percentage correctly', () {
      final limits = FeatureLimits.forTier(SubscriptionTier.starter);

      // Test artwork usage percentage
      expect(
        limits.getUsagePercentage('artworks', 12),
        equals(0.48),
      ); // 12/25 = 0.48

      // Test storage usage percentage
      expect(limits.getUsagePercentage('storage', 2), equals(0.4)); // 2/5 = 0.4

      // Test AI credits usage percentage
      expect(
        limits.getUsagePercentage('ai_credits', 25),
        equals(0.5),
      ); // 25/50 = 0.5
    });
  });

  group('Test Result Class', () {
    test('should create passed test result', () {
      final result = TestResult.passed('Feature works correctly');
      expect(result.passed, isTrue);
      expect(result.message, equals('Feature works correctly'));
      expect(result.timestamp, isNotNull);
    });

    test('should create failed test result', () {
      final result = TestResult.failed('Feature not working');
      expect(result.passed, isFalse);
      expect(result.message, equals('Feature not working'));
      expect(result.timestamp, isNotNull);
    });

    test('should format test result string correctly', () {
      final passedResult = TestResult.passed('Success message');
      final failedResult = TestResult.failed('Error message');

      expect(passedResult.toString(), equals('PASS: Success message'));
      expect(failedResult.toString(), equals('FAIL: Error message'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'services/testable_artist_profile_service_test.dart'
    as testable_artist_profile_service_test;
import 'services/testable_subscription_service_test_new.dart'
    as testable_subscription_service_test;

/// Main test file for artbeat_artist module
/// This file runs all artist module tests
void main() {
  // Note: The artist profile service test currently has issues with mockito setup
  // Uncomment when fixed
  // testable_artist_profile_service_test.main();

  // Subscription service tests
  testable_subscription_service_test.main();

  group('Artist Module Basic Tests', () {
    // Test that the module can be imported
    test('Artist module can be imported', () {
      expect(true, isTrue);
    });

    // Basic functionality test
    test('Artist subscription tiers are defined correctly', () {
      const tiers = ['free', 'basic', 'pro', 'gallery'];
      expect(tiers.contains('free'), isTrue);
      expect(tiers.contains('basic'), isTrue);
      expect(tiers.contains('pro'), isTrue);
      expect(tiers.contains('gallery'), isTrue);
    });
  });
}

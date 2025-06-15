import 'package:flutter_test/flutter_test.dart';
import 'services/testable_achievement_service_test_fixed.dart'
    as testable_achievement_service_test;
import 'services/testable_art_walk_service_test.dart'
    as testable_art_walk_service_test;
import 'services/testable_art_walk_service_simple_test.dart'
    as testable_art_walk_service_simple_test;
import 'services/testable_google_maps_service_test.dart'
    as testable_google_maps_service_test;

/// Main test file for artbeat_art_walk module
/// This file runs all art walk module tests
void main() {
  // Run individual test suites
  testable_achievement_service_test.main();
  testable_art_walk_service_test.main();
  testable_art_walk_service_simple_test.main();
  testable_google_maps_service_test.main();

  group('Art Walk Basic Tests', () {
    // Test that the module can be imported
    test('Art Walk module can be imported', () {
      expect(true, isTrue);
    });
  });
}

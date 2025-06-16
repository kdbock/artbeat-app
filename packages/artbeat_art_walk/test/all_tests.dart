import 'package:flutter_test/flutter_test.dart';
import 'services/testable_achievement_service_test.dart' as achievement_test;
import 'services/testable_art_walk_service_test.dart' as art_walk_test;
import 'services/testable_google_maps_service_test.dart' as maps_test;

/// Main test file for artbeat_art_walk module
/// This file runs all art walk module tests
void main() {
  group('Achievement Service Tests', () {
    achievement_test.main();
  });

  group('Art Walk Service Tests', () {
    art_walk_test.main();
  });

  group('Google Maps Service Tests', () {
    maps_test.main();
  });

  group('Basic Tests', () {
    test('Art Walk module can be imported', () {
      expect(true, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'services/testable_achievement_service_test.dart' as achievement_test;
import 'services/testable_art_walk_service_test.dart' as art_walk_test;
import 'services/testable_google_maps_service_test.dart' as maps_test;

void main() {
  group('Art Walk Module Tests', () {
    achievement_test.main();
    art_walk_test.main();
    maps_test.main();
  });
}

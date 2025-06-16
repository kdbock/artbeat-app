import 'package:flutter_test/flutter_test.dart';

// Import our working test file
import 'core_unified_test.dart' as core_unified_test;
import 'services/enhanced_connectivity_service_test.dart'
    as enhanced_connectivity_test;

void main() {
  group('artbeat_core module', () {
    // Run all the working tests
    core_unified_test.main();
    enhanced_connectivity_test.main();
  });
}

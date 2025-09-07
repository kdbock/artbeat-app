import 'package:flutter_test/flutter_test.dart';

// Import working test files
import 'utils/ad_utils_test.dart' as ad_utils_tests;

/// Simple test runner for working tests
///
/// This file runs only the tests that are currently working
/// to demonstrate the testing infrastructure.
void main() {
  group('ARTbeat Ads - Working Tests', () {
    group('Utility Tests', () {
      group('AdUtils Tests', ad_utils_tests.main);
    });
  });
}

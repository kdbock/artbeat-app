import 'package:artbeat/src/services/crash_prevention_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Crash Prevention Service Tests', () {
    test('should handle null string input safely', () {
      expect(CrashPreventionService.sanitizeString(null), equals(''));
      expect(CrashPreventionService.sanitizeString(''), equals(''));
      expect(CrashPreventionService.sanitizeString('  test  '), equals('test'));
    });

    test('should handle invalid numeric input safely', () {
      expect(CrashPreventionService.sanitizeDouble(null), equals(0.0));
      expect(CrashPreventionService.sanitizeDouble(double.nan), equals(0.0));
      expect(
        CrashPreventionService.sanitizeDouble(double.infinity),
        equals(0.0),
      );
      expect(CrashPreventionService.sanitizeDouble('invalid'), equals(0.0));
      expect(CrashPreventionService.sanitizeDouble('123.45'), equals(123.45));
      expect(CrashPreventionService.sanitizeDouble(42), equals(42.0));
    });

    test('should validate coordinates correctly', () {
      expect(CrashPreventionService.isValidCoordinate(null, null), isFalse);
      expect(CrashPreventionService.isValidCoordinate(double.nan, 0), isFalse);
      expect(
        CrashPreventionService.isValidCoordinate(0, double.infinity),
        isFalse,
      );
      expect(CrashPreventionService.isValidCoordinate(91, 0), isFalse);
      expect(CrashPreventionService.isValidCoordinate(0, 181), isFalse);
      expect(
        CrashPreventionService.isValidCoordinate(40.7128, -74.0060),
        isTrue,
      );
    });

    test('should provide user-friendly error messages', () {
      expect(
        CrashPreventionService.getUserFriendlyErrorMessage('network error'),
        contains('Network connection'),
      );
      expect(
        CrashPreventionService.getUserFriendlyErrorMessage('permission denied'),
        contains('Permission required'),
      );
      expect(
        CrashPreventionService.getUserFriendlyErrorMessage(
          'camera not available',
        ),
        contains('Camera not available'),
      );
      expect(
        CrashPreventionService.getUserFriendlyErrorMessage('unknown error'),
        contains('Something went wrong'),
      );
    });

    test('should execute operations safely', () async {
      // Test successful operation
      final result = await CrashPreventionService.safeExecute<String>(
        operation: () async => 'success',
        operationName: 'test_operation',
      );
      expect(result, equals('success'));

      // Test failed operation with fallback
      final failedResult = await CrashPreventionService.safeExecute<String>(
        operation: () async => throw Exception('test error'),
        operationName: 'failing_operation',
        fallbackValue: 'fallback',
      );
      expect(failedResult, equals('fallback'));
    });

    test('should execute sync operations safely', () {
      // Test successful sync operation
      final result = CrashPreventionService.safeExecuteSync<int>(
        operation: () => 42,
        operationName: 'sync_test',
      );
      expect(result, equals(42));

      // Test failed sync operation with fallback
      final failedResult = CrashPreventionService.safeExecuteSync<int>(
        operation: () => throw Exception('sync error'),
        operationName: 'failing_sync',
        fallbackValue: -1,
      );
      expect(failedResult, equals(-1));
    });

    test('should sanitize lists safely', () {
      expect(CrashPreventionService.sanitizeList<String>(null), equals([]));
      expect(
        CrashPreventionService.sanitizeList<String>(['a', 'b']),
        equals(['a', 'b']),
      );
      expect(
        CrashPreventionService.sanitizeList<int>([1, 2, 3]),
        equals([1, 2, 3]),
      );

      // Test with fallback
      expect(
        CrashPreventionService.sanitizeList<String>(
          null,
          fallback: ['default'],
        ),
        equals(['default']),
      );
    });

    test('should sanitize maps safely', () {
      expect(CrashPreventionService.sanitizeMap(null), equals({}));
      expect(
        CrashPreventionService.sanitizeMap({'key': 'value'}),
        equals({'key': 'value'}),
      );

      // Test with fallback
      expect(
        CrashPreventionService.sanitizeMap(
          null,
          fallback: {'default': 'value'},
        ),
        equals({'default': 'value'}),
      );
    });

    test('should retry operations with exponential backoff', () async {
      int attempts = 0;

      // Test operation that succeeds on third attempt
      final result = await CrashPreventionService.retryOperation<String>(
        operation: () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('Attempt $attempts failed');
          }
          return 'success on attempt $attempts';
        },
        initialDelay: const Duration(milliseconds: 10),
        operationName: 'retry_test',
      );

      expect(result, equals('success on attempt 3'));
      expect(attempts, equals(3));
    });

    test('should handle retry operation that always fails', () async {
      int attempts = 0;

      try {
        await CrashPreventionService.retryOperation<String>(
          operation: () async {
            attempts++;
            throw Exception('Always fails');
          },
          maxRetries: 2,
          initialDelay: const Duration(milliseconds: 10),
          operationName: 'always_fails',
        );
        fail('Should have thrown an exception');
      } catch (e) {
        expect(attempts, equals(2));
        expect(e.toString(), contains('Always fails'));
      }
    });
  });
}

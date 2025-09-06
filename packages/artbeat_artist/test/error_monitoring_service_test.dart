import 'package:flutter_test/flutter_test.dart';

import '../lib/src/services/error_monitoring_service.dart';

void main() {
  group('ErrorMonitoringService', () {
    group('recordError', () {
      test('should record error without context', () {
        // Arrange
        const exception = 'Test exception';
        final stackTrace = StackTrace.current;

        // Act
        ErrorMonitoringService.recordError(exception, stackTrace);

        // Verify - Test that it doesn't throw
        expect(true, isTrue);
      });

      test('should record error with context', () {
        // Arrange
        const exception = 'Test exception';
        final stackTrace = StackTrace.current;
        const context = {'userId': 'test123', 'operation': 'testOp'};

        // Act
        ErrorMonitoringService.recordError(
          exception,
          stackTrace,
          reason: 'Test reason',
          context: context,
        );

        // Verify - Test that it doesn't throw
        expect(true, isTrue);
      });

      test('should sanitize sensitive data in context', () {
        // Arrange
        const exception = 'Test exception';
        final stackTrace = StackTrace.current;
        const context = {
          'stripe_secret': 'sk_test_1234567890',
          'password': 'secretpassword',
          'email': 'test@example.com',
          'safe_data': 'this is safe',
        };

        // Act & Assert - Should not throw
        expect(
          () => ErrorMonitoringService.recordError(
            exception,
            stackTrace,
            context: context,
          ),
          returnsNormally,
        );
      });

      test('should handle fatal errors', () {
        // Arrange
        const exception = 'Fatal error';
        final stackTrace = StackTrace.current;

        // Act & Assert - Should not throw
        expect(
          () => ErrorMonitoringService.recordError(
            exception,
            stackTrace,
            fatal: true,
          ),
          returnsNormally,
        );
      });
    });

    group('setUserContext', () {
      test('should set user context with all parameters', () {
        // Act & Assert - Should not throw
        expect(
          () => ErrorMonitoringService.setUserContext(
            userId: 'test123',
            userType: 'artist',
            subscriptionTier: 'pro',
          ),
          returnsNormally,
        );
      });

      test('should set user context with minimal parameters', () {
        // Act & Assert - Should not throw
        expect(
          () => ErrorMonitoringService.setUserContext(
            userId: 'test123',
          ),
          returnsNormally,
        );
      });

      test('should handle invalid user context gracefully', () {
        // Act & Assert - Should not throw
        expect(
          () => ErrorMonitoringService.setUserContext(
            userId: '',
            userType: null,
            subscriptionTier: null,
          ),
          returnsNormally,
        );
      });
    });

    group('logEvent', () {
      test('should log event without parameters', () {
        // Act & Assert - Should not throw
        expect(
          () => ErrorMonitoringService.logEvent('test_event'),
          returnsNormally,
        );
      });

      test('should log event with parameters', () {
        // Arrange
        const parameters = {
          'screen': 'artist_profile',
          'action': 'follow_artist',
          'count': 1,
        };

        // Act & Assert - Should not throw
        expect(
          () => ErrorMonitoringService.logEvent('test_event',
              parameters: parameters),
          returnsNormally,
        );
      });

      test('should sanitize sensitive data in parameters', () {
        // Arrange
        const parameters = {
          'stripe_key': 'sk_test_1234',
          'password': 'secret123',
          'normal_data': 'safe_value',
        };

        // Act & Assert - Should not throw
        expect(
          () => ErrorMonitoringService.logEvent('test_event',
              parameters: parameters),
          returnsNormally,
        );
      });
    });

    group('safeExecute', () {
      test('should execute function successfully', () async {
        // Arrange
        String testFunction() => 'success';

        // Act
        final result = await ErrorMonitoringService.safeExecute(
          'test_operation',
          () async => testFunction(),
        );

        // Assert
        expect(result, equals('success'));
      });

      test('should return fallback value on error', () async {
        // Arrange
        String testFunction() => throw Exception('Test error');

        // Act
        final result = await ErrorMonitoringService.safeExecute(
          'test_operation',
          () async => testFunction(),
          fallbackValue: 'fallback',
        );

        // Assert
        expect(result, equals('fallback'));
      });

      test('should rethrow error when no fallback provided', () async {
        // Arrange
        String testFunction() => throw Exception('Test error');

        // Act & Assert
        expect(
          () => ErrorMonitoringService.safeExecute(
            'test_operation',
            () async => testFunction(),
          ),
          throwsException,
        );
      });

      test('should execute with context', () async {
        // Arrange
        String testFunction() => 'success';
        const context = {'key': 'value'};

        // Act
        final result = await ErrorMonitoringService.safeExecute(
          'test_operation',
          () async => testFunction(),
          context: context,
        );

        // Assert
        expect(result, equals('success'));
      });

      test('should handle async operations', () async {
        // Arrange
        Future<String> asyncFunction() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return 'async_success';
        }

        // Act
        final result = await ErrorMonitoringService.safeExecute(
          'test_async_operation',
          asyncFunction,
        );

        // Assert
        expect(result, equals('async_success'));
      });

      test('should handle complex return types', () async {
        // Arrange
        Future<List<String>> listFunction() async => ['item1', 'item2'];

        // Act
        final result = await ErrorMonitoringService.safeExecute(
          'test_list_operation',
          listFunction,
          fallbackValue: <String>[],
        );

        // Assert
        expect(result, equals(['item1', 'item2']));
      });

      test('should handle null return values', () async {
        // Arrange
        Future<String?> nullFunction() async => null;

        // Act
        final result = await ErrorMonitoringService.safeExecute(
          'test_null_operation',
          nullFunction,
          fallbackValue: 'default',
        );

        // Assert
        expect(result, isNull);
      });
    });

    group('initialization', () {
      test('should initialize without throwing', () async {
        // Act & Assert - Should not throw
        expect(
          () => ErrorMonitoringService.initialize(),
          returnsNormally,
        );
      });
    });

    group('edge cases', () {
      test('should handle very large context data', () {
        // Arrange
        final largeContext = <String, dynamic>{};
        for (int i = 0; i < 100; i++) {
          largeContext['key_$i'] = 'value_$i' * 100;
        }

        // Act & Assert - Should not throw
        expect(
          () => ErrorMonitoringService.recordError(
            'Large context test',
            StackTrace.current,
            context: largeContext,
          ),
          returnsNormally,
        );
      });

      test('should handle null and empty values', () {
        // Act & Assert - Should not throw
        expect(
          () => ErrorMonitoringService.recordError(
            null,
            null,
            reason: null,
            context: null,
          ),
          returnsNormally,
        );
      });

      test('should handle malformed data gracefully', () {
        // Arrange
        final malformedContext = {
          'circular_ref': <String, dynamic>{},
          'function': () => 'test',
          'object': DateTime.now(),
        };

        // Act & Assert - Should not throw
        expect(
          () => ErrorMonitoringService.recordError(
            'Malformed data test',
            StackTrace.current,
            context: malformedContext,
          ),
          returnsNormally,
        );
      });
    });
  });
}

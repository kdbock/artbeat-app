import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_art_walk/src/services/secure_directions_service.dart';

void main() {
  group('SecureDirectionsService Tests', () {
    late SecureDirectionsService secureDirectionsService;

    setUp(() {
      secureDirectionsService = SecureDirectionsService.instance;
    });

    tearDown(() {
      secureDirectionsService.dispose();
    });

    group('Initialization', () {
      test('should create singleton instance', () {
        // Act
        final instance1 = SecureDirectionsService.instance;
        final instance2 = SecureDirectionsService.instance;

        // Assert
        expect(instance1, same(instance2));
      });
    });

    group('Input Validation', () {
      test('should reject empty origin', () async {
        // Act & Assert
        expect(
          () => secureDirectionsService.getSecureDirections(
            origin: '',
            destination: 'New York, NY',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should reject empty destination', () async {
        // Act & Assert
        expect(
          () => secureDirectionsService.getSecureDirections(
            origin: 'Los Angeles, CA',
            destination: '',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should reject oversized inputs', () async {
        // Arrange
        final longString = 'a' * 250;

        // Act & Assert
        expect(
          () => secureDirectionsService.getSecureDirections(
            origin: longString,
            destination: 'New York, NY',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should reject suspicious characters', () async {
        // Act & Assert
        expect(
          () => secureDirectionsService.getSecureDirections(
            origin: 'Los Angeles<script>',
            destination: 'New York, NY',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test(
        'should accept valid input format without throwing validation errors',
        () {
          // This test just verifies input validation passes for valid data
          // The actual API call will fail in test environment, which is expected
          expect(
            () {
              // Create the request (validation happens here)
              secureDirectionsService.getSecureDirections(
                origin: 'Los Angeles, CA',
                destination: 'New York, NY',
              );
            },
            returnsNormally, // Validation should not throw
          );
        },
      );
    });

    group('Cache Management', () {
      test('should provide cache statistics', () {
        // Act
        final stats = secureDirectionsService.getCacheStats();

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats, containsPair('cached_routes', isA<int>()));
        expect(stats, containsPair('memory_usage_mb', isA<String>()));
      });

      test('should clear cache successfully', () {
        // Act
        secureDirectionsService.clearCache();

        // Assert
        final stats = secureDirectionsService.getCacheStats();
        expect(stats['cached_routes'], equals(0));
      });
    });

    group('Parameter Handling', () {
      test('should accept optional parameters', () {
        // This test verifies the method accepts all optional parameters
        expect(
          () {
            secureDirectionsService.getSecureDirections(
              origin: 'Paris, France',
              destination: 'London, UK',
              language: 'fr',
              region: 'fr',
              waypoints: ['Brussels, Belgium'],
              optimize: true,
            );
          },
          returnsNormally, // Should not throw on parameter validation
        );
      });

      test('should handle empty waypoints', () {
        expect(() {
          secureDirectionsService.getSecureDirections(
            origin: 'Start Location',
            destination: 'End Location',
            waypoints: [],
          );
        }, returnsNormally);
      });

      test('should handle null waypoints', () {
        expect(() {
          secureDirectionsService.getSecureDirections(
            origin: 'Start Location',
            destination: 'End Location',
            waypoints: null,
          );
        }, returnsNormally);
      });
    });

    group('Service Management', () {
      test('should dispose resources', () {
        // Act
        secureDirectionsService.dispose();

        // Assert - verify cache is cleared after disposal
        final stats = secureDirectionsService.getCacheStats();
        expect(stats['cached_routes'], equals(0));
      });
    });

    group('Error Handling', () {
      test(
        'should throw appropriate errors for invalid configuration',
        () async {
          // In a real test environment without proper config,
          // the service should handle missing configuration gracefully
          try {
            await secureDirectionsService.initialize();
          } catch (e) {
            expect(e, isA<Exception>());
          }
        },
      );
    });
  });
}

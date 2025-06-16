import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:artbeat_art_walk/src/services/testable_google_maps_service.dart';

// Create annotations for the mock classes
@GenerateNiceMocks(
    [MockSpec<IGoogleMapsPlatform>(), MockSpec<IMapsImplementation>()])
import 'testable_google_maps_service_test.mocks.dart';

void main() {
  group('TestableGoogleMapsService Tests', () {
    late TestableGoogleMapsService mapService;
    late MockIGoogleMapsPlatform mockMapsPlatform;
    late MockIMapsImplementation mockMapsImplementation;

    setUp(() {
      mockMapsPlatform = MockIGoogleMapsPlatform();
      mockMapsImplementation = MockIMapsImplementation();
      mapService = TestableGoogleMapsService(
        mapsPlatform: mockMapsPlatform,
        mapsImplementation: mockMapsImplementation,
        platform: TargetPlatform
            .android, // Force Android platform for consistent tests
      );
    });

    test('isInitialized returns false initially', () {
      // Assert
      expect(mapService.isInitialized, isFalse);
    });

    test('initializeMaps sets isInitialized to true', () async {
      // Arrange
      when(mockMapsPlatform.init(any)).thenAnswer((_) async {});
      when(mockMapsImplementation.initializeWithRenderer(any))
          .thenAnswer((_) async {});

      // Act
      await mapService.initializeMaps();

      // Assert
      expect(mapService.isInitialized, isTrue);
      verify(mockMapsPlatform.init(any)).called(1);
      verify(mockMapsImplementation.initializeWithRenderer(any)).called(1);
    });

    test('initializeMaps does not reinitialize when already initialized',
        () async {
      // Arrange
      when(mockMapsPlatform.init(any)).thenAnswer((_) async {});
      when(mockMapsImplementation.initializeWithRenderer(any))
          .thenAnswer((_) async {});

      // Act - initialize once
      await mapService.initializeMaps();

      // Reset the mock counters
      clearInteractions(mockMapsPlatform);
      clearInteractions(mockMapsImplementation);

      // Act - try to initialize again
      await mapService.initializeMaps();

      // Assert - the mocks should not be called again
      verifyZeroInteractions(mockMapsPlatform);
      verifyZeroInteractions(mockMapsImplementation);
    });

    test('initializeMaps handles renderer already initialized exception',
        () async {
      // Arrange
      when(mockMapsPlatform.init(any)).thenAnswer((_) async {});
      when(mockMapsImplementation.initializeWithRenderer(any))
          .thenThrow(Exception('Renderer already initialized'));

      // Act
      await mapService.initializeMaps();

      // Assert - should still be initialized despite the exception
      expect(mapService.isInitialized, isTrue);
    });

    test('initializeMaps propagates other exceptions', () async {
      // Arrange
      when(mockMapsPlatform.init(any)).thenAnswer((_) async {});
      when(mockMapsImplementation.initializeWithRenderer(any))
          .thenThrow(Exception('Some other error'));

      // Act & Assert
      expect(() => mapService.initializeMaps(), throwsException);
      expect(mapService.isInitialized, isFalse);
    });

    test('updateMapStyle returns false for empty style string', () async {
      // Act
      final result = await mapService.updateMapStyle('');

      // Assert
      expect(result, isFalse);
    });

    test('updateMapStyle returns true for valid style string', () async {
      // Arrange
      const validStyle = '[]'; // minimally valid JSON

      // Act
      final result = await mapService.updateMapStyle(validStyle);

      // Assert
      expect(result, isTrue);
      expect(mapService.currentMapStyle, equals(validStyle));
    });

    test('defaultMapStyle returns non-empty string', () {
      // Act
      final style = mapService.defaultMapStyle;

      // Assert
      expect(style, isNotEmpty);
      expect(style, contains('featureType'));
    });

    test('resetInitialization sets isInitialized to false', () async {
      // Arrange
      when(mockMapsPlatform.init(any)).thenAnswer((_) async {});
      when(mockMapsImplementation.initializeWithRenderer(any))
          .thenAnswer((_) async {});
      await mapService.initializeMaps();
      expect(mapService.isInitialized, isTrue);

      // Act
      mapService.resetInitialization();

      // Assert
      expect(mapService.isInitialized, isFalse);
    });
  });
}

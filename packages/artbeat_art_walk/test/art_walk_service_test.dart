import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:artbeat_art_walk/src/models/models.dart';

void main() {
  group('Geolocator Tests', () {
    test('should calculate distance between two points', () {
      // Arrange
      const start = LatLng(35.2271, -80.8431); // Charlotte, NC
      const end = LatLng(35.2280, -80.8420); // Nearby point

      // Act
      final distance = Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );

      // Assert
      expect(distance, isA<double>());
      expect(distance, greaterThan(0));
      expect(distance, lessThan(200)); // Should be less than 200 meters
    });

    test('should calculate bearing between two points', () {
      // Arrange
      const start = LatLng(35.2271, -80.8431);
      const end = LatLng(35.2280, -80.8420);

      // Act
      final bearing = Geolocator.bearingBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );

      // Assert
      expect(bearing, isA<double>());
      expect(bearing, greaterThanOrEqualTo(-180));
      expect(bearing, lessThanOrEqualTo(180));
    });
  });

  group('ArtWalkModel Tests', () {
    test('should create ArtWalkModel with valid data', () {
      // Arrange & Act
      final artWalk = ArtWalkModel(
        id: 'walk-1',
        title: 'Downtown Art Walk',
        description: 'A walking tour of downtown public art',
        userId: 'user-123',
        artworkIds: ['artwork-1', 'artwork-2', 'artwork-3'],
        createdAt: DateTime.now(),
        isPublic: true,
        estimatedDuration: 120.0, // 2 hours in minutes
        estimatedDistance: 1.5, // 1.5 miles
        difficulty: 'Easy',
        isAccessible: true,
      );

      // Assert
      expect(artWalk.id, equals('walk-1'));
      expect(artWalk.title, equals('Downtown Art Walk'));
      expect(artWalk.artworkIds.length, equals(3));
      expect(artWalk.estimatedDuration, equals(120.0));
      expect(artWalk.difficulty, equals('Easy'));
      expect(artWalk.estimatedDistance, equals(1.5));
      expect(artWalk.isAccessible, isTrue);
    });

    test('should convert ArtWalkModel to Firestore format', () {
      // Arrange
      final artWalk = ArtWalkModel(
        id: 'walk-1',
        title: 'Test Walk',
        description: 'A test walk',
        userId: 'user-123',
        artworkIds: ['artwork-1'],
        createdAt: DateTime.now(),
        isPublic: true,
        estimatedDuration: 60.0,
        estimatedDistance: 1.0,
      );

      // Act
      final firestoreData = artWalk.toFirestore();

      // Assert
      expect(firestoreData['title'], equals('Test Walk'));
      expect(firestoreData['description'], equals('A test walk'));
      expect(firestoreData['userId'], equals('user-123'));
      expect(firestoreData['artworkIds'], equals(['artwork-1']));
      expect(firestoreData['isPublic'], isTrue);
      expect(firestoreData['estimatedDuration'], equals(60.0));
      expect(firestoreData['estimatedDistance'], equals(1.0));
    });

    test('should create copyWith method', () {
      // Arrange
      final originalWalk = ArtWalkModel(
        id: 'walk-1',
        title: 'Original Walk',
        description: 'Original description',
        userId: 'user-123',
        artworkIds: ['artwork-1'],
        createdAt: DateTime.now(),
      );

      // Act
      final updatedWalk = originalWalk.copyWith(
        title: 'Updated Walk',
        isPublic: true,
      );

      // Assert
      expect(updatedWalk.title, equals('Updated Walk'));
      expect(
        updatedWalk.description,
        equals('Original description'),
      ); // unchanged
      expect(updatedWalk.isPublic, isTrue);
      expect(updatedWalk.id, equals('walk-1')); // unchanged
    });
  });

  group('ArtWalkRouteModel Tests', () {
    test('should create ArtWalkRouteModel with valid data', () {
      // Arrange & Act
      final route = ArtWalkRouteModel(
        id: 'route-1',
        artWalkId: 'walk-1',
        segments: [],
        totalDistanceMeters: 1500,
        totalDurationSeconds: 1800, // 30 minutes
        overviewPolyline: [
          const LatLng(35.2271, -80.8431),
          const LatLng(35.2280, -80.8420),
        ],
        createdAt: DateTime.now(),
      );

      // Assert
      expect(route.id, equals('route-1'));
      expect(route.artWalkId, equals('walk-1'));
      expect(route.totalDistanceMeters, equals(1500));
      expect(route.totalDurationSeconds, equals(1800));
      expect(route.overviewPolyline.length, equals(2));
    });

    test('should format distance correctly', () {
      // Arrange
      final shortRoute = ArtWalkRouteModel(
        id: 'route-1',
        artWalkId: 'walk-1',
        segments: [],
        totalDistanceMeters: 500, // 500 meters
        totalDurationSeconds: 600,
        overviewPolyline: [],
        createdAt: DateTime.now(),
      );

      final longRoute = ArtWalkRouteModel(
        id: 'route-2',
        artWalkId: 'walk-1',
        segments: [],
        totalDistanceMeters: 2500, // 2.5 km
        totalDurationSeconds: 1800,
        overviewPolyline: [],
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(shortRoute.formattedTotalDistance, equals('500m'));
      expect(longRoute.formattedTotalDistance, equals('2.5km'));
    });

    test('should format duration correctly', () {
      // Arrange
      final shortRoute = ArtWalkRouteModel(
        id: 'route-1',
        artWalkId: 'walk-1',
        segments: [],
        totalDistanceMeters: 1000,
        totalDurationSeconds: 45, // 45 seconds
        overviewPolyline: [],
        createdAt: DateTime.now(),
      );

      final mediumRoute = ArtWalkRouteModel(
        id: 'route-2',
        artWalkId: 'walk-1',
        segments: [],
        totalDistanceMeters: 1000,
        totalDurationSeconds: 1800, // 30 minutes
        overviewPolyline: [],
        createdAt: DateTime.now(),
      );

      final longRoute = ArtWalkRouteModel(
        id: 'route-3',
        artWalkId: 'walk-1',
        segments: [],
        totalDistanceMeters: 1000,
        totalDurationSeconds: 7800, // 2 hours 10 minutes
        overviewPolyline: [],
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(shortRoute.formattedTotalDuration, equals('45s'));
      expect(mediumRoute.formattedTotalDuration, equals('30min'));
      expect(longRoute.formattedTotalDuration, equals('2h 10min'));
    });
  });

  group('RouteSegment Tests', () {
    test('should create RouteSegment with valid data', () {
      // Arrange & Act
      final segment = RouteSegment(
        fromArtPieceId: 'art-1',
        toArtPieceId: 'art-2',
        steps: [],
        distanceMeters: 300,
        durationSeconds: 240, // 4 minutes
      );

      // Assert
      expect(segment.fromArtPieceId, equals('art-1'));
      expect(segment.toArtPieceId, equals('art-2'));
      expect(segment.distanceMeters, equals(300));
      expect(segment.durationSeconds, equals(240));
      expect(segment.isFromStartingLocation, isFalse);
    });

    test('should identify starting location segment', () {
      // Arrange & Act
      final startingSegment = RouteSegment(
        fromArtPieceId: null, // null indicates starting from user location
        toArtPieceId: 'art-1',
        steps: [],
        distanceMeters: 500,
        durationSeconds: 360,
      );

      // Assert
      expect(startingSegment.isFromStartingLocation, isTrue);
      expect(startingSegment.fromArtPieceId, isNull);
    });

    test('should format segment distance and duration', () {
      // Arrange
      final segment = RouteSegment(
        toArtPieceId: 'art-1',
        steps: [],
        distanceMeters: 1200, // 1.2 km
        durationSeconds: 900, // 15 minutes
      );

      // Act & Assert
      expect(segment.formattedDistance, equals('1.2km'));
      expect(segment.formattedDuration, equals('15min'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Mock classes for testing
@GenerateMocks([Geolocator])
import 'art_walk_service_test.mocks.dart';

void main() {
  group('ArtWalkService Tests', () {
    late MockGeolocator mockGeolocator;

    setUp(() {
      mockGeolocator = MockGeolocator();
    });

    test('should get current location successfully', () async {
      // Arrange
      final expectedPosition = Position(
        latitude: 35.2271,
        longitude: -80.8431,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      when(
        Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high),
      ).thenAnswer((_) async => expectedPosition);

      // Act
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Assert
      expect(position.latitude, equals(35.2271));
      expect(position.longitude, equals(-80.8431));
      expect(position.accuracy, equals(10.0));
    });

    test('should handle location permission denied', () async {
      // Arrange
      when(
        Geolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);

      // Act
      final permission = await Geolocator.checkPermission();

      // Assert
      expect(permission, equals(LocationPermission.denied));
    });

    test('should request location permission', () async {
      // Arrange
      when(
        Geolocator.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);

      // Act
      final permission = await Geolocator.requestPermission();

      // Assert
      expect(permission, equals(LocationPermission.whileInUse));
    });

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

  group('ArtWalkRoute Tests', () {
    test('should create ArtWalkRoute with valid data', () {
      // Arrange & Act
      final route = ArtWalkRoute(
        id: 'route-1',
        name: 'Downtown Art Walk',
        description: 'A walking tour of downtown public art',
        waypoints: [
          ArtWalkWaypoint(
            id: 'waypoint-1',
            name: 'Sculpture Garden',
            location: const LatLng(35.2271, -80.8431),
            description: 'Beautiful outdoor sculptures',
            artworkIds: ['artwork-1', 'artwork-2'],
          ),
          ArtWalkWaypoint(
            id: 'waypoint-2',
            name: 'Mural Wall',
            location: const LatLng(35.2280, -80.8420),
            description: 'Historic mural depicting city history',
            artworkIds: ['artwork-3'],
          ),
        ],
        estimatedDuration: const Duration(hours: 2),
        difficulty: RouteDifficulty.easy,
        distance: 1.5,
      );

      // Assert
      expect(route.id, equals('route-1'));
      expect(route.name, equals('Downtown Art Walk'));
      expect(route.waypoints.length, equals(2));
      expect(route.estimatedDuration, equals(const Duration(hours: 2)));
      expect(route.difficulty, equals(RouteDifficulty.easy));
      expect(route.distance, equals(1.5));
    });

    test('should calculate total route distance', () {
      // Arrange
      final route = ArtWalkRoute(
        id: 'route-1',
        name: 'Test Route',
        description: 'Test route',
        waypoints: [
          ArtWalkWaypoint(
            id: 'waypoint-1',
            name: 'Start',
            location: const LatLng(35.2271, -80.8431),
            description: 'Starting point',
            artworkIds: [],
          ),
          ArtWalkWaypoint(
            id: 'waypoint-2',
            name: 'Middle',
            location: const LatLng(35.2280, -80.8420),
            description: 'Middle point',
            artworkIds: [],
          ),
          ArtWalkWaypoint(
            id: 'waypoint-3',
            name: 'End',
            location: const LatLng(35.2290, -80.8410),
            description: 'End point',
            artworkIds: [],
          ),
        ],
        estimatedDuration: const Duration(hours: 1),
        difficulty: RouteDifficulty.moderate,
        distance: 0.0, // Will be calculated
      );

      // Act
      final calculatedDistance = route.calculateTotalDistance();

      // Assert
      expect(calculatedDistance, isA<double>());
      expect(calculatedDistance, greaterThan(0));
    });

    test('should validate route data', () {
      // Valid route
      final validRoute = ArtWalkRoute(
        id: 'route-1',
        name: 'Valid Route',
        description: 'A valid route',
        waypoints: [
          ArtWalkWaypoint(
            id: 'waypoint-1',
            name: 'Point 1',
            location: const LatLng(35.2271, -80.8431),
            description: 'First point',
            artworkIds: ['artwork-1'],
          ),
          ArtWalkWaypoint(
            id: 'waypoint-2',
            name: 'Point 2',
            location: const LatLng(35.2280, -80.8420),
            description: 'Second point',
            artworkIds: ['artwork-2'],
          ),
        ],
        estimatedDuration: const Duration(hours: 1),
        difficulty: RouteDifficulty.easy,
        distance: 1.0,
      );
      expect(validRoute.isValid, isTrue);

      // Invalid route - no waypoints
      final invalidRoute1 = ArtWalkRoute(
        id: 'route-1',
        name: 'Invalid Route',
        description: 'Invalid route',
        waypoints: [],
        estimatedDuration: const Duration(hours: 1),
        difficulty: RouteDifficulty.easy,
        distance: 1.0,
      );
      expect(invalidRoute1.isValid, isFalse);

      // Invalid route - empty name
      final invalidRoute2 = ArtWalkRoute(
        id: 'route-1',
        name: '',
        description: 'Invalid route',
        waypoints: [
          ArtWalkWaypoint(
            id: 'waypoint-1',
            name: 'Point 1',
            location: const LatLng(35.2271, -80.8431),
            description: 'First point',
            artworkIds: ['artwork-1'],
          ),
        ],
        estimatedDuration: const Duration(hours: 1),
        difficulty: RouteDifficulty.easy,
        distance: 1.0,
      );
      expect(invalidRoute2.isValid, isFalse);
    });

    test('should convert ArtWalkRoute to JSON', () {
      // Arrange
      final route = ArtWalkRoute(
        id: 'route-1',
        name: 'JSON Route',
        description: 'Route for JSON test',
        waypoints: [
          ArtWalkWaypoint(
            id: 'waypoint-1',
            name: 'Point 1',
            location: const LatLng(35.2271, -80.8431),
            description: 'First point',
            artworkIds: ['artwork-1'],
          ),
        ],
        estimatedDuration: const Duration(hours: 2),
        difficulty: RouteDifficulty.moderate,
        distance: 2.5,
        isPublic: true,
        rating: 4.5,
        reviewsCount: 10,
      );

      // Act
      final json = route.toJson();

      // Assert
      expect(json['id'], equals('route-1'));
      expect(json['name'], equals('JSON Route'));
      expect(json['description'], equals('Route for JSON test'));
      expect(json['waypoints'], isA<List>());
      expect(json['estimatedDurationMinutes'], equals(120));
      expect(json['difficulty'], equals(RouteDifficulty.moderate.toString()));
      expect(json['distance'], equals(2.5));
      expect(json['isPublic'], isTrue);
      expect(json['rating'], equals(4.5));
      expect(json['reviewsCount'], equals(10));
    });

    test('should create ArtWalkRoute from JSON', () {
      // Arrange
      final json = {
        'id': 'route-1',
        'name': 'JSON Route',
        'description': 'Route from JSON',
        'waypoints': [
          {
            'id': 'waypoint-1',
            'name': 'Point 1',
            'latitude': 35.2271,
            'longitude': -80.8431,
            'description': 'First point',
            'artworkIds': ['artwork-1'],
          },
        ],
        'estimatedDurationMinutes': 90,
        'difficulty': RouteDifficulty.easy.toString(),
        'distance': 1.8,
        'isPublic': true,
        'rating': 4.2,
        'reviewsCount': 5,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Act
      final route = ArtWalkRoute.fromJson(json);

      // Assert
      expect(route.id, equals('route-1'));
      expect(route.name, equals('JSON Route'));
      expect(route.waypoints.length, equals(1));
      expect(route.estimatedDuration, equals(const Duration(minutes: 90)));
      expect(route.difficulty, equals(RouteDifficulty.easy));
      expect(route.distance, equals(1.8));
      expect(route.isPublic, isTrue);
      expect(route.rating, equals(4.2));
      expect(route.reviewsCount, equals(5));
    });
  });

  group('ArtWalkWaypoint Tests', () {
    test('should create ArtWalkWaypoint with valid data', () {
      // Arrange & Act
      final waypoint = ArtWalkWaypoint(
        id: 'waypoint-1',
        name: 'Test Waypoint',
        location: const LatLng(35.2271, -80.8431),
        description: 'A test waypoint',
        artworkIds: ['artwork-1', 'artwork-2'],
        estimatedVisitDuration: const Duration(minutes: 15),
        accessibility: AccessibilityInfo(
          isWheelchairAccessible: true,
          hasAudioGuide: false,
          visuallyImpairedFriendly: true,
        ),
      );

      // Assert
      expect(waypoint.id, equals('waypoint-1'));
      expect(waypoint.name, equals('Test Waypoint'));
      expect(waypoint.location.latitude, equals(35.2271));
      expect(waypoint.location.longitude, equals(-80.8431));
      expect(waypoint.description, equals('A test waypoint'));
      expect(waypoint.artworkIds.length, equals(2));
      expect(waypoint.estimatedVisitDuration, equals(const Duration(minutes: 15)));
      expect(waypoint.accessibility?.isWheelchairAccessible, isTrue);
    });

    test('should validate waypoint data', () {
      // Valid waypoint
      final validWaypoint = ArtWalkWaypoint(
        id: 'waypoint-1',
        name: 'Valid Waypoint',
        location: const LatLng(35.2271, -80.8431),
        description: 'Valid description',
        artworkIds: ['artwork-1'],
      );
      expect(validWaypoint.isValid, isTrue);

      // Invalid waypoint - empty name
      final invalidWaypoint1 = ArtWalkWaypoint(
        id: 'waypoint-1',
        name: '',
        location: const LatLng(35.2271, -80.8431),
        description: 'Description',
        artworkIds: ['artwork-1'],
      );
      expect(invalidWaypoint1.isValid, isFalse);

      // Invalid waypoint - invalid coordinates
      final invalidWaypoint2 = ArtWalkWaypoint(
        id: 'waypoint-1',
        name: 'Waypoint',
        location: const LatLng(91.0, -80.8431), // Invalid latitude
        description: 'Description',
        artworkIds: ['artwork-1'],
      );
      expect(invalidWaypoint2.isValid, isFalse);
    });

    test('should calculate distance to another waypoint', () {
      // Arrange
      final waypoint1 = ArtWalkWaypoint(
        id: 'waypoint-1',
        name: 'First',
        location: const LatLng(35.2271, -80.8431),
        description: 'First waypoint',
        artworkIds: [],
      );

      final waypoint2 = ArtWalkWaypoint(
        id: 'waypoint-2',
        name: 'Second',
        location: const LatLng(35.2280, -80.8420),
        description: 'Second waypoint',
        artworkIds: [],
      );

      // Act
      final distance = waypoint1.distanceTo(waypoint2);

      // Assert
      expect(distance, isA<double>());
      expect(distance, greaterThan(0));
      expect(distance, lessThan(200)); // Should be less than 200 meters
    });
  });

  group('RouteDifficulty Tests', () {
    test('should convert RouteDifficulty to string correctly', () {
      expect(RouteDifficulty.easy.toString(), equals('RouteDifficulty.easy'));
      expect(
        RouteDifficulty.moderate.toString(),
        equals('RouteDifficulty.moderate'),
      );
      expect(RouteDifficulty.hard.toString(), equals('RouteDifficulty.hard'));
    });

    test('should parse RouteDifficulty from string correctly', () {
      expect(
        RouteDifficultyExtension.fromString('RouteDifficulty.easy'),
        equals(RouteDifficulty.easy),
      );
      expect(
        RouteDifficultyExtension.fromString('RouteDifficulty.moderate'),
        equals(RouteDifficulty.moderate),
      );
      expect(
        RouteDifficultyExtension.fromString('RouteDifficulty.hard'),
        equals(RouteDifficulty.hard),
      );
      expect(
        RouteDifficultyExtension.fromString('invalid'),
        equals(RouteDifficulty.easy),
      ); // Default
    });

    test('should get difficulty display name correctly', () {
      expect(RouteDifficulty.easy.displayName, equals('Easy'));
      expect(RouteDifficulty.moderate.displayName, equals('Moderate'));
      expect(RouteDifficulty.hard.displayName, equals('Hard'));
    });
  });
}

// These classes should be in your actual art walk model files
class ArtWalkRoute {
  final String id;
  final String name;
  final String description;
  final List<ArtWalkWaypoint> waypoints;
  final Duration estimatedDuration;
  final RouteDifficulty difficulty;
  final double distance;
  final bool isPublic;
  final double? rating;
  final int reviewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ArtWalkRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.waypoints,
    required this.estimatedDuration,
    required this.difficulty,
    required this.distance,
    this.isPublic = true,
    this.rating,
    this.reviewsCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isValid {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        description.isNotEmpty &&
        waypoints.isNotEmpty &&
        distance >= 0;
  }

  double calculateTotalDistance() {
    if (waypoints.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      totalDistance += waypoints[i].distanceTo(waypoints[i + 1]);
    }
    return totalDistance / 1000; // Convert to kilometers
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'waypoints': waypoints.map((w) => w.toJson()).toList(),
    'estimatedDurationMinutes': estimatedDuration.inMinutes,
    'difficulty': difficulty.toString(),
    'distance': distance,
    'isPublic': isPublic,
    'rating': rating,
    'reviewsCount': reviewsCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ArtWalkRoute.fromJson(Map<String, dynamic> json) => ArtWalkRoute(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    waypoints: (json['waypoints'] as List)
        .map((w) => ArtWalkWaypoint.fromJson(w))
        .toList(),
    estimatedDuration: Duration(minutes: json['estimatedDurationMinutes']),
    difficulty: RouteDifficultyExtension.fromString(json['difficulty']),
    distance: json['distance'].toDouble(),
    isPublic: json['isPublic'] ?? true,
    rating: json['rating']?.toDouble(),
    reviewsCount: json['reviewsCount'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}

class ArtWalkWaypoint {
  final String id;
  final String name;
  final LatLng location;
  final String description;
  final List<String> artworkIds;
  final Duration? estimatedVisitDuration;
  final AccessibilityInfo? accessibility;

  ArtWalkWaypoint({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.artworkIds,
    this.estimatedVisitDuration,
    this.accessibility,
  });

  bool get isValid {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        description.isNotEmpty &&
        location.latitude >= -90 &&
        location.latitude <= 90 &&
        location.longitude >= -180 &&
        location.longitude <= 180;
  }

  double distanceTo(ArtWalkWaypoint other) {
    return Geolocator.distanceBetween(
      location.latitude,
      location.longitude,
      other.location.latitude,
      other.location.longitude,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': location.latitude,
    'longitude': location.longitude,
    'description': description,
    'artworkIds': artworkIds,
    'estimatedVisitDurationMinutes': estimatedVisitDuration?.inMinutes,
    'accessibility': accessibility?.toJson(),
  };

  factory ArtWalkWaypoint.fromJson(Map<String, dynamic> json) =>
      ArtWalkWaypoint(
        id: json['id'],
        name: json['name'],
        location: LatLng(json['latitude'], json['longitude']),
        description: json['description'],
        artworkIds: List<String>.from(json['artworkIds']),
        estimatedVisitDuration: json['estimatedVisitDurationMinutes'] != null
            ? Duration(minutes: json['estimatedVisitDurationMinutes'])
            : null,
        accessibility: json['accessibility'] != null
            ? AccessibilityInfo.fromJson(json['accessibility'])
            : null,
      );
}

enum RouteDifficulty { easy, moderate, hard }

extension RouteDifficultyExtension on RouteDifficulty {
  static RouteDifficulty fromString(String value) {
    switch (value) {
      case 'RouteDifficulty.easy':
        return RouteDifficulty.easy;
      case 'RouteDifficulty.moderate':
        return RouteDifficulty.moderate;
      case 'RouteDifficulty.hard':
        return RouteDifficulty.hard;
      default:
        return RouteDifficulty.easy;
    }
  }

  String get displayName {
    switch (this) {
      case RouteDifficulty.easy:
        return 'Easy';
      case RouteDifficulty.moderate:
        return 'Moderate';
      case RouteDifficulty.hard:
        return 'Hard';
    }
  }
}

class AccessibilityInfo {
  final bool isWheelchairAccessible;
  final bool hasAudioGuide;
  final bool visuallyImpairedFriendly;

  AccessibilityInfo({
    required this.isWheelchairAccessible,
    required this.hasAudioGuide,
    required this.visuallyImpairedFriendly,
  });

  Map<String, dynamic> toJson() => {
    'isWheelchairAccessible': isWheelchairAccessible,
    'hasAudioGuide': hasAudioGuide,
    'visuallyImpairedFriendly': visuallyImpairedFriendly,
  };

  factory AccessibilityInfo.fromJson(Map<String, dynamic> json) =>
      AccessibilityInfo(
        isWheelchairAccessible: json['isWheelchairAccessible'] ?? false,
        hasAudioGuide: json['hasAudioGuide'] ?? false,
        visuallyImpairedFriendly: json['visuallyImpairedFriendly'] ?? false,
      );
}

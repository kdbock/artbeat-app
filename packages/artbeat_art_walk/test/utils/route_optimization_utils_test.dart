import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_art_walk/src/utils/route_optimization_utils.dart';
import 'package:artbeat_art_walk/src/models/public_art_model.dart';

void main() {
  group('RouteOptimizationUtils', () {
    late List<PublicArtModel> testArtPieces;
    late LatLng startLocation;

    setUp(() {
      startLocation = const LatLng(35.7796, -78.6382); // Raleigh, NC

      testArtPieces = [
        PublicArtModel(
          id: 'art1',
          title: 'Art Piece 1',
          artistName: 'Artist 1',
          imageUrl: 'https://example.com/art1.jpg',
          location: const GeoPoint(35.7800, -78.6400), // Close to start
          description: 'Test art piece 1',
          tags: ['test'],
          userId: 'user1',
          usersFavorited: [],
          createdAt: Timestamp.now(),
        ),
        PublicArtModel(
          id: 'art2',
          title: 'Art Piece 2',
          artistName: 'Artist 2',
          imageUrl: 'https://example.com/art2.jpg',
          location: const GeoPoint(35.7900, -78.6500), // Further away
          description: 'Test art piece 2',
          tags: ['test'],
          userId: 'user1',
          usersFavorited: [],
          createdAt: Timestamp.now(),
        ),
        PublicArtModel(
          id: 'art3',
          title: 'Art Piece 3',
          artistName: 'Artist 3',
          imageUrl: 'https://example.com/art3.jpg',
          location: const GeoPoint(35.7810, -78.6390), // Medium distance
          description: 'Test art piece 3',
          tags: ['test'],
          userId: 'user1',
          usersFavorited: [],
          createdAt: Timestamp.now(),
        ),
      ];
    });

    test('should return empty list for empty input', () {
      final result = RouteOptimizationUtils.optimizeRouteFromLocation(
        [],
        startLocation,
      );
      expect(result, isEmpty);
    });

    test('should return single item for single art piece', () {
      final singleArt = [testArtPieces.first];
      final result = RouteOptimizationUtils.optimizeRouteFromLocation(
        singleArt,
        startLocation,
      );
      expect(result, equals(singleArt));
    });

    test('should optimize route using nearest neighbor algorithm', () {
      final result = RouteOptimizationUtils.optimizeRouteFromLocation(
        testArtPieces,
        startLocation,
      );

      // Should return all art pieces
      expect(result.length, equals(testArtPieces.length));

      // Should contain all original art pieces
      for (final art in testArtPieces) {
        expect(result.contains(art), isTrue);
      }

      // First art piece should be the closest to start location (art1)
      expect(result.first.id, equals('art1'));
    });

    test('should calculate total distance correctly', () {
      final routePoints = [
        const LatLng(35.7796, -78.6382),
        const LatLng(35.7800, -78.6400),
        const LatLng(35.7810, -78.6390),
      ];

      final distance = RouteOptimizationUtils.calculateTotalDistance(
        routePoints,
      );
      expect(distance, greaterThan(0));
    });

    test('should create route points with start location', () {
      final optimizedArt = RouteOptimizationUtils.optimizeRouteFromLocation(
        testArtPieces,
        startLocation,
      );

      final routePoints = RouteOptimizationUtils.createRoutePoints(
        optimizedArt,
        startLocation,
      );

      // Should start with the start location
      expect(routePoints.first, equals(startLocation));

      // Should have one point for start + one for each art piece
      expect(routePoints.length, equals(optimizedArt.length + 1));
    });

    test('should create route points with return to start', () {
      final optimizedArt = RouteOptimizationUtils.optimizeRouteFromLocation(
        testArtPieces,
        startLocation,
      );

      final routePoints = RouteOptimizationUtils.createRoutePoints(
        optimizedArt,
        startLocation,
        returnToStart: true,
      );

      // Should start and end with the start location
      expect(routePoints.first, equals(startLocation));
      expect(routePoints.last, equals(startLocation));

      // Should have one point for start + one for each art piece + one for return
      expect(routePoints.length, equals(optimizedArt.length + 2));
    });
  });
}

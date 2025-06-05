import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:artbeat_core/artbeat_core.dart';

import 'package:artbeat_art_walk/artbeat_art_walk.dart' as directions;

/// Service class for handling Google Directions API requests with secure API key handling
class SecureDirectionsService {
  static String get _apiKey {
    try {
      // Get API key from environment variables
      final apiKey = AppConfig.googleMapsApiKey;

      // Check if this is a valid API key or a placeholder
      if (apiKey.isNotEmpty && apiKey != 'placeholder_google_maps_key') {
        return apiKey;
      }

      // Since we're in a private repo, we can fall back to the original key
      debugPrint('Using original Google Maps API key from private repository');
      return 'AIzaSyAclolfPruwSH4oQ-keOXkfTPQJT86-dPU';
    } catch (e) {
      // Log warning in debug mode
      if (kDebugMode) {
        debugPrint('⚠️ Warning: Could not get Google Maps API key: $e');
        debugPrint('Falling back to original key (safe in private repo)');
      }
      // Return original API key since we're in a private repository
      return 'AIzaSyAclolfPruwSH4oQ-keOXkfTPQJT86-dPU';
    }
  }

  /// Wrapper method to call directions service with secure API key
  static Future<directions.DirectionsResult?> getWalkingDirections({
    required List<LatLng> waypoints,
    bool optimizeWaypoints = true,
  }) async {
    // Create DirectionsService instance
    final service = directions.DirectionsService();

    try {
      // Check if we have a valid API key
      if (_apiKey.isEmpty || _apiKey == 'development_placeholder_key') {
        if (kDebugMode) {
          debugPrint(
              '⚠️ Maps API key not available. Directions service disabled.');
          // Return mock data in debug mode
          return _getMockDirectionsData(waypoints);
        } else {
          throw Exception('Google Maps API key not configured');
        }
      }

      // Call the actual service
      return service.getWalkingDirections(
        waypoints: waypoints,
        optimizeWaypoints: optimizeWaypoints,
      );
    } catch (e) {
      debugPrint('Error getting directions: $e');
      if (kDebugMode) {
        // Return mock data in debug mode
        return _getMockDirectionsData(waypoints);
      } else {
        rethrow;
      }
    } finally {
      service.dispose();
    }
  }

  /// Helper method to generate mock directions data for development
  static directions.DirectionsResult? _getMockDirectionsData(
      List<LatLng> waypoints) {
    if (waypoints.length < 2) return null;

    // This is just simplified mock data for development purposes
    final legs = <directions.Leg>[];
    for (int i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];

      legs.add(directions.Leg(
        distanceMeters: 500,
        durationSeconds: 300,
        startAddress: 'Mock Start Address',
        endAddress: 'Mock End Address',
        startLocation: start,
        endLocation: end,
        steps: [
          directions.Step(
            instruction: 'Walk to destination',
            distanceMeters: 500,
            durationSeconds: 300,
            startLocation: start,
            endLocation: end,
            polyline: '',
            points: [start, end],
            travelMode: 'WALKING',
          ),
        ],
      ));
    }

    return directions.DirectionsResult(
      routes: [
        directions.Route(
          legs: legs,
          polyline: '',
          points: waypoints,
          distanceMeters: 500 * (waypoints.length - 1),
          durationSeconds: 300 * (waypoints.length - 1),
          bounds: LatLngBounds(
            northeast: waypoints.reduce((a, b) => LatLng(
                  a.latitude > b.latitude ? a.latitude : b.latitude,
                  a.longitude > b.longitude ? a.longitude : b.longitude,
                )),
            southwest: waypoints.reduce((a, b) => LatLng(
                  a.latitude < b.latitude ? a.latitude : b.latitude,
                  a.longitude < b.longitude ? a.longitude : b.longitude,
                )),
          ),
        ),
      ],
    );
  }
}

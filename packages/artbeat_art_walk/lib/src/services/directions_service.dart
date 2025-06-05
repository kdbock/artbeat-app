import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Service class for handling Google Directions API requests
class DirectionsService {
  // API key for Google Directions API is loaded from environment variables
  // Make sure the API key has the "Directions API" enabled in the Google Cloud Console.
  // For more information, see: https://developers.google.com/maps/documentation/directions/get-api-key
  static String get _apiKey => AppConfig.googleMapsApiKey;
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  final Logger _logger = Logger();
  final http.Client _httpClient;

  DirectionsService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Get walking directions between multiple points
  Future<DirectionsResult> getWalkingDirections({
    required List<LatLng> waypoints,
    bool optimizeWaypoints = true,
  }) async {
    if (waypoints.length < 2) {
      throw ArgumentError('At least 2 waypoints are required for directions');
    }

    try {
      final origin = waypoints.first;
      final destination = waypoints.last;

      // For development/testing: you can use mock data by calling _getMockDirectionsData directly if needed.

      // Format intermediate waypoints if any
      String waypointsParam = '';
      if (waypoints.length > 2) {
        final intermediatePoints = waypoints.sublist(1, waypoints.length - 1);
        waypointsParam = intermediatePoints
            .map((point) => '${point.latitude},${point.longitude}')
            .join('|');
      }

      // Build the request URL
      // Note: API key restrictions should be set in Google Cloud Console
      final Uri url = Uri.parse('$_baseUrl?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '${waypoints.length > 2 ? '&waypoints=${optimizeWaypoints ? "optimize:true|" : ""}$waypointsParam' : ''}'
          '&mode=walking'
          '&key=$_apiKey');

      // Make the API call
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return DirectionsResult.fromJson(data);
        } else {
          _logger.e(
              'Directions API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          throw Exception('Failed to get directions: ${data['status']}');
        }
      } else {
        _logger.e('HTTP error: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to get directions: HTTP ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error getting directions: $e');
      rethrow;
    }
  }

  /// Dispose method to clean up resources
  void dispose() {
    _httpClient.close();
  }
}

/// Model to represent the API response
class DirectionsResult {
  final List<Route> routes;

  DirectionsResult({required this.routes});

  factory DirectionsResult.fromJson(Map<String, dynamic> json) {
    final List<Route> routes =
        (json['routes'] as List).map((route) => Route.fromJson(route)).toList();

    return DirectionsResult(routes: routes);
  }
}

/// Model to represent a route in the directions result
class Route {
  final List<Leg> legs;
  final String polyline;
  final List<LatLng> points;
  final int distanceMeters;
  final int durationSeconds;
  final LatLngBounds bounds;

  Route({
    required this.legs,
    required this.polyline,
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.bounds,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    // Parse legs
    final List<Leg> legs =
        (json['legs'] as List).map((leg) => Leg.fromJson(leg)).toList();

    // Calculate total distance and duration
    int totalDistance = 0;
    int totalDuration = 0;

    for (final leg in legs) {
      totalDistance += leg.distanceMeters;
      totalDuration += leg.durationSeconds;
    }

    // Parse encoded polyline
    final encodedPolyline = json['overview_polyline']['points'] as String;
    final points = _decodePolyline(encodedPolyline);

    // Parse bounds
    final northeast = json['bounds']['northeast'];
    final southwest = json['bounds']['southwest'];
    final bounds = LatLngBounds(
      northeast: LatLng(northeast['lat'], northeast['lng']),
      southwest: LatLng(southwest['lat'], southwest['lng']),
    );

    return Route(
      legs: legs,
      polyline: encodedPolyline,
      points: points,
      distanceMeters: totalDistance,
      durationSeconds: totalDuration,
      bounds: bounds,
    );
  }

  /// Utility method to decode an encoded polyline string to List<LatLng>
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final latitude = lat / 1e5;
      final longitude = lng / 1e5;
      points.add(LatLng(latitude, longitude));
    }

    return points;
  }
}

/// Model to represent a leg of a route
class Leg {
  final int distanceMeters;
  final int durationSeconds;
  final String startAddress;
  final String endAddress;
  final LatLng startLocation;
  final LatLng endLocation;
  final List<Step> steps;

  Leg({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.startAddress,
    required this.endAddress,
    required this.startLocation,
    required this.endLocation,
    required this.steps,
  });

  factory Leg.fromJson(Map<String, dynamic> json) {
    final startLocation = json['start_location'];
    final endLocation = json['end_location'];

    return Leg(
      distanceMeters: json['distance']['value'],
      durationSeconds: json['duration']['value'],
      startAddress: json['start_address'],
      endAddress: json['end_address'],
      startLocation: LatLng(startLocation['lat'], startLocation['lng']),
      endLocation: LatLng(endLocation['lat'], endLocation['lng']),
      steps:
          (json['steps'] as List).map((step) => Step.fromJson(step)).toList(),
    );
  }
}

/// Model to represent a step in a leg
class Step {
  final String instruction;
  final int distanceMeters;
  final int durationSeconds;
  final LatLng startLocation;
  final LatLng endLocation;
  final String polyline;
  final List<LatLng> points;
  final String travelMode;

  Step({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.startLocation,
    required this.endLocation,
    required this.polyline,
    required this.points,
    required this.travelMode,
  });

  factory Step.fromJson(Map<String, dynamic> json) {
    final startLocation = json['start_location'];
    final endLocation = json['end_location'];
    final encodedPolyline = json['polyline']['points'] as String;

    return Step(
      instruction: json['html_instructions'],
      distanceMeters: json['distance']['value'],
      durationSeconds: json['duration']['value'],
      startLocation: LatLng(startLocation['lat'], startLocation['lng']),
      endLocation: LatLng(endLocation['lat'], endLocation['lng']),
      polyline: encodedPolyline,
      points: Route._decodePolyline(encodedPolyline),
      travelMode: json['travel_mode'],
    );
  }
}

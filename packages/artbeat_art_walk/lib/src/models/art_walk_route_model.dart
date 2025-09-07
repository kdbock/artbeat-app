import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'navigation_step_model.dart';

/// Model representing a complete route for an art walk with turn-by-turn navigation
class ArtWalkRouteModel {
  final String id; // Unique identifier for this route
  final String artWalkId; // ID of the art walk this route belongs to
  final List<RouteSegment> segments; // Route segments between art pieces
  final int totalDistanceMeters; // Total distance of the entire route
  final int totalDurationSeconds; // Total estimated duration
  final List<LatLng>
  overviewPolyline; // Simplified polyline for the entire route
  final DateTime createdAt; // When this route was generated
  final String? startAddress; // Starting address if available
  final String? endAddress; // Ending address if available

  ArtWalkRouteModel({
    required this.id,
    required this.artWalkId,
    required this.segments,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.overviewPolyline,
    required this.createdAt,
    this.startAddress,
    this.endAddress,
  });

  /// Create ArtWalkRouteModel from Google Maps Directions API response
  factory ArtWalkRouteModel.fromGoogleMapsRoute(
    String id,
    String artWalkId,
    Map<String, dynamic> route,
    List<String> artPieceIds,
  ) {
    final legs = route['legs'] as List<dynamic>;
    final overviewPolyline = route['overview_polyline'] as Map<String, dynamic>;

    final List<RouteSegment> segments = [];
    int totalDistance = 0;
    int totalDuration = 0;

    for (int i = 0; i < legs.length; i++) {
      final leg = legs[i] as Map<String, dynamic>;
      final steps = leg['steps'] as List<dynamic>;

      final List<NavigationStepModel> navigationSteps = steps
          .map(
            (step) => NavigationStepModel.fromGoogleMapsStep(
              step as Map<String, dynamic>,
            ),
          )
          .toList();

      final distance = leg['distance'] as Map<String, dynamic>;
      final duration = leg['duration'] as Map<String, dynamic>;
      final startAddress = leg['start_address'] as String?;
      final endAddress = leg['end_address'] as String?;

      final segmentDistance = distance['value'] as int;
      final segmentDuration = duration['value'] as int;

      segments.add(
        RouteSegment(
          fromArtPieceId: i == 0
              ? null
              : artPieceIds[i - 1], // null for start location
          toArtPieceId: artPieceIds[i],
          steps: navigationSteps,
          distanceMeters: segmentDistance,
          durationSeconds: segmentDuration,
          startAddress: startAddress,
          endAddress: endAddress,
        ),
      );

      totalDistance += segmentDistance;
      totalDuration += segmentDuration;
    }

    return ArtWalkRouteModel(
      id: id,
      artWalkId: artWalkId,
      segments: segments,
      totalDistanceMeters: totalDistance,
      totalDurationSeconds: totalDuration,
      overviewPolyline: NavigationStepModel.decodePolyline(
        overviewPolyline['points'] as String? ?? '',
      ),
      createdAt: DateTime.now(),
      startAddress: segments.isNotEmpty ? segments.first.startAddress : null,
      endAddress: segments.isNotEmpty ? segments.last.endAddress : null,
    );
  }

  /// Get formatted total distance
  String get formattedTotalDistance {
    if (totalDistanceMeters < 1000) {
      return '${totalDistanceMeters}m';
    } else {
      return '${(totalDistanceMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Get formatted total duration
  String get formattedTotalDuration {
    if (totalDurationSeconds < 60) {
      return '${totalDurationSeconds}s';
    } else if (totalDurationSeconds < 3600) {
      final minutes = (totalDurationSeconds / 60).round();
      return '${minutes}min';
    } else {
      final hours = (totalDurationSeconds / 3600).floor();
      final minutes = ((totalDurationSeconds % 3600) / 60).round();
      return '${hours}h ${minutes}min';
    }
  }

  /// Get all navigation steps for the entire route
  List<NavigationStepModel> get allSteps {
    final allSteps = <NavigationStepModel>[];
    for (final segment in segments) {
      allSteps.addAll(segment.steps);
    }
    return allSteps;
  }

  /// Get the route segment to a specific art piece
  RouteSegment? getSegmentToArtPiece(String artPieceId) {
    return segments.firstWhere(
      (segment) => segment.toArtPieceId == artPieceId,
      orElse: () => segments.first,
    );
  }
}

/// Represents a segment of the route between two points (start to art piece, or art piece to art piece)
class RouteSegment {
  final String? fromArtPieceId; // null if starting from user location
  final String toArtPieceId; // ID of the destination art piece
  final List<NavigationStepModel> steps; // Turn-by-turn steps for this segment
  final int distanceMeters; // Distance of this segment
  final int durationSeconds; // Duration of this segment
  final String? startAddress; // Starting address for this segment
  final String? endAddress; // Ending address for this segment

  RouteSegment({
    this.fromArtPieceId,
    required this.toArtPieceId,
    required this.steps,
    required this.distanceMeters,
    required this.durationSeconds,
    this.startAddress,
    this.endAddress,
  });

  /// Get formatted distance for this segment
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters}m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Get formatted duration for this segment
  String get formattedDuration {
    if (durationSeconds < 60) {
      return '${durationSeconds}s';
    } else {
      final minutes = (durationSeconds / 60).round();
      return '${minutes}min';
    }
  }

  /// Check if this segment is from the starting location
  bool get isFromStartingLocation => fromArtPieceId == null;
}

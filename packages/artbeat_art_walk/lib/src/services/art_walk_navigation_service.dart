import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

/// Service for handling turn-by-turn navigation during art walks
class ArtWalkNavigationService {
  final DirectionsService _directionsService;
  static const double _proximityThreshold = 20.0; // meters
  static const double _offRouteThreshold = 50.0; // meters

  // Stream controllers for real-time navigation updates
  final StreamController<NavigationUpdate> _navigationUpdateController =
      StreamController<NavigationUpdate>.broadcast();
  final StreamController<Position> _locationUpdateController =
      StreamController<Position>.broadcast();

  // Current navigation state
  ArtWalkRouteModel? _currentRoute;
  int _currentSegmentIndex = 0;
  int _currentStepIndex = 0;
  Position? _lastKnownPosition;
  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _locationSubscription;

  ArtWalkNavigationService({DirectionsService? directionsService})
    : _directionsService = directionsService ?? DirectionsService();

  /// Stream of navigation updates
  Stream<NavigationUpdate> get navigationUpdates {
    core.AppLogger.info('🧭 Navigation stream accessed');
    return _navigationUpdateController.stream;
  }

  /// Stream of location updates
  Stream<Position> get locationUpdates => _locationUpdateController.stream;

  /// Current route being navigated
  ArtWalkRouteModel? get currentRoute => _currentRoute;

  /// Current segment being navigated
  RouteSegment? get currentSegment =>
      _currentRoute?.segments[_currentSegmentIndex];

  /// Current step being navigated
  NavigationStepModel? get currentStep =>
      currentSegment?.steps[_currentStepIndex];

  /// Progress through the current segment (0.0 to 1.0)
  double get segmentProgress => currentSegment?.steps.isEmpty == true
      ? 0.0
      : _currentStepIndex / currentSegment!.steps.length;

  /// Progress through the entire route (0.0 to 1.0)
  double get routeProgress => _currentRoute?.segments.isEmpty == true
      ? 0.0
      : (_currentSegmentIndex + segmentProgress) /
            _currentRoute!.segments.length;

  /// Generate a complete route for an art walk with optimized waypoints
  Future<ArtWalkRouteModel> generateRoute(
    String artWalkId,
    List<PublicArtModel> artPieces,
    Position startPosition,
  ) async {
    core.AppLogger.info(
      '🧭 Generating route for ${artPieces.length} art pieces',
    );

    if (artPieces.isEmpty) {
      throw Exception('No art pieces provided for route generation');
    }

    // Create origin and destination
    final origin = '${startPosition.latitude},${startPosition.longitude}';
    final destination = origin; // Return to start for circular route

    // Create waypoints for intermediate art pieces (all except the last one)
    final waypoints = <String>[];

    // Add all art pieces as waypoints for a complete route
    for (int i = 0; i < artPieces.length; i++) {
      final artPiece = artPieces[i];
      waypoints.add(
        '${artPiece.location.latitude},${artPiece.location.longitude}',
      );
    }

    try {
      // Use the DirectionsService to get route data with waypoints
      final directionsData = await _directionsService.getDirections(
        origin,
        destination,
        waypoints: waypoints,
      );

      // Validate the response
      if (directionsData['routes'] == null ||
          (directionsData['routes'] as List).isEmpty) {
        throw Exception('No routes found in directions response');
      }

      // Create route model from directions data
      final routeId =
          'route_${artWalkId}_${DateTime.now().millisecondsSinceEpoch}';
      final route = ArtWalkRouteModel.fromGoogleMapsRoute(
        routeId,
        artWalkId,
        directionsData['routes'][0] as Map<String, dynamic>,
        artPieces.map((art) => art.id).toList(),
      );

      core.AppLogger.info(
        '🧭 Generated Google route with ${route.segments.length} segments',
      );
      return route;
    } catch (e) {
      // If Google Directions fails, create a simple route
      core.AppLogger.info(
        '🧭 Google Directions failed: $e. Creating simple route.',
      );
      final simpleRoute = _createSimpleRoute(
        artWalkId,
        artPieces,
        startPosition,
      );
      core.AppLogger.info(
        '🧭 Generated simple route with ${simpleRoute.segments.length} segments',
      );
      return simpleRoute;
    }
  }

  /// Create a simple route without Google Directions API
  /// This is a fallback when the API is unavailable or fails
  ArtWalkRouteModel _createSimpleRoute(
    String artWalkId,
    List<PublicArtModel> artPieces,
    Position startPosition,
  ) {
    final routeId =
        'simple_route_${artWalkId}_${DateTime.now().millisecondsSinceEpoch}';
    final segments = <RouteSegment>[];

    // Create segments between consecutive points
    final allPoints = [
      LatLng(startPosition.latitude, startPosition.longitude),
      ...artPieces.map(
        (art) => LatLng(art.location.latitude, art.location.longitude),
      ),
      LatLng(
        startPosition.latitude,
        startPosition.longitude,
      ), // Return to start
    ];

    for (int i = 0; i < allPoints.length - 1; i++) {
      final from = allPoints[i];
      final to = allPoints[i + 1];

      // Calculate distance and bearing
      final distance = Geolocator.distanceBetween(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      );

      final bearing = Geolocator.bearingBetween(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      );

      // Create simple navigation step
      final step = NavigationStepModel(
        instruction: _generateSimpleInstruction(bearing, distance),
        maneuver: 'straight',
        distanceMeters: distance.round(),
        durationSeconds: (distance / 1.4)
            .round(), // Assume 1.4 m/s walking speed
        startLocation: from,
        endLocation: to,
        polylinePoints: [from, to], // Simple straight line
      );

      // Create segment
      final segment = RouteSegment(
        fromArtPieceId: i > 0 ? artPieces[i - 1].id : null,
        toArtPieceId: i < artPieces.length ? artPieces[i].id : 'start',
        steps: [step],
        distanceMeters: distance.round(),
        durationSeconds: step.durationSeconds,
      );

      segments.add(segment);
    }

    return ArtWalkRouteModel(
      id: routeId,
      artWalkId: artWalkId,
      segments: segments,
      totalDistanceMeters: segments.fold(
        0,
        (sum, segment) => sum + segment.distanceMeters,
      ),
      totalDurationSeconds: segments.fold(
        0,
        (sum, segment) => sum + segment.durationSeconds,
      ),
      overviewPolyline: allPoints,
      createdAt: DateTime.now(),
    );
  }

  /// Generate simple navigation instruction based on bearing
  String _generateSimpleInstruction(double bearing, double distance) {
    final distanceText = distance > 1000
        ? '${(distance / 1000).toStringAsFixed(1)} km'
        : '${distance.round()} m';

    String direction;
    if (bearing >= -22.5 && bearing < 22.5) {
      direction = 'north';
    } else if (bearing >= 22.5 && bearing < 67.5) {
      direction = 'northeast';
    } else if (bearing >= 67.5 && bearing < 112.5) {
      direction = 'east';
    } else if (bearing >= 112.5 && bearing < 157.5) {
      direction = 'southeast';
    } else if (bearing >= 157.5 || bearing < -157.5) {
      direction = 'south';
    } else if (bearing >= -157.5 && bearing < -112.5) {
      direction = 'southwest';
    } else if (bearing >= -112.5 && bearing < -67.5) {
      direction = 'west';
    } else {
      direction = 'northwest';
    }

    return 'Head $direction for $distanceText';
  }

  /// Start navigation for a given route
  Future<void> startNavigation(ArtWalkRouteModel route) async {
    core.AppLogger.info('🧭 Starting navigation for route: ${route.id}');
    core.AppLogger.info('🧭 Route has ${route.segments.length} segments');

    _currentRoute = route;
    _currentSegmentIndex = 0;
    _currentStepIndex = 0;

    // Debug current state
    core.AppLogger.info(
      '🧭 Current segment: ${currentSegment?.fromArtPieceId} -> ${currentSegment?.toArtPieceId}',
    );
    core.AppLogger.info('🧭 Current step: ${currentStep?.instruction}');

    // Start location monitoring
    await _startLocationMonitoring();

    // Send initial navigation update
    _sendNavigationUpdate(NavigationUpdateType.routeStarted);
    core.AppLogger.info('🧭 Initial navigation update sent');
  }

  /// Stop navigation and clean up resources
  Future<void> stopNavigation() async {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;

    await _locationSubscription?.cancel();
    _locationSubscription = null;

    _currentRoute = null;
    _currentSegmentIndex = 0;
    _currentStepIndex = 0;
    _lastKnownPosition = null;

    _sendNavigationUpdate(NavigationUpdateType.routeStopped);
  }

  /// Move to the next step in navigation
  void nextStep() {
    if (_currentRoute == null || currentSegment == null) return;

    if (_currentStepIndex < currentSegment!.steps.length - 1) {
      _currentStepIndex++;
      _sendNavigationUpdate(NavigationUpdateType.stepChanged);
    } else {
      // Move to next segment
      nextSegment();
    }
  }

  /// Move to the next segment (art piece)
  void nextSegment() {
    if (_currentRoute == null) return;

    if (_currentSegmentIndex < _currentRoute!.segments.length - 1) {
      _currentSegmentIndex++;
      _currentStepIndex = 0;
      _sendNavigationUpdate(NavigationUpdateType.segmentChanged);
    } else {
      // Route completed
      _sendNavigationUpdate(NavigationUpdateType.routeCompleted);
    }
  }

  /// Calculate distance from current position to next waypoint
  double? getDistanceToNextWaypoint() {
    if (_lastKnownPosition == null || currentStep == null) return null;

    // Calculate distance to the end location of the current step
    return Geolocator.distanceBetween(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      currentStep!.endLocation.latitude,
      currentStep!.endLocation.longitude,
    );
  }

  /// Check if user is close to the next waypoint
  bool isNearNextWaypoint() {
    final distance = getDistanceToNextWaypoint();
    return distance != null && distance <= _proximityThreshold;
  }

  /// Check if user is off the planned route
  bool isOffRoute() {
    if (_lastKnownPosition == null || currentStep == null) return false;

    // Calculate distance from current position to the route line
    final distanceToRoute = _calculateDistanceToPolyline(
      LatLng(_lastKnownPosition!.latitude, _lastKnownPosition!.longitude),
      currentStep!.polylinePoints,
    );

    return distanceToRoute > _offRouteThreshold;
  }

  /// Start monitoring location updates
  Future<void> _startLocationMonitoring() async {
    core.AppLogger.info('🧭 Starting location monitoring...');
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium, // Reduced from high to medium
      distanceFilter: 10, // Increased from 5 to 10 meters to reduce updates
      timeLimit: Duration(
        minutes: 30,
      ), // Add time limit to prevent indefinite tracking
    );

    final locationStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );

    _locationSubscription = locationStream.listen(
      (Position position) {
        core.AppLogger.info(
          '🧭 Location update received: ${position.latitude}, ${position.longitude}',
        );
        if (!_locationUpdateController.isClosed) {
          _lastKnownPosition = position;
          _locationUpdateController.add(position);
          _processLocationUpdate(position);
        }
      },
      onError: (Object error) {
        // Handle location stream errors gracefully
        core.AppLogger.error('Location stream error: $error');
        // Try to restart location monitoring after a delay
        Future.delayed(const Duration(seconds: 5), () {
          if (_currentRoute != null && !_locationUpdateController.isClosed) {
            _startLocationMonitoring();
          }
        });
      },
      cancelOnError: false, // Don't cancel the stream on errors
    );

    // Add a safety timer to prevent indefinite location tracking
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Check if navigation is still active
      if (_currentRoute == null || _locationUpdateController.isClosed) {
        timer.cancel();
        _locationSubscription?.cancel();
      }
    });
  }

  /// Process location updates and check for navigation events
  void _processLocationUpdate(Position position) {
    if (_currentRoute == null) return;

    // Check if near next waypoint
    if (isNearNextWaypoint()) {
      _sendNavigationUpdate(NavigationUpdateType.approachingWaypoint);
      // Auto-advance to next step
      nextStep();
    }

    // Check if off route
    if (isOffRoute()) {
      _sendNavigationUpdate(NavigationUpdateType.offRoute);
    }

    // Send general location update
    _sendNavigationUpdate(NavigationUpdateType.locationUpdate);
  }

  /// Send navigation update to listeners
  void _sendNavigationUpdate(NavigationUpdateType type) {
    final update = NavigationUpdate(
      type: type,
      currentSegment: currentSegment,
      currentStep: currentStep,
      segmentProgress: segmentProgress,
      routeProgress: routeProgress,
      distanceToNextWaypoint: getDistanceToNextWaypoint(),
      isOffRoute: isOffRoute(),
      currentPosition: _lastKnownPosition,
    );

    core.AppLogger.info('🧭 Sending navigation update: $type');
    core.AppLogger.info(
      '🧭 Current step instruction: ${update.currentStep?.instruction}',
    );
    core.AppLogger.info(
      '🧭 Route progress: ${(update.routeProgress * 100).toInt()}%',
    );

    if (!_navigationUpdateController.isClosed) {
      _navigationUpdateController.add(update);
    } else {
      core.AppLogger.warning('🧭 Navigation update controller is closed!');
    }
  }

  /// Calculate distance from a point to a polyline
  double _calculateDistanceToPolyline(LatLng point, List<LatLng> polyline) {
    double minDistance = double.infinity;

    for (int i = 0; i < polyline.length - 1; i++) {
      final distance = _calculateDistanceToLineSegment(
        point,
        polyline[i],
        polyline[i + 1],
      );
      minDistance = math.min(minDistance, distance);
    }

    return minDistance;
  }

  /// Calculate distance from a point to a line segment
  double _calculateDistanceToLineSegment(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    final A = point.latitude - lineStart.latitude;
    final B = point.longitude - lineStart.longitude;
    final C = lineEnd.latitude - lineStart.latitude;
    final D = lineEnd.longitude - lineStart.longitude;

    final dot = A * C + B * D;
    final lenSquared = C * C + D * D;

    double param = -1;
    if (lenSquared != 0) {
      param = dot / lenSquared;
    }

    double xx, yy;
    if (param < 0) {
      xx = lineStart.latitude;
      yy = lineStart.longitude;
    } else if (param > 1) {
      xx = lineEnd.latitude;
      yy = lineEnd.longitude;
    } else {
      xx = lineStart.latitude + param * C;
      yy = lineStart.longitude + param * D;
    }

    return Geolocator.distanceBetween(point.latitude, point.longitude, xx, yy);
  }

  /// Dispose of resources
  void dispose() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;

    _locationSubscription?.cancel();
    _locationSubscription = null;

    _currentRoute = null;
    _lastKnownPosition = null;

    if (!_navigationUpdateController.isClosed) {
      _navigationUpdateController.close();
    }
    if (!_locationUpdateController.isClosed) {
      _locationUpdateController.close();
    }
  }
}

/// Types of navigation updates
enum NavigationUpdateType {
  routeStarted,
  routeStopped,
  routeCompleted,
  segmentChanged,
  stepChanged,
  approachingWaypoint,
  offRoute,
  locationUpdate,
}

/// Navigation update data structure
class NavigationUpdate {
  final NavigationUpdateType type;
  final RouteSegment? currentSegment;
  final NavigationStepModel? currentStep;
  final double segmentProgress;
  final double routeProgress;
  final double? distanceToNextWaypoint;
  final bool isOffRoute;
  final Position? currentPosition;

  NavigationUpdate({
    required this.type,
    this.currentSegment,
    this.currentStep,
    required this.segmentProgress,
    required this.routeProgress,
    this.distanceToNextWaypoint,
    required this.isOffRoute,
    this.currentPosition,
  });
}

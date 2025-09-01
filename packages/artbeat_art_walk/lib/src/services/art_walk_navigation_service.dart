import 'dart:async';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

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
  Stream<NavigationUpdate> get navigationUpdates =>
      _navigationUpdateController.stream;

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

  /// Generate a complete route for an art walk
  Future<ArtWalkRouteModel> generateRoute(
    String artWalkId,
    List<PublicArtModel> artPieces,
    Position startPosition,
  ) async {
    if (artPieces.isEmpty) {
      throw Exception('No art pieces provided for route generation');
    }

    // Create waypoints list starting from user location
    final waypoints = <String>[];
    waypoints.add('${startPosition.latitude},${startPosition.longitude}');

    // Add all art piece locations
    for (final artPiece in artPieces) {
      waypoints.add(
        '${artPiece.location.latitude},${artPiece.location.longitude}',
      );
    }

    // Use the existing DirectionsService to get route data
    final directionsData = await _directionsService.getDirections(
      waypoints.first,
      waypoints.last,
      // Pass waypoints as intermediate stops - this might need API modification
    );

    // Create route model from directions data
    final routeId =
        'route_${artWalkId}_${DateTime.now().millisecondsSinceEpoch}';
    final route = ArtWalkRouteModel.fromGoogleMapsRoute(
      routeId,
      artWalkId,
      directionsData['routes'][0] as Map<String, dynamic>,
      artPieces.map((art) => art.id).toList(),
    );

    return route;
  }

  /// Start navigation for a given route
  Future<void> startNavigation(ArtWalkRouteModel route) async {
    _currentRoute = route;
    _currentSegmentIndex = 0;
    _currentStepIndex = 0;

    // Start location monitoring
    await _startLocationMonitoring();

    // Send initial navigation update
    _sendNavigationUpdate(NavigationUpdateType.routeStarted);
  }

  /// Stop navigation and clean up resources
  Future<void> stopNavigation() async {
    _locationUpdateTimer?.cancel();
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
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    final locationStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );

    _locationSubscription = locationStream.listen((Position position) {
      if (!_locationUpdateController.isClosed) {
        _lastKnownPosition = position;
        _locationUpdateController.add(position);
        _processLocationUpdate(position);
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

    if (!_navigationUpdateController.isClosed) {
      _navigationUpdateController.add(update);
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
    _locationSubscription?.cancel();
    _navigationUpdateController.close();
    _locationUpdateController.close();
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

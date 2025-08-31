import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Enhanced art walk experience screen with turn-by-turn navigation
class EnhancedArtWalkExperienceScreen extends StatefulWidget {
  final String artWalkId;
  final ArtWalkModel artWalk;

  const EnhancedArtWalkExperienceScreen({
    super.key,
    required this.artWalkId,
    required this.artWalk,
  });

  @override
  State<EnhancedArtWalkExperienceScreen> createState() =>
      _EnhancedArtWalkExperienceScreenState();
}

class _EnhancedArtWalkExperienceScreenState
    extends State<EnhancedArtWalkExperienceScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<PublicArtModel> _artPieces = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<String> _visitedArtIds = [];
  bool _isLoading = true;
  bool _isWalkCompleted = false;
  bool _isNavigationMode = false;
  bool _showCompactNavigation = false;

  // Navigation services
  final ArtWalkService _artWalkService = ArtWalkService();
  late ArtWalkNavigationService _navigationService;
  ArtWalkRouteModel? _currentRoute;

  @override
  void initState() {
    super.initState();
    _navigationService = ArtWalkNavigationService();
    _initializeWalk();
  }

  @override
  void dispose() {
    _navigationService.dispose();
    super.dispose();
  }

  Future<void> _initializeWalk() async {
    await _getCurrentLocation();
    await _loadArtPieces();
    await _loadVisitedArt();
    _createMarkersAndRoute();

    setState(() {
      _isLoading = false;
    });

    // Auto-start navigation if user location is available and there are art pieces
    if (_currentPosition != null && _artPieces.isNotEmpty) {
      // Show a brief message that navigation is starting
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Starting turn-by-turn navigation...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Small delay to ensure UI is ready
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        _startNavigation();
      }
    } else if (_currentPosition == null) {
      // Show message if location is not available
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location not available. Please enable location services for navigation.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      // debugPrint('Error getting current location: $e');
    }
  }

  Future<void> _loadArtPieces() async {
    try {
      final artPieces = await _artWalkService.getArtInWalk(widget.artWalkId);
      setState(() {
        _artPieces = artPieces;
      });
    } catch (e) {
      // debugPrint('Error loading art pieces: $e');
    }
  }

  Future<void> _loadVisitedArt() async {
    try {
      final visitedIds = await _artWalkService.getUserVisitedArt(
        widget.artWalkId,
      );
      setState(() {
        _visitedArtIds = visitedIds;
        _isWalkCompleted =
            _visitedArtIds.length == _artPieces.length && _artPieces.isNotEmpty;
      });
    } catch (e) {
      // debugPrint('Error loading visited art: $e');
    }
  }

  void _createMarkersAndRoute() {
    if (_artPieces.isEmpty) return;

    final markers = <Marker>{};
    final polylinePoints = <LatLng>[];

    // Add current location marker if available
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
      polylinePoints.add(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      );
    }

    // Create markers for each art piece
    for (int i = 0; i < _artPieces.length; i++) {
      final art = _artPieces[i];
      final isVisited = _visitedArtIds.contains(art.id);
      final isNext = i == _getNextUnvisitedIndex() && !isVisited;

      markers.add(
        Marker(
          markerId: MarkerId(art.id),
          position: LatLng(art.location.latitude, art.location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isVisited
                ? BitmapDescriptor.hueGreen
                : isNext
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: '${i + 1}. ${art.title}',
            snippet: isVisited ? 'Visited ✓' : 'Tap for details',
          ),
          onTap: () => _showArtDetail(art),
        ),
      );

      polylinePoints.add(LatLng(art.location.latitude, art.location.longitude));
    }

    // Create route polyline
    if (polylinePoints.length > 1) {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('art_walk_route'),
          points: polylinePoints,
          color: _isNavigationMode ? Colors.blue : Colors.grey,
          width: _isNavigationMode ? 5 : 3,
          patterns: _isNavigationMode
              ? []
              : [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _startNavigation() async {
    if (_currentPosition == null || _artPieces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to start navigation. Check your location settings.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Generate route
      final route = await _navigationService.generateRoute(
        widget.artWalkId,
        _artPieces,
        _currentPosition!,
      );

      setState(() {
        _currentRoute = route;
        _isNavigationMode = true;
        _isLoading = false;
      });

      // Start navigation
      await _navigationService.startNavigation(route);

      // Update map with detailed route
      _updateMapWithRoute(route);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Navigation started! Follow the turn-by-turn instructions.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start navigation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopNavigation() async {
    await _navigationService.stopNavigation();
    setState(() {
      _isNavigationMode = false;
      _currentRoute = null;
      _showCompactNavigation = false;
    });
    _createMarkersAndRoute();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation stopped.'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  void _updateMapWithRoute(ArtWalkRouteModel route) {
    // Update polylines with detailed route
    final polylines = <Polyline>{};

    for (int i = 0; i < route.segments.length; i++) {
      final segment = route.segments[i];
      final polylinePoints = <LatLng>[];

      for (final step in segment.steps) {
        polylinePoints.addAll(step.polylinePoints);
      }

      if (polylinePoints.isNotEmpty) {
        polylines.add(
          Polyline(
            polylineId: PolylineId('segment_$i'),
            points: polylinePoints,
            color: Colors.blue,
            width: 5,
          ),
        );
      }
    }

    setState(() {
      _polylines = polylines;
    });
  }

  void _showArtDetail(PublicArtModel art) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ArtDetailBottomSheet(
        art: art,
        onVisitPressed: () => _markAsVisited(art),
        isVisited: _visitedArtIds.contains(art.id),
        distanceText: _getDistanceToArt(art),
      ),
    );
  }

  Future<void> _markAsVisited(PublicArtModel art) async {
    if (_visitedArtIds.contains(art.id)) return;

    try {
      final success = await _artWalkService.recordArtVisit(
        artWalkId: widget.artWalkId,
        artId: art.id,
      );

      if (success) {
        setState(() {
          _visitedArtIds.add(art.id);
          _isWalkCompleted = _visitedArtIds.length == _artPieces.length;
        });

        _createMarkersAndRoute();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${art.title} marked as visited! +5 XP'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        if (_isWalkCompleted) {
          _showWalkCompletionDialog();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking as visited: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWalkCompletionDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Walk Completed!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Congratulations! You\'ve completed this art walk.'),
            SizedBox(height: 16),
            Text('Rewards earned:'),
            Text('• +50 XP for completion'),
            Text('• Achievement progress updated'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeWalk();
            },
            child: const Text('Claim Rewards'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeWalk() async {
    try {
      await _artWalkService.recordArtWalkCompletion(
        artWalkId: widget.artWalkId,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing walk: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getDistanceToArt(PublicArtModel art) {
    if (_currentPosition == null) return '';

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      art.location.latitude,
      art.location.longitude,
    );

    if (distance < 1000) {
      return '${distance.round()}m away';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km away';
    }
  }

  int _getNextUnvisitedIndex() {
    for (int i = 0; i < _artPieces.length; i++) {
      if (!_visitedArtIds.contains(_artPieces[i].id)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MainLayout(
        currentIndex: -1,
        child: Scaffold(
          appBar: EnhancedUniversalHeader(
            title: widget.artWalk.title,
            showLogo: false,
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: EnhancedUniversalHeader(
          title: widget.artWalk.title,
          showLogo: false,
          actions: [
            if (_isNavigationMode)
              IconButton(
                icon: Icon(
                  _showCompactNavigation
                      ? Icons.expand_more
                      : Icons.expand_less,
                ),
                onPressed: () {
                  setState(() {
                    _showCompactNavigation = !_showCompactNavigation;
                  });
                },
              ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('How to Use'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• Tap "Start Navigation" for turn-by-turn directions',
                        ),
                        const Text('• Follow the blue route line'),
                        const Text('• Tap markers to view art details'),
                        const Text('• Mark art as visited when you reach it'),
                        const Text('• Green markers = visited'),
                        const Text('• Orange marker = next destination'),
                        const Text('• Red markers = not yet visited'),
                        if (_isNavigationMode) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Navigation Mode:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text('• Follow turn-by-turn instructions'),
                          const Text(
                            '• Tap expand/collapse button to adjust navigation view',
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            // Map
            GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                _centerOnUserLocation();
              },
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null
                    ? LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      )
                    : _artPieces.isNotEmpty
                    ? LatLng(
                        _artPieces[0].location.latitude,
                        _artPieces[0].location.longitude,
                      )
                    : const LatLng(35.5951, -82.5515),
                zoom: 16.0,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),

            // Progress card
            if (!_isNavigationMode || _showCompactNavigation)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress: ${_visitedArtIds.length}/${_artPieces.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_currentRoute != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _currentRoute!.formattedTotalDistance,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _artPieces.isEmpty
                              ? 0.0
                              : _visitedArtIds.length / _artPieces.length,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isWalkCompleted ? Colors.green : Colors.blue,
                          ),
                        ),
                        if (!_isWalkCompleted && _artPieces.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Next: ${_artPieces[_getNextUnvisitedIndex()].title}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                        if (_isWalkCompleted) ...[
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Walk Completed! 🎉',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            // Turn-by-turn navigation widget
            if (_isNavigationMode)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: TurnByTurnNavigationWidget(
                  navigationService: _navigationService,
                  isCompact: _showCompactNavigation,
                  onNextStep: () => _navigationService.nextStep(),
                  onPreviousStep: () {
                    // Implement previous step logic if needed
                  },
                  onStopNavigation: _stopNavigation,
                ),
              ),

            // Navigation control button
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!_isNavigationMode)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _startNavigation,
                        icon: const Icon(Icons.navigation),
                        label: const Text('Start Navigation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _stopNavigation,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop Navigation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _currentPosition != null
            ? FloatingActionButton(
                onPressed: _centerOnUserLocation,
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                tooltip: 'Center on my location',
                child: const Icon(Icons.my_location),
              )
            : null,
      ),
    );
  }

  void _centerOnUserLocation() {
    if (_currentPosition == null || _mapController == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        16.0,
      ),
    );
  }
}

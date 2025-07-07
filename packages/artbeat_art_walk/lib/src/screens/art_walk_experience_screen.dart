import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'dart:math' as math;

/// Screen for experiencing a self-guided art walk
class ArtWalkExperienceScreen extends StatefulWidget {
  final String artWalkId;
  final ArtWalkModel artWalk;

  const ArtWalkExperienceScreen({
    super.key,
    required this.artWalkId,
    required this.artWalk,
  });

  @override
  State<ArtWalkExperienceScreen> createState() =>
      _ArtWalkExperienceScreenState();
}

class _ArtWalkExperienceScreenState extends State<ArtWalkExperienceScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<PublicArtModel> _artPieces = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<String> _visitedArtIds = [];
  int _currentArtIndex = 0;
  bool _isLoading = true;
  bool _isWalkCompleted = false;

  final ArtWalkService _artWalkService = ArtWalkService();

  @override
  void initState() {
    super.initState();
    _initializeWalk();
  }

  /// Calculate distance between two points in miles
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 3959.0; // miles
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Get distance from user's current location to an art piece
  String _getDistanceToArt(PublicArtModel art) {
    if (_currentPosition == null) return '';

    final distance = _calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      art.location.latitude,
      art.location.longitude,
    );

    if (distance < 1) {
      return '${(distance * 5280).round()}ft away';
    } else {
      return '${distance.toStringAsFixed(1)}mi away';
    }
  }

  /// Calculate total walk distance
  double _calculateTotalDistance() {
    if (_artPieces.isEmpty) return 0.0;

    double totalDistance = 0.0;

    // Add distance from current location to first art piece
    if (_currentPosition != null) {
      totalDistance += _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _artPieces[0].location.latitude,
        _artPieces[0].location.longitude,
      );
    }

    // Add distances between consecutive art pieces
    for (int i = 0; i < _artPieces.length - 1; i++) {
      totalDistance += _calculateDistance(
        _artPieces[i].location.latitude,
        _artPieces[i].location.longitude,
        _artPieces[i + 1].location.latitude,
        _artPieces[i + 1].location.longitude,
      );
    }

    return totalDistance;
  }

  Future<void> _initializeWalk() async {
    await _getCurrentLocation();
    await _loadArtPieces();
    await _loadVisitedArt();
    _createMarkersAndRoute();
    setState(() {
      _isLoading = false;
    });
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
      debugPrint('Error getting current location: $e');
    }
  }

  Future<void> _loadArtPieces() async {
    try {
      final artPieces = await _artWalkService.getArtInWalk(widget.artWalkId);
      setState(() {
        _artPieces = artPieces;
      });
    } catch (e) {
      debugPrint('Error loading art pieces: $e');
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
      debugPrint('Error loading visited art: $e');
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
          infoWindow: const InfoWindow(title: 'Your Starting Point'),
        ),
      );
      // Add current location to polyline to show route from start
      polylinePoints.add(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      );
    }

    // Create markers for each art piece
    for (int i = 0; i < _artPieces.length; i++) {
      final art = _artPieces[i];
      final isVisited = _visitedArtIds.contains(art.id);
      final isCurrent = i == _currentArtIndex && !isVisited;
      final distance = _getDistanceToArt(art);

      markers.add(
        Marker(
          markerId: MarkerId(art.id),
          position: LatLng(art.location.latitude, art.location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isVisited
                ? BitmapDescriptor.hueGreen
                : isCurrent
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: '${i + 1}. ${art.title}',
            snippet: isVisited
                ? 'Visited ✓'
                : distance.isEmpty
                ? 'Tap to visit'
                : '$distance • Tap to visit',
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
          color: Colors.blue,
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    }

    setState(() {
      _markers = markers;
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
      // Record the visit
      final success = await _artWalkService.recordArtVisit(
        artWalkId: widget.artWalkId,
        artId: art.id,
      );

      if (success) {
        setState(() {
          _visitedArtIds.add(art.id);
          _currentArtIndex = _getNextUnvisitedIndex();
          _isWalkCompleted = _visitedArtIds.length == _artPieces.length;
        });

        _createMarkersAndRoute();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${art.title} marked as visited! +5 XP'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Check if walk is completed
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

  int _getNextUnvisitedIndex() {
    for (int i = 0; i < _artPieces.length; i++) {
      if (!_visitedArtIds.contains(_artPieces[i].id)) {
        return i;
      }
    }
    return 0;
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
              Navigator.of(context).pop(); // Close dialog
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

      // Navigate back with success
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

  void _centerOnCurrentArt() {
    if (_artPieces.isEmpty || _mapController == null) return;

    final currentArt = _artPieces[_currentArtIndex];
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(currentArt.location.latitude, currentArt.location.longitude),
        16.0,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.artWalk.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artWalk.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to Use'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Follow the blue dashed route'),
                      Text('• Tap markers to view art details'),
                      Text('• Mark art as visited when you reach it'),
                      Text('• Green markers = visited'),
                      Text('• Orange marker = next destination'),
                      Text('• Red markers = not yet visited'),
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
              if (_artPieces.isNotEmpty) {
                _centerOnCurrentArt();
              }
            },
            initialCameraPosition: CameraPosition(
              target: _artPieces.isNotEmpty
                  ? LatLng(
                      _artPieces[0].location.latitude,
                      _artPieces[0].location.longitude,
                    )
                  : const LatLng(35.5951, -82.5515), // Default to Asheville
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Progress card
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
                        if (_currentPosition != null) ...[
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
                              'Total: ${_calculateTotalDistance().toStringAsFixed(1)}mi',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Next: ${_artPieces[_currentArtIndex].title}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          if (_currentPosition != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getDistanceToArt(_artPieces[_currentArtIndex]),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
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

          // Control buttons
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'center_art',
                  mini: true,
                  onPressed: _centerOnCurrentArt,
                  child: const Icon(Icons.center_focus_strong),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'center_user',
                  mini: true,
                  onPressed: _centerOnUserLocation,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

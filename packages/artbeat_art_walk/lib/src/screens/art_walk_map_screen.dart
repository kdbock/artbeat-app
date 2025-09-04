import 'dart:async';
import 'dart:io' show SocketException;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_capture/src/screens/capture_detail_screen.dart';
import '../widgets/art_walk_drawer.dart';

/// Screen that displays a map with nearby captures and art walks
class ArtWalkMapScreen extends StatefulWidget {
  const ArtWalkMapScreen({super.key});

  @override
  State<ArtWalkMapScreen> createState() => _ArtWalkMapScreenState();
}

class _ArtWalkMapScreenState extends State<ArtWalkMapScreen> {
  // Services
  final CaptureService _captureService = CaptureService();
  final UserService _userService = UserService();

  // Map controller and state
  GoogleMapController? _mapController;
  Position? _currentPosition;
  String _currentZipCode = '';
  bool _hasMovedToUserLocation = false;
  bool _isLoading = true;
  bool _isSearchingZip = false;
  bool _hasMapError = false;
  String _mapErrorMessage = '';
  bool _showCapturesSlider = false;

  // Map data
  final Set<Marker> _markers = <Marker>{};
  List<CaptureModel> _nearbyCaptures = [];
  String _artFilter = 'all'; // 'all', 'public', 'captures', 'my_captures'

  // Location and timer
  Timer? _locationUpdateTimer;
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(35.23838, -77.52658), // Kinston, NC - 28501
    zoom: 10.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeMapsAndLocation();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Initialize maps and location
  Future<void> _initializeMapsAndLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasMapError = false;
    });

    try {
      // Get user's saved ZIP code from profile
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userProfile = await _userService.getUserProfile(user.uid);
        if (userProfile != null &&
            userProfile['zipCode'] != null &&
            userProfile['zipCode'].toString().isNotEmpty) {
          _currentZipCode = userProfile['zipCode'].toString();
        }
      }

      // Priority 1: Try to get current location
      final position = await _tryGetCurrentLocation();
      if (position != null && mounted) {
        setState(() => _currentPosition = position);
        await _moveMapToLocation(position.latitude, position.longitude, 14.0);
        await _loadNearbyCaptures(position.latitude, position.longitude);
        _startLocationUpdates();
      } else if (_currentZipCode.isNotEmpty) {
        // Priority 2: Use user's saved ZIP code
        final coordinates = await _getCoordinatesFromZipCode(_currentZipCode);
        if (coordinates != null) {
          await _moveMapToLocation(
            coordinates.latitude,
            coordinates.longitude,
            12.0,
          );
          await _loadNearbyCaptures(
            coordinates.latitude,
            coordinates.longitude,
          );
        } else {
          // Fallback to default location if ZIP code lookup fails
          await _moveMapToLocation(
            _defaultLocation.target.latitude,
            _defaultLocation.target.longitude,
            10.0,
          );
          await _loadNearbyCaptures(
            _defaultLocation.target.latitude,
            _defaultLocation.target.longitude,
          );
        }
      } else {
        // Priority 3: Use default location (Kinston, NC - 28501)
        await _moveMapToLocation(
          _defaultLocation.target.latitude,
          _defaultLocation.target.longitude,
          10.0,
        );
        await _loadNearbyCaptures(
          _defaultLocation.target.latitude,
          _defaultLocation.target.longitude,
        );
      }
    } catch (e) {
      debugPrint('❌ Error initializing location: $e');
      if (mounted) {
        setState(() {
          _hasMapError = true;
          _mapErrorMessage =
              'Error getting location: ${e.toString().split('] ').last}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Try to get user's current location with proper error handling
  Future<Position?> _tryGetCurrentLocation() async {
    try {
      // Check if location services are enabled
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services are disabled. Using saved location or default.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return null;
      }

      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission denied. Using saved location or default.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position with a timeout
      final position =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              // If getting high accuracy location times out, try lower accuracy
              return Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.medium,
                  timeLimit: Duration(seconds: 5),
                ),
              );
            },
          );

      return position;
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location services timed out. Using saved location or default.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return null;
    } catch (e) {
      if (e is SocketException) {
        _showSnackBar('Network error. Using saved location or default.');
      }
      return null;
    }
  }

  /// Get coordinates from ZIP code
  Future<LatLng?> _getCoordinatesFromZipCode(String zipCode) async {
    try {
      if (zipCode == '28501') {
        return const LatLng(35.23838, -77.52658);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Move map to specified location
  Future<void> _moveMapToLocation(
    double latitude,
    double longitude,
    double zoom,
  ) async {
    if (_mapController != null && mounted && !_hasMovedToUserLocation) {
      try {
        await _mapController!
            .animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: LatLng(latitude, longitude), zoom: zoom),
              ),
            )
            .timeout(const Duration(seconds: 3));
        _hasMovedToUserLocation = true;
      } catch (e) {
        debugPrint('⚠️ Error animating camera: $e');
      }
    }
  }

  /// Load nearby captures for given coordinates
  Future<void> _loadNearbyCaptures(double latitude, double longitude) async {
    try {
      // Get all captures and filter by location
      final allCaptures = await _captureService.getAllCaptures(limit: 100);

      // Filter captures by distance (within 10km radius)
      final nearbyCaptures = <CaptureModel>[];
      for (final capture in allCaptures) {
        if (capture.location != null) {
          final distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            capture.location!.latitude,
            capture.location!.longitude,
          );

          // Convert distance from meters to kilometers
          if (distance / 1000 <= 10.0) {
            nearbyCaptures.add(capture);
          }
        }
      }

      if (mounted) {
        setState(() {
          _nearbyCaptures = nearbyCaptures;
        });
        _updateMarkers();
      }
    } catch (e) {
      debugPrint('❌ Error loading nearby captures: $e');
      if (mounted) {
        setState(() {
          _nearbyCaptures = [];
        });
        _updateMarkers();
      }
    }
  }

  /// Update user's ZIP code in profile
  Future<void> _updateUserZipCode(String zipCode) async {
    try {
      await _userService.updateUserZipCode(zipCode);
    } catch (e) {
      debugPrint('❌ Error updating user ZIP code: $e');
    }
  }

  /// Update markers on the map based on nearby captures
  void _updateMarkers() {
    if (!mounted) return;

    setState(() {
      _markers.clear();
      for (final capture in _nearbyCaptures) {
        if (capture.location != null) {
          _markers.add(
            Marker(
              markerId: MarkerId(capture.id),
              position: LatLng(
                capture.location!.latitude,
                capture.location!.longitude,
              ),
              infoWindow: InfoWindow(
                title: capture.title ?? 'Untitled',
                snippet: capture.artistName ?? 'Unknown Artist',
              ),
              onTap: () => _onMarkerTapped(capture),
            ),
          );
        }
      }
    });
  }

  /// Handle marker tap
  void _onMarkerTapped(CaptureModel capture) {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CaptureDetailBottomSheet(capture: capture),
    );
  }

  /// Show snackbar
  void _showSnackBar(String message, {Duration? duration}) {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Start location updates
  void _startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshLocation(),
    );
  }

  /// Refresh location
  Future<void> _refreshLocation() async {
    if (!mounted) return;
    try {
      final newPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() => _currentPosition = newPosition);
      await _updateNearbyCaptures();
    } catch (e) {
      debugPrint('❌ Error refreshing location: $e');
    }
  }

  /// Update nearby captures based on current position and filter
  Future<void> _updateNearbyCaptures() async {
    if (!mounted || _currentPosition == null) return;
    try {
      List<CaptureModel> nearbyCaptures = [];
      final user = FirebaseAuth.instance.currentUser;

      switch (_artFilter) {
        case 'all':
          // Get all captures
          final allCaptures = await _captureService.getAllCaptures(limit: 100);
          nearbyCaptures = _filterCapturesByDistance(
            allCaptures,
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
          break;
        case 'public':
          // Get only public captures
          final publicCaptures = await _captureService.getPublicCaptures(
            limit: 100,
          );
          nearbyCaptures = _filterCapturesByDistance(
            publicCaptures,
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
          break;
        case 'captures':
          // Get all captures (same as 'all' for now)
          final allCaptures = await _captureService.getAllCaptures(limit: 100);
          nearbyCaptures = _filterCapturesByDistance(
            allCaptures,
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
          break;
        case 'my_captures':
          // Get only user's captures
          if (user != null) {
            final userCaptures = await _captureService.getCapturesForUser(
              user.uid,
            );
            nearbyCaptures = _filterCapturesByDistance(
              userCaptures,
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            );
          }
          break;
      }

      if (!mounted) return;
      setState(() {
        _nearbyCaptures = nearbyCaptures;
      });
      _updateMarkers();
    } catch (e) {
      debugPrint('❌ Error updating nearby captures: $e');
    }
  }

  /// Filter captures by distance from given coordinates
  List<CaptureModel> _filterCapturesByDistance(
    List<CaptureModel> captures,
    double latitude,
    double longitude,
  ) {
    final nearbyCaptures = <CaptureModel>[];
    for (final capture in captures) {
      if (capture.location != null) {
        final distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          capture.location!.latitude,
          capture.location!.longitude,
        );

        // Convert distance from meters to kilometers
        if (distance / 1000 <= 10.0) {
          nearbyCaptures.add(capture);
        }
      }
    }
    return nearbyCaptures;
  }

  /// Change filter
  void _changeFilter(String newFilter) {
    setState(() {
      _artFilter = newFilter;
    });
    _updateNearbyCaptures();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 2, // Art Walk tab
      drawer: const ArtWalkDrawer(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Art Walk Map'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4FB3BE), // Light Teal
                  Color(0xFFFF9E80), // Light Orange/Peach
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Google Map
            GoogleMap(
              initialCameraPosition: _defaultLocation,
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

            // Loading indicator
            if (_isLoading || _isSearchingZip)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
              ),

            // Error message
            if (_hasMapError)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _mapErrorMessage,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeMapsAndLocation,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),

            // ZIP code search bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter ZIP code (current: $_currentZipCode)',
                    border: InputBorder.none,
                    suffixIcon: const Icon(Icons.search),
                  ),
                  onSubmitted: (zipCode) async {
                    if (zipCode.isNotEmpty) {
                      setState(() => _isSearchingZip = true);
                      final coordinates = await _getCoordinatesFromZipCode(
                        zipCode,
                      );
                      if (coordinates != null) {
                        await _moveMapToLocation(
                          coordinates.latitude,
                          coordinates.longitude,
                          12.0,
                        );
                        await _loadNearbyCaptures(
                          coordinates.latitude,
                          coordinates.longitude,
                        );
                        await _updateUserZipCode(zipCode);
                        setState(() => _currentZipCode = zipCode);
                      } else {
                        _showSnackBar('ZIP code not found');
                      }
                      setState(() => _isSearchingZip = false);
                    }
                  },
                ),
              ),
            ),

            // Filter buttons
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFilterButton('All', 'all'),
                  _buildFilterButton('Public', 'public'),
                  _buildFilterButton('Captures', 'captures'),
                  _buildFilterButton('Mine', 'my_captures'),
                ],
              ),
            ),

            // Action buttons
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle captures slider
                  FloatingActionButton(
                    heroTag: 'toggle_slider',
                    mini: true,
                    onPressed: () {
                      setState(() {
                        _showCapturesSlider = !_showCapturesSlider;
                      });
                    },
                    child: Icon(_showCapturesSlider ? Icons.close : Icons.list),
                  ),
                  const SizedBox(height: 8),

                  // My location button
                  FloatingActionButton(
                    heroTag: 'my_location',
                    mini: true,
                    onPressed: _currentPosition != null
                        ? () {
                            _mapController?.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  ),
                                  zoom: 15.0,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),

            // Captures slider
            if (_showCapturesSlider)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nearby Captures (${_nearbyCaptures.length})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => _showCapturesSlider = false);
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _nearbyCaptures.isEmpty
                            ? const Center(
                                child: Text('No captures found nearby'),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _nearbyCaptures.length,
                                itemBuilder: (context, index) {
                                  final capture = _nearbyCaptures[index];
                                  return _buildCaptureCard(capture);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String filter) {
    final isSelected = _artFilter == filter;
    return ElevatedButton(
      onPressed: () => _changeFilter(filter),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? ArtbeatColors.primary : Colors.white,
        foregroundColor: isSelected ? Colors.white : ArtbeatColors.primary,
        elevation: 2,
      ),
      child: Text(label),
    );
  }

  Widget _buildCaptureCard(CaptureModel capture) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                child: OptimizedImage(
                  imageUrl: capture.thumbnailUrl ?? capture.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capture.title ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (capture.artistName != null)
                    Text(
                      capture.artistName!,
                      style: const TextStyle(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for capture details
class CaptureDetailBottomSheet extends StatelessWidget {
  final CaptureModel capture;

  const CaptureDetailBottomSheet({super.key, required this.capture});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Image
          if (capture.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: OptimizedImage(
                imageUrl: capture.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capture.title ?? 'Untitled',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (capture.artistName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'by ${capture.artistName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (capture.description != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    capture.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (capture.locationName != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          capture.locationName!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to capture detail screen
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                CaptureDetailScreen(capture: capture),
                          ),
                        );
                      },
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

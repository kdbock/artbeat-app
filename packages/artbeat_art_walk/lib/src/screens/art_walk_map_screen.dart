import 'dart:async';
import 'dart:io' show Platform, SocketException;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../widgets/zip_code_search_box.dart';

/// Screen that displays a map with nearby public art and art walks
class ArtWalkMapScreen extends StatefulWidget {
  const ArtWalkMapScreen({super.key});

  @override
  State<ArtWalkMapScreen> createState() => _ArtWalkMapScreenState();
}

class _ArtWalkMapScreenState extends State<ArtWalkMapScreen> {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _mapController;
  Timer? _locationUpdateTimer;
  final Set<Marker> _markers = {};
  final ArtWalkService _artWalkService = ArtWalkService();
  final GoogleMapsService _mapsService = GoogleMapsService();
  final UserService _userService = UserService();
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isSearchingZip = false;
  bool _hasMapError = false;
  String _mapErrorMessage = '';
  List<PublicArtModel> _nearbyArt = [];
  bool _showInfoCard = true;
  String _currentZipCode = '';
  String _artFilter = 'all'; // 'all', 'public', 'captures', 'my_captures'
  bool _hasMovedToUserLocation =
      false; // Track if we've already moved to user location
  bool _showCapturesSlider = false; // Track if captures slider is visible

  // Default to ZIP code 28501 (Kinston, NC) with better zoom
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(35.23838, -77.52658), // ZIP code 28501 (Kinston, NC)
    zoom: 10.0, // Better initial zoom level
  );

  @override
  void initState() {
    super.initState();
    _initializeMapsAndLocation();
  }

  /// Initialize Google Maps and location services
  Future<void> _initializeMapsAndLocation() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      debugPrint('🗺️ Initializing Google Maps...');

      // Check if we're running on an emulator to provide appropriate feedback
      final isEmulator = await _checkIfEmulator();
      if (isEmulator) {
        debugPrint('⚠️ Running on emulator - map performance may be limited');
      }

      // Initialize Maps with retry logic
      final mapsInitialized = await _mapsService.initializeMaps();

      if (!mapsInitialized) {
        if (!mounted) return;
        setState(() {
          _hasMapError = true;
          _mapErrorMessage = isEmulator
              ? 'Maps initialization failed. Emulators may have performance issues with Google Maps.'
              : 'Failed to initialize Google Maps. Please check your connectivity and try again.';
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _hasMapError = false;
          _isLoading = false;
        });
      }

      debugPrint('✅ Maps initialized successfully');

      // Load user's ZIP code first
      await _loadUserZipCode();

      // Location initialization will happen in _onMapCreated() after map is ready

      // If we're on an emulator, reduce map resource usage
      if (isEmulator && _mapController != null) {
        debugPrint('🗺️ Optimizing map settings for emulator');
        try {
          // Use a more modest zoom level to reduce tile loading
          await _mapController!.moveCamera(CameraUpdate.zoomTo(10.0));

          // Note: Traffic layer and map type are set in the GoogleMap widget
          // We can't modify them directly through the controller
        } catch (e) {
          debugPrint('⚠️ Error optimizing map for emulator: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in map/location initialization: $e');
      if (mounted) {
        setState(() {
          _hasMapError = true;
          _mapErrorMessage =
              'Google Maps initialization failed: ${e.toString().split('] ').last}';
          _isLoading = false;
        });
      }
    }
  }

  /// Check if running on an emulator
  Future<bool> _checkIfEmulator() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.isPhysicalDevice == false ||
            androidInfo.model.contains('sdk') ||
            androidInfo.model.contains('emulator');
      } else if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        return !iosInfo.isPhysicalDevice;
      }
    } catch (e) {
      debugPrint('⚠️ Error checking if device is emulator: $e');
    }
    return false;
  }

  /// Load user's ZIP code from profile
  Future<void> _loadUserZipCode() async {
    try {
      final user = await _userService.getCurrentUserModel();
      if (user?.zipCode != null && user!.zipCode!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _currentZipCode = user.zipCode!;
          });
        }
        debugPrint('📍 Loaded user ZIP code: ${user.zipCode}');
      } else {
        debugPrint(
          '📍 No user ZIP code found, will use location-based detection',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading user ZIP code: $e');
    }
  }

  Future<void> _initializeLocation() async {
    if (!mounted) return;

    try {
      // Priority 1: Try to get user's current location
      final currentLocationResult = await _tryGetCurrentLocation();

      if (currentLocationResult != null) {
        // Successfully got current location - use it
        _currentPosition = currentLocationResult;
        debugPrint('🌍 Using current location: $_currentPosition');
        await _moveMapToLocation(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          15.0,
        );

        // Get ZIP code from coordinates if we don't have user's ZIP code
        if (_currentZipCode.isEmpty) {
          _currentZipCode = await _artWalkService.getZipCodeFromCoordinates(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
          debugPrint('📍 Location-derived ZIP code: $_currentZipCode');

          // Save the detected ZIP code to user profile if valid
          if (_currentZipCode.isNotEmpty && _currentZipCode != '00000') {
            _updateUserZipCode(_currentZipCode);
          }
        }

        // Load nearby art based on current location
        await _loadNearbyArt(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        _startLocationUpdates();
      } else if (_currentZipCode.isNotEmpty) {
        // Priority 2: Use user's saved ZIP code
        debugPrint('📍 Using user profile ZIP code: $_currentZipCode');
        final coordinates = await _getCoordinatesFromZipCode(_currentZipCode);
        if (coordinates != null) {
          await _moveMapToLocation(
            coordinates.latitude,
            coordinates.longitude,
            12.0,
          );
          await _loadNearbyArt(coordinates.latitude, coordinates.longitude);
        } else {
          // Fallback to default location if ZIP code lookup fails
          debugPrint('📍 ZIP code lookup failed, using default location');
          await _moveMapToLocation(
            _defaultLocation.target.latitude,
            _defaultLocation.target.longitude,
            10.0,
          );
        }
      } else {
        // Priority 3: Use default location (Kinston, NC - 28501)
        debugPrint('📍 Using default location: Kinston, NC (28501)');
        await _moveMapToLocation(
          _defaultLocation.target.latitude,
          _defaultLocation.target.longitude,
          10.0,
        );
        await _loadNearbyArt(
          _defaultLocation.target.latitude,
          _defaultLocation.target.longitude,
        );
      }
    } catch (e) {
      debugPrint('❌ Error initializing location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error getting location: ${e.toString().split('] ').last}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      // Fallback to default location on any error
      await _moveMapToLocation(
        _defaultLocation.target.latitude,
        _defaultLocation.target.longitude,
        10.0,
      );
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
        debugPrint('📍 Location services are disabled');
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
          debugPrint('📍 Location permission denied');
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
        debugPrint('📍 Location permission permanently denied');
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
      debugPrint('⌛ Timeout getting current location');
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
      debugPrint('❌ Error getting current location: $e');
      if (e is SocketException) {
        debugPrint('🌐 Network error while getting location data: $e');
        _showSnackBar('Network error. Using saved location or default.');
      }
      return null;
    }
  }

  /// Get coordinates from ZIP code
  Future<({double latitude, double longitude})?> _getCoordinatesFromZipCode(
    String zipCode,
  ) async {
    try {
      // You might want to implement a ZIP code to coordinates lookup
      // For now, we'll use a simple lookup for common ZIP codes
      // This could be enhanced with a proper geocoding service

      // Special case for our default ZIP code
      if (zipCode == '28501') {
        return (latitude: 35.23838, longitude: -77.52658);
      }

      // For other ZIP codes, you might want to use a geocoding service
      // For now, return null to fall back to default location
      debugPrint('📍 ZIP code coordinate lookup not implemented for: $zipCode');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting coordinates from ZIP code: $e');
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
        debugPrint('🗺️ Moving map to location: $latitude, $longitude');
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

  /// Load nearby art for given coordinates
  Future<void> _loadNearbyArt(double latitude, double longitude) async {
    try {
      _nearbyArt = await _artWalkService
          .getPublicArtNearLocation(
            latitude: latitude,
            longitude: longitude,
            radiusKm: 10.0,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint(
                '⚠️ Loading nearby art timed out, using cached data if available',
              );
              return _artWalkService.getCachedPublicArt();
            },
          );

      debugPrint('🎨 Loaded ${_nearbyArt.length} nearby art pieces');
      _updateMarkers();
    } catch (e) {
      debugPrint('❌ Error loading nearby art: $e');
      _nearbyArt = [];
      _updateMarkers();
    }
  }

  /// Update user's ZIP code in profile
  void _updateUserZipCode(String zipCode) async {
    try {
      await _userService.updateUserZipCode(zipCode);
      debugPrint('✅ Successfully updated user ZIP code to: $zipCode');
    } catch (e) {
      debugPrint('❌ Error updating user ZIP code: $e');
    }
  }

  /// Update markers on the map based on nearby art
  void _updateMarkers() {
    if (!mounted) return;

    setState(() {
      _markers.clear();
      for (final art in _nearbyArt) {
        _markers.add(
          Marker(
            markerId: MarkerId(art.id),
            position: LatLng(art.location.latitude, art.location.longitude),
            infoWindow: InfoWindow(
              title: art.title,
              snippet: art.artistName ?? 'Unknown Artist',
            ),
            onTap: () => _onMarkerTapped(art),
          ),
        );
      }
    });
  }

  /// Handle marker tap events
  void _onMarkerTapped(PublicArtModel art) {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ArtDetailBottomSheet(art: art),
    );
  }

  /// Called when the map is created to initialize the controller
  Future<void> _onMapCreated(GoogleMapController controller) async {
    debugPrint('🗺️ GoogleMap controller created successfully');
    debugPrint(
      '🔑 Using API key: ${ConfigService.instance.googleMapsApiKey?.substring(0, 20)}...',
    );

    _mapController = controller;
    _mapControllerCompleter.complete(controller);

    // Test if the map can load tiles by checking if we can get the camera position
    try {
      final position = await controller.getLatLng(
        const ScreenCoordinate(x: 100, y: 100),
      );
      debugPrint('🗺️ Map tiles loading properly - test coordinate: $position');
    } catch (e) {
      debugPrint('⚠️ Map tiles may not be loading: $e');
      if (mounted) {
        _showSnackBar(
          'Map tiles not loading properly. This may be an API key issue.',
        );
      }
    }

    // If we already have user location, move to it immediately
    if (_currentPosition != null && !_hasMovedToUserLocation) {
      debugPrint('🗺️ Moving map to existing user location');
      try {
        await controller.animateCamera(
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
        _hasMovedToUserLocation = true;
      } catch (e) {
        debugPrint('⚠️ Error moving to existing location: $e');
      }
    }

    // Initialize location after map is ready (this will get location if we don't have it)
    await _initializeLocation();
  }

  /// Start periodic location updates
  void _startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshLocation(),
    );
  }

  /// Refresh the current location and update nearby art
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
      await _updateNearbyArt();
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  /// Update the current location and nearby art
  Future<void> _updateNearbyArt() async {
    if (!mounted || _currentPosition == null) return;

    try {
      List<PublicArtModel> nearbyArt = [];

      switch (_artFilter) {
        case 'all':
          nearbyArt = await _artWalkService.getCombinedArtNearLocation(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            radiusKm: 10.0,
            includeUserCaptures: true,
          );
          break;
        case 'public':
          nearbyArt = await _artWalkService.getPublicArtNearLocation(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            radiusKm: 10.0,
          );
          break;
        case 'captures':
          // Get all public art (community + user's own)
          final allCaptures = await _artWalkService
              .getPublicArtNearLocationWithFilter(
                latitude: _currentPosition!.latitude,
                longitude: _currentPosition!.longitude,
                radiusKm: 10.0,
                includeUserOnly: false, // Gets all public art
              );
          debugPrint('🔍 [DEBUG] all captures length: ${allCaptures.length}');
          nearbyArt =
              allCaptures; // Already PublicArtModel, no conversion needed
          break;
        case 'my_captures':
          debugPrint('🔍 [DEBUG] Filter my_captures selected');
          final captures = await _artWalkService
              .getPublicArtNearLocationWithFilter(
                latitude: _currentPosition!.latitude,
                longitude: _currentPosition!.longitude,
                radiusKm: 10.0,
                includeUserOnly: true,
              );
          debugPrint('🔍 [DEBUG] my_captures docs count: ${captures.length}');
          nearbyArt = captures; // Already PublicArtModel, no conversion needed
          break;
      }

      if (!mounted) return;
      setState(() {
        _nearbyArt = nearbyArt;
        _updateMarkers();
      });
    } catch (e) {
      debugPrint('Error updating nearby art: $e');
    }
  }

  /// Show a snackbar message safely
  void _showSnackBar(String message, {Duration? duration}) {
    if (!mounted) return;

    // Use a local variable to avoid BuildContext async gap issues
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Show filter dialog for art types
  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Art'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('All Art'),
              subtitle: const Text('Public art + captured art'),
              value: 'all',
              groupValue: _artFilter,
              onChanged: (value) {
                Navigator.of(context).pop();
                _changeFilter(value!);
              },
            ),
            RadioListTile<String>(
              title: const Text('Public Art Only'),
              subtitle: const Text('Curated public art pieces'),
              value: 'public',
              groupValue: _artFilter,
              onChanged: (value) {
                Navigator.of(context).pop();
                _changeFilter(value!);
              },
            ),
            RadioListTile<String>(
              title: const Text('Community Captures'),
              subtitle: const Text('Art captured by community'),
              value: 'captures',
              groupValue: _artFilter,
              onChanged: (value) {
                Navigator.of(context).pop();
                _changeFilter(value!);
              },
            ),
            RadioListTile<String>(
              title: const Text('My Captures'),
              subtitle: const Text('Art you\'ve captured'),
              value: 'my_captures',
              groupValue: _artFilter,
              onChanged: (value) {
                Navigator.of(context).pop();
                _changeFilter(value!);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Change the art filter and refresh the map
  void _changeFilter(String newFilter) {
    setState(() {
      _artFilter = newFilter;
    });
    _updateNearbyArt();
  }

  /// Handle ZIP code search submission
  Future<void> _handleZipCodeSearch(String zipCode) async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final mapController = _mapController;

    setState(() {
      _isSearchingZip = true;
      _currentZipCode = zipCode;
    });

    try {
      // Convert ZIP code to coordinates
      final coordinates = await LocationUtils.getCoordinatesFromZipCode(
        zipCode,
      );
      if (coordinates == null) {
        if (mounted) {
          _showSnackBar('Invalid ZIP code or unable to find location');
        }
        return;
      }

      // Get nearby art from the service using the actual coordinates
      final nearbyArt = await _artWalkService.getPublicArtNearLocation(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        radiusKm: 10.0,
      );

      if (!mounted) return;

      setState(() {
        _nearbyArt = nearbyArt;
        _updateMarkers();
      });

      // Update user's ZIP code if they searched for a valid one
      if (zipCode.isNotEmpty && zipCode != '00000') {
        _updateUserZipCode(zipCode);
      }

      if (nearbyArt.isNotEmpty && mapController != null) {
        final firstArt = nearbyArt.first;
        await mapController.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(firstArt.location.latitude, firstArt.location.longitude),
            13.0,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('No public art found in this area'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error searching by ZIP code: $e');
      if (mounted) {
        _showSnackBar('Error searching location: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSearchingZip = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 1, // Art Walk is index 1
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/images/artbeat_logo.png',
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'ARTbeat',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'Art Walk',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
        ),
        drawer: const ArtbeatDrawer(),
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _defaultLocation,
              onMapCreated: _onMapCreated,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              compassEnabled: true,
              trafficEnabled: false,
              buildingsEnabled: true,
              indoorViewEnabled: false,
              // Add error handling for API key issues
              onTap: (LatLng position) {
                debugPrint('🗺️ Map tapped at: $position');
              },
            ),

            // Floating Create Art Walk Button with label
            Positioned(
              right: 16,
              bottom: 120, // Above bottom navigation
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: 'Create a new art walk',
                    child: FloatingActionButton(
                      heroTag: 'createArtWalk',
                      onPressed: () {
                        Navigator.pushNamed(context, '/art-walk/create');
                      },
                      backgroundColor: Colors.purple,
                      child: const Icon(Icons.route, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Create Walk',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading || _isSearchingZip)
              const Center(child: CircularProgressIndicator()),
            if (_hasMapError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _mapErrorMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
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
            // Unified Control Bar with Search and Action Buttons
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: TextEditingController(
                          text: _currentZipCode,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter ZIP code to search...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          hintStyle: TextStyle(fontSize: 14),
                        ),
                        style: const TextStyle(fontSize: 14),
                        onSubmitted: _handleZipCodeSearch,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Action buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery toggle
                        _buildActionButton(
                          icon: Icons.view_carousel,
                          label: 'Gallery',
                          isActive: _showCapturesSlider,
                          onPressed: () {
                            setState(() {
                              _showCapturesSlider = !_showCapturesSlider;
                            });
                          },
                          tooltip: _showCapturesSlider
                              ? 'Hide art gallery'
                              : 'Show art gallery',
                        ),
                        // Filter
                        _buildActionButton(
                          icon: Icons.filter_list,
                          label: 'Filter',
                          isActive: false,
                          onPressed: _showFilterDialog,
                          tooltip: 'Filter art types',
                        ),
                        // Zoom In
                        _buildActionButton(
                          icon: Icons.zoom_in,
                          label: 'Zoom In',
                          isActive: false,
                          onPressed: () async {
                            if (_mapController != null) {
                              await _mapController!.animateCamera(
                                CameraUpdate.zoomIn(),
                              );
                            }
                          },
                          tooltip: 'Zoom in on map',
                        ),
                        // Zoom Out
                        _buildActionButton(
                          icon: Icons.zoom_out,
                          label: 'Zoom Out',
                          isActive: false,
                          onPressed: () async {
                            if (_mapController != null) {
                              await _mapController!.animateCamera(
                                CameraUpdate.zoomOut(),
                              );
                            }
                          },
                          tooltip: 'Zoom out on map',
                        ),
                        // My Location
                        _buildActionButton(
                          icon: Icons.my_location,
                          label: 'Location',
                          isActive: false,
                          onPressed: () async {
                            if (_currentPosition != null &&
                                _mapController != null) {
                              await _mapController!.animateCamera(
                                CameraUpdate.newLatLng(
                                  LatLng(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  ),
                                ),
                              );
                            }
                          },
                          tooltip: 'Go to my location',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Captures Slider with header
            if (_showCapturesSlider)
              Positioned(
                top: MediaQuery.of(context).padding.top + 180,
                left: 0,
                right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with instruction
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _nearbyArt.isNotEmpty
                                  ? 'Tap any art piece to view details and location'
                                  : 'No art found in this area. Try changing your filter or location.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_nearbyArt.isNotEmpty)
                            Text(
                              '${_nearbyArt.length} found',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_nearbyArt.isNotEmpty)
                      _buildCapturesSlider()
                    else
                      Container(
                        height: 120,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 32,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No art pieces found',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try adjusting your filters or location',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (_showInfoCard)
              Positioned(
                bottom: 100, // Increased to account for bottom navigation
                left: 16,
                right: 16,
                child: ArtWalkInfoCard(
                  onDismiss: () => setState(() => _showInfoCard = false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build action button for the unified control bar
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? Colors.purple : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? Colors.purple : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: onPressed,
              icon: Icon(
                icon,
                size: 20,
                color: isActive ? Colors.white : Colors.grey[700],
              ),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.purple : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Build horizontal slider showing captures visible on the map
  Widget _buildCapturesSlider() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _nearbyArt.length,
        itemBuilder: (context, index) {
          final art = _nearbyArt[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                // Move map to this art piece
                if (_mapController != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(
                          art.location.latitude,
                          art.location.longitude,
                        ),
                        zoom: 17.0,
                      ),
                    ),
                  );
                }
                // Show art details
                _onMarkerTapped(art);
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Art image
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          color: Colors.grey[200],
                        ),
                        child: art.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                child: Image.network(
                                  art.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                        size: 24,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                              ),
                      ),
                    ),
                    // Art title
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          art.title,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}

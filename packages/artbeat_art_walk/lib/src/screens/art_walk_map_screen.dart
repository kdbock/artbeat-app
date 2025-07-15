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

  // Default to North Carolina center with better zoom with better zoom
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(35.7596, -79.0193), // Center of NC
    zoom: 10.0, // Better initial zoom level // Better initial zoom level
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

      // Load user's ZIP code first, then initialize location
      await _loadUserZipCode();

      // Now initialize location
      await _initializeLocation();

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
      // Check if location services are enabled
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services are disabled. Please enable them to see nearby art.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
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
                  'Location permission denied. Some features may be limited.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Get current position with a timeout
      try {
        _currentPosition =
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

        debugPrint('🌍 Got current position: $_currentPosition');

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
        } else {
          debugPrint('📍 Using user profile ZIP code: $_currentZipCode');
        }

        // Load nearby art with a timeout
        _nearbyArt = await _artWalkService
            .getPublicArtNearLocation(
              latitude: _currentPosition!.latitude,
              longitude: _currentPosition!.longitude,
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

        // Create markers for nearby art
        _updateMarkers();

        // If map is ready, move to current location with better zoom
        if (_mapController != null && mounted) {
          try {
            debugPrint('🗺️ Moving map to current location');
            await _mapController!
                .animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      zoom: 15.0, // Increased zoom for better visibility
                    ),
                  ),
                )
                .timeout(const Duration(seconds: 3));
          } catch (e) {
            debugPrint('⚠️ Error animating camera: $e');
          }
        }

        // Set up periodic location updates
        _startLocationUpdates();
      } on TimeoutException {
        debugPrint('⌛ Timeout getting precise location');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services timed out. Using approximate location.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (e is SocketException) {
          debugPrint('🌐 Network error while getting location data: $e');
          _showSnackBar('Network error. Some features may be limited.');
        }
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

    // Initialize location after map is ready
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
          // Get all public captures (community + user's own)
          final allCaptures = await _artWalkService.getCapturedArtNearLocation(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            radiusKm: 10.0,
            includeUserOnly: false, // Gets all public captures
          );
          debugPrint('🔍 [DEBUG] all captures length: ${allCaptures.length}');
          nearbyArt = allCaptures
              .map(
                (captureModel) =>
                    _artWalkService.captureToPublicArt(captureModel),
              )
              .toList();
          break;
        case 'my_captures':
          debugPrint('🔍 [DEBUG] Filter my_captures selected');
          final captures = await _artWalkService.getCapturedArtNearLocation(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            radiusKm: 10.0,
            includeUserOnly: true,
          );
          debugPrint('🔍 [DEBUG] my_captures docs count: ${captures.length}');
          nearbyArt = captures
              .map((c) => _artWalkService.captureToPublicArt(c))
              .toList();
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
        appBar: EnhancedUniversalHeader(
          title: 'Art Walk Map',
          showDeveloperTools: false,
          onSearchPressed: () {
            // Handle search action - could open a search overlay
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Search functionality coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
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
            Positioned(
              right: 16,
              top:
                  MediaQuery.of(context).padding.top +
                  120, // Increased to account for app bar
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'artFilter',
                    onPressed: _showFilterDialog,
                    child: const Icon(Icons.filter_list),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'myLocation',
                    onPressed: () async {
                      if (_currentPosition != null && _mapController != null) {
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
                    child: const Icon(Icons.my_location),
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
            Positioned(
              top:
                  MediaQuery.of(context).padding.top +
                  80, // Increased to account for app bar
              left: 16,
              right: 16,
              child: ZipCodeSearchBox(
                initialValue: _currentZipCode,
                onZipCodeSubmitted: _handleZipCodeSearch,
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

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}

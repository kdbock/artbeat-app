import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import '../widgets/zip_code_search_box.dart';
import '../widgets/map_floating_menu.dart';

class ArtWalkMapScreen extends StatefulWidget {
  const ArtWalkMapScreen({super.key});

  @override
  State<ArtWalkMapScreen> createState() => _ArtWalkMapScreenState();
}

class _ArtWalkMapScreenState extends State<ArtWalkMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final ArtWalkService _artWalkService = ArtWalkService();
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isSearchingZip = false;
  List<PublicArtModel> _nearbyArt = [];
  bool _showInfoCard = true;
  final String _currentZipCode = '';

  // Default to North Carolina center
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(35.7596, -79.0193), // Center of NC
    zoom: 7.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoading = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location services are disabled. Please enable them to see nearby art.'),
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
                    'Location permission denied. Some features may be limited.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition();

      // Load nearby art
      _nearbyArt = await _artWalkService.getPublicArtNearLocation(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: 10.0,
      );

      // Create markers for nearby art
      _updateMarkers();

      if (_mapController != null && mounted) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                  _currentPosition!.latitude, _currentPosition!.longitude),
              zoom: 13.0,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
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

  Future<void> _searchByZipCode(String zipCode) async {
    setState(() => _isSearchingZip = true);
    try {
      // Here you would typically:
      // 1. Convert ZIP code to coordinates
      // 2. Move map to those coordinates
      // 3. Load nearby art for that location
      // For now, just show an error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('ZIP code search will be implemented in a future update'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSearchingZip = false);
      }
    }
  }

  void _updateMarkers() {
    setState(() {
      _markers.clear();
      for (final art in _nearbyArt) {
        _markers.add(
          Marker(
            markerId: MarkerId(art.id),
            position: LatLng(art.location.latitude, art.location.longitude),
            infoWindow: InfoWindow(
              title: art.title,
              snippet: art.artistName != null ? 'by ${art.artistName}' : null,
            ),
          ),
        );
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 13.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Art Walk Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _initializeLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _defaultLocation,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
          ),
          if (_isLoading || _isSearchingZip)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_showInfoCard)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ArtWalkInfoCard(
                onDismiss: () => setState(() => _showInfoCard = false),
              ),
            ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Stack(
              children: [
                ZipCodeSearchBox(
                  initialValue: _currentZipCode,
                  onZipCodeSubmitted: _searchByZipCode,
                ),
                if (_isSearchingZip)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: MapFloatingMenu(
        onCreateArtWalk: () => Navigator.pushNamed(context, '/art_walk/create'),
        onViewArtWalks: () => Navigator.pushNamed(context, '/art_walk/list'),
        onViewAttractions: () {}, // Placeholder for future feature
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

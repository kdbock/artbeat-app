import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart';

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
  List<PublicArtModel> _nearbyArt = [];
  bool _showInfoCard = true;

  // Default center on a common location if we can't get the user's location
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(37.7749, -122.4194), // San Francisco
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("📍 Location services are disabled");
        setState(() => _isLoading = false);
        // Instead of throwing, just return and use default location
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("📍 Location permission denied");
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("📍 Location permission permanently denied");
        setState(() => _isLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      // Use CoordinateValidator to validate position
      if (CoordinateValidator.isValidLatitude(position.latitude) &&
          CoordinateValidator.isValidLongitude(position.longitude)) {
        setState(() => _currentPosition = position);

        // Move camera to current position if controller is initialized
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 14.0,
              ),
            ),
          );
        }
      } else {
        debugPrint(
            "📍 Warning: Received invalid coordinates from Geolocator: lat=${position.latitude}, lng=${position.longitude}");
      }

      // Load nearby art
      await _loadNearbyArt();
    } catch (error) {
      debugPrint("📍 Location error: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadNearbyArt() async {
    if (_currentPosition == null) return;

    try {
      // Use CoordinateValidator to validate position
      if (!CoordinateValidator.isValidLatitude(_currentPosition!.latitude) ||
          !CoordinateValidator.isValidLongitude(_currentPosition!.longitude)) {
        debugPrint("📍 Invalid coordinates for loading nearby art");
        return;
      }

      final nearbyArt = await _artWalkService.getPublicArtNearLocation(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: 10.0, // 10km radius
      );

      if (mounted) {
        setState(() {
          _nearbyArt = nearbyArt;
          _updateMarkers();
        });
      }
    } catch (error) {
      debugPrint("🎨 Error loading nearby art: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading nearby art: ${error.toString()}')),
        );
      }
    }
  }

  void _updateMarkers() {
    final Set<Marker> markers = {};

    // Add marker for current location
    if (_currentPosition != null) {
      // Use CoordinateValidator to validate position
      if (CoordinateValidator.isValidLatitude(_currentPosition!.latitude) &&
          CoordinateValidator.isValidLongitude(_currentPosition!.longitude)) {
        markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position:
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'You are here'),
          ),
        );
      }
    }

    // Add markers for nearby art with validation
    int validMarkers = 0;
    int invalidMarkers = 0;

    for (final art in _nearbyArt) {
      // Use CoordinateValidator to validate art location
      if (!CoordinateValidator.isValidGeoPoint(art.location)) {
        CoordinateValidator.logInvalidCoordinates(
            art.id, art.location.latitude, art.location.longitude);
        invalidMarkers++;
        continue;
      }

      validMarkers++;
      markers.add(
        Marker(
          markerId: MarkerId(art.id),
          position: LatLng(art.location.latitude, art.location.longitude),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: art.title,
            snippet: art.artistName != null ? 'by ${art.artistName}' : null,
            onTap: () => _showArtDetails(art),
          ),
        ),
      );
    }

    debugPrint(
        '🎨 Created $validMarkers valid markers, skipped $invalidMarkers invalid markers');

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(markers);
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Move camera to current location if available
    if (_currentPosition != null) {
      // Validate coordinates
      if (_currentPosition!.latitude.isFinite &&
          _currentPosition!.longitude.isFinite) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                  _currentPosition!.latitude, _currentPosition!.longitude),
              zoom: 14.0,
            ),
          ),
        );
      }
    }
  }

  void _showArtDetails(PublicArtModel art) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.network(
                  art.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Handle image loading errors
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image_not_supported,
                            size: 50, color: Colors.grey),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        art.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (art.artistName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Artist: ${art.artistName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                      if (art.artType != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Type: ${art.artType}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        art.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      if (art.address != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                art.address!,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Here you would add this art to the current art walk
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    '${art.title} added to your art walk')),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add to My Art Walk'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _hideInfoCard() {
    setState(() => _showInfoCard = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Art Walk Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _defaultLocation,
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            onCameraIdle: () {
              // This prevents certain map-related NaN errors
              debugPrint("📍 Map camera idle");
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_showInfoCard)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ArtWalkInfoCard(
                onDismiss: _hideInfoCard,
              ),
            ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'createArtWalk',
              tooltip: 'Create Art Walk',
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.pushNamed(context, '/art-walk/create');
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat/models/public_art_model.dart';
import 'package:artbeat/services/art_walk_service.dart';
import 'package:artbeat/widgets/art_walk_info_card.dart';
import 'package:artbeat/services/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ArtWalkMapScreen extends StatefulWidget {
  const ArtWalkMapScreen({super.key});

  @override
  State<ArtWalkMapScreen> createState() => _ArtWalkMapScreenState();
}

class _ArtWalkMapScreenState extends State<ArtWalkMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final ArtWalkService _artWalkService = ArtWalkService();
  final ConnectivityService _connectivityService = ConnectivityService();
  Position? _currentPosition;
  bool _isLoading = true;
  List<PublicArtModel> _nearbyArt = [];
  bool _showInfoCard = true;
  final bool _isOffline = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

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
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);

      // Move camera to current position
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

      // Load nearby art
      await _loadNearbyArt();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNearbyArt() async {
    if (_currentPosition == null) return;

    try {
      final nearbyArt = await _artWalkService.getPublicArtNearLocation(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: 10.0, // 10km radius
      );

      setState(() {
        _nearbyArt = nearbyArt;
        _updateMarkers();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading nearby art: ${e.toString()}')),
      );
    }
  }

  void _updateMarkers() {
    final Set<Marker> markers = {};

    // Add marker for current location
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      );
    }

    // Add markers for nearby art
    for (final art in _nearbyArt) {
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

    setState(() => _markers.clear());
    setState(() => _markers.addAll(markers));
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Move camera to current location if available
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 14.0,
          ),
        ),
      );
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

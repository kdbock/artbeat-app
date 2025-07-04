import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import '../models/models.dart';
import '../services/services.dart';


/// Enhanced Art Walk Create Screen with Map View
class EnhancedArtWalkCreateScreen extends StatefulWidget {
  static const String routeName = '/enhanced-create-art-walk';

  final String? artWalkId; // For editing existing art walk
  final ArtWalkModel? artWalkToEdit; // Pre-loaded art walk data

  const EnhancedArtWalkCreateScreen({
    super.key,
    this.artWalkId,
    this.artWalkToEdit,
  });

  @override
  State<EnhancedArtWalkCreateScreen> createState() =>
      _EnhancedArtWalkCreateScreenState();
}

class _EnhancedArtWalkCreateScreenState
    extends State<EnhancedArtWalkCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  final _zipCodeController = TextEditingController();

  // Map related
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Position? _currentPosition;
  LatLng? _mapCenter;

  // Art pieces and route
  final List<PublicArtModel> _selectedArtPieces = [];
  List<PublicArtModel> _availableArtPieces = [];
  List<LatLng> _routePoints = [];

  // State variables
  File? _coverImageFile;
  bool _isLoading = false;
  bool _isPublic = true;
  bool _showMapView = true;
  double _estimatedDistance = 0.0;

  // Services
  final ArtWalkService _artWalkService = ArtWalkService();
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    // Initialize form if editing existing art walk
    if (widget.artWalkToEdit != null) {
      _initializeEditingMode();
    }

    _initializeLocation();
    _loadAvailableArtPieces();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedDurationController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _initializeEditingMode() {
    final artWalk = widget.artWalkToEdit!;
    _titleController.text = artWalk.title;
    _descriptionController.text = artWalk.description;
    _isPublic = artWalk.isPublic;
    _estimatedDurationController.text =
        artWalk.estimatedDuration?.toString() ?? '';
    _zipCodeController.text = artWalk.zipCode ?? '';
    _estimatedDistance = artWalk.estimatedDistance ?? 0.0;
  }

  Future<void> _initializeLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _mapCenter = LatLng(position.latitude, position.longitude);
      });

      // Update zip code based on current location
      await _updateZipCodeFromLocation(_mapCenter!);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      // Default to central NC if location fails
      setState(() {
        _mapCenter = const LatLng(35.7796, -78.6382);
      });
    }
  }

  Future<void> _updateZipCodeFromLocation(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          _zipCodeController.text = placemark.postalCode ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error getting zip code from location: $e');
    }
  }

  Future<void> _loadAvailableArtPieces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use current position if available, otherwise default to central NC
      final latitude = _currentPosition?.latitude ?? 35.7796;
      final longitude = _currentPosition?.longitude ?? -78.6382;

      // Fetch all captures
      final captureService = CaptureService();
      final captures = await captureService.getAllCaptures(limit: 100);

      // Convert captures to PublicArtModel
      final List<PublicArtModel> captureArt = captures
          .map(
            (capture) => PublicArtModel(
              id: capture.id,
              title: capture.title ?? 'Captured Art',
              artistName: capture.artistName ?? 'Unknown Artist',
              imageUrl: capture.imageUrl,
              location: capture.location ?? const GeoPoint(0, 0),
              description: capture.description ?? '',
              tags: capture.tags ?? [],
              userId: capture.userId,
              usersFavorited: const [],
              createdAt: Timestamp.fromDate(capture.createdAt),
            ),
          )
          .toList();

      // Fetch public art near location
      final publicArt = await _artWalkService.getPublicArtNearLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: 50.0,
      );

      setState(() {
        _availableArtPieces = [...publicArt, ...captureArt];
        _updateMapMarkers();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading art pieces: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateMapMarkers() {
    final markers = <Marker>{};

    // Add markers for all available art pieces
    for (final art in _availableArtPieces) {
      final isSelected = _selectedArtPieces.contains(art);
      final markerId = MarkerId(art.id);

      markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(art.location.latitude, art.location.longitude),
          icon: isSelected
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: art.title,
            snippet: art.artistName,
            onTap: () => _toggleArtPieceSelection(art),
          ),
          onTap: () => _toggleArtPieceSelection(art),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _toggleArtPieceSelection(PublicArtModel art) {
    setState(() {
      if (_selectedArtPieces.contains(art)) {
        _selectedArtPieces.remove(art);
      } else {
        _selectedArtPieces.add(art);
      }
    });

    _updateMapMarkers();
    _updateRoute();
  }

  void _updateRoute() {
    if (_selectedArtPieces.length < 2) {
      setState(() {
        _polylines.clear();
        _routePoints.clear();
        _estimatedDistance = 0.0;
      });
      return;
    }

    // Sort selected art pieces by distance to create an optimal route
    final sortedPieces = _optimizeRoute(_selectedArtPieces);

    // Create route points
    final routePoints = sortedPieces
        .map((art) => LatLng(art.location.latitude, art.location.longitude))
        .toList();

    // Calculate total distance
    double totalDistance = 0.0;
    for (int i = 0; i < routePoints.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        routePoints[i].latitude,
        routePoints[i].longitude,
        routePoints[i + 1].latitude,
        routePoints[i + 1].longitude,
      );
    }

    // Convert to miles
    final distanceInMiles = totalDistance / 1609.344;

    setState(() {
      _routePoints = routePoints;
      _estimatedDistance = distanceInMiles;
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: ArtbeatColors.primary,
          width: 3,
        ),
      };
    });
  }

  List<PublicArtModel> _optimizeRoute(List<PublicArtModel> artPieces) {
    if (artPieces.length <= 2) return artPieces;

    // Simple nearest neighbor approach for route optimization
    final List<PublicArtModel> optimized = [];
    final List<PublicArtModel> remaining = List.from(artPieces);

    // Start with the first piece
    optimized.add(remaining.removeAt(0));

    while (remaining.isNotEmpty) {
      final current = optimized.last;
      PublicArtModel nearest = remaining.first;
      double minDistance = double.infinity;

      for (final art in remaining) {
        final distance = Geolocator.distanceBetween(
          current.location.latitude,
          current.location.longitude,
          art.location.latitude,
          art.location.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearest = art;
        }
      }

      optimized.add(nearest);
      remaining.remove(nearest);
    }

    return optimized;
  }

  Future<void> _pickCoverImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _coverImageFile = File(pickedFile.path);
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    // Map controller initialized
  }

  void _onMapTap(LatLng position) {
    _updateZipCodeFromLocation(position);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedArtPieces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one art piece')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isEditing = widget.artWalkId != null;

      // Get art piece IDs
      final artworkIds = _selectedArtPieces.map((art) => art.id).toList();

      // Calculate estimated duration based on distance and number of pieces
      final estimatedMinutes =
          (_estimatedDistance * 20) + (_selectedArtPieces.length * 5);

      if (isEditing) {
        // Update existing art walk
        await _artWalkService.updateArtWalk(
          walkId: widget.artWalkId!,
          title: _titleController.text,
          description: _descriptionController.text,
          artworkIds: artworkIds,
          coverImageFile: _coverImageFile,
          isPublic: _isPublic,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Art Walk updated successfully!')),
          );
          Navigator.of(context).pop();
        }
      } else {
        // Create new art walk
        final userId = _auth.currentUser?.uid;
        if (userId == null) {
          throw Exception('User not authenticated');
        }

        // Create route data
        final routeData = _routePoints
            .map((point) => '${point.latitude},${point.longitude}')
            .join(';');

        // Create the art walk
        final artWalkData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'userId': userId,
          'artworkIds': artworkIds,
          'isPublic': _isPublic,
          'zipCode': _zipCodeController.text,
          'estimatedDuration': estimatedMinutes,
          'estimatedDistance': _estimatedDistance,
          'routeData': routeData,
          'createdAt': FieldValue.serverTimestamp(),
          'viewCount': 0,
          'imageUrls': <String>[],
        };

        // Add cover image URL if available
        if (_coverImageFile != null) {
          // Upload cover image
          final coverImageUrl = await _uploadCoverImage(_coverImageFile!);
          artWalkData['coverImageUrl'] = coverImageUrl;
        }

        await _firestore.collection('art_walks').add(artWalkData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Art Walk created successfully!')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${widget.artWalkId != null ? 'updating' : 'creating'} art walk: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _uploadCoverImage(File imageFile) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_cover.jpg';
    final ref = FirebaseStorage.instance.ref().child(
      'art_walk_covers/$userId/$fileName',
    );

    final uploadTask = ref.putFile(imageFile);
    final snapshot = await uploadTask;

    return snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.artWalkId != null
              ? 'Edit Art Walk'
              : 'Create Enhanced Art Walk',
        ),
        actions: [
          IconButton(
            icon: Icon(_showMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMapView = !_showMapView;
              });
            },
          ),
        ],
      ),
      body: _isLoading && _availableArtPieces.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map or List View Toggle
                SizedBox(
                  height: 300,
                  child: _showMapView ? _buildMapView() : _buildListView(),
                ),

                // Form Section
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Information
                          _buildBasicInformation(),
                          const SizedBox(height: 20),

                          // Route Information
                          _buildRouteInformation(),
                          const SizedBox(height: 20),

                          // Cover Image
                          _buildCoverImageSection(),
                          const SizedBox(height: 20),

                          // Settings
                          _buildSettingsSection(),
                          const SizedBox(height: 20),

                          // Selected Art Pieces Summary
                          _buildSelectedArtSummary(),
                          const SizedBox(height: 24),

                          // Submit Button
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMapView() {
    if (_mapCenter == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GoogleMap(
      onMapCreated: _onMapCreated,
      onTap: _onMapTap,
      initialCameraPosition: CameraPosition(target: _mapCenter!, zoom: 12.0),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      zoomControlsEnabled: true,
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _availableArtPieces.length,
      itemBuilder: (context, index) {
        final art = _availableArtPieces[index];
        final isSelected = _selectedArtPieces.contains(art);

        return Card(
          child: ListTile(
            leading: art.imageUrl.isNotEmpty
                ? CircleAvatar(backgroundImage: NetworkImage(art.imageUrl))
                : const CircleAvatar(child: Icon(Icons.art_track)),
            title: Text(art.title),
            subtitle: Text(art.artistName ?? 'Unknown Artist'),
            trailing: Checkbox(
              value: isSelected,
              onChanged: (value) => _toggleArtPieceSelection(art),
            ),
            onTap: () => _toggleArtPieceSelection(art),
          ),
        );
      },
    );
  }

  Widget _buildBasicInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Art Walk Title',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRouteInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Route Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _zipCodeController,
                decoration: const InputDecoration(
                  labelText: 'Zip Code',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _estimatedDurationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                readOnly: true,
                initialValue: _estimatedDistance > 0
                    ? ((_estimatedDistance * 20) +
                              (_selectedArtPieces.length * 5))
                          .toStringAsFixed(0)
                    : '',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_estimatedDistance > 0)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Distance:'),
                      Text('${_estimatedDistance.toStringAsFixed(2)} miles'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Art Pieces:'),
                      Text('${_selectedArtPieces.length}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCoverImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cover Image',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: _pickCoverImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _coverImageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_coverImageFile!, fit: BoxFit.cover),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Add Cover Image'),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        SwitchListTile(
          title: const Text('Make this Art Walk public'),
          value: _isPublic,
          onChanged: (value) {
            setState(() {
              _isPublic = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSelectedArtSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Art Pieces (${_selectedArtPieces.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (_selectedArtPieces.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No art pieces selected. Tap on markers in the map or use the list view to select art pieces.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

        if (_selectedArtPieces.isNotEmpty)
          Column(
            children: _selectedArtPieces.asMap().entries.map((entry) {
              final index = entry.key;
              final art = entry.value;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(art.title),
                  subtitle: Text(art.artistName ?? 'Unknown Artist'),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _toggleArtPieceSelection(art),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.artWalkId != null
                    ? 'Update Art Walk'
                    : 'Create Art Walk',
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}

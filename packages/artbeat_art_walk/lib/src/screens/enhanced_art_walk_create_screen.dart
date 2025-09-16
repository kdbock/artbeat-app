import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

// Enhanced Create Art Walk specific colors
class EnhancedCreateColors {
  static const Color primaryIndigo = Color(0xFF3F51B5);
  static const Color primaryIndigoLight = Color(0xFF5C6BC0);
  static const Color primaryIndigoDark = Color(0xFF303F9F);
  static const Color accentCyan = Color(0xFF00BCD4);
  static const Color accentCyanLight = Color(0xFF4DD0E1);
  static const Color backgroundGradientStart = Color(0xFFE8EAF6);
  static const Color backgroundGradientEnd = Color(0xFFE0F2F1);
  static const Color cardBackground = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF1A237E);
  static const Color textSecondary = Color(0xFF3F51B5);
}

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
    extends State<EnhancedArtWalkCreateScreen>
    with SingleTickerProviderStateMixin {
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
  final bool _isUploading = false;

  // Animation
  late AnimationController _introAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _hasShownIntro = false;

  // Services
  final ArtWalkService _artWalkService = ArtWalkService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _introAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _introAnimationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _introAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Start with intro if not editing
    if (widget.artWalkId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showIntroDialog();
      });
    }

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
    _introAnimationController.dispose();
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
      // debugPrint('Error getting current location: $e');
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
      // debugPrint('Error getting zip code from location: $e');
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
          if (coverImageUrl != null) {
            artWalkData['coverImageUrl'] = coverImageUrl;
            artWalkData['imageUrls'] = [coverImageUrl];
          }
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

  Future<String?> _uploadCoverImage(File imageFile) async {
    try {
      if (!mounted) return null;

      setState(() {
        _isLoading = true;
      });

      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final walkId =
          widget.artWalkId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_cover.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('art_walk_covers')
          .child(userId)
          .child(walkId)
          .child(fileName);

      final uploadTask = await ref.putFile(imageFile);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // debugPrint('✅ EnhancedArtWalkCreate: Cover image uploaded: $imageUrl');
      return imageUrl;
    } catch (e) {
      // debugPrint('❌ EnhancedArtWalkCreate: Error uploading cover image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading cover image: $e')),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showIntroDialog() {
    if (_hasShownIntro) return;
    _hasShownIntro = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: AlertDialog(
            title: const Text('Create Your Art Walk Journey'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_walk, size: 48, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  'Ready to curate your own artistic adventure?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a unique path through local art pieces, share your favorite spots, and inspire others to explore the artistic side of your city.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _introAnimationController.forward();
                },
                child: const Text('Let\'s Begin'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Art Walk Creation?'),
            content: const Text('Your progress will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: MainLayout(
        currentIndex: -1,
        child: Scaffold(
          appBar: EnhancedUniversalHeader(
            title: widget.artWalkId == null
                ? 'Create Art Walk'
                : 'Edit Art Walk',
            showLogo: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.chat),
                onPressed: () => Navigator.pushNamed(context, '/messaging'),
              ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProgressIndicator(),
                const SizedBox(height: 24),
                _buildTitleField(),
                const SizedBox(height: 16),
                _buildDescriptionField(),
                const SizedBox(height: 24),
                _buildMapSection(),
                const SizedBox(height: 24),
                _buildArtPiecesSection(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
        if (_isUploading) // Add loading overlay
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final int progress = _calculateProgress();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getProgressMessage(progress),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  int _calculateProgress() {
    int progress = 0;
    if (_titleController.text.isNotEmpty) progress += 20;
    if (_descriptionController.text.isNotEmpty) progress += 20;
    if (_selectedArtPieces.isNotEmpty) progress += 30;
    if (_routePoints.isNotEmpty) progress += 30;
    return progress;
  }

  String _getProgressMessage(int progress) {
    if (progress < 20) return 'Start by giving your walk a name! 🎨';
    if (progress < 40)
      return 'Great title! Now describe your artistic journey ✍️';
    if (progress < 70) return 'Add some art pieces to create your path 🗺️';
    if (progress < 100) return 'Almost there! Finalize your route 🎯';
    return 'Perfect! Ready to share your art walk! 🎉';
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Title',
        hintText: 'Give your art walk a creative name',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
      onChanged: (_) => setState(() {}), // Update progress
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Describe your art walk experience',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
      onChanged: (_) => setState(() {}), // Update progress
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Map View',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Map or List View Toggle
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showMapView = true;
                  });
                },
                child: const Text('Map View'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showMapView = false;
                  });
                },
                child: const Text('List View'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Map or List View
        SizedBox(
          height: 300,
          child: _showMapView ? _buildMapView() : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildArtPiecesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Art Pieces',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Selected Art Pieces Summary
        _buildSelectedArtSummary(),

        const SizedBox(height: 16),

        // Available Art Pieces
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          _availableArtPieces.isEmpty
              ? const Center(child: Text('No art pieces available.'))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: _availableArtPieces.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final art = _availableArtPieces[index];
                    final isSelected = _selectedArtPieces.contains(art);

                    return GestureDetector(
                      onTap: () => _toggleArtPieceSelection(art),
                      child: Card(
                        elevation: isSelected ? 4 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                child: Image.network(
                                  art.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    art.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    art.artistName ?? 'Unknown Artist',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ],
    );
  }

  Widget _buildMapView() {
    if (_mapCenter == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (kIsWeb) {
      return _buildWebMapFallback();
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
            leading:
                art.imageUrl.isNotEmpty &&
                    Uri.tryParse(art.imageUrl)?.hasScheme == true
                ? CircleAvatar(
                    backgroundImage:
                        NetworkImage(art.imageUrl) as ImageProvider,
                  )
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
    final progress = _calculateProgress();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      child: ElevatedButton(
        onPressed: progress == 100 ? _submitForm : null,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: progress == 100 ? 4 : 0,
        ),
        child: Text(
          progress == 100 ? 'Share Your Art Walk' : 'Complete Your Walk',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildWebMapFallback() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Create Art Walk',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Map-based art walk creation is optimized for mobile devices.\nUse the list view below to select art pieces for your walk.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

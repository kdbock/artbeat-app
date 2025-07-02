import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import '../services/art_walk_service.dart';
import '../services/google_maps_service.dart';
import '../models/art_walk_model.dart';

/// Fixed Art Walk Dashboard Screen - No overflow issues
class ArtWalkDashboardScreen extends StatefulWidget {
  const ArtWalkDashboardScreen({super.key});

  @override
  State<ArtWalkDashboardScreen> createState() => _ArtWalkDashboardScreenState();
}

class _ArtWalkDashboardScreenState extends State<ArtWalkDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;
  CameraPosition? _initialCameraPosition;
  Set<Marker> _markers = {};
  final ArtWalkService _artWalkService = ArtWalkService();
  final UserService _userService = UserService();
  final CaptureService _captureService = CaptureService();
  List<ArtWalkModel> _myWalks = [];
  List<ArtWalkModel> _publicWalks = [];
  List<CaptureModel> _myCaptures = [];
  List<CaptureModel> _nearbyCaptures = [];
  bool _isLoadingWalks = true;
  bool _isLoadingCaptures = true;
  String _userZipCode = '';
  bool _mapsInitialized = false;
  final TextEditingController _zipSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeMaps();
    _loadUserLocationAndSetMap();
    _loadData();
  }

  Future<void> _initializeMaps() async {
    final googleMapsService = GoogleMapsService();
    final initialized = await googleMapsService.initializeMaps();
    if (mounted) {
      setState(() => _mapsInitialized = initialized);
    }
  }

  Future<void> _loadUserLocationAndSetMap() async {
    try {
      final user = await _userService.getCurrentUserModel();
      if (user?.zipCode != null && user!.zipCode!.isNotEmpty) {
        final coordinates = await LocationUtils.getCoordinatesFromZipCode(
          user.zipCode!,
        );
        if (coordinates != null && mounted) {
          setState(() {
            _initialCameraPosition = CameraPosition(
              target: LatLng(coordinates.latitude, coordinates.longitude),
              zoom: 13,
            );
            _userZipCode = user.zipCode!;
          });
          _updateMapMarkers();
          _loadNearbyCaptures();
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _setFallbackLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 13,
          );
        });
        _updateMapMarkers();
        _loadNearbyCaptures();
      }
    } catch (e) {
      _setFallbackLocation();
    }
  }

  void _setFallbackLocation() {
    if (mounted) {
      setState(() {
        _initialCameraPosition = const CameraPosition(
          target: LatLng(37.7749, -122.4194),
          zoom: 13,
        );
      });
      _updateMapMarkers();
      _loadNearbyCaptures();
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMyWalks(),
      _loadPublicWalks(),
      _loadMyCaptures(),
      _loadNearbyCaptures(),
    ]);
  }

  Future<void> _loadMyWalks() async {
    try {
      final userId = _artWalkService.getCurrentUserId();
      if (userId == null) {
        if (mounted) setState(() => _isLoadingWalks = false);
        return;
      }
      final walks = await _artWalkService.getUserArtWalks(userId);
      if (mounted) {
        setState(() {
          _myWalks = walks;
          _isLoadingWalks = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingWalks = false);
    }
  }

  Future<void> _loadPublicWalks() async {
    try {
      final walks = await _artWalkService.getPopularArtWalks(limit: 20);
      if (mounted) setState(() => _publicWalks = walks);
    } catch (e) {
      if (mounted) setState(() => _publicWalks = []);
    }
  }

  Future<void> _loadMyCaptures() async {
    try {
      final userId = _artWalkService.getCurrentUserId();
      if (userId == null) {
        if (mounted) setState(() => _isLoadingCaptures = false);
        return;
      }
      final captures = await _captureService.getCapturesForUser(userId);
      if (mounted) {
        setState(() {
          _myCaptures = captures;
          _isLoadingCaptures = false;
        });
        _updateMapMarkers();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCaptures = false);
    }
  }

  Future<void> _loadNearbyCaptures() async {
    setState(() {
      _isLoadingCaptures = true;
    });

    try {
      // Use CaptureService to get all captures
      final captures = await _captureService.getAllCaptures(limit: 50);

      if (mounted) {
        setState(() {
          _nearbyCaptures = captures;
          _isLoadingCaptures = false;
        });
        _updateMapMarkers(); // Update map markers with captured art
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCaptures = false;
        });
      }
    }
  }

  void _updateMapMarkers() {
    if (!mounted || _initialCameraPosition == null) return;

    final Set<Marker> markers = {
      // User location marker
      Marker(
        markerId: const MarkerId('user_location'),
        position: _initialCameraPosition!.target,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };

    // Add captured art markers (show all nearby captures, not just user's)
    for (final capture in _nearbyCaptures) {
      if (capture.location != null) {
        markers.add(
          Marker(
            markerId: MarkerId('capture_capture.id'),
            position: LatLng(
              capture.location!.latitude,
              capture.location!.longitude,
            ),
            infoWindow: InfoWindow(
              title: capture.title ?? capture.artistName ?? 'Captured Art',
              snippet: capture.locationName ?? 'Public Art',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            onTap: () => _showCaptureDetails(capture),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showCaptureDetails(CaptureModel capture) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Image
                if (capture.imageUrl.isNotEmpty)
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(capture.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                // Title
                Text(
                  capture.title ?? 'Untitled Art Piece',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Artist
                if (capture.artistName?.isNotEmpty == true) ...[
                  Text(
                    'Artist: ${capture.artistName}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: ArtbeatColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Description
                if (capture.description?.isNotEmpty == true) ...[
                  Text(
                    capture.description!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                ],

                // Location
                if (capture.locationName?.isNotEmpty == true)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: ArtbeatColors.primaryPurple,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          capture.locationName!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to capture details or gallery
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ArtbeatColors.primaryPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to directions or map
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ArtbeatColors.primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    _zipSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 1, // Art Walk tab in bottom navigation
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: UniversalHeader(
          title: 'Art Walk Dashboard',
          showLogo: false,
          showDeveloperTools: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // Handle notifications
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                // Handle settings
              },
            ),
          ],
        ),
        drawer: const ArtbeatDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              // ZIP Search
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _zipSearchController,
                        decoration: const InputDecoration(
                          hintText: 'Enter ZIP code',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        buildCounter:
                            (
                              _, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () =>
                          _searchByZipCode(_zipSearchController.text.trim()),
                      child: const Text('Search'),
                    ),
                  ],
                ),
              ),

              // Map
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _mapsInitialized && _initialCameraPosition != null
                          ? GoogleMap(
                              initialCameraPosition: _initialCameraPosition!,
                              onMapCreated: (controller) =>
                                  _mapController = controller,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              markers: _markers,
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                    ),
                    // Sync to location button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: IconButton(
                          icon: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                          ),
                          tooltip: 'Sync to my location',
                          onPressed: _syncToCurrentLocation,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Map Legend
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem(
                      color: Colors.blue,
                      label: 'Your Location',
                      icon: Icons.person_pin_circle,
                    ),
                    _buildLegendItem(
                      color: Colors.green,
                      label: 'Captured Art',
                      icon: Icons.photo_camera,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Tabs
              Expanded(
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: ArtbeatColors.primaryPurple,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: ArtbeatColors.primaryPurple,
                        tabs: const [
                          Tab(text: 'My Walks'),
                          Tab(text: 'Discover'),
                          Tab(text: 'My Captures'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          TabBarView(
                            controller: _tabController,
                            children: [
                              _buildMyWalksTab(),
                              _buildDiscoverTab(),
                              _buildMyCapturesTab(),
                            ],
                          ),
                          // Floating action button for creating an art walk (only on My Walks tab)
                          Positioned(
                            bottom: 24,
                            right: 24,
                            child: AnimatedBuilder(
                              animation: _tabController,
                              builder: (context, child) {
                                return _tabController.index == 0
                                    ? FloatingActionButton.extended(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/art-walk/create',
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.add_location_alt,
                                        ),
                                        label: const Text('Create Art Walk'),
                                        backgroundColor:
                                            ArtbeatColors.primaryPurple,
                                      )
                                    : const SizedBox.shrink();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyWalksTab() {
    if (_isLoadingWalks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myWalks.isEmpty) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_walk, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No Art Walks Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Create your first art walk!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myWalks.length,
      itemBuilder: (context, index) => _buildWalkCard(_myWalks[index], true),
    );
  }

  Widget _buildDiscoverTab() {
    if (_publicWalks.isEmpty) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No Public Walks Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Check back later!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _publicWalks.length,
      itemBuilder: (context, index) =>
          _buildWalkCard(_publicWalks[index], false),
    );
  }

  Widget _buildMyCapturesTab() {
    if (_isLoadingCaptures) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myCaptures.isEmpty) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No Captures Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Start capturing art!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _myCaptures.length,
      itemBuilder: (context, index) => _buildCaptureCard(_myCaptures[index]),
    );
  }

  Widget _buildWalkCard(ArtWalkModel walk, bool isOwner) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isOwner ? Icons.directions_walk : Icons.public,
          color: isOwner
              ? ArtbeatColors.primaryPurple
              : ArtbeatColors.primaryGreen,
        ),
        title: Text(
          walk.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${walk.artPieces.length} art pieces'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(
          context,
          '/art-walk/detail',
          arguments: {'walkId': walk.id}, // Pass as map for detail screen
        ),
      ),
    );
  }

  Widget _buildCaptureCard(CaptureModel capture) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: capture.imageUrl.isNotEmpty
                ? Image.network(
                    capture.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 40),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.camera_alt, size: 40),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                capture.title ?? 'Untitled',
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Future<void> _searchByZipCode(String zipCode) async {
    if (zipCode.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 5-digit ZIP code')),
      );
      return;
    }

    try {
      final coordinates = await LocationUtils.getCoordinatesFromZipCode(
        zipCode,
      );
      if (coordinates != null && mounted) {
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: LatLng(coordinates.latitude, coordinates.longitude),
            zoom: 13,
          );
          _userZipCode = zipCode;
        });
        _updateMapMarkers();
        _loadNearbyCaptures();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error searching location')),
        );
      }
    }
  }

  Future<void> _syncToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission permanently denied. Please enable it in settings.',
            ),
          ),
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final newCameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 13,
      );
      setState(() {
        _initialCameraPosition = newCameraPosition;
      });
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(newCameraPosition),
      );
      _updateMapMarkers();
      _loadNearbyCaptures();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error syncing to location: $e')));
    }
  }
}

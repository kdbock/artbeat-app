import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import '../services/art_walk_service.dart';
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
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final TextEditingController _zipSearchController = TextEditingController();
  Position? _currentPosition;
  List<CaptureModel> _nearbyCaptures = [];
  bool _isLoadingWalks = true;

  final ArtWalkService _artWalkService = ArtWalkService();
  final UserService _userService = UserService();
  final CaptureService _captureService = CaptureService();
  List<ArtWalkModel> _myWalks = [];
  List<ArtWalkModel> _publicWalks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.wait([_loadUserLocationAndSetMap(), _loadData()]);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _zipSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocationAndSetMap() async {
    try {
      // First try to get location from stored ZIP code
      final user = await _userService.getCurrentUserModel();
      if (user?.zipCode != null && user!.zipCode!.isNotEmpty) {
        final coordinates = await LocationUtils.getCoordinatesFromZipCode(
          user.zipCode!,
        );
        if (coordinates != null && mounted) {
          _updateMapPosition(coordinates.latitude, coordinates.longitude);
          return;
        }
      }

      // Then try to get current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        _updateMapPosition(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Default to Asheville, NC
      _updateMapPosition(35.5951, -82.5515);
    }
  }

  Position _createPosition(double latitude, double longitude) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Art Walks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Map'),
            Tab(icon: Icon(Icons.directions_walk), text: 'My Walks'),
            Tab(icon: Icon(Icons.explore), text: 'Discover'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMapTab(), _buildMyWalksTab(), _buildDiscoverTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/art-walk/create'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: UniversalBottomNav(
        currentIndex: 1, // Art Walk tab
        onTap: (int index) {
          final currentRoute = ModalRoute.of(context)?.settings.name;
          switch (index) {
            case 0:
              if (currentRoute != '/dashboard') {
                Navigator.pushReplacementNamed(context, '/dashboard');
              }
              break;
            case 1:
              // Already here
              break;
            case 2:
              if (currentRoute != '/community') {
                Navigator.pushReplacementNamed(context, '/community');
              }
              break;
            case 3:
              if (currentRoute != '/events') {
                Navigator.pushReplacementNamed(context, '/events');
              }
              break;
            case 4:
              if (currentRoute != '/capture') {
                Navigator.pushNamed(context, '/capture');
              }
              break;
          }
        },
      ),
    );
  }

  void _updateMapPosition(double latitude, double longitude) {
    setState(() {
      _currentPosition = _createPosition(latitude, longitude);
      // Reset ZIP code on map move
    });
    _updateMapMarkers();
    _loadNearbyCaptures();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMyWalks(),
      _loadPublicWalks(),
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

  Future<void> _loadNearbyCaptures() async {
    setState(() {
      _isLoadingWalks = true;
    });

    try {
      // Use CaptureService to get all captures
      final captures = await _captureService.getAllCaptures(limit: 50);

      if (mounted) {
        setState(() {
          _nearbyCaptures = captures;
          _isLoadingWalks = false;
        });
        _updateMapMarkers(); // Update map markers with captured art
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWalks = false;
        });
      }
    }
  }

  void _updateMapMarkers() {
    if (!mounted || _currentPosition == null) return;

    final Set<Marker> markers = {
      // User location marker
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };

    // Add captured art markers (show all nearby captures, not just user's)
    for (final capture in _nearbyCaptures) {
      if (capture.location != null) {
        markers.add(
          Marker(
            markerId: MarkerId('capture_${capture.id}'),
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
      _markers.clear();
      _markers.addAll(markers);
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
                Text(
                  capture.title ?? 'Untitled Art Piece',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
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
                if (capture.description?.isNotEmpty == true) ...[
                  Text(
                    capture.description!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                ],
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ArtbeatColors.primaryPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
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

  Widget _buildMapTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ArtbeatColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ArtbeatColors.primaryPurple.withAlpha((0.1 * 255).toInt()),
        ),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withAlpha((0.05 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _currentPosition != null
            ? Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      zoom: 13,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                  ),
                  // Optional Map Overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ArtbeatColors.backgroundPrimary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.1 * 255).toInt()),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${_markers.length} artworks',
                        style: const TextStyle(
                          color: ArtbeatColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ArtbeatColors.primaryPurple,
                  ),
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

  Widget _buildWalkCard(ArtWalkModel walk, bool isOwner) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: ArtbeatColors.primaryPurple.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/art-walk/detail',
          arguments: walk.id,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section
            Container(
              height: 160,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                color: ArtbeatColors.backgroundSecondary,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Stack(
                  children: [
                    _buildWalkImage(walk),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha((0.5 * 255).toInt()),
                          ],
                        ),
                      ),
                    ),
                    // Info overlay
                    Positioned(
                      left: 12,
                      bottom: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            walk.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.white.withAlpha(
                                  (0.8 * 255).toInt(),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  walk.zipCode ?? 'No location',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(
                                      (0.8 * 255).toInt(),
                                    ),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Stats section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWalkStat(
                    icon: Icons.route,
                    value:
                        '${(walk.estimatedDistance ?? 0.0).toStringAsFixed(1)} mi',
                    label: 'Distance',
                  ),
                  _buildWalkStat(
                    icon: Icons.palette,
                    value: '${walk.artworkIds.length}',
                    label: 'Artworks',
                  ),
                  _buildWalkStat(
                    icon: Icons.access_time,
                    value: '${(walk.estimatedDuration ?? 0).toInt()} min',
                    label: 'Duration',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: ArtbeatColors.primaryPurple),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: ArtbeatColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: ArtbeatColors.textSecondary.withAlpha(200),
          ),
        ),
      ],
    );
  }

  Widget _buildWalkImage(ArtWalkModel walk) {
    // Try to show cover image first
    if (walk.coverImageUrl?.isNotEmpty == true) {
      return Image.network(
        walk.coverImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(walk),
      );
    }

    // Try to show first image from imageUrls
    if (walk.imageUrls.isNotEmpty) {
      return Image.network(
        walk.imageUrls.first,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(walk),
      );
    }

    // Show fallback image
    return _buildFallbackImage(walk);
  }

  Widget _buildFallbackImage(ArtWalkModel walk) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Art Walk',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

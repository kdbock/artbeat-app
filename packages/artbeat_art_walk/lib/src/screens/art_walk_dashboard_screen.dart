import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import '../services/art_walk_service.dart';
import '../services/google_maps_service.dart';
import '../models/art_walk_model.dart';
import 'my_captures_screen.dart';

/// Art Walk Dashboard Screen
/// Shows user's art walks, public walks, and map preview. Entry point for creating and exploring art walks.
class ArtWalkDashboardScreen extends StatefulWidget {
  const ArtWalkDashboardScreen({super.key});

  @override
  State<ArtWalkDashboardScreen> createState() => _ArtWalkDashboardScreenState();
}

class _ArtWalkDashboardScreenState extends State<ArtWalkDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showOnboarding = true;
  GoogleMapController? _mapController;
  CameraPosition? _initialCameraPosition;
  final ArtWalkService _artWalkService = ArtWalkService();
  final UserService _userService = UserService();
  final CaptureService _captureService = CaptureService();
  List<ArtWalkModel> _myWalks = [];
  List<ArtWalkModel> _publicWalks = [];
  List<CaptureModel> _myCaptures = [];
  bool _isLoadingWalks = true;
  bool _isLoadingCaptures = true;
  String _userZipCode = '';
  bool _mapsInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed to 3 tabs
    _initializeMaps();
    _loadUserLocationAndSetMap();
    _loadData();
  }

  /// Initialize Google Maps
  Future<void> _initializeMaps() async {
    debugPrint('🗺️ Initializing Google Maps...');
    final googleMapsService = GoogleMapsService();
    final initialized = await googleMapsService.initializeMaps();

    if (mounted) {
      setState(() {
        _mapsInitialized = initialized;
      });

      if (initialized) {
        debugPrint('✅ Maps initialized successfully');
      } else {
        debugPrint('❌ Failed to initialize maps');
      }
    }
  }

  Future<void> _loadUserLocationAndSetMap() async {
    try {
      // First try to use user's ZIP code if available
      final user = await _userService.getCurrentUserModel();
      if (user?.zipCode != null && user!.zipCode!.isNotEmpty) {
        final coordinates = await LocationUtils.getCoordinatesFromZipCode(
          user.zipCode!,
        );
        if (coordinates != null) {
          debugPrint(
            '📍 Art Walk Dashboard: Using user ZIP code location: ${user.zipCode}',
          );
          if (mounted) {
            setState(() {
              _initialCameraPosition = CameraPosition(
                target: LatLng(coordinates.latitude, coordinates.longitude),
                zoom: 13,
              );
            });
          }
          return;
        }
      }

      // Fall back to GPS location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _setFallbackLocation();
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Update user's ZIP code if we don't have one
      if (user?.zipCode == null || user!.zipCode!.isEmpty) {
        final zipCode = await LocationUtils.getZipCodeFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (zipCode.isNotEmpty) {
          await _userService.updateUserZipCode(zipCode);
          debugPrint(
            '📍 Art Walk Dashboard: Updated user ZIP code to: $zipCode',
          );
        }
      }

      if (mounted) {
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 13,
          );
        });
      }
    } catch (e) {
      debugPrint('Error getting user location: $e');
      _setFallbackLocation();
    }
  }

  void _setFallbackLocation() {
    if (mounted) {
      setState(() {
        _initialCameraPosition = const CameraPosition(
          target: LatLng(37.7749, -122.4194), // San Francisco
          zoom: 13,
        );
      });
    }
  }

  Future<void> _loadData() async {
    await _loadUserZipCode();
    await Future.wait([_loadMyWalks(), _loadPublicWalks(), _loadMyCaptures()]);
  }

  Future<void> _loadUserZipCode() async {
    try {
      final user = await _userService.getCurrentUserModel();
      if (user?.zipCode != null && user!.zipCode!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _userZipCode = user.zipCode!;
          });
        }
        debugPrint(
          '📍 Art Walk Dashboard: Loaded user ZIP code: ${user.zipCode}',
        );
      } else {
        debugPrint('📍 Art Walk Dashboard: No user ZIP code found');
      }
    } catch (e) {
      debugPrint('❌ Art Walk Dashboard: Error loading user ZIP code: $e');
    }
  }

  Future<void> _loadMyWalks() async {
    try {
      final userId = _artWalkService.getCurrentUserId();
      if (userId == null) {
        if (mounted) {
          setState(() {
            _myWalks = [];
            _isLoadingWalks = false;
          });
        }
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
      debugPrint('Error loading my walks: $e');
      if (mounted) {
        setState(() {
          _myWalks = [];
          _isLoadingWalks = false;
        });
      }
    }
  }

  Future<void> _loadPublicWalks() async {
    try {
      List<ArtWalkModel> walks;
      if (_userZipCode.isNotEmpty) {
        // Load walks near user's ZIP code first
        walks = await _artWalkService.getArtWalksByZipCodes([
          _userZipCode,
        ], limit: 20);
        debugPrint(
          '📍 Loaded ${walks.length} walks for ZIP code: $_userZipCode',
        );

        // If no walks found for user's ZIP, fall back to popular walks
        if (walks.isEmpty) {
          walks = await _artWalkService.getPopularArtWalks(limit: 20);
          debugPrint('📍 Fallback: Loaded ${walks.length} popular walks');
        }
      } else {
        // No user ZIP code, load popular walks
        walks = await _artWalkService.getPopularArtWalks(limit: 20);
        debugPrint('📍 No user ZIP, loaded ${walks.length} popular walks');
      }

      if (mounted) {
        setState(() {
          _publicWalks = walks;
        });
      }
    } catch (e) {
      debugPrint('Error loading public walks: $e');
      if (mounted) {
        setState(() {
          _publicWalks = [];
        });
      }
    }
  }

  Future<void> _loadMyCaptures() async {
    try {
      final userId = _artWalkService.getCurrentUserId();
      if (userId == null) {
        if (mounted) {
          setState(() {
            _myCaptures = [];
            _isLoadingCaptures = false;
          });
        }
        return;
      }

      final captures = await _captureService.getCapturesForUser(userId);
      if (mounted) {
        setState(() {
          _myCaptures = captures;
          _isLoadingCaptures = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading captures: $e');
      if (mounted) {
        setState(() {
          _myCaptures = [];
          _isLoadingCaptures = false;
        });
        // Only show error if it's not a simple "no captures" case
        if (e.toString().contains('permission-denied') ||
            e.toString().contains('network') ||
            e.toString().contains('timeout')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to load captures: Please check your connection',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onCreateArtWalk() {
    Navigator.pushNamed(context, '/art-walk/create');
  }

  void _onCapture() {
    Navigator.pushNamed(context, '/capture');
  }

  Set<Marker> _getMarkers() {
    if (_initialCameraPosition == null) return {};

    final Set<Marker> markers = {};

    // Add user location marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _initialCameraPosition!.target,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    // Add markers for nearby captured art
    for (final capture in _myCaptures) {
      if (capture.location != null) {
        final geoPoint = capture.location!;
        final latLng = LatLng(geoPoint.latitude, geoPoint.longitude);
        final markerId = capture.id.isNotEmpty
            ? capture.id
            : (capture.title ?? 'capture_marker');
        markers.add(
          Marker(
            markerId: MarkerId(markerId),
            position: latLng,
            infoWindow: InfoWindow(title: capture.title ?? 'Captured Art'),
          ),
        );
      }
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 1, // Art Walk is index 1
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: UniversalHeader(
          title: 'Art Walks',
          showLogo: false,
          showDeveloperTools: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.help_outline,
                color: ArtbeatColors.primaryPurple,
              ),
              tooltip: 'How Art Walks Work',
              onPressed: () {
                setState(() => _showOnboarding = true);
              },
            ),
          ],
        ),
        drawer: const ArtbeatDrawer(),
        body: Container(
          constraints: const BoxConstraints.expand(),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ArtbeatColors.primaryPurple.withAlpha(13),
                Colors.white,
                ArtbeatColors.primaryGreen.withAlpha(13),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                if (_showOnboarding) _onboardingCard(),

                // Create Art Walk Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    border: Border(
                      bottom: BorderSide(
                        color: ArtbeatColors.border.withAlpha(128),
                        width: 1,
                      ),
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _onCreateArtWalk,
                    icon: const Icon(Icons.add_road),
                    label: const Text('Create Art Walk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtbeatColors.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    border: Border(
                      bottom: BorderSide(
                        color: ArtbeatColors.border.withAlpha(128),
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: ArtbeatColors.primaryPurple,
                    unselectedLabelColor: ArtbeatColors.textSecondary,
                    indicatorColor: ArtbeatColors.primaryPurple,
                    tabs: const [
                      Tab(text: 'My Walks'),
                      Tab(text: 'Discover'),
                      Tab(text: 'My Captures'), // Added My Captures tab
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _myWalksTab(),
                      _discoverTab(),
                      _myCapturesTab(), // Added My Captures tab content
                    ],
                  ),
                ),

                // Map Preview
                _mapPreviewSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _onboardingCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtbeatColors.primaryPurple.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArtbeatColors.primaryPurple.withAlpha(77)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.directions_walk,
            size: 40,
            color: ArtbeatColors.primaryPurple,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How Art Walks Work',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Capture art with your camera. Each photo is pinned to its location. Create self-guided art walks by linking your art locations. Share your walks, explore others, and leave reviews!',
                  style: TextStyle(color: ArtbeatColors.textSecondary),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _showOnboarding = false),
                    style: TextButton.styleFrom(
                      foregroundColor: ArtbeatColors.primaryPurple,
                    ),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _myWalksTab() {
    if (_isLoadingWalks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myWalks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_walk, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No Art Walks Yet',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first art walk by capturing art and linking locations!',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _onCreateArtWalk,
                icon: const Icon(Icons.add_road),
                label: const Text('Create Art Walk'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyWalks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myWalks.length,
        itemBuilder: (context, index) {
          final walk = _myWalks[index];
          return _artWalkListTile(
            walk: walk,
            onTap: () => Navigator.pushNamed(
              context,
              '/art-walk/detail',
              arguments: walk.id,
            ),
            onEdit: () => Navigator.pushNamed(
              context,
              '/art-walk/edit',
              arguments: walk.id,
            ),
            onDelete: () => _deleteWalk(walk),
          );
        },
      ),
    );
  }

  Widget _discoverTab() {
    if (_publicWalks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.explore, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No Public Walks Available',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for new art walks from the community!',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPublicWalks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _publicWalks.length,
        itemBuilder: (context, index) {
          final walk = _publicWalks[index];
          return _artWalkListTile(
            walk: walk,
            onTap: () => Navigator.pushNamed(
              context,
              '/art-walk/detail',
              arguments: walk.id,
            ),
            isPublic: true,
          );
        },
      ),
    );
  }

  Widget _myCapturesTab() {
    if (_isLoadingCaptures) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myCaptures.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Captures Yet',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Start capturing art around you to see them here!',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _onCapture,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capture Art'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyCaptures,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: _myCaptures.length,
        itemBuilder: (context, index) {
          final capture = _myCaptures[index];
          return _buildCaptureCard(capture);
        },
      ),
    );
  }

  Widget _buildCaptureCard(CaptureModel capture) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showCaptureDetail(capture),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[200]),
                child: capture.imageUrl.isNotEmpty
                    ? Image.network(
                        capture.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capture.title ?? 'Untitled',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (capture.artistName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'by ${capture.artistName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          capture.isPublic ? Icons.public : Icons.lock,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          capture.isPublic ? 'Public' : 'Private',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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

  void _showCaptureDetail(CaptureModel capture) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => MyCapturesScreen(initialCapture: capture),
      ),
    );
  }

  Widget _artWalkListTile({
    required ArtWalkModel walk,
    required VoidCallback onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    bool isPublic = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          isPublic ? Icons.public : Icons.directions_walk,
          color: isPublic
              ? ArtbeatColors.primaryGreen
              : ArtbeatColors.primaryPurple,
        ),
        title: Text(
          walk.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.textPrimary,
          ),
        ),
        subtitle: Text(
          walk.description,
          style: const TextStyle(color: ArtbeatColors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
        trailing: onEdit != null && onDelete != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: ArtbeatColors.primaryPurple,
                    ),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Future<void> _deleteWalk(ArtWalkModel walk) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Art Walk'),
        content: Text('Are you sure you want to delete "${walk.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _artWalkService.deleteArtWalk(walk.id);
        _loadMyWalks(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Art walk deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting art walk: $e')),
          );
        }
      }
    }
  }

  Widget _mapPreviewSection() {
    if (_initialCameraPosition == null || !_mapsInitialized) {
      return Container(
        height: 180,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                _mapsInitialized ? 'Loading map...' : 'Initializing maps...',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 180,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: _initialCameraPosition!,
          onMapCreated: (controller) {
            _mapController = controller;
            debugPrint('🗺️ Art Walk Map created successfully');
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: _getMarkers(),
          onTap: (position) {
            // Navigate to full map view
            Navigator.pushNamed(context, '/art-walk/map');
          },
        ),
      ),
    );
  }
}

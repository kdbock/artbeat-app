import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_ads/artbeat_ads.dart';
import '../widgets/art_walk_drawer.dart';

// Art Walk specific colors
class ArtWalkColors {
  static const Color primaryTeal = Color(0xFF00838F);
  static const Color primaryTealLight = Color(0xFF4FB3BE);
  static const Color primaryTealDark = Color(0xFF005662);
  static const Color accentOrange = Color(0xFFFF7043);
  static const Color accentOrangeLight = Color(0xFFFF9E80);
  static const Color backgroundGradientStart = Color(0xFFE0F2F1);
  static const Color backgroundGradientEnd = Color(0xFFE8F5E8);
  static const Color cardBackground = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF607D8B);
}

/// Redesigned Art Walk Dashboard Screen
/// Welcome Traveler, User Name - Where will art take you today?
/// - Map widget that syncs to user location and populates local captures
/// - Captures widget (local, user captures)
/// - Art walks widget (local, user created)
/// - Achievements related to Art Walk
class ArtWalkDashboardScreen extends StatefulWidget {
  const ArtWalkDashboardScreen({super.key});

  @override
  State<ArtWalkDashboardScreen> createState() => _ArtWalkDashboardScreenState();
}

class _ArtWalkDashboardScreenState extends State<ArtWalkDashboardScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  List<CaptureModel> _localCaptures = [];
  List<AchievementModel> _artWalkAchievements = [];
  UserModel? _currentUser;
  bool _isDisposed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final ArtWalkService _artWalkService = ArtWalkService();
  final AchievementService _achievementService = AchievementService();
  final UserService _userService = UserService();
  final CaptureService _captureService = CaptureService();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadCurrentUser(),
      _loadUserLocationAndSetMap(),
      _loadLocalCaptures(),
      _loadArtWalkAchievements(),
    ]);
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userService.getCurrentUserModel();
      if (!_isDisposed && mounted) {
        setState(() => _currentUser = user);
      }
    } catch (e) {
      // debugPrint('Error loading current user: $e');
    }
  }

  Future<void> _loadUserLocationAndSetMap() async {
    try {
      // First try to get location from stored ZIP code
      if (_currentUser?.zipCode != null && _currentUser!.zipCode!.isNotEmpty) {
        final coordinates = await LocationUtils.getCoordinatesFromZipCode(
          _currentUser!.zipCode!,
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

      if (!_isDisposed && mounted) {
        _updateMapPosition(position.latitude, position.longitude);
      }
    } catch (e) {
      // debugPrint('Error getting location: $e');
      // Default to Asheville, NC
      _updateMapPosition(35.5951, -82.5515);
    }
  }

  Future<void> _loadLocalCaptures() async {
    try {
      // Load all public captures for discovery
      final captures = await _captureService.getAllCaptures(limit: 50);
      if (!_isDisposed && mounted) {
        setState(() => _localCaptures = captures);
      }
    } catch (e) {
      // debugPrint('Error loading local captures: $e');
    }
  }

  Future<void> _loadArtWalkAchievements() async {
    try {
      final userId = _artWalkService.getCurrentUserId();
      if (userId != null) {
        final achievements = await _achievementService.getUserAchievements(
          userId: userId,
        );
        if (!_isDisposed && mounted) {
          setState(() => _artWalkAchievements = achievements);
        }
      }
    } catch (e) {
      // debugPrint('Error loading achievements: $e');
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

  void _updateMapPosition(double latitude, double longitude) {
    if (_isDisposed) return;
    setState(() {
      _currentPosition = _createPosition(latitude, longitude);
    });
    _updateMapMarkers();
  }

  void _updateMapMarkers() {
    if (!mounted || _currentPosition == null || _isDisposed) return;

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

    // Add local capture markers
    for (final capture in _localCaptures) {
      if (capture.location != null) {
        markers.add(
          Marker(
            markerId: MarkerId('capture_${capture.id}'),
            position: LatLng(
              capture.location!.latitude,
              capture.location!.longitude,
            ),
            infoWindow: InfoWindow(
              title: capture.title ?? capture.artistName ?? 'Local Art',
              snippet: capture.locationName ?? 'Art Discovery',
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
                        image: NetworkImage(capture.imageUrl) as ImageProvider,
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
                      color: ArtWalkColors.primaryTeal,
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
                        color: ArtWalkColors.primaryTeal,
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context); // Close the bottom sheet
                            // Navigate to create art walk with this capture pre-selected
                            Navigator.pushNamed(
                              context,
                              '/art-walk/create',
                              arguments: {'preSelectedCapture': capture},
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: ArtWalkColors.accentOrange.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: ArtWalkColors.accentOrange.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFF7043), // Orange
                                          Color(0xFFFF9E80), // Light Orange
                                        ],
                                      ).createShader(
                                        Rect.fromLTWH(
                                          0,
                                          0,
                                          bounds.width,
                                          bounds.height,
                                        ),
                                      ),
                                  child: const Icon(
                                    Icons.add_location,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Add to Art Walk',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: ArtWalkColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close, color: Colors.grey, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Close',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  // ignore: unused_element
  void _showArtistDiscoveryMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.palette,
                      color: ArtWalkColors.primaryTeal,
                      size: 24,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Artist Discovery',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ArtWalkColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Connect with artists and explore their work',
                            style: TextStyle(
                              fontSize: 14,
                              color: ArtWalkColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Menu items
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildDiscoveryTile(
                      icon: Icons.person_search,
                      title: 'Find Artists',
                      subtitle: 'Discover local and featured artists',
                      color: ArtWalkColors.primaryTeal,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artist-search');
                      },
                    ),
                    _buildDiscoveryTile(
                      icon: Icons.trending_up,
                      title: 'Trending',
                      subtitle: 'Popular artists and trending art',
                      color: ArtWalkColors.accentOrange,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/trending');
                      },
                    ),
                    _buildDiscoveryTile(
                      icon: Icons.palette,
                      title: 'Browse Artwork',
                      subtitle: 'Explore art collections and galleries',
                      color: ArtWalkColors.primaryTealLight,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artwork/browse');
                      },
                    ),
                    _buildDiscoveryTile(
                      icon: Icons.location_on,
                      title: 'Local Scene',
                      subtitle: 'Art events and spaces near you',
                      color: ArtWalkColors.primaryTealDark,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/local');
                      },
                    ),
                    _buildDiscoveryTile(
                      icon: Icons.account_circle,
                      title: 'My Profile',
                      subtitle: 'View and edit your profile',
                      color: ArtWalkColors.textSecondary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/profile');
                      },
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

  Widget _buildDiscoveryTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ArtWalkColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ArtWalkColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 1,
      drawer: const ArtWalkDrawer(),
      scaffoldKey: _scaffoldKey,
      appBar: EnhancedUniversalHeader(
        title: 'Art Walk',
        showLogo: false,
        showBackButton: false,
        scaffoldKey: _scaffoldKey,
        backgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFF4FB3BE), // Light Teal
            Color(0xFFFF9E80), // Light Orange/Peach
          ],
        ),
        titleGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFF4FB3BE), // Light Teal
            Color(0xFFFF9E80), // Light Orange/Peach
          ],
        ),
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4FB3BE), // Light Teal
                Color(0xFFFF9E80), // Light Orange
                ArtWalkColors.backgroundGradientStart,
                ArtWalkColors.backgroundGradientEnd,
              ],
              stops: [0.0, 0.15, 0.5, 1.0],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // ZIP Code Search Box for location-based discovery
                ZipCodeSearchBox(
                  initialValue: _currentUser?.zipCode ?? '',
                  onZipCodeSubmitted: (zipCode) async {
                    try {
                      final coordinates =
                          await LocationUtils.getCoordinatesFromZipCode(
                            zipCode,
                          );
                      if (coordinates != null && mounted) {
                        // Update map position and reload data
                        _updateMapPosition(
                          coordinates.latitude,
                          coordinates.longitude,
                        );
                        // Reload local captures for new location
                        await _loadLocalCaptures();
                        // Update user ZIP code
                        if (_currentUser != null) {
                          // Note: UserService doesn't have updateUser method
                          // ZIP code is stored locally for this session
                          setState(
                            () => _currentUser = _currentUser!.copyWith(
                              zipCode: zipCode,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invalid ZIP code: $zipCode'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  isLoading: false,
                ),
                const SizedBox(height: 16),
                _buildMapWidget(),
                const SizedBox(height: 16),
                const BannerAdWidget(location: AdLocation.artWalkMap),
                const SizedBox(height: 24),
                _buildCapturesWidget(),
                const SizedBox(height: 16),
                const BannerAdWidget(location: AdLocation.artWalkCaptures),
                const SizedBox(height: 24),
                _buildArtWalksWidget(),
                const SizedBox(height: 24),
                _buildAchievementsWidget(),
                const SizedBox(height: 16),
                const BannerAdWidget(location: AdLocation.artWalkAchievements),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/art-walk/create'),
          backgroundColor: ArtWalkColors.accentOrange,
          foregroundColor: Colors.white,
          elevation: 8,
          label: const Text(
            'Create Art Walk',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          icon: const Icon(Icons.add_location, size: 24),
        ),
      ),
    );
  }

  Widget _buildMapWidget() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: ArtWalkColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ArtWalkColors.primaryTeal.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/art-walk/map');
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.map,
                    color: ArtWalkColors.primaryTeal,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Local Art Map',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ArtWalkColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ArtWalkColors.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_localCaptures.length} captures',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ArtWalkColors.primaryTeal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: ArtWalkColors.primaryTeal,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ArtWalkColors.primaryTeal.withValues(alpha: 0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _currentPosition != null
                    ? GoogleMap(
                        onMapCreated: (controller) =>
                            _mapController = controller,
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
                        mapToolbarEnabled: false,
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ArtWalkColors.primaryTeal,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturesWidget() {
    return Container(
      decoration: BoxDecoration(
        color: ArtWalkColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ArtWalkColors.primaryTeal.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.camera_alt,
                  color: ArtWalkColors.primaryTeal,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Captures',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ArtWalkColors.textPrimary,
                    ),
                  ),
                ),
                const Spacer(),
                if (_localCaptures.isNotEmpty) ...[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          Navigator.pushNamed(context, '/capture/public'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: ArtWalkColors.primaryTeal.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ArtWalkColors.primaryTeal.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF00FF87), // Green
                                      Color(0xFF7B2FF2), // Purple
                                    ],
                                  ).createShader(
                                    Rect.fromLTWH(
                                      0,
                                      0,
                                      bounds.width,
                                      bounds.height,
                                    ),
                                  ),
                              child: const Icon(
                                Icons.visibility,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'View All',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ArtWalkColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          Navigator.pushNamed(context, '/art-walk/create'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: ArtWalkColors.accentOrange.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ArtWalkColors.accentOrange.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFF7043), // Orange
                                      Color(0xFFFF9E80), // Light Orange
                                    ],
                                  ).createShader(
                                    Rect.fromLTWH(
                                      0,
                                      0,
                                      bounds.width,
                                      bounds.height,
                                    ),
                                  ),
                              child: const Icon(
                                Icons.add_location,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Create Walk',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ArtWalkColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_localCaptures.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'No local captures yet. Be the first to discover art here!',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 120,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _localCaptures.take(10).length,
                itemBuilder: (context, index) {
                  final capture = _localCaptures[index];
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => _showCaptureDetails(capture),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ArtWalkColors.primaryTeal.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: capture.imageUrl.isNotEmpty
                                    ? Image.network(
                                        capture.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                    Icons.image,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            capture.title?.isNotEmpty == true
                                ? capture.title!
                                : capture.artistName?.isNotEmpty == true
                                ? capture.artistName!
                                : 'Art Piece',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ArtWalkColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (capture.locationName?.isNotEmpty == true)
                            Text(
                              capture.locationName!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: ArtWalkColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArtWalksWidget() {
    return LocalArtWalkPreviewWidget(
      zipCode: _currentUser?.zipCode ?? '10001',
      onSeeAllPressed: () => Navigator.pushNamed(context, '/art-walk/list'),
    );
  }

  Widget _buildAchievementsWidget() {
    return AchievementsGrid(
      achievements: _artWalkAchievements,
      onAchievementTap: (achievement) {
        // Handle achievement tap - could show details or navigate
        // For now, just show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Achievement: ${achievement.title}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}

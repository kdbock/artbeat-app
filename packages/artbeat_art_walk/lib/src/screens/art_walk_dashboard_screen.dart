import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_ads/artbeat_ads.dart';
import 'package:flutter/foundation.dart';

// Dashboard specific colors (using design system colors)
class DashboardColors {
  static const Color primaryTeal = ArtWalkDesignSystem.primaryTeal;
  static const Color primaryTealLight = ArtWalkDesignSystem.primaryTealLight;
  static const Color primaryTealDark = ArtWalkDesignSystem.primaryTealDark;
  static const Color accentOrange = ArtWalkDesignSystem.accentOrange;
  static const Color accentOrangeLight = ArtWalkDesignSystem.accentOrangeLight;
  static const Color backgroundGradientStart =
      ArtWalkDesignSystem.backgroundGradientStart;
  static const Color backgroundGradientEnd =
      ArtWalkDesignSystem.backgroundGradientEnd;
  static const Color cardBackground = ArtWalkDesignSystem.cardBackground;
  static const Color textPrimary = ArtWalkDesignSystem.textPrimary;
  static const Color textSecondary = ArtWalkDesignSystem.textSecondary;
  static const Color headingDarkPurple = Color(
    0xFF2D1B69,
  ); // Dark purple, almost black
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
  Set<Marker> _markers = {};
  Position? _currentPosition;
  List<CaptureModel> _localCaptures = [];
  List<AchievementModel> _artWalkAchievements = [];
  UserModel? _currentUser;
  bool _isDisposed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Engagement boost state variables
  int _currentStreak = 0;
  String? _featuredWalkTitle;
  int _activeWalkersNearby = 0;
  List<String> _friendsRecentWalks = [];
  String? _dailyChallenge;
  int _dailyChallengeProgress = 0;
  final int _dailyChallengeTarget = 3;

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
      _loadEngagementData(),
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

  Future<void> _loadEngagementData() async {
    try {
      // Load engagement boost data
      await Future.wait([
        _loadUserStreak(),
        _loadFeaturedWalk(),
        _loadActiveWalkersNearby(),
        _loadFriendsRecentWalks(),
        _loadDailyChallenge(),
        _loadTrendingCaptures(),
      ]);
    } catch (e) {
      // debugPrint('Error loading engagement data: $e');
    }
  }

  Future<void> _loadUserStreak() async {
    try {
      // Mock data for now - in real implementation, this would come from user service
      if (!_isDisposed && mounted) {
        setState(() => _currentStreak = 5); // Example: 5-day streak
      }
    } catch (e) {
      // debugPrint('Error loading user streak: $e');
    }
  }

  Future<void> _loadFeaturedWalk() async {
    try {
      // Mock data for now - in real implementation, this would come from content service
      if (!_isDisposed && mounted) {
        setState(() => _featuredWalkTitle = 'Downtown Mural Discovery');
      }
    } catch (e) {
      // debugPrint('Error loading featured walk: $e');
    }
  }

  Future<void> _loadActiveWalkersNearby() async {
    try {
      // Mock data for now - in real implementation, this would come from location service
      if (!_isDisposed && mounted) {
        setState(() => _activeWalkersNearby = 12);
      }
    } catch (e) {
      // debugPrint('Error loading active walkers: $e');
    }
  }

  Future<void> _loadFriendsRecentWalks() async {
    try {
      // Mock data for now - in real implementation, this would come from social service
      if (!_isDisposed && mounted) {
        setState(
          () => _friendsRecentWalks = [
            'Sarah completed: Street Art Adventure',
            'Mike completed: Gallery District Walk',
          ],
        );
      }
    } catch (e) {
      // debugPrint('Error loading friends recent walks: $e');
    }
  }

  Future<void> _loadDailyChallenge() async {
    try {
      // Mock data for now - in real implementation, this would come from challenge service
      if (!_isDisposed && mounted) {
        setState(() {
          _dailyChallenge = 'Discover 3 new captures today for bonus XP';
          _dailyChallengeProgress = 1; // User has completed 1 out of 3
        });
      }
    } catch (e) {
      // debugPrint('Error loading daily challenge: $e');
    }
  }

  Future<void> _loadTrendingCaptures() async {
    try {
      // Note: Trending captures functionality ready for future implementation
      // Could be used for a trending section or featured content
      if (!_isDisposed && mounted) {
        // Placeholder for future trending captures feature
      }
    } catch (e) {
      // debugPrint('Error loading trending captures: $e');
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

    // Animate camera to new position
    if (_mapController != null && mounted) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(latitude, longitude), zoom: 13),
        ),
      );
    }
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
                if (ImageUrlValidator.isValidImageUrl(capture.imageUrl))
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
                      color: DashboardColors.primaryTeal,
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
                        color: DashboardColors.primaryTeal,
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
                              color: DashboardColors.accentOrange.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: DashboardColors.accentOrange.withValues(
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
                                    color: DashboardColors.textPrimary,
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
                const SizedBox(height: 24),

                // Artist Monetization CTAs
                if (capture.artistName?.isNotEmpty == true) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DashboardColors.primaryTeal.withValues(alpha: 0.1),
                          DashboardColors.accentOrange.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: DashboardColors.primaryTeal.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: DashboardColors.primaryTeal.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: DashboardColors.primaryTeal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Support ${capture.artistName}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: DashboardColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(
                                      context,
                                      '/artist/profile',
                                      arguments: {
                                        'artistName': capture.artistName,
                                      },
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DashboardColors.primaryTeal
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: DashboardColors.primaryTeal
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person,
                                          color: DashboardColors.primaryTeal,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'View Profile',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: DashboardColors.primaryTeal,
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
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showArtistSupportDialog(
                                      capture.artistName!,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DashboardColors.accentOrange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.card_giftcard,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Send Tip',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
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
                        const SizedBox(height: 12),
                        // Artist's other works or events
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event,
                                color: DashboardColors.primaryTeal,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'See more works by ${capture.artistName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: DashboardColors.textSecondary,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: DashboardColors.primaryTeal,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Ad Space - Bottom of Capture Detail
                const AdSpaceWidget(
                  location: AdLocation.artWalkDashboard,
                  customLabel: 'Art Inspiration & Tools',
                  height: 90,
                  trackAnalytics: true,
                ),
                const SizedBox(height: 16),
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
                      color: DashboardColors.primaryTeal,
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
                              color: DashboardColors.headingDarkPurple,
                            ),
                          ),
                          Text(
                            'Connect with artists and explore their work',
                            style: TextStyle(
                              fontSize: 14,
                              color: DashboardColors.textSecondary,
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
                      color: DashboardColors.primaryTeal,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artist-search');
                      },
                    ),
                    _buildDiscoveryTile(
                      icon: Icons.trending_up,
                      title: 'Trending',
                      subtitle: 'Popular artists and trending art',
                      color: DashboardColors.accentOrange,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/trending');
                      },
                    ),
                    _buildDiscoveryTile(
                      icon: Icons.palette,
                      title: 'Browse Artwork',
                      subtitle: 'Explore art collections and galleries',
                      color: DashboardColors.primaryTealLight,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artwork/browse');
                      },
                    ),
                    _buildDiscoveryTile(
                      icon: Icons.location_on,
                      title: 'Local Scene',
                      subtitle: 'Art events and spaces near you',
                      color: DashboardColors.primaryTealDark,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/local');
                      },
                    ),
                    _buildDiscoveryTile(
                      icon: Icons.account_circle,
                      title: 'My Profile',
                      subtitle: 'View and edit your profile',
                      color: DashboardColors.textSecondary,
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
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: DashboardColors.textSecondary,
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
    return Scaffold(
      key: _scaffoldKey,
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
      drawer: const ArtWalkDrawer(),
      body: Stack(
        children: [
          Container(
            decoration: _buildBackgroundDecoration(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Hero Welcome Section
                  _buildHeroWelcomeSection(),
                  const SizedBox(height: 24),

                  // Quick Actions Dashboard
                  _buildQuickActionsDashboard(),
                  const SizedBox(height: 24),

                  // Local Art Captures (Prominent position)
                  _buildEnhancedCapturesWidget(),
                  const SizedBox(height: 24),

                  // Ad Space - Below Captures
                  const AdSpaceWidget(
                    location: AdLocation.artWalkDashboard,
                    customLabel: 'Discover Art Tools',
                    height: 80,
                    trackAnalytics: true,
                  ),
                  const SizedBox(height: 24),

                  // Interactive Map & Location
                  _buildInteractiveMapSection(),
                  const SizedBox(height: 24),

                  // Art Discovery Overview
                  _buildArtDiscoveryOverview(),
                  const SizedBox(height: 24),

                  // Sponsored Experiences Carousel
                  _buildSponsoredExperiencesCarousel(),
                  const SizedBox(height: 24),

                  // Ad Space - Below Local Art Captures
                  const AdSpaceWidget(
                    location: AdLocation.artWalkDashboard,
                    customLabel: 'Art Supplies & Events',
                    height: 100,
                    trackAnalytics: true,
                  ),
                  const SizedBox(height: 24),

                  // Art Walks & Achievements Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildModernArtWalksWidget()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildModernAchievementsWidget()),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MODERN DESIGN METHODS ====================

  BoxDecoration _buildBackgroundDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          DashboardColors.primaryTealLight,
          DashboardColors.accentOrangeLight,
          DashboardColors.backgroundGradientStart,
          DashboardColors.backgroundGradientEnd,
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }

  BoxDecoration _buildGlassDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      boxShadow: [
        BoxShadow(
          color: DashboardColors.primaryTeal.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _buildHeroWelcomeSection() {
    final userName =
        _currentUser?.fullName ??
        _currentUser?.email.split('@').first ??
        'Traveler';
    final timeOfDay = DateTime.now().hour;
    final String greeting = timeOfDay < 12
        ? 'Good Morning'
        : timeOfDay < 17
        ? 'Good Afternoon'
        : 'Good Evening';

    return Container(
      decoration: _buildGlassDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DashboardColors.accentOrange.withValues(alpha: 0.3),
                      DashboardColors.primaryTeal.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.palette, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $userName!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: DashboardColors.headingDarkPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Where will art take you today?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Location Search with modern design
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: ZipCodeSearchBox(
              initialValue: _currentUser?.zipCode ?? '',
              onZipCodeSubmitted: (zipCode) async {
                try {
                  final coordinates =
                      await LocationUtils.getCoordinatesFromZipCode(zipCode);
                  if (coordinates != null && mounted) {
                    _updateMapPosition(
                      coordinates.latitude,
                      coordinates.longitude,
                    );
                    await _loadLocalCaptures();
                    if (_currentUser != null) {
                      setState(
                        () => _currentUser = _currentUser!.copyWith(
                          zipCode: zipCode,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not find location for this ZIP code',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error searching ZIP code: $e'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              onNavigateToMap: () {
                Navigator.pushNamed(context, '/art-walk/map');
              },
              isLoading: false,
            ),
          ),
          const SizedBox(height: 20),

          // Streak Counter and Featured Walk Row
          Row(
            children: [
              // Streak Counter
              if (_currentStreak > 0) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: DashboardColors.accentOrange.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_currentStreak Day Streak',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Keep it up!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Featured Walk
              if (_featuredWalkTitle != null) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: DashboardColors.primaryTeal.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Featured Walk',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                _featuredWalkTitle!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsDashboard() {
    return Container(
      decoration: _buildGlassDecoration(),
      padding: const EdgeInsets.all(24),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
        children: [
          _buildQuickActionCard(
            'Start Art Walk',
            Icons.directions_walk_rounded,
            DashboardColors.accentOrange,
            () => Navigator.pushNamed(context, '/art-walk/create'),
          ),
          _buildQuickActionCard(
            'Discover Art',
            Icons.explore_rounded,
            DashboardColors.primaryTeal,
            () => Navigator.pushNamed(context, '/capture/public'),
          ),
          _buildSponsoredQuickActionCard(
            'Sponsored Walk',
            Icons.local_cafe_rounded,
            const Color(0xFF8E24AA), // Purple for sponsored content
            () => _showSponsoredWalkDialog(),
            'Coffee Shop Tour',
          ),
          _buildQuickActionCard(
            'Achievements',
            Icons.emoji_events_rounded,
            DashboardColors.accentOrangeLight,
            () => Navigator.pushNamed(context, '/achievements'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSponsoredQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    String sponsorText,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, size: 16, color: Colors.white),
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    sponsorText,
                    style: TextStyle(
                      fontSize: 6,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSponsoredWalkDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sponsor logo/icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E24AA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_cafe,
                    size: 32,
                    color: Color(0xFF8E24AA),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Coffee Shop Art Tour',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sponsored by Local Brew Co.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Discover amazing street art while exploring the best coffee shops in town. Complete this walk and get 10% off your next coffee!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Maybe Later',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/art-walk/create',
                            arguments: {'sponsoredWalk': 'coffee-shop-tour'},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E24AA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Start Walk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtDiscoveryOverview() {
    return Container(
      decoration: _buildGlassDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Your Art Journey',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.headingDarkPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Local Art',
                  _localCaptures.length.toString(),
                  Icons.location_on_rounded,
                  DashboardColors.primaryTeal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Achievements',
                  _artWalkAchievements.length.toString(),
                  Icons.emoji_events_rounded,
                  DashboardColors.accentOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Social Proof Section
          if (_activeWalkersNearby > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DashboardColors.primaryTeal.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$_activeWalkersNearby people are exploring art nearby right now',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Daily Challenge Section
          if (_dailyChallenge != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: DashboardColors.accentOrange.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.flag,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Daily Challenge',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '$_dailyChallengeProgress/$_dailyChallengeTarget',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _dailyChallenge!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor:
                          _dailyChallengeProgress / _dailyChallengeTarget,
                      child: Container(
                        decoration: BoxDecoration(
                          color: DashboardColors.accentOrange,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Friends Recent Walks
          if (_friendsRecentWalks.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: DashboardColors.primaryTealLight.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.group,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Friends Activity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...(_friendsRecentWalks
                      .take(2)
                      .map(
                        (walk) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            walk,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMapSection() {
    return Container(
      decoration: _buildGlassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Local Art Map',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.headingDarkPurple,
                    ),
                  ),
                ),
                _buildModernButton(
                  'Explore',
                  Icons.fullscreen_rounded,
                  () => Navigator.pushNamed(context, '/art-walk/map'),
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _currentPosition != null
                  ? (kIsWeb
                        ? _buildWebMapFallback()
                        : GoogleMap(
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
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                          ))
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
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

  Widget _buildEnhancedCapturesWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DashboardColors.primaryTeal.withValues(alpha: 0.1),
            DashboardColors.accentOrange.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.primaryTeal.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEnhancedSectionHeader(),
            const SizedBox(height: 20),
            _buildEnhancedCapturesContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DashboardColors.accentOrange.withValues(alpha: 0.3),
                DashboardColors.primaryTeal.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Local Art Captures',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: DashboardColors.headingDarkPurple,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Discover amazing street art, murals, and sculptures found by our community',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (_localCaptures.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  DashboardColors.primaryTeal,
                  DashboardColors.accentOrange,
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/capture/public'),
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.explore, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Explore All',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEnhancedCapturesContent() {
    if (_localCaptures.isEmpty) {
      return _buildEnhancedEmptyState();
    }

    return SizedBox(
      height: 280, // Increased height for better showcase
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _localCaptures.length,
        itemBuilder: (context, index) {
          final capture = _localCaptures[index];
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 16, // Increased spacing
              right: index == _localCaptures.length - 1 ? 0 : 0,
            ),
            child: _buildEnhancedCaptureCard(capture, index),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedEmptyState() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_camera_outlined,
              color: Colors.white70,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'No captures yet',
              style: TextStyle(
                color: DashboardColors.headingDarkPurple,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Be the first to discover and share amazing local art!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    DashboardColors.primaryTeal,
                    DashboardColors.accentOrange,
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/capture/create'),
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Add Capture',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  /// Enhanced capture card with modern design and better engagement
  Widget _buildEnhancedCaptureCard(CaptureModel capture, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(
        milliseconds: 300 + (index * 100),
      ), // Staggered animation
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: SizedBox(
              width: 200, // Wider cards for better showcase
              child: Hero(
                tag: 'capture_${capture.id}',
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(20),
                  shadowColor: DashboardColors.primaryTeal.withValues(
                    alpha: 0.3,
                  ),
                  child: InkWell(
                    onTap: () => _showCaptureDetails(capture),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Colors.grey.shade50],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced image section with overlay
                          Expanded(
                            flex: 7, // More space for the image
                            child: Stack(
                              children: [
                                // Main image
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: DashboardColors
                                          .backgroundGradientStart,
                                      image:
                                          ImageUrlValidator.isValidImageUrl(
                                            capture.imageUrl,
                                          )
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                capture.imageUrl,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child:
                                        !ImageUrlValidator.isValidImageUrl(
                                          capture.imageUrl,
                                        )
                                        ? const Icon(
                                            Icons.palette,
                                            color: DashboardColors.primaryTeal,
                                            size: 48,
                                          )
                                        : null,
                                  ),
                                ),

                                // Gradient overlay for better text readability
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.7),
                                        ],
                                        stops: const [0.6, 1.0],
                                      ),
                                    ),
                                  ),
                                ),

                                // Floating engagement actions
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Column(
                                    children: [
                                      _buildFloatingActionButton(
                                        icon: Icons.favorite_border,
                                        color: DashboardColors.accentOrange,
                                        onTap: () => _handleLike(capture),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildFloatingActionButton(
                                        icon: Icons.share_outlined,
                                        color: DashboardColors.primaryTeal,
                                        onTap: () => _handleShare(capture),
                                      ),
                                    ],
                                  ),
                                ),

                                // Location badge
                                if (capture.locationName?.isNotEmpty == true)
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              capture.locationName!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Content section
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title with better typography
                                  Text(
                                    capture.title?.isNotEmpty == true
                                        ? capture.title!
                                        : 'Untitled Artwork',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: DashboardColors.textPrimary,
                                      height: 1.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 4),

                                  // Call to action
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          DashboardColors.primaryTeal,
                                          DashboardColors.accentOrange,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.explore,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'Discover',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  void _handleLike(CaptureModel capture) {
    // TODO: Implement like functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Liked ${capture.title ?? 'artwork'}!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleShare(CaptureModel capture) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared ${capture.title ?? 'artwork'}!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildModernArtWalksWidget() {
    return Container(
      decoration: _buildGlassDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Art Walks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.headingDarkPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LocalArtWalkPreviewWidget(
            zipCode: _currentUser?.zipCode ?? '10001',
            onSeeAllPressed: () =>
                Navigator.pushNamed(context, '/art-walk/list'),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAchievementsWidget() {
    return Container(
      decoration: _buildGlassDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.headingDarkPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AchievementsGrid(
            achievements: _artWalkAchievements,
            onAchievementTap: (achievement) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Achievement: ${achievement.title}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSponsoredExperiencesCarousel() {
    final sponsoredExperiences = [
      {
        'title': 'Art & Wine Evening',
        'sponsor': 'Vineyard Gallery',
        'description': 'Combine art discovery with wine tasting',
        'discount': '20% off wine flights',
        'icon': Icons.wine_bar,
        'color': const Color(0xFF7B1FA2),
      },
      {
        'title': 'Photography Workshop',
        'sponsor': 'Camera Corner',
        'description': 'Learn to capture street art like a pro',
        'discount': 'Free lens rental',
        'icon': Icons.camera_alt,
        'color': const Color(0xFF1976D2),
      },
      {
        'title': 'Artisan Market Walk',
        'sponsor': 'Local Makers Co.',
        'description': 'Meet artists and see works in progress',
        'discount': '15% off purchases',
        'icon': Icons.palette,
        'color': const Color(0xFF388E3C),
      },
    ];

    return Container(
      decoration: _buildGlassDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_offer,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sponsored Experiences',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.headingDarkPurple,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sponsoredExperiences.length,
              itemBuilder: (context, index) {
                final experience = sponsoredExperiences[index];
                return Container(
                  width: 280,
                  margin: EdgeInsets.only(
                    right: index < sponsoredExperiences.length - 1 ? 16 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (experience['color'] as Color).withValues(
                        alpha: 0.3,
                      ),
                      width: 2,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showSponsoredExperienceDialog(experience),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (experience['color'] as Color)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    experience['icon'] as IconData,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        experience['title'] as String,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'by ${experience['sponsor']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              experience['description'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: (experience['color'] as Color)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (experience['color'] as Color)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_offer,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    experience['discount'] as String,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
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
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showArtistSupportDialog(String artistName) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DashboardColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 32,
                    color: DashboardColors.primaryTeal,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Support $artistName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Show your appreciation for this artist',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildTipButton('\$2', 2.0)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTipButton('\$5', 5.0)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTipButton('\$10', 10.0)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DashboardColors.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: DashboardColors.accentOrange,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tips help artists continue creating amazing public art',
                          style: TextStyle(
                            fontSize: 12,
                            color: DashboardColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Maybe Later',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to artist profile for more support options
                          Navigator.pushNamed(
                            context,
                            '/artist/profile',
                            arguments: {'artistName': artistName},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DashboardColors.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'View Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipButton(String amount, double value) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Thank you for supporting the artist with $amount!',
              ),
              backgroundColor: DashboardColors.primaryTeal,
              duration: const Duration(seconds: 3),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: DashboardColors.accentOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DashboardColors.accentOrange.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DashboardColors.accentOrange,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _showSponsoredExperienceDialog(Map<String, dynamic> experience) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (experience['color'] as Color).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    experience['icon'] as IconData,
                    size: 32,
                    color: experience['color'] as Color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  experience['title'] as String,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sponsored by ${experience['sponsor']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  experience['description'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (experience['color'] as Color).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (experience['color'] as Color).withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_offer,
                        size: 20,
                        color: experience['color'] as Color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        experience['discount'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: experience['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Not Now',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/art-walk/create',
                            arguments: {
                              'sponsoredExperience': experience['title'],
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: experience['color'] as Color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Join Experience',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebMapFallback() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 8),
            Text(
              'Local Art Map',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Map view available on mobile',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

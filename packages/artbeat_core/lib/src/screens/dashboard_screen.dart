import "package:flutter/material.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:provider/provider.dart";
import "../services/user_service.dart";
import "../models/user_model.dart";
import "../models/artist_profile_model.dart";
import "../utils/location_utils.dart";
import "../widgets/universal_bottom_nav.dart";
import "../widgets/universal_header.dart";
import "../widgets/artbeat_drawer.dart";
import "../theme/index.dart";
import "package:artbeat_capture/artbeat_capture.dart";
import "package:artbeat_artist/artbeat_artist.dart";

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  UserModel? _currentUser;
  LatLng? _userLocation;
  Set<Marker> _markers = {};
  List<ArtistProfileModel> _featuredArtists = [];
  bool _isLoadingArtists = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _loadFeaturedArtists();
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0: // Home - Stay on dashboard
        break;
      case 1: // Art Walk
        Navigator.pushNamed(context, '/art-walk/dashboard');
        break;
      case 2: // Community
        Navigator.pushNamed(context, '/community/dashboard');
        break;
      case 3: // Events
        Navigator.pushNamed(context, '/events/dashboard');
        break;
      case 4: // Capture (Camera button) - Open as modal
        _openCaptureModal();
        break;
    }
  }

  void _openCaptureModal() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const CaptureScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _navigateToArtistOnboarding() {
    if (_currentUser != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ArtistOnboardingScreen(
            user: _currentUser!,
            onComplete: () {
              Navigator.of(context).pop();
              // Optionally refresh user data or show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Welcome to ARTbeat for Artists!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to become an artist'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Load featured artists from Firestore
  Future<void> _loadFeaturedArtists() async {
    if (mounted) {
      setState(() {
        _isLoadingArtists = true;
      });
    }

    try {
      final artistService = ArtistProfileService();
      final artists = await artistService.getFeaturedArtists(limit: 6);
      
      if (mounted) {
        setState(() {
          _featuredArtists = artists;
          _isLoadingArtists = false;
        });
      }
    } catch (e) {
      print('Error loading featured artists: $e');
      if (mounted) {
        setState(() {
          _featuredArtists = [];
          _isLoadingArtists = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    final userService = Provider.of<UserService>(context, listen: false);
    final user = await userService.getCurrentUserModel();
    
    if (user != null && user.zipCode != null && user.zipCode!.isNotEmpty) {
      debugPrint('📍 Dashboard: Using user ZIP code: ${user.zipCode}');
      final coordinates = await LocationUtils.getCoordinatesFromZipCode(
        user.zipCode!,
      );
      if (coordinates != null) {
        setState(() {
          _currentUser = user;
          _userLocation = LatLng(coordinates.latitude, coordinates.longitude);
          _createArtMarkers();
        });
        return;
      }
    }
    
    // Fall back to GPS location if no ZIP code or ZIP code failed
    try {
      final position = await LocationUtils.getCurrentPosition();
      final zipCode = await LocationUtils.getZipCodeFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      // Update user's ZIP code if we got a valid one
      if (zipCode.isNotEmpty && user != null) {
        await userService.updateUserZipCode(zipCode);
        debugPrint('📍 Dashboard: Updated user ZIP code to: $zipCode');
      }
      
      setState(() {
        _currentUser = user;
        _userLocation = LatLng(position.latitude, position.longitude);
        _createArtMarkers();
      });
    } catch (e) {
      debugPrint('❌ Dashboard: Error getting location: $e');
      setState(() {
        _currentUser = user;
        // Default to Asheville, NC if everything fails
        _userLocation = const LatLng(35.5951, -82.5515);
        _createArtMarkers();
      });
    }
  }

  void _createArtMarkers() {
    if (_userLocation == null) return;

    // Create some sample art markers around the user's location
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('art1'),
        position: LatLng(
          _userLocation!.latitude + 0.002,
          _userLocation!.longitude - 0.003,
        ),
        infoWindow: const InfoWindow(
          title: 'Rainbow Mural',
          snippet: 'by Maya Chen',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: const MarkerId('art2'),
        position: LatLng(
          _userLocation!.latitude - 0.001,
          _userLocation!.longitude + 0.002,
        ),
        infoWindow: const InfoWindow(
          title: 'Bronze Statue',
          snippet: 'by David Martinez',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('art3'),
        position: LatLng(
          _userLocation!.latitude + 0.001,
          _userLocation!.longitude + 0.001,
        ),
        infoWindow: const InfoWindow(
          title: 'Street Art',
          snippet: 'by Local Artist',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };

    setState(() {
      _markers = markers;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: UniversalHeader(
        showDeveloperTools: true, // Enable developer tools icon
        onSearchPressed: () {
          // Handle search action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Search functionality coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
      drawer: const ArtbeatDrawer(),
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArtbeatColors.primaryPurple.withAlpha(13), // 0.05 opacity
              Colors.white,
              ArtbeatColors.primaryGreen.withAlpha(13), // 0.05 opacity
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // User greeting
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(
                      230,
                    ), // Semi-transparent white
                    border: Border(
                      bottom: BorderSide(
                        color: ArtbeatColors.border.withAlpha(128),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    _currentUser != null && _currentUser!.fullName.isNotEmpty
                        ? 'Hello Art Explorer, ${_currentUser!.fullName}'
                        : 'Hello Art Explorer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ArtbeatColors.textPrimary,
                    ),
                  ),
                ),

                // XP and Level Section
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.stars,
                            color: ArtbeatColors.accentYellow,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Level ${_currentUser?.level ?? 1}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ArtbeatColors.textPrimary,
                                ),
                              ),
                              Text(
                                _getLevelTitle(_currentUser?.level ?? 1),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ArtbeatColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            '${_currentUser?.experiencePoints ?? 0} XP',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: ArtbeatColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _getLevelProgress(),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ArtbeatColors.accentYellow,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Next level: ${_getXPForNextLevel()} XP',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Achievement Progress Section
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            color: ArtbeatColors.accentYellow,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Your Art Journey Progress',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ArtbeatColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAchievementProgress(
                              'Art Captures',
                              3,
                              10,
                              Icons.camera_alt_outlined,
                              ArtbeatColors.primaryPurple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAchievementProgress(
                              'Art Walks',
                              1,
                              5,
                              Icons.directions_walk_outlined,
                              ArtbeatColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAchievementProgress(
                              'Community',
                              2,
                              8,
                              Icons.people_outline,
                              ArtbeatColors.secondaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tab bar
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
                      Tab(text: 'Explore'),
                      Tab(text: 'Artists'),
                      Tab(text: 'Artwork'),
                    ],
                  ),
                ),

                // Tab content
                Container(
                  height: 600, // Fixed height for tab content
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildExploreTab(),
                      _buildArtistsTab(),
                      _buildArtworkTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: UniversalBottomNav(
        currentIndex: 0, // Dashboard is always index 0 (Home)
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildExploreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Google Map Section
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _userLocation != null
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _userLocation!,
                        zoom: 14.0,
                      ),
                      markers: _markers,
                      myLocationEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text(
                              'Loading map...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Captured Art Near You section - Single row
          const Text(
            'Captured Art Near You',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCapturedArtCard(
                  'Rainbow Mural',
                  'Maya Chen',
                  '0.3 mi',
                  '🎨',
                ),
                _buildCapturedArtCard(
                  'Bronze Statue',
                  'David Martinez',
                  '0.5 mi',
                  '🗿',
                ),
                _buildCapturedArtCard(
                  'Street Art',
                  'Local Artist',
                  '0.8 mi',
                  '🌆',
                ),
                _buildCapturedArtCard(
                  'Garden Gate',
                  'Community',
                  '1.1 mi',
                  '🚪',
                ),
                _buildCapturedArtCard(
                  'Mosaic Wall',
                  'Jane Smith',
                  '1.3 mi',
                  '🏺',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Admin banner ad
          GestureDetector(
            onTap: () => _navigateToArtistOnboarding(),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 0),
              child: Image.asset(
                'assets/images/admin_banner_ad.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image not found
                  return Container(
                    height: 80,
                    color: Colors.grey[100],
                    child: Center(
                      child: Text(
                        'Become an Artist - Tap to Get Started!',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Artists Near You section
          const Text(
            'Artists Near You',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 140, // Adjusted to fit content better
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildArtistCard('Maya Chen', '28403', 'Muralist', 'MC'),
                _buildArtistCard('David Martinez', '28401', 'Sculptor', 'DM'),
                _buildArtistCard(
                  'Sarah Williams',
                  '28405',
                  'Photographer',
                  'SW',
                ),
                _buildArtistCard(
                  'Alex Thompson',
                  '28403',
                  'Street Artist',
                  'AT',
                ),
                _buildArtistCard('Maria Rodriguez', '28402', 'Painter', 'MR'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Artist banner ad
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 0),
            child: Image.asset(
              'assets/images/artist_banner_ad.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image not found
                return Container(
                  height: 80,
                  color: Colors.grey[100],
                  child: Center(
                    child: Text(
                      'Artist Banner Ad',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Artwork Near You section
          const Text(
            'Artwork Near You',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildArtworkCard('Urban Dreams', 'Maya Chen'),
                _buildArtworkCard('Sunset Memories', 'David Martinez'),
                _buildArtworkCard('City Lights', 'Sarah Williams'),
                _buildArtworkCard('Abstract Flow', 'Alex Thompson'),
                _buildArtworkCard('Nature\'s Call', 'Maria Rodriguez'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedArtCard(
    String title,
    String artist,
    String distance,
    String emoji,
  ) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
          ),
          // Art details
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'by $artist',
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  distance,
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCard(
    String name,
    String zipCode,
    String medium,
    String initials,
  ) {
    return Container(
      width: 120,
      height: 130, // Add explicit height constraint
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8), // Reduced padding from 12 to 8
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Use minimum space needed
          children: [
            // Avatar - smaller size
            CircleAvatar(
              radius: 20, // Further reduced from 25 to 20
              backgroundColor: const Color(0xFF6366F1),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // Reduced from 16 to 14
                ),
              ),
            ),
            const SizedBox(height: 6), // Reduced from 8 to 6
            // Name
            Flexible(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12, // Reduced from 13 to 12
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2), // Reduced from 4 to 2
            // Zip code
            Flexible(
              child: Text(
                zipCode,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10, // Reduced from 11 to 10
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2), // Reduced from 4 to 2
            // Medium
            Flexible(
              child: Text(
                medium,
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 10, // Reduced from 11 to 10
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtworkCard(String title, String artist) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background image placeholder
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[300]!,
                    Colors.purple[300]!,
                    Colors.pink[300]!,
                  ],
                ),
              ),
            ),
            // Fade overlay with text
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by $artist',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildAchievementProgress(
    String title,
    int current,
    int total,
    IconData icon,
    Color color,
  ) {
    double progress = current / total;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ArtbeatColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: ArtbeatColors.backgroundSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 4),
          Text(
            '$current/$total',
            style: TextStyle(fontSize: 10, color: ArtbeatColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsTab() {
    if (_isLoadingArtists) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading artists...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_featuredArtists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.palette_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Artists Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for featured artists in your area',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.stars,
                color: ArtbeatColors.accentYellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Featured Artists',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _featuredArtists.length,
            itemBuilder: (context, index) {
              final artist = _featuredArtists[index];
              return _buildRealArtistCard(artist);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRealArtistCard(ArtistProfileModel artist) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to artist public profile
          Navigator.pushNamed(
            context,
            '/artist/public-profile',
            arguments: artist.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artist profile image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: artist.profileImageUrl != null && artist.profileImageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          artist.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildArtistAvatar(artist);
                          },
                        ),
                      )
                    : _buildArtistAvatar(artist),
              ),
            ),
            // Artist details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Artist name with verification badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            artist.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (artist.isVerified)
                          Icon(
                            Icons.verified,
                            color: ArtbeatColors.primaryPurple,
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Location
                    if (artist.location != null && artist.location!.isNotEmpty)
                      Text(
                        artist.location!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    // Mediums
                    if (artist.mediums.isNotEmpty)
                      Text(
                        artist.mediums.take(2).join(', '),
                        style: TextStyle(
                          fontSize: 11,
                          color: ArtbeatColors.primaryPurple,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    // Featured badge
                    if (artist.isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ArtbeatColors.accentYellow.withAlpha(51),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: ArtbeatColors.accentYellow.withAlpha(128),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Featured',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: ArtbeatColors.accentYellow.withAlpha(200),
                          ),
                        ),
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

  Widget _buildArtistAvatar(ArtistProfileModel artist) {
    final initials = artist.displayName.isNotEmpty
        ? artist.displayName.split(' ').map((name) => name[0]).take(2).join()
        : 'A';
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: ArtbeatColors.primaryPurple.withAlpha(51),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: Center(
        child: CircleAvatar(
          radius: 30,
          backgroundColor: ArtbeatColors.primaryPurple,
          child: Text(
            initials.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtworkTab() {
    return const Center(
      child: Text(
        'Artwork Tab',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Get level progress (0.0 to 1.0)
  double _getLevelProgress() {
    if (_currentUser == null) return 0.0;

    final currentXP = _currentUser!.experiencePoints;
    final currentLevel = _currentUser!.level;

    // Use new level system from RewardsService
    const levelSystem = {
      1: {'minXP': 0, 'maxXP': 199},
      2: {'minXP': 200, 'maxXP': 499},
      3: {'minXP': 500, 'maxXP': 999},
      4: {'minXP': 1000, 'maxXP': 1499},
      5: {'minXP': 1500, 'maxXP': 2499},
      6: {'minXP': 2500, 'maxXP': 3999},
      7: {'minXP': 4000, 'maxXP': 5999},
      8: {'minXP': 6000, 'maxXP': 7999},
      9: {'minXP': 8000, 'maxXP': 9999},
      10: {'minXP': 10000, 'maxXP': 999999},
    };

    if (currentLevel >= 10) return 1.0; // Max level

    final levelData = levelSystem[currentLevel];
    if (levelData == null) return 0.0;

    final minXP = levelData['minXP']!;
    final maxXP = levelData['maxXP']!;

    final progressXP = currentXP - minXP;
    final requiredXP = maxXP - minXP + 1;

    return (progressXP / requiredXP).clamp(0.0, 1.0);
  }

  /// Get XP required for next level
  int _getXPForNextLevel() {
    if (_currentUser == null) return 200;

    final currentLevel = _currentUser!.level;
    final currentXP = _currentUser!.experiencePoints;

    // Use new level system from RewardsService
    const levelSystem = {
      1: {'minXP': 0, 'maxXP': 199},
      2: {'minXP': 200, 'maxXP': 499},
      3: {'minXP': 500, 'maxXP': 999},
      4: {'minXP': 1000, 'maxXP': 1499},
      5: {'minXP': 1500, 'maxXP': 2499},
      6: {'minXP': 2500, 'maxXP': 3999},
      7: {'minXP': 4000, 'maxXP': 5999},
      8: {'minXP': 6000, 'maxXP': 7999},
      9: {'minXP': 8000, 'maxXP': 9999},
      10: {'minXP': 10000, 'maxXP': 999999},
    };

    if (currentLevel >= 10) return 0; // Max level

    final nextLevelData = levelSystem[currentLevel + 1];
    if (nextLevelData == null) return 0;

    return nextLevelData['minXP']! - currentXP;
  }

  /// Get level title
  String _getLevelTitle(int level) {
    const levelTitles = {
      1: 'Sketcher (Frida Kahlo)',
      2: 'Color Blender (Jacob Lawrence)',
      3: 'Brush Trailblazer (Yayoi Kusama)',
      4: 'Street Master (Jean-Michel Basquiat)',
      5: 'Mural Maven (Faith Ringgold)',
      6: 'Avant-Garde Explorer (Zarina Hashmi)',
      7: 'Visionary Creator (El Anatsui)',
      8: 'Art Legend (Leonardo da Vinci)',
      9: 'Cultural Curator (Shirin Neshat)',
      10: 'Art Walk Influencer',
    };

    return levelTitles[level] ?? 'Unknown Level';
  }
}

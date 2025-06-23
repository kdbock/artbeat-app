import "package:flutter/material.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:provider/provider.dart";
import "../services/user_service.dart";
import "../models/user_model.dart";
import "../utils/location_utils.dart";
import "../widgets/universal_bottom_nav.dart";
import "../widgets/universal_header.dart";
import "../widgets/artbeat_drawer.dart";
import "../theme/index.dart";
import "package:artbeat_capture/artbeat_capture.dart";

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
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

  Future<void> _loadUserData() async {
    final userService = Provider.of<UserService>(context, listen: false);
    final user = await userService.getCurrentUserModel();
    if (user != null && user.zipCode != null) {
      final coordinates = await LocationUtils.getCoordinatesFromZipCode(
        user.zipCode!,
      );
      if (coordinates != null) {
        setState(() {
          _currentUser = user;
          _userLocation = LatLng(coordinates.latitude, coordinates.longitude);
          _createArtMarkers();
        });
      }
    } else {
      setState(() {
        _currentUser = user;
        // Default to Asheville, NC if no zip code
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
          child: Column(
            children: [
              // User greeting
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230), // Semi-transparent white
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
              Expanded(
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
          Container(
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
                      'Admin Banner Ad',
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
            height: 150, // Reduced from 160 to 150
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
          mainAxisAlignment: MainAxisAlignment.center, // Center the content
          children: [
            // Avatar - smaller size
            CircleAvatar(
              radius: 25, // Reduced from 30 to 25
              backgroundColor: const Color(0xFF6366F1),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16, // Reduced from 18 to 16
                ),
              ),
            ),
            const SizedBox(height: 8), // Reduced from 12 to 8
            // Name
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13, // Reduced from 14 to 13
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2), // Reduced from 4 to 2
            // Zip code
            Text(
              zipCode,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11, // Reduced from 12 to 11
              ),
            ),
            const SizedBox(height: 2), // Reduced from 4 to 2
            // Medium
            Text(
              medium,
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 11, // Reduced from 12 to 11
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    return const Center(
      child: Text(
        'Artists Tab',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
}

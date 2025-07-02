import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../models/artist_profile_model.dart';

import '../widgets/universal_header.dart';
import '../widgets/artbeat_drawer.dart';
import '../widgets/main_layout.dart';
import '../widgets/achievement_runner.dart';
import '../widgets/achievement_badge.dart';
import '../theme/index.dart';

import 'package:artbeat_events/artbeat_events.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  UserModel? _currentUser;
  LatLng? _userLocation;
  Set<Marker> _markers = {};
  late TabController _tabController;

  List<ArtistProfileModel> _nearbyArtists = [];
  bool _isLoadingNearbyArtists = false;

  List<ArtworkModel> _nearbyArtworks = [];
  bool _isLoadingNearbyArtworks = false;

  List<CaptureModel> _nearbyCaptures = [];
  bool _isLoadingCaptures = false;

  List<ArtbeatEvent> _upcomingEvents = [];
  bool _isLoadingEvents = false;

  bool _mapsInitialized = false;

  // Achievement dropdown state
  bool _isAchievementsExpanded = false;

  // Services
  final CaptureService _captureService = CaptureService();
  final ArtworkService _artworkService = ArtworkService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _initializeMaps();
    _loadUserData();
    _loadNearbyArtists();
    _loadNearbyArtworks();
    _loadNearbyCaptures();
    _loadUpcomingEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Initialize Google Maps service
  Future<void> _initializeMaps() async {
    try {
      // Initialize Google Maps service for iOS compatibility
      await art_walk.GoogleMapsService().initializeMaps();

      setState(() {
        _mapsInitialized = true;
      });

      // Get user location after maps are initialized
      await _getUserLocation();
    } catch (e) {
      // Still try to get location even if maps fail
      await _getUserLocation();
    }
  }

  /// Get user location and set up markers
  Future<void> _getUserLocation() async {
    try {
      // Try to get actual user location first
      final position = await art_walk.LocationUtils.getCurrentPosition();
      final userLocation = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _userLocation = userLocation;
          _updateMapMarkers();
        });
      }

      // Location set successfully for map display
    } catch (e) {
      // Fallback to default location (Asheville, NC)
      const defaultLocation = LatLng(35.5951, -82.5515);

      if (mounted) {
        setState(() {
          _userLocation = defaultLocation;
          _updateMapMarkers();
        });
      }

      // Default location set for map display
    }
  }

  /// Update markers on the map with user location and captured art
  void _updateMapMarkers() {
    if (_userLocation == null) return;

    final Set<Marker> markers = {
      // User location marker
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userLocation!,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };

    // Add captured art markers
    for (int i = 0; i < _nearbyCaptures.length; i++) {
      final capture = _nearbyCaptures[i];
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
          ),
        );
      }
    }

    _markers = markers;
  }

  void _navigateToArtistOnboarding() {
    Navigator.pushNamed(context, '/artist/onboarding', arguments: _currentUser);
  }

  Future<void> _loadUserData() async {
    final userService = Provider.of<UserService>(context, listen: false);
    final user = await userService.getCurrentUserModel();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
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
          _updateMapMarkers(); // Update map markers with captured art
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCaptures = false;
        });
      }
    }
  }

  Future<void> _loadUpcomingEvents() async {
    setState(() {
      _isLoadingEvents = true;
    });

    try {
      final eventService = EventService();
      final events = await eventService.getUpcomingPublicEvents(limit: 10);

      if (mounted) {
        setState(() {
          _upcomingEvents = events;
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEvents = false;
        });
      }
    }
  }

  /// Load all artists
  Future<void> _loadNearbyArtists() async {
    setState(() {
      _isLoadingNearbyArtists = true;
    });

    try {
      // Get all artists - no location filtering
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .where('userType', isEqualTo: 'artist')
          .get();

      final List<ArtistProfileModel> allArtists = [];

      for (var doc in snapshot.docs) {
        if (!doc.exists) continue;

        try {
          final profile = ArtistProfileModel.fromFirestore(doc);
          allArtists.add(profile);
        } catch (e) {}
      }

      // Sort by most recently updated
      allArtists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (mounted) {
        setState(() {
          _nearbyArtists = allArtists; // Show all artists
          _isLoadingNearbyArtists = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingNearbyArtists = false;
        });
      }
    }
  }

  /// Load all artworks (no filter on isPublic)
  Future<void> _loadNearbyArtworks() async {
    setState(() {
      _isLoadingNearbyArtworks = true;
    });

    try {
      // Use ArtworkService to get all artwork (no filter)
      final artworks = await _artworkService.getAllArtwork(limit: 50);

      // Replace print with debugPrint for logging
      debugPrint('Dashboard: Successfully loaded ${artworks.length} artworks');

      if (mounted) {
        setState(() {
          _nearbyArtworks = artworks;
          _isLoadingNearbyArtworks = false;
        });
      }
    } catch (e) {
      // Replace print with debugPrint for logging
      debugPrint('Dashboard: Error loading artworks: $e');
      if (mounted) {
        setState(() {
          _isLoadingNearbyArtworks = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0,
      child: Scaffold(
        appBar: UniversalHeader(
          title: 'ARTbeat',
          showDeveloperTools: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: Implement search
              },
            ),
          ],
        ),
        drawer: const ArtbeatDrawer(),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Welcome section with user stats
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ArtbeatColors.primaryPurple.withAlpha(25),
                        ArtbeatColors.primaryGreen.withAlpha(25),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser != null
                            ? 'Welcome back, ${_currentUser!.fullName.split(' ').first}!'
                            : 'Welcome to ARTbeat!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_currentUser != null) ...[
                        // Enhanced Achievement Runner
                        AchievementRunner(
                          progress: _getLevelProgress(),
                          currentLevel: _currentUser!.level,
                          experiencePoints: _currentUser!.experiencePoints,
                          levelTitle: _getLevelTitle(_currentUser!.level),
                          showAnimations: true,
                          height: 24.0, // Made thinner
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                        ),
                      ] else ...[
                        const Text(
                          'Discover local art, connect with artists, and join the creative community.',
                          style: TextStyle(
                            fontSize: 16,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Achievements Section - Now a dropdown
                if (_currentUser != null) _buildAchievementsDropdown(),

                // Tab Bar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: ArtbeatColors.primaryPurple,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: ArtbeatColors.primaryPurple,
                    tabs: const [
                      Tab(text: 'Explore'),
                      Tab(text: 'Artists'),
                      Tab(text: 'Artwork'),
                    ],
                  ),
                ),

                // Tab Content - Now fully scrollable with minimum height
                SizedBox(
                  height: 600, // Provide minimum height for tab content
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
    );
  }

  Widget _buildExploreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Google Map Section with Art Markers
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/art-walk/dashboard');
            },
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _mapsInitialized && _userLocation != null
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _userLocation!,
                          zoom: 14,
                        ),
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: false,
                        onMapCreated: (controller) {},
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Captured Art section - REAL DATA
          const Text(
            'Captured Art',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 180,
            child: _isLoadingCaptures
                ? const Center(child: CircularProgressIndicator())
                : _nearbyCaptures.isEmpty
                ? const Center(child: Text('No captures found.'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _nearbyCaptures.length,
                    itemBuilder: (context, index) {
                      return _buildCapturedArtCard(_nearbyCaptures[index]);
                    },
                  ),
          ),

          const SizedBox(height: 24),

          // Artists section - ALL ARTISTS
          const Text(
            'Featured Artists',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 145,
            child: Builder(
              builder: (context) {
                if (_isLoadingNearbyArtists) {
                  return const Center(child: CircularProgressIndicator());
                } else if (_nearbyArtists.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No artists found nearby',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Check back later for artists in your area',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _nearbyArtists.length,
                    itemBuilder: (context, index) {
                      final artist = _nearbyArtists[index];
                      return _buildArtistCard(artist);
                    },
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 24),

          // Upcoming Events section
          const Text(
            'Upcoming Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 180,
            child: _isLoadingEvents
                ? const Center(child: CircularProgressIndicator())
                : _upcomingEvents.isEmpty
                ? Container(
                    height: 120,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ArtbeatColors.accentYellow.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ArtbeatColors.accentYellow.withAlpha(77),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: 32,
                            color: ArtbeatColors.accentYellow.withAlpha(204),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No Upcoming Events',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Check back later for events in your area',
                            style: TextStyle(
                              fontSize: 14,
                              color: ArtbeatColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _upcomingEvents.length,
                    itemBuilder: (context, index) {
                      final event = _upcomingEvents[index];
                      return _buildEventCard(event);
                    },
                  ),
          ),

          const SizedBox(height: 24),

          // Call to action
          GestureDetector(
            onTap: _navigateToArtistOnboarding,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ArtbeatColors.primaryPurple.withAlpha(25),
                    ArtbeatColors.primaryGreen.withAlpha(25),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ArtbeatColors.primaryPurple.withAlpha(77),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.palette,
                    size: 48,
                    color: ArtbeatColors.primaryPurple,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Become an Artist',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ArtbeatColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Join our community of artists and showcase your creativity',
                    style: TextStyle(
                      fontSize: 14,
                      color: ArtbeatColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Artists',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          _isLoadingNearbyArtists
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _nearbyArtists.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Artists Found Nearby',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for artists in your area',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _nearbyArtists.length,
                  itemBuilder: (context, index) {
                    final artist = _nearbyArtists[index];
                    return _buildArtistGridCard(artist);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildArtworkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Artwork',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          _isLoadingNearbyArtworks
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _nearbyArtworks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Artwork Found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Artists haven\'t uploaded artwork yet',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _nearbyArtworks.length,
                  itemBuilder: (context, index) {
                    final artwork = _nearbyArtworks[index];
                    return _buildArtworkCard(artwork);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildArtistCard(ArtistProfileModel artist) {
    return SizedBox(
      width: 120,
      height: 160, // Fixed height to prevent overflow and ensure tap area
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/artist/profile',
              arguments: artist.userId,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: ArtbeatColors.primaryPurple.withAlpha(25),
                  backgroundImage:
                      artist.profileImageUrl != null &&
                          artist.profileImageUrl!.isNotEmpty
                      ? NetworkImage(artist.profileImageUrl!)
                      : null,
                  child:
                      (artist.profileImageUrl == null ||
                          artist.profileImageUrl!.isEmpty)
                      ? const Icon(
                          Icons.person,
                          color: ArtbeatColors.primaryPurple,
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  artist.displayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  artist.bio ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 9),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistGridCard(ArtistProfileModel artist) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/artist/profile',
            arguments: artist.userId,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Artist avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: ArtbeatColors.primaryPurple.withAlpha(25),
                backgroundImage:
                    artist.profileImageUrl != null &&
                        artist.profileImageUrl!.isNotEmpty
                    ? NetworkImage(artist.profileImageUrl!)
                    : null,
                child:
                    (artist.profileImageUrl == null ||
                        artist.profileImageUrl!.isEmpty)
                    ? const Icon(
                        Icons.person,
                        color: ArtbeatColors.primaryPurple,
                        size: 40,
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              // Artist name
              Text(
                artist.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Artist bio/medium
              Expanded(
                child: Text(
                  artist.bio ??
                      (artist.mediums.isNotEmpty
                          ? artist.mediums.first
                          : 'Artist'),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              // Follow button
              SizedBox(
                width: double.infinity,
                height: 28,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/artist/profile',
                      arguments: artist.userId,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArtbeatColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('View Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtworkCard(ArtworkModel artwork) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/artwork/details',
            arguments: artwork.id,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork image
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
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: artwork.imageUrl.isNotEmpty
                      ? Image.network(
                          artwork.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey,
                              ),
                        )
                      : const Icon(Icons.image, size: 48, color: Colors.grey),
                ),
              ),
            ),
            // Artwork info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.title.isNotEmpty ? artwork.title : 'Untitled',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artwork.userId, // Use userId from the new ArtworkModel
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (artwork.price != null)
                      Text(
                        '\$${artwork.price!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    if (artwork.isSold)
                      const Text(
                        'SOLD',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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

  Widget _buildCapturedArtCard(CaptureModel capture) {
    return SizedBox(
      width: 150,
      height: 180, // Fixed height to prevent overflow
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) {
                return Padding(
                  padding: MediaQuery.of(context).viewInsets,
                  child: Wrap(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: capture.imageUrl.isNotEmpty
                                    ? Image.network(
                                        capture.imageUrl,
                                        height: 180,
                                        width: 180,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 180,
                                        width: 180,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              capture.title ??
                                  capture.artistName ??
                                  'Captured Art',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            if (capture.locationName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  capture.locationName!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: ArtbeatColors.primaryGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  capture.artType ?? 'Public Art',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: ArtbeatColors.primaryGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add_location_alt),
                                label: const Text('Add to Art Walk'),
                                onPressed: () {
                                  Navigator.pop(context); // Close the modal
                                  Navigator.pushNamed(
                                    context,
                                    '/art-walk/create',
                                    arguments: {'capture': capture},
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ArtbeatColors.primaryPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  textStyle: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Captured art image
              SizedBox(
                height: 100,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: capture.imageUrl.isNotEmpty
                      ? Image.network(
                          capture.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      capture.title ?? capture.artistName ?? 'Captured Art',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (capture.locationName != null)
                      Text(
                        capture.locationName!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Row(
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          size: 12,
                          color: ArtbeatColors.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            capture.artType ?? 'Public Art',
                            style: const TextStyle(
                              fontSize: 10,
                              color: ArtbeatColors.primaryGreen,
                              fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildEventCard(ArtbeatEvent event) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to event details
          Navigator.pushNamed(context, '/events/details', arguments: event.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event banner image
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
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: event.eventBannerUrl.isNotEmpty
                      ? Image.network(
                          event.eventBannerUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.event,
                                size: 40,
                                color: ArtbeatColors.accentYellow.withAlpha(
                                  204,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.event,
                            size: 40,
                            color: ArtbeatColors.accentYellow.withAlpha(204),
                          ),
                        ),
                ),
              ),
            ),
            // Event info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Flexible(
                      child: Text(
                        event.location,
                        style: TextStyle(color: Colors.grey[600], fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 10,
                          color: ArtbeatColors.accentYellow.withAlpha(204),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${event.dateTime.month}/${event.dateTime.day}',
                            style: TextStyle(
                              fontSize: 9,
                              color: ArtbeatColors.accentYellow.withAlpha(204),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (event.hasFreeTickets)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: ArtbeatColors.primaryGreen,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'FREE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                              ),
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

  /// Get level progress (0.0 to 1.0)
  double _getLevelProgress() {
    if (_currentUser == null) return 0.0;

    final currentXP = _currentUser!.experiencePoints;
    final currentLevel = _currentUser!.level;

    // XP needed for next level: level * 100
    final xpForCurrentLevel = currentLevel * 100;
    final xpForNextLevel = (currentLevel + 1) * 100;
    final xpInCurrentLevel = currentXP - xpForCurrentLevel;
    final xpNeededForLevel = xpForNextLevel - xpForCurrentLevel;

    if (xpNeededForLevel <= 0) return 1.0;

    return (xpInCurrentLevel / xpNeededForLevel).clamp(0.0, 1.0);
  }

  /// Get user level title
  String _getLevelTitle(int level) {
    final Map<int, String> levelTitles = {
      0: 'Art Explorer',
      1: 'Art Enthusiast',
      2: 'Art Collector',
      3: 'Art Connoisseur',
      4: 'Art Advocate',
      5: 'Art Ambassador',
      6: 'Art Curator',
      7: 'Art Patron',
      8: 'Art Master',
      9: 'Art Legend',
      10: 'Art Icon',
    };

    return levelTitles[level] ?? 'Unknown Level';
  }

  /// Build achievements dropdown section
  Widget _buildAchievementsDropdown() {
    final achievements = _getSampleAchievements();
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with dropdown toggle
          InkWell(
            onTap: () {
              setState(() {
                _isAchievementsExpanded = !_isAchievementsExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: ArtbeatColors.primaryPurple,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Achievements',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ArtbeatColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$unlockedCount/${achievements.length} unlocked',
                          style: const TextStyle(
                            fontSize: 14,
                            color: ArtbeatColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isAchievementsExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_more,
                      color: ArtbeatColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isAchievementsExpanded ? 170 : 0,
            child: _isAchievementsExpanded
                ? Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: achievements.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.emoji_events_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No achievements yet',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.all(16),
                            itemCount: achievements.length,
                            itemBuilder: (context, index) {
                              final achievement = achievements[index];
                              return AchievementBadge(
                                title: achievement.title,
                                description: achievement.description,
                                icon: achievement.icon,
                                isUnlocked: achievement.isUnlocked,
                                progress: achievement.progress,
                                customColor: achievement.customColor,
                                showProgress: achievement.showProgress,
                                progressText: achievement.progressText,
                                onTap: achievement.onTap,
                              );
                            },
                          ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  /// Get sample achievements based on user data and activities
  List<AchievementBadgeData> _getSampleAchievements() {
    final userLevel = _currentUser?.level ?? 0;
    final userXP = _currentUser?.experiencePoints ?? 0;
    final capturesCount = _nearbyCaptures.length;
    final artistsDiscovered = _nearbyArtists.length;

    return [
      AchievementBadgeData(
        title: 'First Steps',
        description: 'Create your first account',
        icon: Icons.person_add,
        isUnlocked: _currentUser != null,
        customColor: ArtbeatColors.primaryGreen,
      ),
      AchievementBadgeData(
        title: 'Art Hunter',
        description: 'Capture 5 artworks',
        icon: Icons.camera_alt,
        isUnlocked: capturesCount >= 5,
        progress: (capturesCount / 5).clamp(0.0, 1.0),
        showProgress: capturesCount < 5,
        progressText: '$capturesCount/5',
        customColor: ArtbeatColors.secondaryTeal,
      ),
      AchievementBadgeData(
        title: 'Art Enthusiast',
        description: 'Reach Level 3',
        icon: Icons.star,
        isUnlocked: userLevel >= 3,
        progress: userLevel < 3 ? (userLevel / 3).clamp(0.0, 1.0) : 1.0,
        showProgress: userLevel < 3,
        progressText: 'Level $userLevel/3',
        customColor: ArtbeatColors.primaryPurple,
      ),
      AchievementBadgeData(
        title: 'Explorer',
        description: 'Discover 10 artists',
        icon: Icons.explore,
        isUnlocked: artistsDiscovered >= 10,
        progress: (artistsDiscovered / 10).clamp(0.0, 1.0),
        showProgress: artistsDiscovered < 10,
        progressText: '$artistsDiscovered/10',
        customColor: ArtbeatColors.accentYellow,
      ),
      AchievementBadgeData(
        title: 'Experience Master',
        description: 'Earn 500 XP',
        icon: Icons.emoji_events,
        isUnlocked: userXP >= 500,
        progress: (userXP / 500).clamp(0.0, 1.0),
        showProgress: userXP < 500,
        progressText: '$userXP/500 XP',
        customColor: ArtbeatColors.featured,
      ),
      AchievementBadgeData(
        title: 'Community Member',
        description: 'Join ARTbeat community',
        icon: Icons.group,
        isUnlocked: true, // Always unlocked for being in the app
        customColor: ArtbeatColors.primaryGreen,
      ),
    ];
  }
}

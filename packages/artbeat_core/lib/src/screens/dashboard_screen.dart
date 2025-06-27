import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/maps_diagnostic_service.dart';
import '../utils/location_utils.dart';
import '../models/user_model.dart';
import '../models/artist_profile_model.dart';
import '../models/artwork_model.dart';
import '../models/capture_model.dart';

import '../widgets/universal_header.dart';
import '../widgets/artbeat_drawer.dart';
import '../widgets/main_layout.dart';
import '../theme/index.dart';

import 'package:artbeat_events/artbeat_events.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

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

  List<ArtistProfileModel> _featuredArtists = [];
  bool _mapsInitialized = false;

  List<ArtistProfileModel> _nearbyArtists = [];
  bool _isLoadingNearbyArtists = false;

  List<ArtworkModel> _nearbyArtworks = [];
  bool _isLoadingNearbyArtworks = false;

  List<CaptureModel> _nearbyCaptures = [];
  bool _isLoadingCaptures = false;

  List<ArtbeatEvent> _upcomingEvents = [];
  bool _isLoadingEvents = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _initializeMaps();
    _loadUserData();
    _loadFeaturedArtists();
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


  Future<void> _initializeMaps() async {
    try {


      await GoogleMapsService().initializeMaps();

      setState(() {
        _mapsInitialized = true;
      });



      await _getUserLocation();
    } catch (e) {

      await _getUserLocation();
    }
  }


  Future<void> _getUserLocation() async {
    try {

      final position = await LocationUtils.getCurrentPosition();
      final userLocation = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _userLocation = userLocation;
          _updateMapMarkers();
        });
      }


    } catch (e) {

      const defaultLocation = LatLng(35.5951, -82.5515);

      if (mounted) {
        setState(() {
          _userLocation = defaultLocation;
          _updateMapMarkers();
        });
      }


    }
  }


  void _updateMapMarkers() {
    if (_userLocation == null) return;

    final Set<Marker> markers = {

      Marker(
        markerId: const MarkerId('user_location'),
        position: _userLocation!,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };


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
      }
    }

    _markers = markers;
  }

  void _navigateToArtistOnboarding() {
    Navigator.pushNamed(context, '/artist/onboarding');
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


  Future<void> _loadFeaturedArtists() async {
    try {


      final QuerySnapshot artistUsersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'artist')
          .get();



      final List<Future<DocumentSnapshot>> profileFutures = artistUsersSnapshot
          .docs
          .map(
            (userDoc) => FirebaseFirestore.instance
                .collection('artistProfiles')
                .doc(userDoc.id)
                .get(),
          )
          .toList();

      final List<DocumentSnapshot> profileDocs = await Future.wait(
        profileFutures,


      final List<ArtistProfileModel> artistProfiles = [];

      for (var profileDoc in profileDocs) {
        if (!profileDoc.exists) continue;

        try {
          final data = profileDoc.data() as Map<String, dynamic>;


            '  Raw userType value: ${data['userType']} (${data['userType'].runtimeType})',

          final profile = ArtistProfileModel.fromFirestore(profileDoc);



          artistProfiles.add(profile);
        } catch (e) {
          final data = profileDoc.data() as Map<String, dynamic>;

        }
      }


      artistProfiles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (mounted) {
        setState(() {
          _featuredArtists = artistProfiles;
        });
      }



      for (var artist in artistProfiles) {
      }
    } catch (e) {
    }
  }

  Future<void> _loadNearbyCaptures() async {
    setState(() {
      _isLoadingCaptures = true;
    });

    try {

      final captures = <CaptureModel>[];


      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {

        try {
          final userCapturesSnapshot = await FirebaseFirestore.instance
              .collection('captures')
              .where('userId', isEqualTo: currentUserId)
              .orderBy('createdAt', descending: true)
              .get();


          for (final doc in userCapturesSnapshot.docs) {
            try {
              final data = doc.data();
              final capture = CaptureModel.fromJson({...data, 'id': doc.id});
              captures.add(capture);
            } catch (e) {
            }
          }
        } catch (e) {
        }
      }


      try {
        final publicCapturesSnapshot = await FirebaseFirestore.instance
            .collection('captures')
            .where('isPublic', isEqualTo: true)
            .where('isProcessed', isEqualTo: true)
            .limit(20)
            .get();


        for (final doc in publicCapturesSnapshot.docs) {
          try {
            final data = doc.data();

            if (data['userId'] != currentUserId) {
              final capture = CaptureModel.fromJson({...data, 'id': doc.id});
              captures.add(capture);
            }
          } catch (e) {
          }
        }
      } catch (e) {
      }


      captures.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _nearbyCaptures = captures;
          _isLoadingCaptures = false;
          _updateMapMarkers();
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


  Future<void> _loadNearbyArtists() async {
    setState(() {
      _isLoadingNearbyArtists = true;
    });

    try {


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
        } catch (e) {
        }
      }


      allArtists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (mounted) {
        setState(() {
          _nearbyArtists = allArtists;
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


  Future<void> _loadNearbyArtworks() async {
    setState(() {
      _isLoadingNearbyArtworks = true;
    });

    try {


      await _loadNearbyArtworkFromStorage();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingNearbyArtworks = false;
        });
      }
    }
  }

  Future<void> _loadNearbyArtworkFromStorage() async {
    try {


      try {
        FirebaseStorage.instance.ref();
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingNearbyArtworks = false;
          });
        }
        return;
      }

      final Reference storageRef = FirebaseStorage.instance.ref().child(
        'artwork_images',
      final ListResult result = await storageRef.listAll();

      final List<ArtworkModel> artworks = [];
      int processed = 0;


      for (var item in result.items) {
        try {
          final String downloadUrl = await item.getDownloadURL();
          final FullMetadata metadata = await item.getMetadata();

          final artwork = ArtworkModel(
            id: item.name,
            title:
                metadata.customMetadata?['title'] ??
                item.name
                    .replaceAll('_', ' ')
                    .replaceAll('.jpg', '')
                    .replaceAll('.png', ''),
            artistId: metadata.customMetadata?['artistId'] ?? 'unknown',
            imageUrl: downloadUrl,
            description:
                metadata.customMetadata?['description'] ?? 'Local artwork',
            createdAt: metadata.timeCreated ?? DateTime.now(),
            tags: metadata.customMetadata?['tags']?.split(',') ?? [],
            isSold: false,
            price: 0.0,
            medium: metadata.customMetadata?['medium'] ?? 'Mixed Media',

          artworks.add(artwork);
          processed++;

        } catch (e) {
        }
      }

      if (mounted) {
        setState(() {
          _nearbyArtworks = artworks;
          _isLoadingNearbyArtworks = false;
        });
      }

    } catch (e) {
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
              onPressed: () {              },
            ),
          ],
        ),
        drawer: const ArtbeatDrawer(),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [

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
                        Text(
                          'Level ${_currentUser!.level} • ${_currentUser!.experiencePoints} XP',
                          style: const TextStyle(
                            fontSize: 16,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _getLevelProgress(),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    ArtbeatColors.primaryPurple,
                                    ArtbeatColors.primaryGreen,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getLevelTitle(_currentUser!.level),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: ArtbeatColors.primaryPurple,
                          ),
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


                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
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
  }

  Widget _buildExploreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

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
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _userLocation != null && _mapsInitialized
                        ? GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _userLocation!,
                              zoom: 14.0,
                            ),
                            markers: _markers,
                            myLocationEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            onMapCreated:
                                (GoogleMapController controller) async {
                                  try {
                                    await controller.animateCamera(
                                      CameraUpdate.newLatLng(_userLocation!),
                                  } catch (e) {
                                    await MapsDiagnosticService.logDiagnostics();
                                  }
                                },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[200],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!_mapsInitialized) ...[
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Initializing maps...',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ] else if (_userLocation == null) ...[
                                    const Icon(
                                      Icons.location_searching,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Getting your location...',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                  ),

                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.7 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Tap to explore Art Walk',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_nearbyCaptures.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ArtbeatColors.primaryGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_nearbyCaptures.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
          ),

          const SizedBox(height: 24),


          const Text(
            'Captured Art',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 180,
            child: _isLoadingCaptures
                ? const Center(child: CircularProgressIndicator())
                : _nearbyCaptures.isEmpty
                ? Container(
                    height: 120,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ArtbeatColors.primaryGreen.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ArtbeatColors.primaryGreen.withAlpha(77),
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 32,
                            color: ArtbeatColors.primaryGreen,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No Captured Art Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Be the first to capture art!',
                            style: TextStyle(
                              fontSize: 14,
                              color: ArtbeatColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _nearbyCaptures.length,
                    itemBuilder: (context, index) {
                      final capture = _nearbyCaptures[index];
                      return _buildCapturedArtCard(capture);
                    },
                  ),
          ),

          const SizedBox(height: 24),


          const Text(
            'Artists',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 145,
            child: Builder(
              builder: (context) {
                  '  _isLoadingNearbyArtists: $_isLoadingNearbyArtists',
                  '  _nearbyArtists.isEmpty: ${_nearbyArtists.isEmpty}',

                return _isLoadingNearbyArtists
                    ? const Center(child: CircularProgressIndicator())
                    : _nearbyArtists.isEmpty
                    ? Center(
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
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _nearbyArtists.length,
                        itemBuilder: (context, index) {
                          final artist = _nearbyArtists[index];
                          return _buildArtistCard(artist);
                        },
              },
            ),
          ),

          const SizedBox(height: 24),


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
  }

  Widget _buildArtistCard(ArtistProfileModel artist) {
    return Container(
      width: 120,
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
          Navigator.pushNamed(context, '/artist/profile', arguments: artist.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              CircleAvatar(
                radius: 30,
                backgroundColor: ArtbeatColors.primaryPurple.withAlpha(25),
                backgroundImage: artist.profileImageUrl != null
                    ? NetworkImage(artist.profileImageUrl!)
                    : null,
                child: artist.profileImageUrl == null
                    ? Text(
                        artist.displayName.isNotEmpty
                            ? artist.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ArtbeatColors.primaryPurple,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 6),

              Text(
                artist.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),

              Text(
                artist.bio ??
                    (artist.mediums.isNotEmpty
                        ? artist.mediums.first
                        : 'Artist'),
                style: TextStyle(color: Colors.grey[600], fontSize: 9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
          Navigator.pushNamed(context, '/artist/profile', arguments: artist.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              CircleAvatar(
                radius: 40,
                backgroundColor: ArtbeatColors.primaryPurple.withAlpha(25),
                backgroundImage: artist.profileImageUrl != null
                    ? NetworkImage(artist.profileImageUrl!)
                    : null,
                child: artist.profileImageUrl == null
                    ? Text(
                        artist.displayName.isNotEmpty
                            ? artist.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: ArtbeatColors.primaryPurple,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),

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

              SizedBox(
                width: double.infinity,
                height: 28,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/artist/profile',
                      arguments: artist.id,
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
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

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
                  child: Image.network(
                    artwork.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey,
                        ),
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                    },
                  ),
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artwork.medium,
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (!artwork.isSold && artwork.price > 0)
                      Text(
                        '\$${artwork.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: ArtbeatColors.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
  }

  Widget _buildCapturedArtCard(CaptureModel capture) {
    return Container(
      width: 150,
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

          Navigator.pushNamed(context, '/art-walk/dashboard');
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

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
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
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
            ),

            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const Spacer(),
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
            ),
          ],
        ),
      ),
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

          Navigator.pushNamed(context, '/events/details', arguments: event.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

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
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
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

            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.location,
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: ArtbeatColors.accentYellow.withAlpha(204),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${event.dateTime.month}/${event.dateTime.day}',
                            style: TextStyle(
                              fontSize: 10,
                              color: ArtbeatColors.accentYellow.withAlpha(204),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (event.hasFreeTickets)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ArtbeatColors.primaryGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FREE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
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
  }


  double _getLevelProgress() {
    if (_currentUser == null) return 0.0;

    final currentXP = _currentUser!.experiencePoints;
    final currentLevel = _currentUser!.level;


    final xpForCurrentLevel = currentLevel * 100;
    final xpForNextLevel = (currentLevel + 1) * 100;
    final xpInCurrentLevel = currentXP - xpForCurrentLevel;
    final xpNeededForLevel = xpForNextLevel - xpForCurrentLevel;

    if (xpNeededForLevel <= 0) return 1.0;

    return (xpInCurrentLevel / xpNeededForLevel).clamp(0.0, 1.0);
  }


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
}

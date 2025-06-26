import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/user_service.dart';
import '../services/maps_diagnostic_service.dart';
import '../models/user_model.dart';
import '../models/artist_profile_model.dart';
import '../models/artwork_model.dart';
import '../models/user_type.dart';
import '../utils/location_utils.dart';
import '../widgets/universal_header.dart';
import '../widgets/artbeat_drawer.dart';
import '../widgets/main_layout.dart';
import '../theme/index.dart';
import 'package:artbeat_art_walk/src/services/google_maps_service.dart';

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
  bool _mapsInitialized = false;

  List<ArtworkModel> _featuredArtworks = [];
  bool _isLoadingArtworks = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Add debug message about expected Firebase warnings
    debugPrint('🔥 Dashboard: Starting initialization...');
    debugPrint(
      'ℹ️ Note: Firebase App Check errors are expected in debug mode and can be ignored',
    );

    _initializeMaps();
    _loadUserData();
    _loadFeaturedArtists();
    _loadFeaturedArtworks();

    // Debug: Check what user types exist in database
    _debugUserTypes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Initialize Google Maps with diagnostic checks for iOS fix
  Future<void> _initializeMaps() async {
    debugPrint('🗺️ Initializing Google Maps...');

    // Run diagnostic check first for iOS troubleshooting
    await MapsDiagnosticService.logDiagnostics();

    try {
      // Use the GoogleMapsService from art_walk
      final googleMapsService = GoogleMapsService();
      final initialized = await googleMapsService.initializeMaps();

      if (mounted) {
        setState(() {
          _mapsInitialized = initialized;
        });

        if (initialized) {
          debugPrint('✅ Maps initialized successfully');
          await _getUserLocation();
        } else {
          debugPrint('❌ Failed to initialize maps - check iOS configuration');
          debugPrint('📋 iOS Troubleshooting:');
          debugPrint('   1. Check if Google Maps API key is set in Info.plist');
          debugPrint('   2. Verify iOS deployment target is 11.0+');
          debugPrint(
            '   3. Check if Maps SDK for iOS is enabled in Google Console',
          );
          debugPrint('   4. API Key: AIzaSyDzH_pJ_I2U_rkC4OBKVasjjJMus3LtSH0');
          debugPrint('   5. Bundle ID: com.wordnerd.artbeat');
          await MapsDiagnosticService.logDiagnostics();
          // Still try to get location even if maps fail
          await _getUserLocation();
        }
      }
    } catch (e) {
      debugPrint('❌ Maps initialization error: $e');
      debugPrint('🔍 Common iOS Maps Issues:');
      debugPrint('   - API key not configured in Info.plist');
      debugPrint('   - Maps SDK not enabled in Google Cloud Console');
      debugPrint('   - iOS deployment target too low');
      await MapsDiagnosticService.logDiagnostics();
      // Still try to get location even if maps crash
      await _getUserLocation();
    }
  }

  /// Get user location and set up markers
  Future<void> _getUserLocation() async {
    try {
      // Try to get actual user location first
      final position = await LocationUtils.getCurrentPosition();
      final userLocation = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _userLocation = userLocation;
          _markers = {
            Marker(
              markerId: const MarkerId('user_location'),
              position: userLocation,
              infoWindow: const InfoWindow(title: 'Your Location'),
            ),
          };
        });
      }
      debugPrint('📍 User location set to: $userLocation');
    } catch (e) {
      debugPrint('❌ Failed to get user location: $e, using default location');
      // Fallback to default location (Asheville, NC)
      const defaultLocation = LatLng(35.5951, -82.5515);

      if (mounted) {
        setState(() {
          _userLocation = defaultLocation;
          _markers = {
            Marker(
              markerId: const MarkerId('user_location'),
              position: defaultLocation,
              infoWindow: const InfoWindow(
                title: 'Default Location (Asheville, NC)',
              ),
            ),
          };
        });
      }
    }
  }

  void _navigateToArtistOnboarding() {
    Navigator.pushNamed(context, '/artist/onboarding');
  }

  Future<void> _loadUserData() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final user = await userService.getCurrentUserModel();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
    }
  }

  Future<void> _loadFeaturedArtists() async {
    setState(() {
      _isLoadingArtists = true;
    });

    try {
      debugPrint(
        '📊 Loading artist profiles from artistProfiles collection...',
      );

      // First, check and create missing artist profiles
      await _ensureArtistProfilesExist();

      // Get all artist profiles - skip orderBy to get all documents
      debugPrint(
        '🔍 Executing Firestore query: collection("artistProfiles").get() (no orderBy to avoid index issues)',
      );

      final artistProfileSnapshot = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .get(); // Get all documents without orderBy

      debugPrint('✅ Query completed successfully');
      debugPrint(
        '📊 Found ${artistProfileSnapshot.docs.length} artist profiles total',
      );

      // Debug: Log document IDs and data found
      if (artistProfileSnapshot.docs.isNotEmpty) {
        debugPrint('🔍 Artist Profile Documents found:');
        for (var doc in artistProfileSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          debugPrint('  - Document ID: ${doc.id}');
          debugPrint('    displayName: ${data['displayName']}');
          debugPrint('    userId: ${data['userId']}');
          debugPrint('    userType: ${data['userType']}');
          debugPrint(
            '    updatedAt: ${data['updatedAt']} (${data['updatedAt']?.runtimeType})',
          );
          debugPrint(
            '    createdAt: ${data['createdAt']} (${data['createdAt']?.runtimeType})',
          );

          // Check for missing required fields
          final missingFields = <String>[];
          if (data['userId'] == null) missingFields.add('userId');
          if (data['displayName'] == null) missingFields.add('displayName');
          if (data['userType'] == null) missingFields.add('userType');
          if (data['createdAt'] == null) missingFields.add('createdAt');
          if (data['updatedAt'] == null) missingFields.add('updatedAt');

          if (missingFields.isNotEmpty) {
            debugPrint('    ⚠️ Missing fields: ${missingFields.join(', ')}');
          }
        }
      }

      // Convert documents to ArtistProfileModel
      final List<ArtistProfileModel> artistProfiles = [];

      for (var doc in artistProfileSnapshot.docs) {
        try {
          debugPrint('🔄 Converting document ${doc.id}...');
          final profile = ArtistProfileModel.fromFirestore(doc);
          artistProfiles.add(profile);
          debugPrint(
            '✅ Successfully loaded artist profile: ${doc.id} - ${profile.displayName}',
          );
        } catch (e) {
          debugPrint('❌ Error converting document ${doc.id}: $e');
          final data = doc.data() as Map<String, dynamic>;
          debugPrint('   Document data: $data');
        }
      }

      // Sort in memory by updatedAt
      artistProfiles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      // Debug log each artist profile
      for (var artist in artistProfiles) {
        debugPrint(
          '🎨 Artist Profile: ${artist.displayName} (${artist.userType.name}) - ID: ${artist.id}',
        );
      }

      if (mounted) {
        setState(() {
          _featuredArtists = artistProfiles;
          _isLoadingArtists = false;
        });
      }

      debugPrint('✅ Total artists loaded: ${artistProfiles.length}');
    } catch (e) {
      debugPrint('❌ Error loading artist profiles: $e');
      if (mounted) {
        setState(() {
          _isLoadingArtists = false;
        });
      }
    }
  }

  /// Ensure that all users with userType "artist" have corresponding artist profiles
  Future<void> _ensureArtistProfilesExist() async {
    try {
      debugPrint('🔍 Checking for missing artist profiles...');

      // Get users with userType "artist" from the users collection
      debugPrint(
        '👥 Loading users with userType "artist" from users collection...',
      );
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'artist')
          .get();

      debugPrint(
        '📊 Found ${usersSnapshot.docs.length} users with userType "artist"',
      );

      if (usersSnapshot.docs.isEmpty) {
        debugPrint('ℹ️ No users with userType "artist" found');
        return;
      }

      // Get existing artist profiles
      final artistProfilesSnapshot = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .get();

      // Create a set of userIds that already have artist profiles
      final existingProfileUserIds = <String>{};
      for (final doc in artistProfilesSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        if (userId != null) {
          existingProfileUserIds.add(userId);
        }
      }

      debugPrint(
        '🔍 Found ${existingProfileUserIds.length} existing artist profiles',
      );

      // Find users who need artist profiles
      final usersNeedingProfiles = <DocumentSnapshot>[];

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        if (!existingProfileUserIds.contains(userId)) {
          usersNeedingProfiles.add(userDoc);
          final userData = userDoc.data() as Map<String, dynamic>;
          debugPrint(
            '🔍 User needs profile: ${userData['fullName']} (ID: $userId)',
          );
        }
      }

      if (usersNeedingProfiles.isEmpty) {
        debugPrint('✅ All artist users already have profiles');
        return;
      }

      debugPrint(
        '📝 Creating ${usersNeedingProfiles.length} missing artist profiles...',
      );

      // Create missing artist profiles
      int successCount = 0;

      for (final userDoc in usersNeedingProfiles) {
        try {
          final userId = userDoc.id;
          final userData = userDoc.data() as Map<String, dynamic>;

          final fullName = userData['fullName'] as String? ?? 'Unknown Artist';
          final bio = userData['bio'] as String? ?? 'Artist on ARTbeat';
          final location = userData['location'] as String?;
          final profileImageUrl = userData['profileImageUrl'] as String?;
          final coverImageUrl = userData['coverImageUrl'] as String?;

          final now = DateTime.now();

          final artistProfileData = {
            'userId': userId,
            'displayName': fullName,
            'bio': bio,
            'location': location,
            'profileImageUrl': profileImageUrl,
            'coverImageUrl': coverImageUrl,
            'website': null,
            'userType': 'artist',
            'subscriptionTier': 'artistBasic',
            'isVerified': false,
            'isFeatured': false,
            'isPortfolioPublic': true,
            'mediums': <String>[],
            'styles': <String>[],
            'socialLinks': <String, String>{},
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          };

          final docRef = await FirebaseFirestore.instance
              .collection('artistProfiles')
              .add(artistProfileData);

          debugPrint(
            '✅ Created artist profile for $fullName (Profile ID: ${docRef.id})',
          );
          successCount++;
        } catch (e) {
          debugPrint('❌ Error creating profile for user ${userDoc.id}: $e');
        }
      }

      debugPrint('🎉 Created $successCount missing artist profiles');
    } catch (e) {
      debugPrint('❌ Error ensuring artist profiles exist: $e');
    }
  }

  Future<void> _loadFeaturedArtworks() async {
    setState(() {
      _isLoadingArtworks = true;
    });

    try {
      debugPrint('🖼️ Loading artworks from Firebase Storage...');

      // Load artwork directly from Firebase Storage since that's where they're stored
      await _loadArtworkFromStorage();
    } catch (e) {
      debugPrint('❌ Error loading featured artworks: $e');
      // Try loading from Storage as fallback
      await _loadArtworkFromStorage();
    }
  }

  Future<void> _loadArtworkFromStorage() async {
    try {
      debugPrint(
        '📁 Loading artworks from Firebase Storage artwork_images/ folder...',
      );

      // Check if Firebase Storage is available
      try {
        FirebaseStorage.instance.ref();
      } catch (e) {
        debugPrint('⚠️ Firebase Storage not available: $e');
        if (mounted) {
          setState(() {
            _isLoadingArtworks = false;
          });
        }
        return;
      }

      final Reference storageRef = FirebaseStorage.instance.ref().child(
        'artwork_images',
      );

      // Add timeout to prevent hanging
      final ListResult result = await storageRef.listAll().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ Storage listing timed out after 10 seconds');
          throw Exception('Storage access timed out');
        },
      );

      debugPrint(
        '📊 Found ${result.items.length} items in artwork_images folder',
      );

      if (result.items.isNotEmpty) {
        List<ArtworkModel> storageArtworks = [];

        // Limit to first 20 items for performance
        final itemsToLoad = result.items.take(20);

        for (var item in itemsToLoad) {
          try {
            final String downloadUrl = await item.getDownloadURL();
            final FullMetadata metadata = await item.getMetadata();

            // Create artwork model from storage item
            final artwork = ArtworkModel(
              id: item.name,
              title:
                  metadata.customMetadata?['title'] ??
                  item.name.split('/').last.split('.').first,
              description:
                  metadata.customMetadata?['description'] ??
                  'Artwork from gallery',
              artistId: metadata.customMetadata?['artistId'] ?? 'unknown',
              imageUrl: downloadUrl,
              price:
                  double.tryParse(metadata.customMetadata?['price'] ?? '0') ??
                  0,
              medium: metadata.customMetadata?['medium'] ?? 'Mixed Media',
              tags: (metadata.customMetadata?['tags'] ?? '')
                  .split(',')
                  .where((t) => t.isNotEmpty)
                  .toList(),
              createdAt: metadata.timeCreated ?? DateTime.now(),
              isSold: metadata.customMetadata?['isSold'] == 'true',
            );

            storageArtworks.add(artwork);
            debugPrint('🖼️ Loaded artwork: ${artwork.title}');
          } catch (e) {
            debugPrint('⚠️ Error loading artwork ${item.name}: $e');
          }
        }

        if (mounted) {
          setState(() {
            _featuredArtworks = storageArtworks;
            _isLoadingArtworks = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingArtworks = false;
          });
        }
      }
    } catch (e) {
      // Enhanced error logging for different Firebase Storage errors
      if (e.toString().contains('-13020')) {
        debugPrint(
          '❌ Firebase Storage connection error (-13020): This is often due to App Check or network issues in debug mode',
        );
        debugPrint(
          'ℹ️ This error is expected in development and won\'t affect artwork display from Firestore',
        );
      } else if (e.toString().contains('timeout')) {
        debugPrint('❌ Firebase Storage timeout: Network or connectivity issue');
      } else {
        debugPrint('❌ Error loading artworks from storage: $e');
      }

      if (mounted) {
        setState(() {
          _isLoadingArtworks = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0, // Dashboard is index 0 (Home)
      child: Scaffold(
        appBar: UniversalHeader(
          title: 'ARTbeat',
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
                // Welcome Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                        'Welcome${_currentUser?.fullName != null && _currentUser!.fullName.isNotEmpty ? ', ${_currentUser!.fullName}' : ''}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Discover art in your community',
                        style: TextStyle(
                          fontSize: 16,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Level Progress Section
                if (_currentUser != null)
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
                            const Icon(
                              Icons.emoji_events,
                              color: ArtbeatColors.accentYellow,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Level ${_currentUser!.level} - ${_getLevelTitle(_currentUser!.level)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ArtbeatColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_currentUser!.experiencePoints} XP',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: ArtbeatColors.primaryPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _getLevelProgress(),
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            ArtbeatColors.accentYellow,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Next level: ${_getXPForNextLevel()} XP',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
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
                SizedBox(
                  height: 800, // Fixed height for tab content
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
          // Google Map Section - FIXED FOR iOS
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
                            onMapCreated: (GoogleMapController controller) async {
                              debugPrint('🗺️ Map created successfully');
                              // Test if the map is working by trying to move camera
                              try {
                                await controller.animateCamera(
                                  CameraUpdate.newLatLng(_userLocation!),
                                );
                                debugPrint('✅ Map camera test successful');
                              } catch (e) {
                                debugPrint('❌ Map camera test failed: $e');
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
                                    const SizedBox(height: 8),
                                    const Text(
                                      'If this takes too long, check docs/IOS_GOOGLE_MAPS_FIX_GUIDE.md',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
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
                                  ] else ...[
                                    const Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Map loading error',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Check iOS fix guide in docs/',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                  ),
                  // Tap indicator overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.7 * 255).toInt()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'View Art Walk',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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

          // Captured Art Near You section - NO MORE FAKE DATA
          const Text(
            'Captured Art Near You',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Captured art is available in the Art Walk feature
          Container(
            height: 120,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ArtbeatColors.primaryGreen.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ArtbeatColors.primaryGreen.withAlpha(77),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 32,
                    color: ArtbeatColors.primaryGreen,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Captured Art',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ArtbeatColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Available in Art Walk',
                    style: TextStyle(
                      fontSize: 14,
                      color: ArtbeatColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Artists Near You section - ALL ARTISTS
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
            height: 140,
            child: _isLoadingArtists
                ? const Center(child: CircularProgressIndicator())
                : _featuredArtists.isEmpty
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
                    itemCount: _featuredArtists.length.clamp(0, 5),
                    itemBuilder: (context, index) {
                      final artist = _featuredArtists[index];
                      return _buildCompactArtistCard(artist);
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
                    'Share your art with the community',
                    style: TextStyle(
                      fontSize: 14,
                      color: ArtbeatColors.textSecondary,
                    ),
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
            Icon(Icons.palette_outlined, size: 64, color: Colors.grey[400]),
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
              'Check back later for artists in your area',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _navigateToArtistOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Become an Artist'),
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
          // Header with stats - ENHANCED ARTIST WIDGET
          Row(
            children: [
              const Icon(
                Icons.stars,
                color: ArtbeatColors.accentYellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Artists',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.filter_list,
                  color: ArtbeatColors.primaryPurple,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Artist filters coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick stats - ARTIST STATISTICS WIDGET
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ArtbeatColors.primaryPurple.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ArtbeatColors.primaryPurple.withAlpha(77),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_featuredArtists.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ArtbeatColors.primaryPurple,
                        ),
                      ),
                      const Text(
                        'Artists',
                        style: TextStyle(
                          fontSize: 12,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_featuredArtists.where((a) => a.isVerified).length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ArtbeatColors.primaryGreen,
                        ),
                      ),
                      const Text(
                        'Verified Artists',
                        style: TextStyle(
                          fontSize: 12,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_featuredArtists.expand((a) => a.mediums).toSet().length}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ArtbeatColors.accentYellow.withAlpha(204),
                        ),
                      ),
                      const Text(
                        'Art Mediums',
                        style: TextStyle(
                          fontSize: 12,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Artists grid - REAL ARTIST DATA
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
              return _buildArtistCard(artist);
            },
          ),

          const SizedBox(height: 24),

          // Call to action for artists - ENHANCED WIDGET
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ArtbeatColors.primaryPurple.withAlpha(77),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.palette,
                  size: 48,
                  color: ArtbeatColors.primaryPurple,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you an artist?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join our community of artists and showcase your work to art lovers.',
                  style: TextStyle(
                    fontSize: 14,
                    color: ArtbeatColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _navigateToArtistOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArtbeatColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Become an Artist',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkTab() {
    if (_isLoadingArtworks) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading artwork...',
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with stats
          Row(
            children: [
              const Icon(
                Icons.palette,
                color: ArtbeatColors.accentYellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Featured Artwork',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.filter_list,
                  color: ArtbeatColors.primaryPurple,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Artwork filters coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick stats for artwork
          if (_featuredArtworks.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryGreen.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ArtbeatColors.primaryGreen.withAlpha(77),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_featuredArtworks.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ArtbeatColors.primaryGreen,
                          ),
                        ),
                        const Text(
                          'Artworks',
                          style: TextStyle(
                            fontSize: 12,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_featuredArtworks.expand((a) => [a.medium]).toSet().length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ArtbeatColors.primaryPurple,
                          ),
                        ),
                        const Text(
                          'Mediums',
                          style: TextStyle(
                            fontSize: 12,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_featuredArtworks.where((a) => !a.isSold).length}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ArtbeatColors.accentYellow.withAlpha(204),
                          ),
                        ),
                        const Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 12,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Show artwork grid or empty state
          _featuredArtworks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Artwork Found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for featured artwork',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to artwork upload or browse
                          Navigator.pushNamed(
                            context,
                            '/artist/artwork/upload',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ArtbeatColors.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Upload Artwork'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _featuredArtworks.length,
                  itemBuilder: (context, index) {
                    final artwork = _featuredArtworks[index];
                    return _buildArtworkGridCard(artwork);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildArtworkGridCard(ArtworkModel artwork) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to artwork detail screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Artwork: ${artwork.title}'),
              duration: const Duration(seconds: 2),
            ),
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
                decoration: BoxDecoration(color: Colors.grey[100]),
                child: artwork.imageUrl.isNotEmpty
                    ? Image.network(
                        artwork.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
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
                          Icons.palette,
                          size: 40,
                          color: Colors.grey,
                        ),
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
                      artwork.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artwork.medium,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (artwork.price > 0)
                          Text(
                            '\$${artwork.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.primaryGreen,
                              fontSize: 12,
                            ),
                          )
                        else
                          const Text(
                            'NFP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.primaryPurple,
                              fontSize: 12,
                            ),
                          ),
                        if (artwork.isSold)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'SOLD',
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
    );
  }

  Widget _buildCompactArtistCard(ArtistProfileModel artist) {
    final initials = artist.displayName.isNotEmpty
        ? artist.displayName.split(' ').map((name) => name[0]).take(2).join()
        : 'A';

    return Container(
      width: 120,
      height: 130,
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
            '/artist/public-profile',
            arguments: artist.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: ArtbeatColors.primaryPurple,
                backgroundImage:
                    artist.profileImageUrl != null &&
                        artist.profileImageUrl!.isNotEmpty
                    ? NetworkImage(artist.profileImageUrl!)
                    : null,
                child:
                    artist.profileImageUrl == null ||
                        artist.profileImageUrl!.isEmpty
                    ? Text(
                        initials.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 6),
              // Name with verification badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      artist.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (artist.isVerified) ...[
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.verified,
                      color: ArtbeatColors.primaryPurple,
                      size: 12,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              // Location
              if (artist.location != null && artist.location!.isNotEmpty)
                Flexible(
                  child: Text(
                    artist.location!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 2),
              // Medium
              if (artist.mediums.isNotEmpty)
                Flexible(
                  child: Text(
                    artist.mediums.take(2).join(', '),
                    style: const TextStyle(
                      color: ArtbeatColors.primaryPurple,
                      fontSize: 10,
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
      ),
    );
  }

  Widget _buildArtistCard(ArtistProfileModel artist) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
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
                child:
                    artist.profileImageUrl != null &&
                        artist.profileImageUrl!.isNotEmpty
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
                padding: const EdgeInsets.all(8), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Use minimum space needed
                  children: [
                    // Artist name with verification badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            artist.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13, // Slightly smaller font
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (artist.isVerified)
                          const Icon(
                            Icons.verified,
                            color: ArtbeatColors.primaryPurple,
                            size: 14, // Smaller icon
                          ),
                      ],
                    ),
                    const SizedBox(height: 2), // Reduced spacing
                    // Location
                    if (artist.location != null && artist.location!.isNotEmpty)
                      Text(
                        artist.location!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ), // Smaller font
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2), // Reduced spacing
                    // Mediums
                    if (artist.mediums.isNotEmpty)
                      Flexible(
                        // Use Flexible instead of taking full width
                        child: Text(
                          artist.mediums.take(2).join(', '),
                          style: const TextStyle(
                            fontSize: 10, // Smaller font
                            color: ArtbeatColors.primaryPurple,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // Remove Spacer to prevent overflow
                    // Featured badge
                    if (artist.isFeatured)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 2,
                        ), // Small top margin
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: ArtbeatColors.accentYellow.withAlpha(51),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: ArtbeatColors.accentYellow.withAlpha(128),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            'Featured',
                            style: TextStyle(
                              fontSize: 8, // Smaller font
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.accentYellow.withAlpha(204),
                            ),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Center(
        child: CircleAvatar(
          radius: 30,
          backgroundColor: ArtbeatColors.primaryPurple,
          backgroundImage:
              artist.profileImageUrl != null &&
                  artist.profileImageUrl!.isNotEmpty
              ? NetworkImage(artist.profileImageUrl!)
              : null,
          child:
              artist.profileImageUrl == null || artist.profileImageUrl!.isEmpty
              ? Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  /// Get level progress (0.0 to 1.0)
  double _getLevelProgress() {
    if (_currentUser == null) return 0.0;

    final currentXP = _currentUser!.experiencePoints;
    final currentLevel = _currentUser!.level;

    // Use level system from RewardsService
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

    // Use level system from RewardsService
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

  /// Debug method to check what user types exist in the database
  Future<void> _debugUserTypes() async {
    try {
      debugPrint('🔍 DEBUG: Checking user types in database...');

      // Get a sample of users to see their userType values
      final QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(10)
          .get();

      debugPrint('🔍 Found ${usersSnapshot.docs.length} total users');

      Map<String, int> userTypeCounts = {};

      for (var doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userType = data['userType'] as String?;

        if (userType != null) {
          userTypeCounts[userType] = (userTypeCounts[userType] ?? 0) + 1;

          // Log first few examples
          if (userTypeCounts[userType]! <= 2) {
            debugPrint(
              '👤 User ${doc.id}: ${data['fullName']} (${data['username']}) - userType: "$userType"',
            );
          }
        } else {
          userTypeCounts['null'] = (userTypeCounts['null'] ?? 0) + 1;
          debugPrint(
            '⚠️ User ${doc.id}: ${data['fullName']} - NO userType field',
          );
        }
      }

      debugPrint('📊 User Type Summary:');
      userTypeCounts.forEach((type, count) {
        debugPrint('   - $type: $count users');
      });
    } catch (e) {
      debugPrint('❌ Error in _debugUserTypes: $e');
    }
  }

  /// Debug method to check artistProfiles collection
  Future<void> _debugArtistProfiles() async {
    print('\n🔍 ======= DEBUGGING ARTIST PROFILES =======');

    try {
      // Step 1: Get all documents in artistProfiles collection
      print('📊 Step 1: Getting all artistProfiles documents...');
      final QuerySnapshot allSnapshot = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .get();

      print('   Found ${allSnapshot.docs.length} total documents');

      // Print details of each document
      for (int i = 0; i < allSnapshot.docs.length; i++) {
        final doc = allSnapshot.docs[i];
        final data = doc.data() as Map<String, dynamic>;

        print('\n   Document ${i + 1}: ${doc.id}');
        print('     displayName: ${data['displayName']}');
        print('     userId: ${data['userId']}');
        print(
          '     updatedAt: ${data['updatedAt']} (${data['updatedAt']?.runtimeType})',
        );

        // Check if updatedAt is missing or invalid
        if (data['updatedAt'] == null) {
          print('     ⚠️ PROBLEM: updatedAt is null!');
        } else if (data['updatedAt'] is! Timestamp) {
          print('     ⚠️ PROBLEM: updatedAt is not a Firestore Timestamp!');
        } else {
          final date = (data['updatedAt'] as Timestamp).toDate();
          print('     ✅ updatedAt is valid: $date');
        }
      }

      // Step 2: Test the dashboard query
      print('\n📊 Step 2: Testing dashboard query (orderBy updatedAt)...');

      try {
        final QuerySnapshot orderedSnapshot = await FirebaseFirestore.instance
            .collection('artistProfiles')
            .orderBy('updatedAt', descending: true)
            .get();

        print('   ✅ OrderBy query successful!');
        print('   Returned ${orderedSnapshot.docs.length} documents');

        if (orderedSnapshot.docs.length < allSnapshot.docs.length) {
          print('   🚨 ISSUE FOUND: OrderBy query returned fewer documents!');
          print('      Total: ${allSnapshot.docs.length}');
          print('      OrderBy: ${orderedSnapshot.docs.length}');
          print(
            '      Missing: ${allSnapshot.docs.length - orderedSnapshot.docs.length}',
          );

          // Find missing documents
          final orderedIds = orderedSnapshot.docs.map((d) => d.id).toSet();
          final allIds = allSnapshot.docs.map((d) => d.id).toSet();
          final missing = allIds.difference(orderedIds);
          print('      Missing IDs: $missing');
        }

        // Print ordered results
        print('   Ordered results:');
        for (int i = 0; i < orderedSnapshot.docs.length; i++) {
          final doc = orderedSnapshot.docs[i];
          final data = doc.data() as Map<String, dynamic>;
          print('     ${i + 1}. ${doc.id} - ${data['displayName']}');
        }
      } catch (e) {
        print('   ❌ OrderBy query failed: $e');
        print('   This explains why not all profiles show!');
      }

      // Step 3: Check for model conversion issues
      print('\n📊 Step 3: Testing ArtistProfileModel conversion...');

      for (final doc in allSnapshot.docs) {
        try {
          final profile = ArtistProfileModel.fromFirestore(doc);
          print(
            '   ✅ ${doc.id}: Conversion successful - ${profile.displayName}',
          );
        } catch (e) {
          print('   ❌ ${doc.id}: Conversion failed - $e');

          // Check for missing required fields
          final data = doc.data() as Map<String, dynamic>;
          final requiredFields = [
            'userId',
            'displayName',
            'userType',
            'createdAt',
            'updatedAt',
          ];

          for (final field in requiredFields) {
            if (!data.containsKey(field) || data[field] == null) {
              print('      Missing field: $field');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Debug failed: $e');
    }

    print('🔍 ======= END ARTIST PROFILES DEBUG =======\n');
  }
}

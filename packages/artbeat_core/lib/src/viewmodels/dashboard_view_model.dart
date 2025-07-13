import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Core imports
import '../models/user_model.dart';
import '../models/artist_profile_model.dart';
import '../models/event_model.dart';
import '../models/capture_model.dart';
import '../services/user_service.dart';
import 'base_view_model.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart'
    show RewardsService, ArtWalkModel, ArtWalkService;

// External package imports
import 'package:artbeat_capture/artbeat_capture.dart' show CaptureService;
import 'package:artbeat_artwork/artbeat_artwork.dart'
    show ArtworkService, ArtworkModel;
import '../utils/location_utils.dart';
import 'package:artbeat_community/artbeat_community.dart'
    show CommunityService, PostModel;
import '../widgets/achievement_badge.dart' show AchievementBadgeData;

/// ViewModel for managing dashboard state and business logic
bool _disposed = false;

class DashboardViewModel extends BaseViewModel {
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Services
  final UserService _userService = UserService();
  final ArtWalkService _artWalkService = ArtWalkService();
  final CaptureService _captureService = CaptureService();
  final RewardsService _rewardsService = RewardsService();
  final ArtworkService _artworkService = ArtworkService();
  final CommunityService _communityService = CommunityService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication state
  bool get _isAuthenticated => _auth.currentUser != null;

  // Rest of state
  int _unreadMessageCount = 0;
  bool _hasUnreadMessages = false;
  int _bottomNavIndex = 0;
  bool _isAchievementsExpanded = false;
  GoogleMapController? _mapController;
  bool _isLoadingMap = false;
  UserModel? _currentUser;
  bool _isLoadingUser = false;
  List<CaptureModel> _captures = [];
  bool _isLoadingCaptures = false;
  String? _capturesError;
  List<ArtistProfileModel> _artists = [];
  bool _isLoadingArtists = false;
  String? _artistsError;
  List<ArtistProfileModel> _featuredArtists = [];
  bool _isLoadingFeaturedArtists = false;
  String? _featuredArtistsError;
  List<ArtworkModel> _artworks = [];
  bool _isLoadingArtworks = false;
  String? _artworksError;
  List<EventModel> _events = [];
  bool _isLoadingEvents = false;
  String? _eventsError;
  List<PostModel> _posts = [];
  bool _isLoadingPosts = false;
  String? _postsError;
  List<AchievementBadgeData> _achievements = [];
  bool _isLoadingAchievements = false;
  bool _isMapPreviewReady = false;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  List<ArtWalkModel> _userArtWalks = [];
  bool _isLoadingUserArtWalks = false;
  String? _userArtWalksError;

  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(35.7796, -78.6382), // Default to Raleigh, NC
    zoom: 12,
  );

  // Getters
  int get unreadMessageCount => _unreadMessageCount;
  bool get hasUnreadMessages => _hasUnreadMessages;
  bool get isLoadingMap => _isLoadingMap;
  UserModel? get currentUser => _currentUser;
  bool get isLoadingUser => _isLoadingUser;
  List<CaptureModel> get captures => _captures;
  bool get isLoadingCaptures => _isLoadingCaptures;
  String? get capturesError => _capturesError;
  List<ArtistProfileModel> get artists => _artists;
  bool get isLoadingArtists => _isLoadingArtists;
  String? get artistsError => _artistsError;
  List<ArtistProfileModel> get featuredArtists => _featuredArtists;
  bool get isLoadingFeaturedArtists => _isLoadingFeaturedArtists;
  String? get featuredArtistsError => _featuredArtistsError;
  List<ArtworkModel> get artworks => _artworks;
  bool get isLoadingArtworks => _isLoadingArtworks;
  String? get artworksError => _artworksError;
  List<EventModel> get events => _events;
  bool get isLoadingEvents => _isLoadingEvents;
  String? get eventsError => _eventsError;
  List<PostModel> get posts => _posts;
  bool get isLoadingPosts => _isLoadingPosts;
  String? get postsError => _postsError;
  List<AchievementBadgeData> get achievements => _achievements;
  bool get isLoadingAchievements => _isLoadingAchievements;
  bool get isAchievementsExpanded => _isAchievementsExpanded;
  bool get isMapPreviewReady => _isMapPreviewReady;
  LatLng? get currentLocation => _currentLocation;
  Set<Marker> get markers => _markers;
  CameraPosition get initialCameraPosition => _initialCameraPosition;
  List<ArtWalkModel> get userArtWalks => _userArtWalks;
  bool get isLoadingUserArtWalks => _isLoadingUserArtWalks;
  String? get userArtWalksError => _userArtWalksError;
  int get bottomNavIndex => _bottomNavIndex;

  /// Initialize the view model
  Future<void> initialize() async {
    _isLoadingUser = true;
    notifyListeners();

    try {
      if (_isAuthenticated) {
        _currentUser = await _userService.getCurrentUserModel();
        await updateUnreadMessageCount();

        // Load all dashboard data
        await Future.wait([
          loadFeaturedArtists(),
          loadArtworks(),
          loadPosts(),
          loadEvents(),
          loadUserArtWalks(),
          loadCaptures(),
        ]);
      }
    } catch (e) {
      debugPrint('Error initializing dashboard: $e');
    } finally {
      _isLoadingUser = false;
      notifyListeners();
    }
  }

  /// Load user-created art walks
  Future<void> loadUserArtWalks() async {
    _isLoadingUserArtWalks = true;
    _userArtWalksError = null;
    notifyListeners();

    try {
      final userId = _currentUser?.id;
      if (userId == null) {
        _userArtWalks = [];
        return;
      }
      final walks = await _artWalkService.getUserArtWalks(userId);
      _userArtWalks = walks;
    } catch (e) {
      _userArtWalksError = e.toString();
      debugPrint('Error loading user art walks: $e');
    } finally {
      _isLoadingUserArtWalks = false;
      notifyListeners();
    }
  }

  /// Refresh all dashboard data
  Future<void> refresh() async {
    await initialize();
  }

  /// Load current user data
  Future<void> loadUserData() async {
    _isLoadingUser = true;
    notifyListeners();

    try {
      final user = await _userService.getCurrentUserModel();
      _currentUser = user;

      // Once user is loaded, reload captures with user context
      if (_currentUser != null) {
        await loadCaptures();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      _isLoadingUser = false;
      _safeNotifyListeners();
    }
  }

  /// Load user's captures
  Future<void> loadCaptures() async {
    _isLoadingCaptures = true;
    _capturesError = null;
    notifyListeners();

    try {
      final userId = _currentUser?.id;
      if (userId == null) {
        _captures = [];
        return;
      }

      final captures = await _captureService.getCapturesForUser(userId);

      _captures = captures;
      _updateMapMarkers();
    } catch (e) {
      _capturesError = e.toString();
      debugPrint('Error loading captures: $e');
    } finally {
      _isLoadingCaptures = false;
      notifyListeners();
    }
  }

  /// Load all artists
  Future<void> loadArtists() async {
    _isLoadingArtists = true;
    _artistsError = null;
    notifyListeners();

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
          debugPrint('Error parsing artist profile: $e');
        }
      }

      // Sort by most recently updated
      allArtists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _artists = allArtists;
    } catch (e) {
      _artistsError = e.toString();
      debugPrint('Error loading artists: $e');
    } finally {
      _isLoadingArtists = false;
      notifyListeners();
    }
  }

  /// Load featured artists
  Future<void> loadFeaturedArtists() async {
    _isLoadingFeaturedArtists = true;
    _featuredArtistsError = null;
    notifyListeners();

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .where('userType', isEqualTo: 'artist')
          .where('isFeatured', isEqualTo: true)
          .get();

      final List<ArtistProfileModel> featuredArtists = [];

      for (var doc in snapshot.docs) {
        if (!doc.exists) continue;
        try {
          final profile = ArtistProfileModel.fromFirestore(doc);
          featuredArtists.add(profile);
        } catch (e) {
          debugPrint('Error parsing featured artist profile: $e');
        }
      }

      // Sort by most recently updated
      featuredArtists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _featuredArtists = featuredArtists;
    } catch (e) {
      _featuredArtistsError = e.toString();
      debugPrint('Error loading featured artists: $e');
    } finally {
      _isLoadingFeaturedArtists = false;
      notifyListeners();
    }
  }

  /// Load all artworks
  Future<void> loadArtworks() async {
    _isLoadingArtworks = true;
    _artworksError = null;
    notifyListeners();

    try {
      final artworks = await _artworkService.getAllArtwork(limit: 50);
      _artworks = artworks;
    } catch (e) {
      _artworksError = e.toString();
      debugPrint('Error loading artworks: $e');
    } finally {
      _isLoadingArtworks = false;
      notifyListeners();
    }
  }

  /// Load upcoming events near the user's location
  Future<void> loadEvents() async {
    _isLoadingEvents = true;
    _eventsError = null;
    notifyListeners();

    try {
      if (_currentLocation == null) {
        // Default to loading events in Raleigh if location not available
        _currentLocation = const LatLng(35.7796, -78.6382);
      }

      // Query events within ~25 miles of current location
      // First try with both filters, fallback to single filter if composite index missing
      QuerySnapshot? snapshots;
      try {
        snapshots = await FirebaseFirestore.instance
            .collection('events')
            .where(
              'dateTime',
              isGreaterThan: Timestamp.fromDate(DateTime.now()),
            )
            .where('isPublic', isEqualTo: true)
            .orderBy('dateTime')
            .limit(10)
            .get();
      } catch (e) {
        // Fallback to single filter if composite index not available
        debugPrint(
          'Composite index not available, falling back to single filter',
        );
        snapshots = await FirebaseFirestore.instance
            .collection('events')
            .where('isPublic', isEqualTo: true)
            .orderBy('dateTime')
            .limit(10)
            .get();
      }

      final List<EventModel> filteredEvents = [];
      for (var doc in snapshots.docs) {
        final event = EventModel.fromFirestore(doc);

        // Filter for future events if we used the fallback query
        if (event.startDate.isBefore(DateTime.now())) {
          continue;
        }

        if (_currentLocation != null) {
          final eventLocation = await LocationUtils.getLocationFromAddress(
            event.location,
          );
          if (eventLocation != null) {
            final distance = LocationUtils.calculateDistance(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
              eventLocation.latitude,
              eventLocation.longitude,
            );
            if (distance <= 40233.6) {
              // ~25 miles in meters
              filteredEvents.add(event);
            }
          } else {
            // If location can't be resolved, include the event
            filteredEvents.add(event);
          }
        } else {
          filteredEvents.add(event);
        }
      }
      _events = filteredEvents;
    } catch (e) {
      _eventsError = e.toString();
      debugPrint('Error loading events: $e');
    } finally {
      _isLoadingEvents = false;
      notifyListeners();
    }
  }

  /// Load community posts
  Future<void> loadPosts() async {
    _isLoadingPosts = true;
    _postsError = null;
    notifyListeners();

    try {
      final posts = await _communityService.getPosts(limit: 10);
      _posts = posts;
    } catch (e) {
      _postsError = e.toString();
      debugPrint('Error loading posts: $e');
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  /// Load user achievements/badges
  Future<void> loadAchievements() async {
    _isLoadingAchievements = true;
    notifyListeners();

    try {
      final userId = _currentUser?.id;
      if (userId == null) {
        _achievements = [];
        return;
      }

      // Load badges from RewardsService
      final userBadges = await _rewardsService.getUserBadges(userId);

      // Convert badges to AchievementBadgeData
      final List<AchievementBadgeData> badgeData = [];

      for (final entry in userBadges.entries) {
        final badgeId = entry.key;
        final badgeInfo = RewardsService.badges[badgeId];

        if (badgeInfo != null) {
          final IconData icon = _getIconFromBadgeIcon(
            badgeInfo['icon'] as String,
          );

          badgeData.add(
            AchievementBadgeData(
              title: badgeInfo['name'] as String,
              description: badgeInfo['description'] as String,
              icon: icon,
              isUnlocked: true, // All badges from the service are unlocked
            ),
          );
        }
      }

      _achievements = badgeData;
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    } finally {
      _isLoadingAchievements = false;
      notifyListeners();
    }
  }

  /// DEBUG: Award test achievements for debugging
  Future<void> debugAwardTestAchievements() async {
    try {
      final userId = _currentUser?.id;
      if (userId == null) {
        debugPrint('No user logged in, cannot award badges');
        return;
      }

      // Award some test badges using RewardsService
      const testBadges = [
        'first_walk_completed',
        'first_capture_approved',
        'first_review_submitted',
        'contributor_level_1',
      ];

      for (final badgeId in testBadges) {
        await _rewardsService.awardBadge(userId, badgeId);
      }

      // Reload achievements to see the new ones
      await loadAchievements();
    } catch (e) {
      debugPrint('Error awarding test achievements: $e');
    }
  }

  /// Helper method to convert badge emoji to IconData
  IconData _getIconFromBadgeIcon(String badgeIcon) {
    // Map emoji icons to Material icons
    switch (badgeIcon) {
      case '🚶':
        return Icons.directions_walk;
      case '🎨':
        return Icons.palette;
      case '📸':
        return Icons.photo_camera;
      case '✍️':
        return Icons.edit;
      case '👍':
        return Icons.thumb_up;
      case '🏃':
        return Icons.directions_run;
      case '📷':
        return Icons.camera_alt;
      case '📝':
        return Icons.description;
      case '🌟':
        return Icons.star;
      case '🏛️':
        return Icons.account_balance;
      case '🎭':
        return Icons.theater_comedy;
      case '🔥':
        return Icons.whatshot;
      case '🥉':
        return Icons.looks_3;
      case '🥈':
        return Icons.looks_two;
      case '🥇':
        return Icons.looks_one;
      case '🗺️':
        return Icons.map;
      case '📅':
        return Icons.calendar_today;
      case '💡':
        return Icons.lightbulb;
      case '📚':
        return Icons.book;
      case '📢':
        return Icons.campaign;
      case '⭐':
        return Icons.star;
      case '🎯':
        return Icons.gps_fixed;
      case '🌅':
        return Icons.wb_sunny;
      case '🏠':
        return Icons.home;
      case '🏆':
        return Icons.emoji_events;
      case '👑':
        return Icons.military_tech;
      default:
        return Icons.emoji_events;
    }
  }

  /// Get user location
  Future<void> getUserLocation() async {
    try {
      final position = await LocationUtils.getCurrentPosition();
      final userLocation = LatLng(position.latitude, position.longitude);

      _currentLocation = userLocation;
      _updateMapMarkers();
      _isMapPreviewReady = true;
      notifyListeners();
    } catch (e) {
      // Fallback to default location (Asheville, NC)
      const defaultLocation = LatLng(35.5951, -82.5515);
      _currentLocation = defaultLocation;
      _updateMapMarkers();
      _isMapPreviewReady = true;
      notifyListeners();
    }
  }

  // Map initialization callback
  void onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    await _initializeMapLocation();
    _isLoadingMap = false;
    notifyListeners();
  }

  /// Initialize map location
  Future<void> _initializeMapLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(position.latitude, position.longitude);
      _initialCameraPosition = CameraPosition(
        target: _currentLocation!,
        zoom: 12,
      );

      _isMapPreviewReady = true;
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(_initialCameraPosition),
        );
      }

      _updateMapMarkers();
      loadEvents(); // Reload events with new location
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      _isLoadingMap = false;
      notifyListeners();
    }
  }

  /// Update map markers based on captures
  void _updateMapMarkers() {
    if (_captures.isEmpty || _currentLocation == null) return;

    final newMarkers = _captures
        .map((capture) {
          if (capture.location == null) return null;

          return Marker(
            markerId: MarkerId(capture.id),
            position: LatLng(
              capture.location!.latitude,
              capture.location!.longitude,
            ),
            infoWindow: InfoWindow(
              title: capture.title,
              snippet: capture.description,
            ),
          );
        })
        .whereType<Marker>()
        .toSet();

    _markers = newMarkers;
    notifyListeners();
  }

  /// Centers the dashboard map on the user's current location
  Future<void> centerMapOnUserLocation() async {
    try {
      // Request location permission if needed
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          // Permission denied, show error or fallback
          return;
        }
      }
      // Get current position using locationSettings
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      // Animate map camera to user location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      }
    } catch (e) {
      // Handle error (e.g., show a snackbar or log)
    }
  }

  /// Toggle achievements expansion
  void toggleAchievementsExpansion() {
    _isAchievementsExpanded = !_isAchievementsExpanded;
    notifyListeners();
  }

  /// Update bottom navigation index
  void updateBottomNavIndex(int index) {
    _bottomNavIndex = index;
    notifyListeners();
  }

  /// Load unread message count
  Future<void> updateUnreadMessageCount() async {
    if (!_isAuthenticated) return;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Check if current user is admin
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final isAdmin =
          userId == 'ARFuyX0C44PbYlHSUSlQx55b9vt2' ||
          (userDoc.exists && userDoc.data()?['userType'] == 'admin');

      debugPrint('🔐 Current user is admin: $isAdmin');

      if (isAdmin) {
        // Admin: Check all users' messages
        final allUsers = await _firestore.collection('users').get();
        int totalUnread = 0;

        for (var user in allUsers.docs) {
          // Check direct messages
          final directMessages = await _firestore
              .collection('users')
              .doc(user.id)
              .collection('messageStats')
              .where('unread', isEqualTo: true)
              .get();

          // Check chat room messages
          final chatRoomStats = await _firestore
              .collection('users')
              .doc(user.id)
              .collection('messageStats')
              .doc('chatStats')
              .collection('unreadCounts')
              .get();

          int unreadChatRoomMessages = 0;
          for (var doc in chatRoomStats.docs) {
            unreadChatRoomMessages += (doc.data()['count'] as int?) ?? 0;
          }

          totalUnread += directMessages.docs.length + unreadChatRoomMessages;
        }

        _unreadMessageCount = totalUnread;
      } else {
        // Regular user: Check only their messages
        final directMessages = await _firestore
            .collection('users')
            .doc(userId)
            .collection('messageStats')
            .where('unread', isEqualTo: true)
            .get();

        final chatRoomStats = await _firestore
            .collection('users')
            .doc(userId)
            .collection('messageStats')
            .doc('chatStats')
            .collection('unreadCounts')
            .get();

        int unreadChatRoomMessages = 0;
        for (var doc in chatRoomStats.docs) {
          unreadChatRoomMessages += (doc.data()['count'] as int?) ?? 0;
        }

        _unreadMessageCount =
            directMessages.docs.length + unreadChatRoomMessages;
      }

      _hasUnreadMessages = _unreadMessageCount > 0;
      debugPrint('✉️ Updated unread count: $_unreadMessageCount');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading unread message count: $e');
      // Don't update state on error to keep previous values
    }
  }

  /// Navigate to messaging section
  void showMessagingMenu(BuildContext context) {
    Navigator.pushNamed(context, '/messaging');
  }

  /// Get level progress (0.0 to 1.0)
  double getLevelProgress() {
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
  String getLevelTitle(int level) {
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

  /// Safe notify listeners that checks disposal state
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}

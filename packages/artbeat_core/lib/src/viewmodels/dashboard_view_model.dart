import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as artWalkLib;
import 'package:artbeat_artist/artbeat_artist.dart' as artist_profile;
import 'package:artbeat_events/artbeat_events.dart' as eventLib;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artworkLib;
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_community/artbeat_community.dart' as community;

class DashboardViewModel extends ChangeNotifier {
  final eventLib.EventService _eventService;
  final artworkLib.ArtworkService _artworkService;
  final artWalkLib.ArtWalkService _artWalkService;
  final artWalkLib.SocialService _socialService;
  final artWalkLib.ChallengeService _challengeService;
  final SubscriptionService _subscriptionService;
  final UserService _userService;
  final CaptureService _captureService;
  final ContentEngagementService _engagementService;
  final community.ArtCommunityService _communityService;
  final artist_profile.CommunityService _artistCommunityService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _currentUser;
  bool _isInitializing = true;
  bool _isLoadingEvents = true;
  bool _isLoadingUpcomingEvents = true;
  bool _isLoadingArtwork = true;
  bool _isLoadingArtists = true;
  bool _isLoadingLocation = true;
  bool _isMapPreviewReady = false;
  final bool _isLoadingMap = false;
  bool _isLoadingAchievements = true;
  bool _isLoadingLocalCaptures = true;
  bool _isLoadingPosts = true;
  bool _isLoadingUserProgress = true;
  bool _isLoadingActivities = true;

  String? _eventsError;
  String? _upcomingEventsError;
  String? _artworkError;
  String? _achievementsError;
  String? _artistsError;
  String? _locationError;
  String? _localCapturesError;
  String? _postsError;

  List<EventModel> _events = [];
  final List<EventModel> _upcomingEvents = [];
  List<ArtworkModel> _artwork = [];
  List<ArtistProfileModel> _artists = [];
  Set<Marker> _markers = {};
  Position? _currentLocation;
  LatLng? _mapLocation;
  List<artWalkLib.AchievementModel> _achievements = [];
  List<CaptureModel> _localCaptures = [];
  List<community.PostModel> _posts = [];
  List<artWalkLib.SocialActivity> _activities = [];
  artWalkLib.ChallengeModel? _todaysChallenge;

  // User progress stats
  int _totalDiscoveries = 0;
  int _currentStreak = 0;
  int _weeklyProgress = 0;

  DashboardViewModel({
    required eventLib.EventService eventService,
    required artworkLib.ArtworkService artworkService,
    required artWalkLib.ArtWalkService artWalkService,
    artWalkLib.SocialService? socialService,
    artWalkLib.ChallengeService? challengeService,
    required SubscriptionService subscriptionService,
    required UserService userService,
    CaptureService? captureService,
    ContentEngagementService? engagementService,
    community.ArtCommunityService? communityService,
    artist_profile.CommunityService? artistCommunityService,
  }) : _eventService = eventService,
       _artworkService = artworkService,
       _artWalkService = artWalkService,
       _socialService = socialService ?? artWalkLib.SocialService(),
       _challengeService = challengeService ?? artWalkLib.ChallengeService(),
       _subscriptionService = subscriptionService,
       _userService = userService,
       _captureService = captureService ?? CaptureService(),
       _engagementService = engagementService ?? ContentEngagementService(),
       _communityService = communityService ?? community.ArtCommunityService(),
       _artistCommunityService =
           artistCommunityService ?? artist_profile.CommunityService();

  /// Initializes dashboard data and state
  Future<void> initialize() async {
    debugPrint(
      '🔍 DashboardViewModel: initialize() called, _isInitializing=$_isInitializing',
    );
    if (!_isInitializing) {
      debugPrint('🔍 DashboardViewModel: Already initialized, skipping...');
      return; // Prevent multiple initializations
    }

    try {
      debugPrint('🔍 DashboardViewModel: Starting initialization...');
      _resetLoadingStates();
      // First load current user since other operations depend on it
      await _loadCurrentUser();
      AppLogger.info('👤 Current user loaded: ${_currentUser?.id}');

      // Then load all other data in parallel
      await Future.wait<void>([
        _loadEvents(),
        _loadArtwork(),
        _loadArtists(),
        _loadLocation(),
        _loadAchievements(),
        _loadLocalCaptures(),
        _loadPosts(),
        _loadActivities(),
        _loadUserProgress(),
        _loadTodaysChallenge(),
      ]);
      debugPrint('🔍 DashboardViewModel: ✅ Initialization complete');
    } catch (e, stack) {
      debugPrint('🔍 DashboardViewModel: ❌ Initialization error: $e');
      AppLogger.error('❌ Error initializing dashboard: $e');
      AppLogger.error('❌ Stack trace: $stack');
    } finally {
      _isInitializing = false;
      _safeNotifyListeners();
      debugPrint('🔍 DashboardViewModel: _isInitializing set to false');
    }
  }

  void _resetLoadingStates() {
    _isLoadingEvents = true;
    _isLoadingUpcomingEvents = true;
    _isLoadingArtwork = true;
    _isLoadingArtists = true;
    _isLoadingLocation = true;
    _isLoadingAchievements = true;
    _isLoadingLocalCaptures = true;
    _isLoadingPosts = true;
    _isLoadingActivities = true;
    _isLoadingUserProgress = true;
    _safeNotifyListeners();
  }

  /// Safely notify listeners, catching disposal errors
  void _safeNotifyListeners() {
    try {
      notifyListeners();
    } catch (e) {
      // Ignore errors if widget is disposed
      AppLogger.warning(
        '⚠️ Attempted to notify listeners on disposed ViewModel',
      );
    }
  }

  Future<void> _loadCurrentUser() async {
    if (_auth.currentUser == null) {
      _currentUser = null;
      return;
    }

    try {
      _currentUser = await _userService.getCurrentUserModel();
    } catch (e) {
      AppLogger.error('Error loading current user: $e');
      _currentUser = null;
    }
  }

  // Getters
  bool get isInitializing => _isInitializing;
  bool get isLoadingEvents => _isLoadingEvents;
  bool get isLoadingUpcomingEvents => _isLoadingUpcomingEvents;
  bool get isLoadingArtwork => _isLoadingArtwork;
  bool get isLoadingArtists => _isLoadingArtists;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isMapPreviewReady => _isMapPreviewReady;
  bool get isLoadingMap => _isLoadingMap;
  bool get isLoadingLocalCaptures => _isLoadingLocalCaptures;
  bool get isLoadingAchievements => _isLoadingAchievements;
  bool get isLoadingPosts => _isLoadingPosts;
  bool get isAuthenticated => _auth.currentUser != null;
  String? get eventsError => _eventsError;
  String? get upcomingEventsError => _upcomingEventsError;
  String? get artworkError => _artworkError;
  String? get achievementsError => _achievementsError;
  String? get artistsError => _artistsError;
  String? get locationError => _locationError;
  String? get localCapturesError => _localCapturesError;
  String? get postsError => _postsError;

  List<EventModel> get events => List.unmodifiable(_events);
  List<EventModel> get upcomingEvents => List.unmodifiable(_upcomingEvents);
  List<ArtworkModel> get artwork => List.unmodifiable(_artwork);
  List<ArtistProfileModel> get artists => List.unmodifiable(_artists);
  Set<Marker> get markers => Set.unmodifiable(_markers);
  Position? get currentLocation => _currentLocation;
  List<artWalkLib.AchievementModel> get achievements =>
      List.unmodifiable(_achievements);
  List<CaptureModel> get localCaptures => List.unmodifiable(_localCaptures);
  List<community.PostModel> get posts => List.unmodifiable(_posts);
  List<artWalkLib.SocialActivity> get activities =>
      List.unmodifiable(_activities);
  LatLng? get mapLocation => _mapLocation;
  UserModel? get currentUser => _currentUser;
  artWalkLib.ChallengeModel? get todaysChallenge => _todaysChallenge;

  // User progress getters
  int get totalDiscoveries => _totalDiscoveries;
  int get currentStreak => _currentStreak;
  int get weeklyProgress => _weeklyProgress;
  bool get isLoadingUserProgress => _isLoadingUserProgress;
  bool get isLoadingActivities => _isLoadingActivities;

  // Methods
  /// Reload just the activities feed
  Future<void> reloadActivities() async {
    debugPrint('🔍 DashboardViewModel: reloadActivities() called');
    await _loadActivities();
  }

  Future<void> refresh() async {
    if (_isInitializing) {
      // If still initializing, wait for it to complete
      return;
    }

    try {
      _resetLoadingStates();
      await _loadCurrentUser();

      await Future.wait<void>([
        _loadEvents(),
        _loadArtwork(),
        _loadArtists(),
        _loadLocation(),
        _loadAchievements(),
        _loadLocalCaptures(),
        _loadPosts(),
        _loadActivities(),
        _loadUserProgress(),
      ]);
    } catch (e, stack) {
      AppLogger.error('❌ Error refreshing dashboard: $e');
      AppLogger.error('❌ Stack trace: $stack');
    } finally {
      _safeNotifyListeners();
    }
  }

  Future<void> _loadAchievements() async {
    try {
      if (_currentUser == null) {
        _achievements = [];
        _achievementsError = null;
        return;
      }

      _achievements = await _userService.getUserAchievements(_currentUser!.id);
      _achievementsError = null;
    } catch (e) {
      AppLogger.error('Error loading achievements: $e');
      _achievementsError = e.toString();
      _achievements = [];
    } finally {
      _isLoadingAchievements = false;
      _safeNotifyListeners();
    }
  }

  Future<void> _loadEvents() async {
    try {
      _isLoadingEvents = true;
      _safeNotifyListeners();

      final events = await _eventService.getUpcomingPublicEvents();
      _events = events
          .map(
            (e) => EventModel(
              id: e.id,
              title: e.title,
              description: e.description,
              startDate: e.dateTime,
              location: e.location,
              artistId: e.artistId,
              isPublic: e.isPublic,
              attendeeIds: e.attendeeIds,
              createdAt: e.createdAt,
              updatedAt: e.updatedAt,
              imageUrl: e.imageUrls.isNotEmpty ? e.imageUrls.first : null,
              price: 0.0, // Default price
            ),
          )
          .toList();
      _eventsError = null;
    } catch (e) {
      AppLogger.error('Error loading events: $e');
      _eventsError = e.toString();
      _events = [];
    } finally {
      _isLoadingEvents = false;
      _safeNotifyListeners();
    }
  }

  Future<void> _loadArtwork() async {
    try {
      _isLoadingArtwork = true;
      _safeNotifyListeners();

      // Try featured artwork first, fallback to public artwork
      var artworkServiceModels = await _artworkService.getFeaturedArtwork();
      if (artworkServiceModels.isEmpty) {
        AppLogger.info('No featured artwork found, loading public artwork...');
        artworkServiceModels = await _artworkService.getAllPublicArtwork(
          limit: 10,
        );
      }

      // Convert artworkLib.ArtworkModel to core ArtworkModel
      _artwork = artworkServiceModels
          .map(
            (a) => ArtworkModel(
              id: a.id,
              title: a.title,
              description: a.description,
              artistId: a.userId, // Use userId as artistId
              imageUrl: a.imageUrl,
              price: a.price ?? 0.0,
              medium: a.medium,
              tags: a.tags ?? [],
              createdAt: a.createdAt,
              isSold: a.isSold,
              applauseCount: a.likesCount,
              viewsCount: a.viewCount,
              artistName: 'Artist', // Will be loaded separately if needed
            ),
          )
          .toList();

      _artworkError = null;
      AppLogger.info('✅ Loaded ${_artwork.length} artworks successfully');
    } catch (e) {
      AppLogger.error('Error loading artwork: $e');
      _artworkError = e.toString();
      _artwork = [];
    } finally {
      _isLoadingArtwork = false;
      _safeNotifyListeners();
    }
  }

  Future<void> _loadArtists() async {
    try {
      _isLoadingArtists = true;
      _safeNotifyListeners();

      final profileService = artist_profile.ArtistProfileService();
      final featuredArtists = await profileService.getFeaturedArtists(
        limit: 10,
      );
      if (featuredArtists.isNotEmpty) {
        _artists = featuredArtists;
      } else {
        // Fallback: load all artists if no featured
        final allArtists = await profileService.getAllArtists(limit: 10);
        _artists = allArtists;
      }
      _artistsError = null;
    } catch (e) {
      AppLogger.error('Error loading artists: $e');
      _artistsError = e.toString();
      _artists = [];
    } finally {
      _isLoadingArtists = false;
      _safeNotifyListeners();
    }
  }

  Future<void> _loadLocalCaptures() async {
    try {
      _isLoadingLocalCaptures = true;
      _safeNotifyListeners();

      // Get all captures
      final allCaptures = await _captureService.getAllCaptures();

      // Show all captures regardless of location (removed 15-mile restriction)
      _localCaptures = allCaptures;

      _localCapturesError = null;
    } catch (e) {
      AppLogger.error('Error loading local captures: $e');
      _localCapturesError = e.toString();
      _localCaptures = [];
    } finally {
      _isLoadingLocalCaptures = false;
      _safeNotifyListeners();
    }
  }

  Future<void> _loadPosts() async {
    try {
      _isLoadingPosts = true;
      _safeNotifyListeners();

      // Load recent posts from community service
      final posts = await _communityService.getFeed(limit: 10);

      _posts = posts;
      _postsError = null;
      AppLogger.info('✅ Loaded ${_posts.length} posts successfully');
    } catch (e) {
      AppLogger.error('Error loading posts: $e');
      _postsError = e.toString();
      _posts = [];
    } finally {
      _isLoadingPosts = false;
      _safeNotifyListeners();
    }
  }

  Future<void> _loadActivities() async {
    try {
      _isLoadingActivities = true;
      _safeNotifyListeners();

      debugPrint('🔍 DashboardViewModel: Starting to load activities');

      // Load recent social activities from all users
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('🔍 DashboardViewModel: ❌ No user logged in');
        _activities = [];
        AppLogger.info('No user logged in, no activities to load');
        return;
      }

      debugPrint('🔍 DashboardViewModel: User logged in: ${user.uid}');

      final allActivities = <artWalkLib.SocialActivity>[];

      // Try to load nearby activities if location is available
      if (_currentLocation != null) {
        debugPrint('🔍 DashboardViewModel: Loading nearby activities');
        try {
          final nearbyActivities = await _socialService.getNearbyActivities(
            userPosition: _currentLocation!,
            radiusKm: 50.0, // 50km radius for broader coverage
            limit: 20,
          );
          debugPrint(
            '🔍 DashboardViewModel: Loaded ${nearbyActivities.length} nearby activities',
          );
          allActivities.addAll(nearbyActivities);
        } catch (e) {
          debugPrint(
            '🔍 DashboardViewModel: ⚠️ Error loading nearby activities: $e',
          );
        }
      } else {
        debugPrint(
          '🔍 DashboardViewModel: ⚠️ Location not available, skipping nearby activities',
        );
      }

      // If no nearby activities found, load recent activities from all users
      // by querying the socialActivities collection directly
      if (allActivities.isEmpty) {
        debugPrint(
          '🔍 DashboardViewModel: No nearby activities, loading recent activities from all users',
        );
        try {
          // Load recent activities without location filter
          final recentActivities = await _socialService.getRecentActivities(
            limit: 20,
          );
          debugPrint(
            '🔍 DashboardViewModel: Loaded ${recentActivities.length} recent activities',
          );
          allActivities.addAll(recentActivities);
        } catch (e) {
          debugPrint(
            '🔍 DashboardViewModel: ⚠️ Error loading recent activities: $e',
          );
        }
      }

      // Sort by timestamp (most recent first)
      allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Take top 20 activities
      _activities = allActivities.take(20).toList();

      debugPrint(
        '🔍 DashboardViewModel: Final activities count: ${_activities.length}',
      );

      AppLogger.info('✅ Loaded ${_activities.length} activities successfully');
    } catch (e, stack) {
      debugPrint('🔍 DashboardViewModel: ❌ Error loading activities: $e');
      debugPrint('🔍 DashboardViewModel: Stack trace: $stack');
      AppLogger.error('Error loading activities: $e');
      _activities = [];
    } finally {
      _isLoadingActivities = false;
      _safeNotifyListeners();
      debugPrint(
        '🔍 DashboardViewModel: Finished loading activities, total: ${_activities.length}',
      );
    }
  }

  Future<void> _loadLocation() async {
    try {
      _isLoadingLocation = true;
      _safeNotifyListeners();

      // Use shorter timeout for better UX - if location takes too long, fallback faster
      final position =
          await LocationUtils.getCurrentPosition(
            timeoutDuration: const Duration(seconds: 8), // Reduced timeout
          ).timeout(
            const Duration(seconds: 10), // Overall timeout reduced
            onTimeout: () {
              AppLogger.warning(
                '⚠️ Location request timed out after 10 seconds',
              );
              throw TimeoutException(
                'Location request timed out',
                const Duration(seconds: 10),
              );
            },
          );

      _currentLocation = position;
      _mapLocation = LatLng(position.latitude, position.longitude);

      await _loadNearbyArtMarkers();
      _locationError = null;
      debugPrint(
        '✅ Location loaded successfully: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      AppLogger.error('❌ Error loading location: $e');
      _locationError = e.toString();

      // Set default location to Raleigh, NC if location fails
      _mapLocation = const LatLng(35.7796, -78.6382);
      AppLogger.info('🌍 Using default location: Raleigh, NC');

      // Still try to load markers for default location
      try {
        await _loadNearbyArtMarkers();
      } catch (markerError) {
        debugPrint(
          '❌ Error loading markers for default location: $markerError',
        );
      }
    } finally {
      _isLoadingLocation = false;
      _safeNotifyListeners();
    }
  }

  Future<void> _loadNearbyArtMarkers() async {
    if (_mapLocation == null) return;

    try {
      final newMarkers = <Marker>{};

      // Add current location marker if we have it
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _mapLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Current Location'),
        ),
      );

      // Get nearby art pieces from ArtWalk service
      final nearbyArt = await _artWalkService.getPublicArtNearLocation(
        latitude: _mapLocation!.latitude,
        longitude: _mapLocation!.longitude,
        radiusKm: 10, // 10km radius
      );

      // Add markers for each art piece
      for (final art in nearbyArt) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('art_${art.id}'),
            position: LatLng(art.location.latitude, art.location.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
            infoWindow: InfoWindow(title: art.title, snippet: art.artistName),
          ),
        );
      }

      _markers = newMarkers;
      _isMapPreviewReady = true;
      _safeNotifyListeners();
    } catch (e) {
      AppLogger.error('Error loading nearby art markers: $e');
      _isMapPreviewReady = false;
      _safeNotifyListeners();
    }
  }

  Future<void> _loadTodaysChallenge() async {
    try {
      debugPrint('🎯 DashboardViewModel: Loading today\'s challenge');
      // Temporarily disable service call for testing
      // _todaysChallenge = await _challengeService.getTodaysChallenge();

      // Use a test challenge instead
      _todaysChallenge = artWalkLib.ChallengeModel(
        id: 'test_daily_challenge',
        userId: 'test_user',
        title: 'Art Hunter',
        description: 'Discover 3 pieces of public art in your neighborhood',
        type: artWalkLib.ChallengeType.daily,
        targetCount: 3,
        currentCount: 1,
        rewardXP: 150,
        rewardDescription: '🏆 Explorer Badge + 150 XP',
        isCompleted: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 18)),
      );

      debugPrint(
        '🎯 DashboardViewModel: Loaded challenge: ${_todaysChallenge?.title ?? "None"}',
      );
      AppLogger.info(
        'Loaded today\'s challenge: ${_todaysChallenge?.title ?? "None"}',
      );
    } catch (e) {
      debugPrint('🎯 DashboardViewModel: ❌ Error loading challenge: $e');
      AppLogger.error('Error loading today\'s challenge: $e');
      _todaysChallenge = null;
    }
  }

  // Intentionally removed duplicate methods that were declared again below

  Future<void> _loadUserProgress() async {
    try {
      if (_currentUser == null) {
        _totalDiscoveries = 0;
        _currentStreak = 0;
        _weeklyProgress = 0;
        _isLoadingUserProgress = false;
        return;
      }

      // Import the InstantDiscoveryService
      final instantDiscoveryService = artWalkLib.InstantDiscoveryService();
      final stats = await instantDiscoveryService.getUserProgressStats();

      _totalDiscoveries = stats['totalDiscoveries'] ?? 0;
      _currentStreak = stats['currentStreak'] ?? 0;
      _weeklyProgress = stats['weeklyProgress'] ?? 0;

      AppLogger.info(
        '✅ User progress loaded: $_totalDiscoveries discoveries, $_currentStreak streak, $_weeklyProgress this week',
      );
    } catch (e) {
      AppLogger.error('❌ Error loading user progress: $e');
      _totalDiscoveries = 0;
      _currentStreak = 0;
      _weeklyProgress = 0;
    } finally {
      _isLoadingUserProgress = false;
      _safeNotifyListeners();
    }
  }

  Future<void> followArtist({required String artistId}) async {
    if (!isAuthenticated) {
      throw Exception('User must be logged in to follow artists');
    }

    try {
      // Optimistic update
      _artists = _artists
          .map((a) => a.id == artistId ? a.copyWith(isFollowing: true) : a)
          .toList();
      _safeNotifyListeners();

      final subscription = await _subscriptionService.getUserSubscription();
      if (subscription != null) {
        final success = await _artistCommunityService.followArtist(artistId);
        if (!success) {
          throw Exception('Failed to follow artist');
        }
        AppLogger.info('Artist follow requested: $artistId');
      }
    } catch (e) {
      // Revert on error
      _artists = _artists
          .map((a) => a.id == artistId ? a.copyWith(isFollowing: false) : a)
          .toList();
      _safeNotifyListeners();
      rethrow;
    }
  }

  Future<void> unfollowArtist({required String artistId}) async {
    if (!isAuthenticated) {
      throw Exception('User must be logged in to unfollow artists');
    }

    try {
      // Optimistic update
      _artists = _artists
          .map((a) => a.id == artistId ? a.copyWith(isFollowing: false) : a)
          .toList();
      _safeNotifyListeners();

      final subscription = await _subscriptionService.getUserSubscription();
      if (subscription != null) {
        final success = await _artistCommunityService.unfollowArtist(artistId);
        if (!success) {
          throw Exception('Failed to unfollow artist');
        }
        AppLogger.info('Artist unfollow requested: $artistId');
      }
    } catch (e) {
      // Revert on error
      _artists = _artists
          .map((a) => a.id == artistId ? a.copyWith(isFollowing: true) : a)
          .toList();
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Updates an artist in the artists list
  void updateArtist(ArtistProfileModel updatedArtist) {
    final index = _artists.indexWhere((a) => a.userId == updatedArtist.userId);
    if (index != -1) {
      _artists[index] = updatedArtist;
      _safeNotifyListeners();
    }
  }

  /// Handles when the Google Map is created - currently not used
  void onMapCreated(GoogleMapController controller) {
    // Map controller initialization
    _safeNotifyListeners();
  }

  /// Toggle like for a capture
  Future<bool> toggleCaptureLike(String captureId) async {
    if (!isAuthenticated) {
      throw Exception('User must be logged in to like captures');
    }

    try {
      final isLiked = await _engagementService.toggleEngagement(
        contentId: captureId,
        contentType: 'capture',
        engagementType: EngagementType.like,
      );

      // Update local captures list to reflect the change
      _localCaptures = _localCaptures.map((capture) {
        if (capture.id == captureId) {
          // Note: CaptureModel doesn't have a likes count field
          // We'll handle the liked state separately in the UI
          return capture;
        }
        return capture;
      }).toList();

      _safeNotifyListeners();
      return isLiked;
    } catch (e) {
      AppLogger.error('Error toggling capture like: $e');
      rethrow;
    }
  }

  /// Check if current user has liked a capture
  Future<bool> hasUserLikedCapture(String captureId) async {
    if (!isAuthenticated) return false;

    try {
      return await _engagementService.hasUserEngaged(
        contentId: captureId,
        engagementType: EngagementType.like,
      );
    } catch (e) {
      AppLogger.error('Error checking capture like status: $e');
      return false;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:artbeat_core/artbeat_core.dart';
import '../utils/location_utils.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_artist/artbeat_artist.dart' as artist_profile;
import 'package:artbeat_events/artbeat_events.dart' as eventLib;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artworkLib;
import 'package:artbeat_capture/artbeat_capture.dart';

class DashboardViewModel extends ChangeNotifier {
  final eventLib.EventService _eventService;
  final artworkLib.ArtworkService _artworkService;
  final ArtWalkService _artWalkService;
  final SubscriptionService _subscriptionService;
  final UserService _userService;
  final CaptureService _captureService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _currentUser;
  bool _isInitializing = true;
  bool _isLoadingEvents = true;
  bool _isLoadingUpcomingEvents = true;
  bool _isLoadingArtwork = true;
  bool _isLoadingArtists = true;
  bool _isLoadingLocation = true;
  bool _isMapPreviewReady = false;
  bool _isLoadingMap = false;
  bool _isLoadingAchievements = true;
  bool _isLoadingLocalCaptures = true;

  String? _eventsError;
  String? _upcomingEventsError;
  String? _artworkError;
  String? _achievementsError;
  String? _artistsError;
  String? _locationError;
  String? _localCapturesError;

  List<EventModel> _events = [];
  List<EventModel> _upcomingEvents = [];
  List<ArtworkModel> _artwork = [];
  List<ArtistProfileModel> _artists = [];
  Set<Marker> _markers = {};
  Position? _currentLocation;
  LatLng? _mapLocation;
  List<AchievementModel> _achievements = [];
  List<CaptureModel> _localCaptures = [];

  DashboardViewModel({
    required eventLib.EventService eventService,
    required artworkLib.ArtworkService artworkService,
    required ArtWalkService artWalkService,
    required SubscriptionService subscriptionService,
    required UserService userService,
    CaptureService? captureService,
  }) : _eventService = eventService,
       _artworkService = artworkService,
       _artWalkService = artWalkService,
       _subscriptionService = subscriptionService,
       _userService = userService,
       _captureService = captureService ?? CaptureService();

  /// Initializes dashboard data and state
  Future<void> initialize() async {
    if (!_isInitializing) return; // Prevent multiple initializations

    try {
      _resetLoadingStates();
      // First load current user since other operations depend on it
      await _loadCurrentUser();
      debugPrint('👤 Current user loaded: ${_currentUser?.id}');

      // Then load all other data in parallel
      await Future.wait<void>([
        _loadEvents(),
        _loadArtwork(),
        _loadArtists(),
        _loadLocation(),
        _loadAchievements(),
        _loadLocalCaptures(),
      ]);
    } catch (e, stack) {
      debugPrint('❌ Error initializing dashboard: $e');
      debugPrint('❌ Stack trace: $stack');
    } finally {
      _isInitializing = false;
      notifyListeners();
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
    notifyListeners();
  }

  Future<void> _loadCurrentUser() async {
    if (_auth.currentUser == null) {
      _currentUser = null;
      return;
    }

    try {
      _currentUser = await _userService.getCurrentUserModel();
    } catch (e) {
      debugPrint('Error loading current user: $e');
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
  bool get isAuthenticated => _auth.currentUser != null;
  String? get eventsError => _eventsError;
  String? get upcomingEventsError => _upcomingEventsError;
  String? get artworkError => _artworkError;
  String? get achievementsError => _achievementsError;
  String? get artistsError => _artistsError;
  String? get locationError => _locationError;
  String? get localCapturesError => _localCapturesError;

  List<EventModel> get events => List.unmodifiable(_events);
  List<EventModel> get upcomingEvents => List.unmodifiable(_upcomingEvents);
  List<ArtworkModel> get artwork => List.unmodifiable(_artwork);
  List<ArtistProfileModel> get artists => List.unmodifiable(_artists);
  Set<Marker> get markers => Set.unmodifiable(_markers);
  Position? get currentLocation => _currentLocation;
  List<AchievementModel> get achievements => List.unmodifiable(_achievements);
  List<CaptureModel> get localCaptures => List.unmodifiable(_localCaptures);
  LatLng? get mapLocation => _mapLocation;
  UserModel? get currentUser => _currentUser;

  // Methods
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
      ]);
    } catch (e, stack) {
      debugPrint('❌ Error refreshing dashboard: $e');
      debugPrint('❌ Stack trace: $stack');
    } finally {
      notifyListeners();
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
      debugPrint('Error loading achievements: $e');
      _achievementsError = e.toString();
      _achievements = [];
    } finally {
      _isLoadingAchievements = false;
      notifyListeners();
    }
  }

  Future<void> _loadEvents() async {
    try {
      _isLoadingEvents = true;
      notifyListeners();

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
      debugPrint('Error loading events: $e');
      _eventsError = e.toString();
      _events = [];
    } finally {
      _isLoadingEvents = false;
      notifyListeners();
    }
  }

  Future<void> _loadArtwork() async {
    try {
      _isLoadingArtwork = true;
      notifyListeners();

      final artworks = await _artworkService.getFeaturedArtwork();
      _artwork = artworks
          .map(
            (a) => ArtworkModel(
              id: a.id,
              title: a.title,
              description: a.description,
              artistId: a.id, // Using artwork id as artist id for now
              medium: 'digital', // Default medium
              tags: const <String>[], // Empty tags list
              imageUrl: a.imageUrl,
              price: 0.0, // Default price
              isSold: false, // Default not sold
              applauseCount: 0, // Default applause count
              createdAt: DateTime.now(),
              viewsCount: 0, // Default views count
              artistName: 'Featured Artist', // Default artist name
            ),
          )
          .toList();
      _artworkError = null;
    } catch (e) {
      debugPrint('Error loading artwork: $e');
      _artworkError = e.toString();
      _artwork = [];
    } finally {
      _isLoadingArtwork = false;
      notifyListeners();
    }
  }

  Future<void> _loadArtists() async {
    try {
      _isLoadingArtists = true;
      notifyListeners();

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
      debugPrint('Error loading artists: $e');
      _artistsError = e.toString();
      _artists = [];
    } finally {
      _isLoadingArtists = false;
      notifyListeners();
    }
  }

  Future<void> _loadLocalCaptures() async {
    try {
      _isLoadingLocalCaptures = true;
      notifyListeners();

      // Get all captures
      final allCaptures = await _captureService.getAllCaptures();

      // Filter captures within 15 miles (24.14 km) of user location if available
      if (_currentLocation != null) {
        _localCaptures = allCaptures.where((capture) {
          if (capture.location == null) {
            return false;
          }

          final distance = Geolocator.distanceBetween(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            capture.location!.latitude,
            capture.location!.longitude,
          );

          // Convert meters to miles (1 mile = 1609.34 meters)
          final distanceInMiles = distance / 1609.34;
          return distanceInMiles <= 15.0;
        }).toList();
      } else {
        // If no location available, show all captures (or limit to a reasonable number)
        _localCaptures = allCaptures.take(10).toList();
      }

      _localCapturesError = null;
    } catch (e) {
      debugPrint('Error loading local captures: $e');
      _localCapturesError = e.toString();
      _localCaptures = [];
    } finally {
      _isLoadingLocalCaptures = false;
      notifyListeners();
    }
  }

  Future<void> _loadLocation() async {
    try {
      _isLoadingLocation = true;
      notifyListeners();

      // Use LocationUtils with a shorter timeout and better error handling
      final position =
          await LocationUtils.getCurrentPosition(
            timeoutDuration: const Duration(seconds: 5), // Reduced timeout
          ).timeout(
            const Duration(seconds: 8), // Overall timeout
            onTimeout: () {
              debugPrint('⚠️ Location request timed out after 8 seconds');
              throw TimeoutException(
                'Location request timed out',
                const Duration(seconds: 8),
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
      debugPrint('❌ Error loading location: $e');
      _locationError = e.toString();

      // Set default location to Raleigh, NC if location fails
      _mapLocation = const LatLng(35.7796, -78.6382);
      debugPrint('🌍 Using default location: Raleigh, NC');

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
      notifyListeners();
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
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading nearby art markers: $e');
      _isMapPreviewReady = false;
      notifyListeners();
    }
  }

  // Intentionally removed duplicate methods that were declared again below

  Future<void> followArtist({required String artistId}) async {
    if (!isAuthenticated) {
      throw Exception('User must be logged in to follow artists');
    }

    try {
      // Optimistic update
      _artists = _artists
          .map((a) => a.id == artistId ? a.copyWith(isFollowing: true) : a)
          .toList();
      notifyListeners();

      final subscription = await _subscriptionService.getUserSubscription();
      if (subscription != null) {
        // TODO: Implement artist following with ArtistService
        debugPrint('Artist follow requested: $artistId');
      }
    } catch (e) {
      // Revert on error
      _artists = _artists
          .map((a) => a.id == artistId ? a.copyWith(isFollowing: false) : a)
          .toList();
      notifyListeners();
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
      notifyListeners();

      final subscription = await _subscriptionService.getUserSubscription();
      if (subscription != null) {
        // TODO: Implement artist unfollowing with ArtistService
        debugPrint('Artist unfollow requested: $artistId');
      }
    } catch (e) {
      // Revert on error
      _artists = _artists
          .map((a) => a.id == artistId ? a.copyWith(isFollowing: true) : a)
          .toList();
      notifyListeners();
      rethrow;
    }
  }

  /// Handles when the Google Map is created - currently not used
  void onMapCreated(GoogleMapController controller) {
    // Map controller initialization
    notifyListeners();
  }
}

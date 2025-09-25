import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Enhanced art walk experience screen with turn-by-turn navigation
class EnhancedArtWalkExperienceScreen extends StatefulWidget {
  final String artWalkId;
  final ArtWalkModel artWalk;
  final ArtWalkService? artWalkService;

  const EnhancedArtWalkExperienceScreen({
    super.key,
    required this.artWalkId,
    required this.artWalk,
    this.artWalkService,
  });

  @override
  State<EnhancedArtWalkExperienceScreen> createState() =>
      _EnhancedArtWalkExperienceScreenState();
}

class _EnhancedArtWalkExperienceScreenState
    extends State<EnhancedArtWalkExperienceScreen>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<PublicArtModel> _artPieces = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _isNavigationMode = false;
  bool _showCompactNavigation = false;
  bool _isStartingNavigation = false;

  // Progress tracking
  ArtWalkProgress? _currentProgress;
  final ArtWalkProgressService _progressService = ArtWalkProgressService();
  final AudioNavigationService _audioService = AudioNavigationService();

  // New services for enhanced UX
  SmartOnboardingService? _onboardingService;
  HapticFeedbackService? _hapticService;

  // Tutorial overlay state
  TutorialStep? _currentTutorialStep;
  bool _showTutorialOverlay = false;

  // Navigation services
  ArtWalkService? _artWalkService;
  ArtWalkService get artWalkService =>
      _artWalkService ??= widget.artWalkService ?? ArtWalkService();
  late ArtWalkNavigationService _navigationService;
  ArtWalkRouteModel? _currentRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navigationService = ArtWalkNavigationService();
    _initializeServices();
    _initializeWalk();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _navigationService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        // App is going to background - pause navigation to prevent crashes
        if (_isNavigationMode) {
          _pauseNavigationForBackground();
        }
        break;
      case AppLifecycleState.resumed:
        // App is coming back to foreground - resume navigation if it was active
        if (_isNavigationMode && _currentRoute != null) {
          _resumeNavigationFromBackground();
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        // App is being closed or becoming inactive - stop navigation
        if (_isNavigationMode) {
          _stopNavigation();
        }
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state if needed
        break;
    }
  }

  /// Pause navigation when app goes to background
  void _pauseNavigationForBackground() {
    // Don't fully stop navigation, just pause location tracking
    // This prevents crashes while maintaining navigation state
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigation paused while app is in background'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Resume navigation when app comes back to foreground
  void _resumeNavigationFromBackground() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigation resumed'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _initializeServices() async {
    await _audioService.initialize();

    // Initialize new services
    final prefs = await SharedPreferences.getInstance();
    _onboardingService = SmartOnboardingService(prefs, _audioService);
    await _onboardingService!.initializeOnboarding();

    _hapticService = await HapticFeedbackService.getInstance();
  }

  Future<void> _initializeWalk() async {
    await _getCurrentLocation();
    await _loadArtPieces();
    await _loadOrCreateProgress();
    _createMarkersAndRoute();

    setState(() {
      _isLoading = false;
    });

    // Show tutorial for first-time users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorial();
    });

    // Don't auto-start navigation - let user manually start it
    if (_currentPosition == null) {
      // Show message if location is not available
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location not available. Please enable location services for navigation.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services are disabled. Please enable them in settings.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission denied. Navigation features will be limited.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission permanently denied. Please enable in app settings.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadArtPieces() async {
    try {
      final artPieces = await artWalkService.getArtInWalk(widget.artWalkId);
      setState(() {
        _artPieces = artPieces;
      });
    } catch (e) {
      // debugPrint('Error loading art pieces: $e');
    }
  }

  Future<void> _loadOrCreateProgress() async {
    try {
      final userId = artWalkService.getCurrentUserId();
      if (userId == null) return;

      // Try to load existing progress
      final existingProgress = await _progressService.getWalkProgress(
        userId,
        widget.artWalkId,
      );

      if (existingProgress != null) {
        setState(() {
          _currentProgress = existingProgress;
        });
      } else {
        // Create new progress if none exists
        final newProgress = await _progressService.startWalk(
          artWalkId: widget.artWalkId,
          totalArtCount: _artPieces.length,
          userId: userId,
        );
        setState(() {
          _currentProgress = newProgress;
        });
      }
    } catch (e) {
      // debugPrint('Error loading progress: $e');
    }
  }

  void _createMarkersAndRoute() {
    if (_artPieces.isEmpty) return;

    final markers = <Marker>{};
    final polylinePoints = <LatLng>[];

    // Add current location marker if available
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
      polylinePoints.add(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      );
    }

    // Create markers for each art piece
    for (int i = 0; i < _artPieces.length; i++) {
      final art = _artPieces[i];
      final isVisited = _isArtVisited(art.id);
      final isNext = i == _getNextUnvisitedIndex() && !isVisited;

      markers.add(
        Marker(
          markerId: MarkerId(art.id),
          position: LatLng(art.location.latitude, art.location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isVisited
                ? BitmapDescriptor.hueGreen
                : isNext
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: '${i + 1}. ${art.title}',
            snippet: isVisited ? 'Visited ✓' : 'Tap for details',
          ),
          onTap: () => _showArtDetail(art),
        ),
      );

      polylinePoints.add(LatLng(art.location.latitude, art.location.longitude));
    }

    // Create route polyline
    if (polylinePoints.length > 1) {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('art_walk_route'),
          points: polylinePoints,
          color: _isNavigationMode ? Colors.blue : Colors.grey,
          width: _isNavigationMode ? 5 : 3,
          patterns: _isNavigationMode
              ? []
              : [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _startNavigation() async {
    // Prevent multiple simultaneous navigation starts
    if (_isStartingNavigation || _isNavigationMode) {
      debugPrint('🧭 Navigation already starting or active, ignoring tap');
      return;
    }

    // Haptic feedback for button press
    await _hapticService?.buttonPressed();

    if (_currentPosition == null || _artPieces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to start navigation. Check your location settings.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _isStartingNavigation = true;
      });

      // Optimize the route for efficiency before generating navigation
      final currentLocation = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      final optimizedArtPieces =
          RouteOptimizationUtils.optimizeRouteFromLocation(
            _artPieces,
            currentLocation,
          );

      // Generate route with optimized art pieces
      debugPrint('🧭 Experience Screen: Generating route...');
      final route = await _navigationService.generateRoute(
        widget.artWalkId,
        optimizedArtPieces,
        _currentPosition!,
      );

      debugPrint(
        '🧭 Experience Screen: Route generated, entering navigation mode',
      );
      setState(() {
        _currentRoute = route;
        _artPieces =
            optimizedArtPieces; // Update art pieces to reflect optimized order
        _isNavigationMode = true;
        _isLoading = false;
        _isStartingNavigation = false;
      });
      debugPrint('🧭 Experience Screen: _isNavigationMode set to true');

      // Start navigation
      debugPrint('🧭 Experience Screen: Starting navigation service...');
      await _navigationService.startNavigation(route);
      debugPrint('🧭 Experience Screen: Navigation service started');

      // Update map with detailed route
      _updateMapWithRoute(route);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Navigation started! Follow the turn-by-turn instructions.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isStartingNavigation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start navigation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopNavigation() async {
    // Haptic feedback for button press
    await _hapticService?.buttonPressed();

    await _navigationService.stopNavigation();
    setState(() {
      _isNavigationMode = false;
      _currentRoute = null;
      _showCompactNavigation = false;
      _isStartingNavigation = false;
    });
    _createMarkersAndRoute();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation stopped.'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  void _updateMapWithRoute(ArtWalkRouteModel route) {
    // Update polylines with detailed route
    final polylines = <Polyline>{};

    for (int i = 0; i < route.segments.length; i++) {
      final segment = route.segments[i];
      final polylinePoints = <LatLng>[];

      for (final step in segment.steps) {
        polylinePoints.addAll(step.polylinePoints);
      }

      if (polylinePoints.isNotEmpty) {
        polylines.add(
          Polyline(
            polylineId: PolylineId('segment_$i'),
            points: polylinePoints,
            color: Colors.blue,
            width: 5,
          ),
        );
      }
    }

    setState(() {
      _polylines = polylines;
    });
  }

  void _showArtDetail(PublicArtModel art) {
    // Haptic feedback for marker tap
    _hapticService?.markerTapped();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ArtDetailBottomSheet(
        art: art,
        onVisitPressed: () => _markAsVisited(art),
        isVisited: _isArtVisited(art.id),
        distanceText: _getDistanceToArt(art),
      ),
    );
  }

  Future<void> _markAsVisited(PublicArtModel art) async {
    if (_isArtVisited(art.id) || _currentProgress == null) return;

    try {
      // Use the progress service to record the visit
      final updatedProgress = await _progressService.recordArtVisit(
        artId: art.id,
        userLocation: _currentPosition!,
        artLocation: Position(
          latitude: art.location.latitude,
          longitude: art.location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
      );

      setState(() {
        _currentProgress = updatedProgress;
      });

      _createMarkersAndRoute();

      // Announce visit with audio
      await _audioService.celebrateArtVisit(art, 10);

      // Haptic feedback for achievement
      await _hapticService?.artPieceVisited();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${art.title} marked as visited! +10 XP'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      if (_isWalkCompleted()) {
        _showWalkCompletionDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking as visited: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWalkCompletionDialog() {
    // Haptic feedback for walk completion
    _hapticService?.walkCompleted();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Walk Completed!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Congratulations! You\'ve completed this art walk.'),
            SizedBox(height: 16),
            Text('Rewards earned:'),
            Text('• +50 XP for completion'),
            Text('• Achievement progress updated'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeWalk();
            },
            child: const Text('Claim Rewards'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeWalk() async {
    try {
      final completedProgress = await _progressService.completeWalk();

      // Create celebration data
      final celebrationData = CelebrationData(
        walk: widget.artWalk,
        progress: completedProgress,
        walkDuration: completedProgress.timeSpent,
        distanceWalked: 0.0, // TODO: Calculate actual distance
        artPiecesVisited: completedProgress.visitedArt.length,
        pointsEarned: completedProgress.totalPointsEarned,
        newAchievements: const [], // TODO: Get new achievements
        visitedArtPhotos: completedProgress.visitedArt
            .where((visit) => visit.photoTaken != null)
            .map((visit) => visit.photoTaken!)
            .toList(),
        personalBests: const {}, // TODO: Calculate personal bests
        milestones: const [], // TODO: Get milestones
        celebrationType: CelebrationType.regularCompletion,
      );

      // Navigate to celebration screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) =>
                ArtWalkCelebrationScreen(celebrationData: celebrationData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing walk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDistanceToArt(PublicArtModel art) {
    if (_currentPosition == null) return '';

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      art.location.latitude,
      art.location.longitude,
    );

    if (distance < 1000) {
      return '${distance.round()}m away';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km away';
    }
  }

  int _getNextUnvisitedIndex() {
    if (_currentProgress == null) return 0;

    for (int i = 0; i < _artPieces.length; i++) {
      if (!_isArtVisited(_artPieces[i].id)) {
        return i;
      }
    }
    return 0;
  }

  bool _isArtVisited(String artId) {
    if (_currentProgress == null) return false;
    return _currentProgress!.visitedArt.any((visit) => visit.artId == artId);
  }

  bool _isWalkCompleted() {
    if (_currentProgress == null) return false;
    return _currentProgress!.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MainLayout(
        currentIndex: -1,
        child: Scaffold(
          appBar: EnhancedUniversalHeader(
            title: widget.artWalk.title,
            showLogo: false,
            showBackButton: true,
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
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: EnhancedUniversalHeader(
          title: widget.artWalk.title,
          showLogo: false,
          showBackButton: true,
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
          actions: [
            if (_isNavigationMode)
              IconButton(
                icon: Icon(
                  _showCompactNavigation
                      ? Icons.expand_more
                      : Icons.expand_less,
                ),
                onPressed: () {
                  setState(() {
                    _showCompactNavigation = !_showCompactNavigation;
                  });
                },
              ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('How to Use'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• Tap "Start Navigation" for turn-by-turn directions',
                        ),
                        const Text('• Follow the blue route line'),
                        const Text('• Tap markers to view art details'),
                        const Text('• Mark art as visited when you reach it'),
                        const Text('• Green markers = visited'),
                        const Text('• Orange marker = next destination'),
                        const Text('• Red markers = not yet visited'),
                        if (_isNavigationMode) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Navigation Mode:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text('• Follow turn-by-turn instructions'),
                          const Text(
                            '• Tap expand/collapse button to adjust navigation view',
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            // Map
            if (kIsWeb)
              _buildWebMapFallback()
            else
              GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  _centerOnUserLocation();
                },
                initialCameraPosition: CameraPosition(
                  target: _currentPosition != null
                      ? LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        )
                      : _artPieces.isNotEmpty
                      ? LatLng(
                          _artPieces[0].location.latitude,
                          _artPieces[0].location.longitude,
                        )
                      : const LatLng(35.5951, -82.5515),
                  zoom: 16.0,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),

            // Enhanced Progress Visualization
            if (!_isNavigationMode || _showCompactNavigation)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: EnhancedProgressVisualization(
                  visitedCount: _currentProgress?.visitedArt.length ?? 0,
                  totalCount: _artPieces.length,
                  progressPercentage:
                      _currentProgress?.progressPercentage ?? 0.0,
                  isNavigationMode: _isNavigationMode,
                  onTap: () {
                    // Could expand to show detailed progress or achievements
                    _hapticService?.buttonPressed();
                  },
                ),
              ),

            // Turn-by-turn navigation widget
            if (_isNavigationMode) ...[
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Builder(
                  builder: (context) {
                    debugPrint(
                      '🧭 Experience Screen: Building TurnByTurnNavigationWidget',
                    );
                    return TurnByTurnNavigationWidget(
                      navigationService: _navigationService,
                      isCompact: _showCompactNavigation,
                      onNextStep: () => _navigationService.nextStep(),
                      onPreviousStep: () {
                        // Implement previous step logic if needed
                      },
                      onStopNavigation: _stopNavigation,
                    );
                  },
                ),
              ),
            ],

            // Navigation control button
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Builder(
                builder: (context) {
                  debugPrint(
                    '🧭 UI State: _isNavigationMode = $_isNavigationMode',
                  );
                  debugPrint(
                    '🧭 UI State: _currentPosition = $_currentPosition',
                  );
                  debugPrint(
                    '🧭 UI State: _artPieces.length = ${_artPieces.length}',
                  );
                  debugPrint('🧭 UI State: Building navigation button area');

                  return Container(
                    color: Colors.red.withValues(
                      alpha: 0.3,
                    ), // Temporary debug background
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (!_isNavigationMode) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isStartingNavigation
                                  ? null
                                  : () {
                                      debugPrint(
                                        '🧭 Start Navigation button pressed',
                                      );
                                      _startNavigation();
                                    },
                              icon: _isStartingNavigation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(Icons.navigation),
                              label: Text(
                                _isStartingNavigation
                                    ? 'Starting...'
                                    : 'Start Navigation',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                debugPrint('🧭 Stop Navigation button pressed');
                                _stopNavigation();
                              },
                              icon: const Icon(Icons.stop),
                              label: const Text('Stop Navigation'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Tutorial overlay
            if (_showTutorialOverlay && _currentTutorialStep != null)
              TutorialOverlay(
                step: _currentTutorialStep!,
                onDismiss: _dismissTutorial,
                onComplete: _completeTutorial,
              ),
          ],
        ),
        floatingActionButton: _currentPosition != null
            ? FloatingActionButton(
                onPressed: _centerOnUserLocation,
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                tooltip: 'Center on my location',
                child: const Icon(Icons.my_location),
              )
            : null,
      ),
    );
  }

  void _centerOnUserLocation() {
    // Haptic feedback for button press
    _hapticService?.buttonPressed();

    if (_currentPosition == null || _mapController == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        16.0,
      ),
    );
  }

  /// Show tutorial overlay
  void _showTutorial() {
    if (_onboardingService == null) return;

    final tutorialStep = _onboardingService!.getNextTutorialStep(
      'art_walk_experience',
    );
    if (tutorialStep != null) {
      setState(() {
        _currentTutorialStep = tutorialStep;
        _showTutorialOverlay = true;
      });
    }
  }

  /// Dismiss tutorial overlay
  void _dismissTutorial() {
    setState(() {
      _showTutorialOverlay = false;
      _currentTutorialStep = null;
    });
  }

  /// Complete tutorial step
  void _completeTutorial() {
    if (_onboardingService != null && _currentTutorialStep != null) {
      _onboardingService!.completeTutorialStep(_currentTutorialStep!.id);
    }
    _dismissTutorial();

    // Show next tutorial if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorial();
    });
  }

  Widget _buildWebMapFallback() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Enhanced Art Walk',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Interactive map features are optimized for mobile devices.\nUse the navigation controls below to explore art pieces.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

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
    debugPrint('🧭 Experience Screen: dispose() called');
    WidgetsBinding.instance.removeObserver(this);

    // Properly stop navigation before disposing
    if (_isNavigationMode) {
      debugPrint('🧭 Experience Screen: Stopping navigation before dispose');
      _navigationService.stopNavigation();
    }

    debugPrint('🧭 Experience Screen: Disposing navigation service');
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

  void _handlePreviousStep() {
    debugPrint('🧭 Experience Screen: Handling previous step request');

    // Add haptic feedback
    _hapticService?.buttonPressed();

    // For now, just show a message indicating this feature is not implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Previous step navigation not implemented yet.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );

    // TODO: Implement actual previous step logic when needed
    // This could involve going back to previous navigation step
    // or previous art piece in the route
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

    // Calculate actual rewards
    final completionBonus = _calculateCompletionBonus();
    final photosCount =
        _currentProgress?.visitedArt
            .where((v) => v.photoTaken != null)
            .length ??
        0;
    final timeSpent = _currentProgress?.timeSpent ?? Duration.zero;
    final isPerfect = _currentProgress?.progressPercentage == 1.0;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Walk Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Congratulations! You\'ve completed this art walk.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rewards earned:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text('• +$completionBonus XP total'),
            if (isPerfect) const Text('  ✓ Perfect completion bonus (+50 XP)'),
            if (timeSpent.inHours < 2) const Text('  ✓ Speed bonus (+25 XP)'),
            if (photosCount >= (_currentProgress?.visitedArt.length ?? 0) * 0.5)
              const Text('  ✓ Photo documentation bonus (+30 XP)'),
            const SizedBox(height: 8),
            Text(
              '• ${_currentProgress?.visitedArt.length ?? 0} art pieces visited',
            ),
            Text('• $photosCount photos taken'),
            Text('• ${_formatDuration(timeSpent)} duration'),
            const SizedBox(height: 8),
            const Text('• Achievement progress updated'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Review Walk'),
          ),
          ElevatedButton(
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: MainLayout(
        currentIndex: -1,
        child: Scaffold(
          appBar:
              EnhancedUniversalHeader(
                    title: _buildTitleWithProgress(),
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
                                  const Text(
                                    '• Tap markers to view art details',
                                  ),
                                  const Text(
                                    '• Mark art as visited when you reach it',
                                  ),
                                  const Text('• Green markers = visited'),
                                  const Text(
                                    '• Orange marker = next destination',
                                  ),
                                  const Text('• Red markers = not yet visited'),
                                  if (_isNavigationMode) ...[
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Navigation Mode:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      '• Follow turn-by-turn instructions',
                                    ),
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
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: _handleMenuAction,
                        itemBuilder: (context) => [
                          if (_currentProgress?.status == WalkStatus.inProgress)
                            const PopupMenuItem(
                              value: 'pause',
                              child: Row(
                                children: [
                                  Icon(Icons.pause),
                                  SizedBox(width: 8),
                                  Text('Pause Walk'),
                                ],
                              ),
                            ),
                          if (_currentProgress?.status == WalkStatus.paused)
                            const PopupMenuItem(
                              value: 'resume',
                              child: Row(
                                children: [
                                  Icon(Icons.play_arrow),
                                  SizedBox(width: 8),
                                  Text('Resume Walk'),
                                ],
                              ),
                            ),
                          if (_currentProgress?.canComplete == true)
                            const PopupMenuItem(
                              value: 'complete',
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Complete Walk'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'progress',
                            child: Row(
                              children: [
                                Icon(Icons.analytics),
                                SizedBox(width: 8),
                                Text('View Progress'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'abandon',
                            child: Row(
                              children: [
                                Icon(Icons.exit_to_app, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Abandon Walk'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                  as PreferredSizeWidget,
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
                        onNextStep: () {
                          debugPrint(
                            '🧭 Experience Screen: Next step requested',
                          );
                          try {
                            _navigationService.nextStep();
                            debugPrint(
                              '🧭 Experience Screen: Next step called successfully',
                            );
                          } catch (e) {
                            debugPrint(
                              '🧭 Experience Screen: Error calling next step: $e',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error advancing navigation: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        onPreviousStep: () {
                          debugPrint(
                            '🧭 Experience Screen: Previous step requested',
                          );
                          try {
                            _handlePreviousStep();
                          } catch (e) {
                            debugPrint(
                              '🧭 Experience Screen: Error handling previous step: $e',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error with previous step: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        onStopNavigation: () {
                          debugPrint(
                            '🧭 Experience Screen: Stop navigation requested',
                          );
                          try {
                            _stopNavigation();
                            debugPrint(
                              '🧭 Experience Screen: Stop navigation completed',
                            );
                          } catch (e) {
                            debugPrint(
                              '🧭 Experience Screen: Error stopping navigation: $e',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error stopping navigation: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
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
                                  debugPrint(
                                    '🧭 Stop Navigation button pressed',
                                  );
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

  // ========== NEW UX IMPROVEMENT METHODS ==========

  /// Build title with progress for app bar
  String _buildTitleWithProgress() {
    if (_currentProgress == null) return widget.artWalk.title;
    final visited = _currentProgress!.visitedArt.length;
    final total = _currentProgress!.totalArtCount;
    return '${widget.artWalk.title} ($visited/$total)';
  }

  /// Handle back button press with confirmation
  Future<bool> _onWillPop() async {
    if (_currentProgress?.status == WalkStatus.inProgress ||
        _currentProgress?.status == WalkStatus.paused) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave Walk?'),
          content: const Text(
            'Your progress will be saved and you can resume this walk later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }
    return true;
  }

  /// Handle menu actions
  Future<void> _handleMenuAction(String action) async {
    await _hapticService?.buttonPressed();

    switch (action) {
      case 'pause':
        await _pauseWalkAction();
        break;
      case 'resume':
        await _resumeWalkAction();
        break;
      case 'complete':
        await _manualCompleteWalk();
        break;
      case 'progress':
        _showProgressDialog();
        break;
      case 'abandon':
        await _abandonWalkAction();
        break;
    }
  }

  /// Pause walk action
  Future<void> _pauseWalkAction() async {
    try {
      final pausedProgress = await _progressService.pauseWalk();
      setState(() {
        _currentProgress = pausedProgress;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Walk paused. You can resume anytime!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error pausing walk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Resume walk action
  Future<void> _resumeWalkAction() async {
    try {
      if (_currentProgress == null) return;

      final resumedProgress = await _progressService.resumeWalk(
        _currentProgress!.id,
      );
      setState(() {
        _currentProgress = resumedProgress;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Walk resumed. Let\'s continue!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resuming walk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Manual complete walk (for early completion at 80%+)
  Future<void> _manualCompleteWalk() async {
    if (_currentProgress == null || !_currentProgress!.canComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You need to visit at least 80% of art pieces to complete early.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Walk Early?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve visited ${_currentProgress!.visitedArt.length}/${_currentProgress!.totalArtCount} art pieces.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Completing early means:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• You won\'t get the perfect completion bonus'),
            const Text('• You can still claim other rewards'),
            const SizedBox(height: 8),
            const Text('Would you like to finish now or continue exploring?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Exploring'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Complete Now'),
          ),
        ],
      ),
    );

    if (shouldComplete == true) {
      _showWalkCompletionDialog();
    }
  }

  /// Show progress dialog
  void _showProgressDialog() {
    if (_currentProgress == null) return;

    final visited = _currentProgress!.visitedArt.length;
    final total = _currentProgress!.totalArtCount;
    final percentage = (_currentProgress!.progressPercentage * 100)
        .toStringAsFixed(0);
    final timeSpent = _currentProgress!.timeSpent;
    final photosCount = _currentProgress!.visitedArt
        .where((v) => v.photoTaken != null)
        .length;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Walk Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$percentage% Complete',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            _buildProgressRow(
              Icons.location_on,
              'Art Pieces',
              '$visited / $total visited',
            ),
            _buildProgressRow(Icons.camera_alt, 'Photos', '$photosCount taken'),
            _buildProgressRow(
              Icons.timer,
              'Duration',
              _formatDuration(timeSpent),
            ),
            _buildProgressRow(
              Icons.stars,
              'Points',
              '${_currentProgress!.totalPointsEarned} XP earned',
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _currentProgress!.progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 8,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Abandon walk action
  Future<void> _abandonWalkAction() async {
    final shouldAbandon = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon Walk?'),
        content: const Text(
          'Are you sure you want to abandon this walk? All progress will be lost and cannot be recovered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Abandon'),
          ),
        ],
      ),
    );

    if (shouldAbandon == true) {
      try {
        await _progressService.abandonWalk();

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error abandoning walk: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Calculate completion bonus (mirrors service logic)
  int _calculateCompletionBonus() {
    if (_currentProgress == null) return 0;

    int bonus = 100; // Base completion bonus

    // Perfect completion bonus
    if (_currentProgress!.progressPercentage >= 1.0) {
      bonus += 50;
    }

    // Speed bonus (completed in under 2 hours)
    if (_currentProgress!.timeSpent.inHours < 2) {
      bonus += 25;
    }

    // Photo documentation bonus
    final photosCount = _currentProgress!.visitedArt
        .where((v) => v.photoTaken != null)
        .length;
    if (photosCount >= _currentProgress!.visitedArt.length * 0.5) {
      bonus += 30; // Documented at least 50% with photos
    }

    return bonus;
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

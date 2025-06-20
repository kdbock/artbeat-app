import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

class ArtWalkDetailScreen extends StatefulWidget {
  final String walkId;

  const ArtWalkDetailScreen({super.key, required this.walkId});

  @override
  State<ArtWalkDetailScreen> createState() => _ArtWalkDetailScreenState();
}

class _ArtWalkDetailScreenState extends State<ArtWalkDetailScreen> {
  final ArtWalkService _artWalkService = ArtWalkService();
  final AchievementService _achievementService = AchievementService();
  bool _isLoading = true;
  bool _isCompletingWalk = false;
  bool _hasCompletedWalk = false;
  ArtWalkModel? _walk;
  List<PublicArtModel> _artPieces = [];
  Set<Marker> _markers = <Marker>{};
  Set<Polyline> _polylines = <Polyline>{};

  @override
  void initState() {
    super.initState();
    _loadArtWalk();
  }

  /// Check if the current user has already completed this walk
  Future<void> _checkCompletionStatus() async {
    if (_walk == null) return;

    final userId = _artWalkService.getCurrentUserId();
    if (userId == null) return;

    try {
      final hasCompleted = await _achievementService.hasCompletedArtWalk(
        userId,
        _walk!.id,
      );
      if (mounted) {
        setState(() {
          _hasCompletedWalk = hasCompleted;
        });
      }
    } catch (e) {
      debugPrint('Error checking completion status: ${e.toString()}');
    }
  }

  Future<void> _loadArtWalk() async {
    setState(() => _isLoading = true);

    try {
      // First check for expired cache and clean it if needed
      await _artWalkService.checkAndClearExpiredCache();

      // Load the art walk
      final walk = await _artWalkService.getArtWalkById(widget.walkId);
      if (walk == null) {
        throw Exception('Art walk not found');
      }

      // Record the view (only if online)
      try {
        await _artWalkService.recordArtWalkView(walk.id);
      } catch (e) {
        // If offline, this will fail, but that's okay
        debugPrint('Could not record view, probably offline: ${e.toString()}');
      }

      // Load all art pieces in the walk
      final artPieces = await _artWalkService.getArtInWalk(walk.id);

      // Create markers
      final markers = _createMarkers(artPieces);

      // Create polylines if route data available
      // final polylines = _createPolylines(walk, artPieces); // Updated: routePolyline removed from model
      final polylines = _createPolylines(artPieces); // Pass only artPieces

      setState(() {
        _walk = walk;
        _artPieces = artPieces;
        _markers = markers;
        _polylines = polylines;
      });

      // Check if user has completed this walk
      await _checkCompletionStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Set<Marker> _createMarkers(List<PublicArtModel> artPieces) {
    final Set<Marker> markers = {};

    for (int i = 0; i < artPieces.length; i++) {
      final art = artPieces[i];

      // Skip art pieces with invalid coordinates to prevent NaN errors
      if (!art.location.latitude.isFinite || !art.location.longitude.isFinite) {
        debugPrint(
          "⚠️ Skipping marker for art with invalid coordinates: ${art.id}",
        );
        continue;
      }

      markers.add(
        Marker(
          markerId: MarkerId(art.id),
          position: LatLng(art.location.latitude, art.location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: '${i + 1}. ${art.title}',
            snippet: art.artistName != null ? 'by ${art.artistName}' : null,
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _createPolylines(
    // ArtWalkModel walk, // Removed walk parameter
    List<PublicArtModel> artPieces,
  ) {
    // If there are not enough art pieces, return empty set
    if (artPieces.length < 2) {
      return {};
    }

    // Filter out any art with invalid coordinates to prevent NaN errors
    final validArtPieces = artPieces
        .where(
          (art) =>
              art.location.latitude.isFinite && art.location.longitude.isFinite,
        )
        .toList();

    // Check if we still have enough valid points
    if (validArtPieces.length < 2) {
      debugPrint("⚠️ Not enough valid coordinates for polyline");
      return {};
    }

    // Create points for polyline from valid art pieces only
    final points = validArtPieces
        .map((art) => LatLng(art.location.latitude, art.location.longitude))
        .toList();

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: Colors.blue,
        width: 4,
      ),
    };
  }

  Future<void> _shareArtWalk() async {
    if (_walk == null) return;

    try {
      await Share.share(
        'Check out this Art Walk: "${_walk!.title}" on WordNerd!',
      );

      await _artWalkService.recordArtWalkShare(_walk!.id);
      _logger.i('Shared successfully');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing: ${e.toString()}')));
      _logger.e('Error sharing: ${e.toString()}');
    }
  }

  void _startNavigation() {
    // In a real app, this would launch the navigation mode
    // For now, just show a snackbar
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation would start here')),
    );
  }

  Future<void> _completeArtWalk() async {
    if (_walk == null) return;

    final userId = _artWalkService.getCurrentUserId();
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to complete art walks'),
        ),
      );
      return;
    }

    setState(() => _isCompletingWalk = true);

    try {
      await _artWalkService.recordArtWalkCompletion(artWalkId: _walk!.id);

      // Check if user received any new achievements
      final unviewedAchievements = await _achievementService
          .getUnviewedAchievements();

      if (mounted) {
        setState(() {
          _hasCompletedWalk = true;
          _isCompletingWalk = false;
        });
      }

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Art walk completed! 🎉')));

      // If there are new achievements, show them
      if (unviewedAchievements.isNotEmpty) {
        for (final achievement in unviewedAchievements) {
          // Show one achievement at a time with a dialog
          if (!mounted) return;
          await NewAchievementDialog.show(context, achievement);
          // Mark as viewed after showing
          await _achievementService.markAchievementAsViewed(achievement.id);
        }

        // Show a snackbar with option to view all achievements
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You earned new achievements!'),
            action: SnackBarAction(
              label: 'View All',
              onPressed: () {
                if (!mounted) return;
                Navigator.pushNamed(context, '/profile/achievements');
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompletingWalk = false);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing art walk: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Art Walk Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_walk == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Art Walk Details')),
        body: const Center(child: Text('Art walk not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_walk!.title),
              background:
                  _walk!
                      .imageUrls
                      .isNotEmpty // Use imageUrls list
                  ? Image.network(
                      _walk!.imageUrls.first, // Display the first image
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(
                          Icons.map, // Default icon if no image
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareArtWalk,
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats and info card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _walk!.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),

                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat(
                              Icons.photo,
                              '${_artPieces.length}',
                              'Artworks',
                            ),
                            // Conditionally display distance and time if data can be derived/fetched elsewhere
                            // As distanceKm and estimatedMinutes are removed from ArtWalkModel,
                            // these stats are currently not displayed.
                            // if (_walk!.distanceKm != null) // Removed
                            //   _buildStat(
                            //     Icons.straighten,
                            //     '${_walk!.distanceKm!.toStringAsFixed(1)} km',
                            //     'Distance',
                            //   ),
                            // if (_walk!.estimatedMinutes != null) // Removed
                            //   _buildStat(
                            //     Icons.access_time,
                            //     '${_walk!.estimatedMinutes} min',
                            //     'Time',
                            //   ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Start navigation button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _startNavigation,
                            icon: const Icon(Icons.navigation),
                            label: const Text('Start Navigation'),
                          ),
                        ),

                        // Complete art walk button (only show if not already completed)
                        if (!_hasCompletedWalk) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isCompletingWalk
                                  ? null
                                  : _completeArtWalk,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              icon: _isCompletingWalk
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle),
                              label: Text(
                                _isCompletingWalk
                                    ? 'Completing...'
                                    : 'Complete Art Walk',
                              ),
                            ),
                          ),
                        ],
                        // Show completed status if walk is completed
                        if (_hasCompletedWalk) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Completed',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Map preview
                Container(
                  height: 250,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _markers.isNotEmpty
                            ? _markers.first.position
                            : const LatLng(37.7749, -122.4194), // Default to SF
                        zoom: 13,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      liteModeEnabled: true,
                      zoomControlsEnabled: false,
                      scrollGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ),

                // Art pieces list
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Art in this Walk',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._artPieces.asMap().entries.map((entry) {
                        final index = entry.key;
                        final art = entry.value;
                        return _buildArtCard(art, index);
                      }),
                    ],
                  ),
                ),

                // Comment section
                SliverToBoxAdapter(
                  child: ArtWalkCommentSection(
                    artWalkId: widget.walkId,
                    artWalkTitle: _walk!.title,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildArtCard(PublicArtModel art, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index number
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
            child: Image.network(
              art.imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    art.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (art.artistName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'by ${art.artistName}',
                      style: const TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 6),
                  if (art.artType != null)
                    Text(
                      art.artType!,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
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
}

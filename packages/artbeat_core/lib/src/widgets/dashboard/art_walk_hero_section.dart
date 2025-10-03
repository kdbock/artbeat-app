import 'package:flutter/material.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

/// Art Walk Hero Section - Makes Art Walk the star of the main dashboard
class ArtWalkHeroSection extends StatefulWidget {
  final VoidCallback onInstantDiscoveryTap;
  final VoidCallback onProfileMenuTap;

  const ArtWalkHeroSection({
    Key? key,
    required this.onInstantDiscoveryTap,
    required this.onProfileMenuTap,
  }) : super(key: key);

  @override
  State<ArtWalkHeroSection> createState() => _ArtWalkHeroSectionState();
}

class _ArtWalkHeroSectionState extends State<ArtWalkHeroSection>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late Animation<double> _radarAnimation;

  int _nearbyArtCount = 0;
  int _activeUsersNearby = 0;
  int _userStreak = 0;
  bool _isLoading = true;

  final InstantDiscoveryService _discoveryService = InstantDiscoveryService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadHeroData();
  }

  void _setupAnimations() {
    _radarController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _radarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _radarController, curve: Curves.linear));
  }

  Future<void> _loadHeroData() async {
    try {
      // Load nearby art count
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final nearbyArt = await _discoveryService.getNearbyArt(
        position,
        radiusMeters: 500,
      );

      // Load user streak (placeholder - would need to implement)
      // final currentUser = await _userService.getCurrentUserModel();

      if (mounted) {
        setState(() {
          _nearbyArtCount = nearbyArt.length;
          _activeUsersNearby = 0; // Placeholder - would need social service
          _userStreak = 0; // Placeholder - would need streak service
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to demo data if location fails
      if (mounted) {
        setState(() {
          _nearbyArtCount = 3; // Demo data
          _activeUsersNearby = 7; // Demo data
          _userStreak = 2; // Demo data
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4FB3BE), // Teal
            Color(0xFFFF9E80), // Orange/Peach
            Color(0xFFBA68C8), // Purple accent
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated radar background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _radarAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: RadarPainter(
                    progress: _radarAnimation.value,
                    nearbyCount: _nearbyArtCount,
                  ),
                );
              },
            ),
          ),

          // Content overlay
          SafeArea(
            child: Column(
              children: [
                // Header with profile menu
                _buildHeader(),

                // Main content
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _buildHeroContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.palette, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'ARTbeat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: widget.onProfileMenuTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.menu, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Finding nearby art...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic messaging based on nearby art
          _buildDynamicMessage(),

          const SizedBox(height: 8),

          // Social proof
          if (_activeUsersNearby > 0)
            Text(
              '$_activeUsersNearby art explorers active nearby',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),

          const SizedBox(height: 24),

          // Call to action button
          _buildActionButton(),

          const SizedBox(height: 16),

          // Streak indicator
          if (_userStreak > 0) _buildStreakIndicator(),
        ],
      ),
    );
  }

  Widget _buildDynamicMessage() {
    String title;
    String subtitle;

    if (_nearbyArtCount == 0) {
      title = '🏙️ Explore somewhere exciting!';
      subtitle = 'Find art hotspots in your city';
    } else if (_nearbyArtCount == 1) {
      title = '🎨 One hidden artwork nearby!';
      subtitle = 'Ready for discovery?';
    } else if (_nearbyArtCount < 5) {
      title = '🎯 $_nearbyArtCount artworks waiting!';
      subtitle = 'Your art adventure awaits';
    } else {
      title = '🔥 $_nearbyArtCount artworks nearby!';
      subtitle = 'Art hunt time!';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onInstantDiscoveryTap,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.radar, color: Color(0xFF4FB3BE), size: 20),
                const SizedBox(width: 8),
                Text(
                  _nearbyArtCount > 0
                      ? 'Start Discovering'
                      : 'Find Art Hotspots',
                  style: const TextStyle(
                    color: Color(0xFF4FB3BE),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$_userStreak day streak!',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for animated radar background
class RadarPainter extends CustomPainter {
  final double progress;
  final int nearbyCount;

  RadarPainter({required this.progress, required this.nearbyCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw radar circles
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final radius = maxRadius * (i / 3);
      canvas.drawCircle(center, radius, circlePaint);
    }

    // Draw sweeping radar line
    final sweepPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final sweepAngle = progress * 2 * 3.14159; // Full circle
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius),
      -3.14159 / 2, // Start from top
      sweepAngle,
      false,
      sweepPaint,
    );

    // Draw art indicators (simplified)
    if (nearbyCount > 0) {
      final artPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;

      // Draw some sample art dots around the radar
      for (int i = 0; i < nearbyCount && i < 5; i++) {
        final angle = (i * 2 * 3.14159) / nearbyCount;
        final distance = maxRadius * 0.6;
        final x = center.dx + distance * math.cos(angle);
        final y = center.dy + distance * math.sin(angle);
        canvas.drawCircle(Offset(x, y), 4, artPaint);
      }
    }
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.nearbyCount != nearbyCount;
  }
}

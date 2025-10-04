import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/public_art_model.dart';
import '../services/instant_discovery_service.dart';
import '../theme/art_walk_design_system.dart';

/// Radar widget showing nearby art in Pokemon Go style
class InstantDiscoveryRadar extends StatefulWidget {
  final Position userPosition;
  final List<PublicArtModel> nearbyArt;
  final double radiusMeters;
  final void Function(PublicArtModel art, double distance)? onArtTap;

  const InstantDiscoveryRadar({
    super.key,
    required this.userPosition,
    required this.nearbyArt,
    this.radiusMeters = 500,
    this.onArtTap,
  });

  @override
  State<InstantDiscoveryRadar> createState() => _InstantDiscoveryRadarState();
}

class _InstantDiscoveryRadarState extends State<InstantDiscoveryRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;
  final InstantDiscoveryService _discoveryService = InstantDiscoveryService();

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ArtWalkDesignSystem.backgroundGradientStart,
            ArtWalkDesignSystem.backgroundGradientEnd,
          ],
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          // Radar
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildRadar(),
                ),
              ),
            ),
          ),
          // Art list
          _buildArtList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtWalkDesignSystem.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instant Discovery',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ArtWalkDesignSystem.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.nearbyArt.length} artworks nearby',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ArtWalkDesignSystem.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ArtWalkDesignSystem.primaryTeal,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.radar, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.radiusMeters.toInt()}m',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadar() {
    return CustomPaint(
      painter: RadarPainter(
        sweepAnimation: _sweepController,
        userPosition: widget.userPosition,
        nearbyArt: widget.nearbyArt,
        radiusMeters: widget.radiusMeters,
      ),
      child: Stack(
        children: [
          // Art pins
          ...widget.nearbyArt.map((art) => _buildArtPin(art)),
          // User position (center)
          Center(child: _buildUserPin()),
        ],
      ),
    );
  }

  Widget _buildUserPin() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: ArtWalkDesignSystem.accentOrange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: ArtWalkDesignSystem.accentOrange.withValues(
                    alpha: 0.5,
                  ),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation
        setState(() {});
      },
    );
  }

  Widget _buildArtPin(PublicArtModel art) {
    final distance = _discoveryService.calculateDistance(
      widget.userPosition,
      art,
    );

    // Calculate position on radar
    final bearing = Geolocator.bearingBetween(
      widget.userPosition.latitude,
      widget.userPosition.longitude,
      art.location.latitude,
      art.location.longitude,
    );

    // Convert to radians
    final angleRadians = (bearing - 90) * math.pi / 180;

    // Calculate normalized distance (0 to 1)
    final normalizedDistance = (distance / widget.radiusMeters).clamp(0.0, 1.0);

    // Calculate position (center is 0.5, 0.5)
    final x = 0.5 + (normalizedDistance * 0.45 * math.cos(angleRadians));
    final y = 0.5 + (normalizedDistance * 0.45 * math.sin(angleRadians));

    // Determine if art is close (< 100m)
    final isClose = distance < 100;

    return Positioned.fill(
      child: Align(
        alignment: Alignment((x - 0.5) * 2, (y - 0.5) * 2),
        child: GestureDetector(
          onTap: () => widget.onArtTap?.call(art, distance),
          child: _buildArtMarker(art, distance, isClose),
        ),
      ),
    );
  }

  Widget _buildArtMarker(PublicArtModel art, double distance, bool isClose) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: isClose ? 1.3 : 1.0),
      duration: Duration(milliseconds: isClose ? 800 : 1500),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isClose
                  ? ArtWalkDesignSystem.accentOrange
                  : ArtWalkDesignSystem.primaryTeal,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color:
                      (isClose
                              ? ArtWalkDesignSystem.accentOrange
                              : ArtWalkDesignSystem.primaryTeal)
                          .withValues(alpha: 0.5),
                  blurRadius: isClose ? 15 : 8,
                  spreadRadius: isClose ? 3 : 1,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.palette, color: Colors.white, size: 20),
            ),
          ),
        );
      },
      onEnd: () {
        if (isClose) {
          // Restart pulsing animation for close art
          setState(() {});
        }
      },
    );
  }

  Widget _buildArtList() {
    if (widget.nearbyArt.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.search_off,
              size: 48,
              color: ArtWalkDesignSystem.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No art nearby',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ArtWalkDesignSystem.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try moving to a different location',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ArtWalkDesignSystem.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: ArtWalkDesignSystem.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.nearbyArt.length,
        itemBuilder: (context, index) {
          final art = widget.nearbyArt[index];
          final distance = _discoveryService.calculateDistance(
            widget.userPosition,
            art,
          );
          return _buildArtListItem(art, distance);
        },
      ),
    );
  }

  Widget _buildArtListItem(PublicArtModel art, double distance) {
    final proximityMessage = _discoveryService.getProximityMessage(distance);
    final isClose = distance < 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isClose
                ? ArtWalkDesignSystem.accentOrange
                : ArtWalkDesignSystem.primaryTeal,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.palette, color: Colors.white),
        ),
        title: Text(
          art.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (art.artistName != null)
              Text(
                'by ${art.artistName}',
                style: const TextStyle(
                  color: ArtWalkDesignSystem.textSecondary,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              proximityMessage,
              style: TextStyle(
                color: isClose
                    ? ArtWalkDesignSystem.accentOrange
                    : ArtWalkDesignSystem.primaryTeal,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${distance.toInt()}m',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Icon(
              Icons.arrow_forward,
              size: 16,
              color: ArtWalkDesignSystem.textSecondary,
            ),
          ],
        ),
        onTap: () => widget.onArtTap?.call(art, distance),
      ),
    );
  }
}

/// Custom painter for radar background
class RadarPainter extends CustomPainter {
  final Animation<double> sweepAnimation;
  final Position userPosition;
  final List<PublicArtModel> nearbyArt;
  final double radiusMeters;

  RadarPainter({
    required this.sweepAnimation,
    required this.userPosition,
    required this.nearbyArt,
    required this.radiusMeters,
  }) : super(repaint: sweepAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw distance rings
    _drawDistanceRings(canvas, center, radius);

    // Draw sweep line
    _drawSweepLine(canvas, center, radius);

    // Draw crosshairs
    _drawCrosshairs(canvas, center, radius);
  }

  void _drawDistanceRings(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw 3 rings (100m, 250m, 500m)
    final rings = [0.2, 0.5, 0.9];
    for (var ringRadius in rings) {
      canvas.drawCircle(center, radius * ringRadius, paint);
    }
  }

  void _drawSweepLine(Canvas canvas, Offset center, double radius) {
    final sweepAngle = sweepAnimation.value * 2 * math.pi;

    // Create gradient for sweep
    final gradient = SweepGradient(
      colors: [
        ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.0),
        ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.3),
        ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(sweepAngle),
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius * 0.9, paint);
  }

  void _drawCrosshairs(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - radius * 0.9, center.dy),
      Offset(center.dx + radius * 0.9, center.dy),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.9),
      Offset(center.dx, center.dy + radius * 0.9),
      paint,
    );
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) {
    return oldDelegate.nearbyArt != nearbyArt ||
        oldDelegate.userPosition != userPosition;
  }
}

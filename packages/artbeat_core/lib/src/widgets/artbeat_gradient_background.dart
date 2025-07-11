import 'package:flutter/material.dart';
import '../theme/artbeat_colors.dart';

/// Reusable gradient background widget with ARTbeat's signature design
/// 
/// Features:
/// - Diagonal gradient with purple, green, and blue colors
/// - Subtle white overlay for brightness
/// - Consistent visual identity across the app
/// - Customizable intensity and direction
class ArtbeatGradientBackground extends StatelessWidget {
  final Widget child;
  final double intensity;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final bool addShadow;
  final BorderRadius? borderRadius;

  const ArtbeatGradientBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.addShadow = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: [
            Colors.white,
            ArtbeatColors.primaryPurple.withValues(alpha: 0.15 * intensity),
            const Color(0xFF4A90E2).withValues(alpha: 0.2 * intensity), // Blue
            Colors.white.withValues(alpha: 0.95),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.12 * intensity),
            Colors.white,
          ],
          stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
        ),
        borderRadius: borderRadius,
        boxShadow: addShadow ? [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 4,
            offset: const Offset(-1, -1),
          ),
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(1, 1),
          ),
        ] : null,
      ),
      child: child,
    );
  }
}

/// Background variant for bottom navigation and smaller components
class ArtbeatGradientBackgroundCompact extends StatelessWidget {
  final Widget child;
  final double intensity;
  final double? height;
  final EdgeInsets? padding;

  const ArtbeatGradientBackgroundCompact({
    super.key,
    required this.child,
    this.intensity = 0.8,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            ArtbeatColors.primaryPurple.withValues(alpha: 0.12 * intensity),
            const Color(0xFF4A90E2).withValues(alpha: 0.15 * intensity), // Blue
            Colors.white.withValues(alpha: 0.98),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.1 * intensity),
            Colors.white.withValues(alpha: 0.95),
          ],
          stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}
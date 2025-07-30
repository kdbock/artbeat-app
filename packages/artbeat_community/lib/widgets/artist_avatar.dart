import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// A circular avatar widget for displaying artist profile images
/// This is now a wrapper around the unified UserAvatar widget
class ArtistAvatar extends StatelessWidget {
  /// The URL of the artist's avatar image
  final String? imageUrl;

  /// The artist's display name (used for fallback)
  final String displayName;

  /// The radius of the avatar circle
  final double radius;

  /// Whether this avatar shows a verification badge
  final bool isVerified;

  /// Called when the avatar is tapped
  final VoidCallback? onTap;

  const ArtistAvatar({
    super.key,
    this.imageUrl,
    required this.displayName,
    this.radius = 20.0,
    this.isVerified = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('ArtistAvatar build: $displayName');
    }

    return UserAvatar(
      imageUrl: imageUrl,
      displayName: displayName,
      radius: radius,
      isVerified: isVerified,
      onTap: onTap,
    );
  }
}

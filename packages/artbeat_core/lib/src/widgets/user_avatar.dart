import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/artbeat_colors.dart';

/// A unified avatar widget for displaying user profile images across the app
class UserAvatar extends StatelessWidget {
  /// The URL of the user's avatar image
  final String? imageUrl;

  /// The user's display name (used for fallback initials)
  final String displayName;

  /// The radius of the avatar circle
  final double radius;

  /// Whether this avatar shows a verification badge
  final bool isVerified;

  /// Called when the avatar is tapped
  final VoidCallback? onTap;

  /// Background color for the fallback avatar
  final Color? backgroundColor;

  /// Text color for the fallback avatar
  final Color? textColor;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.displayName,
    this.radius = 20.0,
    this.isVerified = false,
    this.onTap,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Debug logging to help identify issues
    debugPrint('🔍 UserAvatar build:');
    debugPrint('  - displayName: "$displayName"');
    debugPrint('  - imageUrl: "${imageUrl ?? 'null'}"');
    debugPrint('  - imageUrl isEmpty: ${imageUrl?.isEmpty ?? 'N/A'}');
    debugPrint(
      '  - will show fallback: ${imageUrl == null || imageUrl!.isEmpty}',
    );

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor ?? ArtbeatColors.backgroundSecondary,
            ),
            child: ClipOval(child: _buildAvatarContent(theme)),
          ),
          if (isVerified)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: ArtbeatColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.check,
                  size: radius * 0.6,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(ThemeData theme) {
    // If we have a valid image URL, try to load it
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: radius * 2,
          height: radius * 2,
          color: backgroundColor ?? ArtbeatColors.backgroundSecondary,
          child: Center(
            child: SizedBox(
              width: radius * 0.5,
              height: radius * 0.5,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ArtbeatColors.primaryPurple,
                ),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackAvatar(theme),
      );
    }

    // If no image URL, show fallback
    return _buildFallbackAvatar(theme);
  }

  Widget _buildFallbackAvatar(ThemeData theme) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: backgroundColor ?? ArtbeatColors.primaryPurple,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitials(displayName),
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: radius * 0.8,
            color: textColor ?? Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }

    return name[0].toUpperCase();
  }
}

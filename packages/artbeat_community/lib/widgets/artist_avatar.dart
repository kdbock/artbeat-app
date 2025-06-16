import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/index.dart';

/// A circular avatar widget for displaying artist profile images
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
    this.radius = CommunitySpacing.avatarSizeMedium / 2,
    this.isVerified = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typography = CommunityTypography(Theme.of(context));

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: ClipOval(
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      width: radius * 2,
                      height: radius * 2,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: radius * 2,
                        height: radius * 2,
                        color: Theme.of(context).colorScheme.surface,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: radius * 2,
                        height: radius * 2,
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withOpacity(0.1),
                        child: Center(
                          child: Text(
                            displayName[0].toUpperCase(),
                            style: typography.commentAuthor.copyWith(
                              fontSize: radius * 0.8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        displayName[0].toUpperCase(),
                        style: typography.commentAuthor.copyWith(
                          fontSize: radius * 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
          if (isVerified)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: CommunityColors.verified,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.check,
                  size: radius * 0.7,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

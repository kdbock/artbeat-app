import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

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
    this.radius = 20.0,
    this.isVerified = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    debugPrint('ArtistAvatar build - displayName: "$displayName", imageUrl: "$imageUrl"');

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ArtbeatColors.backgroundSecondary,
            ),
            child: ClipOval(
              child: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? Image.network(
                      imageUrl!,
                      width: radius * 2,
                      height: radius * 2,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          debugPrint('ArtistAvatar - Image loaded successfully: $imageUrl');
                          return child;
                        }
                        debugPrint('ArtistAvatar - Loading image: $imageUrl');
                        return Container(
                          width: radius * 2,
                          height: radius * 2,
                          color: ArtbeatColors.backgroundSecondary,
                          child: Center(
                            child: SizedBox(
                              width: radius * 0.5,
                              height: radius * 0.5,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ArtbeatColors.primaryPurple,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('ArtistAvatar - Image load error for $imageUrl: $error');
                        return _buildFallbackAvatar(theme);
                      },
                    )
                  : ((){
                      debugPrint('ArtistAvatar - No imageUrl provided, showing fallback');
                      return _buildFallbackAvatar(theme);
                    })(),
            ),
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

  Widget _buildFallbackAvatar(ThemeData theme) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: ArtbeatColors.primaryPurple,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: radius * 0.8,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

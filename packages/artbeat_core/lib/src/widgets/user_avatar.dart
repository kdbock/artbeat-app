import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

    // Debug logging to help identify issues (reduced for performance)
    if (kDebugMode) {
      debugPrint('🔍 UserAvatar build: $displayName');
    }

    Widget avatar;
    // Only use NetworkImage if imageUrl is a valid HTTP(S) URL
    final isValidNetworkUrl =
        imageUrl != null &&
        imageUrl!.isNotEmpty &&
        (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));

    if (isValidNetworkUrl) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? theme.primaryColor,
        child: ClipOval(
          child: Image.network(
            imageUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Error loading avatar image: $error');
              return _buildFallbackAvatar(theme);
            },
          ),
        ),
      );
    } else {
      avatar = _buildFallbackAvatar(theme);
    }

    // Add verification badge if needed
    if (isVerified) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.verified,
                color: ArtbeatColors.primaryPurple,
                size: radius * 0.7,
              ),
            ),
          ),
        ],
      );
    }

    // Wrap in gesture detector if onTap is provided
    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _buildFallbackAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? theme.primaryColor,
      child: Text(
        _getInitials(),
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getInitials() {
    final nameParts = displayName.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return displayName.substring(0, 1).toUpperCase();
  }
}

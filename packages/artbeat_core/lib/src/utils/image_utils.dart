import 'package:flutter/material.dart';

/// Utility class for handling image loading with proper URL validation
class ImageUtils {
  /// Checks if a URL is valid for NetworkImage
  static bool isValidNetworkImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }

    // Check for placeholder URLs that should not be loaded
    if (url == 'placeholder_headshot_url' ||
        url.startsWith('file:///placeholder') ||
        url.contains('placeholder')) {
      return false;
    }

    // Check if it's a valid HTTP(S) URL
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// Creates a safe NetworkImage provider or returns null if URL is invalid
  static ImageProvider<Object>? safeNetworkImage(String? url) {
    if (isValidNetworkImageUrl(url)) {
      return NetworkImage(url!);
    }
    return null;
  }

  /// Creates a safe CircleAvatar with proper fallback
  static Widget safeCircleAvatar({
    String? imageUrl,
    required String displayName,
    double radius = 20.0,
    Color? backgroundColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    Widget avatar;

    if (isValidNetworkImageUrl(imageUrl)) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: NetworkImage(imageUrl!),
        child: null,
      );
    } else {
      // Create fallback avatar with initials
      final initials = _getInitials(displayName);
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[400],
        child: Text(
          initials,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: radius * 0.7,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  /// Creates a safe DecorationImage or returns null if URL is invalid
  static DecorationImage? safeDecorationImage(
    String? url, {
    BoxFit fit = BoxFit.cover,
  }) {
    if (isValidNetworkImageUrl(url)) {
      return DecorationImage(image: NetworkImage(url!), fit: fit);
    }
    return null;
  }

  static String _getInitials(String displayName) {
    final nameParts = displayName.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : '?';
  }
}

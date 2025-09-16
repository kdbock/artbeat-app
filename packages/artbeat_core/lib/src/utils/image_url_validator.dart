import 'package:flutter/material.dart';

/// Utility class for validating image URLs before using with NetworkImage
class ImageUrlValidator {
  /// Validates if an image URL is safe to use with NetworkImage
  ///
  /// Returns true if the URL is valid and can be used with NetworkImage,
  /// false otherwise.
  ///
  /// This prevents the common error:
  /// "Invalid argument(s): No host specified in URI file:///"
  static bool isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;

    final trimmedUrl = url.trim();

    // Check for common invalid patterns that cause NetworkImage errors
    if (trimmedUrl == 'file:///' ||
        trimmedUrl == '' ||
        trimmedUrl == 'null' ||
        trimmedUrl == 'undefined') {
      return false;
    }

    // Basic URL validation - should start with http:// or https://
    return trimmedUrl.startsWith('http://') ||
        trimmedUrl.startsWith('https://');
  }

  /// Creates a safe NetworkImage with error handling
  ///
  /// Returns a NetworkImage if the URL is valid, or null if invalid.
  /// Use this when you need to conditionally create a NetworkImage.
  static NetworkImage? safeNetworkImage(String? url) {
    return isValidImageUrl(url) ? NetworkImage(url!) : null;
  }
}

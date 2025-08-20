import 'package:flutter/material.dart';

/// Utility functions for validating and handling image URLs
class AdImageUtils {
  /// Validates if the image URL is valid and not a placeholder
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url.contains('placeholder.com')) return false;
    if (url.contains('example.com')) return false;
    if (url.contains('lorem')) return false;
    if (url.trim() == '') return false;

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // Must be HTTP/HTTPS or local file
    return uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'file');
  }

  /// Gets a valid image URL or returns empty string if invalid
  static String getValidImageUrl(String? url) {
    return isValidImageUrl(url) ? url! : '';
  }

  /// Filters a list of image URLs to only include valid ones
  static List<String> filterValidUrls(List<String>? urls) {
    if (urls == null) return [];
    return urls.where(isValidImageUrl).toList();
  }

  /// Checks if any URLs in a list are invalid placeholder URLs
  static bool hasInvalidUrls(List<String>? urls) {
    if (urls == null) return false;
    return urls.any((url) => !isValidImageUrl(url));
  }

  /// Returns error widget for broken images
  static Widget get errorIcon =>
      const Icon(Icons.broken_image, size: 48, color: Colors.grey);

  /// Returns placeholder widget for missing images
  static Widget get placeholderIcon =>
      const Icon(Icons.image, size: 48, color: Colors.grey);
}

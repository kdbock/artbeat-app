/// AdType for simplified ad formats
enum AdType {
  banner_ad, // Banner advertisements
  feed_ad, // Feed advertisements
}

extension AdTypeExtension on AdType {
  /// Get display name for this ad type
  String get displayName {
    switch (this) {
      case AdType.banner_ad:
        return 'Banner Ad';
      case AdType.feed_ad:
        return 'Feed Ad';
    }
  }

  /// Get description for this ad type
  String get description {
    switch (this) {
      case AdType.banner_ad:
        return 'Banner advertisement displayed at the top or bottom of screens';
      case AdType.feed_ad:
        return 'Advertisement integrated into content feeds';
    }
  }
}

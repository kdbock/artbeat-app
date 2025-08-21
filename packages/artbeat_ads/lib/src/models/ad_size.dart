/// AdSize for standardized ad dimensions
enum AdSize {
  small, // 320x50 pixels - $1/day
  medium, // 320x100 pixels - $5/day
  large, // 320x250 pixels - $10/day
}

extension AdSizeExtension on AdSize {
  /// Get the width for this ad size
  int get width => 320;

  /// Get the height for this ad size
  int get height {
    switch (this) {
      case AdSize.small:
        return 50;
      case AdSize.medium:
        return 100;
      case AdSize.large:
        return 250;
    }
  }

  /// Get the daily price for this ad size
  double get pricePerDay {
    switch (this) {
      case AdSize.small:
        return 1.0;
      case AdSize.medium:
        return 5.0;
      case AdSize.large:
        return 10.0;
    }
  }

  /// Get display name for this ad size
  String get displayName {
    switch (this) {
      case AdSize.small:
        return 'Small (320x50)';
      case AdSize.medium:
        return 'Medium (320x100)';
      case AdSize.large:
        return 'Large (320x250)';
    }
  }

  /// Get dimensions as a string
  String get dimensions => '${width}x${height}';
}

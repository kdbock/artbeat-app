import 'package:flutter/material.dart';

/// ImageFit for controlling how ad images are displayed
enum ImageFit {
  cover, // Scales image to cover entire area (may crop)
  contain, // Scales image to fit within area (may have empty space)
  fill, // Stretches image to fill entire area (may distort)
  fitWidth, // Scales image to fit width (may crop height)
  fitHeight, // Scales image to fit height (may crop width)
  none, // Represents no specific fit
  scaleDown, // Image scales down to fit.
}

extension ImageFitExtension on ImageFit {
  String get description {
    switch (this) {
      case ImageFit.cover:
        return 'covers the entire ad space';
      case ImageFit.contain:
        return 'entirely visible within ad space';
      case ImageFit.fill:
        return 'fills the entire ad space';
      case ImageFit.fitWidth:
        return 'fit the width of the ad space';
      case ImageFit.fitHeight:
        return 'fit the height of the ad space';
      case ImageFit.scaleDown:
        return 'scale down to fit';
      case ImageFit.none:
        return 'shows original image size and aspect ratio';
    }
  }

  /// Get display name for this image fit
  String get displayName {
    switch (this) {
      case ImageFit.cover:
        return 'Cover (Fill & Crop)';
      case ImageFit.contain:
        return 'Contain (Fit & Letterbox)';
      case ImageFit.fill:
        return 'Fill (Stretch)';
      case ImageFit.fitWidth:
        return 'Fit Width';
      case ImageFit.fitHeight:
        return 'Fit Height';
      case ImageFit.scaleDown:
        return 'Scale Down';
      case ImageFit.none:
        return 'None (Original Size)';
    }
  }

  /// Get BoxFit equivalent for Flutter
  BoxFit get boxFit {
    switch (this) {
      case ImageFit.cover:
        return BoxFit.cover;
      case ImageFit.contain:
        return BoxFit.contain;
      case ImageFit.fill:
        return BoxFit.fill;
      case ImageFit.fitWidth:
        return BoxFit.fitWidth;
      case ImageFit.fitHeight:
        return BoxFit.fitHeight;
      case ImageFit.scaleDown:
        return BoxFit.scaleDown;
      case ImageFit.none:
        return BoxFit.none;
    }
  }
}

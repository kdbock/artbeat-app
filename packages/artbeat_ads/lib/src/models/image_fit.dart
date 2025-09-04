import 'package:flutter/material.dart';

/// ImageFit for controlling how ad images are displayed
enum ImageFit {
  cover, // Scales image to cover entire area (may crop)
  contain, // Scales image to fit within area (may have empty space)
  fill, // Stretches image to fill entire area (may distort)
  fitWidth, // Scales image to fit width (may crop height)
  fitHeight, // Scales image to fit height (may crop width)
  none, // No scaling, shows original size
}

extension ImageFitExtension on ImageFit {
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
      case ImageFit.none:
        return 'Original Size';
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
      case ImageFit.none:
        return BoxFit.none;
    }
  }
}

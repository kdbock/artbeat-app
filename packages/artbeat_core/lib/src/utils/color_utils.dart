import 'package:flutter/material.dart';

/// Extension on Color to handle opacity and color manipulations in a non-deprecated way
extension ColorUtils on Color {
  /// Creates a copy of this color with the given opacity.
  /// This is a replacement for the deprecated withOpacity method.
  Color withOpacityValue(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return withAlpha((255.0 * opacity).round());
  }

  /// Returns a lighter version of this color
  Color lighter([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Returns a darker version of this color
  Color darker([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Returns a color that contrasts well with this color (black or white)
  Color get contrastingColor {
    // Calculate perceived brightness using W3C formula
    final brightness = ((red * 299) + (green * 587) + (blue * 114)) / 1000;
    return brightness > 128 ? Colors.black : Colors.white;
  }

  /// Creates a copy of this color with the given opacity with different parameter name
  /// to make it clear this is our recommended replacement
  Color withValues([double opacity = 1.0]) => withOpacityValue(opacity);
}

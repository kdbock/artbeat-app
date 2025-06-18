import 'package:flutter/material.dart';

/// Extension for more precise color manipulation
extension ColorX on Color {
  /// Returns a color with a specified opacity value between 0 and 1
  Color withAlphaValue(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return Color.fromRGBO(
      (r * 255.0).round(),
      (g * 255.0).round(),
      (b * 255.0).round(),
      opacity,
    );
  }

  /// Returns a color with the specified percentage of another color blended in
  Color blendWith(Color other, double amount) {
    assert(amount >= 0.0 && amount <= 1.0);
    return Color.lerp(this, other, amount)!;
  }

  /// Returns a color lightened by the specified percentage
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0.0 && amount <= 1.0);
    return blendWith(const Color(0xFFFFFFFF), amount);
  }

  /// Returns a color darkened by the specified percentage
  Color darken([double amount = 0.1]) {
    assert(amount >= 0.0 && amount <= 1.0);
    return blendWith(const Color(0xFF000000), amount);
  }
}

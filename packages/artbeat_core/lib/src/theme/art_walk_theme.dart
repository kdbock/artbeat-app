import 'package:flutter/material.dart';

class ArtWalkTheme {
  static CardTheme cardTheme(ThemeData theme) => CardTheme(
    elevation: 2.0,
    shadowColor: theme.shadowColor.withAlpha((0.3 * 255).round()),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
  );

  // Update other color opacities
  static Color overlayColor(ThemeData theme) =>
      theme.primaryColor.withAlpha((0.5 * 255).round());

  static Color shadowColor(ThemeData theme) =>
      theme.shadowColor.withAlpha((0.2 * 255).round());
}

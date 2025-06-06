import 'package:flutter/material.dart';

class ArtbeatColors {
  // Primary Colors
  static const Color primaryPurple = Color(0xFF8C52FF);
  static const Color primaryGreen = Color(0xFF00BF63);
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Text Colors
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF666666);
  static const Color textWhite = Colors.white;
  static const Color textDisabled = Color(0xFFAAAAAA);

  // Background Colors
  static const Color backgroundPrimary = Colors.white;
  static const Color backgroundSecondary = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);

  // Button Colors
  static const Color buttonPrimary = primaryPurple;
  static const Color buttonSecondary = primaryGreen;
  static const Color buttonDisabled = Color(0xFFDDDDDD);

  // Status Colors
  static const Color success = Color(0xFF00BF63);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);
  static const Color info = Color(0xFF007AFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryGreen],
  );
}

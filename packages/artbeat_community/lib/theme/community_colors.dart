import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Custom colors for the community module
class CommunityColors {
  // Primary colors
  static const primary = Color(0xFF800020); // Burgundy
  static const secondary = Color(0xFFFFD700); // Gold

  // Interactive states
  static const applause = Color(0xFFFFB74D);
  static const applauseBackground = Color(0xFFFFF3E0);
  static const feedback = Color(0xFF4DB6AC);
  static const feedbackBackground = Color(0xFFE0F2F1);
  static const gift = Color(0xFFFF6B6B);
  static const giftBackground = Color(0xFFFCE4EC);
  static const studio = Color(0xFF4A90E2);
  static const commission = Color(0xFFFFA726);

  // Background colors
  static const background = Color(0xFFFAFAFA);
  static const cardBackground = Colors.white;
  static const threadBackground = Color(0xFFF5F5F5);
  static const canvasBackground = Color(0xFFFAFAFA);
  static const canvasBorder = Color(0xFFE0E0E0);
  static const studioBackground = Color(0xFFEDE7F6);

  // Text colors
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
  static const textHint = Color(0xFF999999);
  static const comment = Color(0xFF757575);
  static const mention = Color(0xFF800020); // Burgundy for mentions
  static const hashtag = Color(0xFF42A5F5);

  // Status colors
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFFF5252);
  static const info = Color(0xFF2196F3);
  static const verified = ArtbeatColors.success;
  static const featured = Color(0xFFFFD700);
  static const sponsored = Color(0xFF90CAF9);

  // Overlay colors
  static const quietModeOverlay = Color(0x33000000);
  static const portfolioOverlay = Color(0x40FFFFFF);
  static const sharedElementBackground = Color(0xB3FFFFFF);

  // Active states
  static const studioActive = Color(0xFF9575CD);
  static const giftPrimary = Color(0xFFEC407A);

  // Gradients
  static const applauseGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const giftGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF4081)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Community header and button gradient - Burgundy to Gold
  static const communityGradient = LinearGradient(
    colors: [Color(0xFF800020), Color(0xFFFFD700)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Community background gradient
  static const communityBackgroundGradient = LinearGradient(
    colors: [
      Color(0x33800020), // Burgundy with alpha
      Color(0x33FFD700), // Gold with alpha
      Colors.white,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

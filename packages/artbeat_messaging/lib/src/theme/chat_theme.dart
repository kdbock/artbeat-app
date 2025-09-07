import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' show ArtbeatColors;

class ChatTheme {
  // Main colors
  static const Color primaryColor = ArtbeatColors.primaryPurple;
  static const Color secondaryColor = ArtbeatColors.primaryGreen;
  static const Color accentColor = ArtbeatColors.secondaryTeal;

  // Bubble colors
  static const Color currentUserBubbleColor = ArtbeatColors.primaryPurple;
  static const Color otherUserBubbleColor = Colors.white;
  static const Color backgroundColor = Color(0xFFF8F9FE);

  // Status colors
  static const Color onlineColor = Color(0xFF4CAF50);
  static const Color offlineColor = Color(0xFFBDBDBD);
  static const Color typingColor = ArtbeatColors.primaryPurple;

  // Text styles
  static const TextStyle currentUserTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    height: 1.4,
  );

  static const TextStyle otherUserTextStyle = TextStyle(
    color: Colors.black87,
    fontSize: 16,
    height: 1.4,
  );

  static const TextStyle timestampStyle = TextStyle(
    color: Color(0xFF9E9E9E),
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle chatNameStyle = TextStyle(
    color: Colors.black87,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle lastMessageStyle = TextStyle(
    color: Color(0xFF757575),
    fontSize: 14,
    overflow: TextOverflow.ellipsis,
  );

  static const TextStyle unreadCountStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );

  // Input decoration
  static InputDecoration messageInputDecoration = InputDecoration(
    hintText: 'Type a message...',
    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(
        color: ArtbeatColors.primaryPurple.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(
        color: ArtbeatColors.primaryPurple.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: const BorderSide(
        color: ArtbeatColors.primaryPurple,
        width: 1.5,
      ),
    ),
    filled: true,
    fillColor: Colors.grey.shade50,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  );

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Shadows
  static List<BoxShadow> messageBubbleShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: ArtbeatColors.primaryPurple.withValues(alpha: 0.2),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Border radius
  static const double cardBorderRadius = 16.0;
  static const double bubbleBorderRadius = 20.0;
  static const double buttonBorderRadius = 12.0;

  // Spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
}

import 'package:flutter/material.dart';
import 'package:artbeat_core/theme/index.dart';

/// Typography styles for the community module
class CommunityTypography {
  // Studio text styles
  static final TextStyle studioTitle =
      ArtbeatTypography.textTheme.headlineMedium!.copyWith(
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static final TextStyle studioDescription =
      ArtbeatTypography.textTheme.bodyLarge!.copyWith(
    color: Colors.black87,
    height: 1.5,
  );

  // Feed post text styles
  static final TextStyle feedPostTitle =
      ArtbeatTypography.textTheme.titleMedium!.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
  );

  static final TextStyle feedPostBody =
      ArtbeatTypography.textTheme.bodyLarge!.copyWith(
    height: 1.6,
    letterSpacing: 0.15,
  );

  // Comment text styles
  static final TextStyle commentText =
      ArtbeatTypography.textTheme.bodyMedium!.copyWith(
    height: 1.4,
    letterSpacing: 0.25,
  );

  static final TextStyle commentAuthor =
      ArtbeatTypography.textTheme.labelMedium!.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static final TextStyle commentTimestamp =
      ArtbeatTypography.textTheme.labelSmall!.copyWith(
    color: Colors.black54,
    letterSpacing: 0.4,
  );

  // Interaction text styles
  static final TextStyle applauseCount =
      ArtbeatTypography.textTheme.labelSmall!.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static final TextStyle hashtagText =
      ArtbeatTypography.textTheme.bodyMedium!.copyWith(
    color: Colors.blue[700],
    fontWeight: FontWeight.w500,
  );

  static final TextStyle mentionText =
      ArtbeatTypography.textTheme.bodyMedium!.copyWith(
    color: Colors.purple[700],
    fontWeight: FontWeight.w500,
  );

  // Status text styles
  static final TextStyle commentCount =
      ArtbeatTypography.textTheme.labelMedium!.copyWith(
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static final TextStyle verifiedBadge =
      ArtbeatTypography.textTheme.labelSmall!.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: Colors.white,
  );

  static final TextStyle featuredLabel =
      ArtbeatTypography.textTheme.labelMedium!.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: 0.25,
    color: Colors.amber[900],
  );
}

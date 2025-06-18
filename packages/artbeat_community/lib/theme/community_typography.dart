import 'package:flutter/material.dart';

/// Typography styles for the community module
class CommunityTypography {
  const CommunityTypography(this.theme);

  final ThemeData theme;

  TextTheme get textTheme => theme.textTheme.copyWith(
        headlineMedium: studioTitle,
        titleMedium: feedPostTitle,
        bodyLarge: feedPostBody,
        bodyMedium: commentText,
        labelSmall: applauseCount,
        labelMedium: commentAuthor,
      );

  // Studio text styles
  TextStyle get studioTitle => theme.textTheme.headlineMedium!.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  TextStyle get studioDescription => theme.textTheme.bodyLarge!.copyWith(
        color: Colors.black87,
        height: 1.5,
      );

  // Feed post text styles
  TextStyle get feedPostTitle => theme.textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      );

  TextStyle get feedPostBody => theme.textTheme.bodyLarge!.copyWith(
        height: 1.6,
        letterSpacing: 0.15,
      );

  TextStyle get commentAuthor => theme.textTheme.labelMedium!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  TextStyle get commentText => theme.textTheme.bodyMedium!.copyWith(
        height: 1.4,
        letterSpacing: 0.25,
      );

  TextStyle get commentTimestamp => theme.textTheme.labelSmall!.copyWith(
        color: Colors.black54,
        letterSpacing: 0.4,
      );

  TextStyle get applauseCount => theme.textTheme.labelSmall!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  TextStyle get hashtagText => theme.textTheme.bodyMedium!.copyWith(
        color: Colors.blue[700],
        fontWeight: FontWeight.w500,
      );

  TextStyle get mentionText => theme.textTheme.bodyMedium!.copyWith(
        color: Colors.purple[700],
        fontWeight: FontWeight.w500,
      );

  TextStyle get commentCount => theme.textTheme.labelMedium!.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );

  TextStyle get verifiedBadge => theme.textTheme.labelSmall!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Colors.white,
      );

  TextStyle get featuredLabel => theme.textTheme.labelMedium!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.25,
        color: Colors.amber[900],
      );
}

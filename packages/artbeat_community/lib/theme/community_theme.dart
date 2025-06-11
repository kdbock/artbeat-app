import 'package:flutter/material.dart';
import 'package:artbeat_core/theme/index.dart';
import 'community_colors.dart';
import 'community_spacing.dart';
import 'community_typography.dart';

/// Collection of community-specific widget components
class CommunityComponents {
  /// Card theme for community content
  static CardTheme get cardTheme => CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(CommunitySpacing.canvasBorderRadius),
        ),
        color: CommunityColors.cardBackground,
        margin: const EdgeInsets.symmetric(
          horizontal: CommunitySpacing.feedHorizontalPadding,
          vertical: CommunitySpacing.feedItemSpacing,
        ),
      );

  /// Chip theme for tags and categories
  static ChipThemeData get chipTheme => ChipThemeData(
        backgroundColor: CommunityColors.threadBackground,
        labelStyle: CommunityTypography.commentText,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      );

  /// Button theme for applause actions
  static ElevatedButtonThemeData get applauseButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CommunityColors.applause,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: CommunitySpacing.applauseButtonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );

  /// Button theme for feedback actions
  static OutlinedButtonThemeData get feedbackButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CommunityColors.feedback,
          padding: CommunitySpacing.feedbackButtonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: const BorderSide(
            color: CommunityColors.feedback,
            width: 1.5,
          ),
        ),
      );

  /// List tile theme for comments
  static ListTileThemeData get listTileTheme => ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CommunitySpacing.commentHorizontalSpacing,
          vertical: CommunitySpacing.commentVerticalSpacing / 2,
        ),
        minLeadingWidth: CommunitySpacing.avatarSizeSmall,
        minVerticalPadding: CommunitySpacing.commentVerticalSpacing / 2,
        tileColor: CommunityColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );

  /// Divider theme for comment threads
  static DividerThemeData get dividerTheme => DividerThemeData(
        space: CommunitySpacing.commentVerticalSpacing,
        thickness: 1,
        color: CommunityColors.canvasBorder.withOpacity(0.2),
      );
}

/// Wraps community module widgets with appropriate theming
class CommunityThemeWrapper extends StatelessWidget {
  final Widget child;

  const CommunityThemeWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        cardTheme: CommunityComponents.cardTheme,
        chipTheme: CommunityComponents.chipTheme,
        elevatedButtonTheme: CommunityComponents.applauseButtonTheme,
        outlinedButtonTheme: CommunityComponents.feedbackButtonTheme,
        dividerTheme: CommunityComponents.dividerTheme,
        listTileTheme: CommunityComponents.listTileTheme,

        // Community-specific colors
        colorScheme: theme.colorScheme.copyWith(
          secondary: CommunityColors.applause,
          tertiary: CommunityColors.feedback,
          surface: CommunityColors.canvasBackground,
          outline: CommunityColors.canvasBorder,
        ),

        // Custom text styles for community content
        textTheme: theme.textTheme.copyWith(
          headlineMedium: CommunityTypography.studioTitle,
          titleMedium: CommunityTypography.feedPostTitle,
          bodyLarge: CommunityTypography.feedPostBody,
          bodyMedium: CommunityTypography.commentText,
          labelSmall: CommunityTypography.applauseCount,
          labelMedium: CommunityTypography.commentAuthor,
        ),
      ),
      child: child,
    );
  }
}

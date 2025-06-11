import 'package:flutter/material.dart';
import 'package:artbeat_core/theme/index.dart';

class ArtWalkThemeWrapper extends StatelessWidget {
  final Widget child;

  const ArtWalkThemeWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        // Map marker and route styles
        colorScheme: theme.colorScheme.copyWith(
          tertiary: ArtbeatColors.primaryGreen, // Route color
          tertiaryContainer: ArtbeatColors.primaryPurple, // Marker color
        ),
        // Art walk card styles
        cardTheme: CardTheme(
          elevation: 3,
          shadowColor: theme.shadowColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: theme.colorScheme.surface,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        // Location badge styles
        badgeTheme: BadgeThemeData(
          backgroundColor: theme.colorScheme.tertiary,
          textColor: theme.colorScheme.onTertiary,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          alignment: AlignmentDirectional.topStart,
        ),
        // Art walk metadata styles
        listTileTheme: ListTileThemeData(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          titleTextStyle: ArtbeatTypography.textTheme.titleMedium,
          subtitleTextStyle: ArtbeatTypography.textTheme.bodyMedium,
        ),
      ),
      child: child,
    );
  }
}

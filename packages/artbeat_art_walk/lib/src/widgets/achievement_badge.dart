import 'package:flutter/material.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

/// A widget for displaying a single achievement badge
class AchievementBadge extends StatelessWidget {
  final AchievementModel achievement;
  final bool showDetails;
  final VoidCallback? onTap;
  final bool isNew;
  final double size;

  const AchievementBadge({
    super.key,
    required this.achievement,
    this.showDetails = false,
    this.onTap,
    this.isNew = false,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget badgeContent = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Badge background
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getBadgeColors(theme),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withAlpha(76),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _getIconData(),
                size: size * 0.5,
                color: Colors.white,
              ),
            ),
          ),

          // "New" indicator
          if (isNew)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size / 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (!showDetails) {
      return badgeContent;
    }

    // Show with details
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        badgeContent,
        const SizedBox(height: 8),
        Text(
          achievement.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        if (showDetails)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              achievement.description,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  /// Get the appropriate icon for this achievement type
  IconData _getIconData() {
    final String iconName = achievement.iconName;

    // Map the string icon name to actual IconData
    switch (iconName) {
      case 'directions_walk':
        return Icons.directions_walk;
      case 'explore':
        return Icons.explore;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'collections':
        return Icons.collections;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'add_a_photo':
        return Icons.add_a_photo;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'comment':
        return Icons.comment;
      case 'share':
        return Icons.share;
      case 'palette':
        return Icons.palette;
      case 'star':
        return Icons.star;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'access_time':
        return Icons.access_time;
      default:
        return Icons.emoji_events;
    }
  }

  /// Get colors for the badge gradient based on achievement type
  List<Color> _getBadgeColors(ThemeData theme) {
    switch (achievement.type) {
      // "First" achievements - bronze
      case AchievementType.firstWalk:
      case AchievementType.artCollector:
      case AchievementType.photographer:
      case AchievementType.commentator:
      case AchievementType.socialButterfly:
      case AchievementType.curator:
      case AchievementType.earlyAdopter:
        return [const Color(0xFFCD7F32), const Color(0xFFA05B20)];

      // Mid-level achievements - silver
      case AchievementType.walkExplorer:
      case AchievementType.artExpert:
      case AchievementType.marathonWalker:
        return [const Color(0xFFC0C0C0), const Color(0xFF8a8a8a)];

      // Advanced achievements - gold
      case AchievementType.walkMaster:
      case AchievementType.contributor:
      case AchievementType.masterCurator:
        return [const Color(0xFFFFD700), const Color(0xFFB7950B)];
    }
  }
}

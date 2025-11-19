import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;

/// Activity card that matches the style of EnhancedPostCard
class ActivityCard extends StatelessWidget {
  final art_walk.SocialActivity activity;
  final VoidCallback? onTap;

  const ActivityCard({super.key, required this.activity, this.onTap});

  String _getActivityIcon(art_walk.SocialActivityType type) {
    switch (type) {
      case art_walk.SocialActivityType.discovery:
        return '🎨';
      case art_walk.SocialActivityType.capture:
        return '📸';
      case art_walk.SocialActivityType.walkCompleted:
        return '🚶';
      case art_walk.SocialActivityType.achievement:
        return '🏆';
      case art_walk.SocialActivityType.friendJoined:
        return '👋';
      case art_walk.SocialActivityType.milestone:
        return '⭐';
    }
  }

  String _getActivityTitle(art_walk.SocialActivityType type) {
    switch (type) {
      case art_walk.SocialActivityType.discovery:
        return 'Art Discovery';
      case art_walk.SocialActivityType.capture:
        return 'Art Capture';
      case art_walk.SocialActivityType.walkCompleted:
        return 'Walk Completed!';
      case art_walk.SocialActivityType.achievement:
        return 'Achievement Unlocked';
      case art_walk.SocialActivityType.friendJoined:
        return 'New Friend';
      case art_walk.SocialActivityType.milestone:
        return 'Milestone Reached';
    }
  }

  Color _getActivityColor(art_walk.SocialActivityType type) {
    switch (type) {
      case art_walk.SocialActivityType.discovery:
        return ArtbeatColors.primaryPurple;
      case art_walk.SocialActivityType.capture:
        return ArtbeatColors.primaryGreen;
      case art_walk.SocialActivityType.walkCompleted:
        return const Color(0xFF4CAF50); // Green for completion
      case art_walk.SocialActivityType.achievement:
        return const Color(0xFFFFD700); // Gold for achievements
      case art_walk.SocialActivityType.friendJoined:
        return ArtbeatColors.primaryPurple;
      case art_walk.SocialActivityType.milestone:
        return const Color(0xFFFFA500); // Orange for milestones
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityColor = _getActivityColor(activity.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: activityColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with activity icon and type
            _buildHeader(activityColor),

            // Activity message
            _buildContent(),

            // Location if available
            if (activity.location != null) _buildLocation(),

            // Timestamp
            _buildTimestamp(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color activityColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            activityColor.withValues(alpha: 0.1),
            activityColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Activity icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activityColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                _getActivityIcon(activity.type),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Activity title and user
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getActivityTitle(activity.type),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: activityColor,
                  ),
                ),
                Text(
                  activity.userName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ArtbeatColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Activity type indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: activityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              activity.type.name.toUpperCase(),
              style: TextStyle(
                color: activityColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        activity.message,
        style: const TextStyle(
          fontSize: 14,
          height: 1.4,
          color: ArtbeatColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildLocation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: 14,
            color: ArtbeatColors.textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            'Nearby',
            style: TextStyle(
              fontSize: 12,
              color: ArtbeatColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text(
        timeago.format(activity.timestamp),
        style: TextStyle(
          fontSize: 12,
          color: ArtbeatColors.textSecondary.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

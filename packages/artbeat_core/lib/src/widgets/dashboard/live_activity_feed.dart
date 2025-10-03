import 'package:flutter/material.dart';

/// Live Activity Feed - Shows social proof of art discoveries nearby
class LiveActivityFeed extends StatefulWidget {
  final List<ActivityItem> activities;
  final int maxItems;
  final VoidCallback? onTap;

  const LiveActivityFeed({
    Key? key,
    this.activities = const [],
    this.maxItems = 3,
    this.onTap,
  }) : super(key: key);

  @override
  State<LiveActivityFeed> createState() => _LiveActivityFeedState();
}

class _LiveActivityFeedState extends State<LiveActivityFeed>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use demo data if no activities provided
    final activities = widget.activities.isNotEmpty
        ? widget.activities.take(widget.maxItems).toList()
        : _getDemoActivities();

    if (activities.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.live_tv,
                    color: Colors.green,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Live Activity',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Activity list
            ...activities.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildActivityItem(activity),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(ActivityItem activity) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: activity.avatarUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    activity.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person,
                      color: Colors.black87,
                      size: 16,
                    ),
                  ),
                )
              : const Icon(Icons.person, color: Colors.black87, size: 16),
        ),

        const SizedBox(width: 12),

        // Activity content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: activity.userName,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    TextSpan(
                      text: ' ${activity.action}',
                      style: TextStyle(
                        color: Colors.black87.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    TextSpan(
                      text: ' ${activity.artworkTitle}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                activity.timeAgo,
                style: TextStyle(
                  color: Colors.black87.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Distance indicator
        if (activity.distance != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${activity.distance!.toStringAsFixed(1)}mi',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  List<ActivityItem> _getDemoActivities() {
    return const [
      ActivityItem(
        userName: 'Sarah',
        action: 'discovered',
        artworkTitle: '"Urban Dreams"',
        timeAgo: '2 min ago',
        distance: 0.3,
        avatarUrl: null,
      ),
      ActivityItem(
        userName: 'Mike',
        action: 'found',
        artworkTitle: '"Street Poetry"',
        timeAgo: '5 min ago',
        distance: 0.8,
        avatarUrl: null,
      ),
      ActivityItem(
        userName: 'Emma',
        action: 'captured',
        artworkTitle: '"City Lights"',
        timeAgo: '8 min ago',
        distance: 1.2,
        avatarUrl: null,
      ),
    ];
  }
}

/// Data model for activity items
class ActivityItem {
  final String userName;
  final String action;
  final String artworkTitle;
  final String timeAgo;
  final double? distance;
  final String? avatarUrl;

  const ActivityItem({
    required this.userName,
    required this.action,
    required this.artworkTitle,
    required this.timeAgo,
    this.distance,
    this.avatarUrl,
  });
}

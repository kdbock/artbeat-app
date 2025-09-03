import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Enhanced artwork card with the new social engagement system
class EnhancedArtworkCard extends StatelessWidget {
  final ArtworkModel artwork;
  final VoidCallback? onTap;
  final bool showEngagement;
  final bool isCompact;

  const EnhancedArtworkCard({
    super.key,
    required this.artwork,
    this.onTap,
    this.showEngagement = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 16,
        vertical: isCompact ? 4 : 8,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artist Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: isCompact ? 16 : 20,
                    backgroundColor: ArtbeatColors.primaryPurple.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(
                      Icons.person,
                      color: ArtbeatColors.primaryPurple,
                      size: isCompact ? 16 : 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artwork.artistName,
                          style: TextStyle(
                            fontSize: isCompact ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: ArtbeatColors.textPrimary,
                          ),
                        ),
                        Text(
                          _formatTimeAgo(artwork.createdAt),
                          style: TextStyle(
                            fontSize: isCompact ? 11 : 12,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    color: ArtbeatColors.textSecondary,
                    onPressed: () => _showArtworkOptions(context),
                  ),
                ],
              ),
            ),

            // Artwork Image
            Container(
              width: double.infinity,
              height: isCompact ? 200 : 300,
              decoration: BoxDecoration(
                color: ArtbeatColors.backgroundSecondary,
                image: artwork.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(artwork.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: artwork.imageUrl.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.image,
                        size: 64,
                        color: ArtbeatColors.textSecondary,
                      ),
                    )
                  : null,
            ),

            // Artwork Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Description
                  Text(
                    artwork.title,
                    style: TextStyle(
                      fontSize: isCompact ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: ArtbeatColors.textPrimary,
                    ),
                  ),
                  if (artwork.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      artwork.description,
                      style: TextStyle(
                        fontSize: isCompact ? 13 : 14,
                        color: ArtbeatColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: isCompact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Artwork Tags
                  if (artwork.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: artwork.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ArtbeatColors.primaryPurple.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ArtbeatColors.primaryPurple.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: ArtbeatColors.primaryPurple,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Price and Sale Info
                  if (!artwork.isSold && artwork.price > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ArtbeatColors.accentGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ArtbeatColors.accentGold.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 16,
                            color: ArtbeatColors.accentGold,
                          ),
                          Text(
                            '\$${artwork.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ArtbeatColors.accentGold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'For Sale',
                            style: TextStyle(
                              fontSize: 12,
                              color: ArtbeatColors.accentGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Engagement Bar
            if (showEngagement)
              ContentEngagementBar(
                contentId: artwork.id,
                contentType: 'artwork',
                initialStats: EngagementStats(
                  likeCount: artwork.applauseCount,
                  commentCount: 0,
                  shareCount: 0,
                  seenCount: artwork.viewsCount,
                  lastUpdated: artwork.createdAt,
                ),
                isCompact: isCompact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showArtworkOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Options
            _buildOption(
              icon: Icons.share,
              title: 'Share Artwork',
              onTap: () {
                Navigator.pop(context);
                // Handle share
              },
            ),
            _buildOption(
              icon: Icons.bookmark_border,
              title: 'Save to Collection',
              onTap: () {
                Navigator.pop(context);
                // Handle save
              },
            ),
            _buildOption(
              icon: Icons.report_outlined,
              title: 'Report',
              onTap: () {
                Navigator.pop(context);
                // Handle report
              },
            ),
            _buildOption(
              icon: Icons.block,
              title: 'Hide from Feed',
              onTap: () {
                Navigator.pop(context);
                // Handle hide
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: ArtbeatColors.textSecondary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: ArtbeatColors.textPrimary),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

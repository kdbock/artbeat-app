import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'artist_avatar.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final List<CommentModel> comments;
  final void Function(String) onUserTap;
  final void Function(PostModel) onApplause;
  final void Function(String) onComment;
  final void Function(PostModel) onShare;
  final void Function(PostModel)? onFeature;
  final void Function(PostModel)? onGift;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.comments,
    required this.onUserTap,
    required this.onApplause,
    required this.onComment,
    required this.onShare,
    this.onFeature,
    this.onGift,
    this.isExpanded = false,
    required this.onToggleExpand,
  });

  /// Get the post type based on the PostModel
  String get postType => 'POST';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      elevation: 2,
      color: ArtbeatColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and post header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArtistAvatar(
                  imageUrl: post.userPhotoUrl,
                  displayName: post.userName,
                  isVerified: post.isUserVerified,
                  onTap: () {
                    debugPrint(
                      'Avatar tapped - User: ${post.userName}, PhotoURL: "${post.userPhotoUrl}"',
                    );
                    onUserTap(post.userId);
                  },
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: ArtbeatColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 2,
                            child: Text(
                              post.location,
                              style: const TextStyle(
                                color: ArtbeatColors.textSecondary,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: ArtbeatColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              timeago.format(post.createdAt),
                              style: const TextStyle(
                                color: ArtbeatColors.textSecondary,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Post type button in top right corner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPostTypeColor().withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPostTypeColor().withAlpha(77),
                    ),
                  ),
                  child: Text(
                    postType,
                    style: TextStyle(
                      color: _getPostTypeColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Post content
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 15,
                  height: 1.4,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
            ),

          // Post images (Artwork section)
          if (post.imageUrls.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: ArtbeatColors.black.withAlpha(26), // 0.1 opacity
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: PageView.builder(
                    itemCount: post.imageUrls.length,
                    itemBuilder: (context, index) {
                      final imageUrl = post.imageUrls[index];
                      if (imageUrl.isEmpty) {
                        return Container(
                          color: ArtbeatColors.backgroundSecondary,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: ArtbeatColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      return ImageManagementService().getOptimizedImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          color: ArtbeatColors.backgroundSecondary,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: ArtbeatColors.primaryPurple,
                            ),
                          ),
                        ),
                        errorWidget: Container(
                          color: ArtbeatColors.error.withAlpha(25),
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: ArtbeatColors.error,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Tags and metadata
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: post.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ArtbeatColors.primaryPurple.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ArtbeatColors.primaryPurple.withAlpha(77),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        color: ArtbeatColors.primaryPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Applause button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.thumb_up_outlined,
                    label: 'Appreciate',
                    count: post.applauseCount,
                    color: ArtbeatColors.accentYellow,
                    onTap: () => onApplause(post),
                  ),
                ),
                const SizedBox(width: 8),
                // Comment button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.comment_outlined,
                    label: 'Comment',
                    count: comments.length,
                    color: ArtbeatColors.primaryPurple,
                    onTap: () => onComment(post.id),
                  ),
                ),
                const SizedBox(width: 8),
                // Feature button (only for admins/moderators)
                if (onFeature != null)
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.star_outline,
                      label: 'Feature',
                      color: ArtbeatColors.primaryGreen,
                      onTap: () => onFeature!(post),
                    ),
                  ),
                if (onFeature != null) const SizedBox(width: 8),
                // Gift button
                if (onGift != null)
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.card_giftcard_outlined,
                      label: 'Gift',
                      color: ArtbeatColors.primaryPurple,
                      onTap: () => onGift!(post),
                    ),
                  ),
                if (onGift != null) const SizedBox(width: 8),
                // Share button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    color: ArtbeatColors.primaryGreen,
                    onTap: () => onShare(post),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get the color for the post type badge
  Color _getPostTypeColor() {
    switch (postType) {
      case 'ARTWORK':
        return ArtbeatColors.primaryPurple;
      case 'EVENT':
        return ArtbeatColors.primaryGreen;
      case 'ART WALK':
        return Colors.blue;
      case 'OPPORTUNITY':
        return Colors.orange;
      default:
        return ArtbeatColors.textSecondary;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    int? count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                count != null && count > 0 ? '$count' : label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

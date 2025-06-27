import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'applause_button.dart';
import 'artist_avatar.dart';
import 'package:artbeat_core/artbeat_core.dart' show ArtbeatColors;
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/gifts/gift_modal.dart';
import '../screens/sponsorships/sponsor_modal.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final List<CommentModel> comments;
  final void Function(String) onUserTap;
  final void Function(PostModel) onApplause;
  final void Function(String) onComment;
  final void Function(PostModel) onShare;
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
    this.isExpanded = false,
    required this.onToggleExpand,
  });

  // Always show gift/sponsor/applause for all posts in the artist community feed
  bool get canGift => true;

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
                // Gift and Sponsor buttons - constrain this column
                SizedBox(
                  width: 80, // Fixed width to prevent overflow
                  child: Column(
                    children: [
                      if (canGift) ...[
                        _buildActionChip(
                          context,
                          icon: Icons.card_giftcard,
                          label: 'Gift',
                          color: ArtbeatColors.primaryPurple,
                          onTap: () => showDialog<GiftModal>(
                            context: context,
                            builder: (ctx) =>
                                GiftModal(recipientId: post.userId),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildActionChip(
                          context,
                          icon: Icons.volunteer_activism,
                          label: 'Sponsor',
                          color: ArtbeatColors.accentYellow,
                          onTap: () => showDialog<SponsorModal>(
                            context: context,
                            builder: (ctx) =>
                                SponsorModal(artistId: post.userId),
                          ),
                        ),
                      ],
                      if (post.userId == currentUserId)
                        IconButton(
                          icon: const Icon(
                            Icons.more_vert,
                            color: ArtbeatColors.textSecondary,
                          ),
                          onPressed: () => _showPostOptions(context),
                        ),
                    ],
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
                      return CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: ArtbeatColors.backgroundSecondary,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: ArtbeatColors.primaryPurple,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
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
                ApplauseButton(
                  postId: post.id,
                  userId: currentUserId,
                  count: post.applauseCount,
                  onTap: () => onApplause(post),
                  maxApplause: PostModel.maxApplausePerUser,
                  color: ArtbeatColors.accentYellow,
                ),
                const SizedBox(width: 8),
                // Art Discussion button (renamed from comment)
                Expanded(
                  flex: 2,
                  child: _buildActionButton(
                    icon: Icons.palette_outlined,
                    label: 'Art Discussion',
                    count: comments.length,
                    color: ArtbeatColors.primaryPurple,
                    onTap: () => onComment(post.id),
                  ),
                ),
                const SizedBox(width: 8),
                // Share button
                Expanded(
                  flex: 1,
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

  Widget _buildActionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              count != null && count > 0 ? '$label ($count)' : label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Post'),
            onTap: () {
              Navigator.pop(context);
              _handleEditPost(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Post'),
            onTap: () {
              Navigator.pop(context);
              _handleDeletePost(context);
            },
          ),
        ],
      ),
    );
  }

  void _handleEditPost(BuildContext context) {
    // Implement edit post functionality
  }

  void _handleDeletePost(BuildContext context) {
    // Implement delete post functionality
  }
}

import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'applause_button.dart';
import 'artist_avatar.dart';
import '../theme/index.dart';
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

  CommunityTypography _getTypography(BuildContext context) {
    return CommunityTypography(Theme.of(context));
  }

  // Always show gift/sponsor/applause for all posts in the artist community feed
  bool get canGift => true;

  @override
  Widget build(BuildContext context) {
    final typography = _getTypography(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gift and Sponsor buttons on top right
          if (canGift)
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog<GiftModal>(
                        context: context,
                        builder: (ctx) => GiftModal(recipientId: post.userId),
                      );
                    },
                    icon: const Icon(Icons.card_giftcard, color: Colors.purple),
                    label: const Text('Gift'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog<SponsorModal>(
                        context: context,
                        builder: (ctx) => SponsorModal(artistId: post.userId),
                      );
                    },
                    icon: const Icon(
                      Icons.volunteer_activism,
                      color: Colors.amber,
                    ),
                    label: const Text('Sponsor'),
                  ),
                ],
              ),
            ),

          // User info and post header
          ListTile(
            leading: ArtistAvatar(
              imageUrl: post.userPhotoUrl,
              displayName: post.userName,
              isVerified: post.isUserVerified,
              onTap: () => onUserTap(post.userId),
              radius: CommunitySpacing.avatarSizeMedium,
            ),
            title: Text(post.userName, style: typography.feedPostTitle),
            subtitle: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 153,
                  ), // Fixed deprecated withOpacity
                ),
                const SizedBox(width: 4),
                Text(post.location, style: typography.commentTimestamp),
                const SizedBox(width: 8),
                Text('•', style: typography.commentTimestamp),
                const SizedBox(width: 8),
                Text(
                  timeago.format(post.createdAt),
                  style: typography.commentTimestamp,
                ),
              ],
            ),
            trailing: post.userId == currentUserId
                ? IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showPostOptions(context),
                  )
                : null,
          ),

          // Post content
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CommunitySpacing.feedHorizontalPadding,
                vertical: CommunitySpacing.feedItemSpacing,
              ),
              child: Text(post.content, style: typography.feedPostBody),
            ),

          // Post images (Canvas section)
          if (post.imageUrls.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  CommunitySpacing.canvasBorderRadius,
                ),
                border: Border.all(
                  color: CommunityColors.canvasBorder.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  CommunitySpacing.canvasBorderRadius,
                ),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: PageView.builder(
                    itemCount: post.imageUrls.length,
                    itemBuilder: (context, index) {
                      final imageUrl = post.imageUrls[index];
                      if (imageUrl.isEmpty) {
                        return Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Theme.of(context).colorScheme.surface,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.error.withValues(alpha: 25),
                              child: const Center(
                                child: Icon(Icons.error_outline),
                              ),
                            ),
                          ),
                          // Gradient overlay for text visibility
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 72,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 153),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

          // Tags and metadata
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CommunitySpacing.feedHorizontalPadding,
                vertical: CommunitySpacing.feedItemSpacing,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: post.tags.map((tag) {
                  return Chip(
                    label: Text('#$tag', style: typography.hashtagText),
                    backgroundColor: CommunityColors.threadBackground,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
            ),

          // Action buttons (applause and comment) on bottom
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: CommunityColors.canvasBorder.withValues(alpha: 25),
                ),
              ),
            ),
            padding: const EdgeInsets.all(CommunitySpacing.feedItemSpacing),
            child: Row(
              children: [
                // Yellow applause button
                ApplauseButton(
                  postId: post.id,
                  userId: currentUserId,
                  count: post.applauseCount,
                  onTap: () => onApplause(post),
                  maxApplause: PostModel.maxApplausePerUser,
                  color: Colors.amber,
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => onComment(post.id),
                  icon: const Icon(Icons.comment_outlined, color: Colors.blue),
                  tooltip: 'Comment',
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => onShare(post),
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Share this artwork',
                ),
              ],
            ),
          ),

          // Comments section
          if (comments.isNotEmpty)
            InkWell(
              onTap: onToggleExpand,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: CommunityColors.canvasBorder.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: CommunitySpacing.feedHorizontalPadding,
                  vertical: CommunitySpacing.feedItemSpacing,
                ),
                child: Row(
                  children: [
                    Text(
                      'View ${comments.length} comments',
                      style: typography.commentCount.copyWith(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ],
                ),
              ),
            ),

          // Expanded comments
          if (isExpanded && comments.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: CommunityColors.threadBackground,
                border: Border(
                  top: BorderSide(
                    color: CommunityColors.canvasBorder.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == comments.length - 1
                          ? 0
                          : CommunitySpacing.commentVerticalSpacing,
                    ),
                    child: ListTile(
                      leading: ArtistAvatar(
                        imageUrl: comment.userAvatarUrl,
                        displayName: comment.userName,
                        radius: CommunitySpacing.avatarSizeSmall,
                      ),
                      title: Row(
                        children: [
                          Text(
                            comment.userName,
                            style: typography.commentAuthor,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.tertiary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              comment.type,
                              style: typography.commentCount.copyWith(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timeago.format(comment.createdAt.toDate()),
                            style: typography.commentTimestamp,
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          comment.content,
                          style: typography.commentText,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: CommunitySpacing.feedHorizontalPadding,
                        vertical: CommunitySpacing.commentVerticalSpacing / 2,
                      ),
                    ),
                  );
                },
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

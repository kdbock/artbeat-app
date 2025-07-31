import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'applause_button.dart';
import 'artist_avatar.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../screens/gifts/gift_modal.dart';
import '../screens/sponsorships/sponsor_modal.dart';

class CritiqueCard extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final List<CommentModel> comments;
  final void Function(String) onUserTap;
  final void Function(PostModel) onApplause;
  final void Function(String) onComment;
  final void Function(PostModel) onShare;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const CritiqueCard({
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: ArtbeatColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.black.withAlpha(15), // 0.06 opacity
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artwork Section - Primary Focus
          if (post.imageUrls.isNotEmpty) _buildArtworkSection(),

          // User Information - Minimal Header
          _buildArtistHeader(context, theme),

          // Post Description
          if (post.content.isNotEmpty) _buildDescription(theme),

          // Tags
          if (post.tags.isNotEmpty) _buildTags(),

          // Critique Actions - Focused on Feedback
          _buildCritiqueActions(theme),

          // Preview of Recent Feedback
          if (comments.isNotEmpty) _buildFeedbackPreview(theme),
        ],
      ),
    );
  }

  Widget _buildArtworkSection() {
    final hasImages =
        post.imageUrls.isNotEmpty && post.imageUrls.first.isNotEmpty;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 400, minHeight: 200),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Stack(
          children: [
            hasImages
                ? _ArtworkPageView(imageUrls: post.imageUrls)
                : Image.asset(
                    'assets/default_artwork.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
            // Artwork status indicator
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ArtbeatColors.primaryPurple.withAlpha(230),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.feedback_outlined,
                      size: 14,
                      color: ArtbeatColors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Seeking Critique',
                      style: TextStyle(
                        color: ArtbeatColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistHeader(BuildContext context, ThemeData theme) {
    final userPhotoUrl = post.userPhotoUrl.isNotEmpty
        ? post.userPhotoUrl
        : 'assets/default_profile.png';

    final displayName = post.userName.isNotEmpty
        ? '@${post.userName}'
        : 'Unknown User';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ArtistAvatar(
            imageUrl: userPhotoUrl,
            displayName: post.userName,
            isVerified: post.isUserVerified,
            onTap: () => onUserTap(post.userId),
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ArtbeatColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (post.isUserVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 16,
                        color: ArtbeatColors.primaryPurple,
                      ),
                    ],
                  ],
                ),
                Text(
                  '${timeago.format(post.createdAt)} • ${post.location}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ArtbeatColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Show comment and applause counts
          Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.comment_outlined,
                    size: 16,
                    color: ArtbeatColors.primaryPurple,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${post.commentCount}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.emoji_emotions_outlined,
                    size: 16,
                    color: ArtbeatColors.accentYellow,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${post.applauseCount}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Support actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSupportButton(
                context: context,
                icon: Icons.card_giftcard_outlined,
                label: 'Gift',
                color: ArtbeatColors.primaryPurple,
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (ctx) => GiftModal(recipientId: post.userId),
                ),
              ),
              const SizedBox(width: 8),
              _buildSupportButton(
                context: context,
                icon: Icons.volunteer_activism_outlined,
                label: 'Sponsor',
                color: ArtbeatColors.accentYellow,
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (ctx) => SponsorModal(artistId: post.userId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Post Description',
            style: theme.textTheme.labelLarge?.copyWith(
              color: ArtbeatColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            post.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              height: 1.4,
              color: ArtbeatColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: post.tags.map<Widget>((String tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ArtbeatColors.primaryPurple.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ArtbeatColors.primaryPurple.withAlpha(77),
                width: 1,
              ),
            ),
            child: Text(
              '#$tag',
              style: const TextStyle(
                color: ArtbeatColors.primaryPurple,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCritiqueActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: ArtbeatColors.backgroundSecondary, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community Feedback',
            style: theme.textTheme.labelLarge?.copyWith(
              color: ArtbeatColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Helpful feedback button
              Expanded(
                flex: 2,
                child: _buildCritiqueButton(
                  icon: Icons.comment_outlined,
                  label: 'Give Critique',
                  count: comments.length,
                  color: ArtbeatColors.primaryPurple,
                  onTap: () => onComment(post.id),
                ),
              ),
              const SizedBox(width: 12),
              // Appreciation button
              Expanded(
                flex: 1,
                child: ApplauseButton(
                  postId: post.id,
                  userId: currentUserId,
                  count: post.applauseCount,
                  onTap: () => onApplause(post),
                  maxApplause: PostModel.maxApplausePerUser,
                  color: ArtbeatColors.accentYellow,
                ),
              ),
              const SizedBox(width: 12),
              // Share button
              Expanded(
                flex: 1,
                child: _buildIconButton(
                  icon: Icons.share_outlined,
                  color: ArtbeatColors.primaryGreen,
                  onTap: () => onShare(post),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCritiqueButton({
    required IconData icon,
    required String label,
    int? count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                count != null && count > 0 ? '$label ($count)' : label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77), width: 1),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildFeedbackPreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: ArtbeatColors.backgroundSecondary, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Feedback',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: ArtbeatColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (comments.length > 2)
                GestureDetector(
                  onTap: () => onComment(post.id),
                  child: Text(
                    'View All (${comments.length})',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: ArtbeatColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...comments
              .take(2)
              .map<Widget>(
                (CommentModel comment) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildCommentPreview(comment, theme),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildCommentPreview(CommentModel comment, ThemeData theme) {
    // Use asset fallback if userAvatarUrl is empty or not a valid network URL
    String avatarUrl = comment.userAvatarUrl;
    if (avatarUrl.isEmpty ||
        avatarUrl == 'placeholder_headshot_url' ||
        !(avatarUrl.startsWith('http://') ||
            avatarUrl.startsWith('https://'))) {
      avatarUrl = 'assets/default_profile.png';
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ArtistAvatar(
          imageUrl: avatarUrl,
          displayName: comment.userName,
          isVerified: false, // CommentModel doesn't have isVerified field
          onTap: () => onUserTap(comment.userId),
          radius: 12,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.userName,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              Text(
                comment.content,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ArtbeatColors.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Top-level widget for artwork page view with fallback and counter
class _ArtworkPageView extends StatefulWidget {
  final List<String> imageUrls;
  const _ArtworkPageView({required this.imageUrls});

  @override
  State<_ArtworkPageView> createState() => _ArtworkPageViewState();
}

class _ArtworkPageViewState extends State<_ArtworkPageView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: widget.imageUrls.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (context, index) {
            final imageUrl = widget.imageUrls[index];
            if (imageUrl.isEmpty) {
              return Image.asset(
                'assets/default_artwork.png',
                fit: BoxFit.cover,
                width: double.infinity,
              );
            }
            return ImageManagementService().getOptimizedImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: Image.asset(
                'assets/default_artwork.png',
                fit: BoxFit.cover,
              ),
              errorWidget: Image.asset(
                'assets/default_artwork.png',
                fit: BoxFit.cover,
              ),
            );
          },
        ),
        if (widget.imageUrls.length > 1)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ArtbeatColors.black.withAlpha(179),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.imageUrls.length}',
                style: const TextStyle(
                  color: ArtbeatColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

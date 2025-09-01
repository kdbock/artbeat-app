import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Post card widget using the universal engagement system
/// This replaces the old post card with Appreciate/Connect/Discuss/Amplify actions
class PostCard extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final List<CommentModel> comments;
  final void Function(String) onUserTap;
  final void Function(String) onComment;
  // Removed legacy onApplause and onShare callbacks; use UniversalEngagementBar via UniversalContentCard
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
    required this.onComment,
    this.onFeature,
    this.onGift,
    this.isExpanded = false,
    required this.onToggleExpand,
  });

  /// Get the post type based on the PostModel
  String get postType => 'POST';

  @override
  Widget build(BuildContext context) {
    return UniversalContentCard(
      contentId: post.id,
      contentType: 'post',
      // Use a short title and full description to avoid duplication in the UI
      title: post.content.length > 80
          ? '${post.content.substring(0, 77)}...'
          : post.content,
      description: post.content.isNotEmpty ? post.content : null,
      imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls.first : null,
      authorName: post.userName,
      authorImageUrl: post.userPhotoUrl,
      authorId: post.userId,
      createdAt: post.createdAt,
      engagementStats: post.engagementStats,
      tags: post.tags,
      // Tapping a post should open the post detail modal (navigate to comments)
      // The feed passes onComment to open the detail view; keep onToggleExpand
      // for explicit expand controls if needed.
      onTap: () => onComment(post.id),
      onAuthorTap: () => onUserTap(post.userId),
      onDiscuss: () => onComment(post.id),
      onAmplify:
          null, // use engagement bar's default amplify behavior or pass a handler via props if needed
      onGift: () => onGift?.call(post),
      showGift: true,
      isCompact: !isExpanded,
    );
  }
}

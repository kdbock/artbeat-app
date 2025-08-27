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
  final void Function(PostModel) onApplause; // Legacy - will be removed
  final void Function(String) onComment;
  final void Function(PostModel) onShare; // Legacy - will be removed
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
    return UniversalContentCard(
      contentId: post.id,
      contentType: 'post',
      title: post.content,
      description: post.content.length > 100 ? null : post.content,
      imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls.first : null,
      authorName: post.userName,
      authorImageUrl: post.userPhotoUrl,
      authorId: post.userId,
      createdAt: post.createdAt,
      engagementStats: post.engagementStats,
      tags: post.tags,
      onTap: onToggleExpand,
      onAuthorTap: () => onUserTap(post.userId),
      onDiscuss: () => onComment(post.id),
      onAmplify: () => onShare(post), // Legacy callback
      isCompact: !isExpanded,
    );
  }
}

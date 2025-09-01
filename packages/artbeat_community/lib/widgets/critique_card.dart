import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'post_card.dart';
// Compatibility shim: CritiqueCard is deprecated. Use `PostCard` instead.
// This file keeps older imports working while directing usage to the new PostCard.

@deprecated
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
    // Forward to PostCard for the simplified social feed UI
    return PostCard(
      post: post,
      currentUserId: currentUserId,
      comments: comments,
      onUserTap: onUserTap,
      onComment: onComment,
      isExpanded: isExpanded,
      onToggleExpand: onToggleExpand,
    );
  }
}

// Artwork Section - Primary Focus

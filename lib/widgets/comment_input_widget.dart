import 'package:flutter/material.dart';
import 'package:artbeat/services/community_service.dart';
import 'package:artbeat/models/comment_model.dart';

/// A widget for entering and submitting comments on posts
class CommentInputWidget extends StatefulWidget {
  final String postId;
  final Function(CommentModel) onCommentAdded;
  final String? parentCommentId;
  final FocusNode? focusNode;
  final String? replyingTo;

  const CommentInputWidget({
    super.key,
    required this.postId,
    required this.onCommentAdded,
    this.parentCommentId,
    this.focusNode,
    this.replyingTo,
  });

  @override
  State<CommentInputWidget> createState() => _CommentInputWidgetState();
}

class _CommentInputWidgetState extends State<CommentInputWidget> {
  final TextEditingController _commentController = TextEditingController();
  final CommunityService _communityService = CommunityService();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.replyingTo != null) {
      _commentController.text = '@${widget.replyingTo} ';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Extract mentioned users from comment text
      final List<String> mentionedUsers = [];
      final RegExp mentionRegex = RegExp(r'@(\w+)');
      final matches = mentionRegex.allMatches(content);

      for (final match in matches) {
        if (match.groupCount >= 1) {
          final username = match.group(1);
          if (username != null && username.isNotEmpty) {
            mentionedUsers.add(username);
          }
        }
      }

      // Add comment to post
      final commentId = await _communityService.addComment(
        postId: widget.postId,
        content: content,
        parentCommentId: widget.parentCommentId,
        mentionedUsers: mentionedUsers.isNotEmpty ? mentionedUsers : null,
      );

      // Get the comment model
      final comments = await _communityService.getCommentsForPost(
        widget.postId,
        limit: 1,
        startAfter: null,
        onlyWithId: commentId,
      );

      if (comments.isNotEmpty) {
        widget.onCommentAdded(comments.first);
      }

      // Clear the input field
      _commentController.clear();

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: const AssetImage('assets/default_profile.png'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: widget.focusNode,
              decoration: InputDecoration(
                hintText: widget.parentCommentId != null
                    ? 'Reply to comment...'
                    : 'Add a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              textInputAction: TextInputAction.send,
              minLines: 1,
              maxLines: 5,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: _isSubmitting ? null : _submitComment,
          ),
        ],
      ),
    );
  }
}

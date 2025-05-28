import 'package:flutter/material.dart';
import 'package:artbeat/models/comment_model.dart';
import 'package:artbeat/services/community_service.dart';
import 'package:artbeat/widgets/comment_input_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

/// A widget for displaying comments on a post with a modern UX
class CommentListWidget extends StatefulWidget {
  final String postId;
  final List<CommentModel> initialComments;
  final int maxVisibleComments;
  final Function(int) onCommentCountChanged;

  const CommentListWidget({
    super.key,
    required this.postId,
    required this.initialComments,
    this.maxVisibleComments = 3,
    required this.onCommentCountChanged,
  });

  @override
  State<CommentListWidget> createState() => _CommentListWidgetState();
}

class _CommentListWidgetState extends State<CommentListWidget> {
  late List<CommentModel> _comments;
  final CommunityService _communityService = CommunityService();
  bool _isLoadingMoreComments = false;
  bool _hasMoreComments = true;
  String? _selectedCommentId; // For replying to specific comments
  final Map<String, FocusNode> _replyFocusNodes = {};
  final Map<String, bool> _showReplies = {};

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.initialComments);
    _loadTopLevelComments();
  }

  @override
  void didUpdateWidget(CommentListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialComments != widget.initialComments) {
      _comments = List.from(widget.initialComments);
    }
  }

  @override
  void dispose() {
    // Dispose all focus nodes
    for (final node in _replyFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// Get a focus node for replying to a comment
  FocusNode _getFocusNodeForComment(String commentId) {
    if (!_replyFocusNodes.containsKey(commentId)) {
      _replyFocusNodes[commentId] = FocusNode();
    }
    return _replyFocusNodes[commentId]!;
  }

  /// Load the top-level comments for a post
  Future<void> _loadTopLevelComments() async {
    if (_isLoadingMoreComments || !_hasMoreComments) return;

    setState(() {
      _isLoadingMoreComments = true;
    });

    try {
      // Get the last visible comment as the starting point
      final lastComment = _comments.isNotEmpty ? _comments.last : null;
      final documentSnapshot = lastComment?.id;

      // Load more comments
      final moreComments = await _communityService.getCommentsForPost(
        widget.postId,
        limit: 10, // Load 10 more comments
        startAfter: documentSnapshot,
      );

      if (mounted) {
        setState(() {
          if (moreComments.isEmpty) {
            _hasMoreComments = false;
          } else {
            // Append new comments to the list
            _comments.addAll(moreComments);
          }
          _isLoadingMoreComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMoreComments = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading comments: ${e.toString()}')),
        );
      }
    }
  }

  /// Load replies for a specific comment
  Future<void> _loadRepliesForComment(String commentId) async {
    setState(() {
      _showReplies[commentId] = true;
    });

    try {
      final replies = await _communityService.getCommentReplies(
        widget.postId,
        commentId,
      );

      if (mounted) {
        setState(() {
          // Add replies to the comment list
          for (final reply in replies) {
            if (!_comments.any((c) => c.id == reply.id)) {
              _comments.add(reply);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading replies: ${e.toString()}')),
        );
      }
    }
  }

  /// Handle a new comment being added
  void _handleCommentAdded(CommentModel comment) {
    setState(() {
      // Add the new comment to the list
      if (!_comments.any((c) => c.id == comment.id)) {
        _comments.add(comment);
      }
    });

    // Notify parent widget about the new comment count
    widget.onCommentCountChanged(_comments.length);
  }

  /// Format the timestamp for display
  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }

  /// Start replying to a comment
  void _replyToComment(String commentId, String userName) {
    setState(() {
      _selectedCommentId = commentId;
    });

    // Focus the input field
    final focusNode = _getFocusNodeForComment(commentId);
    focusNode.requestFocus();
  }

  /// Build a single comment widget
  Widget _buildCommentWidget(CommentModel comment, {bool isReply = false}) {
    final isParentComment = comment.parentCommentId == null;
    final replies =
        _comments.where((c) => c.parentCommentId == comment.id).toList();
    final hasReplies = replies.isNotEmpty;
    final showReplies = _showReplies[comment.id] ?? false;

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 40.0 : 0.0,
        bottom: 8.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: comment.userPhotoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(comment.userPhotoUrl)
                        as ImageProvider
                    : const AssetImage('assets/default_profile.png'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(comment.content),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                      child: Row(
                        children: [
                          Text(
                            _formatTimestamp(comment.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () =>
                                _replyToComment(comment.id, comment.userName),
                            child: Text(
                              'Reply',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Show reply input if selected for reply
          if (_selectedCommentId == comment.id)
            Padding(
              padding: const EdgeInsets.only(left: 40.0, top: 8.0),
              child: CommentInputWidget(
                postId: widget.postId,
                onCommentAdded: _handleCommentAdded,
                parentCommentId: comment.id,
                focusNode: _getFocusNodeForComment(comment.id),
                replyingTo: comment.userName,
              ),
            ),

          // Show "View replies" button if there are replies
          if (hasReplies && isParentComment && !showReplies)
            Padding(
              padding: const EdgeInsets.only(left: 40.0, top: 4.0),
              child: TextButton.icon(
                onPressed: () => _loadRepliesForComment(comment.id),
                icon: const Icon(Icons.subdirectory_arrow_right, size: 14),
                label: Text(
                    'View ${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),

          // Show replies if expanded
          if (hasReplies && showReplies)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: replies
                  .map((reply) => _buildCommentWidget(reply, isReply: true))
                  .toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter comments to show only top-level initially, unless we have replies to show
    final topLevelComments = _comments
        .where((comment) => comment.parentCommentId == null)
        .take(widget.maxVisibleComments)
        .toList();

    // Also include any comments that have replies being shown
    final visibleReplies = _comments
        .where((comment) =>
            comment.parentCommentId != null &&
            _showReplies[comment.parentCommentId] == true)
        .toList();

    // Combine the lists
    final visibleComments = [...topLevelComments, ...visibleReplies];

    // Sort by creation date
    visibleComments.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Get only unique comments
    final uniqueComments = <CommentModel>[];
    for (final comment in visibleComments) {
      if (!uniqueComments.any((c) => c.id == comment.id)) {
        uniqueComments.add(comment);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments list
        if (uniqueComments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('No comments yet'),
          )
        else
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: uniqueComments
                  .where((comment) =>
                      comment.parentCommentId == null ||
                      _showReplies[comment.parentCommentId] == true)
                  .map((comment) => _buildCommentWidget(
                        comment,
                        isReply: comment.parentCommentId != null,
                      ))
                  .toList(),
            ),
          ),

        // "View more comments" button if needed
        if (_hasMoreComments && _comments.length >= widget.maxVisibleComments)
          Center(
            child: TextButton(
              onPressed: _isLoadingMoreComments ? null : _loadTopLevelComments,
              child: _isLoadingMoreComments
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('View more comments'),
            ),
          ),

        // Main comment input field (for top-level comments)
        if (_selectedCommentId == null)
          CommentInputWidget(
            postId: widget.postId,
            onCommentAdded: _handleCommentAdded,
          ),
      ],
    );
  }
}

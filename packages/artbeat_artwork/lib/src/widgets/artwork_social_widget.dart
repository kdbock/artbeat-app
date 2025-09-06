import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/artwork_rating_model.dart';
import '../services/artwork_rating_service.dart';
import '../services/artwork_comment_service.dart';

/// Comprehensive social engagement widget for artwork
///
/// Provides ratings, comments, and social interaction features
/// in a unified interface for artwork detail screens.
class ArtworkSocialWidget extends StatefulWidget {
  final String artworkId;
  final String artworkTitle;
  final bool showComments;
  final bool showRatings;
  final VoidCallback? onEngagementChanged;

  const ArtworkSocialWidget({
    super.key,
    required this.artworkId,
    required this.artworkTitle,
    this.showComments = true,
    this.showRatings = true,
    this.onEngagementChanged,
  });

  @override
  State<ArtworkSocialWidget> createState() => _ArtworkSocialWidgetState();
}

class _ArtworkSocialWidgetState extends State<ArtworkSocialWidget> {
  final ArtworkRatingService _ratingService = ArtworkRatingService();
  final ArtworkCommentService _commentService = ArtworkCommentService();
  final TextEditingController _commentController = TextEditingController();

  ArtworkRatingStats? _ratingStats;
  ArtworkRatingModel? _userRating;
  bool _isLoadingRating = false;
  bool _isPostingComment = false;
  int _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    _loadRatingData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadRatingData() async {
    if (!widget.showRatings) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final stats = await _ratingService.getArtworkRatingStats(widget.artworkId);
    final userRating = await _ratingService.getUserRatingForArtwork(
      widget.artworkId,
      user.uid,
    );

    if (mounted) {
      setState(() {
        _ratingStats = stats;
        _userRating = userRating;
        _selectedRating = userRating?.rating ?? 0;
      });
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0 || _isLoadingRating) return;

    setState(() {
      _isLoadingRating = true;
    });

    final success = await _ratingService.submitRating(
      artworkId: widget.artworkId,
      rating: _selectedRating,
    );

    if (success != null) {
      await _loadRatingData();
      widget.onEngagementChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_userRating == null
                ? 'Rating submitted successfully!'
                : 'Rating updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit rating. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingRating = false;
      });
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || _isPostingComment) return;

    setState(() {
      _isPostingComment = true;
    });

    final success = await _commentService.postComment(
      artworkId: widget.artworkId,
      content: _commentController.text.trim(),
    );

    if (success != null) {
      _commentController.clear();
      widget.onEngagementChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post comment. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isPostingComment = false;
      });
    }
  }

  Widget _buildRatingSection() {
    if (!widget.showRatings || _ratingStats == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Ratings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Average rating display
            if (_ratingStats!.totalRatings > 0) ...[
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < _ratingStats!.averageRating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 24,
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    '${_ratingStats!.averageRating.toStringAsFixed(1)} (${_ratingStats!.totalRatings} ratings)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // User rating input
            if (FirebaseAuth.instance.currentUser != null) ...[
              Text(
                _userRating == null
                    ? 'Rate this artwork:'
                    : 'Update your rating:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    final rating = index + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRating = rating;
                        });
                      },
                      child: Icon(
                        rating <= _selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    );
                  }),
                  const SizedBox(width: 16),
                  if (_selectedRating > 0 &&
                      _selectedRating != _userRating?.rating)
                    ElevatedButton(
                      onPressed: _isLoadingRating ? null : _submitRating,
                      child: _isLoadingRating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_userRating == null ? 'Submit' : 'Update'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    if (!widget.showComments) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.comment, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Comment input
            if (FirebaseAuth.instance.currentUser != null) ...[
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Share your thoughts about this artwork...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _isPostingComment ? null : _postComment,
                    child: _isPostingComment
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Post Comment'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Comments list
            StreamBuilder(
              stream: _commentService.streamArtworkComments(
                widget.artworkId,
                limit: 10,
                includeReplies: false,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No comments yet. Be the first to comment!'),
                  );
                }

                return Column(
                  children: snapshot.data!.map((comment) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: comment.userAvatarUrl.isNotEmpty
                              ? NetworkImage(comment.userAvatarUrl)
                              : null,
                          child: comment.userAvatarUrl.isEmpty
                              ? Text(comment.userName[0].toUpperCase())
                              : null,
                        ),
                        title: Text(comment.userName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(comment.content),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(comment.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    final DateTime dateTime = timestamp is DateTime
        ? timestamp
        : (timestamp as dynamic).toDate() as DateTime;

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRatingSection(),
        _buildCommentSection(),
      ],
    );
  }
}

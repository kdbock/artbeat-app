import 'package:flutter/material.dart';
import 'package:artbeat/models/post_model.dart';
import 'package:artbeat/models/comment_model.dart';
import 'package:artbeat/services/community_service.dart';
import 'package:artbeat/widgets/post_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Screen that displays a single post with comments
class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key, 
    required this.postId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _commentController = TextEditingController();
  
  bool _isLoading = true;
  bool _isPostingComment = false;
  bool _isLiked = false;
  PostModel? _post;
  List<CommentModel> _comments = [];
  
  @override
  void initState() {
    super.initState();
    _loadPostDetails();
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPostDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load the post
      final post = await _communityService.getPostById(widget.postId);
      if (post == null) {
        // Post not found, handle error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post not found')),
          );
          Navigator.pop(context);
        }
        return;
      }
      
      // Check if current user has liked the post
      final hasLiked = await _communityService.hasUserLikedPost(widget.postId);
      
      // Load comments
      final comments = await _communityService.getCommentsForPost(widget.postId);
      
      if (mounted) {
        setState(() {
          _post = post;
          _comments = comments;
          _isLiked = hasLiked;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading post: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _refreshPost() async {
    await _loadPostDetails();
  }
  
  Future<void> _toggleLike() async {
    try {
      await _communityService.toggleLikePost(widget.postId);
      
      if (mounted) {
        setState(() {
          if (_isLiked) {
            _post = _post?.copyWith(
              likeCount: _post!.likeCount - 1,
            );
          } else {
            _post = _post?.copyWith(
              likeCount: _post!.likeCount + 1,
            );
          }
          _isLiked = !_isLiked;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error liking post: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _sharePost() async {
    // Show dialog to add an optional comment
    final comment = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final commentController = TextEditingController();
        return AlertDialog(
          title: const Text('Share this post'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(
              hintText: 'Add a comment (optional)',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Share'),
              onPressed: () => Navigator.of(context).pop(commentController.text),
            ),
          ],
        );
      },
    );
    
    if (comment != null) {
      try {
        final sharedPostId = await _communityService.sharePost(
          widget.postId,
          comment: comment.isNotEmpty ? comment : null,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post shared successfully')),
          );
          
          // Update the share count in the UI
          setState(() {
            _post = _post?.copyWith(
              shareCount: _post!.shareCount + 1,
            );
          });
          
          // Navigate to the shared post
          Navigator.pushReplacementNamed(
            context,
            '/community/post-detail',
            arguments: {'postId': sharedPostId},
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sharing post: ${e.toString()}')),
          );
        }
      }
    }
  }
  
  Future<void> _postComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;
    
    setState(() {
      _isPostingComment = true;
    });
    
    try {
      await _communityService.addComment(
        postId: widget.postId,
        content: comment,
      );
      
      // Clear input and refresh comments
      _commentController.clear();
      
      // Refresh the post and comments
      await _loadPostDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPostingComment = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          if (_post != null && _post!.userId == _communityService.getCurrentUserId())
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Post'),
                    content: const Text('Are you sure you want to delete this post?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  try {
                    await _communityService.deletePost(widget.postId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post deleted')),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting post: ${e.toString()}')),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? const Center(child: Text('Post not found'))
              : RefreshIndicator(
                  onRefresh: _refreshPost,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            PostCard(
                              post: _post!,
                              isLiked: _isLiked,
                              onLike: _toggleLike,
                              onShare: _sharePost,
                            ),
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Comments',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ..._buildCommentsList(),
                          ],
                        ),
                      ),
                      _buildCommentInput(),
                    ],
                  ),
                ),
    );
  }
  
  List<Widget> _buildCommentsList() {
    if (_comments.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No comments yet. Be the first to comment!'),
          ),
        ),
      ];
    }
    
    return _comments.map((comment) => _buildCommentItem(comment)).toList();
  }
  
  Widget _buildCommentItem(CommentModel comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: comment.userPhotoUrl.isNotEmpty
                ? CachedNetworkImageProvider(comment.userPhotoUrl) as ImageProvider
                : const AssetImage('assets/default_profile.png'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${comment.likeCount} likes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        // Show reply input
                      },
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundImage: AssetImage('assets/default_profile.png'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _postComment(),
            ),
          ),
          IconButton(
            icon: _isPostingComment
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: _isPostingComment ? null : _postComment,
          ),
        ],
      ),
    );
  }
  
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
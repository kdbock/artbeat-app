import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../../models/comment_model.dart';
import '../../models/post_model.dart';
import '../../widgets/feedback_thread_widget.dart';

class CommentsScreen extends StatefulWidget {
  final PostModel post;

  const CommentsScreen({super.key, required this.post});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSendingComment = false;
  String _commentType = 'Appreciation'; // Default comment type
  CommentModel? _replyingTo;

  // Available comment types matching the concept doc
  final List<String> _commentTypes = [
    'Appreciation',
    'Constructive Critique',
    'Technical Question',
    'Inspiration',
    'General Discussion',
  ];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    debugPrint('🔍 Loading comments for post ID: ${widget.post.id}');
    setState(() {
      _isLoading = true;
    });

    try {
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('postId', isEqualTo: widget.post.id)
          .orderBy('createdAt', descending: false)
          .get();

      debugPrint('📊 Found ${commentsSnapshot.docs.length} comments');
      for (var doc in commentsSnapshot.docs) {
        debugPrint('💬 Comment: ${doc.data()}');
      }

      if (mounted) {
        setState(() {
          _comments = commentsSnapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList();
          _isLoading = false;
        });
        debugPrint('✅ Loaded ${_comments.length} comments into state');
      }
    } catch (e) {
      debugPrint('❌ Error loading comments: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (e.toString().contains('index')) {
        debugPrint(
          '🔍 This might be an index issue. Check Firebase Console for index status.',
        );
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load comments: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSendingComment = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to be signed in to comment')),
        );
        return;
      }

      // Get user data
      final userService = Provider.of<UserService>(context, listen: false);
      final userModel = await userService.getUserById(user.uid);

      if (userModel == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user profile')),
        );
        return;
      }

      // Create comment document
      final commentDoc = {
        'postId': widget.post.id,
        'userId': user.uid,
        'userName': userModel.fullName,
        'userAvatarUrl': userModel.profileImageUrl ?? '',
        'content': _commentController.text.trim(),
        'type': _commentType,
        'parentCommentId': _replyingTo?.id ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      debugPrint('💬 Creating comment: ${commentDoc.toString()}');
      debugPrint('🔐 User ID: ${user.uid}');
      debugPrint(
        '📝 Parent Comment ID: ${_replyingTo?.id ?? "none (top-level)"}',
      );

      // Add to Firestore
      final commentRef = await FirebaseFirestore.instance
          .collection('comments')
          .add(commentDoc);

      debugPrint('✅ Comment created with ID: ${commentRef.id}');

      // Update post comment count
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .update({'commentCount': FieldValue.increment(1)});

      debugPrint('📊 Post comment count updated');

      // Create CommentModel for local display
      final newComment = CommentModel(
        id: commentRef.id,
        postId: widget.post.id,
        userId: user.uid,
        userName: userModel.fullName,
        userAvatarUrl: userModel.profileImageUrl ?? '',
        content: _commentController.text.trim(),
        type: _commentType,
        parentCommentId: _replyingTo?.id ?? '',
        createdAt: Timestamp.now(),
      );

      // Reset form and refresh list
      setState(() {
        _comments.add(newComment);
        _commentController.clear();
        _replyingTo = null;
        _commentType = 'General';
      });

      // Scroll to bottom after adding comment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('❌ Error adding comment: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');

      if (mounted) {
        String errorMessage = 'Failed to add comment';

        if (e.toString().contains('permission-denied')) {
          errorMessage = 'Permission denied. Please check your authentication.';
          debugPrint(
            '🔐 Permission denied - check Firestore rules and user authentication',
          );
        } else if (e.toString().contains('not-found')) {
          errorMessage = 'Post not found. Please refresh and try again.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingComment = false;
        });
      }
    }
  }

  void _setReplyTo(CommentModel comment) {
    setState(() {
      _replyingTo = comment;
      _commentController.text = '@${comment.userName} ';
    });

    FocusScope.of(context).requestFocus(FocusNode());
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(FocusNode());
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Art Discussion',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Artwork summary card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.palette, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discussing ${widget.post.userName}\'s artwork',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (widget.post.content.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.post.content,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Discussion list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No discussion yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a thoughtful discussion about this artwork!',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : FeedbackThreadWidget(
                    comments: _comments,
                    onReply: _setReplyTo,
                  ),
          ),

          // Reply indicator
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to ${_replyingTo!.userName}',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: _cancelReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Comment input area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Comment type selector
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButton<String>(
                      value: _commentType,
                      icon: const Icon(Icons.arrow_drop_down),
                      iconSize: 24,
                      elevation: 16,
                      style: TextStyle(color: Theme.of(context).primaryColor),
                      underline: Container(height: 0),
                      isExpanded: false,
                      onChanged: (String? newValue) {
                        setState(() {
                          _commentType = newValue!;
                        });
                      },
                      items: _commentTypes.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Comment text field
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                InkWell(
                  onTap: _isSendingComment ? null : _addComment,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: _isSendingComment
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
          // Bottom padding for keyboard
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

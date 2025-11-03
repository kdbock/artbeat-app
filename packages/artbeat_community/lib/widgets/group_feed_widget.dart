import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:share_plus/share_plus.dart';
import '../models/group_models.dart';
import '../models/post_model.dart';
import '../screens/feed/comments_screen.dart';
import 'group_post_card.dart';

/// Widget that displays the feed for a specific group type
class GroupFeedWidget extends StatefulWidget {
  final GroupType groupType;

  const GroupFeedWidget({super.key, required this.groupType});

  @override
  State<GroupFeedWidget> createState() => _GroupFeedWidgetState();
}

class _GroupFeedWidgetState extends State<GroupFeedWidget>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final List<BaseGroupPost> _posts = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;
  DocumentSnapshot? _lastDocument;

  static const int _postsPerPage = 10;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _posts.clear();
    });

    try {
      AppLogger.info('Loading ${widget.groupType.value} group posts...');

      // Query posts for this specific group type
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('groupType', isEqualTo: widget.groupType.value)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_postsPerPage)
          .get();

      if (!mounted) return;

      if (postsSnapshot.docs.isNotEmpty) {
        _lastDocument = postsSnapshot.docs.last;

        final loadedPosts = <BaseGroupPost>[];
        for (final doc in postsSnapshot.docs) {
          final post = _createPostFromDocument(doc);
          if (post != null) {
            loadedPosts.add(post);
          }
        }

        debugPrint(
          'Loaded ${loadedPosts.length} ${widget.groupType.value} posts',
        );

        if (mounted) {
          setState(() {
            _posts.addAll(loadedPosts);
            _isLoading = false;
          });
        }
      } else {
        AppLogger.info('No ${widget.groupType.value} posts found');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      AppLogger.error('Error loading ${widget.groupType.value} posts: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load posts: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || _lastDocument == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('groupType', isEqualTo: widget.groupType.value)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_postsPerPage)
          .get();

      if (!mounted) return;

      if (postsSnapshot.docs.isNotEmpty) {
        _lastDocument = postsSnapshot.docs.last;

        final morePosts = <BaseGroupPost>[];
        for (final doc in postsSnapshot.docs) {
          final post = _createPostFromDocument(doc);
          if (post != null) {
            morePosts.add(post);
          }
        }

        if (mounted) {
          setState(() {
            _posts.addAll(morePosts);
          });
        }
      }
    } catch (e) {
      AppLogger.error('Error loading more ${widget.groupType.value} posts: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading more posts: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  BaseGroupPost? _createPostFromDocument(DocumentSnapshot doc) {
    try {
      switch (widget.groupType) {
        case GroupType.artist:
          return ArtistGroupPost.fromFirestore(doc);
        case GroupType.event:
          return EventGroupPost.fromFirestore(doc);
        case GroupType.artWalk:
          return ArtWalkAdventurePost.fromFirestore(doc);
        case GroupType.artistWanted:
          return ArtistWantedPost.fromFirestore(doc);
      }
    } catch (e) {
      AppLogger.error('Error creating post from document ${doc.id}: $e');
      return null;
    }
  }

  Future<void> _handleAppreciate(BaseGroupPost post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to appreciate posts')),
        );
      }
      return;
    }

    try {
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id);

      final appreciateRef = postRef.collection('appreciations').doc(user.uid);
      final appreciateDoc = await appreciateRef.get();

      if (!appreciateDoc.exists) {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final postSnapshot = await transaction.get(postRef);
          final currentAppreciateCount =
              (postSnapshot.data()?['applauseCount'] as int?) ?? 0;

          transaction.update(postRef, {
            'applauseCount': currentAppreciateCount + 1,
          });

          transaction.set(appreciateRef, {
            'createdAt': FieldValue.serverTimestamp(),
          });
        });

        // Update local state
        setState(() {
          final index = _posts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            // Create a new post with updated appreciate count
            // This is a simplified approach - in a real app you'd want proper copyWith methods
            _loadPosts(); // Reload to get updated counts
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('❤️ Appreciated!')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You already appreciated this post')),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error appreciating post: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error appreciating post: $e')));
      }
    }
  }

  void _handleComment(BaseGroupPost post) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            CommentsScreen(post: PostModel.fromBaseGroupPost(post)),
      ),
    );
  }

  void _handleFeature(BaseGroupPost post) async {
    try {
      // Mark post as featured in Firestore
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id);

      // First check if the document exists
      final postDoc = await postRef.get();
      if (!postDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Post not found')));
        }
        return;
      }

      // Update the post to mark it as featured
      await postRef.update({'isFeatured': true});

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post featured!')));
      }
    } catch (e) {
      AppLogger.error('Error featuring post: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to feature post: $e')));
      }
    }
  }

  void _handleGift(BaseGroupPost post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => GiftSelectionWidget(
        recipientId: post.userId,
        recipientName: post.userName,
      ),
    );
  }

  void _handleShare(BaseGroupPost post) async {
    try {
      final shareText =
          '${post.content}\n\nShared from ARTbeat by ${post.userName}';
      await SharePlus.instance.share(ShareParams(text: shareText));

      await _updateShareCount(post.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    }
  }

  /// Update share count in Firestore
  Future<void> _updateShareCount(String postId) async {
    try {
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) return;

        final currentCount = postDoc.data()?['shareCount'] ?? 0;
        transaction.update(postRef, {'shareCount': currentCount + 1});
      });
    } catch (e) {
      AppLogger.info('Failed to update share count: $e');
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              ArtbeatColors.primaryPurple,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading posts...',
            style: TextStyle(fontSize: 16, color: ArtbeatColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: ArtbeatColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: const TextStyle(
              fontSize: 16,
              color: ArtbeatColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadPosts, child: const Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getGroupIcon(), size: 64, color: ArtbeatColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No posts yet in ${widget.groupType.title}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ArtbeatColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to share something!',
            style: TextStyle(fontSize: 14, color: ArtbeatColors.textSecondary),
          ),
        ],
      ),
    );
  }

  IconData _getGroupIcon() {
    switch (widget.groupType) {
      case GroupType.artist:
        return Icons.palette;
      case GroupType.event:
        return Icons.event;
      case GroupType.artWalk:
        return Icons.directions_walk;
      case GroupType.artistWanted:
        return Icons.work;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_posts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final post = _posts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GroupPostCard(
              post: post,
              groupType: widget.groupType,
              onAppreciate: () => _handleAppreciate(post),
              onComment: () => _handleComment(post),
              onFeature: () => _handleFeature(post),
              onGift: () => _handleGift(post),
              onShare: () => _handleShare(post),
            ),
          );
        },
      ),
    );
  }
}

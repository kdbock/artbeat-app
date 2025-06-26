import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show ArtbeatColors, ArtbeatComponents;
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../widgets/post_card.dart';
import 'create_post_screen.dart';
import 'comments_screen.dart';

class UnifiedCommunityFeed extends StatefulWidget {
  const UnifiedCommunityFeed({super.key});

  @override
  State<UnifiedCommunityFeed> createState() => _UnifiedCommunityFeedState();
}

class _UnifiedCommunityFeedState extends State<UnifiedCommunityFeed> {
  final ScrollController _scrollController = ScrollController();
  final List<PostModel> _posts = [];
  final Map<String, List<CommentModel>> _postComments = {};
  final Map<String, bool> _postExpansionState = {};

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;
  DocumentSnapshot? _lastDocument;

  static const int _postsPerPage = 10;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

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
      debugPrint('Loading community feed posts...');

      // Query public posts, ordered by creation date
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_postsPerPage)
          .get();

      if (!mounted) return;

      if (postsSnapshot.docs.isNotEmpty) {
        _lastDocument = postsSnapshot.docs.last;

        final loadedPosts = postsSnapshot.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList();

        debugPrint('Loaded ${loadedPosts.length} posts');

        // Enrich posts with current user photo URLs if missing
        final enrichedPosts = <PostModel>[];
        for (final post in loadedPosts) {
          var enrichedPost = post;

          debugPrint(
            'Processing post ${post.id} - User: ${post.userName}, PhotoURL: "${post.userPhotoUrl}"',
          );

          // If userPhotoUrl is missing, try to fetch it from users collection
          if (post.userPhotoUrl.isEmpty && post.userId.isNotEmpty) {
            try {
              debugPrint('Fetching user data for ${post.userId}...');
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(post.userId)
                  .get();

              if (userDoc.exists) {
                final userData = userDoc.data() as Map<String, dynamic>;
                final photoUrl = userData['profileImageUrl'] as String? ?? '';
                final isVerified = userData['isVerified'] as bool? ?? false;

                debugPrint(
                  'User doc found - profileImageUrl: "$photoUrl", isVerified: $isVerified',
                );

                if (photoUrl.isNotEmpty) {
                  enrichedPost = post.copyWith(
                    userPhotoUrl: photoUrl,
                    isUserVerified: isVerified,
                  );
                  debugPrint(
                    'Enriched post ${post.id} with user photo: $photoUrl',
                  );
                } else {
                  debugPrint('User doc exists but profileImageUrl is empty');
                }
              } else {
                debugPrint('User document does not exist for ${post.userId}');
              }
            } catch (e) {
              debugPrint('Error fetching user data for ${post.userId}: $e');
            }
          } else {
            debugPrint('Post already has photoUrl: "${post.userPhotoUrl}"');
          }

          enrichedPosts.add(enrichedPost);
        }

        // Load comments for each post
        for (final post in enrichedPosts) {
          await _fetchCommentsForPost(post.id);
        }

        if (mounted) {
          setState(() {
            _posts.addAll(enrichedPosts);
            _isLoading = false;
          });
        }
      } else {
        debugPrint('No posts found');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading posts: $e');
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
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_postsPerPage)
          .get();

      if (!mounted) return;

      if (postsSnapshot.docs.isNotEmpty) {
        _lastDocument = postsSnapshot.docs.last;

        final morePosts = postsSnapshot.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList();

        // Enrich posts with current user photo URLs if missing
        final enrichedMorePosts = <PostModel>[];
        for (final post in morePosts) {
          var enrichedPost = post;

          // If userPhotoUrl is missing, try to fetch it from users collection
          if (post.userPhotoUrl.isEmpty && post.userId.isNotEmpty) {
            try {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(post.userId)
                  .get();

              if (userDoc.exists) {
                final userData = userDoc.data() as Map<String, dynamic>;
                final photoUrl = userData['profileImageUrl'] as String? ?? '';
                final isVerified = userData['isVerified'] as bool? ?? false;

                if (photoUrl.isNotEmpty) {
                  enrichedPost = post.copyWith(
                    userPhotoUrl: photoUrl,
                    isUserVerified: isVerified,
                  );
                  debugPrint(
                    'Enriched post ${post.id} with user photo: $photoUrl',
                  );
                }
              }
            } catch (e) {
              debugPrint('Error fetching user data for ${post.userId}: $e');
            }
          }

          enrichedMorePosts.add(enrichedPost);
        }

        // Load comments for new posts
        for (final post in enrichedMorePosts) {
          await _fetchCommentsForPost(post.id);
        }

        if (mounted) {
          setState(() {
            _posts.addAll(enrichedMorePosts);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading more posts: $e');
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

  Future<void> _fetchCommentsForPost(String postId) async {
    try {
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .where('parentCommentId', isEqualTo: '')
          .orderBy('createdAt', descending: false)
          .limit(3)
          .get();

      if (mounted) {
        setState(() {
          _postComments[postId] = commentsSnapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading comments for post $postId: $e');
      if (mounted) {
        setState(() {
          _postComments[postId] = [];
        });
      }
    }
  }

  Future<void> _handleApplause(PostModel post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to applaud posts')),
        );
      }
      return;
    }

    try {
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id);

      final applauseRef = postRef.collection('applause').doc(user.uid);
      final applauseDoc = await applauseRef.get();

      int currentApplause = 0;
      if (applauseDoc.exists) {
        currentApplause = (applauseDoc.data()?['count'] as int?) ?? 0;
      }

      // Increment applause (max 5 per user)
      if (currentApplause < PostModel.maxApplausePerUser) {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final postSnapshot = await transaction.get(postRef);
          final currentTotalApplause =
              (postSnapshot.data()?['applauseCount'] as int?) ?? 0;

          transaction.update(postRef, {
            'applauseCount': currentTotalApplause + 1,
          });

          transaction.set(applauseRef, {
            'count': currentApplause + 1,
            'lastApplauseAt': FieldValue.serverTimestamp(),
          });
        });

        // Update local state
        setState(() {
          final index = _posts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            _posts[index] = post.copyWith(
              applauseCount: post.applauseCount + 1,
            );
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('👏 Applause added!')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You\'ve reached the maximum applause for this post',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error adding applause: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding applause: $e')));
      }
    }
  }

  Future<void> _handleShare(PostModel post) async {
    try {
      String shareText = '${post.content}\n\nShared from ARTbeat';
      if (post.imageUrls.isNotEmpty) {
        shareText += '\n\nCheck out this artwork!';
      }

      await SharePlus.instance.share(ShareParams(text: shareText));

      // Update share count
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id);

      await postRef.update({'shareCount': FieldValue.increment(1)});

      // Update local state
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = post.copyWith(shareCount: post.shareCount + 1);
        }
      });
    } catch (e) {
      debugPrint('Error sharing post: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing post: $e')));
      }
    }
  }

  void _navigateToComments(PostModel post) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (context) => CommentsScreen(post: post)),
    ).then((_) {
      // Refresh comments when returning from comments screen
      _fetchCommentsForPost(post.id);
    });
  }

  void _navigateToCreatePost() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (context) => const CreatePostScreen()),
    ).then((_) {
      // Refresh feed when returning from create post
      _loadPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: ArtbeatColors.background,
      appBar: AppBar(
        title: Text(
          'Community Critique',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.textPrimary,
          ),
        ),
        backgroundColor: ArtbeatColors.white,
        elevation: 1,
        shadowColor: ArtbeatColors.black.withAlpha(25),
        iconTheme: const IconThemeData(color: ArtbeatColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _navigateToCreatePost,
            tooltip: 'Create Post',
            color: ArtbeatColors.primaryPurple,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPosts,
            tooltip: 'Refresh',
            color: ArtbeatColors.textSecondary,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ArtbeatColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading community posts...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: ArtbeatColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: ArtbeatColors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPosts,
              style: ArtbeatComponents.primaryButtonStyle,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 64,
              color: ArtbeatColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No artwork shared yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your artwork and get thoughtful feedback from the community!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ArtbeatColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToCreatePost,
              style: ArtbeatComponents.primaryButtonStyle,
              child: const Text('Share Artwork'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      color: ArtbeatColors.primaryPurple,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _posts.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ArtbeatColors.primaryPurple,
                  ),
                ),
              ),
            );
          }

          final post = _posts[index];
          final comments = _postComments[post.id] ?? [];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: PostCard(
              post: post,
              currentUserId: _currentUserId,
              comments: comments,
              onUserTap: (userId) => _handleUserTap(userId),
              onApplause: (post) => _handleApplause(post),
              onComment: (postId) => _navigateToComments(post),
              onShare: (post) => _handleShare(post),
              isExpanded: _postExpansionState[post.id] ?? false,
              onToggleExpand: () => _togglePostExpansion(post.id),
            ),
          );
        },
      ),
    );
  }

  void _handleUserTap(String userId) {
    // Navigate to user profile
    // TODO: Implement user profile navigation
    debugPrint('User tapped: $userId');
  }

  void _togglePostExpansion(String postId) {
    setState(() {
      _postExpansionState[postId] = !(_postExpansionState[postId] ?? false);
    });
  }
}

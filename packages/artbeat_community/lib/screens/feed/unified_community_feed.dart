import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// share_plus import removed; sharing is handled in engagement bar or other flows
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show ArtbeatColors, ArtbeatComponents, CommunityProvider;
import 'package:artbeat_ads/artbeat_ads.dart';
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../widgets/post_card.dart';
import '../../widgets/post_detail_modal.dart';
import 'create_post_screen.dart';

class UnifiedCommunityFeed extends StatefulWidget {
  const UnifiedCommunityFeed({super.key, this.scrollToPostId});

  final String? scrollToPostId;

  @override
  State<UnifiedCommunityFeed> createState() => _UnifiedCommunityFeedState();
}

class _UnifiedCommunityFeedState extends State<UnifiedCommunityFeed> {
  final ScrollController _scrollController = ScrollController();
  final List<PostModel> _posts = [];
  final Map<String, List<CommentModel>> _postComments = {};
  final Map<String, bool> _postExpansionState = {};
  final Map<String, GlobalKey> _postKeys = {};

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;
  DocumentSnapshot? _lastDocument;
  String? _scrollToPostId;
  String? _highlightedPostId;

  static const int _postsPerPage = 10;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _scrollToPostId = widget.scrollToPostId;
    _loadPosts();

    // Mark community as visited when this screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CommunityProvider>().markCommunityAsVisited();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments.containsKey('scrollToPostId')) {
      final postId = arguments['scrollToPostId'] as String?;
      debugPrint('UnifiedCommunityFeed: Received scrollToPostId: $postId');
      setState(() {
        _scrollToPostId = postId;
      });
    }
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

        // Debug post data
        for (final post in loadedPosts) {
          debugPrint(
            'Post ${post.id}: userId="${post.userId}", userName="${post.userName}", '
            'applauseCount=${post.applauseCount}, commentCount=${post.commentCount}, '
            'createdAt=${post.createdAt}, userPhotoUrl="${post.userPhotoUrl}"',
          );
        }

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

          if (_scrollToPostId != null) {
            // Ensure the post is present in the loaded list; if not, try to fetch it and
            // insert it in the correct sorted position, then scroll to it.
            _ensurePostLoadedAndScroll(_scrollToPostId!);
          }
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

  void _scrollToPost(String postId) {
    debugPrint(
      'UnifiedCommunityFeed: _scrollToPost called for postId: $postId',
    );

    final postIndex = _posts.indexWhere((p) => p.id == postId);
    debugPrint('UnifiedCommunityFeed: Post $postId found at index: $postIndex');

    if (postIndex != -1) {
      // Set highlight before scrolling so the animated container reflects the state
      if (mounted) {
        setState(() {
          _highlightedPostId = postId;
        });
      }

      // Use post-frame callback to ensure the list has been rebuilt
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // Calculate the actual list index (accounting for ads)
        final listIndex = _getListIndexForPost(postIndex);
        debugPrint(
          'UnifiedCommunityFeed: Calculated list index for post $postId: $listIndex',
        );

        // Scroll to the calculated position
        if (_scrollController.hasClients) {
          // Estimate item height (post + padding + potential ad)
          const double estimatedItemHeight =
              200.0; // Adjust based on your post height
          final double targetOffset = listIndex * estimatedItemHeight;

          debugPrint(
            'UnifiedCommunityFeed: Scrolling to offset: $targetOffset',
          );

          _scrollController.animateTo(
            targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }

        // Clear highlight after a short delay
        Future<void>.delayed(const Duration(milliseconds: 2400)).then((_) {
          if (mounted) {
            setState(() {
              // Only clear if still highlighting the same post
              if (_highlightedPostId == postId) _highlightedPostId = null;
            });
          }
        });
      });
    } else {
      debugPrint('UnifiedCommunityFeed: Post $postId not found in _posts list');
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

  /// Fetch a single post by id from Firestore, enrich it and insert into _posts
  /// in the correct sorted position (by createdAt desc) if not already present.
  Future<PostModel?> _fetchPostById(String postId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();
      if (!doc.exists) return null;

      var post = PostModel.fromFirestore(doc);

      // Enrich user photo if missing
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
              post = post.copyWith(
                userPhotoUrl: photoUrl,
                isUserVerified: isVerified,
              );
            }
          }
        } catch (e) {
          debugPrint('Error enriching post $postId user data: $e');
        }
      }

      return post;
    } catch (e) {
      debugPrint('Error fetching post $postId: $e');
      return null;
    }
  }

  /// Ensure the requested post is loaded into the list and then scroll to it.
  Future<void> _ensurePostLoadedAndScroll(String postId) async {
    debugPrint(
      'UnifiedCommunityFeed: _ensurePostLoadedAndScroll called for postId: $postId',
    );

    // Already loaded?
    final existingIndex = _posts.indexWhere((p) => p.id == postId);
    if (existingIndex != -1) {
      debugPrint(
        'UnifiedCommunityFeed: Post $postId already exists at index $existingIndex',
      );
      // Already present - scroll to it
      _scrollToPost(postId);
      return;
    }

    debugPrint(
      'UnifiedCommunityFeed: Post $postId not found in current list, fetching...',
    );

    // Try fetching the post directly
    final fetched = await _fetchPostById(postId);
    if (fetched == null) {
      debugPrint('UnifiedCommunityFeed: Failed to fetch post $postId');
      return;
    }

    debugPrint(
      'UnifiedCommunityFeed: Successfully fetched post $postId, inserting into list',
    );

    // Insert maintaining createdAt desc order
    int insertIndex = _posts.indexWhere(
      (p) => p.createdAt.isBefore(fetched.createdAt),
    );
    if (insertIndex == -1) {
      // append at end
      setState(() {
        _posts.add(fetched);
      });
      debugPrint('UnifiedCommunityFeed: Added post $postId to end of list');
    } else {
      setState(() {
        _posts.insert(insertIndex, fetched);
      });
      debugPrint(
        'UnifiedCommunityFeed: Inserted post $postId at index $insertIndex',
      );
    }

    // Load comments for the inserted post
    await _fetchCommentsForPost(fetched.id);

    // Wait for the widget tree to rebuild after setState
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Now scroll to the post
    if (mounted) {
      debugPrint('UnifiedCommunityFeed: Scrolling to post $postId');
      _scrollToPost(postId);
    }
  }

  // Legacy applause/share handlers removed; engagement is handled by UniversalEngagementBar

  void _navigateToComments(PostModel post) {
    debugPrint('_navigateToComments called for post ${post.id}');
    // Show post detail modal instead of full screen
    PostDetailModal.showFromPostModel(context, post).then((_) {
      debugPrint(
        'Post detail modal closed, refreshing comments for post ${post.id}',
      );
      // Refresh comments when returning from modal
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
    return Container(
      color: ArtbeatColors.backgroundSecondary,
      child: Column(
        children: [
          // Create post button section
          Container(
            color: ArtbeatColors.white,
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToCreatePost,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArtbeatColors.primaryPurple,
                  foregroundColor: ArtbeatColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          // Body content
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
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
            const Icon(
              Icons.error_outline,
              size: 64,
              color: ArtbeatColors.error,
            ),
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ArtbeatColors.primaryPurple.withAlpha(25),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  size: 64,
                  color: ArtbeatColors.primaryPurple,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No posts yet',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: ArtbeatColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Be the first to share your creative work, thoughts, or art discoveries and connect with the community.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: ArtbeatColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToCreatePost,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create Your First Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArtbeatColors.primaryPurple,
                    foregroundColor: ArtbeatColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      color: ArtbeatColors.primaryPurple,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        itemCount: _getTotalItemCount(),
        itemBuilder: (context, index) {
          final totalItemsWithoutLoader =
              _getTotalItemCount() - (_isLoadingMore ? 1 : 0);

          // Show loading indicator at the end
          if (index >= totalItemsWithoutLoader) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ArtbeatColors.primaryPurple,
                  ),
                ),
              ),
            );
          }

          // Check if this position should show an ad
          if (_isAdPosition(index)) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: FeedAdWidget(
                location: AdLocation.communityFeed,
                index: index,
              ),
            );
          }

          // Show regular post
          final postIndex = _getPostIndex(index);
          if (postIndex >= _posts.length) {
            // This shouldn't happen, but just in case
            return const SizedBox.shrink();
          }

          final post = _posts[postIndex];
          final comments = _postComments[post.id] ?? [];
          _postKeys.putIfAbsent(post.id, () => GlobalKey());

          return Padding(
            key: _postKeys[post.id],
            padding: const EdgeInsets.only(bottom: 24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: post.id == _highlightedPostId
                    ? ArtbeatColors.primaryPurple.withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: post.id == _highlightedPostId
                    ? Border.all(
                        color: ArtbeatColors.primaryPurple.withValues(
                          alpha: 0.4,
                        ),
                        width: 2,
                      )
                    : Border.all(color: Colors.transparent),
                boxShadow: post.id == _highlightedPostId
                    ? [
                        BoxShadow(
                          color: ArtbeatColors.primaryPurple.withValues(
                            alpha: 0.12,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: PostCard(
                post: post,
                currentUserId: _currentUserId,
                comments: comments,
                onUserTap: (userId) => _handleUserTap(userId),
                onComment: (postId) => _navigateToComments(post),
                onFeature: null,
                onGift: null,
                isExpanded: _postExpansionState[post.id] ?? false,
                onToggleExpand: () => _togglePostExpansion(post.id),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleUserTap(String userId) {
    // TODO: Navigate to user profile
    debugPrint('User tapped: $userId');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User profile for $userId (coming soon)')),
    );
  }

  void _togglePostExpansion(String postId) {
    setState(() {
      _postExpansionState[postId] = !(_postExpansionState[postId] ?? false);
    });
  }

  /// Calculate total item count including ads every 5th post
  int _getTotalItemCount() {
    if (_posts.isEmpty) return _isLoadingMore ? 1 : 0;

    // Add one ad for every 5 posts (after posts 4, 9, 14, etc.)
    final adCount = (_posts.length / 5).floor();
    final totalItems = _posts.length + adCount;

    return totalItems + (_isLoadingMore ? 1 : 0);
  }

  /// Check if the given index should display an ad
  bool _isAdPosition(int index) {
    // We want ads after every 5 posts
    // In the combined list: posts 0,1,2,3,4 -> ad at index 5
    // posts 5,6,7,8,9 -> ad at index 11, etc.
    //
    // Example with 15 posts:
    // Index: 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
    // Item:  P,P,P,P,P,A,P,P,P,P,P, A, P, P, P, P, P, A
    // Where P = Post, A = Ad

    if (index < 5) return false; // No ad in first 5 positions

    // Check if this is an ad position: 5, 11, 17, 23, etc.
    // Pattern: (5 + 6*n) where n = 0, 1, 2, ...
    return (index - 5) % 6 == 0;
  }

  /// Get the actual post index for a given list index (accounting for ads)
  int _getPostIndex(int listIndex) {
    if (listIndex < 5) return listIndex;

    // Calculate how many ads appear before this index
    final adsBeforeIndex = ((listIndex - 5) / 6).floor() + 1;
    return listIndex - adsBeforeIndex;
  }

  /// Get the list index for a given post index (accounting for ads)
  int _getListIndexForPost(int postIndex) {
    if (postIndex < 5) return postIndex;

    // Calculate how many ads should appear before this post
    final adsBeforePost = (postIndex / 5).floor();
    return postIndex + adsBeforePost;
  }
}

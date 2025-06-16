import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async' show unawaited;
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../widgets/post_card.dart';
import '../gifts/gifts_screen.dart';
import '../portfolios/portfolios_screen.dart';
import '../studios/studios_screen.dart';
import '../commissions/commissions_screen.dart';
import '../sponsorships/sponsorship_screen.dart';
import '../../theme/index.dart';

class CommunityTab {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget screen;

  const CommunityTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.screen,
  });
}

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 0;

  final List<PostModel> _posts = [];
  final Set<String> _expandedPosts = {};
  final Map<String, List<CommentModel>> _postComments = {};

  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isLoadingMore = false;
  static const int _postsPerPage = 10;
  DocumentSnapshot? _lastDocument;

  late final List<CommunityTab> _tabs;

  @override
  void initState() {
    super.initState();
    _initializeTabs();
    _scrollController.addListener(_onScroll);
    _loadFeed();
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

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || _lastDocument == null) return;

    setState(() => _isLoadingMore = true);

    try {
      debugPrint('Loading more community feed posts...');

      // Security rules allow public access to posts where isPublic is true
      final postsQuery = FirebaseFirestore.instance
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_postsPerPage);

      final postsSnapshot = await postsQuery.get();

      if (!mounted) return;

      if (postsSnapshot.docs.isNotEmpty) {
        _lastDocument = postsSnapshot.docs.last;

        final morePosts = postsSnapshot.docs
            .map((doc) => PostModel.fromDocument(doc))
            .toList();

        debugPrint('Loaded ${morePosts.length} additional posts');

        setState(() {
          _posts.addAll(morePosts);
        });

        // Pre-fetch comments for new posts in parallel for better performance
        final commentFutures = <Future<void>>[];

        for (final post in morePosts) {
          commentFutures.add(_fetchCommentsForPost(post.id));
        }

        // Don't await here - let comments load in background
        // This way UI updates immediately with posts even if comments are still loading
        unawaited(Future.wait(commentFutures));
      } else {
        debugPrint('No more posts to load');
      }
    } catch (e) {
      debugPrint('Error loading more posts: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error loading more posts: ${e.toString().split('] ').last}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _initializeTabs() {
    _tabs = [
      CommunityTab(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Feed',
        screen: _buildFeedContent(),
      ),
      const CommunityTab(
        icon: Icons.card_giftcard_outlined,
        selectedIcon: Icons.card_giftcard,
        label: 'Gifts',
        screen: GiftsScreen(),
      ),
      const CommunityTab(
        icon: Icons.palette_outlined,
        selectedIcon: Icons.palette,
        label: 'Portfolio',
        screen: PortfoliosScreen(),
      ),
      const CommunityTab(
        icon: Icons.forum_outlined,
        selectedIcon: Icons.forum,
        label: 'Studios',
        screen: StudiosScreen(),
      ),
      const CommunityTab(
        icon: Icons.work_outline,
        selectedIcon: Icons.work,
        label: 'Commissions',
        screen: CommissionsScreen(),
      ),
      const CommunityTab(
        icon: Icons.volunteer_activism_outlined,
        selectedIcon: Icons.volunteer_activism,
        label: 'Sponsors',
        screen: SponsorshipScreen(),
      ),
    ];
  }

  Future<void> _loadFeed() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _posts.clear();
    });

    try {
      debugPrint('Loading community feed posts...');

      // Security rules allow public access to posts where isPublic is true
      // This query ensures we only fetch public posts
      final postsQuery = FirebaseFirestore.instance
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_postsPerPage);

      final postsSnapshot = await postsQuery.get();

      if (!mounted) return;

      _lastDocument =
          postsSnapshot.docs.isNotEmpty ? postsSnapshot.docs.last : null;

      final loadedPosts = postsSnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();

      debugPrint('Loaded ${loadedPosts.length} posts');

      // Pre-fetch comments for all posts in parallel for better performance
      final commentFutures = <Future<void>>[];

      for (final post in loadedPosts) {
        // Add comment fetching task to our list of futures
        commentFutures.add(_fetchCommentsForPost(post.id));
      }

      // Wait for all comment fetches to complete
      await Future.wait(commentFutures);

      if (!mounted) return;

      setState(() {
        _posts.clear();
        _posts.addAll(loadedPosts);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading feed: $e');

      if (!mounted) return;

      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load feed: ${e.toString().split('] ').last}';
        _isLoading = false;
      });
    }
  }

  // Helper method to fetch comments for a specific post
  Future<void> _fetchCommentsForPost(String postId) async {
    try {
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .where('parentCommentId', isEqualTo: '')
          .orderBy('createdAt', descending: true)
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
        // Initialize with empty list if comments can't be loaded
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

    final userId = user.uid;

    try {
      final docRef =
          FirebaseFirestore.instance.collection('posts').doc(post.id);
      final applauseRef = docRef.collection('applause').doc(userId);

      // Get current applause count from subcollection document
      final applauseDoc = await applauseRef.get();
      int currentApplause = 0;

      if (applauseDoc.exists) {
        currentApplause = (applauseDoc.data() ?? {})['count'] as int? ?? 0;
      }

      if (currentApplause < PostModel.maxApplausePerUser) {
        // Using transaction for atomic operations
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // Update applause subcollection document - this matches the security rule
          // where users can only update their own applause documents where userId == auth.uid
          transaction.set(
              applauseRef,
              {
                'count': currentApplause + 1,
                'updatedAt': FieldValue.serverTimestamp(),
                'userId': userId, // Required by security rules
              },
              SetOptions(
                  merge:
                      true)); // Use merge to prevent document not found errors

          // Try to update post count, but this may fail if the user doesn't own the post
          // The security rules allow only the post owner to update the post document
          try {
            // First check if we own the post
            final postDoc = await transaction.get(docRef);
            final postData = postDoc.data() as Map<String, dynamic>?;

            if (postData != null && postData['userId'] == userId) {
              // We own the post, so we can update it directly
              transaction.update(docRef, {
                'applauseCount': FieldValue.increment(1),
              });
            }
            // If we don't own the post, the incremented counter will still be visible
            // in the UI because we'll reload the feed, but the actual post update will
            // have to be done by a background Cloud Function
          } catch (e) {
            debugPrint(
                'Error updating post count (likely permission issue): $e');
            // Continue even if this fails - the applause subcollection updated successfully
          }
        });

        // Refresh the feed to show updated applause count
        if (mounted) {
          await _loadFeed();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('You\'ve reached the maximum applause for this post')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error handling applause: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().split('] ').last}')),
        );
      }
    }
  }

  void _handleUserTap(String userId) {
    Navigator.pushNamed(context, '/profile/view', arguments: userId);
  }

  Future<void> _handleComment(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to comment')),
        );
      }
      return;
    }

    final TextEditingController commentController = TextEditingController();
    String selectedType = 'Appreciation';
    final userId = user.uid;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedType,
                  items: ['Appreciation', 'Critique', 'Question', 'Tip']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      selectedType = newValue;
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final commentText = commentController.text.trim();
                    if (commentText.isEmpty) return;

                    try {
                      // Create comment document with all required fields according to security rules
                      // validateComment function requires userId, content, postId, createdAt, type, parentCommentId
                      final commentData = {
                        'postId': postId,
                        'userId': userId,
                        'content': commentText,
                        'parentCommentId': '', // Required by security rules
                        'type': selectedType, // Must be one of allowed values
                        'createdAt': FieldValue.serverTimestamp(),
                        'userName': user.displayName ?? 'Anonymous',
                        'userAvatarUrl': user.photoURL ?? '',
                        'flagged': false // Additional field for moderation
                      };

                      // Add the comment document
                      final commentRef = await FirebaseFirestore.instance
                          .collection('comments')
                          .add(commentData);

                      debugPrint('Comment created with ID: ${commentRef.id}');

                      // Try to update the post's comment count if we own it
                      // Based on security rules, we can only update posts where userId == auth.uid
                      try {
                        final postDoc = await FirebaseFirestore.instance
                            .collection('posts')
                            .doc(postId)
                            .get();

                        if (postDoc.exists) {
                          final postData =
                              postDoc.data() as Map<String, dynamic>?;

                          if (postData != null &&
                              postData['userId'] == userId) {
                            // We own the post, so we can update it
                            await FirebaseFirestore.instance
                                .collection('posts')
                                .doc(postId)
                                .update({
                              'commentCount': FieldValue.increment(1),
                            });
                          } else {
                            // We don't own the post, so we can't update it directly
                            // This would normally be handled by a Cloud Function
                            debugPrint(
                                'User does not own post - comment count not updated');
                          }
                        }
                      } catch (e) {
                        debugPrint('Could not update post comment count: $e');
                        // Comment was still added successfully
                      }

                      if (!mounted) return;

                      // Refresh the feed to show new comment
                      await _loadFeed();

                      if (!context.mounted) return;

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Comment added successfully')),
                      );
                    } catch (e) {
                      debugPrint('Error adding comment: $e');
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Error adding comment: ${e.toString().split('] ').last}')),
                      );
                    }
                  },
                  child: const Text('Post Comment'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleShare(PostModel post) async {
    final user = FirebaseAuth.instance.currentUser;

    // Convert post data into a shareable format
    final shareText = '''
Check out this ${post.tags.isNotEmpty ? '#${post.tags.first} ' : ''}artwork on ARTbeat!

${post.content}

By ${post.userName} in ${post.location}

Download ARTbeat to see more: https://artbeat.app
''';

    try {
      // Share using share_plus package
      await Share.share(shareText, subject: 'ARTbeat: Art by ${post.userName}');

      // Try to update share count in Firestore if we own the post
      // According to security rules, users can only update their own posts
      if (user != null && user.uid == post.userId) {
        try {
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(post.id)
              .update({
            'shareCount': FieldValue.increment(1),
          });

          debugPrint('Updated share count for post ${post.id}');
        } catch (e) {
          // Permission denied likely means we don't own the post
          debugPrint(
              'Could not update share count (likely permission issue): $e');
          // We'll still consider the share successful even if we can't update the count
        }
      }

      // We need to update the UI after sharing
      if (!mounted) return;

      // Refresh the feed to show potentially updated share count
      await _loadFeed();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post shared successfully')),
      );
    } catch (e) {
      debugPrint('Error handling share: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Sharing failed: ${e.toString().split('] ').last}')),
      );
    }
  }

  void _togglePostExpanded(String postId) {
    setState(() {
      if (_expandedPosts.contains(postId)) {
        _expandedPosts.remove(postId);
      } else {
        _expandedPosts.add(postId);
        // When expanding a post, make sure we have its comments
        _fetchComments(postId);
      }
    });
  }

  Future<void> _fetchComments(String postId) async {
    try {
      // According to the Firestore rules, comments are publicly readable
      // We include proper filtering to match the security rules expectations
      final commentsQuery = FirebaseFirestore.instance
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .where('parentCommentId', isEqualTo: '') // Only top-level comments
          .orderBy('createdAt', descending: true)
          .limit(3);

      final commentsSnapshot = await commentsQuery.get();

      if (!mounted) return;

      // Process the results only if still mounted
      setState(() {
        _postComments[postId] = commentsSnapshot.docs
            .map((doc) => CommentModel.fromFirestore(doc))
            .toList();

        // Add debug info about fetched comments
        debugPrint(
            'Fetched ${_postComments[postId]?.length ?? 0} comments for post $postId');
      });
    } catch (e) {
      debugPrint('Error fetching comments for post $postId: $e');

      // Initialize with empty list if there's an error, but only if mounted
      if (!mounted) return;

      setState(() {
        // Keep existing comments if we have them, otherwise use empty list
        _postComments[postId] = _postComments[postId] ?? [];
      });
    }
  }

  Widget _buildFeedContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage ?? 'An error occurred'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFeed,
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
            const Text('No posts yet'),
            const SizedBox(height: 16),
            if (FirebaseAuth.instance.currentUser != null) ...[
              ElevatedButton(
                onPressed: _createSamplePost,
                child: const Text('Create Sample Post'),
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: _loadFeed,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
          return PostCard(
            post: post,
            currentUserId: currentUserId,
            comments: _postComments[post.id] ?? [],
            onUserTap: _handleUserTap,
            onApplause: _handleApplause,
            onComment: _handleComment,
            onShare: _handleShare,
            isExpanded: _expandedPosts.contains(post.id),
            onToggleExpand: () => _togglePostExpanded(post.id),
          );
        },
      ),
    );
  }

  Future<void> _createSamplePost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to create a post')),
        );
      }
      return;
    }

    try {
      // Create a post document with all required fields according to security rules
      // The validatePost function requires userId, createdAt, content, imageUrls, tags, isPublic
      final now = Timestamp.now();

      // Post data that matches the security rules requirements
      final postData = {
        'userId': user.uid, // Must match the authenticated user's ID
        'userName': user.displayName ?? 'Anonymous',
        'userPhotoUrl': user.photoURL ?? 'https://placekitten.com/200/200',
        'content': 'Welcome to ARTbeat! This is my first post.',
        'imageUrls': ['https://placekitten.com/800/600'],
        'tags': ['welcome', 'first-post'],
        'location': 'San Francisco',
        'createdAt': now, // Timestamp required by security rules
        'applauseCount': 0,
        'commentCount': 0,
        'shareCount': 0,
        'isPublic': true, // Boolean required by security rules
        'geoPoint':
            const GeoPoint(37.7749, -122.4194), // San Francisco coordinates
        'zipCode': '94105',
      };

      final docRef =
          await FirebaseFirestore.instance.collection('posts').add(postData);

      debugPrint('Created sample post with ID: ${docRef.id}');

      if (!mounted) return;

      // Refresh feed to show the new post
      await _loadFeed();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample post created successfully')),
      );
    } catch (e) {
      debugPrint('Error creating sample post: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error creating post: ${e.toString().split('] ').last}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommunityThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tabs[_selectedIndex].label),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _tabs.map((tab) => tab.screen).toList(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: _tabs.map((tab) {
            final idx = _tabs.indexOf(tab);
            return BottomNavigationBarItem(
              icon: Icon(_selectedIndex == idx ? tab.selectedIcon : tab.icon),
              label: tab.label,
            );
          }).toList(),
        ),
        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () =>
                    Navigator.pushNamed(context, '/community/post/create'),
                icon: const Icon(Icons.add),
                label: const Text('Share'),
              )
            : null,
      ),
    );
  }
}

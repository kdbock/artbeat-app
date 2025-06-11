import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
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

class _CommunityFeedScreenState extends State<CommunityFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();

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
    _tabController = TabController(length: _tabs.length, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadFeed();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      final postsQuery = FirebaseFirestore.instance
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_postsPerPage);

      final postsSnapshot = await postsQuery.get();

      if (postsSnapshot.docs.isNotEmpty) {
        _lastDocument = postsSnapshot.docs.last;

        final morePosts = postsSnapshot.docs
            .map((doc) => PostModel.fromDocument(doc))
            .toList();

        setState(() {
          _posts.addAll(morePosts);
        });

        // Pre-fetch comments for new posts
        for (final post in morePosts) {
          _fetchComments(post.id);
        }
      }
    } catch (e) {
      debugPrint('Error loading more posts: $e');
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
      final postsQuery = FirebaseFirestore.instance
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_postsPerPage);

      final postsSnapshot = await postsQuery.get();
      _lastDocument =
          postsSnapshot.docs.isNotEmpty ? postsSnapshot.docs.last : null;

      final loadedPosts = postsSnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();

      // Load initial comments for each post
      for (final post in loadedPosts) {
        final commentsSnapshot = await FirebaseFirestore.instance
            .collection('comments')
            .where('postId', isEqualTo: post.id)
            .where('parentCommentId', isEqualTo: '')
            .orderBy('createdAt', descending: true)
            .limit(3)
            .get();

        _postComments[post.id] = commentsSnapshot.docs
            .map((doc) => CommentModel.fromFirestore(doc))
            .toList();
      }

      if (mounted) {
        setState(() {
          _posts.clear();
          _posts.addAll(loadedPosts);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading feed: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load feed. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleApplause(PostModel post) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final docRef =
          FirebaseFirestore.instance.collection('posts').doc(post.id);
      final applauseRef = docRef.collection('applause').doc(userId);

      final applauseDoc = await applauseRef.get();
      int currentApplause = 0;

      if (applauseDoc.exists) {
        currentApplause = (applauseDoc.data() ?? {})['count'] as int? ?? 0;
      }

      if (currentApplause < PostModel.maxApplausePerUser) {
        await Future.wait([
          applauseRef.set({
            'count': currentApplause + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          }),
          docRef.update({
            'applauseCount': FieldValue.increment(1),
          }),
        ]);
      }

      _loadFeed();
    } catch (e) {
      debugPrint('Error handling applause: $e');
    }
  }

  void _handleUserTap(String userId) {
    Navigator.pushNamed(context, '/profile/view', arguments: userId);
  }

  Future<void> _handleComment(String postId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final TextEditingController commentController = TextEditingController();
    String selectedType = 'Appreciation';

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
                    if (commentController.text.trim().isEmpty) return;

                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    try {
                      await FirebaseFirestore.instance
                          .collection('comments')
                          .add({
                        'postId': postId,
                        'userId': user.uid,
                        'content': commentController.text.trim(),
                        'parentCommentId': '',
                        'type': selectedType,
                        'createdAt': FieldValue.serverTimestamp(),
                        'userName': user.displayName ?? 'Anonymous',
                        'userAvatarUrl': user.photoURL ?? '',
                      });

                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .update({
                        'commentCount': FieldValue.increment(1),
                      });

                      if (mounted) {
                        _loadFeed();
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      debugPrint('Error adding comment: $e');
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
    // Convert post data into a shareable format
    final shareText = '''
Check out this ${post.tags.isNotEmpty ? '#${post.tags.first} ' : ''}artwork on ARTbeat!

${post.content}

By ${post.userName} in ${post.location}

Download ARTbeat to see more: https://artbeat.app
''';

    try {
      // Share using share_plus
      await Share.share(shareText, subject: 'ARTbeat: Art by ${post.userName}');

      // Update share count in Firestore
      await FirebaseFirestore.instance.collection('posts').doc(post.id).update({
        'shareCount': FieldValue.increment(1),
      });

      // We need to update the UI after incrementing the share count
      if (mounted) {
        _loadFeed();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post shared successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error handling share: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share post')),
        );
      }
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
      debugPrint('Error fetching comments for post $postId: $e');
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
    if (user == null) return;

    try {
      final now = DateTime.now();
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userPhotoUrl': user.photoURL ?? 'https://placekitten.com/200/200',
        'content': 'Welcome to ARTbeat! This is my first post.',
        'imageUrls': ['https://placekitten.com/800/600'],
        'tags': ['welcome', 'first-post'],
        'location': 'San Francisco',
        'createdAt': now,
        'applauseCount': 0,
        'commentCount': 0,
        'shareCount': 0,
        'isPublic': true,
        'geoPoint':
            const GeoPoint(37.7749, -122.4194), // San Francisco coordinates
        'zipCode': '94105',
      });

      _loadFeed();
    } catch (e) {
      debugPrint('Error creating sample post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create sample post')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommunityThemeWrapper(
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                floating: true,
                snap: true,
                title: const Text('Community'),
                elevation: innerBoxIsScrolled ? 2 : 0,
                bottom: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: _tabs.map((tab) {
                    return Tab(
                      icon: Icon(
                        _tabController.index == _tabs.indexOf(tab)
                            ? tab.selectedIcon
                            : tab.icon,
                      ),
                      text: tab.label,
                    );
                  }).toList(),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) => tab.screen).toList(),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/community/post/create');
          },
          icon: const Icon(Icons.add),
          label: const Text('Share'),
        ),
      ),
    );
  }
}

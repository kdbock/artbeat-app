import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../services/community_service.dart';
import '../../widgets/post_card.dart';
import '../feed/create_post_screen.dart';
import '../feed/trending_content_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  List<PostModel> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _lastPostId;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _lastPostId != null) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final communityService = Provider.of<CommunityService>(
        context,
        listen: false,
      );
      final posts = await communityService.getPosts();

      setState(() {
        _posts = posts;
        _isLoading = false;
        if (posts.isNotEmpty) {
          _lastPostId = posts.last.id;
        }
      });
    } catch (e) {
      debugPrint('Error loading posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final communityService = Provider.of<CommunityService>(
        context,
        listen: false,
      );
      final morePosts = await communityService.getPosts(
        lastPostId: _lastPostId,
      );

      setState(() {
        _posts.addAll(morePosts);
        _isLoadingMore = false;
        if (morePosts.isNotEmpty) {
          _lastPostId = morePosts.last.id;
        }
      });
    } catch (e) {
      debugPrint('Error loading more posts: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshFeed() async {
    await _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARTbeat Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.trending_up),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const TrendingContentScreen(),
                ),
              );
            },
            tooltip: 'Trending Content',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshFeed,
              child: _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.art_track,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No posts yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Be the first to share your artwork!',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Create Post'),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const CreatePostScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _posts.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final post = _posts[index];
                        return PostCard(
                          post: post,
                          currentUserId:
                              FirebaseAuth.instance.currentUser?.uid ?? '',
                          comments:
                              const [], // Empty list since we don't load comments here
                          onUserTap: (userId) {
                            // Navigate to user profile
                            debugPrint('Navigate to user profile: $userId');
                          },
                          onApplause: (post) {
                            // Handle applause action
                            debugPrint('User applauded post: ${post.id}');
                            // In a real implementation, we would update the post applause count
                            // using FirebaseFirestore to increment the applauseCount
                          },
                          onComment: (postId) {
                            // Navigate to comments screen
                            debugPrint(
                              'Navigate to comments for post: $postId',
                            );
                          },
                          onShare: (post) {
                            // Handle share action
                            debugPrint('Share post: ${post.id}');
                          },
                          onToggleExpand: () {
                            // Toggle expanded view
                            debugPrint('Toggle expand for post: ${post.id}');
                          },
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const CreatePostScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

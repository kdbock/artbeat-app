// filepath: /Users/kristybock/emptytemplate/lib/screens/community/community_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:artbeat/models/post_model.dart';
import 'package:artbeat/services/community_service.dart';
import 'package:artbeat/widgets/post_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Community feed screen that displays posts from users
class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen>
    with SingleTickerProviderStateMixin {
  final CommunityService _communityService = CommunityService();
  late TabController _tabController;

  // Feed state
  bool _isLoading = false;
  String? _zipCode;
  List<PostModel> _personalFeed = [];
  List<PostModel> _communityFeed = [];
  List<PostModel> _trendingFeed = [];

  // Filtering options
  String _selectedLocation = 'Global';
  List<String> _locationOptions = ['Global', 'Local', 'Following'];

  // Refresh control
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _getUserLocation();
    _loadFeeds();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Get user's saved location/zip code
  Future<void> _getUserLocation() async {
    final userId = _communityService.getCurrentUserId();
    if (userId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        if (data.containsKey('zipCode') && data['zipCode'] != null) {
          setState(() {
            _zipCode = data['zipCode'];
            _locationOptions = ['Global', 'Local ($_zipCode)', 'Following'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting user location: $e');
    }
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return;

    _loadFeedForCurrentTab();
  }

  Future<void> _loadFeeds() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load initial data for all tabs
      await Future.wait([
        _loadPersonalFeed(),
        _loadCommunityFeed(),
        _loadTrendingFeed(),
      ]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading feed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFeedForCurrentTab() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      switch (_tabController.index) {
        case 0: // For You
          await _loadPersonalFeed();
          break;
        case 1: // Community
          await _loadCommunityFeed();
          break;
        case 2: // Trending
          await _loadTrendingFeed();
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing feed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadPersonalFeed() async {
    final posts = await _communityService.getPersonalFeed();
    if (mounted) {
      setState(() {
        _personalFeed = posts;
      });
    }
  }

  Future<void> _loadCommunityFeed() async {
    List<PostModel> posts;

    if (_selectedLocation == 'Global') {
      posts = await _communityService.getCommunityFeed();
    } else if (_selectedLocation.startsWith('Local') && _zipCode != null) {
      posts = await _communityService.getCommunityFeed(zipCode: _zipCode);
    } else {
      // Default to global if no location
      posts = await _communityService.getCommunityFeed();
    }

    if (mounted) {
      setState(() {
        _communityFeed = posts;
      });
    }
  }

  Future<void> _loadTrendingFeed() async {
    final posts = await _communityService.getTrendingPosts();
    if (mounted) {
      setState(() {
        _trendingFeed = posts;
      });
    }
  }

  Future<void> _refreshCurrentFeed() async {
    await _loadFeedForCurrentTab();
  }

  void _changeLocation(String? location) {
    if (location == null) return;

    setState(() {
      _selectedLocation = location;
    });

    _loadCommunityFeed();
  }

  void _navigateToCreatePost() {
    Navigator.pushNamed(context, '/community/create-post')
        .then((_) => _refreshCurrentFeed());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/community/search'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: _changeLocation,
            itemBuilder: (BuildContext context) {
              return _locationOptions.map((String location) {
                return PopupMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'For You'),
            Tab(text: 'Community'),
            Tab(text: 'Trending'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFeedList(_personalFeed),
                _buildFeedList(_communityFeed),
                _buildFeedList(_trendingFeed),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        child: const Icon(Icons.create),
      ),
    );
  }

  Widget _buildFeedList(List<PostModel> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.feed, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No posts to show',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _navigateToCreatePost,
              child: const Text('Create a Post'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshCurrentFeed,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return FutureBuilder<bool>(
            future: _communityService.hasUserLikedPost(post.id),
            builder: (context, snapshot) {
              return PostCard(
                post: post,
                isLiked: snapshot.data ?? false,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/community/post-detail',
                  arguments: {'postId': post.id},
                ),
                onLike: () async {
                  await _communityService.toggleLikePost(post.id);
                  // Refresh will happen via StreamBuilder or future rebuild
                },
                onShare: () {
                  // Show share dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Share Post'),
                        content:
                            const Text('Share this post with your followers?'),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: const Text('Share'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _communityService.sharePost(post.id,
                                  comment: null);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Post shared!')),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

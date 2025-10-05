import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/art_models.dart';
import '../models/post_model.dart';
import '../services/art_community_service.dart';
import '../widgets/art_gallery_widgets.dart';
import '../widgets/enhanced_post_card.dart';
import '../widgets/comments_modal.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'artist_onboarding_screen.dart';
import 'artist_feed_screen.dart';
import 'feed/comments_screen.dart';
import 'feed/create_post_screen.dart';
import 'feed/enhanced_community_feed_screen.dart';
import 'package:artbeat_artist/src/services/community_service.dart'
    as artist_community;
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;

/// New simplified community hub with gallery-style design
class ArtCommunityHub extends StatefulWidget {
  const ArtCommunityHub({super.key});

  @override
  State<ArtCommunityHub> createState() => _ArtCommunityHubState();
}

class _ArtCommunityHubState extends State<ArtCommunityHub>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ArtCommunityService _communityService;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _communityService = ArtCommunityService();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _communityService.dispose();
    super.dispose();
  }

  void _checkAuthStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      AppLogger.info('🔐 User is authenticated: ${user.uid} (${user.email})');
    } else {
      AppLogger.error('🔐 User is NOT authenticated');
    }
  }

  void _showSearchDialog() {
    final currentTab = _tabController.index;
    final tabName = currentTab == 0
        ? 'Feed'
        : currentTab == 1
        ? 'Artists'
        : 'Topics';

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: ArtbeatColors.backgroundDark,
              title: Text(
                'Search $tabName',
                style: const TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Searching in: $tabName',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchQuery = '';
                    Navigator.of(context).pop();
                    // Trigger search update in current tab
                    setState(() {});
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: ArtbeatColors.primary),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Trigger search update in current tab
                    setState(() {});
                  },
                  child: const Text(
                    'Search',
                    style: TextStyle(color: ArtbeatColors.primary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48 + 4),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ArtbeatColors.primaryPurple, ArtbeatColors.primaryGreen],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Art Community',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Connect with artists',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              // Debug auth button
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      // Sign in anonymously for testing
                      try {
                        await FirebaseAuth.instance.signInAnonymously();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Signed in anonymously for testing'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sign in failed: $e')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Already signed in: ${user.uid}'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.person, color: Colors.white),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: _showSearchDialog,
                  icon: const Icon(Icons.search, color: Colors.white),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
              tabs: const [
                Tab(text: 'Feed', icon: Icon(Icons.feed, size: 20)),
                Tab(text: 'Artists', icon: Icon(Icons.palette, size: 20)),
                Tab(text: 'Topics', icon: Icon(Icons.topic, size: 20)),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            CommunityFeedTab(
              communityService: _communityService,
              searchQuery: _searchQuery,
            ),
            ArtistsGalleryTab(
              communityService: _communityService,
              searchQuery: _searchQuery,
            ),
            TopicsTab(
              communityService: _communityService,
              searchQuery: _searchQuery,
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ArtbeatColors.primaryPurple, ArtbeatColors.primaryGreen],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            // Navigate to enhanced create post screen
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const CreatePostScreen(),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

/// Feed tab - Gallery of all posts
class CommunityFeedTab extends StatefulWidget {
  final ArtCommunityService communityService;
  final String searchQuery;

  const CommunityFeedTab({
    super.key,
    required this.communityService,
    this.searchQuery = '',
  });

  @override
  State<CommunityFeedTab> createState() => _CommunityFeedTabState();
}

class _CommunityFeedTabState extends State<CommunityFeedTab> {
  List<PostModel> _posts = [];
  List<PostModel> _filteredPosts = [];
  List<art_walk.SocialActivity> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadActivities();
  }

  @override
  void didUpdateWidget(CommunityFeedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _filterPosts();
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    try {
      AppLogger.info('📱 Loading posts from community service...');

      final posts = await widget.communityService.getFeed(limit: 20);

      AppLogger.info('📱 Loaded ${posts.length} posts');
      if (posts.isNotEmpty) {
        AppLogger.info(
          '📱 First post like status: ${posts.first.isLikedByCurrentUser}, like count: ${posts.first.engagementStats.likeCount}',
        );
      }

      if (mounted) {
        setState(() {
          _posts = posts;
          _filteredPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('📱 Error loading posts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading posts: $e')));
      }
    }
  }

  Future<void> _loadActivities() async {
    try {
      AppLogger.info('📱 Loading social activities...');

      final socialService = art_walk.SocialService();
      final user = FirebaseAuth.instance.currentUser;

      List<art_walk.SocialActivity> activities = [];

      if (user != null) {
        // First, try to load user's own activities (most reliable)
        AppLogger.info('📱 Loading user activities for ${user.uid}');
        final userActivities = await socialService.getUserActivities(
          userId: user.uid,
          limit: 10,
        );
        AppLogger.info('📱 Loaded ${userActivities.length} user activities');
        activities = userActivities;

        // If we have few activities, also try to load nearby activities
        if (activities.length < 5) {
          try {
            final userPosition = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
              ),
            );

            final nearbyActivities = await socialService.getNearbyActivities(
              userPosition: userPosition,
              radiusKm: 80.0, // ~50 miles
              limit: 10,
            );

            AppLogger.info(
              '📱 Loaded ${nearbyActivities.length} nearby activities',
            );

            // Combine and deduplicate activities
            final activityIds = activities.map((a) => a.id).toSet();
            for (final activity in nearbyActivities) {
              if (!activityIds.contains(activity.id)) {
                activities.add(activity);
              }
            }
          } catch (e) {
            AppLogger.warning('Could not load nearby activities: $e');
          }
        }
      } else {
        AppLogger.warning('No user logged in, cannot load activities');
      }

      AppLogger.info('📱 Total activities loaded: ${activities.length}');

      if (mounted) {
        setState(() {
          _activities = activities;
        });
      }
    } catch (e) {
      AppLogger.error('📱 Error loading activities: $e');
    }
  }

  void _filterPosts() {
    setState(() {
      if (widget.searchQuery.isEmpty) {
        _filteredPosts = _posts;
      } else {
        _filteredPosts = _posts.where((post) {
          final content = post.content.toLowerCase();
          final authorName = post.userName.toLowerCase();
          final location = post.location.toLowerCase();

          return content.contains(widget.searchQuery) ||
              authorName.contains(widget.searchQuery) ||
              location.contains(widget.searchQuery);
        }).toList();
      }
    });
  }

  void _handlePostTap(PostModel post) {
    _showPostDetailDialog(post);
  }

  void _showPostDetailDialog(PostModel post) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info and close button
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: post.userPhotoUrl.isNotEmpty
                        ? NetworkImage(post.userPhotoUrl)
                        : null,
                    child: post.userPhotoUrl.isEmpty
                        ? Text(post.userName[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatPostTime(post.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Post content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post text
                      Text(post.content, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),

                      // Images
                      if (post.imageUrls.isNotEmpty) ...[
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: post.imageUrls.length,
                            itemBuilder: (context, index) => Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 8),
                              child: Image.network(
                                post.imageUrls[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Location
                      if (post.location.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              post.location,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Tags
                      if (post.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          children: post.tags
                              .map(
                                (tag) => Chip(
                                  label: Text('#$tag'),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Engagement stats
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text('${post.likesCount}'),
                          const SizedBox(width: 16),
                          const Icon(Icons.comment, size: 16),
                          const SizedBox(width: 4),
                          Text('${post.commentsCount}'),
                          const SizedBox(width: 16),
                          const Icon(Icons.share, size: 16),
                          const SizedBox(width: 4),
                          Text('${post.sharesCount}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleLike(post);
                    },
                    icon: Icon(
                      post.isLikedByCurrentUser
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: post.isLikedByCurrentUser ? Colors.red : null,
                    ),
                    label: const Text('Like'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to comments screen
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => CommentsScreen(post: post),
                        ),
                      );
                    },
                    icon: const Icon(Icons.comment),
                    label: const Text('Comment'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Implement share functionality
                      _handleShare(post);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPostTime(DateTime postTime) {
    final now = DateTime.now();
    final difference = now.difference(postTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _handleLike(PostModel post) async {
    try {
      AppLogger.info('🤍 User attempting to like post: ${post.id}');

      // Check authentication first
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.error('🤍 User not authenticated, cannot like post');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to like posts')),
        );
        return;
      }
      AppLogger.info('🤍 User authenticated: ${user.uid}');

      // Optimistically update UI
      final postIndex = _posts.indexWhere((p) => p.id == post.id);
      if (postIndex != -1) {
        AppLogger.info('🤍 Found post at index $postIndex');
        setState(() {
          final currentLikeCount = _posts[postIndex].engagementStats.likeCount;
          final isCurrentlyLiked = _posts[postIndex].isLikedByCurrentUser;

          AppLogger.info(
            '🤍 Current like count: $currentLikeCount, Currently liked: $isCurrentlyLiked',
          );

          // Create new engagement stats with updated like count
          final newEngagementStats = EngagementStats(
            likeCount: isCurrentlyLiked
                ? currentLikeCount - 1
                : currentLikeCount + 1,
            commentCount: _posts[postIndex].engagementStats.commentCount,
            shareCount: _posts[postIndex].engagementStats.shareCount,
            lastUpdated: DateTime.now(),
          );

          // Update the post with new like state
          _posts[postIndex] = _posts[postIndex].copyWith(
            isLikedByCurrentUser: !isCurrentlyLiked,
            engagementStats: newEngagementStats,
          );

          AppLogger.info(
            '🤍 Updated UI optimistically - new like count: ${newEngagementStats.likeCount}, new liked state: ${!isCurrentlyLiked}',
          );
        });
      } else {
        AppLogger.error('🤍 Post not found in _posts list');
      }

      AppLogger.info('🤍 Making API call to toggle like...');
      // Make the actual API call
      final success = await widget.communityService.toggleLike(post.id);
      AppLogger.info('🤍 API call result: $success');

      if (!success) {
        AppLogger.warning('🤍 API call failed, reverting optimistic update');
        // Revert the optimistic update if the API call failed
        if (postIndex != -1) {
          setState(() {
            final currentLikeCount =
                _posts[postIndex].engagementStats.likeCount;
            final isCurrentlyLiked = _posts[postIndex].isLikedByCurrentUser;

            final revertedEngagementStats = EngagementStats(
              likeCount: isCurrentlyLiked
                  ? currentLikeCount - 1
                  : currentLikeCount + 1,
              commentCount: _posts[postIndex].engagementStats.commentCount,
              shareCount: _posts[postIndex].engagementStats.shareCount,
              lastUpdated: DateTime.now(),
            );

            _posts[postIndex] = _posts[postIndex].copyWith(
              isLikedByCurrentUser: !isCurrentlyLiked,
              engagementStats: revertedEngagementStats,
            );
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update like. Please try again.'),
          ),
        );
      } else {
        AppLogger.info('🤍 Like successfully updated!');
      }
    } catch (e) {
      AppLogger.error('Error handling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating like. Please try again.')),
      );
    }
  }

  void _handleComment(PostModel post) {
    AppLogger.info('💬 User attempting to open comments for post: ${post.id}');

    // Check authentication first
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppLogger.error('💬 User not authenticated, cannot view comments');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to view and add comments'),
        ),
      );
      return;
    }
    AppLogger.info('💬 User authenticated: ${user.uid}');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        AppLogger.info('💬 Comments modal builder called');
        return CommentsModal(
          post: post,
          communityService: widget.communityService,
        );
      },
    );
  }

  void _handleShare(PostModel post) async {
    try {
      // Build share content
      String shareText = '';

      if (post.content.isNotEmpty) {
        shareText = '"${post.content}"\n\n';
      }

      shareText += 'Shared from ARTbeat Community\n';
      shareText += 'By ${post.userName}';

      if (post.location.isNotEmpty) {
        shareText += ' • ${post.location}';
      }

      // Add hashtags if any
      if (post.tags.isNotEmpty) {
        shareText += '\n\n${post.tags.map((tag) => '#$tag').join(' ')}';
      }

      // Share with images if available
      if (post.imageUrls.isNotEmpty) {
        // For now, share text only. In the future, we could download and share images
        await SharePlus.instance.share(ShareParams(text: shareText));
      } else {
        await SharePlus.instance.share(ShareParams(text: shareText));
      }

      // Update share count optimistically
      final postIndex = _posts.indexWhere((p) => p.id == post.id);
      if (postIndex != -1) {
        setState(() {
          final currentShareCount =
              _posts[postIndex].engagementStats.shareCount;
          final newEngagementStats = EngagementStats(
            likeCount: _posts[postIndex].engagementStats.likeCount,
            commentCount: _posts[postIndex].engagementStats.commentCount,
            shareCount: currentShareCount + 1,
            lastUpdated: DateTime.now(),
          );

          _posts[postIndex] = _posts[postIndex].copyWith(
            engagementStats: newEngagementStats,
          );
        });

        // Update share count in backend (fire and forget)
        widget.communityService.incrementShareCount(post.id);
      }
    } catch (e) {
      AppLogger.error('Error sharing post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to share post. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            ArtbeatColors.primaryPurple,
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.palette_outlined,
                size: 64,
                color: ArtbeatColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Be the first to share your creative work!',
              style: TextStyle(color: ArtbeatColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      color: ArtbeatColors.primaryPurple,
      child: CustomScrollView(
        slivers: [
          // Live Activity Feed at the top
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: LiveActivityFeed(activities: _activities),
            ),
          ),

          // Posts list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index >= _filteredPosts.length) {
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

                final post = _filteredPosts[index];
                return EnhancedPostCard(
                  post: post,
                  onTap: () => _handlePostTap(post),
                  onLike: () => _handleLike(post),
                  onComment: () => _handleComment(post),
                  onShare: () => _handleShare(post),
                );
              }, childCount: _filteredPosts.length),
            ),
          ),
        ],
      ),
    );
  }
}

/// Artists tab - Gallery of artist profiles
class ArtistsGalleryTab extends StatefulWidget {
  final ArtCommunityService communityService;
  final String searchQuery;

  const ArtistsGalleryTab({
    super.key,
    required this.communityService,
    this.searchQuery = '',
  });

  @override
  State<ArtistsGalleryTab> createState() => _ArtistsGalleryTabState();
}

class _ArtistsGalleryTabState extends State<ArtistsGalleryTab> {
  List<ArtistProfile> _artists = [];
  List<ArtistProfile> _filteredArtists = [];
  bool _isLoading = true;
  late artist_community.CommunityService _artistCommunityService;

  @override
  void initState() {
    super.initState();
    _artistCommunityService = artist_community.CommunityService();
    _loadArtists();
  }

  @override
  void didUpdateWidget(ArtistsGalleryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _filterArtists();
    }
  }

  Future<void> _loadArtists() async {
    setState(() => _isLoading = true);

    try {
      AppLogger.info('🎨 Loading artists...');
      // Fetch artists from Firestore
      final artists = await widget.communityService.fetchArtists(limit: 20);

      AppLogger.info('🎨 Loaded ${artists.length} artists');
      if (artists.isNotEmpty) {
        AppLogger.info(
          '🎨 First artist: ${artists.first.displayName}, avatar: ${artists.first.avatarUrl}, portfolio images: ${artists.first.portfolioImages.length}',
        );
      }

      if (mounted) {
        setState(() {
          _artists = artists;
          _filteredArtists = artists;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('🎨 Error loading artists: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading artists: $e')));
      }
    }
  }

  void _filterArtists() {
    setState(() {
      if (widget.searchQuery.isEmpty) {
        _filteredArtists = _artists;
      } else {
        _filteredArtists = _artists.where((artist) {
          final displayName = artist.displayName.toLowerCase();
          final bio = artist.bio.toLowerCase();

          return displayName.contains(widget.searchQuery) ||
              bio.contains(widget.searchQuery);
        }).toList();
      }
    });
  }

  void _handleArtistTap(ArtistProfile artist) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ArtistFeedScreen(
          artistId: artist.userId,
          artistName: artist.displayName,
        ),
      ),
    );
  }

  void _handleFollow(ArtistProfile artist) async {
    try {
      final success = await _artistCommunityService.followArtist(artist.userId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Following ${artist.displayName}')),
        );
        // Refresh artists to update follow status
        _loadArtists();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to follow artist')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error following artist: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            ArtbeatColors.primaryPurple,
          ),
        ),
      );
    }

    if (_artists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.people_outline,
                size: 64,
                color: ArtbeatColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No artists yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Artists will appear here as they join the community',
              style: TextStyle(color: ArtbeatColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Call-to-action to become an artist
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ArtbeatColors.primaryPurple,
                    ArtbeatColors.primaryPurple.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '🎨 Ready to showcase your art?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join our artist community and share your creative work with the world',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute<bool>(
                          builder: (context) => const ArtistOnboardingScreen(),
                        ),
                      );

                      if (result == true && mounted) {
                        // Refresh the artists list after successful onboarding
                        _loadArtists();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Welcome to the artist community! 🎉',
                            ),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.brush, color: Colors.white),
                    label: const Text(
                      'Become an Artist',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadArtists,
      color: ArtbeatColors.primaryPurple,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: _filteredArtists.length,
        itemBuilder: (context, index) {
          final artist = _filteredArtists[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: ArtistCard(
              artist: artist,
              onTap: () => _handleArtistTap(artist),
              onFollow: () => _handleFollow(artist),
            ),
          );
        },
      ),
    );
  }
}

/// Topics tab - Browse by categories
class TopicsTab extends StatefulWidget {
  final ArtCommunityService communityService;
  final String searchQuery;

  const TopicsTab({
    super.key,
    required this.communityService,
    this.searchQuery = '',
  });

  @override
  State<TopicsTab> createState() => _TopicsTabState();
}

class _TopicsTabState extends State<TopicsTab> {
  List<String> _topics = [];
  List<String> _filteredTopics = [];
  bool _isLoading = true;

  final List<String> _defaultTopics = [
    'Paintings',
    'Digital Art',
    'Photography',
    'Sculpture',
    'Mixed Media',
    'Street Art',
    'Abstract',
    'Realism',
    'Watercolor',
    'Charcoal',
    'Ceramics',
    'Textile Art',
  ];

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  @override
  void didUpdateWidget(TopicsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _filterTopics();
    }
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoading = true);

    try {
      final topics = await widget.communityService.getPopularTopics(limit: 12);
      if (mounted) {
        setState(() {
          _topics = topics.isNotEmpty ? topics : _defaultTopics;
          _filteredTopics = _topics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _topics = _defaultTopics;
          _filteredTopics = _topics;
          _isLoading = false;
        });
      }
    }
  }

  void _filterTopics() {
    setState(() {
      if (widget.searchQuery.isEmpty) {
        _filteredTopics = _topics;
      } else {
        _filteredTopics = _topics
            .where((topic) => topic.toLowerCase().contains(widget.searchQuery))
            .toList();
      }
    });
  }

  void _handleTopicTap(String topic) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EnhancedCommunityFeedScreen(topicFilter: topic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            ArtbeatColors.primaryPurple,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTopics,
      color: ArtbeatColors.primaryPurple,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: _filteredTopics.length,
        itemBuilder: (context, index) {
          final topic = _filteredTopics[index];
          return _buildTopicCard(topic);
        },
      ),
    );
  }

  Widget _buildTopicCard(String topic) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _handleTopicTap(topic),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTopicIcon(topic),
                    size: 32,
                    color: ArtbeatColors.primaryPurple,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  topic,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ArtbeatColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTopicIcon(String topic) {
    switch (topic.toLowerCase()) {
      case 'paintings':
        return Icons.brush;
      case 'digital art':
        return Icons.computer;
      case 'photography':
        return Icons.camera_alt;
      case 'sculpture':
        return Icons.account_balance;
      case 'mixed media':
        return Icons.auto_awesome;
      case 'street art':
        return Icons.location_city;
      case 'abstract':
        return Icons.blur_on;
      case 'realism':
        return Icons.visibility;
      case 'watercolor':
        return Icons.color_lens;
      case 'charcoal':
        return Icons.edit;
      case 'ceramics':
        return Icons.restaurant;
      case 'textile art':
        return Icons.texture;
      default:
        return Icons.palette;
    }
  }
}

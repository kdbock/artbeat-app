import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_ads/artbeat_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/community_service.dart';
import '../../models/post_model.dart';
import '../../models/group_models.dart';

class CommunityDashboardScreen extends StatefulWidget {
  const CommunityDashboardScreen({Key? key}) : super(key: key);

  @override
  State<CommunityDashboardScreen> createState() =>
      _CommunityDashboardScreenState();
}

class _CommunityDashboardScreenState extends State<CommunityDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final CommunityService _communityService = CommunityService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Data lists
  List<Map<String, dynamic>> _onlineArtists = [];
  List<PostModel> _recentPosts = [];
  List<BaseGroupPost> _recentGroupPosts = [];
  List<Map<String, dynamic>> _featuredArtists = [];
  List<Map<String, dynamic>> _verifiedArtists = [];
  List<Map<String, dynamic>> _artists = [];

  // Loading states
  bool _isLoadingOnlineArtists = true;
  bool _isLoadingRecentPosts = true;
  bool _isLoadingFeaturedArtists = true;
  bool _isLoadingVerifiedArtists = true;
  bool _isLoadingArtists = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();

    // Mark community as visited when this screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<core.CommunityProvider>().markCommunityAsVisited();
      }
    });
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadOnlineArtists(),
      _loadRecentPosts(),
      _loadFeaturedArtists(),
      _loadVerifiedArtists(),
      _loadArtists(),
    ]);
  }

  Future<void> _loadOnlineArtists() async {
    try {
      setState(() => _isLoadingOnlineArtists = true);

      // Get artist profiles from artistProfiles collection
      final snapshot = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .where('isOnline', isEqualTo: true)
          .limit(10)
          .get();

      final artists = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'userId': data['userId'] ?? '',
          'name': data['displayName'] ?? 'Unknown Artist',
          'avatar': data['profileImageUrl'] ?? '',
          'isOnline': data['isOnline'] ?? false,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _onlineArtists = artists;
          _isLoadingOnlineArtists = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading online artists: $e');
      if (mounted) {
        setState(() => _isLoadingOnlineArtists = false);
      }
    }
  }

  Future<void> _loadRecentPosts() async {
    try {
      setState(() => _isLoadingRecentPosts = true);

      // Load both regular posts and group posts
      final results = await Future.wait([
        _communityService.getPosts(limit: 5),
        _loadGroupPosts(limit: 5),
      ]);

      if (mounted) {
        setState(() {
          _recentPosts = results[0] as List<PostModel>;
          _recentGroupPosts = results[1] as List<BaseGroupPost>;
          _isLoadingRecentPosts = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent posts: $e');
      if (mounted) {
        setState(() => _isLoadingRecentPosts = false);
      }
    }
  }

  Future<List<BaseGroupPost>> _loadGroupPosts({int limit = 10}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final groupType = data['groupType'] as String? ?? '';

        switch (groupType) {
          case 'artist':
            return ArtistGroupPost.fromFirestore(doc);
          case 'event':
            return EventGroupPost.fromFirestore(doc);
          case 'artwalk':
            return ArtWalkAdventurePost.fromFirestore(doc);
          case 'artistwanted':
            return ArtistWantedPost.fromFirestore(doc);
          default:
            // Return a basic artist post as fallback
            return ArtistGroupPost.fromFirestore(doc);
        }
      }).toList();
    } catch (e) {
      debugPrint('Error loading group posts: $e');
      return [];
    }
  }

  Future<void> _loadFeaturedArtists() async {
    try {
      setState(() => _isLoadingFeaturedArtists = true);

      // Get featured artists from artistProfiles collection
      final snapshot = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .where('isFeatured', isEqualTo: true)
          .limit(10)
          .get();

      final artists = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final followerCount = await _getFollowerCount(doc.id);

        // Get mediums and styles for specialty display
        final mediums = data['mediums'] as List<dynamic>? ?? [];
        final styles = data['styles'] as List<dynamic>? ?? [];
        String specialty = '';

        if (mediums.isNotEmpty) {
          specialty = mediums.first.toString();
        } else if (styles.isNotEmpty) {
          specialty = styles.first.toString();
        } else if (data['location'] != null &&
            (data['location'] as String).isNotEmpty) {
          specialty = data['location'] as String;
        }

        artists.add({
          'id': doc.id,
          'userId': data['userId'] ?? '',
          'name': data['displayName'] ?? 'Unknown Artist',
          'specialty': specialty,
          'avatar': data['profileImageUrl'] ?? '',
          'followers': _formatFollowerCount(followerCount),
        });
      }

      if (mounted) {
        setState(() {
          _featuredArtists = artists;
          _isLoadingFeaturedArtists = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading featured artists: $e');
      if (mounted) {
        setState(() => _isLoadingFeaturedArtists = false);
      }
    }
  }

  Future<void> _loadVerifiedArtists() async {
    try {
      setState(() => _isLoadingVerifiedArtists = true);

      // Get verified artists from artistProfiles collection
      final snapshot = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .where('isVerified', isEqualTo: true)
          .limit(10)
          .get();

      final artists = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final followerCount = await _getFollowerCount(doc.id);

        // Get mediums and styles for specialty display
        final mediums = data['mediums'] as List<dynamic>? ?? [];
        final styles = data['styles'] as List<dynamic>? ?? [];
        String specialty = '';

        if (mediums.isNotEmpty) {
          specialty = mediums.first.toString();
        } else if (styles.isNotEmpty) {
          specialty = styles.first.toString();
        } else if (data['location'] != null &&
            (data['location'] as String).isNotEmpty) {
          specialty = data['location'] as String;
        }

        artists.add({
          'id': doc.id,
          'userId': data['userId'] ?? '',
          'name': data['displayName'] ?? 'Unknown Artist',
          'specialty': specialty,
          'avatar': data['profileImageUrl'] ?? '',
          'followers': _formatFollowerCount(followerCount),
        });
      }

      if (mounted) {
        setState(() {
          _verifiedArtists = artists;
          _isLoadingVerifiedArtists = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading verified artists: $e');
      if (mounted) {
        setState(() => _isLoadingVerifiedArtists = false);
      }
    }
  }

  Future<void> _loadArtists() async {
    try {
      setState(() => _isLoadingArtists = true);

      // Get artists that are not featured and not verified
      final snapshot = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .where('isFeatured', isEqualTo: false)
          .where('isVerified', isEqualTo: false)
          .limit(10)
          .get();

      final artists = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final followerCount = await _getFollowerCount(doc.id);

        // Get mediums and styles for specialty display
        final mediums = data['mediums'] as List<dynamic>? ?? [];
        final styles = data['styles'] as List<dynamic>? ?? [];
        String specialty = '';

        if (mediums.isNotEmpty) {
          specialty = mediums.first.toString();
        } else if (styles.isNotEmpty) {
          specialty = styles.first.toString();
        } else if (data['location'] != null &&
            (data['location'] as String).isNotEmpty) {
          specialty = data['location'] as String;
        }

        artists.add({
          'id': doc.id,
          'userId': data['userId'] ?? '',
          'name': data['displayName'] ?? 'Unknown Artist',
          'specialty': specialty,
          'avatar': data['profileImageUrl'] ?? '',
          'followers': _formatFollowerCount(followerCount),
        });
      }

      if (mounted) {
        setState(() {
          _artists = artists;
          _isLoadingArtists = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading artists: $e');
      if (mounted) {
        setState(() => _isLoadingArtists = false);
      }
    }
  }

  /// Get the actual follower count for an artist from the artistFollows collection
  Future<int> _getFollowerCount(String artistProfileId) async {
    try {
      final followersSnapshot = await FirebaseFirestore.instance
          .collection('artistFollows')
          .where('artistProfileId', isEqualTo: artistProfileId)
          .get();

      return followersSnapshot.docs.length;
    } catch (e) {
      debugPrint(
        'Error getting follower count for artist $artistProfileId: $e',
      );
      return 0;
    }
  }

  String _formatFollowerCount(dynamic count) {
    final intCount = (count is int)
        ? count
        : (count is num)
        ? count.toInt()
        : 0;
    if (intCount >= 1000000) {
      return '${(intCount / 1000000).toStringAsFixed(1)}M';
    } else if (intCount >= 1000) {
      return '${(intCount / 1000).toStringAsFixed(1)}K';
    } else {
      return intCount.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: 3, // Community is index 3
      scaffoldKey: _scaffoldKey,
      appBar: const core.EnhancedUniversalHeader(title: 'Community Canvas'),
      child: RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Online Artists Section
              _buildOnlineArtistsSection(),

              // Ad placement beneath online artists section
              const BannerAdWidget(location: AdLocation.communityOnlineArtists),
              const SizedBox(height: 16),

              // Recent Posts Section
              _buildRecentPostsSection(),

              // Ad placement beneath recent posts section
              const BannerAdWidget(location: AdLocation.communityRecentPosts),
              const SizedBox(height: 16),

              // Are You An Artist Widget
              _buildAreYouAnArtistSection(),

              // Featured Artists Section
              _buildFeaturedArtistsSection(),

              // Ad placement beneath featured artists section
              const BannerAdWidget(
                location: AdLocation.communityFeaturedArtists,
              ),
              const SizedBox(height: 16),

              // Verified Artists Section
              _buildVerifiedArtistsSection(),

              // Ad placement beneath verified artists section
              const BannerAdWidget(
                location: AdLocation.communityVerifiedArtists,
              ),
              const SizedBox(height: 16),

              // Artists Section
              _buildArtistsSection(),

              const SizedBox(height: 120), // Bottom padding for navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineArtistsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: core.ArtbeatColors.primaryGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Artists Online',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: core.ArtbeatColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_isLoadingOnlineArtists)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    '${_onlineArtists.length} online',
                    style: const TextStyle(
                      fontSize: 14,
                      color: core.ArtbeatColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: _isLoadingOnlineArtists
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 5,
                    itemBuilder: (context, index) => Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 40,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _onlineArtists.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No artists online right now',
                        style: TextStyle(
                          color: core.ArtbeatColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _onlineArtists.length,
                    itemBuilder: (context, index) {
                      final artist = _onlineArtists[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: InkWell(
                          onTap: () {
                            // Navigate to artist feed screen
                            final userId = artist['userId'] as String?;
                            if (userId != null && userId.isNotEmpty) {
                              Navigator.pushNamed(
                                context,
                                '/artist/feed',
                                arguments: {'artistUserId': userId},
                              );
                            } else {
                              // Fallback: show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Unable to load artist feed'),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(25),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundImage:
                                        (artist['avatar'] != null &&
                                            (artist['avatar'] as String)
                                                .isNotEmpty &&
                                            Uri.tryParse(
                                                  artist['avatar'] as String,
                                                )?.hasScheme ==
                                                true)
                                        ? NetworkImage(
                                                artist['avatar'] as String,
                                              )
                                              as ImageProvider
                                        : null,
                                    child:
                                        (artist['avatar'] == null ||
                                            (artist['avatar'] as String)
                                                .isEmpty ||
                                            Uri.tryParse(
                                                  artist['avatar'] as String,
                                                )?.hasScheme !=
                                                true)
                                        ? const Icon(Icons.person, size: 30)
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: core.ArtbeatColors.primaryGreen,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                (artist['name'] as String).split(' ')[0],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPostsSection() {
    // Combine regular posts and group posts for display
    final allPosts = <dynamic>[..._recentPosts, ..._recentGroupPosts];
    allPosts.sort((a, b) {
      final aDate = (a as dynamic).createdAt as DateTime;
      final bDate = (b as dynamic).createdAt as DateTime;
      return bDate.compareTo(aDate);
    });
    final displayPosts = allPosts.take(5).toList();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: core.ArtbeatColors.primaryPurple,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recent Posts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: core.ArtbeatColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_isLoadingRecentPosts)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/community/feed');
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _isLoadingRecentPosts
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 3,
                    itemBuilder: (context, index) => Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : displayPosts.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No recent posts available',
                        style: TextStyle(
                          color: core.ArtbeatColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: displayPosts.length,
                    itemBuilder: (context, index) {
                      final post = displayPosts[index];
                      return _buildPostCard(post);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getPostImageUrl(dynamic post) {
    if (post is PostModel) {
      return post.imageUrls.isNotEmpty ? post.imageUrls.first : '';
    } else if (post is BaseGroupPost) {
      return post.imageUrls.isNotEmpty ? post.imageUrls.first : '';
    }
    return '';
  }

  String _getPostTitle(dynamic post) {
    if (post is PostModel) {
      return post.content.length > 30
          ? '${post.content.substring(0, 30)}...'
          : post.content;
    } else if (post is ArtistGroupPost) {
      return post.artworkTitle.isNotEmpty ? post.artworkTitle : post.content;
    } else if (post is EventGroupPost) {
      return post.eventTitle.isNotEmpty ? post.eventTitle : post.content;
    } else if (post is BaseGroupPost) {
      return post.content.length > 30
          ? '${post.content.substring(0, 30)}...'
          : post.content;
    }
    return 'Untitled';
  }

  String _getPostAuthor(dynamic post) {
    if (post is PostModel) {
      return post.userName;
    } else if (post is BaseGroupPost) {
      return post.userName;
    }
    return 'Unknown';
  }

  int _getPostLikes(dynamic post) {
    if (post is PostModel) {
      return post.applauseCount;
    } else if (post is BaseGroupPost) {
      return post.applauseCount;
    }
    return 0;
  }

  Widget _buildPostCard(dynamic post) {
    final imageUrl = _getPostImageUrl(post);
    final title = _getPostTitle(post);
    final author = _getPostAuthor(post);
    final likes = _getPostLikes(post);
    final hasImage = imageUrl.isNotEmpty;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to community feed and scroll to this specific post
          String? postId;
          if (post is PostModel) {
            postId = post.id;
          } else if (post is BaseGroupPost) {
            postId = post.id;
          }

          Navigator.pushNamed(
            context,
            '/community/feed',
            arguments: postId != null ? {'scrollToPostId': postId} : null,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: hasImage
              ? _buildImagePostCard(imageUrl, title, author, likes)
              : _buildTextPostCard(post, title, author, likes),
        ),
      ),
    );
  }

  Widget _buildImagePostCard(
    String imageUrl,
    String title,
    String author,
    int likes,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image, color: Colors.grey, size: 40),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      author,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$likes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextPostCard(
    dynamic post,
    String title,
    String author,
    int likes,
  ) {
    // Get post type and content for better display
    final content = _getPostContent(post);
    final postType = _getPostType(post);
    final backgroundColor = _getPostBackgroundColor(postType);
    final accentColor = _getPostAccentColor(postType);

    return Container(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                postType,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Content
            Expanded(
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: core.ArtbeatColors.textPrimary,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 12),

            // Author and likes
            Row(
              children: [
                Expanded(
                  child: Text(
                    author,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: core.ArtbeatColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.favorite, color: accentColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$likes',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPostContent(dynamic post) {
    if (post is PostModel) {
      return post.content;
    } else if (post is ArtistGroupPost) {
      if (post.artworkTitle.isNotEmpty && post.artworkDescription.isNotEmpty) {
        return '${post.artworkTitle}\n\n${post.artworkDescription}';
      } else if (post.artworkTitle.isNotEmpty) {
        return post.artworkTitle;
      }
      return post.content;
    } else if (post is EventGroupPost) {
      if (post.eventTitle.isNotEmpty && post.eventDescription.isNotEmpty) {
        return '${post.eventTitle}\n\n${post.eventDescription}';
      } else if (post.eventTitle.isNotEmpty) {
        return post.eventTitle;
      }
      return post.content;
    } else if (post is ArtWalkAdventurePost) {
      return post.routeName.isNotEmpty ? post.routeName : post.content;
    } else if (post is ArtistWantedPost) {
      if (post.projectTitle.isNotEmpty && post.projectDescription.isNotEmpty) {
        return '${post.projectTitle}\n\n${post.projectDescription}';
      } else if (post.projectTitle.isNotEmpty) {
        return post.projectTitle;
      }
      return post.content;
    } else if (post is BaseGroupPost) {
      return post.content;
    }
    return 'No content available';
  }

  String _getPostType(dynamic post) {
    if (post is PostModel) {
      return 'POST';
    } else if (post is ArtistGroupPost) {
      return 'ARTWORK';
    } else if (post is EventGroupPost) {
      return 'EVENT';
    } else if (post is ArtWalkAdventurePost) {
      return 'ART WALK';
    } else if (post is ArtistWantedPost) {
      return 'OPPORTUNITY';
    }
    return 'POST';
  }

  Color _getPostBackgroundColor(String postType) {
    switch (postType) {
      case 'ARTWORK':
        return const Color(0xFFF3E5F5); // Light purple
      case 'EVENT':
        return const Color(0xFFE8F5E8); // Light green
      case 'ART WALK':
        return const Color(0xFFE3F2FD); // Light blue
      case 'OPPORTUNITY':
        return const Color(0xFFFFF3E0); // Light orange
      default:
        return const Color(0xFFF5F5F5); // Light gray
    }
  }

  Color _getPostAccentColor(String postType) {
    switch (postType) {
      case 'ARTWORK':
        return core.ArtbeatColors.primaryPurple;
      case 'EVENT':
        return core.ArtbeatColors.primaryGreen;
      case 'ART WALK':
        return Colors.blue;
      case 'OPPORTUNITY':
        return Colors.orange;
      default:
        return core.ArtbeatColors.textSecondary;
    }
  }

  Widget _buildAreYouAnArtistSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: const core.CompactArtistCTAWidget(),
    );
  }

  Widget _buildFeaturedArtistsSection() {
    return _buildArtistSection(
      title: 'Featured Artists',
      artists: _featuredArtists,
      color: core.ArtbeatColors.accentYellow,
      showFollowers: true,
      isLoading: _isLoadingFeaturedArtists,
    );
  }

  Widget _buildVerifiedArtistsSection() {
    return _buildArtistSection(
      title: 'Verified Artists',
      artists: _verifiedArtists,
      color: core.ArtbeatColors.primaryGreen,
      showFollowers: true,
      showVerifiedBadge: true,
      isLoading: _isLoadingVerifiedArtists,
    );
  }

  Widget _buildArtistsSection() {
    return _buildArtistSection(
      title: 'Artists',
      artists: _artists,
      color: core.ArtbeatColors.primaryPurple,
      showFollowers: true,
      isLoading: _isLoadingArtists,
    );
  }

  Widget _buildArtistSection({
    required String title,
    required List<Map<String, dynamic>> artists,
    required Color color,
    bool showFollowers = false,
    bool showVerifiedBadge = false,
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: core.ArtbeatColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/community/artists',
                        arguments: {
                          'title': title,
                          'artists': artists,
                          'color': color,
                          'showFollowers': showFollowers,
                          'showVerifiedBadge': showVerifiedBadge,
                        },
                      );
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: isLoading
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 3,
                    itemBuilder: (context, index) => Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 80,
                            height: 13,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 60,
                            height: 11,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : artists.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No ${title.toLowerCase()} available',
                        style: const TextStyle(
                          color: core.ArtbeatColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: artists.length,
                    itemBuilder: (context, index) {
                      final artist = artists[index];
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 16),
                        child: InkWell(
                          onTap: () {
                            // Navigate to artist feed screen
                            final userId = artist['userId'] as String?;
                            if (userId != null && userId.isNotEmpty) {
                              Navigator.pushNamed(
                                context,
                                '/artist/feed',
                                arguments: {'artistUserId': userId},
                              );
                            } else {
                              // Fallback: show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Unable to load artist feed'),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: color.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundImage:
                                          (artist['avatar'] != null &&
                                              (artist['avatar'] as String)
                                                  .isNotEmpty &&
                                              Uri.tryParse(
                                                    artist['avatar'] as String,
                                                  )?.hasScheme ==
                                                  true)
                                          ? NetworkImage(
                                                  artist['avatar'] as String,
                                                )
                                                as ImageProvider
                                          : null,
                                      child:
                                          (artist['avatar'] == null ||
                                              (artist['avatar'] as String)
                                                  .isEmpty ||
                                              Uri.tryParse(
                                                    artist['avatar'] as String,
                                                  )?.hasScheme !=
                                                  true)
                                          ? const Icon(Icons.person, size: 26)
                                          : null,
                                    ),
                                    if (showVerifiedBadge)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.verified,
                                            color: color,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  artist['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: core.ArtbeatColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                if ((artist['specialty'] as String)
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    artist['specialty'] as String,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: core.ArtbeatColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                if (showFollowers) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    '${artist['followers'] as String} followers',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

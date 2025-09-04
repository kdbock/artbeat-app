import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_ads/artbeat_ads.dart';
import 'package:artbeat_artist/artbeat_artist.dart' show CommissionStatus;
import '../../theme/community_colors.dart';
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../models/artwork_model.dart' as community_artwork;
import '../../models/commission_model.dart';
import '../../services/commission_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/post_detail_modal.dart';
import '../../widgets/community_drawer.dart';

// Tab-specific version of commissions content (without MainLayout)
class CommissionsTab extends StatefulWidget {
  const CommissionsTab({super.key});

  @override
  State<CommissionsTab> createState() => _CommissionsTabState();
}

class _CommissionsTabState extends State<CommissionsTab>
    with SingleTickerProviderStateMixin {
  final CommissionService _commissionService = CommissionService();
  late final TabController _tabController;
  List<CommissionModel> _commissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCommissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommissions() async {
    setState(() => _isLoading = true);
    try {
      final commissions = await _commissionService.getCommissionsByUser(
        'userId',
      );
      setState(() {
        _commissions = commissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading commissions: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs for filtering commissions
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
        // Commission list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Active commissions
                    _buildCommissionList(
                      _commissions
                          .where((c) => c.status == CommissionStatus.active)
                          .toList(),
                    ),
                    // Pending commissions
                    _buildCommissionList(
                      _commissions
                          .where((c) => c.status == CommissionStatus.pending)
                          .toList(),
                    ),
                    // Completed commissions
                    _buildCommissionList(
                      _commissions
                          .where((c) => c.status == CommissionStatus.completed)
                          .toList(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCommissionList(List<CommissionModel> commissions) {
    if (commissions.isEmpty) {
      return const Center(child: Text('No commissions found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: commissions.length,
      itemBuilder: (context, index) {
        final commission = commissions[index];
        return Card(
          child: ListTile(
            title: Text('Commission Rate: ${commission.commissionRate}%'),
            subtitle: Text('Status: ${commission.status}'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              _showCommissionDetails(commission);
            },
          ),
        );
      },
    );
  }

  void _showCommissionDetails(CommissionModel commission) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Commission Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Commission ID', commission.id),
              _buildDetailRow('Gallery ID', commission.galleryId),
              _buildDetailRow('Artist ID', commission.artistId),
              _buildDetailRow('Artwork ID', commission.artworkId),
              _buildDetailRow(
                'Commission Rate',
                '${commission.commissionRate}%',
              ),
              _buildDetailRow('Status', commission.status),
              _buildDetailRow(
                'Created',
                commission.createdAt.toDate().toString(),
              ),
              _buildDetailRow(
                'Updated',
                commission.updatedAt.toDate().toString(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

class UnifiedCommunityHub extends StatefulWidget {
  const UnifiedCommunityHub({super.key});

  @override
  State<UnifiedCommunityHub> createState() => _UnifiedCommunityHubState();
}

class _UnifiedCommunityHubState extends State<UnifiedCommunityHub>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isDisposed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Handle hot reload scenarios where TabController length might be cached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabController.length != 3) {
        _tabController.dispose();
        _tabController = TabController(length: 3, vsync: this);
      }
    });

    // Mark community as visited when this screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        try {
          context.read<CommunityProvider>().markCommunityAsVisited();
        } catch (e) {
          // Provider might be disposed, silently ignore
          debugPrint('CommunityProvider access failed: $e');
        }
      }
    });
  }

  @override
  void didUpdateWidget(UnifiedCommunityHub oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recreate TabController if length doesn't match (handles hot reload issues)
    if (_tabController.length != 3) {
      _tabController.dispose();
      _tabController = TabController(length: 3, vsync: this);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 3,
      drawer: const CommunityDrawer(),
      scaffoldKey: _scaffoldKey,
      appBar: EnhancedUniversalHeader(
        title: 'Community',
        showLogo: false,
        showBackButton: false,
        scaffoldKey: _scaffoldKey,
        backgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [CommunityColors.primary, CommunityColors.secondary],
        ),
        titleGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [CommunityColors.primary, CommunityColors.secondary],
        ),
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: CommunityColors.communityBackgroundGradient,
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              CommunityDiscoverTab(
                onNavigateToTab: (index) => _tabController.animateTo(index),
              ),
              const CommunityFeedTab(),
              const CommissionsTab(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: Implement create post functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create post - Coming soon!')),
            );
          },
          backgroundColor: ArtbeatColors.primaryPurple,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

// Feed Tab - Based on UnifiedCommunityFeed
class CommunityFeedTab extends StatefulWidget {
  const CommunityFeedTab({super.key});

  @override
  State<CommunityFeedTab> createState() => _CommunityFeedTabState();
}

class _CommunityFeedTabState extends State<CommunityFeedTab> {
  final ScrollController _scrollController = ScrollController();
  final List<PostModel> _posts = [];
  final Map<String, List<CommentModel>> _postComments = {};

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;
  DocumentSnapshot? _lastDocument;

  static const int _postsPerPage = 10;

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

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _handleUserTap(String userId) {
    // TODO: Navigate to user profile
    debugPrint('User tapped: $userId');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User profile for $userId (coming soon)')),
    );
  }

  void _navigateToComments(String postId) {
    final post = _posts.firstWhere((p) => p.id == postId);
    PostDetailModal.showFromPostModel(context, post).then((_) {
      _fetchCommentsForPost(postId);
    });
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

        // Enrich posts with user data
        for (var post in loadedPosts) {
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
              debugPrint('Error enriching post ${post.id} user data: $e');
            }
          }
        }

        // Load comments for each post
        for (final post in loadedPosts) {
          await _fetchCommentsForPost(post.id);
        }

        if (mounted) {
          setState(() {
            _posts.addAll(loadedPosts);
            _isLoading = false;
          });
        }
      } else {
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

        // Enrich and load comments for new posts
        for (var post in morePosts) {
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
              debugPrint('Error enriching post ${post.id} user data: $e');
            }
          }
          await _fetchCommentsForPost(post.id);
        }

        if (mounted) {
          setState(() {
            _posts.addAll(morePosts);
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
              style: const TextStyle(color: ArtbeatColors.textPrimary),
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
                'Be the first to share your creative work and connect with the community.',
                style: TextStyle(
                  color: ArtbeatColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
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

          if (_isAdPosition(index)) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: FeedAdWidget(
                location: AdLocation.communityFeed,
                index: index,
              ),
            );
          }

          final postIndex = _getPostIndex(index);
          if (postIndex >= _posts.length) return const SizedBox.shrink();

          final post = _posts[postIndex];
          final comments = _postComments[post.id] ?? [];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PostCard(
              post: post,
              currentUserId: _currentUserId,
              comments: comments,
              onUserTap: _handleUserTap,
              onComment: _navigateToComments,
              onToggleExpand: () => setState(() {}),
            ),
          );
        },
      ),
    );
  }

  int _getTotalItemCount() {
    if (_posts.isEmpty) return _isLoadingMore ? 1 : 0;

    final adCount = (_posts.length / 5).floor();
    final totalItems = _posts.length + adCount;

    return totalItems + (_isLoadingMore ? 1 : 0);
  }

  bool _isAdPosition(int index) {
    if (index < 5) return false;
    return (index - 5) % 6 == 0;
  }

  int _getPostIndex(int listIndex) {
    if (listIndex < 5) return listIndex;

    final adsBeforeIndex = ((listIndex - 5) / 6).floor() + 1;
    return listIndex - adsBeforeIndex;
  }
}

// Artworks Tab - Enhanced version of CanvasFeedScreen
class CommunityArtworksTab extends StatefulWidget {
  const CommunityArtworksTab({super.key});

  @override
  State<CommunityArtworksTab> createState() => _CommunityArtworksTabState();
}

class _CommunityArtworksTabState extends State<CommunityArtworksTab> {
  List<community_artwork.ArtworkModel> _artworks = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadArtworks();
  }

  Future<void> _loadArtworks() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Load artworks from Firestore - you may need to adjust this based on your data structure
      final artworksSnapshot = await FirebaseFirestore.instance
          .collection('artwork')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      if (!mounted) return;

      final artworks = artworksSnapshot.docs.map((doc) {
        final data = doc.data();
        return community_artwork.ArtworkModel(
          id: doc.id,
          title: (data['title'] as String?) ?? 'Untitled',
          description: (data['description'] as String?) ?? '',
          imageUrl: (data['imageUrl'] as String?) ?? '',
          artistId:
              (data['artistId'] as String?) ??
              (data['userId'] as String?) ??
              '',
          medium: (data['medium'] as String?) ?? 'Unknown',
          location: (data['location'] as String?) ?? '',
          createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _artworks = artworks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading artworks: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load artworks: ${e.toString()}';
          _isLoading = false;
        });
      }
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
              style: const TextStyle(color: ArtbeatColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArtworks,
              style: ArtbeatComponents.primaryButtonStyle,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_artworks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                'No artworks yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Artists are working on amazing pieces. Check back soon!',
                style: TextStyle(
                  color: ArtbeatColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadArtworks,
      color: ArtbeatColors.primaryPurple,
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: _artworks.length,
        itemBuilder: (context, index) {
          final artwork = _artworks[index];
          return _buildArtworkCard(artwork);
        },
      ),
    );
  }

  Widget _buildArtworkCard(community_artwork.ArtworkModel artwork) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to artwork detail
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Artwork: ${artwork.title}')));
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: artwork.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(artwork.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: artwork.imageUrl.isEmpty
                    ? const Icon(Icons.image, size: 48, color: Colors.grey)
                    : null,
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ArtbeatColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${artwork.artist?.displayName ?? 'Unknown Artist'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ArtbeatColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.brush,
                          size: 12,
                          color: ArtbeatColors.primaryPurple,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            artwork.medium,
                            style: const TextStyle(
                              fontSize: 12,
                              color: ArtbeatColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Price display removed - not available in community ArtworkModel
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Discover Tab - Based on CommunityDashboardScreen
class CommunityDiscoverTab extends StatefulWidget {
  final void Function(int)? onNavigateToTab;

  const CommunityDiscoverTab({super.key, this.onNavigateToTab});

  @override
  State<CommunityDiscoverTab> createState() => _CommunityDiscoverTabState();
}

class _CommunityDiscoverTabState extends State<CommunityDiscoverTab> {
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _onlineArtists = [];
  List<PostModel> _recentPosts = [];
  List<Map<String, dynamic>> _featuredArtists = [];
  List<Map<String, dynamic>> _verifiedArtists = [];
  List<Map<String, dynamic>> _artists = [];

  bool _isLoadingOnlineArtists = true;
  bool _isLoadingRecentPosts = true;
  bool _isLoadingFeaturedArtists = true;
  bool _isLoadingVerifiedArtists = true;
  bool _isLoadingArtists = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
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

      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      if (mounted) {
        setState(() {
          _recentPosts = snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
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

  Future<void> _loadFeaturedArtists() async {
    try {
      setState(() => _isLoadingFeaturedArtists = true);

      final snapshot = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .where('isFeatured', isEqualTo: true)
          .limit(10)
          .get();

      final artists = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final followerCount = await _getFollowerCount(doc.id);

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

      final snapshot = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .where('isVerified', isEqualTo: true)
          .limit(10)
          .get();

      final artists = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final followerCount = await _getFollowerCount(doc.id);

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
    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: ArtbeatColors.primaryPurple,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Online Artists Section
            _buildOnlineArtistsSection(),

            // Ad placement
            const BannerAdWidget(location: AdLocation.communityOnlineArtists),
            const SizedBox(height: 16),

            // Recent Posts Section
            _buildRecentPostsSection(),

            // Ad placement
            const BannerAdWidget(location: AdLocation.communityRecentPosts),
            const SizedBox(height: 16),

            // Featured Artists Section
            _buildArtistsSection(
              title: 'Featured Artists',
              artists: _featuredArtists,
              color: ArtbeatColors.accentYellow,
              showFollowers: true,
              isLoading: _isLoadingFeaturedArtists,
            ),

            // Ad placement
            const BannerAdWidget(location: AdLocation.communityFeaturedArtists),
            const SizedBox(height: 16),

            // Verified Artists Section
            _buildArtistsSection(
              title: 'Verified Artists',
              artists: _verifiedArtists,
              color: ArtbeatColors.primaryGreen,
              showFollowers: true,
              showVerifiedBadge: true,
              isLoading: _isLoadingVerifiedArtists,
            ),

            // Ad placement
            const BannerAdWidget(location: AdLocation.communityVerifiedArtists),
            const SizedBox(height: 16),

            // Artists Section
            _buildArtistsSection(
              title: 'Artists',
              artists: _artists,
              color: ArtbeatColors.primaryPurple,
              showFollowers: true,
              isLoading: _isLoadingArtists,
            ),

            const SizedBox(height: 120),
          ],
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
                    color: ArtbeatColors.primaryGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Artists Online',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
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
                      color: ArtbeatColors.primaryGreen,
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
                          color: ArtbeatColors.textSecondary,
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
                            final userId = artist['userId'] as String?;
                            if (userId != null && userId.isNotEmpty) {
                              Navigator.pushNamed(
                                context,
                                '/artist/feed',
                                arguments: {
                                  'artistUserId': userId,
                                  'displayName':
                                      artist['name'] ?? 'Unknown Artist',
                                  'profileImageUrl': artist['avatar'],
                                },
                              );
                            } else {
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
                                        color: ArtbeatColors.primaryGreen,
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
    final displayPosts = _recentPosts.take(5).toList();

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
                    color: ArtbeatColors.primaryPurple,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recent Posts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
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
                  Container(
                    decoration: BoxDecoration(
                      gradient: CommunityColors.communityGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to feed tab
                        widget.onNavigateToTab?.call(
                          1,
                        ); // Navigate to Art Feed tab (index 1)
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
                          color: ArtbeatColors.textSecondary,
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
                            // Navigate to feed tab and scroll to post
                            widget.onNavigateToTab?.call(
                              1,
                            ); // Navigate to Art Feed tab (index 1)
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: post.imageUrls.isNotEmpty
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        post.imageUrls.first,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.image,
                                                    color: Colors.grey,
                                                    size: 40,
                                                  ),
                                                ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(
                                                alpha: 0.7,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 12,
                                        left: 12,
                                        right: 12,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              post.content.length > 30
                                                  ? '${post.content.substring(0, 30)}...'
                                                  : post.content,
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
                                                    post.userName,
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.favorite,
                                                      color: Colors.red,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${post.applauseCount}',
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
                                  )
                                : Container(
                                    color: ArtbeatColors.primaryPurple
                                        .withValues(alpha: 0.1),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post.content.length > 50
                                                ? '${post.content.substring(0, 50)}...'
                                                : post.content,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              height: 1.4,
                                              color: ArtbeatColors.textPrimary,
                                            ),
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  post.userName,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: ArtbeatColors
                                                        .textSecondary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.favorite,
                                                    color: ArtbeatColors
                                                        .primaryPurple,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${post.applauseCount}',
                                                    style: const TextStyle(
                                                      color: ArtbeatColors
                                                          .primaryPurple,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
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

  Widget _buildArtistsSection({
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
                    color: ArtbeatColors.textPrimary,
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
                  Container(
                    decoration: BoxDecoration(
                      gradient: CommunityColors.communityGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
                          color: ArtbeatColors.textSecondary,
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
                            final userId = artist['userId'] as String?;
                            if (userId != null && userId.isNotEmpty) {
                              Navigator.pushNamed(
                                context,
                                '/artist/feed',
                                arguments: {
                                  'artistUserId': userId,
                                  'displayName':
                                      artist['name'] ?? 'Unknown Artist',
                                  'profileImageUrl': artist['avatar'],
                                },
                              );
                            } else {
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
                                    color: ArtbeatColors.textPrimary,
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
                                      color: ArtbeatColors.textSecondary,
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import '../../models/post_model.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/applause_button.dart';
import '../gifts/gifts_screen.dart';
import '../portfolios/portfolios_screen.dart';
import '../studios/studios_screen.dart';
import '../commissions/commissions_screen.dart';
import '../sponsorships/sponsorship_screen.dart';

/// Tab configuration for the community navigation
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
  // Social feed specific state
  final _posts = <PostModel>[];
  final _artworkService = ArtworkService();
  final _artworks = <ArtworkModel>[];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  late final List<CommunityTab> _tabs;

  @override
  void initState() {
    super.initState();
    _initializeTabs();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadFeedData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeTabs() {
    _tabs = [
      CommunityTab(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Canvas',
        screen: _buildFeedContent(),
      ),
      CommunityTab(
        icon: Icons.card_giftcard_outlined,
        selectedIcon: Icons.card_giftcard,
        label: 'Gifts',
        screen: const GiftsScreen(),
      ),
      CommunityTab(
        icon: Icons.palette_outlined,
        selectedIcon: Icons.palette,
        label: 'Portfolio',
        screen: const PortfoliosScreen(),
      ),
      CommunityTab(
        icon: Icons.forum_outlined,
        selectedIcon: Icons.forum,
        label: 'Studios',
        screen: const StudiosScreen(),
      ),
      CommunityTab(
        icon: Icons.work_outline,
        selectedIcon: Icons.work,
        label: 'Commissions',
        screen: const CommissionsScreen(),
      ),
      CommunityTab(
        icon: Icons.volunteer_activism_outlined,
        selectedIcon: Icons.volunteer_activism,
        label: 'Sponsors',
        screen: const SponsorshipScreen(),
      ),
    ];
  }

  // Remove duplicate dispose and unused page controller

  Future<void> _loadFeedData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      // Load posts and artworks in parallel
      await Future.wait([
        _loadPosts(),
        _loadArtworks(),
      ]);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load feed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPosts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final posts = snapshot.docs
          .map((doc) {
            try {
              return PostModel.fromFirestore(doc);
            } catch (e, stackTrace) {
              debugPrint('Error parsing post ${doc.id}: $e\n$stackTrace');
              return null;
            }
          })
          .whereType<PostModel>()
          .toList();

      if (mounted) {
        setState(() {
          _posts.clear();
          _posts.addAll(posts);
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading posts: $e\n$stackTrace');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load posts. Please try again.';
        });
      }
    }
  }

  Future<void> _loadArtworks() async {
    try {
      // Use ArtworkService to load featured public artworks
      final artworks = await _artworkService.getFeaturedArtwork();

      if (mounted) {
        setState(() {
          _artworks.clear();
          _artworks.addAll(artworks);
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading artworks: $e\n$stackTrace');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load artworks. Please try again.';
        });
      }
    }
  }

  void _navigateToComments(String postId) async {
    // TODO: Implement with proper navigation service
    debugPrint('Navigate to comments for post: $postId');
  }

  Future<void> _sharePost(String postId) async {
    // TODO: Implement with share_plus package
    debugPrint('Share post: $postId');
  }

  Widget _buildFeedContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage ?? 'An error occurred',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFeedData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF8C52FF),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty && _artworks.isEmpty) {
      return const Center(
        child: Text(
          'No content to show yet',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeedData,
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 80,
          left: 8,
          right: 8,
        ),
        itemCount: _posts.length + _artworks.length,
        itemBuilder: (context, index) {
          // Alternate between posts and artworks
          if (index % 2 == 0 && index ~/ 2 < _posts.length) {
            return _buildPostCard(_posts[index ~/ 2]);
          } else if ((index - 1) ~/ 2 < _artworks.length) {
            return _buildArtworkCard(_artworks[(index - 1) ~/ 2]);
          }
          return null;
        },
      ),
    );
  }

  Widget _buildImageWidget(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
        ),
      );
    }

    return Image.network(
      imageUrl,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox(
          height: 200,
          child: Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: AvatarWidget(avatarUrl: post.userPhotoUrl),
            title: Text(post.userName),
            subtitle: Text(post.location),
            trailing: Text(
              _formatTimestamp(post.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(post.content),
            ),
          if (post.imageUrls.isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: post.imageUrls.length,
                itemBuilder: (context, index) =>
                    _buildImageWidget(post.imageUrls[index]),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ApplauseButton(
                  postId: post.id,
                  userId: post.userId,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.comment),
                  label: Text('${post.commentCount}'),
                  onPressed: () => _navigateToComments(post.id),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.share),
                  label: Text('${post.shareCount}'),
                  onPressed: () => _sharePost(post.id),
                ),
              ],
            ),
          ),
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                children: post.tags
                    .map((tag) => Chip(
                          label: Text('#$tag'),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Helper method to format Timestamps
  String _formatTimestamp(dynamic timestamp) {
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Invalid date';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildArtworkCard(ArtworkModel artwork) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageWidget(artwork.imageUrl),
          ListTile(
            title: Text(artwork.title),
            subtitle: Text(artwork.medium),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    artwork.location ?? 'No location',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  _formatTimestamp(artwork.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8C52FF), // Purple
            Color(0xFF00BF63), // Green
          ],
        ),
      ),
      child: Column(
        children: [
          _buildTopMenu(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) => tab.screen).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMenu() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(top: topPadding),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Community header with filter
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                      'Community',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onPressed: () {
                    // TODO: Implement filtering
                  },
                ),
              ],
            ),
          ),
          // Scrolling tabs bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (int i = 0; i < _tabs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildTab(i),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index) {
    final isSelected = _tabController.index == index;
    final tab = _tabs[index];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _tabController.animateTo(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? tab.selectedIcon : tab.icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                tab.label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

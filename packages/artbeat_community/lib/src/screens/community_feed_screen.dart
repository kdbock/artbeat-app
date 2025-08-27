import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_ads/artbeat_ads.dart';

class CommunityFeedScreen extends StatefulWidget {
  final String? scrollToPostId;

  const CommunityFeedScreen({super.key, this.scrollToPostId});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final CommunityService _communityService = CommunityService();
  final ScrollController _scrollController = ScrollController();

  List<PostModel> _posts = [];
  List<BaseGroupPost> _groupPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we need to scroll to a specific post after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollToPostId != null && !_isLoading) {
        _scrollToPost(widget.scrollToPostId!);
      }
    });
  }

  Future<void> _loadPosts() async {
    try {
      setState(() => _isLoading = true);

      final results = await Future.wait([
        _communityService.getPosts(limit: 20),
        _loadGroupPosts(limit: 20),
      ]);

      if (mounted) {
        setState(() {
          _posts = results[0] as List<PostModel>;
          _groupPosts = results[1] as List<BaseGroupPost>;
          _isLoading = false;
        });

        // Scroll to specific post if requested
        if (widget.scrollToPostId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToPost(widget.scrollToPostId!);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading posts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToPost(String postId) {
    // Find the index of the post
    int targetIndex = -1;

    // Check regular posts first
    for (int i = 0; i < _posts.length; i++) {
      if (_posts[i].id == postId) {
        targetIndex = i;
        break;
      }
    }

    // If not found in regular posts, check group posts
    if (targetIndex == -1) {
      for (int i = 0; i < _groupPosts.length; i++) {
        if (_groupPosts[i].id == postId) {
          targetIndex = _posts.length + i;
          break;
        }
      }
    }

    // Scroll to the post if found
    if (targetIndex != -1) {
      const itemHeight = 200.0; // Approximate height of each post card
      final scrollOffset = targetIndex * itemHeight;

      _scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      // Optional: Show a brief highlight or snackbar to indicate the target post
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Found your post!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  Future<List<BaseGroupPost>> _loadGroupPosts({int limit = 20}) async {
    try {
      // Implementation similar to dashboard
      return [];
    } catch (e) {
      debugPrint('Error loading group posts: $e');
      return [];
    }
  }

  /// Calculate total items including ads
  /// Ads are placed starting after 5 posts, then every 5 posts
  int _getTotalItemsWithAds() {
    final totalPosts = _posts.length + _groupPosts.length;
    if (totalPosts <= 5) return totalPosts;

    // After first 5 posts, add 1 ad for every 5 posts
    final postsAfterFirst5 = totalPosts - 5;
    final additionalAds = (postsAfterFirst5 / 5).floor();
    return totalPosts + 1 + additionalAds; // +1 for the first ad after 5 posts
  }

  /// Check if the current index should show an ad
  bool _shouldShowAd(int index) {
    // First ad after 5 posts (index 5)
    if (index == 5) return true;

    // Subsequent ads every 6 items (5 posts + 1 ad)
    if (index > 5 && (index - 5) % 6 == 0) return true;

    return false;
  }

  /// Get the actual post index accounting for ads
  int _getPostIndex(int listIndex) {
    if (listIndex < 5) return listIndex;

    // After index 5, we need to account for ads
    final adsBeforeThisIndex = ((listIndex - 5) / 6).floor() + 1;
    return listIndex - adsBeforeThisIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CommunityHeader(
        title: 'Community Feed',
        showBackButton: true,
        showSearchIcon: true,
        showMessagingIcon: true,
        showDeveloperIcon: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPosts,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _posts.isEmpty && _groupPosts.isEmpty
              ? const Center(
                  child: Text(
                    'No posts available',
                    style: TextStyle(
                      fontSize: 16,
                      color: ArtbeatColors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _getTotalItemsWithAds(),
                  itemBuilder: (context, index) {
                    // Check if this position should show an ad
                    if (_shouldShowAd(index)) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: InFeedAdWidget(
                          analyticsLocation: 'community_feed_$index',
                        ),
                      );
                    }

                    // Get the actual post index
                    final postIndex = _getPostIndex(index);

                    if (postIndex < _posts.length) {
                      final post = _posts[postIndex];
                      return _buildPostCard(post, key: Key('post_${post.id}'));
                    } else {
                      final groupPostIndex = postIndex - _posts.length;
                      if (groupPostIndex < _groupPosts.length) {
                        final groupPost = _groupPosts[groupPostIndex];
                        return _buildGroupPostCard(
                          groupPost,
                          key: Key('group_post_${groupPost.id}'),
                        );
                      }
                    }

                    // Fallback - should not happen
                    return const SizedBox.shrink();
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildPostCard(PostModel post, {Key? key}) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPostDetail(post),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        post.userPhotoUrl.isNotEmpty &&
                            Uri.tryParse(post.userPhotoUrl)?.hasScheme == true
                        ? NetworkImage(post.userPhotoUrl)
                        : null,
                    child:
                        post.userPhotoUrl.isEmpty ||
                            Uri.tryParse(post.userPhotoUrl)?.hasScheme != true
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            if (post.isUserVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                size: 16,
                                color: ArtbeatColors.primaryPurple,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              _formatDate(post.createdAt),
                              style: const TextStyle(
                                color: ArtbeatColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            if (post.location.isNotEmpty) ...[
                              const Text(
                                ' • ',
                                style: TextStyle(
                                  color: ArtbeatColors.textSecondary,
                                ),
                              ),
                              const Icon(
                                Icons.location_on,
                                size: 12,
                                color: ArtbeatColors.textSecondary,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  post.location,
                                  style: const TextStyle(
                                    color: ArtbeatColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (post.content.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  post.content,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
              if (post.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrls.first,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 50),
                    ),
                  ),
                ),
              ],
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: post.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ArtbeatColors.primaryPurple.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              color: ArtbeatColors.primaryPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _handleLike(post),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: post.applauseCount > 0
                              ? Colors.red
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.applauseCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => _showPostDetail(post),
                    child: Row(
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.commentCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _handleFeature(post),
                    child: Icon(
                      Icons.star_outline,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _handleGift(post),
                    child: Icon(
                      Icons.card_giftcard,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _handleShare(post),
                    child: Icon(
                      Icons.share_outlined,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupPostCard(BaseGroupPost groupPost, {Key? key}) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showGroupPostDetail(groupPost),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'GROUP POST',
                      style: TextStyle(
                        color: ArtbeatColors.primaryPurple,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(groupPost.createdAt),
                    style: const TextStyle(
                      color: ArtbeatColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (groupPost.userPhotoUrl.isNotEmpty &&
                      Uri.tryParse(groupPost.userPhotoUrl)?.hasScheme == true)
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(groupPost.userPhotoUrl),
                    )
                  else
                    const CircleAvatar(
                      radius: 16,
                      child: Icon(Icons.person, size: 16),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupPost.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (groupPost.isUserVerified)
                          const Icon(
                            Icons.verified,
                            size: 12,
                            color: ArtbeatColors.primaryPurple,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                groupPost.content.length > 100
                    ? '${groupPost.content.substring(0, 100)}...'
                    : groupPost.content,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              if (groupPost is ArtistGroupPost &&
                  groupPost.artworkDescription.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  groupPost.artworkDescription.length > 50
                      ? '${groupPost.artworkDescription.substring(0, 50)}...'
                      : groupPost.artworkDescription,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ArtbeatColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (groupPost.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    groupPost.imageUrls.first,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 40),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _handleGroupLike(groupPost),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: groupPost.applauseCount > 0
                              ? Colors.red
                              : Colors.grey[600],
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${groupPost.applauseCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showGroupPostDetail(groupPost),
                    child: Row(
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          color: Colors.grey[600],
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${groupPost.commentCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _handleGroupFeature(groupPost),
                    child: Icon(
                      Icons.star_outline,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _handleGroupGift(groupPost),
                    child: Icon(
                      Icons.card_giftcard,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _handleGroupShare(groupPost),
                    child: Icon(
                      Icons.share_outlined,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostDetail(PostModel post) {
    PostDetailModal.showFromPostModel(context, post);
  }

  Future<void> _handleLike(PostModel post) async {
    try {
      // TODO: Implement actual like functionality in CommunityService
      // For now, just show a visual feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Like functionality coming soon!'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint('Error liking post: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error liking post: $e')));
      }
    }
  }

  void _handleShare(PostModel post) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _showGroupPostDetail(BaseGroupPost groupPost) {
    PostDetailModal.show(context, groupPost);
  }

  Future<void> _handleGroupLike(BaseGroupPost groupPost) async {
    try {
      // TODO: Implement actual group post like functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Like functionality coming soon!'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint('Error liking group post: $e');
    }
  }

  void _handleGroupShare(BaseGroupPost groupPost) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  Future<void> _handleFeature(PostModel post) async {
    try {
      // TODO: Implement actual feature functionality in CommunityService
      // For now, just show a visual feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post featured! 🌟'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error featuring post: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error featuring post: $e')));
      }
    }
  }

  Future<void> _handleGift(PostModel post) async {
    try {
      // TODO: Implement actual gift functionality in CommunityService
      // For now, show a gift dialog
      _showGiftDialog(post);
    } catch (e) {
      debugPrint('Error gifting post: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending gift: $e')));
      }
    }
  }

  Future<void> _handleGroupFeature(BaseGroupPost groupPost) async {
    try {
      // TODO: Implement actual group post feature functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group post featured! 🌟'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error featuring group post: $e');
    }
  }

  Future<void> _handleGroupGift(BaseGroupPost groupPost) async {
    try {
      // TODO: Implement actual group post gift functionality
      _showGroupGiftDialog(groupPost);
    } catch (e) {
      debugPrint('Error gifting group post: $e');
    }
  }

  void _showGiftDialog(PostModel post) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: Colors.orange),
            SizedBox(width: 8),
            Text('Send Gift'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send a gift to ${post.userName}?'),
            const SizedBox(height: 16),
            const Text(
              'Choose your gift:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            _buildGiftOption('Coffee', '☕', '\$3'),
            _buildGiftOption('Flower', '🌺', '\$5'),
            _buildGiftOption('Artwork Boost', '🎨', '\$10'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showGroupGiftDialog(BaseGroupPost groupPost) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: Colors.orange),
            SizedBox(width: 8),
            Text('Send Gift'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send a gift to ${groupPost.userName}?'),
            const SizedBox(height: 16),
            const Text(
              'Choose your gift:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            _buildGiftOption('Coffee', '☕', '\$3'),
            _buildGiftOption('Flower', '🌺', '\$5'),
            _buildGiftOption('Artwork Boost', '🎨', '\$10'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftOption(String name, String emoji, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name gift sent! $emoji'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(child: Text(name)),
              Text(
                price,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

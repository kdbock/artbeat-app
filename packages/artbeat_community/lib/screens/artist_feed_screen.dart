import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../services/art_community_service.dart';
import '../widgets/enhanced_post_card.dart';
import '../widgets/comments_modal.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:share_plus/share_plus.dart';

/// Screen showing all posts from a specific artist
class ArtistFeedScreen extends StatefulWidget {
  final String artistId;
  final String? artistName;

  const ArtistFeedScreen({super.key, required this.artistId, this.artistName});

  @override
  State<ArtistFeedScreen> createState() => _ArtistFeedScreenState();
}

class _ArtistFeedScreenState extends State<ArtistFeedScreen> {
  final ArtCommunityService _communityService = ArtCommunityService();
  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtistAndPosts();
  }

  @override
  void dispose() {
    _communityService.dispose();
    super.dispose();
  }

  Future<void> _loadArtistAndPosts() async {
    setState(() => _isLoading = true);

    try {
      AppLogger.info('🎨 Loading artist feed for: ${widget.artistId}');

      // Load all posts and filter by artist
      final allPosts = await _communityService.getFeed(limit: 100);
      final artistPosts = allPosts
          .where((post) => post.userId == widget.artistId)
          .toList();

      AppLogger.info('🎨 Found ${artistPosts.length} posts from this artist');

      if (mounted) {
        setState(() {
          _posts = artistPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('🎨 Error loading artist feed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading artist feed: $e')),
        );
      }
    }
  }

  void _handlePostTap(PostModel post) {
    // You can implement post detail view here
    AppLogger.info('Post tapped: ${post.id}');
  }

  void _handleLike(PostModel post) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to like posts')),
        );
        return;
      }

      final postIndex = _posts.indexWhere((p) => p.id == post.id);
      if (postIndex != -1) {
        setState(() {
          final currentLikeCount = _posts[postIndex].engagementStats.likeCount;
          final isCurrentlyLiked = _posts[postIndex].isLikedByCurrentUser;

          final newEngagementStats = EngagementStats(
            likeCount: isCurrentlyLiked
                ? currentLikeCount - 1
                : currentLikeCount + 1,
            commentCount: _posts[postIndex].engagementStats.commentCount,
            shareCount: _posts[postIndex].engagementStats.shareCount,
            lastUpdated: DateTime.now(),
          );

          _posts[postIndex] = _posts[postIndex].copyWith(
            isLikedByCurrentUser: !isCurrentlyLiked,
            engagementStats: newEngagementStats,
          );
        });
      }

      final success = await _communityService.toggleLike(post.id);
      if (!success && postIndex != -1) {
        // Revert on failure
        setState(() {
          final currentLikeCount = _posts[postIndex].engagementStats.likeCount;
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

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to update like')));
      }
    } catch (e) {
      AppLogger.error('Error handling like: $e');
    }
  }

  void _handleComment(PostModel post) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CommentsModal(post: post, communityService: _communityService),
    );
  }

  void _handleShare(PostModel post) async {
    try {
      String shareText = '';
      if (post.content.isNotEmpty) {
        shareText = '"${post.content}"\n\n';
      }
      shareText += 'Shared from ARTbeat Community\n';
      shareText += 'By ${post.userName}';

      if (post.location.isNotEmpty) {
        shareText += ' • ${post.location}';
      }

      if (post.tags.isNotEmpty) {
        shareText += '\n\n${post.tags.map((tag) => '#$tag').join(' ')}';
      }

      await SharePlus.instance.share(ShareParams(text: shareText));

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

        _communityService.incrementShareCount(post.id);
      }
    } catch (e) {
      AppLogger.error('Error sharing post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.artistName != null
              ? '${widget.artistName}\'s Posts'
              : 'Artist Feed',
        ),
        backgroundColor: ArtbeatColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  ArtbeatColors.primaryPurple,
                ),
              ),
            )
          : _posts.isEmpty
          ? Center(
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
                    'This artist hasn\'t shared any posts yet',
                    style: TextStyle(
                      color: ArtbeatColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadArtistAndPosts,
              color: ArtbeatColors.primaryPurple,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: EnhancedPostCard(
                      post: post,
                      onTap: () => _handlePostTap(post),
                      onLike: () => _handleLike(post),
                      onComment: () => _handleComment(post),
                      onShare: () => _handleShare(post),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

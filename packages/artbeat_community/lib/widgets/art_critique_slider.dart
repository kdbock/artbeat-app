import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/community_service.dart';
import '../theme/community_colors.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Horizontal scrolling slider displaying art awaiting critique
class ArtCritiqueSlider extends StatefulWidget {
  final VoidCallback? onViewAllPressed;
  final void Function(PostModel)? onPostSelected;

  const ArtCritiqueSlider({
    super.key,
    this.onViewAllPressed,
    this.onPostSelected,
  });

  @override
  State<ArtCritiqueSlider> createState() => _ArtCritiqueSliderState();
}

class _ArtCritiqueSliderState extends State<ArtCritiqueSlider> {
  final CommunityService _communityService = CommunityService();
  List<PostModel> _artPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtPosts();
  }

  Future<void> _loadArtPosts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load posts with images for critique
      final posts = await _communityService.getPosts(limit: 20);

      // Filter to only include posts with images
      final artPosts = posts
          .where((post) => post.imageUrls.isNotEmpty)
          .toList();

      setState(() {
        _artPosts = artPosts;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading art posts for critique: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Art to Critique',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.primary,
                ),
              ),
              if (widget.onViewAllPressed != null)
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
                    onPressed: widget.onViewAllPressed,
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

        // Scrollable art slider
        SizedBox(
          height: 200,
          child: _isLoading
              ? _buildLoadingSlider()
              : _artPosts.isEmpty
              ? _buildEmptyState()
              : _buildArtSlider(),
        ),
      ],
    );
  }

  Widget _buildLoadingSlider() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: 3, // Show 3 loading placeholders
      itemBuilder: (context, index) {
        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Expanded(child: Center(child: CircularProgressIndicator())),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Loading...'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.palette_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'No art awaiting critique',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Check back later for new submissions',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildArtSlider() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _artPosts.length,
      itemBuilder: (context, index) {
        final post = _artPosts[index];
        return _buildArtCard(post);
      },
    );
  }

  Widget _buildArtCard(PostModel post) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => widget.onPostSelected?.call(post),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image section
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: post.imageUrls.isNotEmpty
                      ? ImageManagementService().getOptimizedImage(
                          imageUrl: post.imageUrls.first,
                          fit: BoxFit.cover,
                          isThumbnail: true,
                          errorWidget: Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 32,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
                ),
              ),

              // Content section
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.content.isNotEmpty
                          ? post.content
                          : 'Untitled artwork',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '@${post.authorUsername}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${post.commentCount}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
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
          ),
        ),
      ),
    );
  }
}

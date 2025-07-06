import 'package:flutter/material.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_core/artbeat_core.dart'
    show ArtistProfileModel, UserAvatar, UniversalHeader, MainLayout;
import 'package:share_plus/share_plus.dart';

/// Screen for viewing artwork details
class ArtworkDetailScreen extends StatefulWidget {
  final String artworkId;

  const ArtworkDetailScreen({
    super.key,
    required this.artworkId,
  });

  @override
  State<ArtworkDetailScreen> createState() => _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends State<ArtworkDetailScreen> {
  final ArtworkService _artworkService = ArtworkService();
  final artist.SubscriptionService _subscriptionService =
      artist.SubscriptionService();
  final artist.AnalyticsService _analyticsService = artist.AnalyticsService();

  bool _isLoading = true;
  ArtworkModel? _artwork;
  ArtistProfileModel? _artist;
  bool _hasLiked = false;

  @override
  void initState() {
    super.initState();
    _loadArtworkData();
  }

  Future<void> _loadArtworkData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get artwork details
      final artwork = await _artworkService.getArtworkById(widget.artworkId);

      // Track artwork view for analytics if artwork exists
      if (artwork != null) {
        _analyticsService.trackArtworkView(
          artworkId: widget.artworkId,
          artistId: artwork.userId,
        );
      }

      if (artwork == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Artwork not found')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Get artist profile
      final artistProfile = await _subscriptionService
          .getArtistProfileById(artwork.artistProfileId);

      // Check if user has liked this artwork
      final hasLiked = await _artworkService.hasLiked(widget.artworkId);

      // Increment view count
      await _artworkService.incrementViewCount(widget.artworkId);

      if (mounted) {
        setState(() {
          _artwork = artwork;
          _artist = artistProfile;
          _hasLiked = hasLiked;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading artwork: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_artwork == null) return;

    try {
      final result = await _artworkService.toggleLike(widget.artworkId);

      if (mounted) {
        setState(() {
          _hasLiked = result;
          if (result) {
            _artwork = _artwork!.copyWith(likeCount: _artwork!.likeCount + 1);
          } else {
            _artwork = _artwork!.copyWith(likeCount: _artwork!.likeCount - 1);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _shareArtwork() {
    if (_artwork == null) return;

    final String artistName = _artist?.displayName ?? 'Artist';
    final String title = _artwork!.title;
    final String message = 'Check out "$title" by $artistName on WordNerd!';

    // In a real app, you would generate a dynamic link here
    SharePlus.instance.share(ShareParams(text: message));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MainLayout(
        currentIndex: -1, // No navigation highlight for detail screens
        child: Scaffold(
          appBar: UniversalHeader(
            title: 'Artwork',
            showLogo: false,
          ),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final artwork = _artwork!;
    final artistProfile = _artist;

    return MainLayout(
      currentIndex: -1, // No navigation highlight for detail screens
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // App bar with artwork image
            SliverAppBar(
              expandedHeight: 400.0,
              floating: false,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon:
                      Icon(_hasLiked ? Icons.favorite : Icons.favorite_border),
                  color: _hasLiked ? Colors.red : null,
                  onPressed: _toggleLike,
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareArtwork,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Image.network(
                  artwork.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Artwork details
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                artwork.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              if (artwork.yearCreated != null)
                                Text(
                                  '${artwork.yearCreated}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (artwork.isForSale)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '\$${artwork.price?.toStringAsFixed(2) ?? 'For Sale'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Artist info
                    if (artistProfile != null)
                      InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/artist/public-profile',
                            arguments: {'artistProfileId': artistProfile.id},
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              UserAvatar(
                                imageUrl: artistProfile.profileImageUrl,
                                displayName: artistProfile.displayName,
                                radius: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'By ${artistProfile.displayName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (artistProfile.location != null &&
                                        artistProfile.location!.isNotEmpty)
                                      Text(
                                        artistProfile.location!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),

                    // Divider
                    const Divider(height: 32),

                    // Details section
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    // Artwork properties
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: _buildPropertyRow('Medium', artwork.medium),
                    ),
                    if (artwork.dimensions != null)
                      _buildPropertyRow('Dimensions', artwork.dimensions!),
                    _buildPropertyRow('Style', artwork.styles.join(', ')),

                    // Divider
                    const Divider(height: 32),

                    // Description section
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        artwork.description,
                        style: const TextStyle(height: 1.5),
                      ),
                    ),

                    // Tags
                    if (artwork.tags?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: artwork.tags!
                            .map((tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor: Theme.of(context)
                                      .chipTheme
                                      .backgroundColor,
                                ))
                            .toList(),
                      ),
                    ],

                    // Engagement stats
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                            Icons.favorite, '${artwork.likeCount}', 'Likes'),
                        _buildStatItem(
                            Icons.visibility, '${artwork.viewCount}', 'Views'),
                        _buildStatItem(Icons.comment, '${artwork.commentCount}',
                            'Comments'),
                      ],
                    ),

                    // Action buttons
                    const SizedBox(height: 32),
                    if (artwork.isForSale)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // In a real app, this would navigate to purchase or inquiry page
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Purchase feature coming soon')),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Purchase'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String count, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

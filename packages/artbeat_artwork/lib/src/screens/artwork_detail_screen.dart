import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_core/artbeat_core.dart' hide ArtworkModel;
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  ArtworkModel? _artwork;
  ArtistProfileModel? _artist;
  bool _isOwner = false;

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

      // Check if user is the owner of this artwork

      // Check if current user is the owner of this artwork
      final currentUser = _auth.currentUser;
      final isOwner = currentUser != null && currentUser.uid == artwork.userId;

      // Increment view count
      await _artworkService.incrementViewCount(widget.artworkId);

      if (mounted) {
        setState(() {
          _artwork = artwork;
          _artist = artistProfile;
          _isOwner = isOwner;
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

  void _shareArtwork() {
    if (_artwork == null) return;

    final String artistName = _artist?.displayName ?? 'Artist';
    final String title = _artwork!.title;
    final String message = 'Check out "$title" by $artistName on WordNerd!';

    // In a real app, you would generate a dynamic link here
    SharePlus.instance.share(ShareParams(text: message));
  }

  void _editArtwork() {
    if (_artwork == null) return;

    Navigator.pushNamed(
      context,
      '/artwork/edit',
      arguments: {
        'artworkId': _artwork!.id,
        'artwork': _artwork,
      },
    ).then((_) {
      // Refresh artwork data when returning from edit
      _loadArtworkData();
    });
  }

  Future<void> _showDeleteConfirmation() async {
    if (_artwork == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Artwork'),
        content: Text(
          'Are you sure you want to delete "${_artwork!.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteArtwork();
    }
  }

  Future<void> _deleteArtwork() async {
    if (_artwork == null) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Deleting artwork...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      await _artworkService.deleteArtwork(_artwork!.id);

      if (mounted) {
        // Hide loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_artwork!.title}" has been deleted successfully'),
            backgroundColor: ArtbeatColors.primaryGreen,
          ),
        );

        // Navigate back to the previous screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        // Hide loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete artwork: $e'),
            backgroundColor: ArtbeatColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MainLayout(
        currentIndex: -1, // No navigation highlight for detail screens
        child: Scaffold(
          appBar: EnhancedUniversalHeader(
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
                  icon: const Icon(Icons.share),
                  onPressed: _shareArtwork,
                ),
                if (_isOwner) ...[
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editArtwork();
                      } else if (value == 'delete') {
                        _showDeleteConfirmation();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: SecureNetworkImage(
                  imageUrl: artwork.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
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
                            arguments: {'artistId': artistProfile.id},
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

                    // Content engagement bar
                    const SizedBox(height: 24),
                    ContentEngagementBar(
                      contentId: artwork.id,
                      contentType: 'artwork',
                      initialStats: artwork.engagementStats,
                      showSecondaryActions: true,
                    ),

                    // View count (separate from engagement)
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.visibility,
                            size: 16, color: ArtbeatColors.darkGray),
                        const SizedBox(width: 4),
                        Text(
                          '${artwork.viewCount} views',
                          style: const TextStyle(
                            color: ArtbeatColors.darkGray,
                            fontSize: 14,
                          ),
                        ),
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
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../services/subscription_service.dart' as artist_service;

/// Screen for viewing and managing the current user's artwork
class MyArtworkScreen extends StatefulWidget {
  const MyArtworkScreen({super.key});

  @override
  State<MyArtworkScreen> createState() => _MyArtworkScreenState();
}

class _MyArtworkScreenState extends State<MyArtworkScreen> {
  final _subscriptionService = artist_service.SubscriptionService();
  final _artworkService = ArtworkService();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  List<ArtworkModel> _artworks = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMyArtwork();
  }

  Future<void> _loadMyArtwork() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'Please log in to view your artwork';
          _isLoading = false;
        });
        return;
      }

      // Get the current user's artist profile
      final artistProfile =
          await _subscriptionService.getCurrentArtistProfile();
      if (artistProfile == null) {
        setState(() {
          _error =
              'No artist profile found. Please create an artist profile first.';
          _isLoading = false;
        });
        return;
      }

      // Get the user's artwork
      final artworks =
          await _artworkService.getArtworkByArtistProfileId(artistProfile.id);

      if (mounted) {
        setState(() {
          _artworks = artworks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading artwork: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshArtwork() async {
    await _loadMyArtwork();
  }

  void _navigateToArtworkDetail(ArtworkModel artwork) {
    Navigator.pushNamed(
      context,
      '/artist/artwork-detail',
      arguments: {'artworkId': artwork.id},
    );
  }

  void _navigateToUpload() {
    Navigator.pushNamed(context, '/artwork/upload');
  }

  void _navigateToEdit(ArtworkModel artwork) {
    Navigator.pushNamed(
      context,
      '/artwork/edit',
      arguments: {
        'artworkId': artwork.id,
        'artwork': artwork,
      },
    ).then((_) {
      // Refresh the artwork list when returning from edit
      _refreshArtwork();
    });
  }

  Future<void> _showDeleteConfirmation(ArtworkModel artwork) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Artwork'),
        content: Text(
          'Are you sure you want to delete "${artwork.title}"? This action cannot be undone.',
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
      await _deleteArtwork(artwork);
    }
  }

  Future<void> _deleteArtwork(ArtworkModel artwork) async {
    try {
      // Show loading indicator
      if (mounted) {
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
            duration: Duration(seconds: 30), // Long duration for deletion
          ),
        );
      }

      await _artworkService.deleteArtwork(artwork.id);

      if (mounted) {
        // Hide loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${artwork.title}" has been deleted successfully'),
            backgroundColor: core.ArtbeatColors.primaryGreen,
          ),
        );

        // Refresh the artwork list
        await _refreshArtwork();
      }
    } catch (e) {
      if (mounted) {
        // Hide loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete artwork: $e'),
            backgroundColor: core.ArtbeatColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const core.EnhancedUniversalHeader(
        title: 'My Artwork',
        showLogo: false,
        showSearch: false,
        showDeveloperTools: false,
        backgroundColor: Colors.transparent,
        foregroundColor: core.ArtbeatColors.textPrimary,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToUpload,
        backgroundColor: core.ArtbeatColors.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: core.ArtbeatColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshArtwork,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_artworks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.palette_outlined,
              size: 64,
              color: core.ArtbeatColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Artwork Yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload your first artwork to get started!',
              style: TextStyle(color: core.ArtbeatColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToUpload,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Upload Artwork'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshArtwork,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_artworks.length} ${_artworks.length == 1 ? 'Artwork' : 'Artworks'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: _navigateToUpload,
                    icon: const Icon(Icons.add),
                    label: const Text('Upload'),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final artwork = _artworks[index];
                  return _buildArtworkCard(artwork);
                },
                childCount: _artworks.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80), // Space for FAB
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkCard(ArtworkModel artwork) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: () => _navigateToArtworkDetail(artwork),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Artwork image
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: artwork.imageUrl.isNotEmpty
                        ? Image.network(
                            artwork.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                // Artwork details
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artwork.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (artwork.medium.isNotEmpty)
                        Text(
                          artwork.medium,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: core.ArtbeatColors.textSecondary,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      if (artwork.price != null)
                        Text(
                          '\$${artwork.price!.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: core.ArtbeatColors.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Edit/Delete menu button
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 20,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _navigateToEdit(artwork);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(artwork);
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
            ),
          ),
        ],
      ),
    );
  }
}

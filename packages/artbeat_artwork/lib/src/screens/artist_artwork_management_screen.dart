import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../models/artwork_model.dart';
import '../services/artwork_service.dart';
import '../widgets/artwork_grid_widget.dart';

/// Consolidated screen for artists to manage their artwork
/// Replaces the duplicate MyArtworkScreen from artbeat_artist
class ArtistArtworkManagementScreen extends StatefulWidget {
  const ArtistArtworkManagementScreen({super.key});

  @override
  State<ArtistArtworkManagementScreen> createState() =>
      _ArtistArtworkManagementScreenState();
}

class _ArtistArtworkManagementScreenState
    extends State<ArtistArtworkManagementScreen> {
  final _artworkService = ArtworkService();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  List<ArtworkModel> _artworks = [];
  String? _error;
  String? _artistProfileId;

  @override
  void initState() {
    super.initState();
    _loadArtistArtwork();
  }

  Future<void> _loadArtistArtwork() async {
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

      // Get artist profile ID - this would come from artbeat_artist package
      // For now, using userId as artistProfileId
      _artistProfileId = currentUser.uid;

      // Get the user's artwork
      final artworks =
          await _artworkService.getArtworkByArtistProfileId(_artistProfileId!);

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
    await _loadArtistArtwork();
  }

  void _navigateToUpload() {
    Navigator.pushNamed(context, '/artwork/upload').then((_) {
      // Refresh artwork list after upload
      _refreshArtwork();
    });
  }

  void _navigateToArtworkDetail(ArtworkModel artwork) {
    Navigator.pushNamed(
      context,
      '/artwork/detail',
      arguments: {'artworkId': artwork.id},
    );
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

  Future<void> _deleteArtwork(ArtworkModel artwork) async {
    try {
      await _artworkService.deleteArtwork(artwork.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${artwork.title}" has been deleted successfully'),
            backgroundColor: core.ArtbeatColors.primaryGreen,
          ),
        );
        await _refreshArtwork();
      }
    } catch (e) {
      if (mounted) {
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
    return core.MainLayout(
      currentIndex:
          -1, // Artist artwork management doesn't use bottom navigation
      appBar: core.EnhancedUniversalHeader(
        title: 'My Artwork',
        showBackButton: true,
        showSearch: false,
        actions: [
          IconButton(
            onPressed: _navigateToUpload,
            icon: const Icon(Icons.add),
            tooltip: 'Upload Artwork',
          ),
        ],
      ),
      child: _buildBody(),
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

    return Column(
      children: [
        // Header with artwork count and upload button
        Padding(
          padding: const EdgeInsets.all(16),
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

        // Artwork grid using shared component
        Expanded(
          child: ArtworkGridWidget(
            artworks: _artworks,
            onArtworkTap: _navigateToArtworkDetail,
            onArtworkEdit: _navigateToEdit,
            onArtworkDelete: _deleteArtwork,
            onRefresh: _refreshArtwork,
            showManagementActions:
                true, // Show edit/delete for artist's own artwork
          ),
        ),
      ],
    );
  }
}

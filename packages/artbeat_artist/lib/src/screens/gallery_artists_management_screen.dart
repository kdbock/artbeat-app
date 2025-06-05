import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:flutter/material.dart';

class GalleryArtistsManagementScreen extends StatefulWidget {
  const GalleryArtistsManagementScreen({super.key});

  @override
  State<GalleryArtistsManagementScreen> createState() =>
      _GalleryArtistsManagementScreenState();
}

class _GalleryArtistsManagementScreenState
    extends State<GalleryArtistsManagementScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  List<core.ArtistProfileModel> _galleryArtists = [];
  Map<String, core.ArtistProfileModel> _artistProfiles = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGalleryArtists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGalleryArtists() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // TODO: Load gallery artists from Firestore
      final List<String> artistList = []; // Replace with actual artist IDs
      final Map<String, core.ArtistProfileModel> artistProfiles =
          {}; // Replace with actual profiles

      setState(() {
        _artistProfiles = artistProfiles;
        _galleryArtists = artistList
            .map((id) => _artistProfiles[id])
            .whereType<core.ArtistProfileModel>()
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load gallery artists. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _addArtistToGallery(core.ArtistProfileModel artist) async {
    try {
      // TODO: Implement adding artist to gallery
      setState(() {
        _galleryArtists = [..._galleryArtists, artist];
        _artistProfiles[artist.id] = artist;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add artist to gallery')),
        );
      }
    }
  }

  Future<void> _removeArtistFromGallery(String artistId) async {
    try {
      // TODO: Implement removing artist from gallery
      setState(() {
        _galleryArtists.removeWhere((artist) => artist.id == artistId);
        _artistProfiles.remove(artistId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove artist from gallery')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery Artists'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current Artists'),
            Tab(text: 'Pending Invitations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildArtistsList(),
          _buildPendingInvitations(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showDialog<core.ArtistProfileModel>(
            context: context,
            builder: (context) => _ArtistSearchDialog(
              currentArtists: _galleryArtists.map((a) => a.id).toList(),
              onArtistSelected: (artist) => Navigator.pop(context, artist),
            ),
          );

          if (result != null) {
            await _addArtistToGallery(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildArtistsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    return ListView.builder(
      itemCount: _galleryArtists.length,
      itemBuilder: (context, index) {
        final artist = _galleryArtists[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: artist.profileImageUrl != null
                ? NetworkImage(artist.profileImageUrl!)
                : null,
            child: artist.profileImageUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(artist.displayName),
          subtitle: Text(artist.bio ?? ''),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => _removeArtistFromGallery(artist.id),
          ),
        );
      },
    );
  }

  Widget _buildPendingInvitations() {
    // TODO: Implement pending invitations list
    return const Center(
      child: Text('Pending invitations coming soon'),
    );
  }
}

/// Dialog for searching and selecting artists to add to gallery
class _ArtistSearchDialog extends StatefulWidget {
  final List<String> currentArtists;
  final Function(core.ArtistProfileModel) onArtistSelected;

  const _ArtistSearchDialog({
    required this.currentArtists,
    required this.onArtistSelected,
  });

  @override
  State<_ArtistSearchDialog> createState() => _ArtistSearchDialogState();
}

class _ArtistSearchDialogState extends State<_ArtistSearchDialog> {
  final TextEditingController _searchController = TextEditingController();

  List<core.ArtistProfileModel> _searchResults = [];
  bool _isLoading = false;

  @override
  dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Search for artists
  Future<void> _searchArtists(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement artist search using core.ArtistProfileModel
      final results = <core.ArtistProfileModel>[];

      setState(() {
        // Filter out artists already in the gallery
        _searchResults = results
            .where((artist) => !widget.currentArtists.contains(artist.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Find Artists',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or location',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchArtists,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Type to search for artists'
                                : 'No artists found',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final artist = _searchResults[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              leading: CircleAvatar(
                                backgroundImage: artist.profileImageUrl != null
                                    ? NetworkImage(artist.profileImageUrl!)
                                    : null,
                                child: artist.profileImageUrl == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(artist.displayName),
                              subtitle: Text(
                                artist.location ?? 'No location',
                              ),
                              onTap: () {
                                widget.onArtistSelected(artist);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

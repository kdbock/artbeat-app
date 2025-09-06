import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artwork_model.dart';
import '../services/artwork_service.dart';

/// Admin screen for moderating artwork content
class ArtworkModerationScreen extends StatefulWidget {
  const ArtworkModerationScreen({super.key});

  @override
  State<ArtworkModerationScreen> createState() =>
      _ArtworkModerationScreenState();
}

class _ArtworkModerationScreenState extends State<ArtworkModerationScreen> {
  final ArtworkService _artworkService = ArtworkService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedFilter = 'pending';
  bool _isLoading = false;
  List<ArtworkModel> _artworks = [];
  final Map<String, bool> _selectedArtworks = {};

  @override
  void initState() {
    super.initState();
    _loadArtworks();
  }

  Future<void> _loadArtworks() async {
    setState(() => _isLoading = true);

    try {
      Query query = _firestore.collection('artworks');

      // Apply filter
      switch (_selectedFilter) {
        case 'pending':
          query = query.where('moderationStatus', isEqualTo: 'pending');
          break;
        case 'flagged':
          query = query.where('flagged', isEqualTo: true);
          break;
        case 'approved':
          query = query.where('moderationStatus', isEqualTo: 'approved');
          break;
        case 'rejected':
          query = query.where('moderationStatus', isEqualTo: 'rejected');
          break;
        case 'all':
          // No filter
          break;
      }

      query = query.orderBy('createdAt', descending: true).limit(50);

      final snapshot = await query.get();
      final artworks =
          snapshot.docs.map((doc) => ArtworkModel.fromFirestore(doc)).toList();

      setState(() {
        _artworks = artworks;
        _selectedArtworks.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading artworks: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _moderateArtwork(
      ArtworkModel artwork, ArtworkModerationStatus status,
      {String? notes}) async {
    try {
      await _artworkService.updateArtworkModeration(
        artworkId: artwork.id,
        status: status,
        notes: notes,
      );

      setState(() {
        _artworks.removeWhere((a) => a.id == artwork.id);
        _selectedArtworks.remove(artwork.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Artwork ${status.displayName.toLowerCase()}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moderating artwork: $e')),
      );
    }
  }

  Future<void> _bulkModerate(ArtworkModerationStatus status,
      {String? notes}) async {
    final selectedIds = _selectedArtworks.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      for (final artworkId in selectedIds) {
        await _artworkService.updateArtworkModeration(
          artworkId: artworkId,
          status: status,
          notes: notes,
        );
      }

      setState(() {
        _artworks.removeWhere((artwork) => selectedIds.contains(artwork.id));
        _selectedArtworks.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${selectedIds.length} artworks ${status.displayName.toLowerCase()}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error in bulk moderation: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showModerationDialog(ArtworkModel artwork) {
    final notesController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Moderate "${artwork.title}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose moderation action:'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Moderation Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _moderateArtwork(artwork, ArtworkModerationStatus.approved,
                  notes: notesController.text);
            },
            child: const Text('Approve'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _moderateArtwork(artwork, ArtworkModerationStatus.rejected,
                  notes: notesController.text);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showBulkModerationDialog() {
    final notesController = TextEditingController();
    final selectedCount =
        _selectedArtworks.values.where((selected) => selected).length;

    if (selectedCount == 0) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk Moderate $selectedCount Artworks'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Apply action to all selected artworks:'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Moderation Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _bulkModerate(ArtworkModerationStatus.approved,
                  notes: notesController.text);
            },
            child: const Text('Approve All'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _bulkModerate(ArtworkModerationStatus.rejected,
                  notes: notesController.text);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount =
        _selectedArtworks.values.where((selected) => selected).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artwork Moderation'),
        actions: [
          if (selectedCount > 0) ...[
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: _showBulkModerationDialog,
              tooltip: 'Bulk Approve',
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => _bulkModerate(ArtworkModerationStatus.rejected),
              tooltip: 'Bulk Reject',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                label: Text('$selectedCount selected'),
                backgroundColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Pending'),
                    selected: _selectedFilter == 'pending',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = 'pending');
                        _loadArtworks();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Flagged'),
                    selected: _selectedFilter == 'flagged',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = 'flagged');
                        _loadArtworks();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Approved'),
                    selected: _selectedFilter == 'approved',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = 'approved');
                        _loadArtworks();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Rejected'),
                    selected: _selectedFilter == 'rejected',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = 'rejected');
                        _loadArtworks();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedFilter == 'all',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = 'all');
                        _loadArtworks();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _artworks.isEmpty
                    ? const Center(
                        child: Text('No artworks to moderate'),
                      )
                    : ListView.builder(
                        itemCount: _artworks.length,
                        itemBuilder: (context, index) {
                          final artwork = _artworks[index];
                          final isSelected =
                              _selectedArtworks[artwork.id] ?? false;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              children: [
                                // Selection checkbox
                                CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedArtworks[artwork.id] =
                                          value ?? false;
                                    });
                                  },
                                  title: Text(
                                    artwork.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle:
                                      Text('by ${artwork.artistProfileId}'),
                                ),

                                // Artwork image
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(artwork.imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                                // Artwork details
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        artwork.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Chip(
                                            label: Text(artwork.medium),
                                            backgroundColor: Colors.blue
                                                .withValues(alpha: 0.1),
                                          ),
                                          const SizedBox(width: 8),
                                          Chip(
                                            label: Text(artwork
                                                .moderationStatus.displayName),
                                            backgroundColor: _getStatusColor(
                                                artwork.moderationStatus),
                                          ),
                                        ],
                                      ),
                                      if (artwork.flagged) ...[
                                        const SizedBox(height: 8),
                                        const Row(
                                          children: [
                                            Icon(Icons.flag,
                                                color: Colors.orange, size: 16),
                                            SizedBox(width: 4),
                                            Text('Flagged for review'),
                                          ],
                                        ),
                                      ],
                                      if (artwork.moderationNotes != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Notes: ${artwork.moderationNotes}',
                                          style: const TextStyle(
                                              fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Action buttons
                                OverflowBar(
                                  alignment: MainAxisAlignment.end,
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          _showModerationDialog(artwork),
                                      child: const Text('Review'),
                                    ),
                                    TextButton(
                                      onPressed: () => _moderateArtwork(artwork,
                                          ArtworkModerationStatus.approved),
                                      child: const Text('Approve'),
                                    ),
                                    TextButton(
                                      onPressed: () => _moderateArtwork(artwork,
                                          ArtworkModerationStatus.rejected),
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.red),
                                      child: const Text('Reject'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: selectedCount > 0
          ? FloatingActionButton(
              onPressed: _showBulkModerationDialog,
              tooltip: 'Bulk Actions',
              child: const Icon(Icons.batch_prediction),
            )
          : null,
    );
  }

  Color _getStatusColor(ArtworkModerationStatus status) {
    switch (status) {
      case ArtworkModerationStatus.pending:
        return Colors.orange.withValues(alpha: 0.1);
      case ArtworkModerationStatus.approved:
        return Colors.green.withValues(alpha: 0.1);
      case ArtworkModerationStatus.rejected:
        return Colors.red.withValues(alpha: 0.1);
      case ArtworkModerationStatus.flagged:
        return Colors.orange.withValues(alpha: 0.1);
      case ArtworkModerationStatus.underReview:
        return Colors.blue.withValues(alpha: 0.1);
    }
  }
}

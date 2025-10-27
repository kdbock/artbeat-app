import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/art_walk_model.dart';
import '../services/art_walk_service.dart';

/// Admin screen for moderating art walks
class AdminArtWalkModerationScreen extends StatefulWidget {
  const AdminArtWalkModerationScreen({Key? key}) : super(key: key);

  @override
  State<AdminArtWalkModerationScreen> createState() =>
      _AdminArtWalkModerationScreenState();
}

class _AdminArtWalkModerationScreenState
    extends State<AdminArtWalkModerationScreen> {
  late final ArtWalkService _artWalkService;
  List<ArtWalkModel> _artWalks = [];
  bool _loading = true;
  String _selectedTab = 'all';

  @override
  void initState() {
    super.initState();
    AppLogger.info('🔍 AdminArtWalkModerationScreen: initState called');
    try {
      _artWalkService = ArtWalkService();
      AppLogger.info(
        '✅ AdminArtWalkModerationScreen: ArtWalkService initialized',
      );
      _loadArtWalks();
    } catch (e, stackTrace) {
      AppLogger.error('❌ AdminArtWalkModerationScreen: Error in initState: $e');
      AppLogger.error('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _loadArtWalks() async {
    AppLogger.info('🔍 AdminArtWalkModerationScreen: _loadArtWalks called');
    setState(() => _loading = true);

    try {
      List<ArtWalkModel> walks;
      if (_selectedTab == 'all') {
        AppLogger.info(
          '🔍 AdminArtWalkModerationScreen: Fetching all art walks',
        );
        walks = await _artWalkService.getAllArtWalks(limit: 100);
      } else {
        AppLogger.info(
          '🔍 AdminArtWalkModerationScreen: Fetching reported art walks',
        );
        walks = await _artWalkService.getReportedArtWalks(limit: 100);
      }

      AppLogger.info(
        '✅ AdminArtWalkModerationScreen: Loaded ${walks.length} art walks',
      );
      if (mounted) {
        setState(() {
          _artWalks = walks;
          _loading = false;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ AdminArtWalkModerationScreen: Error loading art walks: $e',
      );
      AppLogger.error('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading art walks: $e')));
      }
    }
  }

  Future<void> _deleteArtWalk(ArtWalkModel walk) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Art Walk'),
          content: Text(
            'Are you sure you want to permanently delete "${walk.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _artWalkService.adminDeleteArtWalk(walk.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Art walk deleted successfully')),
          );
          _loadArtWalks();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting art walk: $e')),
          );
        }
      }
    }
  }

  Future<void> _clearReports(ArtWalkModel walk) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Reports'),
          content: Text(
            'Clear ${walk.reportCount} report(s) from "${walk.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear Reports'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _artWalkService.clearArtWalkReports(walk.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reports cleared successfully')),
          );
          _loadArtWalks();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error clearing reports: $e')));
        }
      }
    }
  }

  void _showArtWalkDetails(ArtWalkModel walk) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(walk.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (walk.coverImageUrl != null &&
                    walk.coverImageUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      walk.coverImageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildDetailRow('Description', walk.description),
                _buildDetailRow('Creator ID', walk.userId),
                _buildDetailRow('Created', _formatDate(walk.createdAt)),
                _buildDetailRow('Public', walk.isPublic ? 'Yes' : 'No'),
                _buildDetailRow('Views', walk.viewCount.toString()),
                _buildDetailRow('Artworks', walk.artworkIds.length.toString()),
                if (walk.estimatedDuration != null)
                  _buildDetailRow(
                    'Duration',
                    '${walk.estimatedDuration!.toStringAsFixed(0)} min',
                  ),
                if (walk.estimatedDistance != null)
                  _buildDetailRow(
                    'Distance',
                    '${walk.estimatedDistance!.toStringAsFixed(1)} mi',
                  ),
                if (walk.difficulty != null)
                  _buildDetailRow('Difficulty', walk.difficulty!),
                if (walk.zipCode != null)
                  _buildDetailRow('ZIP Code', walk.zipCode!),
                if (walk.reportCount > 0)
                  _buildDetailRow(
                    'Reports',
                    walk.reportCount.toString(),
                    isWarning: true,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWarning)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.flag, size: 16, color: Colors.red),
            ),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isWarning ? Colors.red : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: isWarning ? Colors.red : null),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Art Walk Moderation'),
        backgroundColor: ArtbeatColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Tab selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'all',
                  label: Text('All'),
                  icon: Icon(Icons.route),
                ),
                ButtonSegment(
                  value: 'reported',
                  label: Text('Reported'),
                  icon: Icon(Icons.flag),
                ),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedTab = newSelection.first;
                });
                _loadArtWalks();
              },
            ),
          ),

          // Art walks list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _artWalks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedTab == 'reported'
                              ? Icons.flag_outlined
                              : Icons.route_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedTab == 'reported'
                              ? 'No reported art walks'
                              : 'No art walks found',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadArtWalks,
                    child: ListView.builder(
                      itemCount: _artWalks.length,
                      itemBuilder: (context, index) {
                        final walk = _artWalks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading:
                                walk.coverImageUrl != null &&
                                    walk.coverImageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      walk.coverImageUrl!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.route),
                                            );
                                          },
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.route),
                                  ),
                            title: Row(
                              children: [
                                Expanded(child: Text(walk.title)),
                                if (walk.reportCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.flag,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          walk.reportCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  walk.description.length > 60
                                      ? '${walk.description.substring(0, 60)}...'
                                      : walk.description,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${walk.artworkIds.length} artworks • ${walk.viewCount} views',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (walk.reportCount > 0)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.flag_outlined,
                                      color: Colors.blue,
                                    ),
                                    tooltip: 'Clear Reports',
                                    onPressed: () => _clearReports(walk),
                                  ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Delete',
                                  onPressed: () => _deleteArtWalk(walk),
                                ),
                              ],
                            ),
                            onTap: () => _showArtWalkDetails(walk),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

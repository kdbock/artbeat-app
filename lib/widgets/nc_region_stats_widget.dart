import 'package:flutter/material.dart';
import 'package:artbeat/services/nc_region_service.dart';
import 'package:artbeat/utils/nc_location_helper.dart';

/// A widget that displays statistics for a selected NC region
class NCRegionStatsWidget extends StatefulWidget {
  /// The region name to display stats for
  final String regionName;

  /// Whether to show a compact version of the stats
  final bool isCompact;

  const NCRegionStatsWidget({
    super.key,
    required this.regionName,
    this.isCompact = false,
  });

  @override
  State<NCRegionStatsWidget> createState() => _NCRegionStatsWidgetState();
}

class _NCRegionStatsWidgetState extends State<NCRegionStatsWidget> {
  final NCRegionService _regionService = NCRegionService();
  Map<String, int> _stats = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didUpdateWidget(NCRegionStatsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.regionName != widget.regionName) {
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _regionService.getRegionStatistics(widget.regionName);

      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final helper = NCLocationHelper();
    final color = helper.getColorForRegion(widget.regionName);

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error loading region stats: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return widget.isCompact
        ? _buildCompactStats(context, color)
        : _buildFullStats(context, color);
  }

  Widget _buildCompactStats(BuildContext context, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha((255 * 0.2).round())),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
                context, 'Artists', _stats['artistCount'] ?? 0, Icons.person),
            _buildStatItem(
                context, 'Artwork', _stats['artworkCount'] ?? 0, Icons.image),
            _buildStatItem(
                context, 'Events', _stats['eventCount'] ?? 0, Icons.event),
            _buildStatItem(
                context, 'Art Walks', _stats['artWalkCount'] ?? 0, Icons.map),
          ],
        ),
      ),
    );
  }

  Widget _buildFullStats(BuildContext context, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              '${widget.regionName} Region Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                  ),
            ),
          ),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildStatRow(context, 'Artists', _stats['artistCount'] ?? 0,
                      Icons.person),
                  const Divider(),
                  _buildStatRow(context, 'Artwork', _stats['artworkCount'] ?? 0,
                      Icons.image),
                  const Divider(),
                  _buildStatRow(context, 'Events', _stats['eventCount'] ?? 0,
                      Icons.event),
                  const Divider(),
                  _buildStatRow(context, 'Art Walks',
                      _stats['artWalkCount'] ?? 0, Icons.map),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
      BuildContext context, String label, int value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

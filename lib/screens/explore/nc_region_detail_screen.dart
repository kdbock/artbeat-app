import 'package:flutter/material.dart';
import 'package:artbeat/utils/nc_location_helper.dart';
import 'package:artbeat/widgets/nc_region_counties_widget.dart';
import 'package:artbeat/widgets/nc_region_stats_widget.dart';
import 'package:artbeat/widgets/nc_regional_artwork_widget.dart';
import 'package:artbeat/models/artwork_model.dart';

/// Screen to display details about a specific North Carolina region
class NCRegionDetailScreen extends StatefulWidget {
  final String regionName;

  const NCRegionDetailScreen({
    super.key,
    required this.regionName,
  });

  @override
  State<NCRegionDetailScreen> createState() => _NCRegionDetailScreenState();
}

class _NCRegionDetailScreenState extends State<NCRegionDetailScreen> {
  final NCLocationHelper _locationHelper = NCLocationHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Region statistics
                  NCRegionStatsWidget(regionName: widget.regionName),

                  const SizedBox(height: 24),

                  // Counties in this region
                  _buildCountiesSection(),

                  const SizedBox(height: 24),

                  // Region artwork
                  _buildArtworkSection(),

                  const SizedBox(height: 24),

                  // Link to art walks in this region
                  _buildArtWalksCard(),

                  const SizedBox(height: 24),

                  // Link to events in this region
                  _buildEventsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final color = _locationHelper.getColorForRegion(widget.regionName);

    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      backgroundColor: color,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          '${widget.regionName} Region',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black45,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        background: Stack(
          children: [
            // Full-width colored background
            Container(color: color),

            // Semi-transparent overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(0),
                    Colors.black.withAlpha(153),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.map_outlined),
          tooltip: 'Open Map',
          onPressed: () {
            // Navigate to a map view for this region
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Map view coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCountiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Counties',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        NCRegionCountiesWidget(
          regionName: widget.regionName,
          isCompact: true,
          onCountySelected: (county) {
            // Handle county selection
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Selected $county')),
            );
          },
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            _showCountiesDialog(context);
          },
          child: const Text('View All Counties'),
        ),
      ],
    );
  }

  Widget _buildArtworkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured Artwork',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: NCRegionalArtworkWidget(
            initialRegion: widget.regionName,
            showRegionSelector: false,
            onArtworkTap: _handleArtworkTap,
          ),
        ),
      ],
    );
  }

  Widget _buildArtWalksCard() {
    final color = _locationHelper.getColorForRegion(widget.regionName);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/art-walk/list', arguments: {
            'region': widget.regionName,
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.map_outlined,
                color: color,
                size: 36,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Art Walks',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explore curated art walks in the ${widget.regionName} region',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsCard() {
    final color = _locationHelper.getColorForRegion(widget.regionName);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/calendar', arguments: {
            'region': widget.regionName,
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.event_outlined,
                color: color,
                size: 36,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Events',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find art events and exhibitions in the ${widget.regionName} region',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _showCountiesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.regionName} Counties'),
        content: SizedBox(
          width: double.maxFinite,
          child: NCRegionCountiesWidget(
            regionName: widget.regionName,
            isCompact: false,
            onCountySelected: (county) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Selected $county')),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleArtworkTap(ArtworkModel artwork) {
    // Navigate to artwork detail
    Navigator.pushNamed(
      context,
      '/artwork/detail',
      arguments: {'artworkId': artwork.id},
    );
  }
}

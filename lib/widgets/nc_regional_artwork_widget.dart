import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat/data/nc_zip_code_db.dart';
import 'package:artbeat/models/artwork_model.dart';
import 'package:artbeat/widgets/nc_region_selector_widget.dart';

/// Widget to display artwork filtered by North Carolina region
class NCRegionalArtworkWidget extends StatefulWidget {
  /// Limit the number of artwork pieces shown
  final int limit;

  /// Height of the widget
  final double height;

  /// Whether to show the region selector
  final bool showRegionSelector;

  /// Initial region to filter by
  final String? initialRegion;

  /// Function to call when an artwork is tapped
  final Function(ArtworkModel)? onArtworkTap;

  const NCRegionalArtworkWidget({
    super.key,
    this.limit = 10,
    this.height = 280,
    this.showRegionSelector = true,
    this.initialRegion,
    this.onArtworkTap,
  });

  @override
  State<NCRegionalArtworkWidget> createState() =>
      _NCRegionalArtworkWidgetState();
}

class _NCRegionalArtworkWidgetState extends State<NCRegionalArtworkWidget> {
  final NCZipCodeDatabase _db = NCZipCodeDatabase();
  String? _selectedRegion;
  List<String> _zipCodes = [];

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.initialRegion;
    _updateZipCodes();
  }

  void _updateZipCodes() {
    if (_selectedRegion != null && _selectedRegion != 'All Regions') {
      _zipCodes = _db.getZipCodesByRegion(_selectedRegion!);
    } else {
      // Get all ZIP codes
      _zipCodes = _db.getAllZipCodes();
    }
    setState(() {});
  }

  void _onRegionSelected(String region) {
    setState(() {
      _selectedRegion = region == 'All Regions' ? null : region;
    });
    _updateZipCodes();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showRegionSelector)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: NCRegionSelectorWidget(
              onRegionSelected: _onRegionSelected,
              initialRegion: _selectedRegion ?? 'All Regions',
              title: 'Filter by NC Region',
            ),
          ),

        // Regional artwork display
        SizedBox(
          height: widget.height,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _getArtworkQuery().snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading artwork: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No artwork found in this region'),
                );
              }

              final artworks = snapshot.data!.docs
                  .map((doc) => ArtworkModel.fromFirestore(doc))
                  .toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: artworks.length,
                itemBuilder: (context, index) {
                  final artwork = artworks[index];
                  return _ArtworkCard(
                    artwork: artwork,
                    onTap: () {
                      if (widget.onArtworkTap != null) {
                        widget.onArtworkTap!(artwork);
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Query<Map<String, dynamic>> _getArtworkQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('artwork')
        .orderBy('createdAt', descending: true)
        .limit(widget.limit);

    // If we have no region filter or too many ZIP codes, just return the base query
    if (_selectedRegion == null || _selectedRegion == 'All Regions') {
      return query;
    }

    // For Firestore, we'll limit to first 10 ZIP codes to avoid query limitations
    // For a production app, you'd need a more sophisticated approach
    final filteredZips = _zipCodes.take(10).toList();
    if (filteredZips.isNotEmpty) {
      query = query.where('location', whereIn: filteredZips);
    }

    return query;
  }
}

/// Card widget to display an artwork with image and details
class _ArtworkCard extends StatelessWidget {
  final ArtworkModel artwork;
  final VoidCallback onTap;

  const _ArtworkCard({
    required this.artwork,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          width: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artwork image
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  children: [
                    Image.network(
                      artwork.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image,
                              size: 50, color: Colors.grey),
                        );
                      },
                    ),
                    if (!artwork.isForSale)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SOLD',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Artwork details
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artwork.medium,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (artwork.isForSale && artwork.price != null)
                      Text(
                        '\$${artwork.price!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
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

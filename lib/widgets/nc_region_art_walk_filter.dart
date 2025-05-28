import 'package:flutter/material.dart';
import 'package:artbeat/data/nc_zip_code_db.dart';
import 'package:artbeat/models/art_walk_model.dart';
import 'package:artbeat/services/art_walk_service.dart';
import 'package:artbeat/widgets/nc_region_selector_widget.dart';
import 'package:artbeat/widgets/nc_region_marker_widget.dart';
import 'package:artbeat/utils/nc_location_helper.dart';

/// A widget that allows filtering Art Walks by North Carolina region
class NCRegionArtWalkFilter extends StatefulWidget {
  /// Function called when filtered art walks are loaded
  final Function(List<ArtWalkModel>) onArtWalksLoaded;

  /// Initial region to filter by (optional)
  final String? initialRegion;

  /// Whether to show a loading indicator when filtering
  final bool showLoadingIndicator;

  /// Maximum number of art walks to display
  final int limit;

  const NCRegionArtWalkFilter({
    super.key,
    required this.onArtWalksLoaded,
    this.initialRegion,
    this.showLoadingIndicator = true,
    this.limit = 20,
  });

  @override
  State<NCRegionArtWalkFilter> createState() => _NCRegionArtWalkFilterState();
}

class _NCRegionArtWalkFilterState extends State<NCRegionArtWalkFilter> {
  final NCZipCodeDatabase _db = NCZipCodeDatabase();
  final ArtWalkService _artWalkService = ArtWalkService();
  final NCLocationHelper _locationHelper = NCLocationHelper();

  String? _selectedRegion;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.initialRegion;
    _loadArtWalks();
  }

  Future<void> _loadArtWalks() async {
    if (widget.showLoadingIndicator) {
      setState(() => _isLoading = true);
    }

    try {
      List<ArtWalkModel> artWalks = [];

      if (_selectedRegion != null) {
        // Get ZIP codes for the selected region
        final zipCodes = _db.getZipCodesByRegion(_selectedRegion!);

        // Use a subset of ZIP codes for the query (Firestore limitation)
        final limitedZipCodes = zipCodes.take(10).toList();

        // Get art walks filtered by region
        artWalks = await _artWalkService.getArtWalksByZipCodes(
          limitedZipCodes,
          limit: widget.limit,
        );
      } else {
        // No region filter, get popular walks
        artWalks =
            await _artWalkService.getPopularArtWalks(limit: widget.limit);
      }

      // Notify parent widget of the loaded art walks
      widget.onArtWalksLoaded(artWalks);
    } catch (e) {
      debugPrint('Error loading art walks by region: $e');
      widget.onArtWalksLoaded([]);
    } finally {
      if (widget.showLoadingIndicator && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onRegionSelected(String region) {
    setState(() {
      _selectedRegion = region == 'All Regions' ? null : region;
    });
    _loadArtWalks();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Region selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: NCRegionSelectorWidget(
            onRegionSelected: _onRegionSelected,
            initialRegion: _selectedRegion ?? 'All Regions',
            title: 'Browse Art Walks by Region',
          ),
        ),

        // Loading indicator
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),

        // Selected region badge (if a region is selected)
        if (_selectedRegion != null && !_isLoading)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                NCRegionMarkerWidget(
                  regionName: _selectedRegion!,
                  isSmall: false,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing art walks in the ${_selectedRegion!} region',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

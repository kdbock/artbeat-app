import 'package:flutter/material.dart';
import 'package:artbeat/data/nc_zip_code_db.dart';
import 'package:artbeat/models/artwork_model.dart';
import 'package:artbeat/utils/nc_location_finder.dart';
import 'package:artbeat/widgets/nc_regional_artwork_widget.dart';

/// Screen to explore North Carolina regions and their artwork
class NCRegionsExploreScreen extends StatefulWidget {
  const NCRegionsExploreScreen({super.key}) : super();

  @override
  State<NCRegionsExploreScreen> createState() => _NCRegionsExploreScreenState();
}

class _NCRegionsExploreScreenState extends State<NCRegionsExploreScreen> {
  final NCZipCodeDatabase _db = NCZipCodeDatabase();
  final NCLocationFinder _locationFinder = NCLocationFinder();
  String? _userRegion;
  bool _isLoading = true;
  Map<String, dynamic> _locationContext = {};

  @override
  void initState() {
    super.initState();
    _determineUserLocation();
  }

  Future<void> _determineUserLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locationContext = await _locationFinder.getUserLocationContext();
      setState(() {
        _locationContext = locationContext;
        _userRegion = locationContext['region'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not determine location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUserInNC = _locationContext['isInNC'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NC Art Explorer'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _determineUserLocation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location context banner
                    _buildLocationBanner(isUserInNC),

                    const SizedBox(height: 24),

                    // Featured artwork from user's region (if in NC)
                    if (isUserInNC && _userRegion != null) ...[
                      Text(
                        'Artwork from $_userRegion',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      NCRegionalArtworkWidget(
                        initialRegion: _userRegion,
                        showRegionSelector: false,
                        onArtworkTap: _handleArtworkTap,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Browse all NC regions
                    Text(
                      'Browse by NC Region',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    NCRegionalArtworkWidget(
                      onArtworkTap: _handleArtworkTap,
                    ),

                    const SizedBox(height: 24),

                    // Region cards grid
                    Text(
                      'NC Art Regions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildRegionGrid(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLocationBanner(bool isUserInNC) {
    if (isUserInNC && _locationContext['zipCode'] != null) {
      final String zipCode = _locationContext['zipCode'];
      final String locationDescription =
          _locationFinder.getLocationDescription(zipCode);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.green[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'re browsing from:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locationDescription,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[700]),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Browse artwork from across North Carolina, organized by region.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRegionGrid() {
    final regions = _db.getAllRegions();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: regions.length,
      itemBuilder: (context, index) {
        final region = regions[index];
        return _buildRegionCard(region.name);
      },
    );
  }

  Widget _buildRegionCard(String regionName) {
    // Define colors for each region
    final Map<String, Color> regionColors = {
      'Mountain': Colors.green[700]!,
      'Foothills': Colors.amber[800]!,
      'Piedmont': Colors.blue[700]!,
      'Sandhills': Colors.orange[700]!,
      'Coastal Plain': Colors.cyan[700]!,
      'Coastal': Colors.indigo[700]!,
    };

    final Color regionColor = regionColors[regionName] ?? Colors.teal;

    return InkWell(
      onTap: () => _handleRegionTap(regionName),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                regionColor,
                regionColor.withAlpha(179),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                regionName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_db.getCountiesByRegion(regionName).length} counties',
                style: TextStyle(
                  color: Colors.white.withAlpha(230),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRegionTap(String regionName) {
    // Navigate to a filtered view of this region
    // This is a placeholder for the actual implementation
    Navigator.pushNamed(context, '/explore/region', arguments: {
      'regionName': regionName,
    });
  }

  void _handleArtworkTap(ArtworkModel artwork) {
    // Navigate to artwork detail screen
    Navigator.pushNamed(
      context,
      '/artwork/detail',
      arguments: {'artworkId': artwork.id},
    );
  }
}

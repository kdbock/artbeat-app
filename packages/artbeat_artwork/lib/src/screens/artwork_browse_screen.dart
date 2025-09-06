import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show MainLayout;
import '../models/artwork_model.dart';
import '../widgets/artwork_header.dart';
import '../widgets/artwork_grid_widget.dart';
import '../widgets/local_artwork_row_widget.dart';
import '../widgets/artwork_discovery_widget.dart';

/// Screen for browsing all artwork, with filtering options
class ArtworkBrowseScreen extends StatefulWidget {
  const ArtworkBrowseScreen({super.key});

  @override
  State<ArtworkBrowseScreen> createState() => _ArtworkBrowseScreenState();
}

class _ArtworkBrowseScreenState extends State<ArtworkBrowseScreen> {
  final _searchController = TextEditingController();
  String _selectedLocation = 'All';
  String _selectedMedium = 'All';
  List<String> _locations = ['All'];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      // Get distinct locations from artwork collection
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('artwork').get();

      // Extract unique locations
      final Set<String> locations = {'All'};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final location = data['location'] as String?;
        if (location != null && location.isNotEmpty) {
          locations.add(location);
        }
      }

      setState(() {
        _locations = locations.toList()..sort();
      });
    } catch (e) {
      // debugPrint('Error loading locations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex:
          0, // Dashboard tab - artwork browsing is accessed from dashboard
      appBar: ArtworkHeader(
        title: 'Browse Artwork',
        showBackButton: true,
        showSearch: true,
        showDeveloper: false,
        onSearchPressed: () => Navigator.pushNamed(context, '/search'),
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search artwork...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch();
                  },
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Filters:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (_selectedLocation != 'All')
                  Chip(
                    label: Text(_selectedLocation),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedLocation = 'All';
                      });
                      _performSearch();
                    },
                  ),
                const SizedBox(width: 8),
                if (_selectedMedium != 'All')
                  Chip(
                    label: Text(_selectedMedium),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedMedium = 'All';
                      });
                      _performSearch();
                    },
                  ),
              ],
            ),
          ),

          // Local Artwork Section
          LocalArtworkRowWidget(
            zipCode:
                '10001', // Default NYC zip code - should be user's location
            onSeeAllPressed: () =>
                Navigator.pushNamed(context, '/artwork/local'),
          ),
          const SizedBox(height: 16),

          // Discovery Section
          ArtworkDiscoveryWidget(
            userId: 'current_user_id', // Should be replaced with actual user ID
            limit: 5,
            title: 'Discover New Artworks',
            onSeeAllPressed: () =>
                Navigator.pushNamed(context, '/artwork/discovery'),
          ),
          const SizedBox(height: 16),

          // Results
          Expanded(
            child: _buildArtworkGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getArtworkStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('No artwork found matching your criteria.'),
          );
        }

        final artworks =
            docs.map((doc) => ArtworkModel.fromFirestore(doc)).toList();

        return ArtworkGridWidget(
          artworks: artworks,
          onArtworkTap: (artwork) => _navigateToArtworkDetail(artwork.id),
          crossAxisCount: 2,
          childAspectRatio: 0.75,
        );
      },
    );
  }

  Stream<QuerySnapshot> _getArtworkStream() {
    Query query = FirebaseFirestore.instance.collection('artwork');

    // Apply location filter if selected
    if (_selectedLocation != 'All') {
      query = query.where('location', isEqualTo: _selectedLocation);
    }

    // Apply medium filter if selected
    if (_selectedMedium != 'All') {
      query = query.where('medium', isEqualTo: _selectedMedium);
    }

    // Apply search by title if provided
    if (_searchController.text.isNotEmpty) {
      // For a simple search, we can use where with field path
      // This is not a full text search but works for exact matches
      query = query
          .where('title', isGreaterThanOrEqualTo: _searchController.text)
          .where('title',
              isLessThanOrEqualTo: '${_searchController.text}\uf8ff');
    }

    // Sort by creation date (newest first)
    return query.orderBy('createdAt', descending: true).snapshots();
  }

  void _performSearch() {
    // Trigger a rebuild to apply search
    setState(() {});
  }

  void _navigateToArtworkDetail(String artworkId) {
    Navigator.pushNamed(
      context,
      '/artist/artwork-detail',
      arguments: {'artworkId': artworkId},
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../models/artwork_model.dart';

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
  final List<String> _mediums = [
    'All',
    'Painting',
    'Sculpture',
    'Digital',
    'Photography',
    'Mixed Media'
  ];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    // Load unique locations from the artwork collection
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('artwork').get();

      final Set<String> locations = {'All'};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('location') && data['location'] != null) {
          locations.add(data['location'] as String);
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: -1, // No bottom navigation for this screen
      appBar: const core.EnhancedUniversalHeader(
        title: 'Browse Artwork',
        showLogo: false,
        showBackButton: true,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              core.ArtbeatColors.backgroundSecondary,
              core.ArtbeatColors.backgroundPrimary,
            ],
          ),
        ),
        child: Column(
          children: [
            // Subtitle section
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Explore amazing artwork from talented artists',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Search and filter section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    offset: const Offset(0, 2),
                    blurRadius: 4.0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search artwork...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      // Search will be implemented with debounce
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  // Filter section
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                          ),
                          initialValue: _selectedLocation,
                          items: _locations.map((location) {
                            return DropdownMenuItem<String>(
                              value: location,
                              child: Text(location),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedLocation = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Medium',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                          ),
                          initialValue: _selectedMedium,
                          items: _mediums.map((medium) {
                            return DropdownMenuItem<String>(
                              value: medium,
                              child: Text(medium),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMedium = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Artwork grid
            Expanded(
              child: _buildArtworkGrid(),
            ),
          ],
        ),
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

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final artwork = ArtworkModel.fromMap({
              'id': docs[index].id,
              ...docs[index].data() as Map<String, dynamic>
            });
            return _buildArtworkCard(artwork);
          },
        );
      },
    );
  }

  Widget _buildArtworkCard(ArtworkModel artwork) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: InkWell(
        onTap: () => _navigateToArtworkDetail(artwork.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: artwork.imageUrl.isNotEmpty &&
                            _isValidImageUrl(artwork.imageUrl)
                        ? NetworkImage(artwork.imageUrl) as ImageProvider
                        : const AssetImage('assets/default_artwork.png')
                            as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artwork.medium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (artwork.isForSale && artwork.price != null)
                    Text(
                      '\$${artwork.price!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  void _navigateToArtworkDetail(String artworkId) {
    Navigator.pushNamed(
      context,
      '/artist/artwork-detail',
      arguments: {'artworkId': artworkId},
    );
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty || url.trim().isEmpty) return false;

    // Check for invalid file URLs
    if (url == 'file:///' || url.startsWith('file:///') && url.length <= 8) {
      return false;
    }

    // Check for just the file scheme with no actual path
    if (url == 'file://' || url == 'file:') {
      return false;
    }

    // Check for malformed URLs that start with file:// but have no host
    if (url.startsWith('file://') && !url.startsWith('file:///')) {
      return false;
    }

    // Check for valid URL schemes
    return url.startsWith('http://') ||
        url.startsWith('https://') ||
        (url.startsWith('file:///') && url.length > 8);
  }
}

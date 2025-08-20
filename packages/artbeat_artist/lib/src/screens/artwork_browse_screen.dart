import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show EnhancedUniversalHeader, MainLayout;

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
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: const EnhancedUniversalHeader(
          title: 'Browse Artwork',
          showLogo: false,
        ),
        body: Column(
          children: [
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
                          value: _selectedLocation,
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
                          value: _selectedMedium,
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
            // Results section
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildArtworkQuery(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.art_track,
                              size: 72, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No artwork found',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try changing your filters',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  final artworks = snapshot.data!.docs
                      .map((doc) => ArtworkModel.fromFirestore(doc))
                      .toList();

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    padding: const EdgeInsets.all(16.0),
                    itemCount: artworks.length,
                    itemBuilder: (context, index) {
                      final artwork = artworks[index];
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/artist/artwork-detail',
                          arguments: {'artworkId': artwork.id},
                        ),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Artwork image
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(artwork.imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: !artwork.isForSale
                                      ? Align(
                                          alignment: Alignment.topRight,
                                          child: Container(
                                            margin: const EdgeInsets.all(8.0),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                              vertical: 4.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
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
                                        )
                                      : null,
                                ),
                              ),
                              // Artwork info
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      artwork.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('artistProfiles')
                                          .doc(artwork.artistProfileId)
                                          .get(),
                                      builder: (context, snapshot) {
                                        String artistName = 'Unknown Artist';
                                        if (snapshot.hasData &&
                                            snapshot.data != null) {
                                          final artistData = snapshot.data!
                                              .data() as Map<String, dynamic>?;
                                          if (artistData != null &&
                                              artistData
                                                  .containsKey('displayName')) {
                                            artistName =
                                                artistData['displayName']
                                                    as String;
                                          }
                                        }
                                        return Text(
                                          artistName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      artwork.price != null
                                          ? '\$${artwork.price!.toStringAsFixed(2)}'
                                          : 'Not for sale',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _buildArtworkQuery() {
    Query query = FirebaseFirestore.instance.collection('artwork');

    // Apply location filter
    if (_selectedLocation != 'All') {
      query = query.where('location', isEqualTo: _selectedLocation);
    }

    // Apply medium filter
    if (_selectedMedium != 'All') {
      query = query.where('medium', isEqualTo: _selectedMedium);
    } // Apply search if provided
    if (_searchController.text.isNotEmpty) {
      // This is a simplistic approach - in a production app, you'd use a more sophisticated search
      // like Algolia or Firebase's full-text search extension
      // For now, we'll just search by title prefix
      final searchText = _searchController.text.toLowerCase();
      query = query
          .where('title', isGreaterThanOrEqualTo: searchText)
          .where('title', isLessThanOrEqualTo: '$searchText\uf8ff');
    }

    // Sort by most recent
    query = query.orderBy('createdAt', descending: true).limit(50);

    return query.snapshots();
  }
}

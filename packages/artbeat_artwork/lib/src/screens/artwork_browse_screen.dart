import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      debugPrint('Error loading locations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Artwork'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
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
            final artwork = ArtworkModel.fromFirestore(docs[index]);
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
                    image: NetworkImage(artwork.imageUrl),
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

  void _performSearch() {
    // Trigger a rebuild to apply search
    setState(() {});
  }

  void _showFilterDialog() {
    String tempLocation = _selectedLocation;
    String tempMedium = _selectedMedium;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Artwork'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Location',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _locations.map((location) {
                    return ChoiceChip(
                      label: Text(location),
                      selected: tempLocation == location,
                      onSelected: (selected) {
                        setState(() {
                          tempLocation = selected ? location : 'All';
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Medium',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _mediums.map((medium) {
                    return ChoiceChip(
                      label: Text(medium),
                      selected: tempMedium == medium,
                      onSelected: (selected) {
                        setState(() {
                          tempMedium = selected ? medium : 'All';
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedLocation = tempLocation;
                  _selectedMedium = tempMedium;
                });
                Navigator.pop(context);
                _performSearch();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToArtworkDetail(String artworkId) {
    Navigator.pushNamed(
      context,
      '/artist/artwork-detail',
      arguments: {'artworkId': artworkId},
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart' show ArtworkModel;

class SearchResultsScreen extends StatefulWidget {
  final String query;
  const SearchResultsScreen({Key? key, required this.query}) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _isLoading = true;
  List<ArtistProfileModel> _artists = [];
  List<ArtworkModel> _artworks = [];
  List<EventModel> _events = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([_searchArtists(), _searchArtworks(), _searchEvents()]);
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchArtists() async {
    try {
      final query = widget.query.toLowerCase();

      // Search by first name, last name, and display name
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .where('userType', isEqualTo: 'artist')
          .get();

      final List<ArtistProfileModel> results = [];

      for (var doc in snapshot.docs) {
        if (!doc.exists) continue;
        try {
          final profile = ArtistProfileModel.fromFirestore(doc);

          // Check if query matches display name
          final displayName = profile.displayName.toLowerCase();

          if (displayName.contains(query)) {
            results.add(profile);
          }
        } catch (e) {
          debugPrint('Error parsing artist profile: $e');
        }
      }

      _artists = results;
    } catch (e) {
      debugPrint('Error searching artists: $e');
    }
  }

  Future<void> _searchArtworks() async {
    try {
      final query = widget.query.toLowerCase();

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('artwork')
          .get();

      final List<ArtworkModel> results = [];

      for (var doc in snapshot.docs) {
        if (!doc.exists) continue;
        try {
          final artwork = ArtworkModel.fromFirestore(doc);

          // Check if query matches title or description
          final title = artwork.title.toLowerCase();
          final description = artwork.description.toLowerCase();

          if (title.contains(query) || description.contains(query)) {
            results.add(artwork);
          }
        } catch (e) {
          debugPrint('Error parsing artwork: $e');
        }
      }

      _artworks = results;
    } catch (e) {
      debugPrint('Error searching artworks: $e');
    }
  }

  Future<void> _searchEvents() async {
    try {
      final query = widget.query.toLowerCase();

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('events')
          .get();

      final List<EventModel> results = [];

      for (var doc in snapshot.docs) {
        if (!doc.exists) continue;
        try {
          final event = EventModel.fromFirestore(doc);

          // Check if query matches title or description
          final title = event.title.toLowerCase();
          final description = event.description.toLowerCase();

          if (title.contains(query) || description.contains(query)) {
            results.add(event);
          }
        } catch (e) {
          debugPrint('Error parsing event: $e');
        }
      }

      _events = results;
    } catch (e) {
      debugPrint('Error searching events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const EnhancedUniversalHeader(
          title: 'Search Results',
          showLogo: false,
          showBackButton: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $_error'),
                  ],
                ),
              )
            : _buildSearchResults(),
      ),
    );
  }

  Widget _buildSearchResults() {
    final totalResults = _artists.length + _artworks.length + _events.length;

    if (totalResults == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No results found for "${widget.query}"',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different search term',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Text(
            'Found $totalResults results for "${widget.query}"',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_artists.isNotEmpty) ...[
                _buildSectionHeader('Artists (${_artists.length})'),
                ..._artists.map((artist) => _buildArtistTile(artist)),
                const SizedBox(height: 24),
              ],

              if (_artworks.isNotEmpty) ...[
                _buildSectionHeader('Artworks (${_artworks.length})'),
                ..._artworks.map((artwork) => _buildArtworkTile(artwork)),
                const SizedBox(height: 24),
              ],

              if (_events.isNotEmpty) ...[
                _buildSectionHeader('Events (${_events.length})'),
                ..._events.map((event) => _buildEventTile(event)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: ArtbeatColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildArtistTile(ArtistProfileModel artist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: artist.profileImageUrl != null
              ? NetworkImage(artist.profileImageUrl!)
              : null,
          child: artist.profileImageUrl == null
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(artist.displayName),
        subtitle: Text(artist.bio ?? 'Artist'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/artist/profile',
            arguments: {'artistId': artist.id},
          );
        },
      ),
    );
  }

  Widget _buildArtworkTile(ArtworkModel artwork) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: artwork.imageUrl.isNotEmpty
            ? Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(artwork.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image),
              ),
        title: Text(artwork.title),
        subtitle: Text(artwork.description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/artwork/details',
            arguments: {'artworkId': artwork.id},
          );
        },
      ),
    );
  }

  Widget _buildEventTile(EventModel event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: ArtbeatColors.primaryPurple.withValues(
              alpha: 26,
            ), // 0.1 opacity
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.event, color: ArtbeatColors.primaryPurple),
        ),
        title: Text(event.title),
        subtitle: Text(event.description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/event/details',
            arguments: {'eventId': event.id},
          );
        },
      ),
    );
  }
}

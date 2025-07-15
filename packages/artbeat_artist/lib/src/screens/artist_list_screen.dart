import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ArtistListScreen extends StatefulWidget {
  final String? title;
  final bool showFeaturedOnly;

  const ArtistListScreen({
    Key? key,
    this.title,
    this.showFeaturedOnly = false,
  }) : super(key: key);

  @override
  State<ArtistListScreen> createState() => _ArtistListScreenState();
}

class _ArtistListScreenState extends State<ArtistListScreen> {
  List<ArtistProfileModel> _artists = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .where('userType', isEqualTo: 'artist')
          .orderBy('displayName')
          .limit(20)
          .get();

      final List<ArtistProfileModel> artists = [];
      for (var doc in snapshot.docs) {
        if (doc.exists) {
          try {
            final artist = ArtistProfileModel.fromFirestore(doc);
            artists.add(artist);
          } catch (e) {
            debugPrint('Error parsing artist: $e');
          }
        }
      }

      setState(() {
        _artists = artists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadArtists,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _artists.isEmpty
                  ? _buildEmptyWidget()
                  : _buildArtistsList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to load artists'),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadArtists,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No artists found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for featured artists',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadArtists,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _artists.length,
      itemBuilder: (context, index) {
        final artist = _artists[index];
        return _buildArtistCard(artist);
      },
    );
  }

  Widget _buildArtistCard(ArtistProfileModel artist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/artist/public-profile',
            arguments: {'artistId': artist.id},
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Artist Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor:
                    ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                backgroundImage: artist.profileImageUrl != null
                    ? CachedNetworkImageProvider(artist.profileImageUrl!)
                    : null,
                child: artist.profileImageUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 30,
                        color: ArtbeatColors.primaryPurple,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Artist Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ArtbeatColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (artist.bio != null && artist.bio!.isNotEmpty)
                      Text(
                        artist.bio!,
                        style: const TextStyle(
                          color: ArtbeatColors.textSecondary,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    // Artist Stats
                    Row(
                      children: [
                        _buildStatChip(
                          icon: Icons.palette,
                          label: 'Artist',
                          color: ArtbeatColors.primaryPurple,
                        ),
                        const SizedBox(width: 8),
                        if (artist.location != null &&
                            artist.location!.isNotEmpty)
                          _buildStatChip(
                            icon: Icons.location_on,
                            label: artist.location!,
                            color: ArtbeatColors.primaryGreen,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action Button
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/artist/public-profile',
                    arguments: {'artistId': artist.id},
                  );
                },
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: ArtbeatColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

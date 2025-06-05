import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_artist/artbeat_artist.dart';

/// Widget that displays a horizontal list of local artists
class LocalArtistsRowWidget extends StatelessWidget {
  final String zipCode;
  final VoidCallback? onSeeAllPressed;

  const LocalArtistsRowWidget({
    super.key,
    required this.zipCode,
    this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Local Artists',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onSeeAllPressed,
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150, // Increased height to accommodate badges
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('artistProfiles')
                .where('location', isEqualTo: zipCode)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 36,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Error loading artists',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.brush_outlined,
                          size: 40,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No artists found in your area',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final artists = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id; // Add the document ID to the data
                return ArtistProfileModel.fromMap(data);
              }).toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: artists.length,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemBuilder: (context, index) {
                  final artist = artists[index];
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/artist/public-profile',
                      arguments: {'artistId': artist.id},
                    ),
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              // Profile image
                              Container(
                                decoration: BoxDecoration(
                                  border: artist.isVerified
                                      ? Border.all(color: Colors.blue, width: 2)
                                      : artist.isFeatured
                                          ? Border.all(
                                              color: Colors.amber, width: 2)
                                          : null,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: artist.profileImageUrl !=
                                              null &&
                                          artist.profileImageUrl!.isNotEmpty
                                      ? NetworkImage(artist.profileImageUrl!)
                                      : null,
                                  child: artist.profileImageUrl == null ||
                                          artist.profileImageUrl!.isEmpty
                                      ? const Icon(Icons.person, size: 40)
                                      : null,
                                ),
                              ),
                              // Verified badge
                              if (artist.isVerified)
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.verified,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                ),
                              // Featured badge (show only if not verified)
                              if (!artist.isVerified && artist.isFeatured)
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            artist.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            (artist.mediums.isNotEmpty)
                                ? artist.mediums.first
                                : 'Artist',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    );
  }
}

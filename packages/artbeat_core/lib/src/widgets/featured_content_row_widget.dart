import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/index.dart';

/// Widget for displaying featured artist content and articles in a row
class FeaturedContentRowWidget extends StatelessWidget {
  final String zipCode;
  final VoidCallback? onSeeAllPressed;

  const FeaturedContentRowWidget({
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
              Text(
                'Featured Content',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              TextButton(
                onPressed: onSeeAllPressed,
                child: Text(
                  'See All',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: ArtbeatColors.primaryPurple,
                      ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 260,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('featuredContent')
                .where('isActive', isEqualTo: true)
                .orderBy('publishedAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ArtbeatColors.primaryPurple,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ArtbeatColors.error,
                        ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No featured content available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ArtbeatColors.textSecondary,
                          ),
                    ),
                  ),
                );
              }

              final featuredContent = snapshot.data!.docs;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: featuredContent.length,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemBuilder: (context, index) {
                  final content =
                      featuredContent[index].data() as Map<String, dynamic>;

                  return GestureDetector(
                    onTap: () {
                      if (content['type'] == 'article') {
                        // Open article
                      } else if (content['type'] == 'artist') {
                        Navigator.pushNamed(context, '/artist/public-profile',
                            arguments: {'artistId': content['artistId']});
                      }
                    },
                    child: Container(
                      width: 260,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: ArtbeatColors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12.0)),
                              child: Image.network(
                                content['imageUrl'],
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 150,
                                    color: ArtbeatColors.backgroundSecondary,
                                    child: const Icon(
                                      Icons.article,
                                      size: 40,
                                      color: ArtbeatColors.textSecondary,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: content['type'] == 'article'
                                          ? ArtbeatColors.info.withOpacity(0.2)
                                          : ArtbeatColors.primaryPurple
                                              .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: Text(
                                      content['type']?.toUpperCase() ??
                                          'FEATURED',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontSize: 10,
                                            color: content['type'] == 'article'
                                                ? ArtbeatColors.info
                                                : ArtbeatColors.primaryPurple,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    content['title'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    content['author'] ?? 'ARTbeat Staff',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: ArtbeatColors.textSecondary,
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
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

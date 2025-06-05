import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
              const Text(
                'Featured Content',
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
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('No featured content available'),
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
                      // Navigate to the content detail or launch URL
                      if (content['type'] == 'article') {
                        // Open article
                      } else if (content['type'] == 'artist') {
                        // Open artist profile
                        Navigator.pushNamed(context, '/artist/public-profile',
                            arguments: {'artistId': content['artistId']});
                      }
                    },
                    child: Container(
                      width: 260,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: Card(
                        elevation: 2,
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
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.article, size: 40),
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
                                          ? Colors.blue.withAlpha(51)
                                          : Colors.purple.withAlpha(51),
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: Text(
                                      content['type']?.toUpperCase() ??
                                          'FEATURED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: content['type'] == 'article'
                                            ? Colors.blue.shade800
                                            : Colors.purple.shade800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    content['title'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    content['author'] ?? 'ARTbeat Staff',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
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

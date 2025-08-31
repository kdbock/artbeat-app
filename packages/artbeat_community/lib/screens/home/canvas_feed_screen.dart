import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../../models/artwork_model.dart' as community;
import '../../widgets/avatar_widget.dart';

class CanvasFeedScreen extends StatelessWidget {
  final List<community.ArtworkModel> artworks;

  const CanvasFeedScreen({super.key, required this.artworks});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // Not a main navigation screen
      appBar: const EnhancedUniversalHeader(
        title: 'Canvas Feed',
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: true,
      ),
      drawer: const ArtbeatDrawer(),
      child: ListView.builder(
        itemCount: artworks.length,
        itemBuilder: (context, index) {
          final artwork = artworks[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: AvatarWidget(avatarUrl: artwork.imageUrl),
              title: Text(artwork.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Medium: ${artwork.medium}'),
                  Text('Location: ${artwork.location}'),
                  Text('Posted: ${artwork.createdAt.toDate()}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

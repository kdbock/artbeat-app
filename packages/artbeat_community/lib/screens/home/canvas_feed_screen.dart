import 'package:flutter/material.dart';
import '../../models/artwork_model.dart';
import '../../widgets/avatar_widget.dart';

class CanvasFeedScreen extends StatelessWidget {
  final List<ArtworkModel> artworks;

  const CanvasFeedScreen({super.key, required this.artworks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canvas Feed'),
      ),
      body: ListView.builder(
        itemCount: artworks.length,
        itemBuilder: (context, index) {
          final artwork = artworks[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: AvatarWidget(
                avatarUrl: artwork.imageUrl,
              ),
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

import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' show ArtistProfileModel;
import '../models/artwork_model.dart';
import 'avatar_widget.dart';

class CanvasFeed extends StatelessWidget {
  final List<ArtworkModel> artworks;
  final void Function(ArtistProfileModel)
  onArtistTap; // Updated to accept ArtistProfileModel

  const CanvasFeed({
    super.key,
    required this.artworks,
    required this.onArtistTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: artworks.length,
      itemBuilder: (context, index) {
        final artwork = artworks[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: AvatarWidget(
              avatarUrl: artwork.artist?.profileImageUrl ?? '',
              onTap: () {
                if (artwork.artist != null) {
                  onArtistTap(artwork.artist!);
                }
              },
            ),
            title: Text(artwork.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Medium: ${artwork.medium}'),
                Text('Location: ${artwork.location}'),
                Text('Posted: ${artwork.createdAt}'),
              ],
            ),
          ),
        );
      },
    );
  }
}

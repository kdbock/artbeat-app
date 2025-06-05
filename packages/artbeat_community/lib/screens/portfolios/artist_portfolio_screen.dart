import 'package:flutter/material.dart';
import '../../models/artwork_model.dart';
import '../../models/user_model.dart';
import '../../widgets/artwork_card_widget.dart';

class ArtistPortfolioScreen extends StatelessWidget {
  final String artistName;
  final UserModel artist;
  final List<ArtworkModel> artworks;

  const ArtistPortfolioScreen(
      {super.key, required this.artistName, required this.artist, required this.artworks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$artistName\'s Portfolio'),
      ),
      body: artworks.isEmpty
          ? const Center(
              child: Text('No artworks available'),
            )
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
              ),
              itemCount: artworks.length,
              itemBuilder: (context, index) {
                final artwork = artworks[index];
                return ArtworkCardWidget(artwork: artwork, artist: artist);
              },
            ),
    );
  }
}

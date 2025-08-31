import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../../models/artwork_model.dart' as community;
import '../../models/user_model.dart' as community;
import '../../widgets/artwork_card_widget.dart';

class ArtistPortfolioScreen extends StatelessWidget {
  final String artistName;
  final community.UserModel artist;
  final List<community.ArtworkModel> artworks;

  const ArtistPortfolioScreen({
    super.key,
    required this.artistName,
    required this.artist,
    required this.artworks,
  });

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // Not a main navigation screen
      appBar: EnhancedUniversalHeader(
        title: '$artistName\'s Portfolio',
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: true,
      ),
      drawer: const ArtbeatDrawer(),
      child: artworks.isEmpty
          ? const Center(child: Text('No artworks available'))
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

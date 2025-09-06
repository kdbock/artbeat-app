import 'package:flutter/material.dart';
import '../models/artwork_model.dart';
import '../models/user_model.dart';

class ArtworkCardWidget extends StatelessWidget {
  final ArtworkModel artwork;
  final UserModel artist;

  const ArtworkCardWidget({
    super.key,
    required this.artwork,
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the avatar URL is valid for NetworkImage
    final bool isValidAvatarUrl =
        artist.avatarUrl.isNotEmpty &&
        (artist.avatarUrl.startsWith('http://') ||
            artist.avatarUrl.startsWith('https://')) &&
        artist.avatarUrl != 'placeholder_headshot_url';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/artist/public-profile',
                      arguments: {'artistId': artist.id},
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: isValidAvatarUrl
                        ? NetworkImage(artist.avatarUrl)
                        : null,
                    radius: 24,
                    child: !isValidAvatarUrl
                        ? const Icon(Icons.person, size: 24)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      artwork.location,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              artwork.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              artwork.medium,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

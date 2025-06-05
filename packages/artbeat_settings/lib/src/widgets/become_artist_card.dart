import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';
import '../routes.dart';

class BecomeArtistCard extends StatelessWidget {
  final UserModel user;

  const BecomeArtistCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show for users who are already artists
    if (user.userType == UserType.artist.name ||
        user.userType == UserType.gallery.name) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Join ARTbeat as an Artist',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Share your artwork with the world, connect with galleries, and grow your artistic career.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    SettingsRoutes.becomeArtist,
                    arguments: user,
                  );
                },
                child: const Text('Become an Artist'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

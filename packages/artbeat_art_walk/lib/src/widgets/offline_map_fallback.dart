import 'package:flutter/material.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

class OfflineMapFallback extends StatelessWidget {
  final VoidCallback onRetry;
  final bool hasData;
  final String errorMessage;
  final List<PublicArtModel> nearbyArt;

  const OfflineMapFallback({
    super.key,
    required this.onRetry,
    this.hasData = false,
    this.errorMessage = 'Unable to load map',
    this.nearbyArt = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use a stack to create a combined map and offline icon
            SizedBox(
              height: 64,
              width: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.map, // Always show map as the base icon
                    size: 64,
                    color: Colors.grey,
                  ),
                  if (!hasData)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.signal_wifi_off,
                          size: 24,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasData ? 'Map unavailable while offline' : errorMessage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              hasData && nearbyArt.isNotEmpty
                  ? 'You have ${nearbyArt.length} cached art pieces available.\nSome features may be limited in offline mode.'
                  : 'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            if (hasData && nearbyArt.isNotEmpty) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/art-walk/list');
                },
                icon: const Icon(Icons.list_alt),
                label: const Text('View Art Walk List'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

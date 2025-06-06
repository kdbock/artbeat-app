import 'package:flutter/material.dart';

class MapFloatingMenu extends StatelessWidget {
  final VoidCallback onViewArtWalks;
  final VoidCallback onCreateArtWalk;
  final VoidCallback onViewAttractions;

  const MapFloatingMenu({
    super.key,
    required this.onViewArtWalks,
    required this.onCreateArtWalk,
    required this.onViewAttractions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'artWalks',
          onPressed: onViewArtWalks,
          child: const Icon(Icons.route),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'createWalk',
          onPressed: onCreateArtWalk,
          child: const Icon(Icons.add_location),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'attractions',
          onPressed: onViewAttractions,
          child: const Icon(Icons.attractions),
        ),
      ],
    );
  }
}

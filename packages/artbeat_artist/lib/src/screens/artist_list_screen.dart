import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class ArtistListScreen extends StatelessWidget {
  const ArtistListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // No specific tab highlighted for artist list
      child: Scaffold(
        appBar: AppBar(
          // Removed 'const' to fix error
          title: const Text('Artist List'),
        ),
        body: const Center(
          child: Text('List of artists will be displayed here.'),
        ),
      ),
    );
  }
}

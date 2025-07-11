import 'package:flutter/material.dart';
import 'package:artbeat_core/src/widgets/artbeat_bottom_navigation.dart';

class ArtistListScreen extends StatelessWidget {
  const ArtistListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Removed 'const' to fix error
        title: const Text('Artist List'),
      ),
      body: const Center(
        child: Text('List of artists will be displayed here.'),
      ),
      bottomNavigationBar: const ArtbeatBottomNavigation(),
    );
  }
}

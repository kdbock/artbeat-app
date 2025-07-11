import 'package:flutter/material.dart';
import 'package:artbeat_core/src/widgets/artbeat_bottom_navigation.dart';

class CommunityDashboardScreen extends StatelessWidget {
  const CommunityDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Dashboard')),
      body: const Center(child: Text('Community content goes here.')),
      bottomNavigationBar: const ArtbeatBottomNavigation(),
    );
  }
}

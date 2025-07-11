import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class CommunityDashboardScreen extends StatelessWidget {
  const CommunityDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 3, // Community is index 3
      child: Scaffold(
        appBar: AppBar(title: const Text('Community Dashboard')),
        body: const Center(child: Text('Community content goes here.')),
      ),
    );
  }
}

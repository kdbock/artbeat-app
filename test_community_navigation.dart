// Quick test script to verify community navigation routes
import 'package:flutter/material.dart';
import 'package:artbeat_community/artbeat_community.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Community Navigation Test',
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Navigation Test')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Community Dashboard'),
            onTap: () => Navigator.pushNamed(context, '/community/dashboard'),
          ),
          ListTile(
            title: const Text('Community Feed'),
            onTap: () => Navigator.pushNamed(context, '/community/feed'),
          ),
          ListTile(
            title: const Text('Studios'),
            onTap: () => Navigator.pushNamed(context, '/community/studios'),
          ),
          ListTile(
            title: const Text('Gifts'),
            onTap: () => Navigator.pushNamed(context, '/community/gifts'),
          ),
          ListTile(
            title: const Text('Portfolios'),
            onTap: () => Navigator.pushNamed(context, '/community/portfolios'),
          ),
          ListTile(
            title: const Text('Notifications'),
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          ListTile(
            title: const Text('Settings'),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }
}

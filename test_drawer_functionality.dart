// Test script to verify drawer navigation functionality
// Run this with: flutter run test_drawer_functionality.dart

import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

void main() {
  runApp(const DrawerTestApp());
}

class DrawerTestApp extends StatelessWidget {
  const DrawerTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawer Navigation Test',
      theme: ArtbeatTheme.lightTheme,
      home: const DrawerTestScreen(),
    );
  }
}

class DrawerTestScreen extends StatelessWidget {
  const DrawerTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArtbeatAppHeader(showDrawerIcon: true),
      drawer: const ArtbeatDrawer(),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Drawer Navigation Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Look for the hamburger menu (☰) in the top-left corner',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Tap it to open the navigation drawer',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Debug test for dashboard drawer functionality
// Run this with: flutter run debug_dashboard_test.dart

import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

void main() {
  runApp(const DebugDashboardApp());
}

class DebugDashboardApp extends StatelessWidget {
  const DebugDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Debug Dashboard Test',
      theme: ArtbeatTheme.lightTheme,
      home: const DebugDashboardScreen(),
    );
  }
}

class DebugDashboardScreen extends StatelessWidget {
  const DebugDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArtbeatAppHeader(showDrawerIcon: true),
      drawer: const ArtbeatDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Debug Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('This screen should show:'),
            const SizedBox(height: 8),
            const Text('✓ Hamburger menu icon (☰) in top-left corner'),
            const Text('✓ App title "ARTbeat" in center'),
            const Text('✓ Refresh icon and profile menu in top-right'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              child: const Text('Open Drawer Manually'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debug Info:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('• showDrawerIcon: true'),
                  Text('• drawer: ArtbeatDrawer()'),
                  Text('• appBar: ArtbeatAppHeader(showDrawerIcon: true)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

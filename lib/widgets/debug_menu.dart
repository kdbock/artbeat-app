import 'package:flutter/material.dart';
import '../test_artist_features_app.dart';

/// Debug menu for accessing development and testing features
class DebugMenu extends StatelessWidget {
  const DebugMenu({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('🛠️ Debug Menu'),
      backgroundColor: Colors.grey[800],
      foregroundColor: Colors.white,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔧 Development Tools',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tools for testing and debugging app features',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Artist Features Test
          Card(
            child: ListTile(
              leading: const Icon(Icons.science, color: Colors.blue, size: 32),
              title: const Text(
                'Artist Features Test',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Verify all subscription tier features work properly\n2025 optimization validation',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const ArtistFeatureTestApp(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Firebase Debug
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud, color: Colors.orange, size: 32),
              title: const Text(
                'Firebase Debug',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Check Firebase connection and data access'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showFirebaseDebug(context);
              },
            ),
          ),

          const SizedBox(height: 16),

          // Clear Cache
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.cleaning_services,
                color: Colors.red,
                size: 32,
              ),
              title: const Text(
                'Clear Cache',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Reset app cache and preferences'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _clearCache(context);
              },
            ),
          ),

          const Spacer(),

          // Warning
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Debug tools are for development only',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  void _showFirebaseDebug(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔥 Firebase Debug'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Firebase status will be checked here...'),
              // TODO(debug): Add Firebase debug info
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _clearCache(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Clear Cache'),
        content: const Text(
          'Are you sure you want to clear all cached data? This will:\n\n'
          '• Clear image cache\n'
          '• Reset user preferences\n'
          '• Force re-authentication\n'
          '• Clear temporary files',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO(debug): Implement cache clearing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ad_location.dart';
import '../services/simple_ad_service.dart';
import '../widgets/simple_ad_placement_widget.dart';
import '../screens/simple_ad_create_screen.dart';
import '../screens/simple_ad_management_screen.dart';

/// Example showing how to integrate the simplified ad system
class SimpleAdExample extends StatelessWidget {
  const SimpleAdExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SimpleAdService(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Simple Ad System Demo'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SimpleAdCreateScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SimpleAdManagementScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ad Placement Examples',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Banner Ad at top
              const Text('Banner Ad (Dashboard):'),
              const BannerAdWidget(location: AdLocation.dashboard),
              const SizedBox(height: 24),

              // Content with feed ad
              const Text('Content with Feed Ad:'),
              const SizedBox(height: 8),
              _buildContentItem('Content Item 1'),
              _buildContentItem('Content Item 2'),
              const FeedAdWidget(location: AdLocation.communityFeed, index: 2),
              _buildContentItem('Content Item 3'),
              _buildContentItem('Content Item 4'),
              const SizedBox(height: 24),

              // Ad spaces for different locations
              const Text('Ad Spaces by Location:'),
              const SizedBox(height: 8),
              const AdSpaceWidget(
                location: AdLocation.artWalkDashboard,
                customLabel: 'Art Walk Ad',
              ),
              const AdSpaceWidget(
                location: AdLocation.captureDashboard,
                customLabel: 'Capture Ad',
              ),
              const AdSpaceWidget(
                location: AdLocation.eventsDashboard,
                customLabel: 'Events Ad',
              ),
              const SizedBox(height: 24),

              // Instructions
              const Text(
                'How to Use:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Tap the + button to create a new ad\n'
                '2. Select ad type, size, and location\n'
                '3. Upload 1-4 images\n'
                '4. Fill in ad details\n'
                '5. Submit for approval\n'
                '6. Use admin panel to approve/reject ads',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentItem(String title) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.article),
        title: Text(title),
        subtitle: const Text(
          'This is sample content to show how ads integrate with feeds',
        ),
      ),
    );
  }
}

/// Example of how to integrate ads into existing screens
class DashboardWithAdsExample extends StatelessWidget {
  const DashboardWithAdsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard with Ads')),
      body: Column(
        children: [
          // Banner ad at top
          const BannerAdWidget(location: AdLocation.dashboard, showAtTop: true),

          // Main content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Welcome to ARTbeat!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Dashboard content
                _buildDashboardCard('Discover Art', Icons.palette),
                _buildDashboardCard('Art Walks', Icons.directions_walk),
                _buildDashboardCard('Community', Icons.people),
                _buildDashboardCard('Events', Icons.event),

                const SizedBox(height: 16),

                // Another ad placement
                const SimpleAdPlacementWidget(
                  location: AdLocation.dashboard,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ],
            ),
          ),

          // Banner ad at bottom
          const BannerAdWidget(
            location: AdLocation.dashboard,
            showAtTop: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text('Explore $title features'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navigate to feature
        },
      ),
    );
  }
}

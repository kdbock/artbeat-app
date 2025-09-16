import 'package:flutter/material.dart';
import '../widgets/simple_ad_placement_widget.dart';
import '../models/ad_location.dart';

/// Example showing how to use SimpleAdPlacementWidget with animated ads
/// This demonstrates the simplified ad system with automatic image rotation
class AnimatedAdExample extends StatelessWidget {
  const AnimatedAdExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animated Ad Examples')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Banner Ad:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Banner ad placement - automatically shows ads with image rotation
            SimpleAdPlacementWidget(
              location: AdLocation.fluidDashboard,
              showIfEmpty: true,
            ),

            SizedBox(height: 32),

            Text(
              'Community Feed Ad:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Feed ad placement - automatically shows ads with image rotation
            SimpleAdPlacementWidget(
              location: AdLocation.communityInFeed,
              showIfEmpty: true,
            ),

            SizedBox(height: 32),

            Text(
              'Art Walk Dashboard Ad:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Art walk ad placement
            SimpleAdPlacementWidget(
              location: AdLocation.artWalkDashboard,
              showIfEmpty: true,
            ),

            SizedBox(height: 32),

            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How it works:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Ads with multiple images automatically rotate every 3 seconds\n'
                      '• SimpleAdPlacementWidget handles all the complexity\n'
                      '• Just specify the location where you want ads to appear\n'
                      '• Set showIfEmpty: true to show placeholder when no ads available',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

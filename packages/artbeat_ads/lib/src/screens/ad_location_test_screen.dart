import 'package:flutter/material.dart';
import 'package:artbeat_ads/artbeat_ads.dart';

/// Simple test to verify the new ad locations are working
class AdLocationTestScreen extends StatelessWidget {
  const AdLocationTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final businessService = AdBusinessService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad Location Test'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✅ Updated Ad Locations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Show all available locations
            const Text(
              'All Available Locations:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...AdLocation.values.map(
              (location) => Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(_getLocationDisplayName(location)),
                  subtitle: Text('Value: ${location.name}'),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test different user types
            const Text(
              'Available by User Type:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _buildUserTypeSection(
              'Admin',
              businessService.getAvailableLocations('admin'),
            ),
            _buildUserTypeSection(
              'Gallery',
              businessService.getAvailableLocations('gallery'),
            ),
            _buildUserTypeSection(
              'Artist',
              businessService.getAvailableLocations('artist'),
            ),
            _buildUserTypeSection(
              'User',
              businessService.getAvailableLocations('user'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeSection(String userType, List<AdLocation> locations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$userType (${locations.length} locations):',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...locations.map(
              (location) => Text(
                '  • ${_getLocationDisplayName(location)}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLocationDisplayName(AdLocation location) {
    switch (location) {
      case AdLocation.dashboard:
        return 'Main Dashboard';
      case AdLocation.artWalkDashboard:
        return 'Art Walk Dashboard';
      case AdLocation.captureDashboard:
        return 'Capture Dashboard';
      case AdLocation.communityDashboard:
        return 'Community Dashboard';
      case AdLocation.eventsDashboard:
        return 'Events Dashboard';
      case AdLocation.communityFeed:
        return 'Community Feed';
    }
  }
}

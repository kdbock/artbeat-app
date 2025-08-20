import 'package:flutter/material.dart';
import '../models/ad_location.dart' as model;

/// Quick action widget for creating ads for specific dashboard locations
class DashboardAdQuickCreateWidget extends StatelessWidget {
  final ValueChanged<model.AdLocation> onLocationSelected;

  const DashboardAdQuickCreateWidget({
    super.key,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Quick Create Dashboard Ads',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Create ads for specific dashboard placements with one click:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Dashboard placement buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionButton(
                  context,
                  'Dashboard',
                  'Main dashboard location',
                  Icons.dashboard,
                  Colors.blue,
                  model.AdLocation.dashboard,
                ),
                _buildQuickActionButton(
                  context,
                  'Art Walk Dashboard',
                  'Art walk specific location',
                  Icons.directions_walk,
                  Colors.green,
                  model.AdLocation.artWalkDashboard,
                ),
                _buildQuickActionButton(
                  context,
                  'Capture Dashboard',
                  'Camera/capture location',
                  Icons.camera_alt,
                  Colors.purple,
                  model.AdLocation.captureDashboard,
                ),
                _buildQuickActionButton(
                  context,
                  'Community Feed',
                  'Community social feed',
                  Icons.people,
                  Colors.orange,
                  model.AdLocation.communityFeed,
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Community feed button
            _buildQuickActionButton(
              context,
              'Community Feed (In-Feed)',
              'Square • Every 5 posts • 300px height',
              Icons.feed,
              Colors.red,
              model.AdLocation.communityFeed,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    model.AdLocation location, {
    bool fullWidth = false,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: () => onLocationSelected(location),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.3)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

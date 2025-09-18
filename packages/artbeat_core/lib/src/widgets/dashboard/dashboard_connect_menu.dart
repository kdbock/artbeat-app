import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class DashboardConnectMenu extends StatelessWidget {
  const DashboardConnectMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.8,
      minChildSize: 0.3,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.explore,
                    color: ArtbeatColors.primaryPurple,
                    size: 24,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Discover & Connect',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ArtbeatColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Find artists, explore art, join the community',
                          style: TextStyle(
                            fontSize: 14,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildMenuTile(
                    context: context,
                    icon: Icons.leaderboard,
                    title: 'Leaderboard',
                    subtitle: 'See top artists and community rankings',
                    color: ArtbeatColors.warning,
                    route: '/leaderboard',
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.person_search,
                    title: 'Find Artists',
                    subtitle: 'Discover local and featured artists',
                    color: ArtbeatColors.primaryPurple,
                    route: '/artist/browse',
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.palette,
                    title: 'Browse Artwork',
                    subtitle: 'Explore art collections and galleries',
                    color: ArtbeatColors.primaryGreen,
                    route: '/artwork/browse',
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.directions_walk,
                    title: 'Begin Art Walk',
                    subtitle: 'Start a new art discovery journey',
                    color: ArtbeatColors.info,
                    route: '/art-walk/create',
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.groups,
                    title: 'Community Hub',
                    subtitle: 'Connect with the art community',
                    color: ArtbeatColors.primaryPurple,
                    route: '/community/hub',
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.camera_alt,
                    title: 'Explore Art',
                    subtitle: 'View captured artwork and discoveries',
                    color: ArtbeatColors.primaryGreen,
                    route: '/captures/list',
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.event,
                    title: 'Upcoming Events',
                    subtitle: 'Art events and exhibitions near you',
                    color: ArtbeatColors.error,
                    route: '/events/list',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String route,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, route);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

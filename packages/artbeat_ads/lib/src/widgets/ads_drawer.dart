import 'package:flutter/material.dart';

/// Ads Package Specific Drawer
///
/// Contains navigation to all screens within the artbeat_ads package
class AdsDrawer extends StatelessWidget {
  const AdsDrawer({super.key});

  static const Color _headerColor = Color(0xFF7E63F3); // Ads header color
  static const Color _iconTextColor = Color(0xFF00BF63); // Text/Icon color

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(color: _headerColor),
            child: const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.campaign, size: 48, color: _iconTextColor),
                    SizedBox(height: 12),
                    Text(
                      'Ads',
                      style: TextStyle(
                        color: _iconTextColor,
                        fontFamily: 'Limelight',
                        fontSize: 24,
                        fontWeight: FontWeight.normal,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Advertisement Management',
                      style: TextStyle(
                        color: _iconTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),

                // Admin Section
                _buildSectionHeader('Admin'),
                _buildDrawerItem(
                  context,
                  icon: Icons.add_circle_outline,
                  title: 'Create Admin Ad',
                  route: '/ads/admin/create',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.rate_review,
                  title: 'Review Admin Ads',
                  route: '/ads/admin/review',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Ad Management',
                  route: '/ads/admin/management',
                ),

                const Divider(),

                // Artist Section
                _buildSectionHeader('Artist'),
                _buildDrawerItem(
                  context,
                  icon: Icons.palette,
                  title: 'Create Artist Ad',
                  route: '/ads/artist/create',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.analytics,
                  title: 'Artist Ad Status',
                  route: '/ads/artist/status',
                ),

                const Divider(),

                // Gallery Section
                _buildSectionHeader('Gallery'),
                _buildDrawerItem(
                  context,
                  icon: Icons.store,
                  title: 'Create Gallery Ad',
                  route: '/ads/gallery/create',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.assessment,
                  title: 'Gallery Ad Status',
                  route: '/ads/gallery/status',
                ),

                const Divider(),

                // User Section
                _buildSectionHeader('User'),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_add,
                  title: 'Create User Ad',
                  route: '/ads/user/create',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.preview,
                  title: 'Review User Ads',
                  route: '/ads/user/review',
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'ARTbeat Ads v1.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: _headerColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon, color: _headerColor, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        Navigator.pushNamed(context, route);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: true,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/artbeat_colors.dart';
import '../theme/artbeat_typography.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'artbeat_drawer_items.dart';
import 'user_avatar.dart';

class ArtbeatDrawer extends StatelessWidget {
  const ArtbeatDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 2.0,
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ArtbeatColors.primaryPurple,
                    ArtbeatColors.primaryGreen,
                  ],
                ),
              ),
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.userChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user == null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserAvatar(displayName: 'Guest', radius: 30),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guest User',
                              style: ArtbeatTypography.textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Not signed in',
                              style: ArtbeatTypography.textTheme.bodyMedium
                                  ?.copyWith(color: const Color(0xE6FFFFFF)),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  // Single FutureBuilder for both avatar and text to prevent state conflicts
                  return FutureBuilder<UserModel?>(
                    future: Provider.of<UserService>(
                      context,
                      listen: false,
                    ).getUserById(user.uid),
                    builder: (context, userModelSnapshot) {
                      final userModel = userModelSnapshot.data;
                      final isLoading =
                          userModelSnapshot.connectionState ==
                          ConnectionState.waiting;

                      // Use cached data or fallback during loading
                      final displayName =
                          userModel?.fullName ?? user.displayName ?? 'User';
                      final profileImageUrl = userModel?.profileImageUrl;

                      // Debug logging for drawer avatar
                      debugPrint('🗂️ Drawer UserAvatar data:');
                      debugPrint(
                        '  - userModel: ${userModel != null ? 'loaded' : (isLoading ? 'loading' : 'null')}',
                      );
                      debugPrint(
                        '  - profileImageUrl: "${profileImageUrl ?? 'null'}"',
                      );
                      debugPrint(
                        '  - fullName: "${userModel?.fullName ?? 'null'}"',
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserAvatar(
                            imageUrl: profileImageUrl,
                            displayName: displayName,
                            radius: 30,
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: ArtbeatTypography.textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email ?? '',
                                style: ArtbeatTypography.textTheme.bodyMedium
                                    ?.copyWith(color: const Color(0xE6FFFFFF)),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            // User Section
            _buildSectionHeader('User'),
            ...ArtbeatDrawerItems.userItems.map(
              (item) => _buildDrawerItem(context, item),
            ),
            const Divider(),

            // Artist Section
            _buildSectionHeader('Artist'),
            ...ArtbeatDrawerItems.artistItems.map(
              (item) => _buildDrawerItem(context, item),
            ),
            const Divider(),

            // Gallery Section
            _buildSectionHeader('Gallery'),
            ...ArtbeatDrawerItems.galleryItems.map(
              (item) => _buildDrawerItem(context, item),
            ),
            const Divider(),

            // Settings Section
            _buildSectionHeader('Settings'),
            ...ArtbeatDrawerItems.settingsItems.map(
              (item) => _buildDrawerItem(context, item),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                ArtbeatDrawerItems.signOut.icon,
                color: ArtbeatDrawerItems.signOut.color,
              ),
              title: Text(
                ArtbeatDrawerItems.signOut.title,
                style: ArtbeatTypography.textTheme.bodyMedium?.copyWith(
                  color: ArtbeatDrawerItems.signOut.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(
                    context,
                    ArtbeatDrawerItems.signOut.route,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: ArtbeatTypography.textTheme.titleSmall?.copyWith(
          color: ArtbeatColors.primaryPurple,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, ArtbeatDrawerItem item) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: item.color ?? ArtbeatColors.primaryPurple,
      ),
      title: Text(
        item.title,
        style: ArtbeatTypography.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: item.color,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (item.route != ModalRoute.of(context)?.settings.name) {
          Navigator.pushNamed(context, item.route);
        }
      },
    );
  }
}

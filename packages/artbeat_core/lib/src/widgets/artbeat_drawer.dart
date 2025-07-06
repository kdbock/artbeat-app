import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/artbeat_colors.dart';
import '../theme/artbeat_typography.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../models/user_type.dart';
import 'artbeat_drawer_items.dart';
import 'user_avatar.dart';

class ArtbeatDrawer extends StatelessWidget {
  // Cache main routes as a static set for better performance
  static final Set<String> mainRoutes = {
    '/dashboard',
    '/art-walk/dashboard',
    '/community/dashboard',
    '/events/dashboard',
    '/artist/dashboard',
    '/gallery/dashboard',
    '/profile',
    '/captures',
    '/admin/dashboard',
  };

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
              decoration: const BoxDecoration(
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
                        const UserAvatar(displayName: 'Guest', radius: 30),
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

            // Events Section
            _buildSectionHeader('Events'),
            ...ArtbeatDrawerItems.eventsItems.map(
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

            // Admin Section (only visible to admins)
            Consumer<UserService>(
              builder: (context, userService, child) {
                return FutureBuilder<UserModel?>(
                  future: userService.currentUser != null
                      ? userService.getUserById(userService.currentUser!.uid)
                      : null,
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    final isAdmin = user?.userType == UserType.admin;

                    if (!isAdmin) return const SizedBox.shrink();

                    return Column(
                      children: [
                        _buildSectionHeader('Admin'),
                        ...ArtbeatDrawerItems.adminItems.map(
                          (item) => _buildDrawerItem(context, item),
                        ),
                        const Divider(),
                      ],
                    );
                  },
                );
              },
            ),

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
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final bool isCurrentRoute = currentRoute == item.route;
    final bool isMainNavigationRoute = mainRoutes.contains(item.route);

    // Check if we're navigating within the same section
    final bool isWithinSameSection =
        currentRoute != null &&
        item.route.split('/')[1] == currentRoute.split('/')[1];

    // Wrap ListTile in Builder to ensure correct Scaffold context for SnackBar
    return Builder(
      builder: (snackBarContext) => ListTile(
        leading: Icon(
          item.icon,
          color: isCurrentRoute
              ? ArtbeatColors.primaryGreen
              : (item.color ?? ArtbeatColors.primaryPurple),
        ),
        title: Text(
          item.title,
          style: ArtbeatTypography.textTheme.bodyMedium?.copyWith(
            fontWeight: isCurrentRoute ? FontWeight.w600 : FontWeight.w500,
            color: isCurrentRoute ? ArtbeatColors.primaryGreen : item.color,
          ),
        ),
        selected: isCurrentRoute,
        onTap: () {
          // Get the current section from the route
          final String currentSection = currentRoute?.split('/')[1] ?? '';
          final String targetSection = item.route.split('/')[1];

          if (isCurrentRoute) {
            Navigator.pop(context);
            return;
          }

          Navigator.pop(context);

          try {
            if (currentSection == targetSection && !isMainNavigationRoute) {
              // For navigation within same section, preserve back stack
              Navigator.pushNamed(context, item.route);
            } else if (isMainNavigationRoute) {
              // For main navigation routes, use pushReplacement
              Navigator.pushReplacementNamed(context, item.route);
            } else {
              // Cross-section navigation
              Navigator.pushNamed(
                context,
                item.route,
                arguments: {'from': 'drawer', 'showBackButton': true},
              );
            }
          } catch (error) {
            debugPrint('⚠️ Navigation error for [38;5;208m${item.route}[0m: $error');
            ScaffoldMessenger.of(snackBarContext).showSnackBar(
              SnackBar(
                content: Text('Navigation error: ${error.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/artbeat_colors.dart';
import '../theme/artbeat_typography.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'artbeat_drawer_items.dart';
import 'user_avatar.dart';

// Define main navigation routes that should use pushReplacement
const Set<String> mainRoutes = {
  '/dashboard',
  '/community/feed',
  '/art-walk/map',
  '/events/dashboard',
  '/profile',
  '/captures',
  '/artist/dashboard',
  '/gallery/artists-management',
  '/admin/dashboard',
};

class ArtbeatDrawer extends StatefulWidget {
  const ArtbeatDrawer({super.key});

  @override
  State<ArtbeatDrawer> createState() => _ArtbeatDrawerState();
}

class _ArtbeatDrawerState extends State<ArtbeatDrawer> {
  UserModel? _cachedUserModel;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserModel();
    // Listen for auth state changes to refresh user model
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) {
      if (user != null && _cachedUserModel == null) {
        _loadUserModel();
      } else if (user == null && _cachedUserModel != null) {
        if (mounted) {
          setState(() => _cachedUserModel = null);
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserModel() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final model = await userService.getUserById(user.uid);
        if (mounted) {
          setState(() => _cachedUserModel = model);
        }
      }
    } catch (error) {
      debugPrint('Error loading user model: $error');
    }
  }

  void _handleNavigation(
    BuildContext context,
    BuildContext snackBarContext,
    String route,
    bool isMainRoute,
  ) {
    try {
      debugPrint('🔄 Navigating to: $route (isMainRoute: $isMainRoute)');
      if (isMainRoute) {
        Navigator.pushReplacementNamed(context, route);
      } else {
        Navigator.pushNamed(context, route);
      }
    } catch (error) {
      debugPrint('⚠️ Navigation error for route $route: $error');
      if (mounted) {
        ScaffoldMessenger.of(snackBarContext).showSnackBar(
          SnackBar(
            content: Text('Navigation error: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 2.0,
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      ArtbeatColors.primaryPurple.withValues(alpha: 0.15),
                      const Color(
                        0xFF4A90E2,
                      ).withValues(alpha: 0.2), // Blue accent
                      Colors.white.withValues(alpha: 0.95),
                      ArtbeatColors.primaryGreen.withValues(alpha: 0.12),
                      Colors.white,
                    ],
                    stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 4,
                      offset: const Offset(-1, -1),
                    ),
                    BoxShadow(
                      color: ArtbeatColors.primaryPurple.withValues(
                        alpha: 0.05,
                      ),
                      blurRadius: 8,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Logo on the right side
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Opacity(
                        opacity: 0.25,
                        child: Image.asset(
                          'assets/images/artbeat_logo.png',
                          width: 70,
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // User info
                    StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.userChanges(),
                      builder: (context, snapshot) {
                        final user = snapshot.data;

                        if (user == null) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 100,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const UserAvatar(
                                  displayName: 'Guest',
                                  radius: 30,
                                ),
                                const SizedBox(height: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Guest User',
                                      style: ArtbeatTypography
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: ArtbeatColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Not signed in',
                                      style: ArtbeatTypography
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: ArtbeatColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }

                        // Use cached user model to prevent repeated queries
                        final userModel = _cachedUserModel;
                        final displayName =
                            userModel?.fullName ?? user.displayName ?? 'User';
                        final profileImageUrl = userModel?.profileImageUrl;

                        return Padding(
                          padding: const EdgeInsets.only(left: 16, right: 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              UserAvatar(
                                imageUrl: profileImageUrl,
                                displayName: displayName,
                                radius: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                displayName,
                                style: ArtbeatTypography.textTheme.titleMedium
                                    ?.copyWith(
                                      color: ArtbeatColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email ?? '',
                                style: ArtbeatTypography.textTheme.bodySmall
                                    ?.copyWith(
                                      color: ArtbeatColors.textSecondary,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ), // <-- closes DrawerHeader
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

              // Ads Section
              _buildSectionHeader('Ads'),
              ...ArtbeatDrawerItems.adItems.map(
                (item) => _buildDrawerItem(context, item),
              ),
              const Divider(),

              // Admin Section
              _buildSectionHeader('Admin'),
              ...ArtbeatDrawerItems.adminItems
                  .where((item) => !item.route.contains('/ad-'))
                  .map((item) => _buildDrawerItem(context, item)),
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
                  if (mounted) {
                    setState(() => _cachedUserModel = null);
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
        onTap: () async {
          Navigator.pop(context); // Close drawer first
          if (!isCurrentRoute) {
            // Add a small delay to ensure drawer is fully closed
            await Future<void>.delayed(const Duration(milliseconds: 250));
            if (mounted) {
              _handleNavigation(
                context,
                snackBarContext,
                item.route,
                isMainNavigationRoute,
              );
            }
          }
        },
      ),
    );
  }
}

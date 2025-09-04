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
  '/events/discover',
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
      debugPrint('❌ Error loading user model: $error');
    }
  }

  void _handleNavigation(
    BuildContext context,
    BuildContext snackBarContext,
    String route,
    bool isMainRoute,
  ) {
    // List of implemented routes based on app_router.dart
    final implementedRoutes = {
      '/dashboard',
      '/profile',
      '/profile/edit',
      '/login',
      '/register',
      '/artist/dashboard',
      '/artist/onboarding',
      '/artist/profile-edit',
      '/artist/public-profile',
      '/artist/analytics',
      '/artist/artwork',
      '/artist/browse',
      '/artwork/upload',
      '/artwork/browse',
      '/gallery/artists-management',
      '/gallery/analytics',
      '/community/feed',
      '/art-walk/map',
      '/art-walk/list',
      '/art-walk/create',
      '/events/discover',
      '/admin/dashboard',
      '/admin/enhanced-dashboard',
      '/admin/user-management',
      '/admin/content-review',
      '/admin/advanced-content-management',
      '/admin/ad-management',
      '/admin/analytics',
      '/admin/financial-analytics',
      '/admin/settings',
      '/settings/account',
      '/settings/notifications',
      '/settings/privacy',
      '/settings/security',
      '/captures',
      '/achievements',
      '/favorites',
      '/support',
      '/feedback',
    };

    if (implementedRoutes.contains(route)) {
      try {
        debugPrint('🔄 Navigating to: $route (isMainRoute: $isMainRoute)');
        if (isMainRoute) {
          Navigator.pushReplacementNamed(context, route);
        } else {
          Navigator.pushNamed(context, route);
        }
      } catch (error) {
        debugPrint('⚠️ Navigation error for route $route: $error');
        _showError(snackBarContext, error.toString());
      }
    } else {
      // Show "Coming Soon" dialog for unimplemented routes
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Coming Soon'),
          content: Text('The $route feature is coming soon!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showError(BuildContext context, String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation error: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String? _getUserRole() {
    final userModel = _cachedUserModel;
    if (userModel != null) {
      // Use the proper role detection methods from UserModel
      if (userModel.isAdmin) return 'admin';
      if (userModel.isArtist) return 'artist';
      if (userModel.isGallery) return 'gallery';
      if (userModel.isModerator) return 'moderator';
    }
    return null; // Regular user
  }

  @override
  Widget build(BuildContext context) {
    final userRole = _getUserRole();
    final drawerItems = ArtbeatDrawerItems.getItemsForRole(userRole);

    return Drawer(
      backgroundColor: Colors.white,
      elevation: 2.0,
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            // Header
            _buildDrawerHeader(),

            // Navigation Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: drawerItems.length,
                itemBuilder: (context, index) {
                  final item = drawerItems[index];

                  // Add divider before sign out
                  if (item.route == '/login') {
                    return Column(
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        _buildDrawerItem(context, item),
                      ],
                    );
                  }

                  return _buildDrawerItem(context, item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      height: 140, // Increased height to accommodate content
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            ArtbeatColors.primaryPurple.withValues(alpha: 0.15),
            const Color(0xFF4A90E2).withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.95),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.12),
            Colors.white,
          ],
          stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Logo on the right side
          Positioned(
            right: 0,
            top: 8,
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/images/artbeat_logo.png',
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // User info section
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.userChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user == null) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16, right: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const UserAvatar(displayName: 'Guest', radius: 14),
                      const SizedBox(height: 4),
                      Text(
                        'Guest User',
                        style: ArtbeatTypography.textTheme.bodyMedium?.copyWith(
                          color: ArtbeatColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Not signed in',
                        style: ArtbeatTypography.textTheme.bodySmall?.copyWith(
                          color: ArtbeatColors.textSecondary,
                          fontSize: 8,
                        ),
                        maxLines: 1,
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
                padding: const EdgeInsets.only(left: 16, right: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserAvatar(
                      imageUrl: profileImageUrl,
                      displayName: displayName,
                      radius: 14,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      style: ArtbeatTypography.textTheme.bodyMedium?.copyWith(
                        color: ArtbeatColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email ?? '',
                      style: ArtbeatTypography.textTheme.bodySmall?.copyWith(
                        color: ArtbeatColors.textSecondary,
                        fontSize: 8,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    // Show user role badge if applicable
                    if (_getUserRole() != null) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ArtbeatColors.primaryPurple.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getUserRole()!.toUpperCase(),
                          style: ArtbeatTypography.textTheme.bodySmall
                              ?.copyWith(
                                color: ArtbeatColors.primaryPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 6,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
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
          // Handle sign out specially
          if (item.route == '/login' && item.title == 'Sign Out') {
            Navigator.pop(context); // Close drawer
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              setState(() => _cachedUserModel = null);
              Navigator.pushReplacementNamed(context, '/login');
            }
            return;
          }

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

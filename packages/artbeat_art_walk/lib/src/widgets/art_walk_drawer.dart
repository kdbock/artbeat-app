import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

/// Art Walk specific drawer with focused navigation for art walk features
class ArtWalkDrawer extends StatefulWidget {
  const ArtWalkDrawer({super.key});

  @override
  State<ArtWalkDrawer> createState() => _ArtWalkDrawerState();
}

class _ArtWalkDrawerState extends State<ArtWalkDrawer> {
  UserModel? _currentUser;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userService.getCurrentUserModel();
      if (mounted) {
        setState(() => _currentUser = user);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ArtWalkColors.primaryTeal.withValues(alpha: 0.05),
              Colors.white,
              ArtWalkColors.accentOrange.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header with user info
            _buildDrawerHeader(),

            // Navigation items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Quick Actions Section
                  _buildSectionHeader('Quick Actions'),
                  _buildDrawerItem(
                    context,
                    'Create Art Walk',
                    Icons.add_location,
                    '/art-walk/create',
                    ArtWalkColors.accentOrange,
                  ),
                  _buildDrawerItem(
                    context,
                    'Explore Map',
                    Icons.map,
                    '/art-walk/map',
                    ArtWalkColors.primaryTeal,
                  ),
                  _buildDrawerItem(
                    context,
                    'Browse Walks',
                    Icons.list,
                    '/art-walk/list',
                    ArtWalkColors.primaryTeal,
                  ),

                  const Divider(height: 24),

                  // My Art Walks Section
                  _buildSectionHeader('My Art Walks'),
                  _buildDrawerItem(
                    context,
                    'My Walks',
                    Icons.directions_walk,
                    '/art-walk/my-walks',
                    ArtWalkColors.primaryTeal,
                  ),
                  _buildDrawerItem(
                    context,
                    'Completed Walks',
                    Icons.check_circle,
                    '/art-walk/completed',
                    ArtWalkColors.primaryTeal,
                  ),
                  _buildDrawerItem(
                    context,
                    'Saved Walks',
                    Icons.bookmark,
                    '/art-walk/saved',
                    ArtWalkColors.primaryTeal,
                  ),

                  const Divider(height: 24),

                  // Discover Section
                  _buildSectionHeader('Discover'),
                  _buildDrawerItem(
                    context,
                    'Nearby Art',
                    Icons.location_on,
                    '/art-walk/nearby',
                    ArtWalkColors.accentOrange,
                  ),
                  _buildDrawerItem(
                    context,
                    'Popular Walks',
                    Icons.trending_up,
                    '/art-walk/popular',
                    ArtWalkColors.primaryTeal,
                  ),
                  _buildDrawerItem(
                    context,
                    'Achievements',
                    Icons.emoji_events,
                    '/art-walk/achievements',
                    ArtWalkColors.accentOrange,
                  ),

                  const Divider(height: 24),

                  // Tools Section
                  _buildSectionHeader('Tools'),
                  _buildDrawerItem(
                    context,
                    'My Captures',
                    Icons.camera_alt,
                    '/capture/public',
                    ArtWalkColors.primaryTeal,
                  ),
                  _buildDrawerItem(
                    context,
                    'Art Walk Settings',
                    Icons.settings,
                    '/art-walk/settings',
                    Colors.grey,
                  ),

                  const Divider(height: 24),

                  // General Navigation
                  _buildSectionHeader('Navigation'),
                  _buildDrawerItem(
                    context,
                    'Main Dashboard',
                    Icons.dashboard,
                    '/dashboard',
                    Colors.grey,
                  ),
                  _buildDrawerItem(
                    context,
                    'Profile',
                    Icons.person,
                    '/profile',
                    Colors.grey,
                  ),

                  const SizedBox(height: 16),

                  // Sign Out
                  _buildSignOutItem(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        _currentUser?.fullName ?? user?.displayName ?? 'Art Walker';
    final email = user?.email ?? '';

    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ArtWalkColors.primaryTeal, ArtWalkColors.primaryTealLight],
        ),
      ),
      child: Row(
        children: [
          // User Avatar
          Builder(
            builder: (context) {
              final profileImageUrl = _currentUser?.profileImageUrl;
              return CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          color: ArtWalkColors.primaryTeal,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              );
            },
          ),

          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Art Walk Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_walk,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          color: ArtWalkColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    Color color,
  ) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isCurrentRoute = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isCurrentRoute ? ArtWalkColors.accentOrange : color,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isCurrentRoute
              ? ArtWalkColors.accentOrange
              : ArtWalkColors.textPrimary,
          fontSize: 16,
          fontWeight: isCurrentRoute ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: isCurrentRoute,
      selectedTileColor: ArtWalkColors.primaryTeal.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(context); // Close drawer

        if (route == currentRoute) return;

        // Handle navigation
        if (route.startsWith('/art-walk/') || route == '/capture/public') {
          Navigator.pushNamed(context, route);
        } else {
          // For non-art-walk routes, use pushReplacement to avoid stacking
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  Widget _buildSignOutItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red, size: 24),
      title: const Text(
        'Sign Out',
        style: TextStyle(
          color: Colors.red,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () async {
        Navigator.pop(context); // Close drawer

        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/artbeat_colors.dart';

class ArtbeatDrawerItem {
  final String title;
  final IconData icon;
  final String route;
  final Color? color;
  final bool requiresAuth;
  final List<String>? requiredRoles; // null means available to all users

  const ArtbeatDrawerItem({
    required this.title,
    required this.icon,
    required this.route,
    this.color,
    this.requiresAuth = true,
    this.requiredRoles,
  });
}

class ArtbeatDrawerItems {
  // Core Navigation Items (Always Visible)
  static const dashboard = ArtbeatDrawerItem(
    title: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: '/dashboard',
  );

  static const profile = ArtbeatDrawerItem(
    title: 'My Profile',
    icon: Icons.person_outline,
    route: '/profile',
  );

  static const browseCaptures = ArtbeatDrawerItem(
    title: 'Browse Captures',
    icon: Icons.camera_alt_outlined,
    route: '/captures',
  );

  static const browseArtists = ArtbeatDrawerItem(
    title: 'Browse Artists',
    icon: Icons.people_outline,
    route: '/artist/browse',
  );

  static const browseArtwork = ArtbeatDrawerItem(
    title: 'Browse Artwork',
    icon: Icons.image_outlined,
    route: '/artwork/browse',
  );

  static const community = ArtbeatDrawerItem(
    title: 'Community',
    icon: Icons.groups_outlined,
    route: '/community/feed',
  );

  static const events = ArtbeatDrawerItem(
    title: 'Events',
    icon: Icons.event_outlined,
    route: '/events/discover',
  );

  static const artWalk = ArtbeatDrawerItem(
    title: 'Art Walk',
    icon: Icons.map_outlined,
    route: '/art-walk/map',
  );

  // Role-Specific Items

  // Artist-specific items
  static const artistDashboard = ArtbeatDrawerItem(
    title: 'Artist Dashboard',
    icon: Icons.palette_outlined,
    route: '/artist/dashboard',
    requiredRoles: ['artist'],
  );

  static const myArtwork = ArtbeatDrawerItem(
    title: 'My Artwork',
    icon: Icons.image_outlined,
    route: '/artist/artwork',
    requiredRoles: ['artist'],
  );

  static const uploadArtwork = ArtbeatDrawerItem(
    title: 'Upload Artwork',
    icon: Icons.add_photo_alternate_outlined,
    route: '/artwork/upload',
    requiredRoles: ['artist'],
  );

  static const artistAnalytics = ArtbeatDrawerItem(
    title: 'Analytics',
    icon: Icons.analytics_outlined,
    route: '/artist/analytics',
    requiredRoles: ['artist'],
  );

  // Gallery-specific items
  static const galleryDashboard = ArtbeatDrawerItem(
    title: 'Gallery Dashboard',
    icon: Icons.business_outlined,
    route: '/gallery/artists-management',
    requiredRoles: ['gallery'],
  );

  static const manageArtists = ArtbeatDrawerItem(
    title: 'Manage Artists',
    icon: Icons.manage_accounts_outlined,
    route: '/gallery/artists-management',
    requiredRoles: ['gallery'],
  );

  static const galleryAnalytics = ArtbeatDrawerItem(
    title: 'Gallery Analytics',
    icon: Icons.bar_chart_outlined,
    route: '/gallery/analytics',
    requiredRoles: ['gallery'],
  );

  // Admin-specific items
  static const adminDashboard = ArtbeatDrawerItem(
    title: 'Admin Dashboard',
    icon: Icons.admin_panel_settings,
    route: '/admin/dashboard',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const userManagement = ArtbeatDrawerItem(
    title: 'User Management',
    icon: Icons.people_alt_outlined,
    route: '/admin/user-management',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const contentModeration = ArtbeatDrawerItem(
    title: 'Content Moderation',
    icon: Icons.gavel_outlined,
    route: '/admin/content-review',
    requiredRoles: ['admin', 'moderator'],
    color: ArtbeatColors.primaryPurple,
  );

  // Moderator-specific items
  static const moderatorDashboard = ArtbeatDrawerItem(
    title: 'Moderation Dashboard',
    icon: Icons.security_outlined,
    route: '/admin/content-review',
    requiredRoles: ['moderator'],
    color: ArtbeatColors.warning,
  );

  // User-specific items
  static const editProfile = ArtbeatDrawerItem(
    title: 'Edit Profile',
    icon: Icons.edit_outlined,
    route: '/profile/edit',
  );

  static const achievements = ArtbeatDrawerItem(
    title: 'Achievements',
    icon: Icons.emoji_events_outlined,
    route: '/achievements',
  );

  static const favorites = ArtbeatDrawerItem(
    title: 'Favorites',
    icon: Icons.favorite_outline,
    route: '/favorites',
  );

  // Settings items
  static const settings = ArtbeatDrawerItem(
    title: 'Settings',
    icon: Icons.settings_outlined,
    route: '/settings/account',
  );

  static const help = ArtbeatDrawerItem(
    title: 'Help & Support',
    icon: Icons.help_outline,
    route: '/support',
  );

  // Sign out
  static const signOut = ArtbeatDrawerItem(
    title: 'Sign Out',
    icon: Icons.logout,
    route: '/login',
    color: ArtbeatColors.error,
    requiresAuth: false,
  );

  // Grouped items for different user types
  static List<ArtbeatDrawerItem> get coreItems => [
    dashboard,
    profile,
    browseCaptures,
    browseArtists,
    browseArtwork,
    community,
    events,
    artWalk,
  ];

  static List<ArtbeatDrawerItem> get userItems => [
    editProfile,
    achievements,
    favorites,
  ];

  static List<ArtbeatDrawerItem> get artistItems => [
    artistDashboard,
    myArtwork,
    uploadArtwork,
    artistAnalytics,
  ];

  static List<ArtbeatDrawerItem> get galleryItems => [
    galleryDashboard,
    manageArtists,
    galleryAnalytics,
  ];

  static List<ArtbeatDrawerItem> get adminItems => [
    adminDashboard,
    userManagement,
    contentModeration,
  ];

  static List<ArtbeatDrawerItem> get moderatorItems => [moderatorDashboard];

  static List<ArtbeatDrawerItem> get settingsItems => [settings, help];

  // Helper method to get items for a specific user role
  static List<ArtbeatDrawerItem> getItemsForRole(String? userRole) {
    final List<ArtbeatDrawerItem> items = [...coreItems];

    // Add user-specific items
    items.addAll(userItems);

    // Add role-specific items
    switch (userRole) {
      case 'artist':
        items.addAll(artistItems);
        break;
      case 'gallery':
        items.addAll(galleryItems);
        break;
      case 'admin':
        items.addAll(adminItems);
        break;
      case 'moderator':
        items.addAll(moderatorItems);
        break;
    }

    // Add settings and sign out
    items.addAll(settingsItems);
    items.add(signOut);

    return items;
  }
}

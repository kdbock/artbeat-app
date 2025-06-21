import 'package:flutter/material.dart';
import '../theme/artbeat_colors.dart';

class ArtbeatDrawerItem {
  final String title;
  final IconData icon;
  final String route;
  final Color? color;

  const ArtbeatDrawerItem({
    required this.title,
    required this.icon,
    required this.route,
    this.color,
  });
}

class ArtbeatDrawerItems {
  // User Section
  static const viewProfile = ArtbeatDrawerItem(
    title: 'View Profile',
    icon: Icons.person_outline,
    route: '/profile',
  );

  static const editProfile = ArtbeatDrawerItem(
    title: 'Edit Profile',
    icon: Icons.edit_outlined,
    route: '/profile/edit',
  );

  static const captures = ArtbeatDrawerItem(
    title: 'Captures',
    icon: Icons.camera_alt_outlined,
    route: '/captures',
  );

  static const achievements = ArtbeatDrawerItem(
    title: 'Achievements',
    icon: Icons.emoji_events_outlined,
    route: '/achievements',
  );

  static const applause = ArtbeatDrawerItem(
    title: 'Applause',
    icon: Icons.favorite_outline,
    route: '/favorites',
  );

  static const following = ArtbeatDrawerItem(
    title: 'Following',
    icon: Icons.people_outline,
    route: '/following',
  );

  // Artist Section
  static const artistDashboard = ArtbeatDrawerItem(
    title: 'Artist Dashboard',
    icon: Icons.dashboard_outlined,
    route: '/artist/dashboard',
  );

  static const editArtistProfile = ArtbeatDrawerItem(
    title: 'Edit Artist Profile',
    icon: Icons.palette_outlined,
    route: '/artist/profile/edit',
  );

  static const viewPublicProfile = ArtbeatDrawerItem(
    title: 'View Public Profile',
    icon: Icons.public_outlined,
    route: '/artist/profile/public',
  );

  static const artistAnalytics = ArtbeatDrawerItem(
    title: 'Artist Analytics',
    icon: Icons.analytics_outlined,
    route: '/artist/analytics',
  );

  static const artistApprovedAds = ArtbeatDrawerItem(
    title: 'Artist Approved Ads',
    icon: Icons.ads_click_outlined,
    route: '/artist/approved-ads',
  );

  // Gallery Section
  static const artistsManagement = ArtbeatDrawerItem(
    title: 'Artists Management',
    icon: Icons.manage_accounts_outlined,
    route: '/gallery/artists-management',
  );

  static const galleryAnalytics = ArtbeatDrawerItem(
    title: 'Gallery Analytics',
    icon: Icons.bar_chart_outlined,
    route: '/gallery/analytics',
  );

  // Settings Section
  static const accountSettings = ArtbeatDrawerItem(
    title: 'Account Settings',
    icon: Icons.account_circle_outlined,
    route: '/settings/account',
  );

  static const notificationSettings = ArtbeatDrawerItem(
    title: 'Notification Settings',
    icon: Icons.notifications_outlined,
    route: '/settings/notifications',
  );

  static const privacySettings = ArtbeatDrawerItem(
    title: 'Privacy Settings',
    icon: Icons.privacy_tip_outlined,
    route: '/settings/privacy',
  );

  static const securitySettings = ArtbeatDrawerItem(
    title: 'Security Settings',
    icon: Icons.security_outlined,
    route: '/settings/security',
  );

  static const help = ArtbeatDrawerItem(
    title: 'Help & Support',
    icon: Icons.help_outline,
    route: '/support',
  );

  // Logout
  static const signOut = ArtbeatDrawerItem(
    title: 'Sign Out',
    icon: Icons.logout,
    route: '/login',
    color: ArtbeatColors.error,
  );

  // Grouped items for drawer sections
  static List<ArtbeatDrawerItem> get userItems => [
    viewProfile,
    editProfile,
    captures,
    achievements,
    applause,
    following,
  ];

  static List<ArtbeatDrawerItem> get artistItems => [
    artistDashboard,
    editArtistProfile,
    viewPublicProfile,
    artistAnalytics,
    artistApprovedAds,
  ];

  static List<ArtbeatDrawerItem> get galleryItems => [
    artistsManagement,
    galleryAnalytics,
  ];

  static List<ArtbeatDrawerItem> get settingsItems => [
    accountSettings,
    notificationSettings,
    privacySettings,
    securitySettings,
    help,
  ];
}

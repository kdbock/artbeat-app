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
  static const home = ArtbeatDrawerItem(
    title: 'Home',
    icon: Icons.home_outlined,
    route: '/dashboard',
  );

  static const artWalks = ArtbeatDrawerItem(
    title: 'Art Walks',
    icon: Icons.map_outlined,
    route: '/art-walks',
  );

  static const community = ArtbeatDrawerItem(
    title: 'Community',
    icon: Icons.people_outline,
    route: '/community/feed',
  );

  static const artwork = ArtbeatDrawerItem(
    title: 'Artwork',
    icon: Icons.palette_outlined,
    route: '/artwork',
  );

  static const artistDashboard = ArtbeatDrawerItem(
    title: 'Artist Dashboard',
    icon: Icons.dashboard_outlined,
    route: '/artist/dashboard',
  );

  static const settings = ArtbeatDrawerItem(
    title: 'Settings',
    icon: Icons.settings_outlined,
    route: '/settings',
  );

  static const help = ArtbeatDrawerItem(
    title: 'Help & Support',
    icon: Icons.help_outline,
    route: '/support',
  );

  static const signOut = ArtbeatDrawerItem(
    title: 'Sign Out',
    icon: Icons.logout,
    route: '/login',
    color: ArtbeatColors.error,
  );

  static List<ArtbeatDrawerItem> get mainItems => [
        home,
        artWalks,
        community,
        artwork,
      ];

  static List<ArtbeatDrawerItem> get settingsItems => [
        settings,
        help,
      ];
}

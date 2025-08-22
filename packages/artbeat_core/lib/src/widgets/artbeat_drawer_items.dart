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

  static const following = ArtbeatDrawerItem(
    title: 'Following',
    icon: Icons.person_add_outlined,
    route: '/favorites',
  );

  // Artist Section
  static const artistDashboard = ArtbeatDrawerItem(
    title: 'Artist Dashboard',
    icon: Icons.dashboard_outlined,
    route: '/artist/dashboard',
  );

  static const artistFeed = ArtbeatDrawerItem(
    title: 'My Artist Feed',
    icon: Icons.dynamic_feed_outlined,
    route: '/artist/feed',
  );

  static const editArtistProfile = ArtbeatDrawerItem(
    title: 'Edit Artist Profile',
    icon: Icons.palette_outlined,
    route: '/artist/profile-edit',
  );

  static const viewPublicProfile = ArtbeatDrawerItem(
    title: 'View Public Profile',
    icon: Icons.public_outlined,
    route: '/artist/public-profile',
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

  static const myArtwork = ArtbeatDrawerItem(
    title: 'My Artwork',
    icon: Icons.image_outlined,
    route: '/artist/artwork',
  );

  static const uploadArtwork = ArtbeatDrawerItem(
    title: 'Upload Artwork',
    icon: Icons.add_photo_alternate_outlined,
    route: '/artwork/upload',
  );

  // Events Section
  static const allEvents = ArtbeatDrawerItem(
    title: 'Discover Events',
    icon: Icons.explore_outlined,
    route: '/events/discover',
  );

  static const artistEvents = ArtbeatDrawerItem(
    title: 'Artist Events',
    icon: Icons.event_outlined,
    route: '/events/artist-dashboard',
  );

  static const myTickets = ArtbeatDrawerItem(
    title: 'My Tickets',
    icon: Icons.confirmation_number_outlined,
    route: '/events/my-tickets',
  );

  static const createEvent = ArtbeatDrawerItem(
    title: 'Create Event',
    icon: Icons.event_note_outlined,
    route: '/events/create',
  );

  static const myEvents = ArtbeatDrawerItem(
    title: 'My Events',
    icon: Icons.calendar_today_outlined,
    route: '/events/my-events',
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

  static const feedback = ArtbeatDrawerItem(
    title: 'Send Feedback',
    icon: Icons.feedback_outlined,
    route: '/feedback',
  );

  // Admin Section
  static const adminDashboard = ArtbeatDrawerItem(
    title: 'Admin Dashboard',
    icon: Icons.admin_panel_settings,
    route: '/admin/dashboard',
  );

  static const adminReviewAds = ArtbeatDrawerItem(
    title: 'Review Ads',
    icon: Icons.rate_review_outlined,
    route: '/ads/management',
  );

  static const userManagement = ArtbeatDrawerItem(
    title: 'User Management',
    icon: Icons.people_alt_outlined,
    route: '/admin/users',
    color: ArtbeatColors.primaryPurple,
  );

  static const contentModeration = ArtbeatDrawerItem(
    title: 'Content Moderation',
    icon: Icons.gavel_outlined,
    route: '/admin/moderation',
    color: ArtbeatColors.primaryPurple,
  );

  static const systemSettings = ArtbeatDrawerItem(
    title: 'System Settings',
    icon: Icons.settings_applications_outlined,
    route: '/admin/settings',
    color: ArtbeatColors.primaryPurple,
  );

  // Logout
  static const signOut = ArtbeatDrawerItem(
    title: 'Sign Out',
    icon: Icons.logout,
    route: '/login',
    color: ArtbeatColors.error,
  );

  // New Simplified Ad System Items
  static const createAd = ArtbeatDrawerItem(
    title: 'Create Ad',
    icon: Icons.campaign_outlined,
    route: '/ads/create',
    color: ArtbeatColors.primaryPurple,
  );

  static const moderateAds = ArtbeatDrawerItem(
    title: 'Moderate Ads',
    icon: Icons.rate_review_outlined,
    route: '/ads/management',
    color: ArtbeatColors.warning,
  );

  static const adStatistics = ArtbeatDrawerItem(
    title: 'Ad Statistics',
    icon: Icons.analytics_outlined,
    route: '/ads/statistics',
    color: ArtbeatColors.info,
  );

  // Ad Management Items
  static final adItems = [createAd, moderateAds, adStatistics];

  // Admin items getter
  static List<ArtbeatDrawerItem> get adminItemsSection => [
    adminDashboard,
    adminReviewAds,
    userManagement,
    contentModeration,
    systemSettings,
  ];

  // Grouped items for drawer sections
  static List<ArtbeatDrawerItem> get userItems => [
    viewProfile,
    editProfile,
    captures,
    achievements,
    following,
  ];

  static List<ArtbeatDrawerItem> get artistItems => [
    artistDashboard,
    artistFeed,
    editArtistProfile,
    viewPublicProfile,
    myArtwork,
    uploadArtwork,
    artistAnalytics,
    artistApprovedAds,
  ];

  static List<ArtbeatDrawerItem> get eventsItems => [
    allEvents,
    artistEvents,
    myTickets,
    createEvent,
    myEvents,
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
    feedback,
  ];

  static List<ArtbeatDrawerItem> get adminItems => [
    adminDashboard,
    adminReviewAds,
    userManagement,
    contentModeration,
    systemSettings,
  ];
}

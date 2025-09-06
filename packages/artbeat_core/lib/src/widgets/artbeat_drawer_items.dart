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
    route: '/capture/browse',
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

  static const messaging = ArtbeatDrawerItem(
    title: 'Messages',
    icon: Icons.message_outlined,
    route: '/messaging',
    requiresAuth: true,
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

  static const artistEarnings = ArtbeatDrawerItem(
    title: 'Earnings',
    icon: Icons.account_balance_wallet_outlined,
    route: '/artist/earnings',
    requiredRoles: ['artist'],
  );

  static const advertise = ArtbeatDrawerItem(
    title: 'Advertise',
    icon: Icons.campaign,
    route: '/ads/create',
    color: ArtbeatColors.primaryGreen,
  );

  static const artistEvents = ArtbeatDrawerItem(
    title: 'My Events',
    icon: Icons.event_note_outlined,
    route: '/events/my-events',
    requiredRoles: ['artist'],
  );

  static const createEvent = ArtbeatDrawerItem(
    title: 'Create Event',
    icon: Icons.add_circle_outline,
    route: '/events/create',
    requiredRoles: ['artist'],
  );

  static const artistProfileEdit = ArtbeatDrawerItem(
    title: 'Edit Profile',
    icon: Icons.edit_outlined,
    route: '/artist/profile-edit',
    requiredRoles: ['artist'],
  );

  static const artistPublicProfile = ArtbeatDrawerItem(
    title: 'Public Profile',
    icon: Icons.person_outline,
    route: '/artist/public-profile',
    requiredRoles: ['artist'],
  );

  static const artistBrowse = ArtbeatDrawerItem(
    title: 'Browse Artists',
    icon: Icons.people_outline,
    route: '/artist/browse',
    requiredRoles: ['artist'],
  );

  static const featuredArtists = ArtbeatDrawerItem(
    title: 'Featured Artists',
    icon: Icons.star_outline,
    route: '/artist/featured',
    requiredRoles: ['artist'],
  );

  static const payoutRequest = ArtbeatDrawerItem(
    title: 'Payout Request',
    icon: Icons.request_quote_outlined,
    route: '/artist/payout-request',
    requiredRoles: ['artist'],
  );

  static const payoutAccounts = ArtbeatDrawerItem(
    title: 'Payout Accounts',
    icon: Icons.account_balance_outlined,
    route: '/artist/payout-accounts',
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

  static const galleryCommissions = ArtbeatDrawerItem(
    title: 'Commissions',
    icon: Icons.handshake_outlined,
    route: '/gallery/commissions',
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

  static const enhancedAdminDashboard = ArtbeatDrawerItem(
    title: 'Enhanced Admin',
    icon: Icons.dashboard,
    route: '/admin/enhanced-dashboard',
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

  static const advancedContentManagement = ArtbeatDrawerItem(
    title: 'Advanced Content',
    icon: Icons.manage_search,
    route: '/admin/advanced-content-management',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const adManagement = ArtbeatDrawerItem(
    title: 'Ad Management',
    icon: Icons.campaign_outlined,
    route: '/admin/ad-management',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const financialAnalytics = ArtbeatDrawerItem(
    title: 'Financial Analytics',
    icon: Icons.trending_up,
    route: '/admin/financial-analytics',
    requiredRoles: ['admin'],
    color: ArtbeatColors.primaryPurple,
  );

  static const adminSettings = ArtbeatDrawerItem(
    title: 'Admin Settings',
    icon: Icons.admin_panel_settings_outlined,
    route: '/admin/settings',
    requiredRoles: ['admin'],
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

  static const myTickets = ArtbeatDrawerItem(
    title: 'My Tickets',
    icon: Icons.local_activity_outlined,
    route: '/events/my-tickets',
  );

  static const notifications = ArtbeatDrawerItem(
    title: 'Notifications',
    icon: Icons.notifications_outlined,
    route: '/notifications',
  );

  // Enhanced feature items
  static const artWalkCreate = ArtbeatDrawerItem(
    title: 'Create Art Walk',
    icon: Icons.add_location_outlined,
    route: '/art-walk/create',
  );

  static const enhancedSearch = ArtbeatDrawerItem(
    title: 'Advanced Search',
    icon: Icons.search,
    route: '/search',
  );

  static const subscriptionPlans = ArtbeatDrawerItem(
    title: 'Subscription Plans',
    icon: Icons.card_membership_outlined,
    route: '/subscription/plans',
    requiredRoles: ['artist', 'gallery'],
  );

  static const paymentMethods = ArtbeatDrawerItem(
    title: 'Payment Methods',
    icon: Icons.payment_outlined,
    route: '/payment/methods',
    requiredRoles: ['artist', 'gallery'],
  );

  // Advertising items for artists and galleries
  static const createAd = ArtbeatDrawerItem(
    title: 'Create Ad',
    icon: Icons.campaign_outlined,
    route: '/ads/create',
    color: ArtbeatColors.primaryGreen,
    requiredRoles: ['artist', 'gallery'],
  );

  static const manageAds = ArtbeatDrawerItem(
    title: 'Manage Ads',
    icon: Icons.ads_click_outlined,
    route: '/ads/management',
    requiredRoles: ['artist', 'gallery'],
  );

  static const adStatistics = ArtbeatDrawerItem(
    title: 'Ad Statistics',
    icon: Icons.analytics_outlined,
    route: '/ads/statistics',
    requiredRoles: ['artist', 'gallery'],
  );

  static const approvedAds = ArtbeatDrawerItem(
    title: 'Approved Ads',
    icon: Icons.verified_outlined,
    route: '/artist/approved-ads',
    requiredRoles: ['artist'],
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
    advertise,
    messaging,
  ];

  static List<ArtbeatDrawerItem> get userItems => [
    editProfile,
    achievements,
    favorites,
    myTickets,
    notifications,
    artWalkCreate,
    enhancedSearch,
  ];

  static List<ArtbeatDrawerItem> get artistItems => [
    artistDashboard,
    artistProfileEdit,
    artistPublicProfile,
    myArtwork,
    uploadArtwork,
    artistAnalytics,
    artistEarnings,
    payoutRequest,
    payoutAccounts,
    advertise,
    artistEvents,
    createEvent,
    artistBrowse,
    featuredArtists,
    subscriptionPlans,
    paymentMethods,
  ];

  static List<ArtbeatDrawerItem> get galleryItems => [
    galleryDashboard,
    manageArtists,
    galleryAnalytics,
    galleryCommissions,
    advertise,
    subscriptionPlans,
    paymentMethods,
  ];

  static List<ArtbeatDrawerItem> get adminItems => [
    adminDashboard,
    enhancedAdminDashboard,
    userManagement,
    contentModeration,
    advancedContentManagement,
    adManagement,
    financialAnalytics,
    adminSettings,
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

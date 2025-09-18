import 'package:artbeat_admin/artbeat_admin.dart' as admin;
import 'package:artbeat_ads/artbeat_ads.dart' as ads;
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_auth/artbeat_auth.dart' as auth;
import 'package:artbeat_capture/artbeat_capture.dart' as capture;
import 'package:artbeat_community/artbeat_community.dart' as community;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_events/artbeat_events.dart' as events;
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;
import 'package:artbeat_profile/artbeat_profile.dart' as profile;
import 'package:artbeat_settings/artbeat_settings.dart' as settings_pkg;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../screens/in_app_purchase_demo_screen.dart';
import '../../screens/notifications_screen.dart';
import '../../test_payment_debug.dart';
import '../guards/auth_guard.dart';
import '../screens/enhanced_search_screen.dart';
import 'app_routes.dart';
import 'route_utils.dart';

/// Main application router that handles all route generation
class AppRouter {
  final _authGuard = AuthGuard();

  /// Main route generation method
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;
    if (routeName == null) {
      return RouteUtils.createNotFoundRoute();
    }

    core.AppLogger.info('🛣️ Navigating to: $routeName');

    // Check if user is authenticated for protected routes
    if (!_authGuard.isAuthenticated && _isProtectedRoute(routeName)) {
      return RouteUtils.createSimpleRoute(child: const auth.LoginScreen());
    }

    // Core routes
    switch (routeName) {
      case AppRoutes.splash:
        return RouteUtils.createSimpleRoute(child: const core.SplashScreen());

      case AppRoutes.dashboard:
        return RouteUtils.createMainNavRoute(
          currentIndex: 0,
          child: const core.ArtbeatDashboardScreen(),
        );

      case '/debug/payment':
        return RouteUtils.createSimpleRoute(child: const PaymentDebugScreen());

      case AppRoutes.login:
        return RouteUtils.createSimpleRoute(child: const auth.LoginScreen());

      case AppRoutes.register:
        return RouteUtils.createSimpleRoute(child: const auth.RegisterScreen());

      case AppRoutes.forgotPassword:
        return RouteUtils.createSimpleRoute(
          child: const auth.ForgotPasswordScreen(),
        );

      // Profile route is handled in _handleProfileRoutes method

      case AppRoutes.profileEdit:
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return RouteUtils.createMainNavRoute(
          child: profile.EditProfileScreen(userId: currentUserId),
        );

      case AppRoutes.artistDashboard:
        return RouteUtils.createMainNavRoute(
          child: const artist.ArtistDashboardScreen(),
        );

      case AppRoutes.artworkBrowse:
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkBrowseScreen(),
        );

      case AppRoutes.search:
        return RouteUtils.createMainNavRoute(
          child: const EnhancedSearchScreen(),
        );

      case AppRoutes.browse:
        return RouteUtils.createMainNavRoute(
          child: const core.FullBrowseScreen(),
        );

      case '/community/create-post':
        return RouteUtils.createMainNavRoute(
          child: const community.CreateGroupPostScreen(
            groupType: community.GroupType.artist,
            postType: 'artwork',
          ),
        );

      case '/events/create':
        return RouteUtils.createMainNavRoute(
          child: const events.CreateEventScreen(),
        );

      case AppRoutes.artistSearch:
      case AppRoutes.artistSearchShort:
        return RouteUtils.createMainNavRoute(
          child: const artist.ArtistBrowseScreen(),
        );

      case AppRoutes.trending:
        return RouteUtils.createMainNavRoute(
          child: const artist.ArtistBrowseScreen(), // Trending artists
        );

      case AppRoutes.local:
        return RouteUtils.createMainNavRoute(
          child: const events.EventsDashboardScreen(),
        );

      case AppRoutes.inAppPurchaseDemo:
        return RouteUtils.createMainNavRoute(
          child: const InAppPurchaseDemoScreen(),
        );
    }

    // Try specialized routes
    final specializedRoute = _handleSpecializedRoutes(settings);
    if (specializedRoute != null) {
      return specializedRoute;
    }

    // Route not found
    return RouteUtils.createNotFoundRoute();
  }

  bool _isProtectedRoute(String routeName) =>
      routeName != AppRoutes.splash &&
      routeName != AppRoutes.login &&
      routeName != AppRoutes.register &&
      routeName != AppRoutes.forgotPassword &&
      routeName != AppRoutes.artistSearch &&
      routeName != AppRoutes.artistSearchShort &&
      routeName != AppRoutes.trending &&
      routeName != AppRoutes.local &&
      routeName != AppRoutes.artworkBrowse &&
      !routeName.startsWith('/public/');

  /// Handles specialized routes that aren't in core handler
  Route<dynamic>? _handleSpecializedRoutes(RouteSettings settings) {
    final routeName = settings.name!;

    // Artist routes
    if (routeName.startsWith('/artist')) {
      return _handleArtistRoutes(settings);
    }

    // Artwork routes
    if (routeName.startsWith('/artwork')) {
      return _handleArtworkRoutes(settings);
    }

    // Gallery routes
    if (routeName.startsWith('/gallery')) {
      return _handleGalleryRoutes(settings);
    }

    // Commission routes
    if (routeName.startsWith('/commission')) {
      return _handleCommissionRoutes(settings);
    }

    // Community routes
    if (routeName.startsWith('/community')) {
      return _handleCommunityRoutes(settings);
    }

    // Art Walk routes
    if (routeName.startsWith('/art-walk') ||
        routeName.startsWith('/enhanced')) {
      return _handleArtWalkRoutes(settings);
    }

    // Messaging routes
    if (routeName.startsWith('/messaging')) {
      return _handleMessagingRoutes(settings);
    }

    // Events routes
    if (routeName.startsWith('/events')) {
      return _handleEventsRoutes(settings);
    }

    // Admin routes
    if (routeName.startsWith('/admin')) {
      return _handleAdminRoutes(settings);
    }

    // Profile routes
    if (routeName.startsWith('/profile')) {
      return _handleProfileRoutes(settings);
    }

    // Settings routes
    if (routeName.startsWith('/settings')) {
      return _handleSettingsRoutes(settings);
    }

    // Capture routes
    if (routeName.startsWith('/capture')) {
      return _handleCaptureRoutes(settings);
    }

    // Ad routes
    if (routeName.startsWith('/ads')) {
      return _handleAdRoutes(settings);
    }

    // Subscription routes
    if (routeName.startsWith('/subscription')) {
      return _handleSubscriptionRoutes(settings);
    }

    // Miscellaneous routes
    return _handleMiscRoutes(settings);
  }

  /// Handles artist-related routes
  Route<dynamic>? _handleArtistRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/artist/signup':
        return RouteUtils.createMainLayoutRoute(
          child: const artist.Modern2025OnboardingScreen(),
        );
      case AppRoutes.artistDashboard:
        return RouteUtils.createMainNavRoute(
          child: const artist.ArtistDashboardScreen(),
        );

      case AppRoutes.artistOnboarding:
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => core.MainLayout(
            currentIndex: -1,
            appBar: RouteUtils.createAppBar('Join as Artist'),
            child: Builder(
              builder: (context) {
                final firebaseUser = FirebaseAuth.instance.currentUser;
                if (firebaseUser == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final user = RouteUtils.createUserModelFromFirebase(
                  firebaseUser,
                );
                return artist.ArtistOnboardingScreen(
                  user: user,
                  onComplete: () => Navigator.of(context).pop(),
                );
              },
            ),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case AppRoutes.artistProfileEdit:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.ArtistProfileEditScreen(),
        );

      case AppRoutes.artistPublicProfile:
        final artistId = RouteUtils.getArgument<String>(settings, 'artistId');
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final targetUserId = artistId ?? currentUserId;

        if (targetUserId == null) {
          return RouteUtils.createErrorRoute(
            'Please log in to view your profile',
          );
        }
        return RouteUtils.createMainLayoutRoute(
          child: artist.ArtistPublicProfileScreen(userId: targetUserId),
        );

      case AppRoutes.artistAnalytics:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.AnalyticsDashboardScreen(),
        );

      case AppRoutes.artistArtwork:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.MyArtworkScreen(),
        );

      case AppRoutes.artistFeed:
        final args = settings.arguments as Map<String, dynamic>?;
        final artistUserId = args?['artistUserId'] as String?;
        if (artistUserId != null) {
          // For now, create a loading screen that will fetch the artist data
          return RouteUtils.createMainLayoutRoute(
            child: _ArtistFeedLoader(artistUserId: artistUserId),
          );
        }
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Artist not found')),
        );

      case AppRoutes.artistBrowse:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 3,
          child: const artist.ArtistBrowseScreen(),
        );

      case AppRoutes.artistEarnings:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.ArtistEarningsDashboard(),
        );

      case AppRoutes.artistPayoutRequest:
        final args = settings.arguments as Map<String, dynamic>?;
        final availableBalance = args?['availableBalance'] as double? ?? 0.0;
        final onPayoutRequested = args?['onPayoutRequested'] as VoidCallback?;
        return RouteUtils.createMainLayoutRoute(
          child: artist.PayoutRequestScreen(
            availableBalance: availableBalance,
            onPayoutRequested: onPayoutRequested ?? () {},
          ),
        );

      case AppRoutes.artistPayoutAccounts:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.PayoutAccountsScreen(),
        );

      case AppRoutes.artistFeatured:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 3,
          child: const artist.ArtistBrowseScreen(mode: 'featured'),
        );

      case AppRoutes.artistApprovedAds:
        return RouteUtils.createComingSoonRoute('Approved Ads');

      case '/artist/artwork-detail':
        final artworkId = RouteUtils.getArgument<String>(settings, 'artworkId');
        if (artworkId == null) {
          return RouteUtils.createErrorRoute('Artwork not found');
        }
        return RouteUtils.createSimpleRoute(
          child: artwork.ArtworkDetailScreen(artworkId: artworkId),
        );

      default:
        return RouteUtils.createNotFoundRoute('Artist feature');
    }
  }

  /// Handles artwork-related routes
  Route<dynamic>? _handleArtworkRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.artworkUpload:
        return RouteUtils.createMainLayoutRoute(
          child: const artwork.EnhancedArtworkUploadScreen(),
        );

      case AppRoutes.artworkBrowse:
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkBrowseScreen(),
        );

      case AppRoutes.artworkEdit:
        final artworkId = RouteUtils.getArgument<String>(settings, 'artworkId');
        final artworkModel = RouteUtils.getArgument<artwork.ArtworkModel>(
          settings,
          'artwork',
        );
        if (artworkId == null) {
          return RouteUtils.createErrorRoute('Artwork not found');
        }
        return RouteUtils.createSimpleRoute(
          child: artwork.ArtworkEditScreen(
            artworkId: artworkId,
            artwork: artworkModel,
          ),
        );

      case AppRoutes.artworkDetail:
        final artworkId = RouteUtils.getArgument<String>(settings, 'artworkId');
        if (artworkId == null) {
          return RouteUtils.createErrorRoute('Artwork not found');
        }
        return RouteUtils.createSimpleRoute(
          child: artwork.ArtworkDetailScreen(artworkId: artworkId),
        );

      case AppRoutes.artworkFeatured:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Featured Artists'),
          child: const artist.ArtistBrowseScreen(),
        );

      case AppRoutes.artworkSearch:
      case AppRoutes.artworkRecent:
      case AppRoutes.artworkTrending:
        final feature = settings.name!.split('/').last;
        return RouteUtils.createComingSoonRoute(
          '${feature[0].toUpperCase()}${feature.substring(1)} Artwork',
        );

      default:
        return RouteUtils.createNotFoundRoute('Artwork feature');
    }
  }

  /// Handles gallery-related routes
  Route<dynamic>? _handleGalleryRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.galleryArtistsManagement:
        return RouteUtils.createMainNavRoute(
          child: const artist.GalleryArtistsManagementScreen(),
        );

      case AppRoutes.galleryAnalytics:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.GalleryAnalyticsDashboardScreen(),
        );

      default:
        return RouteUtils.createNotFoundRoute('Gallery feature');
    }
  }

  /// Handles community-related routes
  Route<dynamic>? _handleCommunityRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.communityDashboard:
        return RouteUtils.createMainNavRoute(
          currentIndex: 3,
          child: const community.ArtCommunityHub(),
        );

      case AppRoutes.communityFeed:
        // Use createMainNavRoute to ensure proper MainLayout wrapping
        return RouteUtils.createMainNavRoute(
          currentIndex: 3,
          child: const community.ArtCommunityHub(),
        );

      case AppRoutes.communityArtists:
        return RouteUtils.createMainLayoutRoute(
          child: const community.PortfoliosScreen(),
        );

      case AppRoutes.communitySearch:
        return RouteUtils.createMainLayoutRoute(
          child: const EnhancedSearchScreen(),
        );

      case AppRoutes.communityPosts:
        return RouteUtils.createMainLayoutRoute(
          child: const community.ArtCommunityHub(),
        );

      case AppRoutes.communityStudios:
        return RouteUtils.createMainLayoutRoute(
          child: const community.StudiosScreen(),
        );

      case AppRoutes.communityGifts:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Gift Artists'),
          child: const community.GiftsScreen(),
        );

      case AppRoutes.communityPortfolios:
        return RouteUtils.createMainLayoutRoute(
          child: const community.PortfoliosScreen(),
        );

      case AppRoutes.communityModeration:
        return RouteUtils.createMainLayoutRoute(
          child: const community.ModerationQueueScreen(),
        );

      case AppRoutes.communitySponsorships:
        return RouteUtils.createMainLayoutRoute(
          child: const community.EnhancedSponsorshipScreen(),
        );

      case AppRoutes.communitySettings:
        return RouteUtils.createMainLayoutRoute(
          child: const community.QuietModeScreen(),
        );

      case AppRoutes.communityCreate:
        return RouteUtils.createMainLayoutRoute(
          child: const community.CreatePostScreen(),
        );

      case AppRoutes.communityMessaging:
        return RouteUtils.createMainLayoutRoute(
          child: const community.StudiosScreen(),
        );

      case AppRoutes.communityTrending:
        return RouteUtils.createMainLayoutRoute(
          child: const community.TrendingContentScreen(),
        );

      case AppRoutes.communityFeatured:
        return RouteUtils.createMainLayoutRoute(
          child: const community.ArtCommunityHub(),
        );

      case AppRoutes.community:
        // Redirect to community dashboard
        return RouteUtils.createSimpleRoute(
          child: const community.ArtCommunityHub(),
        );

      case AppRoutes.artCommunityHub:
        return RouteUtils.createMainNavRoute(
          currentIndex: 3,
          child: const community.ArtCommunityHub(),
        );

      default:
        return RouteUtils.createNotFoundRoute('Community feature');
    }
  }

  /// Handles commission-related routes
  Route<dynamic>? _handleCommissionRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/commission/request':
        final args = settings.arguments as Map<String, dynamic>?;
        final artistId = args?['artistId'] as String?;
        final artistName = args?['artistName'] as String?;

        // If no arguments provided, show the user's commission requests
        if (artistId == null || artistName == null) {
          return RouteUtils.createMainLayoutRoute(
            appBar: RouteUtils.createAppBar('My Commission Requests'),
            child: const community.DirectCommissionsScreen(),
          );
        }

        // If arguments provided, show commission request form for specific artist
        return RouteUtils.createSimpleRoute(
          child: community.CommissionRequestScreen(
            artistId: artistId,
            artistName: artistName,
          ),
        );

      case '/commission/hub':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Commission Hub'),
          child: const community.CommissionHubScreen(),
        );

      default:
        return RouteUtils.createNotFoundRoute('Commission feature');
    }
  }

  /// Handles art walk-related routes
  Route<dynamic>? _handleArtWalkRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.artWalkDashboard:
        return RouteUtils.createMainNavRoute(
          currentIndex: 1,
          child: const art_walk.ArtWalkDashboardScreen(),
        );

      case AppRoutes.artWalkMap:
        return RouteUtils.createSimpleRoute(
          child: const art_walk.ArtWalkMapScreen(),
        );

      case AppRoutes.artWalkList:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.ArtWalkListScreen(),
        );

      case AppRoutes.artWalkDetail:
        final walkId = RouteUtils.getArgument<String>(settings, 'walkId');
        if (walkId == null) {
          return RouteUtils.createErrorRoute('Art walk not found');
        }
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: art_walk.ArtWalkDetailScreen(walkId: walkId),
        );

      case AppRoutes.artWalkCreate:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.EnhancedArtWalkCreateScreen(),
        );

      case AppRoutes.enhancedArtWalkExperience:
        final walkId = RouteUtils.getArgument<String>(settings, 'walkId');
        if (walkId == null) {
          return RouteUtils.createErrorRoute('Art walk ID is required');
        }
        // For now, create a placeholder - the screen will load the art walk data
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: art_walk.EnhancedArtWalkExperienceScreen(
            artWalkId: walkId,
            artWalk: art_walk.ArtWalkModel(
              id: walkId,
              title: 'Loading...',
              description: '',
              userId: '',
              artworkIds: [],
              createdAt: DateTime.now(),
            ),
          ),
        );

      case AppRoutes.artWalkSearch:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Art Walk Search - Coming Soon')),
        );

      case AppRoutes.artWalkExplore:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Explore Art Walks - Coming Soon')),
        );

      case AppRoutes.artWalkStart:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Start Art Walk - Coming Soon')),
        );

      case AppRoutes.artWalkNearby:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Nearby Art Walks - Coming Soon')),
        );

      case AppRoutes.artWalkMyWalks:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.EnhancedMyArtWalksScreen(),
        );

      case AppRoutes.artWalkMyCaptures:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.MyCapturesScreen(),
        );

      case AppRoutes.artWalkCompleted:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Completed Art Walks - Coming Soon')),
        );

      case AppRoutes.artWalkSaved:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Saved Art Walks - Coming Soon')),
        );

      case AppRoutes.artWalkPopular:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Popular Art Walks - Coming Soon')),
        );

      case AppRoutes.artWalkAchievements:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(
            child: Text('Art Walk Achievements - Coming Soon'),
          ),
        );

      case AppRoutes.artWalkSettings:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Art Walk Settings - Coming Soon')),
        );

      default:
        return RouteUtils.createNotFoundRoute('Art Walk feature');
    }
  }

  /// Handles messaging-related routes
  Route<dynamic>? _handleMessagingRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.messaging:
        return RouteUtils.createMainLayoutRoute(
          child: const messaging.ArtisticMessagingScreen(),
        );

      case AppRoutes.messagingNew:
        return RouteUtils.createMainLayoutRoute(
          child: const messaging.ContactSelectionScreen(),
        );

      case AppRoutes.messagingChat:
        final args = settings.arguments as Map<String, dynamic>?;
        final chat = args?['chat'] as messaging.ChatModel?;
        if (chat != null) {
          return RouteUtils.createMainLayoutRoute(
            child: messaging.ChatScreen(chat: chat),
          );
        }
        return RouteUtils.createNotFoundRoute('Chat not found');

      case AppRoutes.messagingUserChat:
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String?;
        if (userId != null && userId.isNotEmpty) {
          // Create a temporary screen that will handle the chat creation
          return RouteUtils.createMainLayoutRoute(
            child: _UserChatLoader(userId: userId),
          );
        }
        return RouteUtils.createNotFoundRoute('User chat not found');

      default:
        return RouteUtils.createNotFoundRoute('Messaging feature');
    }
  }

  /// Handles events-related routes
  Route<dynamic>? _handleEventsRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.events:
      case AppRoutes.eventsDiscover:
      case AppRoutes.eventsDashboard:
      case AppRoutes.eventsArtistDashboard:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 4,
          appBar: const PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight + 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE74C3C), // Red
                    Color(0xFF3498DB), // Light Blue
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: core.EnhancedUniversalHeader(
                title: 'Events',
                titleGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE74C3C), // Red
                    Color(0xFF3498DB), // Light Blue
                  ],
                ),
              ),
            ),
          ),
          drawer: const events.EventsDrawer(),
          child: const events.EventsDashboardScreen(),
        );

      case AppRoutes.eventsCreate:
        return RouteUtils.createMainLayoutRoute(
          drawer: const events.EventsDrawer(),
          child: const events.CreateEventScreen(),
        );

      case AppRoutes.myEvents:
        return RouteUtils.createMainLayoutRoute(
          drawer: const events.EventsDrawer(),
          child: const events.UserEventsDashboardScreen(),
        );

      case AppRoutes.myTickets:
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return RouteUtils.createSimpleRoute(
          child: events.MyTicketsScreen(userId: currentUserId),
        );

      case AppRoutes.eventsDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        if (eventId != null) {
          return RouteUtils.createMainLayoutRoute(
            drawer: const events.EventsDrawer(),
            child: events.EventDetailsScreen(eventId: eventId),
          );
        }
        return RouteUtils.createNotFoundRoute();

      default:
        return RouteUtils.createComingSoonRoute('Events');
    }
  }

  /// Handles admin-related routes
  Route<dynamic>? _handleAdminRoutes(RouteSettings settings) {
    // First try to use the admin package's route generator
    final adminRoute = admin.AdminRoutes.generateRoute(settings);
    if (adminRoute != null) {
      return adminRoute;
    }

    // Fallback for admin routes not handled by the admin package
    switch (settings.name) {
      case AppRoutes.adminCoupons:
        return RouteUtils.createMainLayoutRoute(
          child: const core.CouponManagementScreen(),
        );

      case AppRoutes.adminCouponManagement:
      case AppRoutes.adminUsers:
      case AppRoutes.adminModeration:
      case '/admin/enhanced-dashboard':
      case '/admin/financial-analytics':
      case '/admin/content-management-suite':
      case '/admin/advanced-content-management':
        // All admin routes now redirect to the modern unified dashboard
        return RouteUtils.createSimpleRoute(
          child: const admin.ModernUnifiedAdminDashboard(),
        );

      default:
        return RouteUtils.createComingSoonRoute('Admin feature');
    }
  }

  /// Handles settings-related routes
  Route<dynamic>? _handleSettingsRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.settings:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Settings'),
          child: const settings_pkg.SettingsScreen(),
        );

      case AppRoutes.settingsAccount:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Account Settings'),
          child: const settings_pkg.AccountSettingsScreen(),
        );

      case AppRoutes.settingsNotifications:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Notification Settings'),
          child: const settings_pkg.NotificationSettingsScreen(),
        );

      case AppRoutes.settingsPrivacy:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Privacy Settings'),
          child: const settings_pkg.PrivacySettingsScreen(),
        );

      case AppRoutes.securitySettings:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Security Settings'),
          child: const settings_pkg.SecuritySettingsScreen(),
        );

      case AppRoutes.paymentSettings:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Payment Settings'),
          child: const artist.PaymentMethodsScreen(),
        );

      default:
        // Handle blocked users and other dynamic routes
        if (settings.name == '/settings/blocked-users') {
          return RouteUtils.createMainLayoutRoute(
            appBar: RouteUtils.createAppBar('Blocked Users'),
            child: const settings_pkg.BlockedUsersScreen(),
          );
        }

        final feature = settings.name!.split('/').last;
        return RouteUtils.createComingSoonRoute(
          '${feature[0].toUpperCase()}${feature.substring(1)} Settings',
        );
    }
  }

  /// Handles profile-related routes
  Route<dynamic>? _handleProfileRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/profile':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Profile not available')),
              );
            }

            // Check if a specific userId was provided in arguments
            final args = settings.arguments as Map<String, dynamic>?;
            final targetUserId = args?['userId'] as String? ?? currentUser.uid;
            final isCurrentUser = targetUserId == currentUser.uid;

            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar(
                isCurrentUser ? 'Profile' : 'User Profile',
              ),
              child: profile.ProfileViewScreen(
                userId: targetUserId,
                isCurrentUser: isCurrentUser,
              ),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/edit':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Profile edit not available')),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Edit Profile'),
              child: profile.EditProfileScreen(
                userId: currentUser.uid,
                onProfileUpdated: () {
                  // Handle profile update if needed
                },
              ),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/picture':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final args = settings.arguments as Map<String, dynamic>?;
            final imageUrl = args?['imageUrl'] as String? ?? '';
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Profile Picture'),
              child: profile.ProfilePictureViewerScreen(imageUrl: imageUrl),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/connections':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => core.MainLayout(
            currentIndex: -1,
            appBar: RouteUtils.createAppBar('Connections'),
            child: const profile.ProfileConnectionsScreen(),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/activity':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => core.MainLayout(
            currentIndex: -1,
            appBar: RouteUtils.createAppBar('Activity History'),
            child: const profile.ProfileActivityScreen(),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/analytics':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => core.MainLayout(
            currentIndex: -1,
            appBar: RouteUtils.createAppBar('Profile Analytics'),
            child: const profile.ProfileAnalyticsScreen(),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/achievements':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => core.MainLayout(
            currentIndex: -1,
            appBar: RouteUtils.createAppBar('Achievements'),
            child: const profile.AchievementsScreen(),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/following':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Following not available')),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Following'),
              child: profile.FollowingListScreen(userId: currentUser.uid),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/followers':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Followers not available')),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Followers'),
              child: profile.FollowersListScreen(userId: currentUser.uid),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      default:
        return RouteUtils.createComingSoonRoute('Profile feature');
    }
  }

  /// Handles capture-related routes
  Route<dynamic>? _handleCaptureRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.captures:
        return RouteUtils.createMainNavRoute(
          currentIndex: 2,
          child: const capture.EnhancedCaptureDashboardScreen(),
        );

      case AppRoutes.captureCamera:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.BasicCaptureScreen(),
        );

      case '/capture/smart':
        return RouteUtils.createMainNavRoute(
          currentIndex: 2,
          child: const capture.SmartCaptureScreen(),
        );

      case AppRoutes.captureDashboard:
        return RouteUtils.createMainNavRoute(
          currentIndex: 2,
          child: const capture.EnhancedCaptureDashboardScreen(),
        );

      case AppRoutes.captureSearch:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CaptureSearchScreen(),
        );

      case AppRoutes.captureNearby:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CapturesListScreen(),
        );

      case AppRoutes.capturePopular:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CapturesListScreen(),
        );

      case AppRoutes.captureMyCaptures:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.MyCapturesScreen(),
        );

      case AppRoutes.capturePending:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.MyCapturesScreen(),
        );

      case AppRoutes.captureMap:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Capture Map - Coming Soon')),
        );

      case AppRoutes.captureBrowse:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CapturesListScreen(),
        );

      case AppRoutes.captureApproved:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.MyCapturesScreen(),
        );

      case AppRoutes.captureSettings:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Capture Settings - Coming Soon')),
        );

      case AppRoutes.captureAdminModeration:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.AdminContentModerationScreen(),
        );

      case AppRoutes.captureGallery:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CapturesListScreen(),
        );

      case AppRoutes.captureEdit:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Edit Capture - Coming Soon')),
        );

      case AppRoutes.captureCreate:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CameraCaptureScreen(),
        );

      case AppRoutes.capturePublic:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CapturesListScreen(),
        );

      case AppRoutes.captureDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final captureId = args?['captureId'] as String?;
        if (captureId == null) {
          return RouteUtils.createNotFoundRoute('Capture ID required');
        }
        return RouteUtils.createMainLayoutRoute(
          child: capture.CaptureDetailWrapperScreen(captureId: captureId),
        );

      default:
        return RouteUtils.createNotFoundRoute('Capture feature');
    }
  }

  /// Handles ad-related routes
  Route<dynamic>? _handleAdRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.adsCreate:
        return RouteUtils.createSimpleRoute(
          child: const ads.AdEducationDashboard(),
        );

      case AppRoutes.adsManagement:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Ad Management'),
          child: const ads.SimpleAdManagementScreen(),
        );

      case AppRoutes.adsStatistics:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Ad Performance'),
          child: const ads.SimpleAdStatisticsScreen(),
        );

      case AppRoutes.adPayment:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Ad Payment'),
          child: const Center(child: Text('Ad Payment - Coming Soon')),
        );

      default:
        return RouteUtils.createNotFoundRoute('Ad feature');
    }
  }

  /// Handles subscription-related routes
  Route<dynamic>? _handleSubscriptionRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.subscriptionComparison:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SubscriptionPurchaseScreen(
            tier: core.SubscriptionTier.starter,
          ),
        );

      case AppRoutes.subscriptionPlans:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Subscription Plans'),
          child: const core.SimpleSubscriptionPlansScreen(),
        );

      case AppRoutes.paymentMethods:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Payment Methods'),
          child: const artist.PaymentMethodsScreen(),
        );

      case AppRoutes.paymentScreen:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Payment Screen'),
          child: const artist.PaymentMethodsScreen(),
        );

      case AppRoutes.paymentRefund:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Refunds'),
          child: const Center(child: Text('Refund management coming soon')),
        );

      default:
        return RouteUtils.createNotFoundRoute('Subscription feature');
    }
  }

  /// Handles miscellaneous routes
  Route<dynamic>? _handleMiscRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.achievements:
        return RouteUtils.createMainLayoutRoute(
          child: const profile.AchievementsScreen(),
        );

      case AppRoutes.achievementsInfo:
        return RouteUtils.createMainLayoutRoute(
          child: const profile.AchievementInfoScreen(),
        );

      case AppRoutes.leaderboard:
        return RouteUtils.createMainLayoutRoute(
          child: const core.LeaderboardScreen(),
        );

      case AppRoutes.notifications:
        return RouteUtils.createSimpleRoute(child: const NotificationsScreen());

      case AppRoutes.search:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Search'),
          child: const EnhancedSearchScreen(),
        );

      case AppRoutes.searchResults:
        final searchArgs = settings.arguments as Map<String, dynamic>;
        final searchQuery = searchArgs['query'] as String;
        return RouteUtils.createMainLayoutRoute(
          child: core.SearchResultsScreen(query: searchQuery),
        );

      case AppRoutes.feedback:
        return RouteUtils.createMainLayoutRoute(
          child: const core.FeedbackForm(),
        );

      case AppRoutes.developerFeedbackAdmin:
        return RouteUtils.createMainLayoutRoute(
          child: const core.DeveloperFeedbackAdminScreen(),
        );

      case AppRoutes.systemInfo:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('System Info - Coming Soon')),
        );

      case AppRoutes.support:
      case '/help':
        return RouteUtils.createMainLayoutRoute(
          child: const core.HelpSupportScreen(),
        );

      case '/favorites':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Favorites not available')),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Favorites'),
              child: profile.FavoritesScreen(userId: currentUser.uid),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/rewards':
        return RouteUtils.createComingSoonRoute('Rewards');

      case '/billing':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Billing & Payments'),
          child: const artist.PaymentMethodsScreen(),
        );

      case '/about':
        return RouteUtils.createComingSoonRoute('About ARTbeat');

      default:
        // Fallback to splash screen for unknown routes
        return RouteUtils.createMainLayoutRoute(
          child: const core.SplashScreen(),
        );
    }
  }
}

/// Widget that loads artist profile data and then shows the artist feed
class _ArtistFeedLoader extends StatefulWidget {
  const _ArtistFeedLoader({required this.artistUserId});
  final String artistUserId;

  @override
  State<_ArtistFeedLoader> createState() => _ArtistFeedLoaderState();
}

class _ArtistFeedLoaderState extends State<_ArtistFeedLoader> {
  core.ArtistProfileModel? _artistProfile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArtistProfile();
  }

  Future<void> _loadArtistProfile() async {
    try {
      setState(() => _isLoading = true);

      // Try to get artist profile from artistProfiles collection
      final artistDoc = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .where('userId', isEqualTo: widget.artistUserId)
          .limit(1)
          .get();

      if (artistDoc.docs.isNotEmpty) {
        _artistProfile = core.ArtistProfileModel.fromFirestore(
          artistDoc.docs.first,
        );
      } else {
        // If no artist profile found, try to get basic user info
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.artistUserId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          _artistProfile = core.ArtistProfileModel(
            id: widget.artistUserId,
            userId: widget.artistUserId,
            displayName:
                (userData['displayName'] as String?) ?? 'Unknown Artist',
            bio: userData['bio'] as String?,
            profileImageUrl: userData['profileImageUrl'] as String?,
            location: userData['location'] as String?,
            userType: core.UserType.artist,
            createdAt:
                (userData['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            updatedAt:
                (userData['updatedAt'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            mediums: [],
            styles: [],
          );
        } else {
          _error = 'Artist not found';
        }
      }
    } on Exception catch (e) {
      _error = 'Failed to load artist: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadArtistProfile,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_artistProfile == null) {
      return const Scaffold(body: Center(child: Text('Artist not found')));
    }

    return community.ArtistCommunityFeedScreen(artist: _artistProfile!);
  }
}

/// Temporary widget to handle user chat navigation
class _UserChatLoader extends StatefulWidget {
  const _UserChatLoader({required this.userId});
  final String userId;

  @override
  State<_UserChatLoader> createState() => _UserChatLoaderState();
}

class _UserChatLoaderState extends State<_UserChatLoader> {
  @override
  void initState() {
    super.initState();
    _navigateToChat();
  }

  Future<void> _navigateToChat() async {
    try {
      // Use the MessagingNavigationHelper to navigate to the chat
      await messaging.MessagingNavigationHelper.navigateToUserChat(
        context,
        widget.userId,
      );

      // Navigation is now using pushReplacementNamed, so we don't need to pop
      // The loader screen will be replaced by the chat screen
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

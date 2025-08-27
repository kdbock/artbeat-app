import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_auth/artbeat_auth.dart' as auth;
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_profile/artbeat_profile.dart' as profile;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_events/artbeat_events.dart' as events;
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;

import '../guards/auth_guard.dart';
import '../screens/enhanced_search_screen.dart';
import '../../screens/notifications_screen.dart';
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

    debugPrint('🛣️ Navigating to: $routeName');

    // Check if user is authenticated for protected routes
    if (!_authGuard.isAuthenticated && _isProtectedRoute(routeName)) {
      return RouteUtils.createSimpleRoute(child: const auth.LoginScreen());
    }

    // Core routes
    switch (routeName) {
      case AppRoutes.dashboard:
        return RouteUtils.createSimpleRoute(
          child: const core.FluidDashboardScreen(),
        );

      case AppRoutes.login:
        return RouteUtils.createSimpleRoute(child: const auth.LoginScreen());

      case AppRoutes.register:
        return RouteUtils.createSimpleRoute(child: const auth.RegisterScreen());

      case AppRoutes.forgotPassword:
        return RouteUtils.createSimpleRoute(
          child: const auth.ForgotPasswordScreen(),
        );

      case AppRoutes.profile:
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return RouteUtils.createMainNavRoute(
          currentIndex: -1,
          child: profile.ProfileViewScreen(
            userId: currentUserId,
            isCurrentUser: true,
          ),
        );

      case AppRoutes.profileEdit:
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return RouteUtils.createMainNavRoute(
          currentIndex: -1,
          child: profile.EditProfileScreen(userId: currentUserId),
        );

      case AppRoutes.artistDashboard:
        return RouteUtils.createMainNavRoute(
          currentIndex: -1,
          child: const artist.ArtistDashboardScreen(),
        );

      case AppRoutes.artworkBrowse:
        return RouteUtils.createMainNavRoute(
          currentIndex: -1,
          child: const artwork.ArtworkBrowseScreen(),
        );

      case AppRoutes.search:
        return RouteUtils.createMainNavRoute(
          currentIndex: -1,
          child: const EnhancedSearchScreen(),
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

  bool _isProtectedRoute(String routeName) {
    return routeName != AppRoutes.login &&
        routeName != AppRoutes.register &&
        routeName != AppRoutes.forgotPassword &&
        !routeName.startsWith('/public/');
  }

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
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Artist Feed - Coming Soon')),
        );

      case AppRoutes.artistBrowse:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 3,
          child: const artist.ArtistBrowseScreen(),
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
        return RouteUtils.createMainLayoutRoute(
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
        return RouteUtils.createSimpleRoute(
          child: const Center(child: Text('Community Dashboard - Coming Soon')),
        );

      case AppRoutes.communityFeed:
        return RouteUtils.createMainNavRoute(
          currentIndex: 2,
          child: const Center(child: Text('Community Feed - Coming Soon')),
        );

      case AppRoutes.communityArtists:
        return RouteUtils.createSimpleRoute(
          child: const Center(child: Text('Community Artists - Coming Soon')),
        );

      case AppRoutes.communitySearch:
        return RouteUtils.createMainLayoutRoute(
          child: const EnhancedSearchScreen(),
        );

      case AppRoutes.communityPosts:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Community Posts - Coming Soon')),
        );

      case AppRoutes.communityStudios:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Studios - Coming Soon')),
        );

      case AppRoutes.communityGifts:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Gifts - Coming Soon')),
        );

      case AppRoutes.communityPortfolios:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Portfolios - Coming Soon')),
        );

      case AppRoutes.communityModeration:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Moderation - Coming Soon')),
        );

      case AppRoutes.communitySponsorships:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Sponsorships - Coming Soon')),
        );

      case AppRoutes.communitySettings:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Community Settings - Coming Soon')),
        );

      default:
        return RouteUtils.createNotFoundRoute('Community feature');
    }
  }

  /// Handles art walk-related routes
  Route<dynamic>? _handleArtWalkRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.artWalkDashboard:
        return RouteUtils.createSimpleRoute(
          child: const art_walk.ArtWalkDashboardScreen(),
        );

      case AppRoutes.artWalkMap:
        return RouteUtils.createSimpleRoute(
          child: const Center(child: Text('Art Walk Map - Coming Soon')),
        );

      case AppRoutes.artWalkList:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Art Walk List - Coming Soon')),
        );

      case AppRoutes.artWalkDetail:
        final walkId = RouteUtils.getArgument<String>(settings, 'walkId');
        if (walkId == null) {
          return RouteUtils.createErrorRoute('Art walk not found');
        }
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Art Walk Detail - Coming Soon')),
        );

      case AppRoutes.artWalkCreate:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Create Art Walk - Coming Soon')),
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
          child: const Center(child: Text('Messaging - Coming Soon')),
        );

      case AppRoutes.messagingNew:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('New Message - Coming Soon')),
        );

      case AppRoutes.messagingChat:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Chat - Coming Soon')),
        );

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
        return RouteUtils.createMainNavRoute(
          child: const events.EventsDashboardScreen(),
        );

      case AppRoutes.eventsCreate:
        return RouteUtils.createMainLayoutRoute(
          child: const events.CreateEventScreen(),
        );

      default:
        return RouteUtils.createComingSoonRoute('Events');
    }
  }

  /// Handles admin-related routes
  Route<dynamic>? _handleAdminRoutes(RouteSettings settings) {
    // Fallback for admin routes
    switch (settings.name) {
      case AppRoutes.adminDashboard:
        return RouteUtils.createSimpleRoute(
          child: const Center(child: Text('Admin Dashboard - Coming Soon')),
        );

      case AppRoutes.adminUsers:
        return RouteUtils.createSimpleRoute(
          child: const Center(child: Text('User Management - Coming Soon')),
        );

      case AppRoutes.adminModeration:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Content Moderation - Coming Soon')),
        );

      default:
        return RouteUtils.createComingSoonRoute('Admin feature');
    }
  }

  /// Handles settings-related routes
  Route<dynamic>? _handleSettingsRoutes(RouteSettings settings) {
    final feature = settings.name!.split('/').last;
    return RouteUtils.createComingSoonRoute(
      '${feature[0].toUpperCase()}${feature.substring(1)} Settings',
    );
  }

  /// Handles capture-related routes
  Route<dynamic>? _handleCaptureRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.captures:
        return RouteUtils.createMainNavRoute(
          child: const Center(child: Text('My Captures - Coming Soon')),
        );

      case AppRoutes.captureCamera:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Camera Capture - Coming Soon')),
        );

      case AppRoutes.captureDashboard:
        return RouteUtils.createSimpleRoute(
          child: const Center(child: Text('Capture Dashboard - Coming Soon')),
        );

      default:
        return RouteUtils.createNotFoundRoute('Capture feature');
    }
  }

  /// Handles ad-related routes
  Route<dynamic>? _handleAdRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.adsCreate:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Create Ad'),
          child: const Center(child: Text('Create Ad - Coming Soon')),
        );

      case AppRoutes.adsManagement:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Ad Management'),
          child: const Center(child: Text('Ad Management - Coming Soon')),
        );

      case AppRoutes.adsStatistics:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Ad Statistics'),
          child: const Center(child: Text('Ad Statistics - Coming Soon')),
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

      default:
        // Fallback to splash screen for unknown routes
        return RouteUtils.createMainLayoutRoute(
          child: const core.SplashScreen(),
        );
    }
  }
}

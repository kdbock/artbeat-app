import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_auth/artbeat_auth.dart' as auth;
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_profile/artbeat_profile.dart' as profile;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_events/artbeat_events.dart' as events;
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_capture/artbeat_capture.dart' as capture;
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;

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
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkBrowseScreen(),
        );

      case AppRoutes.search:
        return RouteUtils.createMainNavRoute(
          currentIndex: -1,
          child: const EnhancedSearchScreen(),
        );

      case AppRoutes.artistSearch:
      case AppRoutes.artistSearchShort:
        return RouteUtils.createMainNavRoute(
          currentIndex: -1,
          child: const artist.ArtistBrowseScreen(),
        );

      case AppRoutes.trending:
        return RouteUtils.createMainNavRoute(
          currentIndex: -1,
          child: const artist.ArtistBrowseScreen(), // Trending artists
        );

      case AppRoutes.local:
        return RouteUtils.createMainNavRoute(
          currentIndex: -1,
          child: const events.EventsDashboardScreen(),
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
        routeName != AppRoutes.artistSearch &&
        routeName != AppRoutes.artistSearchShort &&
        routeName != AppRoutes.trending &&
        routeName != AppRoutes.local &&
        routeName != AppRoutes.artworkBrowse &&
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
      case '/artist/signup':
        return RouteUtils.createMainLayoutRoute(
          child: artist.Modern2025OnboardingScreen(),
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
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Artist Feed - Coming Soon')),
        );

      case AppRoutes.artistBrowse:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 3,
          child: const artist.ArtistBrowseScreen(),
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
          appBar: const core.EnhancedUniversalHeader(title: 'Community Canvas'),
          child: const CommunityDashboardScreen(),
        );

      case AppRoutes.communityFeed:
        // Use createMainNavRoute to ensure proper MainLayout wrapping
        return RouteUtils.createMainNavRoute(
          currentIndex: 3,
          appBar: const core.EnhancedUniversalHeader(
            title: 'Community Feed',
            showBackButton: false,
            showSearch: true,
            showDeveloperTools: true,
          ),
          child: UnifiedCommunityFeed(
            scrollToPostId: settings.arguments is Map<String, dynamic>
                ? (settings.arguments as Map<String, dynamic>)['scrollToPostId']
                      as String?
                : null,
          ),
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

      case AppRoutes.communityCreate:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(
            child: Text('Create Community Post - Coming Soon'),
          ),
        );

      case AppRoutes.communityMessaging:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Community Messaging - Coming Soon')),
        );

      case AppRoutes.communityTrending:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Trending Posts - Coming Soon')),
        );

      case AppRoutes.communityFeatured:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Featured Posts - Coming Soon')),
        );

      case AppRoutes.community:
        // Redirect to community dashboard
        return RouteUtils.createSimpleRoute(
          child: const CommunityDashboardScreen(),
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
          child: const art_walk.CreateArtWalkScreen(),
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
        return RouteUtils.createSimpleRoute(
          child: const events.EventsDashboardScreen(),
        );

      case AppRoutes.eventsCreate:
        return RouteUtils.createMainLayoutRoute(
          child: const events.CreateEventScreen(),
        );

      case AppRoutes.eventsDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        if (eventId != null) {
          return RouteUtils.createSimpleRoute(
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
          child: const capture.EnhancedCaptureDashboardScreen(),
        );

      case AppRoutes.captureSearch:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CaptureSearchScreen(),
        );

      case AppRoutes.captureNearby:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Nearby Captures - Coming Soon')),
        );

      case AppRoutes.capturePopular:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Popular Captures - Coming Soon')),
        );

      case AppRoutes.captureMyCaptures:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('My Captures - Coming Soon')),
        );

      case AppRoutes.captureMap:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Capture Map - Coming Soon')),
        );

      case AppRoutes.captureGallery:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Capture Gallery - Coming Soon')),
        );

      case AppRoutes.captureEdit:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Edit Capture - Coming Soon')),
        );

      case AppRoutes.captureCreate:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Create Capture - Coming Soon')),
        );

      case AppRoutes.capturePublic:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CapturesListScreen(),
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

      case AppRoutes.systemInfo:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('System Info - Coming Soon')),
        );

      default:
        // Fallback to splash screen for unknown routes
        return RouteUtils.createMainLayoutRoute(
          child: const core.SplashScreen(),
        );
    }
  }
}

/// Temporary widget to handle user chat navigation
class _UserChatLoader extends StatefulWidget {
  final String userId;

  const _UserChatLoader({required this.userId});

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
    } catch (e) {
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
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

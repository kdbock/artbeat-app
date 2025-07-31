import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_events/artbeat_events.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_profile/artbeat_profile.dart';
import 'package:artbeat_artist/artbeat_artist.dart';
import 'package:artbeat_artist/src/screens/artist_list_screen.dart';
import 'package:artbeat_ads/artbeat_ads.dart' as ads;
import 'package:artbeat_capture/artbeat_capture.dart' as capture;
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;

import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_admin/artbeat_admin.dart' as admin;

import 'widgets/developer_menu.dart';
import 'debug_profile_fix.dart';
import 'src/widgets/error_boundary.dart';
import 'src/services/firebase_initializer.dart';
import 'src/guards/auth_guard.dart';
import 'src/screens/enhanced_search_screen.dart';
import 'screens/notifications_screen.dart';

class MyApp extends StatelessWidget {
  final navigatorKey = GlobalKey<NavigatorState>();
  final _firebaseInitializer = FirebaseInitializer();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _firebaseInitializer.ensureInitialized(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Error initializing app: ${snapshot.error}'),
              ),
            ),
          );
        }

        return ErrorBoundary(
          onError: (error, stackTrace) {
            debugPrint('❌ App-level error caught: $error');
            debugPrint('❌ Stack trace: $stackTrace');
          },
          child: MultiProvider(
            providers: [
              // Core providers
              ChangeNotifierProvider<core.UserService>(
                create: (_) => core.UserService(),
                lazy: true, // Changed to lazy to prevent early Firebase access
              ),
              Provider<AuthService>(create: (_) => AuthService(), lazy: true),
              ChangeNotifierProvider<core.ConnectivityService>(
                create: (_) => core.ConnectivityService(),
                lazy: false,
              ),
              Provider<ThemeData>(
                create: (_) => core.ArtbeatTheme.lightTheme,
                lazy: false,
              ),
              ChangeNotifierProvider<messaging.ChatService>(
                create: (_) => messaging.ChatService(),
                lazy: true, // Changed to lazy to prevent early Firebase access
              ),
              ChangeNotifierProvider<core.MessagingProvider>(
                create: (context) => core.MessagingProvider(
                  context.read<messaging.ChatService>(),
                ),
                lazy: true,
              ),
              // Community providers
              ChangeNotifierProvider<CommunityService>(
                create: (_) => CommunityService(),
                lazy: true, // Changed to lazy to prevent early Firebase access
              ),
              // Dashboard ViewModel
              ChangeNotifierProvider<core.DashboardViewModel>(
                create: (_) => core.DashboardViewModel(),
                lazy: true,
              ),
            ],
            child: MaterialApp(
              navigatorKey: navigatorKey,
              title: 'ARTbeat',
              theme: core.ArtbeatTheme.lightTheme,
              initialRoute: '/splash',
              onGenerateRoute: onGenerateRoute,
            ),
          ),
        );
      },
    );
  }

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // ...existing code...
    // Artwork browse route
    if (settings.name == '/artwork/browse') {
      return MaterialPageRoute(
        builder: (_) => const core.MainLayout(
          currentIndex: -1,
          child: artwork.ArtworkBrowseScreen(),
        ),
      );
    }
    switch (settings.name) {
      case '/gallery/artists-management':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: GalleryArtistsManagementScreen(),
          ),
        );
      case '/gallery/analytics':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: GalleryAnalyticsDashboardScreen(),
          ),
        );
      // Deep link: /profile/:userId
      case '/profile/deep':
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String?;
        if (userId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(body: Center(child: Text('No user ID provided'))),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              ProfileViewScreen(userId: userId, isCurrentUser: false),
        );

      // Deep link: /favorite/:favoriteId
      case '/favorite/deep':
        final args = settings.arguments as Map<String, dynamic>?;
        final favoriteId = args?['favoriteId'] as String?;
        final userId = args?['userId'] as String?;
        if (favoriteId == null || userId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(
                body: Center(child: Text('No favorite ID or user ID provided')),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              FavoriteDetailScreen(favoriteId: favoriteId, userId: userId),
        );
      // Core routes
      case '/splash':
        return MaterialPageRoute(builder: (_) => const core.SplashScreen());

      // Main dashboard route
      case '/dashboard':
        return MaterialPageRoute(
          builder: (_) {
            debugPrint('🏠 Building dashboard screen...');
            return const core.FluidDashboardScreen();
          },
        );

      // Profile routes
      case '/profile':
        return MaterialPageRoute(
          builder: (_) {
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            if (currentUserId == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Scaffold(
                  body: Center(
                    child: Text('Please log in to view your profile'),
                  ),
                ),
              );
            }
            return ProfileViewScreen(
              userId: currentUserId,
              isCurrentUser: true,
            );
          },
        );
      case '/profile/edit':
        return MaterialPageRoute(
          builder: (_) {
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            if (currentUserId == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Scaffold(
                  body: Center(
                    child: Text('Please log in to edit your profile'),
                  ),
                ),
              );
            }
            return EditProfileScreen(userId: currentUserId);
          },
        );
      case '/profile/picture-viewer':
        final args = settings.arguments as Map<String, dynamic>?;
        final imageUrl = args?['imageUrl'] as String?;
        if (imageUrl == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(
                body: Center(child: Text('No image URL provided')),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => core.MainLayout(
            currentIndex: -1,
            child: ProfilePictureViewerScreen(imageUrl: imageUrl),
          ),
        );
      case '/favorites':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Fan Club',
                showLogo: false,
              ),
              body: Center(child: Text('Fan Club coming soon')),
            ),
          ),
        );

      // Auth routes
      case '/auth':
        return MaterialPageRoute(
          builder: (_) =>
              const core.MainLayout(currentIndex: -1, child: LoginScreen()),
        );
      case '/login':
        return MaterialPageRoute(
          builder: (_) =>
              const core.MainLayout(currentIndex: -1, child: LoginScreen()),
        );
      case '/register':
        return MaterialPageRoute(
          builder: (_) =>
              const core.MainLayout(currentIndex: -1, child: RegisterScreen()),
        );
      case '/forgot-password':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ForgotPasswordScreen(),
          ),
        );
      case '/profile/create':
        return MaterialPageRoute(
          builder: (_) {
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            if (currentUserId == null) {
              // Redirect to login if not authenticated
              return const core.MainLayout(
                currentIndex: -1,
                child: LoginScreen(),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              child: CreateProfileScreen(userId: currentUserId),
            );
          },
        );
      case '/captures':
        return MaterialPageRoute(builder: (_) => const MyCapturesScreen());
      case '/achievements':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: AchievementsScreen(),
          ),
        );
      case '/capture/camera':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: capture.CameraCaptureScreen(),
          ),
        );
      case '/capture/detail':
        final args = settings.arguments as Map<String, dynamic>?;
        final captureId = args?['captureId'] as String?;
        if (captureId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(body: Center(child: Text('Capture not found'))),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: const core.EnhancedUniversalHeader(
                title: 'Capture Details',
                showLogo: false,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Capture Details Screen'),
                    const SizedBox(height: 8),
                    Text('Capture ID: $captureId'),
                    const SizedBox(height: 16),
                    const Text('Coming soon...'),
                  ],
                ),
              ),
            ),
          ),
        );
      case '/community/feed':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: UnifiedCommunityFeed(),
          ),
        );
      // Art Walk routes
      case '/art-walk/map':
        return MaterialPageRoute(builder: (_) => const ArtWalkMapScreen());
      case '/art-walk/list':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: 1, // Art Walk tab index
            child: ArtWalkListScreen(),
          ),
        );
      case '/art-walk/detail':
        final args = settings.arguments as Map<String, dynamic>?;
        final walkId = args?['walkId'] as String?;
        if (walkId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: 1,
              child: Scaffold(body: Center(child: Text('Art walk not found'))),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => core.MainLayout(
            currentIndex: 1,
            child: ArtWalkDetailScreen(walkId: walkId),
          ),
        );
      case '/art-walk/experience':
        final args = settings.arguments as Map<String, dynamic>?;
        final artWalkId = args?['artWalkId'] as String?;
        final artWalk = args?['artWalk'] as ArtWalkModel?;
        if (artWalkId == null || artWalk == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: 1,
              child: Scaffold(body: Center(child: Text('Art walk not found'))),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => core.MainLayout(
            currentIndex: 1,
            child: ArtWalkExperienceScreen(
              artWalkId: artWalkId,
              artWalk: artWalk,
            ),
          ),
        );
      case '/art-walk/create':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => core.MainLayout(
            currentIndex: 1,
            child: CreateArtWalkScreen(
              artWalkId: args?['artWalkId'] as String?,
              artWalkToEdit: args?['artWalk'] as ArtWalkModel?,
            ),
          ),
        );
      case '/art-walk/edit':
        final args = settings.arguments as Map<String, dynamic>?;
        final walkId = args?['walkId'] as String?;
        final artWalk = args?['artWalk'] as ArtWalkModel?;
        if (walkId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: 1,
              child: Scaffold(body: Center(child: Text('Art walk not found'))),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => core.MainLayout(
            currentIndex: 1,
            child: ArtWalkEditScreen(artWalkId: walkId, artWalk: artWalk),
          ),
        );
      case '/art-walk/dashboard':
        return MaterialPageRoute(
          builder: (_) => const ArtWalkDashboardScreen(),
        );
      case '/art-walk/my-walks':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: 1,
            child: ArtWalkListScreen(),
          ),
        );
      case '/art-walk/my-captures':
        return MaterialPageRoute(builder: (_) => const MyCapturesScreen());
      case '/enhanced-create-art-walk':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => core.MainLayout(
            currentIndex: 1,
            child: EnhancedArtWalkCreateScreen(
              artWalkId: args?['artWalkId'] as String?,
              artWalkToEdit: args?['artWalk'] as ArtWalkModel?,
            ),
          ),
        );
      case '/enhanced-art-walk-experience':
        final args = settings.arguments as Map<String, dynamic>?;
        final artWalkId = args?['artWalkId'] as String?;
        final artWalk = args?['artWalk'] as ArtWalkModel?;
        if (artWalkId == null || artWalk == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: 1,
              child: Scaffold(body: Center(child: Text('Art walk not found'))),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => core.MainLayout(
            currentIndex: 1,
            child: EnhancedArtWalkExperienceScreen(
              artWalkId: artWalkId,
              artWalk: artWalk,
            ),
          ),
        );
      case '/events':
        return MaterialPageRoute(
          builder: (_) => const UserEventsDashboardScreen(),
        );
      case '/events/discover':
        return MaterialPageRoute(
          builder: (_) => const UserEventsDashboardScreen(),
        );
      case '/events/dashboard':
        return MaterialPageRoute(builder: (_) => const EventsDashboardScreen());
      case '/events/artist-dashboard':
        return MaterialPageRoute(builder: (_) => const EventsDashboardScreen());
      case '/capture/dashboard':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: capture.EnhancedCaptureDashboardScreen(),
          ),
        );
      case '/community/dashboard':
        return MaterialPageRoute(
          builder: (_) => const CommunityDashboardScreen(),
        );
      case '/notifications':
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case '/community/posts':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: UnifiedCommunityFeed(),
          ),
        );
      case '/community/studios':
        return MaterialPageRoute(
          builder: (_) =>
              const core.MainLayout(currentIndex: -1, child: StudiosScreen()),
        );
      case '/community/gifts':
        return MaterialPageRoute(
          builder: (_) =>
              const core.MainLayout(currentIndex: -1, child: GiftsScreen()),
        );
      case '/community/portfolios':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: PortfoliosScreen(),
          ),
        );
      case '/community/moderation':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ModerationQueueScreen(),
          ),
        );
      case '/community/sponsorships':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: SponsorshipScreen(),
          ),
        );
      case '/community/settings':
        return MaterialPageRoute(
          builder: (_) =>
              const core.MainLayout(currentIndex: -1, child: QuietModeScreen()),
        );
      case '/dev':
        return MaterialPageRoute(
          builder: (_) =>
              const core.MainLayout(currentIndex: -1, child: DeveloperMenu()),
        );
      case '/feedback':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: core.FeedbackForm(),
          ),
        );
      case '/developer-feedback-admin':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: core.DeveloperFeedbackAdminScreen(),
          ),
        );
      case '/artist/artwork':
        return MaterialPageRoute(
          builder: (_) =>
              const core.MainLayout(currentIndex: -1, child: MyArtworkScreen()),
        );
      case '/artwork/upload':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: artwork.EnhancedArtworkUploadScreen(),
          ),
        );

      // Subscription routes
      case '/subscription/comparison':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: SubscriptionComparisonScreen(),
          ),
        );

      // Artist routes
      case '/artist/dashboard':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ArtistDashboardScreen(),
          ),
        );
      case '/artist/profile-edit':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ArtistProfileEditScreen(),
          ),
        );
      case '/artist/onboarding':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            appBar: core.EnhancedUniversalHeader(
              title: 'Join as Artist',
              showLogo: false,
              showBackButton: true,
            ),
            child: Center(child: Text('Artist onboarding coming soon')),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );
      case '/artist/analytics':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: AnalyticsDashboardScreen(),
          ),
        );
      case '/artist/approved-ads':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Approved Ads',
                showLogo: false,
              ),
              body: Center(child: Text('Approved ads coming soon')),
            ),
          ),
        );

      case '/artist/public-profile':
        final args = settings.arguments as Map<String, dynamic>?;
        final artistId = args?['artistId'] as String?;
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        // If no artistId is provided, use the current user's ID
        final targetUserId = artistId ?? currentUserId;

        if (targetUserId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(
                appBar: core.EnhancedUniversalHeader(
                  title: 'Artist Profile',
                  showLogo: false,
                ),
                body: Center(child: Text('Please log in to view your profile')),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => core.MainLayout(
            currentIndex: -1,
            child: ArtistPublicProfileScreen(userId: targetUserId),
          ),
        );
      case '/artist/artwork-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        final artworkId = args?['artworkId'] as String?;
        if (artworkId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(
                appBar: core.EnhancedUniversalHeader(
                  title: 'Artwork Detail',
                  showLogo: false,
                ),
                body: Center(child: Text('Artwork not found')),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => artwork.ArtworkDetailScreen(artworkId: artworkId),
        );

      // Artwork routes
      case '/artwork/search':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Search Artwork',
                showLogo: false,
              ),
              body: Center(child: Text('Artwork search coming soon')),
            ),
          ),
        );
      case '/artwork/featured':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            appBar: core.EnhancedUniversalHeader(
              title: 'Featured Artists',
              showLogo: false,
              showBackButton: true,
            ),
            child: ArtistListScreen(
              title: 'Featured Artists',
              showFeaturedOnly: true,
            ),
          ),
        );
      case '/artwork/recent':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Recent Artwork',
                showLogo: false,
              ),
              body: Center(child: Text('Recent artwork coming soon')),
            ),
          ),
        );
      case '/artwork/trending':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Trending Artwork',
                showLogo: false,
              ),
              body: Center(child: Text('Trending artwork coming soon')),
            ),
          ),
        );
      case '/artwork/edit':
        final args = settings.arguments as Map<String, dynamic>?;
        final artworkId = args?['artworkId'] as String?;
        final artworkModel = args?['artwork'] as artwork.ArtworkModel?;
        if (artworkId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(
                appBar: core.EnhancedUniversalHeader(
                  title: 'Edit Artwork',
                  showLogo: false,
                ),
                body: Center(child: Text('Artwork not found')),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => artwork.ArtworkEditScreen(
            artworkId: artworkId,
            artwork: artworkModel,
          ),
        );

      // Event routes (continued)
      case '/events/detail':
        final args = settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        if (eventId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(
                appBar: core.EnhancedUniversalHeader(
                  title: 'Event Details',
                  showLogo: false,
                ),
                body: Center(child: Text('Event not found')),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => EventDetailsScreen(eventId: eventId),
        );
      case '/events/upcoming':
        return MaterialPageRoute(
          builder: (_) => const EventsListScreen(
            title: 'Upcoming Events',
            showCreateButton: false,
          ),
        );
      case '/events/all':
        return MaterialPageRoute(
          builder: (_) => const EventsListScreen(
            title: 'All Events',
            showCreateButton: true,
          ),
        );
      case '/events/my-events':
        return MaterialPageRoute(
          builder: (_) => Consumer<core.UserService>(
            builder: (context, userService, child) => EventsListScreen(
              title: 'My Events',
              artistId: userService.currentUser?.uid,
              showCreateButton: true,
            ),
          ),
        );
      case '/events/my-tickets':
        return MaterialPageRoute(
          builder: (_) => Consumer<core.UserService>(
            builder: (context, userService, child) {
              final userId = userService.currentUser?.uid;
              if (userId == null) {
                return const core.MainLayout(
                  currentIndex: -1,
                  child: Scaffold(
                    appBar: core.EnhancedUniversalHeader(
                      title: 'My Tickets',
                      showLogo: false,
                    ),
                    body: Center(
                      child: Text('Please log in to view your tickets'),
                    ),
                  ),
                );
              }
              return MyTicketsScreen(userId: userId);
            },
          ),
        );
      case '/events/create':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: CreateEventScreen(),
          ),
        );

      // Additional Events routes
      case '/events/search':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: 4, // Events tab
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Search Events',
                showLogo: false,
              ),
              body: Center(child: Text('Event search coming soon')),
            ),
          ),
        );
      case '/events/nearby':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: 4, // Events tab
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Nearby Events',
                showLogo: false,
              ),
              body: Center(child: Text('Nearby events coming soon')),
            ),
          ),
        );
      case '/events/popular':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: 4, // Events tab
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Popular Events',
                showLogo: false,
              ),
              body: Center(child: Text('Popular events coming soon')),
            ),
          ),
        );
      case '/events/venues':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: 4, // Events tab
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Event Venues',
                showLogo: false,
              ),
              body: Center(child: Text('Event venues coming soon')),
            ),
          ),
        );

      // Settings routes
      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Settings',
                showLogo: false,
              ),
              body: Center(child: Text('Settings coming soon')),
            ),
          ),
        );
      case '/settings/account':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Account Settings',
                showLogo: false,
              ),
              body: Center(child: Text('Account settings coming soon')),
            ),
          ),
        );
      case '/settings/privacy':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Privacy Settings',
                showLogo: false,
              ),
              body: Center(child: Text('Privacy settings coming soon')),
            ),
          ),
        );
      case '/settings/notifications':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Notification Settings',
                showLogo: false,
              ),
              body: Center(child: Text('Notification settings coming soon')),
            ),
          ),
        );
      case '/settings/security':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Security Settings',
                showLogo: false,
              ),
              body: Center(child: Text('Security settings coming soon')),
            ),
          ),
        );
      case '/support':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Help & Support',
                showLogo: false,
              ),
              body: Center(child: Text('Help & Support coming soon')),
            ),
          ),
        );

      // Admin routes
      case '/admin/dashboard':
        return MaterialPageRoute(
          builder: (_) => const admin.AdminDashboardScreen(),
        );
      case '/admin/users':
        return MaterialPageRoute(
          builder: (_) => const admin.AdminUserManagementScreen(),
        );
      case '/admin/moderation':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: capture.AdminContentModerationScreen(),
          ),
        );
      case '/admin/settings':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            appBar: core.EnhancedUniversalHeader(
              title: 'System Settings',
              showLogo: false,
              showBackButton: true,
            ),
            child: core.SystemSettingsScreen(),
          ),
        );
      case '/admin/ad-review':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.AdminAdReviewScreen(),
          ),
        );
      case '/admin/messaging':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: messaging.EnhancedMessagingDashboardScreen(),
          ),
        );

      // Developer menu (already handled above)

      // Feedback submission route (already handled above)
      case '/search':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            appBar: core.EnhancedUniversalHeader(
              title: 'Search',
              showLogo: false,
              showBackButton: true,
            ),
            child: EnhancedSearchScreen(),
          ),
        );
      case '/search/results':
        final searchArgs = settings.arguments as Map<String, dynamic>;
        final searchQuery = searchArgs['query'] as String;
        return MaterialPageRoute(
          builder: (_) => core.MainLayout(
            currentIndex: -1,
            child: core.SearchResultsScreen(query: searchQuery),
          ),
        );
      case '/artist/search':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            appBar: core.EnhancedUniversalHeader(
              title: 'Search Artists',
              showLogo: false,
              showBackButton: true,
            ),
            child: ArtistListScreen(title: 'Search Artists'),
          ),
        );
      case '/artist-search':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex:
                3, // Community tab since this is about discovering artists
            child: ArtistBrowseScreen(),
          ),
        );
      case '/artist/browse':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex:
                3, // Community tab since this is about discovering artists
            child: ArtistBrowseScreen(),
          ),
        );
      case '/art-search':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Search Art',
                showLogo: false,
              ),
              body: Center(child: Text('Art search coming soon')),
            ),
          ),
        );
      case '/art-walk-search':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Search Art Walks',
                showLogo: false,
              ),
              body: Center(child: Text('Art walk search coming soon')),
            ),
          ),
        );
      case '/local':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            appBar: core.EnhancedUniversalHeader(
              title: 'Local Scene',
              showLogo: false,
              showBackButton: true,
            ),
            child: ArtistListScreen(title: 'Local Artists'),
          ),
        );
      case '/location-search':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Search Locations',
                showLogo: false,
              ),
              body: Center(child: Text('Location search coming soon')),
            ),
          ),
        );
      case '/trending':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            appBar: core.EnhancedUniversalHeader(
              title: 'Trending',
              showLogo: false,
              showBackButton: true,
            ),
            child: ArtistListScreen(title: 'Trending Artists'),
          ),
        );

      // Ad Creation Routes
      case '/ad-create/user':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.UserAdCreateScreen(),
          ),
        );
      case '/ad-create/artist':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.ArtistAdCreateScreen(),
          ),
        );
      case '/ad-create/gallery':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.GalleryAdCreateScreen(),
          ),
        );
      case '/ad-create/admin':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.AdminAdCreateScreen(),
          ),
        );

      // Ad Review Routes
      case '/ad-review/user':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.UserAdReviewScreen(),
          ),
        );
      case '/ad-status/artist':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.ArtistAdStatusScreen(),
          ),
        );
      case '/ad-status/gallery':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.GalleryAdStatusScreen(),
          ),
        );
      case '/ad-review/admin':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.AdminAdReviewScreen(),
          ),
        );
      // Messaging routes
      case '/messaging':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: messaging.MessagingNavigation(),
          ),
          fullscreenDialog: true,
        );
      case '/messaging/new':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: messaging.ContactSelectionScreen(),
          ),
        );
      case '/messaging/chat':
        final args = settings.arguments as Map<String, dynamic>?;
        final chat = args?['chat'] as messaging.ChatModel?;
        if (chat == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(body: Center(child: Text('Chat not found'))),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => core.MainLayout(
            currentIndex: -1, // -1 means no bottom nav item is selected
            child: messaging.ChatScreen(chat: chat),
          ),
        );
      case '/messaging/group':
        return MaterialPageRoute(
          builder: (_) => const messaging.GroupChatScreen(),
        );
      case '/messaging/group/new':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: messaging.GroupCreationScreen(),
          ),
        );

      case '/messaging/settings':
        final args = settings.arguments as Map<String, dynamic>?;
        final chat = args?['chat'] as messaging.ChatModel?;
        if (chat == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(body: Center(child: Text('Chat not found'))),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => messaging.ChatSettingsScreen(chat: chat),
        );
      case '/messaging/chat-info':
        final args = settings.arguments as Map<String, dynamic>?;
        final chat = args?['chat'] as messaging.ChatModel?;
        if (chat == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(body: Center(child: Text('Chat not found'))),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => core.MainLayout(
            currentIndex: -1,
            child: messaging.ChatInfoScreen(chat: chat),
          ),
        );
      case '/messaging/blocked-users':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: messaging.BlockedUsersScreen(),
          ),
        );
      case '/messaging/user':
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String?;
        if (userId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(body: Center(child: Text('User not found'))),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (context) => core.MainLayout(
            currentIndex: -1,
            child: FutureBuilder<messaging.UserModel?>(
              future: Provider.of<messaging.ChatService>(
                context,
                listen: false,
              ).getUser(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return const Center(child: Text('User not found'));
                }
                return messaging.UserProfileScreen(user: snapshot.data!);
              },
            ),
          ),
        );
      // Deep link routes for messaging
      case '/messaging/chat-deep':
        final args = settings.arguments as Map<String, dynamic>?;
        final chatId = args?['chatId'] as String?;
        if (chatId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(
                body: Center(child: Text('Chat ID not provided')),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (context) => core.MainLayout(
            currentIndex: -1,
            child: FutureBuilder<messaging.ChatModel?>(
              future: Provider.of<messaging.ChatService>(
                context,
                listen: false,
              ).getChatById(chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return const Center(child: Text('Chat not found'));
                }
                return messaging.ChatScreen(chat: snapshot.data!);
              },
            ),
          ),
        );
      case '/messaging/user-chat':
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String?;
        if (userId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(
                body: Center(child: Text('User ID not provided')),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (context) => core.MainLayout(
            currentIndex: -1,
            child: FutureBuilder<messaging.ChatModel>(
              future: Provider.of<messaging.ChatService>(
                context,
                listen: false,
              ).createOrGetChat(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return const Center(child: Text('Error creating chat'));
                }
                return messaging.ChatScreen(chat: snapshot.data!);
              },
            ),
          ),
        );
      case '/debug/profile-fix':
        return MaterialPageRoute(
          builder: (_) =>
              const core.MainLayout(currentIndex: -1, child: DebugProfileFix()),
        );
    }

    // Handle dynamic routes
    if (settings.name != null) {
      // Handle /event/$eventId route
      if (settings.name!.startsWith('/event/')) {
        final eventId = settings.name!.replaceFirst('/event/', '');
        if (eventId.isNotEmpty) {
          return MaterialPageRoute(
            builder: (_) => EventDetailsWrapper(eventId: eventId),
          );
        }
      }
    }

    // Fallback: return splash screen if no route matched
    return MaterialPageRoute(
      builder: (_) =>
          const core.MainLayout(currentIndex: -1, child: core.SplashScreen()),
    );
  }
}
